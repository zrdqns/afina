BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:user = [pscustomobject]@{ Name = 'PC\Cliente'; Sid = 'S-1-5-21-1'; ProfilePath = 'C:\Users\Cliente'; IsSameAsProcess = $true; HkcuRoot = 'HKCU:' }
}

Describe 'Get-AfSecurityInfo' {
    BeforeEach {
        Mock Get-NetFirewallProfile { @([pscustomobject]@{ Name = 'Domain'; Enabled = $true }, [pscustomobject]@{ Name = 'Private'; Enabled = $true }, [pscustomobject]@{ Name = 'Public'; Enabled = $false }) }
        Mock Get-CimInstance { [pscustomobject]@{ SecurityServicesRunning = @(2) } } -ParameterFilter { $ClassName -eq 'Win32_DeviceGuard' }
        Mock Get-CimInstance { [pscustomobject]@{ InstallState = 2 } } -ParameterFilter { $ClassName -eq 'Win32_OptionalFeature' }
        Mock Get-MpThreat { @() }
        Mock Get-AfFeatureInfo { throw 'sin DISM en las pruebas' }
    }

    It 'lee VMP con DISM, incluido el reinicio pendiente' {
        Mock Get-CimInstance { @() } -ParameterFilter { $ClassName -in 'AntiVirusProduct', 'FirewallProduct' }
        Mock Get-MpComputerStatus { throw 'no hay Defender' }
        Mock Get-MpPreference { throw 'no hay Defender' }
        Mock Get-CimInstance { @([pscustomobject]@{ Name = 'VirtualMachinePlatform'; InstallState = 1 }) } -ParameterFilter { $ClassName -eq 'Win32_OptionalFeature' }
        Mock Get-AfFeatureInfo { [pscustomobject]@{ State = 'Disabled'; Pending = $true; Raw = 'Disable Pending' } }
        $s = Get-AfSecurityInfo -User $script:user
        $s.VmPlatform.State | Should -Be 'Disabled'
        $s.VmPlatform.Pending | Should -BeTrue
        $s.VmPlatformEnabled | Should -BeFalse
    }

    It 'si CIM ve VMP apagada no pregunta a DISM (tarda)' {
        Mock Get-CimInstance { @() } -ParameterFilter { $ClassName -in 'AntiVirusProduct', 'FirewallProduct' }
        Mock Get-MpComputerStatus { throw 'no hay Defender' }
        Mock Get-MpPreference { throw 'no hay Defender' }
        Mock Get-CimInstance { @([pscustomobject]@{ Name = 'VirtualMachinePlatform'; InstallState = 2 }) } -ParameterFilter { $ClassName -eq 'Win32_OptionalFeature' }
        $s = Get-AfSecurityInfo -User $script:user
        $s.VmPlatform.State | Should -Be 'Disabled'
        Should -Invoke Get-AfFeatureInfo -Times 0 -Exactly
    }

    It 'si DISM falla, VMP se lee con CIM' {
        Mock Get-CimInstance { @() } -ParameterFilter { $ClassName -in 'AntiVirusProduct', 'FirewallProduct' }
        Mock Get-MpComputerStatus { throw 'no hay Defender' }
        Mock Get-MpPreference { throw 'no hay Defender' }
        Mock Get-CimInstance { @([pscustomobject]@{ Name = 'VirtualMachinePlatform'; InstallState = 1 }) } -ParameterFilter { $ClassName -eq 'Win32_OptionalFeature' }
        $s = Get-AfSecurityInfo -User $script:user
        $s.VmPlatform.State | Should -Be 'Enabled'
        $s.VmPlatform.Pending | Should -BeFalse
        $s.VmPlatformEnabled | Should -BeTrue
    }

    It 'con Hyper-V activado cuenta como que usa virtualización' {
        Mock Get-CimInstance { @() } -ParameterFilter { $ClassName -in 'AntiVirusProduct', 'FirewallProduct' }
        Mock Get-MpComputerStatus { throw 'no hay Defender' }
        Mock Get-MpPreference { throw 'no hay Defender' }
        Mock Test-AfUsesVirtualization { $false }
        Mock Get-CimInstance { @([pscustomobject]@{ Name = 'Microsoft-Hyper-V-All'; InstallState = 1 }, [pscustomobject]@{ Name = 'VirtualMachinePlatform'; InstallState = 1 }) } -ParameterFilter { $ClassName -eq 'Win32_OptionalFeature' }
        (Get-AfSecurityInfo -User $script:user).UsesVirtualization | Should -BeTrue
    }

    It 'un antivirus de terceros activo se marca IsDefender = $false' {
        Mock Get-CimInstance { @(
                [pscustomobject]@{ displayName = 'ESET Security'; productState = 266240 }
                [pscustomobject]@{ displayName = 'Windows Defender'; productState = 393472 }
            ) } -ParameterFilter { $ClassName -eq 'AntiVirusProduct' }
        Mock Get-MpComputerStatus { throw 'Defender en modo pasivo' }
        Mock Get-MpPreference { throw 'Defender en modo pasivo' }
        $s = Get-AfSecurityInfo -User $script:user
        $eset = $s.Antivirus | Where-Object Name -eq 'ESET Security'
        $eset.IsDefender | Should -BeFalse
        $eset.Enabled | Should -BeTrue
        ($s.Antivirus | Where-Object Name -eq 'Windows Defender').IsDefender | Should -BeTrue
    }

    It 'Defender no disponible deja Available = $false sin lanzar error' {
        Mock Get-CimInstance { @() } -ParameterFilter { $ClassName -eq 'AntiVirusProduct' }
        Mock Get-MpComputerStatus { throw 'no hay Defender' }
        Mock Get-MpPreference { throw 'no hay Defender' }
        { $script:s = Get-AfSecurityInfo -User $script:user } | Should -Not -Throw
        $script:s.Defender.Available | Should -BeFalse
    }

    It 'lee firmas, tiempo real, PUA, amenazas, firewall, HVCI y VM Platform' {
        Mock Get-CimInstance { @([pscustomobject]@{ displayName = 'Windows Defender'; productState = 397568 }) } -ParameterFilter { $ClassName -eq 'AntiVirusProduct' }
        Mock Get-MpComputerStatus { [pscustomobject]@{ AMServiceEnabled = $true; RealTimeProtectionEnabled = $true; AntivirusSignatureAge = 5; IsTamperProtected = $true } }
        Mock Get-MpPreference { [pscustomobject]@{ PUAProtection = 0 } }
        Mock Get-MpThreat { @([pscustomobject]@{ ThreatName = 'Trojan:Win32/Prueba'; IsActive = $true; Resources = @('file:_C:\Users\Cliente\AppData\Local\malo.exe') }) }
        $s = Get-AfSecurityInfo -User $script:user
        $s.Defender.Available | Should -BeTrue
        $s.Defender.SignatureAgeDays | Should -Be 5
        $s.Defender.PuaProtection | Should -Be 0
        $s.Defender.Threats[0].Name | Should -Be 'Trojan:Win32/Prueba'
        $s.Defender.Threats[0].Active | Should -BeTrue
        $s.Defender.Threats[0].Path | Should -Be 'C:\Users\Cliente\AppData\Local\malo.exe'
        ($s.Firewall | Where-Object Profile -eq 'Public').Enabled | Should -BeFalse
        $s.HvciRunning | Should -BeTrue
        $s.VmPlatformEnabled | Should -BeFalse
    }
}

Describe 'Get-AfStartupEntries' {
    BeforeEach {
        Mock Get-AfRunValues { @(
                [pscustomobject]@{ Name = 'EpicGamesLauncher'; Command = '"C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe" -silent'; Scope = 'User'; ApprovedPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' }
                [pscustomobject]@{ Name = 'Updater'; Command = 'C:\Users\Cliente\AppData\Roaming\upd\upd.exe /bg'; Scope = 'User'; ApprovedPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' }
            ) }
        Mock Get-AfStartupFolderItems { @() }
        Mock Get-AfRegistryValue { $null }
        Mock Get-AfRegistryValue { [byte[]](3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) } -ParameterFilter { $Name -eq 'EpicGamesLauncher' }
        Mock Get-AfFileSignature { [pscustomobject]@{ IsSigned = $true; Signer = 'Epic Games Inc.' } }
    }

    It 'una entrada de Run desactivada en StartupApproved (primer byte 3) sale Enabled = $false' {
        $e = @(Get-AfStartupEntries -User $script:user) | Where-Object Name -eq 'EpicGamesLauncher'
        $e.Enabled | Should -BeFalse
        $e.Path | Should -Be 'C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe'
    }

    It 'una ruta en AppData sale InUserWritablePath y sin aprobar queda Enabled' {
        $e = @(Get-AfStartupEntries -User $script:user) | Where-Object Name -eq 'Updater'
        $e.InUserWritablePath | Should -BeTrue
        $e.Enabled | Should -BeTrue
        $e.Path | Should -Be 'C:\Users\Cliente\AppData\Roaming\upd\upd.exe'
    }
}

Describe 'Get-AfStorageInfo' {
    It 'TempBytes suma los tamaños de cada carpeta' {
        Mock Get-CimInstance { [pscustomobject]@{ DeviceID = 'C:'; FreeSpace = 64424509440; Size = 511101108224 } } -ParameterFilter { $ClassName -eq 'Win32_LogicalDisk' }
        Mock Get-AfSystemDiskType { [pscustomobject]@{ MediaType = 'SSD'; BusType = 'NVMe' } }
        Mock Get-AfFolderBytes { 1073741824 }
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 0; Output = 'NTFS DisableDeleteNotify = 0'; TimedOut = $false } }
        $s = Get-AfStorageInfo -User $script:user
        $s.FreeGB | Should -Be 60
        $s.TempBytes.User | Should -Be 1073741824
        $s.TempBytes.ErrorReports | Should -Be 2147483648
        $s.TrimEnabled | Should -BeTrue
    }
}

Describe 'Get-AfFolderBytes' {
    It 'suma los archivos de una carpeta y sus subcarpetas' {
        $dir = Join-Path $TestDrive 'temp'
        New-Item -ItemType Directory -Force (Join-Path $dir 'sub') | Out-Null
        [System.IO.File]::WriteAllBytes((Join-Path $dir 'a.bin'), (New-Object byte[] 100))
        [System.IO.File]::WriteAllBytes((Join-Path $dir 'sub\b.bin'), (New-Object byte[] 50))
        Get-AfFolderBytes -Path $dir | Should -Be 150
    }

    It 'da 0 si la carpeta no existe' {
        Get-AfFolderBytes -Path (Join-Path $TestDrive 'no-existe') | Should -Be 0
    }

    It 'no lanza error en la caché de NetworkService, que un usuario normal no puede abrir' -Skip:(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $path = Join-Path $env:windir 'ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache'
        { $script:bytes = Get-AfFolderBytes -Path $path } | Should -Not -Throw
        $script:bytes | Should -Be 0
    }
}

Describe 'Get-AfWingetUpgrades' {
    It 'marca no disponible si winget no existe' {
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'winget' }
        (Get-AfWingetUpgrades).Available | Should -BeFalse
    }
}
