#include <bitsdojo_window_windows/bitsdojo_window_plugin.h>
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <shobjidl.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// Hide the native frame (we draw our own via Flutter) and start the window
// hidden so the Dart side can position / size it before first paint.
auto bdw_configure = bitsdojo_window_configure(BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP);

// Must match sidecar/internal/branding.AUMID so Toast / taskbar entries coming
// from the Go sidecar group under this process's taskbar icon.
static const wchar_t kAppUserModelID[] = L"FleetKanban.Desktop";

// BindToKillOnCloseJob creates a new Job Object, assigns the current process
// to it with JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE, and intentionally leaks the
// handle. Any child process spawned after this call (including the Go
// sidecar started from Dart Process.start) inherits the job, so when the
// Flutter UI exits (graceful, SIGKILL, or crash) Windows tears the entire
// tree down atomically. Without this, killing fleetkanban_ui.exe leaves the
// sidecar orphaned on the SQLite file.
static void BindToKillOnCloseJob() {
  HANDLE job = ::CreateJobObjectW(nullptr, nullptr);
  if (job == nullptr) return;

  JOBOBJECT_EXTENDED_LIMIT_INFORMATION info = {};
  // KILL_ON_JOB_CLOSE: default behaviour - sidecar dies with the UI.
  // BREAKAWAY_OK: lets the sidecar launch a *detached* helper console
  //   (e.g. Copilot /login in Windows Terminal) by passing
  //   CREATE_BREAKAWAY_FROM_JOB. Without this flag Windows returns
  //   ERROR_ACCESS_DENIED from CreateProcess and the auth-launch fails.
  //   Regular children that don't request breakaway remain in the job, so
  //   the kill-on-close guarantee is unchanged.
  info.BasicLimitInformation.LimitFlags =
      JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE |
      JOB_OBJECT_LIMIT_BREAKAWAY_OK;
  if (!::SetInformationJobObject(job, JobObjectExtendedLimitInformation,
                                 &info, sizeof(info))) {
    ::CloseHandle(job);
    return;
  }
  if (!::AssignProcessToJobObject(job, ::GetCurrentProcess())) {
    ::CloseHandle(job);
    return;
  }
  // Deliberately leak the handle: we want the job to persist for the lifetime
  // of the process. Windows cleans it up on process exit.
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Bind before any child process is created so the sidecar inherits the
  // job automatically.
  BindToKillOnCloseJob();

  // Set the AppUserModelID as early as possible, before any window is
  // created. Windows Shell uses this to group taskbar buttons and route
  // Toast activations.
  ::SetCurrentProcessExplicitAppUserModelID(kAppUserModelID);

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 800);
  if (!window.Create(L"FleetKanban", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
