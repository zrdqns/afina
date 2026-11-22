BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    $script:balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
    $script:saver = 'a1841308-3541-4fab-bc81-f71556f20b4a'

    function Invoke-Apply([string]$Id, $Inventory) {
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id }
        $result = Invoke-AfCheck -Check $check -Inventory $Inventory
        $result.Detection.State | Should -Be 'Improvable' -Because "$Id debe salir mejorable con este inventario"
        $tx = New-AfTransaction -User $Inventory.User
        & $check.Apply $Inventory $result.Detection $tx
        $result
    }

    function New-FakeSecurity([hashtable]$Defender = @{}, [object[]]$Firewall, [object[]]$Antivirus) {
        $d = [ordered]@{ Available = $true; RealTime = $true; SignatureAgeDays = 0; TamperProtected = $true; PuaProtection = 1; Threats = @() }
        foreach ($k in $Defender.Keys) { $d[$k] = $Defender[$k] }
        if (-not $Firewall) { $Firewall = @('Domain', 'Private', 'Public') | ForEach-Object { [pscustomobject]@{ Profile = $_; Enabled = $true } } }
        if (-not $Antivirus) { $Antivirus = @([pscustomobject]@{ Name = 'Microsoft Defender Antivirus'; Enabled = $true; UpToDate = $true; IsDefender = $true }) }
        [pscustomobject]@{ Antivirus = $Antivirus; Defender = [pscustomobject]$d; Firewall = $Firewall; ThirdPartyFirewall = $false; HvciRunning = $false; VmPlatformEnabled = $false; UsesVirtualization = $false }
    }

    function New-StartupEntry([string]$Name) {
        [pscustomobject]@{
            Name = $Name; Command = "C:\Apps\$Name.exe"; Path = "C:\Apps\$Name.exe"; Source = 'Run'; Scope = 'User'; Enabled = $true
            ApprovedKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'; ApprovedName = $Name
            IsSigned = $true; Signer = $Name; InUserWritablePath = $false
        }
    }
}

Describe 'Contrato de Apply' {
    It 'toda revisión Auto tiene Apply y las demás no' {
        foreach ($check in Get-AfCatalog) {
            if ($check.Kind -eq 'Auto') { $check.Apply | Should -BeOfType [scriptblock] -Because $check.Id }
            else { $check.ContainsKey('Apply') | Should -BeFalse -Because $check.Id }
        }
        @(Get-AfCatalog | Where-Object { $_.Apply }).Count | Should -Be 23
    }
}

Describe 'Apply de cada revisión' {
    BeforeEach {
        Mock Set-AfRegistryValue { $true }
        Mock Set-AfActivePowerScheme { $true }
        Mock Set-AfPowerOverlay { $true }
        Mock Set-AfPowerSetting { $true }
        Mock Set-AfDisplayMode { $true }
        Mock Confirm-AfDisplayChange { }
        Mock Set-AfNetAdapterProperty { $true }
        Mock Disable-AfStartupEntry { $true }
        Mock Clear-AfTempFiles { }
        Mock Set-AfTrim { $true }
        Mock Enable-AfDefenderRealtime { }
        Mock Update-AfDefenderSignatures { }
        Mock Set-AfMpPreference { $true }
        Mock Set-AfFirewallProfile { $true }
    }

    It 'updates.windows instala lo que encontró la búsqueda' {
        Mock Find-AfWindowsUpdates { [pscustomobject]@{ Count = 1; Titles = @('KB1'); TimedOut = $false; Reason = $null } }
        Mock Install-AfWindowsUpdates { $true }
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq 'updates.windows' }
        $inv = New-AfFakeInventory
        $detection = & $check.AsyncDetect $inv
        $detection.State | Should -Be 'Improvable'
        & $check.Apply $inv $detection (New-AfTransaction -User $inv.User)
        Should -Invoke Install-AfWindowsUpdates -Times 1 -Exactly
    }

    It 'updates.windows dice por qué no pudo buscar' {
        Mock Find-AfWindowsUpdates { [pscustomobject]@{ Count = 0; Titles = @(); TimedOut = $false; Reason = 'el servicio de Windows Update está desactivado' } }
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq 'updates.windows' }
        $detection = & $check.AsyncDetect (New-AfFakeInventory)
        $detection.State | Should -Be 'Error'
        $detection.Note | Should -Be 'el servicio de Windows Update está desactivado'
    }

    It 'updates.apps ofrece cada app como opción y actualiza solo las elegidas' {
        Mock Get-AfWingetUpgrades {
            [pscustomobject]@{ Available = $true; TimedOut = $false; Apps = @(
                    [pscustomobject]@{ Name = 'Firefox'; Id = 'Mozilla.Firefox'; Version = '1'; Available = '2'; Source = 'winget' }
                    [pscustomobject]@{ Name = 'Discord'; Id = 'Discord.Discord'; Version = '1'; Available = '2'; Source = 'winget' }
                ) }
        }
        Mock Update-AfWingetApps { $true }
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq 'updates.apps' }
        $inv = New-AfFakeInventory
        $detection = & $check.AsyncDetect $inv
        $detection.State | Should -Be 'Improvable'
        $detection.Data.ChoicesLabel | Should -Be 'Apps'
        $detection.Data.Choices[0].Label | Should -Be 'Firefox (1 → 2)'
        $detection.Data.Choices[0].Preselected | Should -BeTrue
        $detection.Data.Choices[0].Selected | Should -BeFalse
        $detection.Data.Choices[1].Selected = $true
        & $check.Apply $inv $detection (New-AfTransaction -User $inv.User)
        Should -Invoke Update-AfWingetApps -Times 1 -Exactly -ParameterFilter { @($Apps).Count -eq 1 -and $Apps[0].Id -eq 'Discord.Discord' }
    }

    It 'energy.power-mode con plan Ahorro cambia el plan y el modo' {
        $inv = New-AfFakeInventory -Override @{ Power = [pscustomobject]@{ ActiveScheme = $script:saver; OverlayAc = $null; WifiPowerAc = 0 } }
        Invoke-Apply 'energy.power-mode' $inv | Out-Null
        Should -Invoke Set-AfActivePowerScheme -Times 1 -Exactly -ParameterFilter { $Guid -eq $script:balanced }
        Should -Invoke Set-AfPowerOverlay -Times 1 -Exactly -ParameterFilter { $Guid -eq 'ded574b5-45a0-4f42-8737-46345c09c238' }
    }

    It 'energy.power-mode con Equilibrado solo cambia el modo' {
        $inv = New-AfFakeInventory -Override @{ Power = [pscustomobject]@{ ActiveScheme = $script:balanced; OverlayAc = '00000000-0000-0000-0000-000000000000'; WifiPowerAc = 0 } }
        Invoke-Apply 'energy.power-mode' $inv | Out-Null
        Should -Invoke Set-AfActivePowerScheme -Times 0 -Exactly
        Should -Invoke Set-AfPowerOverlay -Times 1 -Exactly
    }

    It 'display.refresh lleva cada pantalla lenta a su máximo y pide confirmar' {
        $displays = @(
            [pscustomobject]@{ DeviceName = '\\.\DISPLAY1'; IsPrimary = $true; Width = 2560; Height = 1440; Hz = 165; MaxHzAtCurrentRes = 165; EdidMaxHz = $null; Modes = @() }
            [pscustomobject]@{ DeviceName = '\\.\DISPLAY2'; IsPrimary = $false; Width = 1920; Height = 1080; Hz = 60; MaxHzAtCurrentRes = 144; EdidMaxHz = $null; Modes = @() }
        )
        Invoke-Apply 'display.refresh' (New-AfFakeInventory -Override @{ Displays = $displays }) | Out-Null
        Should -Invoke Set-AfDisplayMode -Times 1 -Exactly -ParameterFilter { $DeviceName -eq '\\.\DISPLAY2' -and $Width -eq 1920 -and $Height -eq 1080 -and $Hz -eq 144 -and $Label -eq 'Pantalla 2' }
        Should -Invoke Confirm-AfDisplayChange -Times 1 -Exactly
    }

    It 'gpu.hags pone HwSchMode en 2' {
        Invoke-Apply 'gpu.hags' (New-AfFakeInventory -Override @{ Registry = @{ 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode' = 1 } }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -and $Name -eq 'HwSchMode' -and $Type -eq 'DWord' -and $Value -eq 2 }
    }

    It 'gaming.game-mode pone AutoGameModeEnabled en 1' {
        Invoke-Apply 'gaming.game-mode' (New-AfFakeInventory -Override @{ Registry = @{ 'HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled' = 0 } }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq 'HKCU:\Software\Microsoft\GameBar' -and $Name -eq 'AutoGameModeEnabled' -and $Value -eq 1 }
    }

    It 'gaming.background-recording pone HistoricalCaptureEnabled en 0' {
        Invoke-Apply 'gaming.background-recording' (New-AfFakeInventory -Override @{ Registry = @{ 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR|HistoricalCaptureEnabled' = 1 } }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Name -eq 'HistoricalCaptureEnabled' -and $Value -eq 0 }
    }

    It 'gaming.windowed-optimizations conserva VRROptimizeEnable=0;' {
        Mock Get-AfRegistryValue { 'VRROptimizeEnable=0;' } -ParameterFilter { $Name -eq 'DirectXUserGlobalSettings' }
        Invoke-Apply 'gaming.windowed-optimizations' (New-AfFakeInventory -Override @{ Registry = @{ 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences|DirectXUserGlobalSettings' = 'VRROptimizeEnable=0;' } }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Name -eq 'DirectXUserGlobalSettings' -and $Type -eq 'String' -and $Value -eq 'VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;' }
    }

    It 'Get-AfWindowedOptimizationsValue cambia SwapEffectUpgradeEnable=0 a 1 y agrega el punto y coma que falta' {
        Get-AfWindowedOptimizationsValue -Current 'SwapEffectUpgradeEnable=0;VRROptimizeEnable=1;' | Should -Be 'SwapEffectUpgradeEnable=1;VRROptimizeEnable=1;'
        Get-AfWindowedOptimizationsValue -Current 'VRROptimizeEnable=0' | Should -Be 'VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;'
        Get-AfWindowedOptimizationsValue -Current '' | Should -Be 'SwapEffectUpgradeEnable=1;'
    }

    It 'network.ethernet-power apaga cada opción de ahorro activa' {
        $nic = [pscustomobject]@{ Name = 'Ethernet'; Kind = 'Ethernet'; Description = 'Realtek PCIe GbE Family Controller'; Status = 'Up'; LinkSpeedMbps = 1000; MaxSpeedMbps = 1000; Properties = @{ '*EEE' = '1'; 'EnableGreenEthernet' = '1'; '*FlowControl' = '3' } }
        Invoke-Apply 'network.ethernet-power' (New-AfFakeInventory -Override @{ Network = @($nic) }) | Out-Null
        Should -Invoke Set-AfNetAdapterProperty -Times 2 -Exactly -ParameterFilter { $Adapter -eq 'Ethernet' -and $Value -eq '0' }
        Should -Invoke Set-AfNetAdapterProperty -Times 0 -Exactly -ParameterFilter { $Keyword -eq '*FlowControl' }
    }

    It 'network.wifi-power pone el ahorro del adaptador inalámbrico en 0 con cargador' {
        $wifi = [pscustomobject]@{ Name = 'Wi-Fi'; Kind = 'WiFi'; Description = 'Intel Wi-Fi 6'; Status = 'Up'; LinkSpeedMbps = 866; MaxSpeedMbps = 866; Properties = @{} }
        $inv = New-AfFakeInventory -Override @{ Network = @($wifi); Power = [pscustomobject]@{ ActiveScheme = $script:balanced; OverlayAc = 'ded574b5-45a0-4f42-8737-46345c09c238'; WifiPowerAc = 2 } }
        Invoke-Apply 'network.wifi-power' $inv | Out-Null
        Should -Invoke Set-AfPowerSetting -Times 1 -Exactly -ParameterFilter { $Subgroup -eq '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1' -and $Setting -eq '12bbebe6-58d6-4636-95bb-3217ef867c1a' -and $Ac -eq 0 }
    }

    It 'startup.apps solo desactiva los elegidos (Epic sí, Steam no)' {
        $inv = New-AfFakeInventory -Override @{ Startup = @((New-StartupEntry 'EpicGamesLauncher'), (New-StartupEntry 'Steam')) }
        $result = Invoke-Apply 'startup.apps' $inv
        @($result.Detection.Data.Choices).Count | Should -Be 2
        Should -Invoke Disable-AfStartupEntry -Times 1 -Exactly -ParameterFilter { $Entry.Name -eq 'EpicGamesLauncher' }
        Should -Invoke Disable-AfStartupEntry -Times 0 -Exactly -ParameterFilter { $Entry.Name -eq 'Steam' }
    }

    It 'startup.apps desactiva Steam si se eligió en el detalle' {
        $inv = New-AfFakeInventory -Override @{ Startup = @((New-StartupEntry 'EpicGamesLauncher'), (New-StartupEntry 'Steam')) }
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq 'startup.apps' }
        $result = Invoke-AfCheck -Check $check -Inventory $inv
        ($result.Detection.Data.Choices | Where-Object Name -eq 'Steam').Selected = $true
        & $check.Apply $inv $result.Detection (New-AfTransaction)
        Should -Invoke Disable-AfStartupEntry -Times 2 -Exactly
    }

    It 'storage.temp borra los temporales y storage.trim enciende TRIM' {
        $storage = [pscustomobject]@{
            SystemDrive = 'C:'; FreeGB = 200; SizeGB = 476; MediaType = 'SSD'; BusType = 'NVMe'; TrimEnabled = $false
            TempBytes = [pscustomobject]@{ User = 2GB; Windows = 0; UpdateCache = 0; DeliveryOptimization = 0; ErrorReports = 0 }
        }
        $inv = New-AfFakeInventory -Override @{ Storage = $storage }
        Invoke-Apply 'storage.temp' $inv | Out-Null
        Invoke-Apply 'storage.trim' $inv | Out-Null
        Should -Invoke Clear-AfTempFiles -Times 1 -Exactly
        Should -Invoke Set-AfTrim -Times 1 -Exactly -ParameterFilter { $Enabled }
    }

    It 'security.antivirus enciende la protección en tiempo real de Defender' {
        $av = @([pscustomobject]@{ Name = 'Microsoft Defender Antivirus'; Enabled = $false; UpToDate = $true; IsDefender = $true })
        Invoke-Apply 'security.antivirus' (New-AfFakeInventory -Override @{ Security = (New-FakeSecurity -Defender @{ RealTime = $false } -Antivirus $av) }) | Out-Null
        Should -Invoke Enable-AfDefenderRealtime -Times 1 -Exactly
    }

    It 'security.signatures descarga firmas, security.pua pone 1 y security.firewall activa el perfil apagado' {
        $firewall = @([pscustomobject]@{ Profile = 'Private'; Enabled = $true }, [pscustomobject]@{ Profile = 'Public'; Enabled = $false })
        $inv = New-AfFakeInventory -Override @{ Security = (New-FakeSecurity -Defender @{ SignatureAgeDays = 5; PuaProtection = 0 } -Firewall $firewall) }
        Invoke-Apply 'security.signatures' $inv | Out-Null
        Invoke-Apply 'security.pua' $inv | Out-Null
        Invoke-Apply 'security.firewall' $inv | Out-Null
        Should -Invoke Update-AfDefenderSignatures -Times 1 -Exactly
        Should -Invoke Set-AfMpPreference -Times 1 -Exactly -ParameterFilter { $Name -eq 'PUAProtection' -and $Value -eq 1 }
        Should -Invoke Set-AfFirewallProfile -Times 1 -Exactly -ParameterFilter { $Profile -eq 'Public' -and $Enabled }
    }

    It 'security.uac pone EnableLUA en 1' {
        Invoke-Apply 'security.uac' (New-AfFakeInventory -Override @{ Registry = @{ 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System|EnableLUA' = 0 } }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Name -eq 'EnableLUA' -and $Value -eq 1 -and $Path -like 'HKLM:*' }
    }
}
