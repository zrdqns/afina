# PCs muy distintas para las pruebas (antes vivían en Profiles.Tests.ps1). Requiere FakeInventory.ps1.
$script:AfBalanced = '381b4222-f694-41f0-9685-ff5bb260df2e'

function New-AfTestGpu([string]$Name, [string]$Vendor, [bool]$Discrete, [bool]$Driver = $true, [int]$Days = 30) {
    [pscustomobject]@{
        Name = $Name; Vendor = $Vendor; IsDiscrete = $Discrete; HasDriver = $Driver
        DriverVersion = $(if ($Driver) { '31.0.101.5000' } else { '10.0.26100.1' }); DriverDate = (Get-Date).AddDays(-$Days); WddmVersion = $(if ($Driver) { 3.1 } else { 1.0 })
    }
}

function New-AfTestDisplay([int]$Hz, [int]$Max, $Edid = $null) {
    [pscustomobject]@{ DeviceName = '\\.\DISPLAY1'; IsPrimary = $true; Width = 1920; Height = 1080; Hz = $Hz; MaxHzAtCurrentRes = $Max; EdidMaxHz = $Edid; Modes = @() }
}

function New-AfTestStorage([string]$Media, $Trim, [double]$FreeGB = 80, [long]$TempUser = 300MB) {
    [pscustomobject]@{ SystemDrive = 'C:'; FreeGB = $FreeGB; SizeGB = 240; MediaType = $Media; BusType = 'SATA'; TrimEnabled = $Trim
        TempBytes = [pscustomobject]@{ User = $TempUser; Windows = 0; UpdateCache = 0; DeliveryOptimization = 0; ErrorReports = 0 } }
}

function New-AfTestStartupEntry([string]$Name) {
    [pscustomobject]@{
        Name = $Name; Command = "C:\Apps\$Name.exe"; Path = "C:\Apps\$Name.exe"; Source = 'Run'; Scope = 'User'; Enabled = $true
        ApprovedKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'; ApprovedName = $Name
        IsSigned = $true; Signer = $Name; InUserWritablePath = $false
    }
}

function Get-AfProfileInventories {
    $profiles = [ordered]@{}
    $profiles.desktopIntel = New-AfFakeInventory -Override @{
        Os = [pscustomobject]@{ Caption = 'Microsoft Windows 10 Pro'; Build = 19045; Edition = 'Professional'; IsWin11 = $false; IsInsider = $false }
        Device = [pscustomobject]@{ Manufacturer = 'Dell Inc.'; Model = 'OptiPlex 7090'; IsLaptop = $false; OnBattery = $false }
        Cpu = [pscustomobject]@{ Name = 'Intel(R) Core(TM) i5-10500 CPU @ 3.10GHz'; Cores = 6; Threads = 12 }
        Gpus = @(New-AfTestGpu 'Intel(R) UHD Graphics 630' 'Intel' $false)
        Memory = [pscustomobject]@{ TotalGB = 8; Socketed = $true; Modules = @(
                [pscustomobject]@{ CapacityGB = 4; Speed = 2666; ConfiguredSpeed = 2666; FormFactor = 8; PartNumber = 'HMA851U6CJR6N-VK'; Locator = 'DIMM1' }
                [pscustomobject]@{ CapacityGB = 4; Speed = 2666; ConfiguredSpeed = 2666; FormFactor = 8; PartNumber = 'HMA851U6CJR6N-VK'; Locator = 'DIMM2' }) }
        Displays = @(New-AfTestDisplay 60 75 75)
        Power = [pscustomobject]@{ ActiveScheme = $script:AfBalanced; OverlayAc = $null; WifiPowerAc = $null }
        Network = @([pscustomobject]@{ Name = 'Ethernet'; Kind = 'Ethernet'; Description = 'Intel(R) Ethernet Connection (11) I219-LM'; Status = 'Up'; LinkSpeedMbps = 1000; MaxSpeedMbps = 1000; Properties = @{ '*EEE' = '1' } })
        Storage = New-AfTestStorage 'HDD' $null
    }
    $profiles.laptopApu = New-AfFakeInventory -Override @{
        Device = [pscustomobject]@{ Manufacturer = 'HP'; Model = 'HP Laptop 15-fc0xxx'; IsLaptop = $true; OnBattery = $true }
        Cpu = [pscustomobject]@{ Name = 'AMD Ryzen 5 7520U with Radeon Graphics'; Cores = 4; Threads = 8 }
        Gpus = @(New-AfTestGpu 'AMD Radeon(TM) Graphics' 'AMD' $false)
        Memory = [pscustomobject]@{ TotalGB = 8; Socketed = $false; Modules = @([pscustomobject]@{ CapacityGB = 8; Speed = 5500; ConfiguredSpeed = 5500; FormFactor = 0; PartNumber = 'MT62F1G32D2DS'; Locator = 'Onboard' }) }
        Network = @([pscustomobject]@{ Name = 'Wi-Fi'; Kind = 'WiFi'; Description = 'Realtek RTL8852BE WiFi 6'; Status = 'Up'; LinkSpeedMbps = 866; MaxSpeedMbps = 866; Properties = @{} })
        Power = [pscustomobject]@{ ActiveScheme = $script:AfBalanced; OverlayAc = '00000000-0000-0000-0000-000000000000'; WifiPowerAc = 2 }
    }
    $profiles.noDriver = New-AfFakeInventory -Override @{
        Device = [pscustomobject]@{ Manufacturer = 'ASUS'; Model = 'System Product Name'; IsLaptop = $false; OnBattery = $false }
        Gpus = @(New-AfTestGpu 'Adaptador de pantalla básico de Microsoft' 'NVIDIA' $true -Driver $false -Days 7000)
        Displays = @(New-AfTestDisplay 60 60 144)
    }
    $profiles.virtualMachine = New-AfFakeInventory -Override @{
        Device = [pscustomobject]@{ Manufacturer = 'Microsoft Corporation'; Model = 'Virtual Machine'; IsLaptop = $false; OnBattery = $false }
        Gpus = @()
        Memory = [pscustomobject]@{ TotalGB = 4; Socketed = $false; Modules = @() }
        Displays = @(New-AfTestDisplay 60 60 $null)
        Network = @()
        Storage = New-AfTestStorage 'Unspecified' $true
        Security = [pscustomobject]@{ Antivirus = @(); Defender = [pscustomobject]@{ Available = $false; RealTime = $null; SignatureAgeDays = $null; TamperProtected = $null; PuaProtection = $null; Threats = @() }
            Firewall = @(); ThirdPartyFirewall = $false; HvciRunning = $false; VmPlatformEnabled = $false; UsesVirtualization = $false }
    }
    # Cada parte del inventario falló (por ejemplo, WMI dañado): todo tiene que seguir sin romperse.
    $profiles.broken = New-AfFakeInventory -Override @{
        Os = $null; Device = $null; Cpu = $null; Gpus = $null; Memory = $null; Displays = $null; Power = $null; VendorTools = $null
        Network = $null; Wlan = $null; Security = $null; Apps = $null; Startup = $null; Autostart = $null; Storage = $null; Registry = @{}
    }
    $profiles
}

# Una PC con casi todo para mejorar: recorre la mayor cantidad de textos de las revisiones.
function New-AfDetunedInventory {
    $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    $registry = @{
        'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode' = 1
        'HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled' = 0
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR|HistoricalCaptureEnabled' = 1
        'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences|DirectXUserGlobalSettings' = 'VRROptimizeEnable=0;'
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System|EnableLUA' = 0
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection|AllowTelemetry' = 3
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy|TailoredExperiencesWithDiagnosticDataEnabled' = 1
        'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity|Enabled' = 1
        "$cdm|SilentInstalledAppsEnabled" = 1
    }
    New-AfFakeInventory -Override @{
        Device = [pscustomobject]@{ Manufacturer = 'ASUSTeK COMPUTER INC.'; Model = 'TUF Gaming F15'; IsLaptop = $true; OnBattery = $true }
        Gpus = @((New-AfTestGpu 'Intel(R) UHD Graphics' 'Intel' $false -Days 400), (New-AfTestGpu 'NVIDIA GeForce RTX 3050 Laptop GPU' 'NVIDIA' $true -Days 400))
        Memory = [pscustomobject]@{ TotalGB = 6; Socketed = $true; Modules = @([pscustomobject]@{ CapacityGB = 6; Speed = 3200; ConfiguredSpeed = 2400; FormFactor = 12; PartNumber = 'M471A1K43DB1-CWE'; Locator = 'DIMM 0' }) }
        Displays = @(New-AfTestDisplay 60 144 165)
        Power = [pscustomobject]@{ ActiveScheme = 'a1841308-3541-4fab-bc81-f71556f20b4a'; OverlayAc = $null; WifiPowerAc = 3 }
        VendorTools = @('Armoury Crate')
        Network = @(
            [pscustomobject]@{ Name = 'Ethernet'; Kind = 'Ethernet'; Description = 'Realtek PCIe GbE Family Controller'; Status = 'Up'; LinkSpeedMbps = 100; MaxSpeedMbps = 1000; Properties = @{ '*EEE' = '1'; 'EnableGreenEthernet' = '1' } }
            [pscustomobject]@{ Name = 'Wi-Fi'; Kind = 'WiFi'; Description = 'Intel(R) Wi-Fi 6 AX201'; Status = 'Up'; LinkSpeedMbps = 144; MaxSpeedMbps = 2400; Properties = @{} }
        )
        Wlan = [pscustomobject]@{ Connected = $true; BandGHz = 2.4; Channel = 6; Ssid = 'Casa' }
        Security = [pscustomobject]@{
            Antivirus = @([pscustomobject]@{ Name = 'Microsoft Defender Antivirus'; Enabled = $false; UpToDate = $false; IsDefender = $true })
            Defender = [pscustomobject]@{ Available = $true; RealTime = $false; SignatureAgeDays = 10; TamperProtected = $false; PuaProtection = 0
                Threats = @([pscustomobject]@{ Name = 'Trojan:Win32/Prueba'; Active = $true; Path = 'C:\Users\Cliente\AppData\Local\malo.exe' }) }
            Firewall = @([pscustomobject]@{ Profile = 'Domain'; Enabled = $true }, [pscustomobject]@{ Profile = 'Private'; Enabled = $false }, [pscustomobject]@{ Profile = 'Public'; Enabled = $false })
            ThirdPartyFirewall = $false; HvciRunning = $true; VmPlatform = [pscustomobject]@{ State = 'Enabled'; Pending = $false }; VmPlatformEnabled = $true; UsesVirtualization = $false
        }
        Apps = [pscustomobject]@{ Promo = @(
                [pscustomobject]@{ Name = 'TikTok'; PackageName = 'BytedancePte.Ltd.TikTok'; PackageFullName = 'BytedancePte.Ltd.TikTok_1'; PackageFamilyName = 'BytedancePte.Ltd.TikTok_6yccndn6064se'; StoreId = '9NH2GPH4JZS4'; Provisioned = $false }
                [pscustomobject]@{ Name = 'Candy Crush'; PackageName = 'king.com.CandyCrushSodaSaga'; PackageFullName = 'king.com.CandyCrushSodaSaga_1'; PackageFamilyName = 'king.com.CandyCrushSodaSaga_kgqvnymyfvs32'; StoreId = $null; Provisioned = $false }
            ) }
        Startup = @((New-AfTestStartupEntry 'EpicGamesLauncher'), (New-AfTestStartupEntry 'Steam'))
        Storage = New-AfTestStorage 'SSD' $false -FreeGB 12 -TempUser 3GB
        Registry = $registry
    }
}
