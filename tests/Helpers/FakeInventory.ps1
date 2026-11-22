# Inventario de mentira con la forma completa de Get-AfInventory (Task 9).
# Laptop Lenovo LOQ 15: Ryzen 7 7435HS + RTX 4060, Windows 11 24H2, 16 GB en un módulo.
# -Override reemplaza propiedades de primer nivel.
function New-AfFakeInventory {
    param([hashtable]$Override = @{})

    $inv = [ordered]@{
        User = [pscustomobject]@{ Name = 'LOQ\Cliente'; Sid = 'S-1-5-21-1'; ProfilePath = 'C:\Users\Cliente'; IsSameAsProcess = $true; HkcuRoot = 'HKCU:' }
        Os = [pscustomobject]@{ Caption = 'Microsoft Windows 11 Home'; Build = 26100; Edition = 'Core'; IsWin11 = $true; IsInsider = $false }
        Device = [pscustomobject]@{ Manufacturer = 'LENOVO'; Model = 'LOQ 15'; IsLaptop = $true; OnBattery = $false }
        Cpu = [pscustomobject]@{ Name = 'AMD Ryzen 7 7435HS'; Cores = 8; Threads = 16 }
        Gpus = @(
            [pscustomobject]@{ Name = 'AMD Radeon(TM) Graphics'; Vendor = 'AMD'; IsDiscrete = $false; HasDriver = $true; DriverVersion = '31.0.24027.1012'; DriverDate = (Get-Date).AddDays(-60); WddmVersion = 3.1 }
            [pscustomobject]@{ Name = 'NVIDIA GeForce RTX 4060 Laptop GPU'; Vendor = 'NVIDIA'; IsDiscrete = $true; HasDriver = $true; DriverVersion = '32.0.15.6094'; DriverDate = (Get-Date).AddDays(-30); WddmVersion = 3.2 }
        )
        Memory = [pscustomobject]@{
            TotalGB = 16; Socketed = $true
            Modules = @([pscustomobject]@{ CapacityGB = 16; Speed = 5600; ConfiguredSpeed = 5600; FormFactor = 12; PartNumber = 'M425R2GA3BB0-CWMOD'; Locator = 'DIMM 0' })
        }
        Displays = @([pscustomobject]@{ DeviceName = '\\.\DISPLAY1'; IsPrimary = $true; Width = 2560; Height = 1440; Hz = 165; MaxHzAtCurrentRes = 165; EdidMaxHz = 165; Modes = @() })
        Power = [pscustomobject]@{ ActiveScheme = '381b4222-f694-41f0-9685-ff5bb260df2e'; OverlayAc = 'ded574b5-45a0-4f42-8737-46345c09c238'; WifiPowerAc = 0 }
        VendorTools = @()
        Network = @([pscustomobject]@{ Name = 'Ethernet'; Kind = 'Ethernet'; Description = 'Realtek PCIe GbE Family Controller'; Status = 'Up'; LinkSpeedMbps = 1000; MaxSpeedMbps = 1000; Properties = @{ '*EEE' = '0' } })
        Wlan = [pscustomobject]@{ Connected = $false; BandGHz = $null; Channel = $null; Ssid = $null }
        Security = [pscustomobject]@{
            Antivirus = @([pscustomobject]@{ Name = 'Microsoft Defender Antivirus'; Enabled = $true; UpToDate = $true; IsDefender = $true })
            Defender = [pscustomobject]@{ Available = $true; RealTime = $true; SignatureAgeDays = 0; TamperProtected = $true; PuaProtection = 1; Threats = @() }
            Firewall = @(
                [pscustomobject]@{ Profile = 'Domain'; Enabled = $true }
                [pscustomobject]@{ Profile = 'Private'; Enabled = $true }
                [pscustomobject]@{ Profile = 'Public'; Enabled = $true }
            )
            ThirdPartyFirewall = $false; HvciRunning = $false; VmPlatform = [pscustomobject]@{ State = 'Disabled'; Pending = $false }; VmPlatformEnabled = $false; UsesVirtualization = $false
        }
        Apps = [pscustomobject]@{ Promo = @() }
        Startup = @()
        Autostart = @()
        Storage = [pscustomobject]@{
            SystemDrive = 'C:'; FreeGB = 200; SizeGB = 476; MediaType = 'SSD'; BusType = 'NVMe'; TrimEnabled = $true
            TempBytes = [pscustomobject]@{ User = 0; Windows = 0; UpdateCache = 0; DeliveryOptimization = 0; ErrorReports = 0 }
        }
        Registry = @{}
        Errors = @()
    }
    foreach ($key in $Override.Keys) { $inv[$key] = $Override[$key] }
    [pscustomobject]$inv
}
