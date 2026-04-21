//go:build windows

package winapi

// Jump List Tasks category via ICustomDestinationList + IObjectCollection +
// IShellLink.
//
// Windows COM vtable layout (all pointers are uintptr-width):
//
//	ICustomDestinationList (CLSID_DestinationList / IID_ICustomDestinationList)
//	  0  QueryInterface
//	  1  AddRef
//	  2  Release
//	  3  SetAppID
//	  4  BeginList        → returns IObjectArray* pRemoved
//	  5  AppendCategory
//	  6  AppendKnownCategory
//	  7  AddUserTasks     → takes IObjectArray*
//	  8  CommitList
//	  9  GetRemovedDestinations
//	 10  DeleteList
//	 11  AbortList
//
//	IObjectCollection (CLSID_EnumerableObjectCollection / IID_IObjectCollection)
//	  0  QueryInterface
//	  1  AddRef
//	  2  Release
//	  3  GetCount  (IObjectArray vtable slot 3)
//	  4  GetAt     (IObjectArray vtable slot 4)
//	  5  AddObject
//	  6  AddFromArray
//	  7  RemoveObjectAt
//	  8  Clear
//
//	IShellLink (CLSID_ShellLink / IID_IShellLinkW)
//	  0  QueryInterface
//	  1  AddRef
//	  2  Release
//	  3  GetPath
//	  4  GetIDList
//	  5  SetIDList
//	  6  GetDescription
//	  7  SetDescription
//	  8  GetWorkingDirectory
//	  9  SetWorkingDirectory
//	 10  GetArguments
//	 11  SetArguments
//	 12  GetHotkey
//	 13  SetHotkey
//	 14  GetShowCmd
//	 15  SetShowCmd
//	 16  GetIconLocation
//	 17  SetIconLocation
//	 18  SetRelativePath
//	 19  Resolve
//	 20  SetPath
//
//	IPropertyStore
//	  0  QueryInterface
//	  1  AddRef
//	  2  Release
//	  3  GetCount
//	  4  GetAt
//	  5  GetValue
//	  6  SetValue
//	  7  Commit
//
// All methods are called via uintptr(unsafe.Pointer(vtable[slot])) + SyscallN.

import (
	"fmt"
	"os"
	"syscall"
	"unsafe"

	"golang.org/x/sys/windows"
)

// COM GUIDs — laid out as [16]byte matching the binary representation of
// the GUID structure (Data1 in little-endian 4-byte, Data2/Data3 in
// little-endian 2-byte, Data4 as 8 raw bytes).

var (
	clsidDestinationList = windows.GUID{
		Data1: 0x77f10cf0,
		Data2: 0x3db5,
		Data3: 0x4966,
		Data4: [8]byte{0xb5, 0x20, 0xb7, 0xb5, 0x44, 0x85, 0x52, 0x88},
	}
	iidCustomDestinationList = windows.GUID{
		Data1: 0x6332debf,
		Data2: 0x87b5,
		Data3: 0x4670,
		Data4: [8]byte{0x90, 0xc0, 0x5e, 0x57, 0xb4, 0x08, 0xa4, 0x9e},
	}

	clsidEnumerableObjectCollection = windows.GUID{
		Data1: 0x2d3468c1,
		Data2: 0x36a7,
		Data3: 0x43b6,
		Data4: [8]byte{0xac, 0x24, 0xd3, 0xf0, 0x2f, 0xd9, 0x60, 0x7a},
	}
	iidObjectCollection = windows.GUID{
		Data1: 0x5632b1a4,
		Data2: 0xe38a,
		Data3: 0x400a,
		Data4: [8]byte{0x92, 0x8a, 0xd4, 0xcd, 0x63, 0x23, 0x02, 0x95},
	}

	clsidShellLink = windows.GUID{
		Data1: 0x00021401,
		Data2: 0x0000,
		Data3: 0x0000,
		Data4: [8]byte{0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46},
	}
	iidShellLinkW = windows.GUID{
		Data1: 0x000214f9,
		Data2: 0x0000,
		Data3: 0x0000,
		Data4: [8]byte{0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46},
	}
	iidPropertyStore = windows.GUID{
		Data1: 0x886d8eeb,
		Data2: 0x8cf2,
		Data3: 0x4446,
		Data4: [8]byte{0x8d, 0x02, 0xcd, 0xba, 0x1d, 0xbd, 0xcf, 0x99},
	}
)

// PROPERTYKEY for System.Title — used to set the display title of a
// IShellLink task entry.  {F29F85E0-4FF9-1068-AB91-08002B27B3D9}, pid 2.
var pkeyTitle = propertyKey{
	fmtID: windows.GUID{
		Data1: 0xf29f85e0,
		Data2: 0x4ff9,
		Data3: 0x1068,
		Data4: [8]byte{0xab, 0x91, 0x08, 0x00, 0x2b, 0x27, 0xb3, 0xd9},
	},
	pid: 2,
}

type propertyKey struct {
	fmtID windows.GUID
	pid   uint32
}

// PROPVARIANT: only the VT_LPWSTR variant is needed here.
// Layout: vt (2 bytes) + reserved (6 bytes) + union (8 bytes pointer-sized).
type propVariant struct {
	vt         uint16
	wReserved1 uint16
	wReserved2 uint16
	wReserved3 uint16
	pwszVal    uintptr // pointer to UTF-16 string when vt == VT_LPWSTR (31)
}

const vtLPWSTR = 31

// ole32 procs — CoInitializeEx / CoUninitialize / CoCreateInstance.
var (
	modole32             = windows.NewLazySystemDLL("ole32.dll")
	procCoInitializeEx   = modole32.NewProc("CoInitializeEx")
	procCoUninitialize   = modole32.NewProc("CoUninitialize")
	procCoCreateInstance = modole32.NewProc("CoCreateInstance")
	// procPropVariantClear is reserved for future PROPVARIANT-typed
	// IPropertyStore::SetValue calls (e.g. PKEY_Title with VT_LPWSTR
	// sometimes round-trips through a PROPVARIANT buffer). Kept as a
	// lazy proc reference so the extra symbol load cost is zero when
	// unused.
	_ = modole32.NewProc("PropVariantClear")
)

// coInitialize initialises COM on the current thread in a multi-threaded
// apartment. Returns true when CoUninitialize must be called by the caller.
func coInitialize() (uninit func(), err error) {
	const coinitMultithreaded = 0x0
	r1, _, _ := procCoInitializeEx.Call(0, uintptr(coinitMultithreaded))
	// S_OK (0) or S_FALSE (1) — already initialised; both require Uninit.
	// RPC_E_CHANGED_MODE (0x80010106) means a different apartment was
	// already set up; we can still use COM but must not call Uninit.
	const sOK = 0
	const sFalse = 1
	hr := uint32(r1)
	if hr == sOK || hr == sFalse {
		return func() { procCoUninitialize.Call() }, nil
	}
	return nil, fmt.Errorf("winapi: CoInitializeEx: HRESULT 0x%08X", hr)
}

// comObj is a Go-pointer-typed handle to a COM object. A COM object's memory
// layout begins with a pointer to its vtable (*vtbl), so we model it as a
// pointer to a pointer to an array of function pointers (**[64]uintptr). This
// keeps the COM object address as a genuine Go pointer throughout, so all
// unsafe.Pointer conversions in the helpers below are pointer-to-pointer and
// do not trigger the go vet "possible misuse of unsafe.Pointer" diagnostic.
//
// The COM objects live in the Windows CRT heap (not the Go heap) and are never
// moved by the GC. We never store a comObj past its COM Release call.
type comObj = **[64]uintptr

// comCreate calls CoCreateInstance and returns a comObj.
func comCreate(clsid, iid *windows.GUID) (comObj, error) {
	const clsctxInprocServer = 0x1
	var ppv **[64]uintptr
	r1, _, _ := procCoCreateInstance.Call(
		uintptr(unsafe.Pointer(clsid)),
		0,
		uintptr(clsctxInprocServer),
		uintptr(unsafe.Pointer(iid)),
		uintptr(unsafe.Pointer(&ppv)),
	)
	if uint32(r1) != 0 {
		return nil, fmt.Errorf("winapi: CoCreateInstance: HRESULT 0x%08X", uint32(r1))
	}
	return ppv, nil
}

// vtCall invokes vtable slot n on obj with additional args. Returns HRESULT.
//
// The COM calling convention passes the object pointer as the first argument
// (the implicit "this" parameter). obj is a **[64]uintptr so *obj gives the
// vtable *[64]uintptr — a live Go pointer — and (*obj)[slot] is the function
// address. All unsafe.Pointer conversions are pointer-to-pointer (vet-clean).
func vtCall(obj comObj, slot int, args ...uintptr) uintptr {
	fn := (*obj)[slot] // vtable function address
	// Prepend the COM this-pointer as first argument.
	objPtr := uintptr(unsafe.Pointer(obj))
	allArgs := make([]uintptr, 0, 1+len(args))
	allArgs = append(allArgs, objPtr)
	allArgs = append(allArgs, args...)
	r1, _, _ := syscall.SyscallN(fn, allArgs...)
	return r1
}

// comRelease calls IUnknown::Release (vtable slot 2).
func comRelease(obj comObj) {
	if obj == nil {
		return
	}
	vtCall(obj, 2)
}

// comQueryInterface calls IUnknown::QueryInterface (vtable slot 0).
func comQueryInterface(obj comObj, iid *windows.GUID) (comObj, error) {
	var ppv **[64]uintptr
	r1 := vtCall(obj, 0, uintptr(unsafe.Pointer(iid)), uintptr(unsafe.Pointer(&ppv)))
	if uint32(r1) != 0 {
		return nil, fmt.Errorf("winapi: QueryInterface: HRESULT 0x%08X", uint32(r1))
	}
	return ppv, nil
}

// jumpListEntry describes a single Tasks-category entry for the jump list.
type jumpListEntry struct {
	// Path is the executable path (e.g. "explorer.exe" or an absolute path).
	Path string
	// Args is the command-line arguments string.
	Args string
	// Title is the display label shown in the jump list.
	Title string
	// Description is the tooltip text.
	Description string
}

// RegisterJumpList attaches a Tasks category to the FleetKanban jump list
// under AUMID "com.fleetkanban.desktop".  Idempotent — re-registration
// replaces any existing entries.
//
// Minimum entries registered:
//   - "Open Harness Skill" → explorer.exe %APPDATA%\FleetKanban\harness-skill
//     (TODO: replace with UI deep-link /harness once the Flutter router
//     exposes a named-pipe / protocol-handler activation path)
//   - "Reveal Runs Directory" → explorer.exe %APPDATA%\FleetKanban\runs
//
// Failure is non-fatal — taskbar integration is optional UX.
func RegisterJumpList(exePath string) error {
	appData := os.Getenv("APPDATA")

	harnessPath := ""
	runsPath := ""
	if appData != "" {
		harnessPath = appData + `\FleetKanban\harness-skill`
		runsPath = appData + `\FleetKanban\runs`
	}

	entries := []jumpListEntry{
		{
			// TODO: replace explorer fallback with UI deep-link activation
			// once Flutter router exposes /harness as a protocol-handler
			// (e.g. fleetkanban://harness). exePath is available here for
			// future: exePath + " --focus-harness".
			Path:        "explorer.exe",
			Args:        harnessPath,
			Title:       "Open Harness Skill",
			Description: "Open the FleetKanban harness-skill directory",
		},
		{
			Path:        "explorer.exe",
			Args:        runsPath,
			Title:       "Reveal Runs Directory",
			Description: "Open the FleetKanban runs output directory",
		},
	}
	_ = exePath // reserved for future --focus-harness deep-link

	uninit, err := coInitialize()
	if err != nil {
		return fmt.Errorf("winapi: RegisterJumpList: %w", err)
	}
	defer uninit()

	// Create ICustomDestinationList.
	cdlPtr, err := comCreate(&clsidDestinationList, &iidCustomDestinationList)
	if err != nil {
		return fmt.Errorf("winapi: RegisterJumpList: ICustomDestinationList: %w", err)
	}
	defer comRelease(cdlPtr)

	// SetAppID — vtable slot 3.
	aumidW, err := windows.UTF16PtrFromString("com.fleetkanban.desktop")
	if err != nil {
		return fmt.Errorf("winapi: RegisterJumpList: encode AUMID: %w", err)
	}
	if r1 := vtCall(cdlPtr, 3, uintptr(unsafe.Pointer(aumidW))); uint32(r1) != 0 {
		return fmt.Errorf("winapi: ICustomDestinationList::SetAppID: HRESULT 0x%08X", uint32(r1))
	}

	// BeginList — vtable slot 4.
	// Signature: BeginList(UINT* pcMinSlots, REFIID riid, void** ppv)
	// We discard the removed-destinations IObjectArray.
	var minSlots uint32
	var removedPtr **[64]uintptr
	if r1 := vtCall(cdlPtr, 4,
		uintptr(unsafe.Pointer(&minSlots)),
		uintptr(unsafe.Pointer(&iidObjectCollection)),
		uintptr(unsafe.Pointer(&removedPtr)),
	); uint32(r1) != 0 {
		return fmt.Errorf("winapi: ICustomDestinationList::BeginList: HRESULT 0x%08X", uint32(r1))
	}
	if removedPtr != nil {
		comRelease(removedPtr)
	}

	// Build an IObjectCollection and fill it with IShellLink objects.
	colPtr, err := comCreate(&clsidEnumerableObjectCollection, &iidObjectCollection)
	if err != nil {
		_ = vtCall(cdlPtr, 11) // AbortList
		return fmt.Errorf("winapi: RegisterJumpList: IObjectCollection: %w", err)
	}
	defer comRelease(colPtr)

	for _, e := range entries {
		if err := addShellLinkToCollection(colPtr, e); err != nil {
			_ = vtCall(cdlPtr, 11) // AbortList
			return fmt.Errorf("winapi: RegisterJumpList: addShellLink %q: %w", e.Title, err)
		}
	}

	// AddUserTasks — vtable slot 7. Requires IObjectArray; IObjectCollection
	// implements IObjectArray so we QueryInterface to be safe.
	iidObjArray := windows.GUID{
		Data1: 0x92ca9dcd,
		Data2: 0x5622,
		Data3: 0x4bba,
		Data4: [8]byte{0xa8, 0x05, 0x5e, 0x9f, 0x54, 0x1b, 0xd8, 0xc9},
	}
	arrPtr, err := comQueryInterface(colPtr, &iidObjArray)
	if err != nil {
		_ = vtCall(cdlPtr, 11)
		return fmt.Errorf("winapi: RegisterJumpList: QI IObjectArray: %w", err)
	}
	defer comRelease(arrPtr)

	if r1 := vtCall(cdlPtr, 7, uintptr(unsafe.Pointer(arrPtr))); uint32(r1) != 0 {
		_ = vtCall(cdlPtr, 11)
		return fmt.Errorf("winapi: ICustomDestinationList::AddUserTasks: HRESULT 0x%08X", uint32(r1))
	}

	// CommitList — vtable slot 8.
	if r1 := vtCall(cdlPtr, 8); uint32(r1) != 0 {
		return fmt.Errorf("winapi: ICustomDestinationList::CommitList: HRESULT 0x%08X", uint32(r1))
	}
	return nil
}

// ClearJumpList removes all custom jump list entries for the FleetKanban
// AUMID by calling ICustomDestinationList::DeleteList.
func ClearJumpList() error {
	uninit, err := coInitialize()
	if err != nil {
		return fmt.Errorf("winapi: ClearJumpList: %w", err)
	}
	defer uninit()

	cdlPtr, err := comCreate(&clsidDestinationList, &iidCustomDestinationList)
	if err != nil {
		return fmt.Errorf("winapi: ClearJumpList: ICustomDestinationList: %w", err)
	}
	defer comRelease(cdlPtr)

	aumidW, err := windows.UTF16PtrFromString("com.fleetkanban.desktop")
	if err != nil {
		return fmt.Errorf("winapi: ClearJumpList: encode AUMID: %w", err)
	}
	// DeleteList — vtable slot 10.
	if r1 := vtCall(cdlPtr, 10, uintptr(unsafe.Pointer(aumidW))); uint32(r1) != 0 {
		return fmt.Errorf("winapi: ICustomDestinationList::DeleteList: HRESULT 0x%08X", uint32(r1))
	}
	return nil
}

// addShellLinkToCollection creates a IShellLink, configures it from e, sets
// the System.Title property via IPropertyStore, then calls
// IObjectCollection::AddObject (vtable slot 5).
func addShellLinkToCollection(colPtr comObj, e jumpListEntry) error {
	slPtr, err := comCreate(&clsidShellLink, &iidShellLinkW)
	if err != nil {
		return fmt.Errorf("CoCreateInstance IShellLink: %w", err)
	}
	defer comRelease(slPtr)

	// SetPath — vtable slot 20.
	pathW, err := windows.UTF16PtrFromString(e.Path)
	if err != nil {
		return err
	}
	if r1 := vtCall(slPtr, 20, uintptr(unsafe.Pointer(pathW))); uint32(r1) != 0 {
		return fmt.Errorf("IShellLink::SetPath: HRESULT 0x%08X", uint32(r1))
	}

	// SetArguments — vtable slot 11.
	argsW, err := windows.UTF16PtrFromString(e.Args)
	if err != nil {
		return err
	}
	if r1 := vtCall(slPtr, 11, uintptr(unsafe.Pointer(argsW))); uint32(r1) != 0 {
		return fmt.Errorf("IShellLink::SetArguments: HRESULT 0x%08X", uint32(r1))
	}

	// SetDescription — vtable slot 7.
	descW, err := windows.UTF16PtrFromString(e.Description)
	if err != nil {
		return err
	}
	if r1 := vtCall(slPtr, 7, uintptr(unsafe.Pointer(descW))); uint32(r1) != 0 {
		return fmt.Errorf("IShellLink::SetDescription: HRESULT 0x%08X", uint32(r1))
	}

	// QueryInterface for IPropertyStore so we can set System.Title.
	psPtr, err := comQueryInterface(slPtr, &iidPropertyStore)
	if err != nil {
		return fmt.Errorf("QI IPropertyStore: %w", err)
	}
	defer comRelease(psPtr)

	titleW, err := windows.UTF16PtrFromString(e.Title)
	if err != nil {
		return err
	}
	pv := propVariant{
		vt:      vtLPWSTR,
		pwszVal: uintptr(unsafe.Pointer(titleW)),
	}
	// IPropertyStore::SetValue — vtable slot 6.
	if r1 := vtCall(psPtr, 6,
		uintptr(unsafe.Pointer(&pkeyTitle)),
		uintptr(unsafe.Pointer(&pv)),
	); uint32(r1) != 0 {
		return fmt.Errorf("IPropertyStore::SetValue(Title): HRESULT 0x%08X", uint32(r1))
	}
	// IPropertyStore::Commit — vtable slot 7.
	if r1 := vtCall(psPtr, 7); uint32(r1) != 0 {
		return fmt.Errorf("IPropertyStore::Commit: HRESULT 0x%08X", uint32(r1))
	}

	// IObjectCollection::AddObject — vtable slot 5.
	// We QueryInterface the IShellLink to IUnknown first (slot 0 identity).
	iidUnknown := windows.GUID{
		Data1: 0x00000000,
		Data2: 0x0000,
		Data3: 0x0000,
		Data4: [8]byte{0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46},
	}
	unkPtr, err := comQueryInterface(slPtr, &iidUnknown)
	if err != nil {
		return fmt.Errorf("QI IUnknown: %w", err)
	}
	defer comRelease(unkPtr)

	if r1 := vtCall(colPtr, 5, uintptr(unsafe.Pointer(unkPtr))); uint32(r1) != 0 {
		return fmt.Errorf("IObjectCollection::AddObject: HRESULT 0x%08X", uint32(r1))
	}
	return nil
}
