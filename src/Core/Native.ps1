$script:AfNativeReady = $null

function Initialize-AfNative {
    if ($null -ne $script:AfNativeReady) { return $script:AfNativeReady }
    if ('Afina.Native' -as [type]) { $script:AfNativeReady = $true; return $true }
    $source = @'
using System;
using System.Runtime.InteropServices;

namespace Afina {
    public static class Native {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct DISPLAY_DEVICE {
            public int cb;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
            public int StateFlags;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct DEVMODE {
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
            public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra;
            public int dmFields; public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput;
            public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
            public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight;
            public int dmDisplayFlags; public int dmDisplayFrequency; public int dmICMMethod; public int dmICMIntent;
            public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2;
            public int dmPanningWidth; public int dmPanningHeight;
        }

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        static extern int ChangeDisplaySettingsEx(string deviceName, ref DEVMODE devMode, IntPtr hwnd, uint flags, IntPtr param);

        [DllImport("powrprof.dll")]
        public static extern uint PowerGetEffectiveOverlayScheme(out Guid overlaySchemeGuid);

        [DllImport("powrprof.dll")]
        static extern uint PowerSetActiveOverlayScheme(Guid overlaySchemeGuid);

        // Windows 11: modo de energía "con cargador", aunque la PC esté en batería.
        [DllImport("powrprof.dll")]
        static extern uint PowerSetUserConfiguredACPowerMode(ref Guid powerModeGuid);

        [StructLayout(LayoutKind.Sequential)]
        public struct SYSTEM_POWER_STATUS {
            public byte ACLineStatus; public byte BatteryFlag; public byte BatteryLifePercent; public byte SystemStatusFlag;
            public int BatteryLifeTime; public int BatteryFullLifeTime;
        }

        [DllImport("kernel32.dll")]
        static extern bool GetSystemPowerStatus(out SYSTEM_POWER_STATUS status);

        // 1 = enchufado, 255 = desconocido (escritorios): los dos cuentan como con cargador.
        public static bool IsOnAcPower() {
            SYSTEM_POWER_STATUS status;
            if (!GetSystemPowerStatus(out status)) return true;
            return status.ACLineStatus != 0;
        }

        // 0 = hecho; 0xFFFFFFFF = en batería y sin la función de Windows 11; 0xFFFFFFFE = Windows no tiene modos de energía.
        public static uint SetAcOverlay(string guid) {
            Guid mode = new Guid(guid);
            bool onAc = IsOnAcPower();
            uint result = onAc ? 0xFFFFFFFE : 0xFFFFFFFF;
            if (onAc) {
                try { result = PowerSetActiveOverlayScheme(mode); } catch (EntryPointNotFoundException) { }
            }
            try {
                uint user = PowerSetUserConfiguredACPowerMode(ref mode);
                if (!onAc || result != 0) result = user;
            } catch (EntryPointNotFoundException) { }
            return result;
        }

        // Ratón y animaciones del área de cliente (SystemParametersInfo). Los Set guardan en el perfil y avisan a las ventanas.
        const uint SPI_GETMOUSE = 0x0003, SPI_SETMOUSE = 0x0004, SPI_GETCLIENTAREAANIMATION = 0x1042, SPI_SETCLIENTAREAANIMATION = 0x1043;
        const uint SPIF_UPDATEINIFILE = 0x01, SPIF_SENDCHANGE = 0x02;

        [DllImport("user32.dll", EntryPoint = "SystemParametersInfoW", SetLastError = true)]
        static extern bool SpiArray(uint action, uint param, int[] values, uint flags);

        [DllImport("user32.dll", EntryPoint = "SystemParametersInfoW", SetLastError = true)]
        static extern bool SpiGetInt(uint action, uint param, out int value, uint flags);

        [DllImport("user32.dll", EntryPoint = "SystemParametersInfoW", SetLastError = true)]
        static extern bool SpiSetPtr(uint action, uint param, IntPtr value, uint flags);

        // { umbral 1, umbral 2, aceleración }
        public static int[] GetMouseParams() {
            int[] values = new int[3];
            if (!SpiArray(SPI_GETMOUSE, 0, values, 0)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            return values;
        }

        public static bool SetMouseParams(int t1, int t2, int accel) {
            return SpiArray(SPI_SETMOUSE, 0, new int[] { t1, t2, accel }, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
        }

        public static bool GetClientAreaAnimation() {
            int value;
            if (!SpiGetInt(SPI_GETCLIENTAREAANIMATION, 0, out value, 0)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            return value != 0;
        }

        public static bool SetClientAreaAnimation(bool on) {
            return SpiSetPtr(SPI_SETCLIENTAREAANIMATION, 0, new IntPtr(on ? 1 : 0), SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
        }

        [DllImport("shell32.dll")]
        static extern void SHChangeNotify(int eventId, uint flags, IntPtr item1, IntPtr item2);

        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, UIntPtr wParam, string lParam, uint flags, uint timeout, out UIntPtr result);

        // Avisa al shell (asociaciones) y a todas las ventanas (WM_SETTINGCHANGE con el área), máximo 2 s por ventana.
        public static void NotifyShell(string area) {
            SHChangeNotify(0x08000000, 0, IntPtr.Zero, IntPtr.Zero);
            UIntPtr result;
            SendMessageTimeout(new IntPtr(0xFFFF), 0x001A, UIntPtr.Zero, area, 0x0002, 2000, out result);
        }

        public class DisplayMode { public int Width; public int Height; public int Hz; }

        public class DisplayInfo {
            public string DeviceName; public string MonitorCode; public bool IsPrimary; public int Width; public int Height; public int Hz;
            public DisplayMode[] Modes;
        }

        static DEVMODE NewDevMode() {
            DEVMODE mode = new DEVMODE();
            mode.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
            return mode;
        }

        // Los recorridos van en C#: PowerShell no pasa bien estructuras por referencia a P/Invoke.
        public static DisplayInfo[] GetDisplays() {
            var result = new System.Collections.Generic.List<DisplayInfo>();
            for (uint i = 0; ; i++) {
                DISPLAY_DEVICE device = new DISPLAY_DEVICE();
                device.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE));
                if (!EnumDisplayDevices(null, i, ref device, 0)) break;
                if ((device.StateFlags & 0x1) == 0) continue;

                DEVMODE current = NewDevMode();
                if (!EnumDisplaySettings(device.DeviceName, -1, ref current)) continue;

                var modes = new System.Collections.Generic.List<DisplayMode>();
                DEVMODE mode = NewDevMode();
                for (int m = 0; EnumDisplaySettings(device.DeviceName, m, ref mode); m++) {
                    if (mode.dmBitsPerPel == 32) {
                        modes.Add(new DisplayMode { Width = mode.dmPelsWidth, Height = mode.dmPelsHeight, Hz = mode.dmDisplayFrequency });
                    }
                    mode = NewDevMode();
                }

                // Código del monitor (p. ej. BOE0A1B en MONITOR\BOE0A1B\{...}\0001), para cruzarlo con el EDID de WMI.
                string monitorCode = null;
                DISPLAY_DEVICE monitor = new DISPLAY_DEVICE();
                monitor.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE));
                if (EnumDisplayDevices(device.DeviceName, 0, ref monitor, 0) && monitor.DeviceID != null) {
                    string[] parts = monitor.DeviceID.Split('\\');
                    if (parts.Length > 1) monitorCode = parts[1];
                }

                result.Add(new DisplayInfo {
                    DeviceName = device.DeviceName, MonitorCode = monitorCode, IsPrimary = (device.StateFlags & 0x4) != 0,
                    Width = current.dmPelsWidth, Height = current.dmPelsHeight, Hz = current.dmDisplayFrequency,
                    Modes = modes.ToArray()
                });
            }
            return result.ToArray();
        }

        public static DisplayMode GetCurrentMode(string device) {
            DEVMODE mode = NewDevMode();
            if (!EnumDisplaySettings(device, -1, ref mode)) return null;
            return new DisplayMode { Width = mode.dmPelsWidth, Height = mode.dmPelsHeight, Hz = mode.dmDisplayFrequency };
        }

        // Primero prueba el modo (CDS_TEST) y después lo guarda (CDS_UPDATEREGISTRY). 0 = hecho.
        public static int ChangeMode(string device, int width, int height, int hz) {
            DEVMODE mode = NewDevMode();
            if (!EnumDisplaySettings(device, -1, ref mode)) return -1;
            mode.dmPelsWidth = width;
            mode.dmPelsHeight = height;
            mode.dmDisplayFrequency = hz;
            mode.dmFields = 0x80000 | 0x100000 | 0x400000;
            int test = ChangeDisplaySettingsEx(device, ref mode, IntPtr.Zero, 0x02, IntPtr.Zero);
            if (test != 0) return test;
            return ChangeDisplaySettingsEx(device, ref mode, IntPtr.Zero, 0x01, IntPtr.Zero);
        }

        public static string GetEffectiveOverlay() {
            try {
                Guid guid;
                return PowerGetEffectiveOverlayScheme(out guid) == 0 ? guid.ToString() : null;
            } catch (EntryPointNotFoundException) {
                return null;
            }
        }

        [DllImport("kernel32.dll")] static extern bool GetFirmwareType(out int type);

        // 1 = BIOS heredado, 2 = UEFI, 0 = no se sabe.
        public static int FirmwareType() {
            int type;
            try { return GetFirmwareType(out type) ? type : 0; } catch (EntryPointNotFoundException) { return 0; }
        }

        [DllImport("cfgmgr32.dll", CharSet = CharSet.Unicode)] static extern int CM_Locate_DevNodeW(out uint devInst, string deviceId, uint flags);
        [DllImport("cfgmgr32.dll")] static extern int CM_Get_First_Log_Conf(out IntPtr logConf, uint devInst, uint flags);
        [DllImport("cfgmgr32.dll")] static extern int CM_Get_Next_Res_Des(out IntPtr next, IntPtr current, uint forResource, out uint resourceId, uint flags);
        [DllImport("cfgmgr32.dll")] static extern int CM_Get_Res_Des_Data_Size(out uint size, IntPtr resDes, uint flags);
        [DllImport("cfgmgr32.dll")] static extern int CM_Get_Res_Des_Data(IntPtr resDes, byte[] buffer, uint length, uint flags);
        [DllImport("cfgmgr32.dll")] static extern int CM_Free_Res_Des_Handle(IntPtr resDes);
        [DllImport("cfgmgr32.dll")] static extern int CM_Free_Log_Conf_Handle(IntPtr logConf);

        // Ventana de memoria más grande que Windows le asignó a un dispositivo PCI, en MB (-1 si no se pudo leer).
        // Recorre la configuración asignada (2): memoria (1) y memoria grande, la de más de 4 GB (7). Base y fin están en los bytes 8 y 16.
        public static long LargestWindowMB(string instanceId) {
            uint dev;
            if (CM_Locate_DevNodeW(out dev, instanceId, 0) != 0) return -1;
            IntPtr conf;
            if (CM_Get_First_Log_Conf(out conf, dev, 2) != 0) return -1;
            ulong largest = 0;
            try {
                foreach (uint type in new uint[] { 1, 7 }) {
                    IntPtr current = conf, next;
                    uint id;
                    while (CM_Get_Next_Res_Des(out next, current, type, out id, 0) == 0) {
                        if (current != conf) CM_Free_Res_Des_Handle(current);
                        current = next;
                        uint size;
                        if (CM_Get_Res_Des_Data_Size(out size, current, 0) != 0 || size < 24) continue;
                        byte[] data = new byte[size];
                        if (CM_Get_Res_Des_Data(current, data, size, 0) != 0) continue;
                        ulong start = BitConverter.ToUInt64(data, 8), end = BitConverter.ToUInt64(data, 16);
                        if (end > start && end - start + 1 > largest) largest = end - start + 1;
                    }
                    if (current != conf) CM_Free_Res_Des_Handle(current);
                }
            } finally {
                CM_Free_Log_Conf_Handle(conf);
            }
            return (long)(largest / (1024 * 1024));
        }
    }
}
'@
    try {
        Add-Type -TypeDefinition $source -ErrorAction Stop
        $script:AfNativeReady = $true
    } catch {
        Write-AfLog -Level Warn -Message "No se pudo compilar el código nativo: $($_.Exception.Message)"
        $script:AfNativeReady = $false
    }
    $script:AfNativeReady
}

function Get-AfDisplayModes {
    if (-not (Initialize-AfNative)) { return @() }
    foreach ($display in [Afina.Native]::GetDisplays()) {
        [pscustomobject]@{
            DeviceName = $display.DeviceName
            MonitorCode = $display.MonitorCode
            IsPrimary = $display.IsPrimary
            Width = $display.Width
            Height = $display.Height
            Hz = $display.Hz
            Modes = @($display.Modes | ForEach-Object { [pscustomobject]@{ Width = $_.Width; Height = $_.Height; Hz = $_.Hz } })
        }
    }
}

function Get-AfCurrentDisplayMode {
    param([Parameter(Mandatory)][string]$DeviceName)
    if (-not (Initialize-AfNative)) { return $null }
    $mode = [Afina.Native]::GetCurrentMode($DeviceName)
    if ($mode) { [pscustomobject]@{ Width = $mode.Width; Height = $mode.Height; Hz = $mode.Hz } }
}

function Invoke-AfDisplayModeChange {
    param([Parameter(Mandatory)][string]$DeviceName, [int]$Width, [int]$Height, [int]$Hz)
    if (-not (Initialize-AfNative)) { return -1 }
    [Afina.Native]::ChangeMode($DeviceName, $Width, $Height, $Hz)
}

# Con Resizable BAR la ventana de la gráfica es casi toda su memoria; sin él, 256 MB. $null si no se pudo leer.
function Get-AfGpuWindowMB {
    param([string]$PnpId)
    if (-not $PnpId -or -not (Initialize-AfNative)) { return $null }
    $mb = [Afina.Native]::LargestWindowMB($PnpId)
    if ($mb -ge 0) { $mb }
}

# 'UEFI', 'BIOS' (modo heredado) o $null si no se sabe.
function Get-AfFirmwareType {
    if (-not (Initialize-AfNative)) { return $null }
    switch ([Afina.Native]::FirmwareType()) { 1 { 'BIOS' } 2 { 'UEFI' } default { $null } }
}

function Test-AfOnAcPower {
    if (-not (Initialize-AfNative)) { return $true }
    [Afina.Native]::IsOnAcPower()
}

function Invoke-AfSetAcOverlay {
    param([Parameter(Mandatory)][string]$Guid)
    if (-not (Initialize-AfNative)) { return [uint32]4294967294 }
    [Afina.Native]::SetAcOverlay($Guid)
}

# Modo de energía con cargador. El registro da el de CA en concreto; la API, el de la fuente actual.
function Get-AfPowerOverlay {
    $value = Get-AfRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActiveOverlayAcPowerScheme'
    if ($value) { return ([string]$value).ToLowerInvariant() }
    if (-not (Initialize-AfNative)) { return $null }
    [Afina.Native]::GetEffectiveOverlay()
}
