BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:samples = Join-Path $PSScriptRoot 'Samples'
}

Describe 'Get-AfSystemInfo' {
    It 'marca Windows 11 desde la build 22000 e Insider si hay BranchName' {
        Mock Get-CimInstance { [pscustomobject]@{ Caption = 'Microsoft Windows 11 Pro'; BuildNumber = '26300' } } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
        Mock Get-AfRegistryValue { 'Canary' } -ParameterFilter { $Name -eq 'BranchName' }
        Mock Get-AfRegistryValue { 'Professional' } -ParameterFilter { $Name -eq 'EditionID' }
        $s = Get-AfSystemInfo
        $s.Build | Should -Be 26300
        $s.IsWin11 | Should -BeTrue
        $s.IsInsider | Should -BeTrue
        $s.Edition | Should -Be 'Professional'
    }

    It 'Windows 10 no es Windows 11' {
        Mock Get-CimInstance { [pscustomobject]@{ Caption = 'Microsoft Windows 10 Home'; BuildNumber = '19045' } } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
        Mock Get-AfRegistryValue { $null }
        (Get-AfSystemInfo).IsWin11 | Should -BeFalse
    }
}

Describe 'Get-AfDeviceInfo' {
    BeforeEach {
        Mock Get-CimInstance { [pscustomobject]@{ Manufacturer = 'LENOVO'; Model = '83DV' } } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' }
        Mock Get-CimInstance { [pscustomobject]@{ Version = 'LOQ 15IAX9' } } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystemProduct' }
    }

    It 'IsLaptop con chasis 10' {
        Mock Get-CimInstance { [pscustomobject]@{ ChassisTypes = @(10) } } -ParameterFilter { $ClassName -eq 'Win32_SystemEnclosure' }
        Mock Get-CimInstance { } -ParameterFilter { $ClassName -eq 'Win32_Battery' }
        $d = Get-AfDeviceInfo
        $d.IsLaptop | Should -BeTrue
        $d.Model | Should -Be 'LOQ 15IAX9'
    }

    It 'IsLaptop con batería y chasis 3' {
        Mock Get-CimInstance { [pscustomobject]@{ ChassisTypes = @(3) } } -ParameterFilter { $ClassName -eq 'Win32_SystemEnclosure' }
        Mock Get-CimInstance { [pscustomobject]@{ BatteryStatus = 2 } } -ParameterFilter { $ClassName -eq 'Win32_Battery' }
        $d = Get-AfDeviceInfo
        $d.IsLaptop | Should -BeTrue
        $d.OnBattery | Should -BeFalse
    }

    It 'OnBattery si BatteryStatus es 1' {
        Mock Get-CimInstance { [pscustomobject]@{ ChassisTypes = @(10) } } -ParameterFilter { $ClassName -eq 'Win32_SystemEnclosure' }
        Mock Get-CimInstance { [pscustomobject]@{ BatteryStatus = 1 } } -ParameterFilter { $ClassName -eq 'Win32_Battery' }
        (Get-AfDeviceInfo).OnBattery | Should -BeTrue
    }
}

Describe 'Get-AfGpuInfo' {
    BeforeEach {
        Mock Get-CimInstance { @(
                [pscustomobject]@{ Name = 'AMD Radeon(TM) Graphics'; AdapterCompatibility = 'Advanced Micro Devices, Inc.'; PNPDeviceID = 'PCI\VEN_1002&DEV_15BF&SUBSYS_3C1817AA&REV_C1\4&1'; InfFilename = 'oem45.inf'; DriverVersion = '31.0.24027.1012'; DriverDate = (Get-Date '2025-06-01') }
                [pscustomobject]@{ Name = 'NVIDIA GeForce RTX 4060 Laptop GPU'; AdapterCompatibility = 'NVIDIA'; PNPDeviceID = 'PCI\VEN_10DE&DEV_28E0&SUBSYS_3C1817AA&REV_A1\4&2'; InfFilename = 'oem50.inf'; DriverVersion = '32.0.15.6094'; DriverDate = (Get-Date '2025-09-01') }
                [pscustomobject]@{ Name = 'Microsoft Basic Display Adapter'; AdapterCompatibility = '(Standard display types)'; PNPDeviceID = 'ROOT\BASICDISPLAY\0000'; InfFilename = 'display.inf'; DriverVersion = '10.0.26100.1'; DriverDate = (Get-Date '2006-06-21') }
                [pscustomobject]@{ Name = 'Microsoft Hyper-V Video'; AdapterCompatibility = 'Microsoft Corporation'; PNPDeviceID = 'VMBUS\{DA0A7802-E377-4AAC-8E77-0558EB1073F8}\5620E0C7'; InfFilename = 'wvmbusvideo.inf'; DriverVersion = '10.0.26100.1'; DriverDate = (Get-Date '2006-06-21') }
                [pscustomobject]@{ Name = 'VMware SVGA 3D'; AdapterCompatibility = 'VMware, Inc.'; PNPDeviceID = 'PCI\VEN_15AD&DEV_0405&SUBSYS_040515AD&REV_00\3&1'; InfFilename = 'oem3.inf'; DriverVersion = '9.17.7.1'; DriverDate = (Get-Date '2024-01-01') }
                [pscustomobject]@{ Name = 'Adaptador de pantalla básico de Microsoft'; AdapterCompatibility = '(Adaptadores de pantalla estándar)'; PNPDeviceID = 'PCI\VEN_10DE&DEV_2504&SUBSYS_88C61043&REV_A1\4&3'; InfFilename = 'display.inf'; DriverVersion = '10.0.26100.1'; DriverDate = (Get-Date '2006-06-21') }
            ) } -ParameterFilter { $ClassName -eq 'Win32_VideoController' }
    }

    It 'RTX 4060 Laptop es dedicada y AMD Radeon(TM) Graphics no' {
        $g = @(Get-AfGpuInfo)
        $rtx = $g | Where-Object Name -match 'RTX'
        $rtx.IsDiscrete | Should -BeTrue
        $rtx.Vendor | Should -Be 'NVIDIA'
        $rtx.HasDriver | Should -BeTrue
        $rtx.WddmVersion | Should -Be 3.2
        ($g | Where-Object Name -match 'Radeon').IsDiscrete | Should -BeFalse
    }

    It 'ignora las gráficas virtuales y el adaptador básico sin gráfica física' {
        $names = @(Get-AfGpuInfo | ForEach-Object Name)
        $names | Should -Not -Contain 'Microsoft Basic Display Adapter'
        $names | Should -Not -Contain 'Microsoft Hyper-V Video'
        $names | Should -Not -Contain 'VMware SVGA 3D'
        $names.Count | Should -Be 3
    }

    It 'una gráfica física sin driver queda con HasDriver falso y su fabricante sale del PCI, en cualquier idioma' {
        $g = @(Get-AfGpuInfo | Where-Object Name -eq 'Adaptador de pantalla básico de Microsoft')[0]
        $g.HasDriver | Should -BeFalse
        $g.Vendor | Should -Be 'NVIDIA'
        $g.IsDiscrete | Should -BeTrue
    }
}

Describe 'Get-AfMemoryInfo' {
    It 'un solo SODIMM da Socketed y un módulo' {
        Mock Get-CimInstance { @([pscustomobject]@{ Capacity = 17179869184; Speed = 5600; ConfiguredClockSpeed = 5600; FormFactor = 12; PartNumber = 'M425R2GA3BB0-CWMOD '; DeviceLocator = 'DIMM 0' }) } -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' }
        $m = Get-AfMemoryInfo
        $m.TotalGB | Should -Be 16
        @($m.Modules).Count | Should -Be 1
        $m.Socketed | Should -BeTrue
        $m.Modules[0].PartNumber | Should -Be 'M425R2GA3BB0-CWMOD'
    }

    It 'la RAM soldada no es Socketed' {
        Mock Get-CimInstance { @([pscustomobject]@{ Capacity = 8589934592; Speed = 6400; ConfiguredClockSpeed = 6400; FormFactor = 0; PartNumber = 'LPDDR5'; DeviceLocator = 'Controller0-ChannelA' }) } -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' }
        (Get-AfMemoryInfo).Socketed | Should -BeFalse
    }
}

Describe 'Get-AfDisplayInfo' {
    It 'calcula los Hz máximos de la resolución actual y los del EDID del mismo monitor' {
        Mock Get-AfDisplayModes { @([pscustomobject]@{ DeviceName = '\\.\DISPLAY1'; MonitorCode = 'BOE0A1B'; IsPrimary = $true; Width = 1920; Height = 1080; Hz = 60; Modes = @(
                        [pscustomobject]@{ Width = 1920; Height = 1080; Hz = 60 }
                        [pscustomobject]@{ Width = 1920; Height = 1080; Hz = 144 }
                        [pscustomobject]@{ Width = 1280; Height = 720; Hz = 165 }) }) }
        Mock Get-CimInstance { @([pscustomobject]@{ InstanceName = 'DISPLAY\BOE0A1B\4&1a2b3c&0&UID265988_0'; MonitorSourceModes = @(
                        [pscustomobject]@{ VerticalRefreshRateNumerator = 60000; VerticalRefreshRateDenominator = 1000 }
                        [pscustomobject]@{ VerticalRefreshRateNumerator = 165000; VerticalRefreshRateDenominator = 1000 }) }) } -ParameterFilter { $ClassName -eq 'WmiMonitorListedSupportedSourceModes' }
        $d = @(Get-AfDisplayInfo)[0]
        $d.MaxHzAtCurrentRes | Should -Be 144
        $d.EdidMaxHz | Should -Be 165
    }
}

Describe 'Get-AfPowerInfo' {
    It 'lee plan, modo con cargador y ahorro del Wi-Fi' {
        $sample = [System.IO.File]::ReadAllText((Join-Path $script:samples 'powercfg-wifi-es.txt'), [System.Text.Encoding]::UTF8)
        Mock Get-AfRegistryValue { '381B4222-F694-41F0-9685-FF5BB260DF2E' } -ParameterFilter { $Name -eq 'ActivePowerScheme' }
        Mock Get-AfPowerOverlay { 'ded574b5-45a0-4f42-8737-46345c09c238' }
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 0; Output = $sample; TimedOut = $false } }
        $p = Get-AfPowerInfo
        $p.ActiveScheme | Should -Be '381b4222-f694-41f0-9685-ff5bb260df2e'
        $p.OverlayAc | Should -Be 'ded574b5-45a0-4f42-8737-46345c09c238'
        $p.WifiPowerAc | Should -Be 0
    }
}

Describe 'Get-AfVendorTools' {
    It 'detecta Lenovo Vantage por su servicio' {
        Mock Get-Service { @([pscustomobject]@{ Name = 'ImControllerService'; Status = 'Running' }) }
        Mock Get-Process { @() }
        Get-AfVendorTools | Should -Contain 'Lenovo Vantage'
    }

    It 'detecta G-Helper por su proceso' {
        Mock Get-Service { @() }
        Mock Get-Process { @([pscustomobject]@{ ProcessName = 'GHelper' }) }
        Get-AfVendorTools | Should -Contain 'G-Helper'
    }
}

Describe 'Get-AfNetworkInfo' {
    It 'solo incluye físicos de Ethernet y Wi-Fi y lee las claves' {
        Mock Get-NetAdapter { @(
                [pscustomobject]@{ Name = 'Ethernet'; InterfaceDescription = 'Realtek PCIe GbE Family Controller'; Status = 'Up'; PhysicalMediaType = '802.3'; ReceiveLinkSpeed = 1000000000 }
                [pscustomobject]@{ Name = 'Conexión de red Bluetooth'; InterfaceDescription = 'Bluetooth Device (Personal Area Network)'; Status = 'Disconnected'; PhysicalMediaType = 'BlueTooth'; ReceiveLinkSpeed = 3000000 }
            ) }
        Mock Get-NetAdapterAdvancedProperty { @(
                [pscustomobject]@{ RegistryKeyword = '*EEE'; RegistryValue = @('1') }
                [pscustomobject]@{ RegistryKeyword = '*SpeedDuplex'; RegistryValue = @('0'); ValidRegistryValues = @('0', '1', '2', '3', '4', '6') }
            ) }
        $n = @(Get-AfNetworkInfo)
        $n.Count | Should -Be 1
        $n[0].Kind | Should -Be 'Ethernet'
        $n[0].Properties['*EEE'] | Should -Be '1'
        $n[0].LinkSpeedMbps | Should -Be 1000
        $n[0].MaxSpeedMbps | Should -Be 1000
    }
}

Describe 'Get-AfWlanInfo' {
    It 'usa netsh y su lector' {
        $sample = [System.IO.File]::ReadAllText((Join-Path $script:samples 'netsh-wlan-es.txt'), [System.Text.Encoding]::UTF8)
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 0; Output = $sample; TimedOut = $false } }
        (Get-AfWlanInfo).BandGHz | Should -Be 5
    }
}

Describe 'Inventario real' -Tag 'Integration' {
    It 'Get-AfDisplayInfo da el código del monitor y los Hz de esta PC' {
        $d = @(Get-AfDisplayInfo)[0]
        $d.MonitorCode | Should -Not -BeNullOrEmpty
        $d.MaxHzAtCurrentRes | Should -BeGreaterOrEqual $d.Hz
    }
}
