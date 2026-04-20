// Taskbar overlay: shows a running-task count badge on the Windows 11
// taskbar button for the Flutter window.
//
// Uses ITaskbarList3 directly over FFI (win32 5.15 does not ship prebuilt
// bindings for this interface). We also drive SetProgressState with
// TBPF_INDETERMINATE so there is motion on the taskbar while tasks run —
// otherwise a static overlay icon blends into the app icon at a glance.
//
// Lifecycle:
//   * init(hwnd) — called once after the window becomes ready.
//   * update(runningCount) — called every time the running-task count
//     changes. Zero clears the overlay and stops progress.
//   * dispose() — called on app shutdown. Releases the COM pointer and
//     the most recently-created HICON.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

// CLSID_TaskbarList and IID_ITaskbarList3. Constants rather than inline
// strings so the intent is clear in stack traces.
const _clsidTaskbarList = '{56FDF344-FD6D-11D0-958A-006097C9A090}';
const _iidITaskbarList3 = '{EA1AFB91-9E28-4B86-90E9-9E9F8A5EEFAF}';

// Taskbar progress flags (TBPFLAG).
const int _tbpfNoProgress = 0x0;
const int _tbpfIndeterminate = 0x1;

// RPC_E_CHANGED_MODE — CoInitializeEx succeeded previously with a
// different apartment. Not an error for our use case because we don't
// actually need a fresh apartment, we just need COM to be live.
const int _rpcEChangedMode = 0x80010106;

class TaskbarOverlay {
  TaskbarOverlay._();
  static final TaskbarOverlay instance = TaskbarOverlay._();

  Pointer<COMObject>? _ptr;
  int _hwnd = 0;
  int _lastIcon = 0; // HICON; kept so we can destroy it on update/dispose
  int _lastCount = -1;

  /// Creates the ITaskbarList3 COM object and pairs it with [hwnd]. Returns
  /// false on failure; callers should treat the feature as unavailable and
  /// continue without crashing.
  bool init(int hwnd) {
    if (_ptr != null) return true;
    if (hwnd == 0) return false;

    final initHr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (initHr < 0 && initHr != _rpcEChangedMode) return false;

    final clsid = GUIDFromString(_clsidTaskbarList);
    final iid = GUIDFromString(_iidITaskbarList3);
    final ppv = calloc<Pointer<COMObject>>();
    try {
      final hr = CoCreateInstance(
        clsid,
        nullptr,
        CLSCTX_INPROC_SERVER,
        iid,
        ppv.cast(),
      );
      if (hr < 0 || ppv.value.address == 0) return false;
      _ptr = ppv.value;
      _hwnd = hwnd;
      // HrInit — vtable slot 3. Must be called before any other ITaskbarList
      // method, per MSDN.
      _callHrInit();
      return true;
    } finally {
      free(clsid);
      free(iid);
      free(ppv);
    }
  }

  /// Updates the overlay for [runningCount]. Zero clears it and removes the
  /// progress indicator; positive counts draw a red badge with the number
  /// (or "9+" for counts over 9, matching Windows 11 notification badges).
  void update(int runningCount) {
    final ptr = _ptr;
    if (ptr == null) return;
    if (runningCount == _lastCount) return;
    _lastCount = runningCount;

    if (runningCount <= 0) {
      _setOverlayIcon(0, '');
      _setProgressState(_tbpfNoProgress);
    } else {
      final label = runningCount > 9 ? '9+' : runningCount.toString();
      final hIcon = _createCountIcon(label);
      _setOverlayIcon(hIcon, '$runningCount running tasks');
      _setProgressState(_tbpfIndeterminate);
      // The system copies the bitmap, so we can destroy our handle after
      // the call returns. Hold until next update to be safe.
      if (_lastIcon != 0) DestroyIcon(_lastIcon);
      _lastIcon = hIcon;
    }
  }

  /// Releases COM resources. After dispose() the instance must be re-init'd.
  void dispose() {
    if (_lastIcon != 0) {
      DestroyIcon(_lastIcon);
      _lastIcon = 0;
    }
    final ptr = _ptr;
    if (ptr != null) {
      // Release via IUnknown (vtable slot 2).
      (ptr.ref.vtable + 2)
          .cast<Pointer<NativeFunction<Uint32 Function(VTablePointer)>>>()
          .value
          .asFunction<int Function(VTablePointer)>()(ptr.ref.lpVtbl);
      _ptr = null;
    }
    _lastCount = -1;
  }

  // --- vtable helpers ------------------------------------------------------

  void _callHrInit() {
    final ptr = _ptr!;
    (ptr.ref.vtable + 3)
        .cast<Pointer<NativeFunction<Int32 Function(VTablePointer)>>>()
        .value
        .asFunction<int Function(VTablePointer)>()(ptr.ref.lpVtbl);
  }

  void _setProgressState(int flag) {
    final ptr = _ptr!;
    // Slot 10: HRESULT SetProgressState(HWND hwnd, TBPFLAG tbpFlags)
    (ptr.ref.vtable + 10)
        .cast<
          Pointer<
            NativeFunction<
              Int32 Function(VTablePointer, IntPtr hwnd, Int32 flag)
            >
          >
        >()
        .value
        .asFunction<int Function(VTablePointer, int hwnd, int flag)>()(
      ptr.ref.lpVtbl,
      _hwnd,
      flag,
    );
  }

  void _setOverlayIcon(int hIcon, String description) {
    final ptr = _ptr!;
    final descPtr = description.isEmpty ? nullptr : description.toNativeUtf16();
    try {
      // Slot 18: HRESULT SetOverlayIcon(HWND, HICON, LPCWSTR)
      (ptr.ref.vtable + 18)
          .cast<
            Pointer<
              NativeFunction<
                Int32 Function(
                  VTablePointer,
                  IntPtr hwnd,
                  IntPtr hIcon,
                  Pointer<Utf16> desc,
                )
              >
            >
          >()
          .value
          .asFunction<
            int Function(
              VTablePointer,
              int hwnd,
              int hIcon,
              Pointer<Utf16> desc,
            )
          >()(ptr.ref.lpVtbl, _hwnd, hIcon, descPtr);
    } finally {
      if (descPtr != nullptr) free(descPtr);
    }
  }
}

// ---------------------------------------------------------------------------
// Dynamic icon rendering
// ---------------------------------------------------------------------------

/// Draws [label] on a 16x16 icon: red disc, white centered text. Returns an
/// HICON the caller owns (must DestroyIcon). Returns 0 on GDI failure.
int _createCountIcon(String label) {
  final hdcScreen = GetDC(0);
  if (hdcScreen == 0) return 0;

  final hdcMem = CreateCompatibleDC(hdcScreen);
  final hBitmapColor = CreateCompatibleBitmap(hdcScreen, 16, 16);
  final hBitmapMask = CreateBitmap(16, 16, 1, 1, nullptr);
  // Always release the screen DC; the memory DC and bitmaps we'll manage
  // explicitly because their lifetimes are scoped to this function.
  ReleaseDC(0, hdcScreen);

  final oldBitmap = SelectObject(hdcMem, hBitmapColor);

  // Fill the entire bitmap with red. Leaving the bottom-right pixel
  // transparent would look cleaner but requires a DIB section; the alpha
  // mask handles visual shape well enough for a 16×16 badge.
  final rect = calloc<RECT>()
    ..ref.left = 0
    ..ref.top = 0
    ..ref.right = 16
    ..ref.bottom = 16;
  final brush = CreateSolidBrush(_rgb(196, 32, 32));
  FillRect(hdcMem, rect, brush);
  DeleteObject(brush);

  // Draw a tight circle over the fill so the icon reads as a badge at
  // extra-small sizes rather than a square swatch.
  final blackPen = GetStockObject(_nullPen);
  final oldPen = SelectObject(hdcMem, blackPen);
  SelectObject(hdcMem, CreateSolidBrush(_rgb(196, 32, 32)));
  Ellipse(hdcMem, 0, 0, 16, 16);
  SelectObject(hdcMem, oldPen);

  // Text: small bold white centered. Use a LOGFONT with CreateFontIndirect
  // so we get consistent metrics across monitors.
  final lf = calloc<LOGFONT>()
    ..ref.lfHeight = -10
    ..ref.lfWeight =
        700 // bold
    ..ref.lfCharSet =
        1 // DEFAULT_CHARSET
    ..ref.lfQuality = 5; // CLEARTYPE_QUALITY
  // "Segoe UI" is the Windows 11 default; setter handles the UTF-16 copy.
  lf.ref.lfFaceName = 'Segoe UI';
  final hFont = CreateFontIndirect(lf);
  free(lf);

  final oldFont = SelectObject(hdcMem, hFont);
  SetBkMode(hdcMem, TRANSPARENT);
  SetTextColor(hdcMem, _rgb(255, 255, 255));
  final labelPtr = label.toNativeUtf16();
  DrawText(hdcMem, labelPtr, -1, rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
  free(labelPtr);

  SelectObject(hdcMem, oldFont);
  SelectObject(hdcMem, oldBitmap);
  DeleteObject(hFont);
  free(rect);

  final iconInfo = calloc<ICONINFO>()
    ..ref.fIcon = 1
    ..ref.xHotspot = 0
    ..ref.yHotspot = 0
    ..ref.hbmMask = hBitmapMask
    ..ref.hbmColor = hBitmapColor;
  final hIcon = CreateIconIndirect(iconInfo);
  free(iconInfo);

  DeleteDC(hdcMem);
  DeleteObject(hBitmapColor);
  DeleteObject(hBitmapMask);

  return hIcon;
}

// GetStockObject index for NULL_PEN. Not a DT_/LR_ constant so it's not in
// win32's re-exports.
const int _nullPen = 8;

int _rgb(int r, int g, int b) => r | (g << 8) | (b << 16);
