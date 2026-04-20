# Find processes holding a file handle via Windows Restart Manager API.
# Works without SysInternals. Returns pid/name for each locker.
param([Parameter(Mandatory=$true)][string]$Path)

$code = @"
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;

public static class RestartManager {
    [StructLayout(LayoutKind.Sequential)]
    struct RM_UNIQUE_PROCESS {
        public int dwProcessId;
        public System.Runtime.InteropServices.ComTypes.FILETIME ProcessStartTime;
    }
    const int RmRebootReasonNone = 0;
    const int CCH_RM_MAX_APP_NAME = 255;
    const int CCH_RM_MAX_SVC_NAME = 63;
    enum RM_APP_TYPE {
        RmUnknownApp = 0, RmMainWindow = 1, RmOtherWindow = 2,
        RmService = 3, RmExplorer = 4, RmConsole = 5, RmCritical = 1000
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct RM_PROCESS_INFO {
        public RM_UNIQUE_PROCESS Process;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCH_RM_MAX_APP_NAME + 1)]
        public string strAppName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCH_RM_MAX_SVC_NAME + 1)]
        public string strServiceShortName;
        public RM_APP_TYPE ApplicationType;
        public uint AppStatus;
        public uint TSSessionId;
        [MarshalAs(UnmanagedType.Bool)] public bool bRestartable;
    }
    [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)]
    static extern int RmStartSession(out uint pSessionHandle, int dwSessionFlags, string strSessionKey);
    [DllImport("rstrtmgr.dll")]
    static extern int RmEndSession(uint pSessionHandle);
    [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)]
    static extern int RmRegisterResources(uint pSessionHandle, uint nFiles, string[] rgsFilenames,
        uint nApplications, [In] RM_UNIQUE_PROCESS[] rgApplications,
        uint nServices, string[] rgsServiceNames);
    [DllImport("rstrtmgr.dll")]
    static extern int RmGetList(uint dwSessionHandle, out uint pnProcInfoNeeded,
        ref uint pnProcInfo, [In, Out] RM_PROCESS_INFO[] rgAffectedApps, ref uint lpdwRebootReasons);

    public static List<string> WhoIsLocking(string path) {
        var results = new List<string>();
        uint session;
        string key = Guid.NewGuid().ToString();
        int rc = RmStartSession(out session, 0, key);
        if (rc != 0) { results.Add("RmStartSession rc=" + rc); return results; }
        try {
            string[] files = new[] { path };
            rc = RmRegisterResources(session, 1, files, 0, null, 0, null);
            if (rc != 0) { results.Add("RmRegisterResources rc=" + rc); return results; }
            uint procNeeded = 0, procCount = 0, rebootReasons = RmRebootReasonNone;
            rc = RmGetList(session, out procNeeded, ref procCount, null, ref rebootReasons);
            if (rc == 234 /* ERROR_MORE_DATA */) {
                var info = new RM_PROCESS_INFO[procNeeded];
                procCount = procNeeded;
                rc = RmGetList(session, out procNeeded, ref procCount, info, ref rebootReasons);
                if (rc == 0) {
                    for (int i = 0; i < procCount; i++) {
                        results.Add(info[i].Process.dwProcessId + "\t" + info[i].strAppName);
                    }
                } else { results.Add("RmGetList rc=" + rc); }
            } else if (rc != 0) {
                results.Add("RmGetList rc=" + rc);
            }
        } finally { RmEndSession(session); }
        return results;
    }
}
"@

Add-Type -TypeDefinition $code -Language CSharp | Out-Null
[RestartManager]::WhoIsLocking($Path) | ForEach-Object { Write-Output $_ }
