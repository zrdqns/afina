BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
}

Describe 'Test-AfPolicyEdition' {
    It 'es falso en Home' {
        foreach ($e in 'Core', 'CoreSingleLanguage', 'CoreCountrySpecific') { Test-AfPolicyEdition -Os ([pscustomobject]@{ Edition = $e }) | Should -BeFalse }
    }
    It 'es verdadero en Pro y Enterprise' {
        foreach ($e in 'Professional', 'Enterprise') { Test-AfPolicyEdition -Os ([pscustomobject]@{ Edition = $e }) | Should -BeTrue }
    }
}

Describe 'Test-AfEnterpriseEdition' {
    It 'distingue las ediciones de organización' {
        Test-AfEnterpriseEdition -Os ([pscustomobject]@{ Edition = 'Professional' }) | Should -BeFalse
        foreach ($e in 'Enterprise', 'Education', 'IoTEnterprise') { Test-AfEnterpriseEdition -Os ([pscustomobject]@{ Edition = $e }) | Should -BeTrue }
    }
}

Describe 'Test-AfBatteryPercentBuild' {
    It 'decide por build y revisión: <Build>.<Ubr>' -ForEach @(
        @{ Build = 26100; Ubr = 7018; Expected = $false }
        @{ Build = 26100; Ubr = 7019; Expected = $true }
        @{ Build = 26200; Ubr = 7019; Expected = $true }
        @{ Build = 26120; Ubr = 9000; Expected = $false }
        @{ Build = 26300; Ubr = 1; Expected = $true }
        @{ Build = 22631; Ubr = 9999; Expected = $false }
    ) {
        Test-AfBatteryPercentBuild -Os ([pscustomobject]@{ Build = $Build; Ubr = $Ubr }) | Should -Be $Expected
    }
}

Describe 'Test-AfLowDisk' {
    It 'avisa con menos de 20 GB o menos del 15 % libre: <Free> de <Size>' -ForEach @(
        @{ Free = 19; Size = 476; Expected = $true }
        @{ Free = 20; Size = 100; Expected = $false }
        @{ Free = 25; Size = 200; Expected = $true }
    ) {
        Test-AfLowDisk -Storage ([pscustomobject]@{ FreeGB = $Free; SizeGB = $Size }) | Should -Be $Expected
    }
}

Describe 'Get-AfEdgeInfo' {
    BeforeEach {
        $script:mySession = [Diagnostics.Process]::GetCurrentProcess().SessionId
    }
    It 'procesos sin ventana cuentan como en ejecución pero sin ventana' {
        Mock Get-Process { @([pscustomobject]@{ SessionId = $script:mySession; MainWindowHandle = [IntPtr]::Zero }) }
        $e = Get-AfEdgeInfo
        $e.Running | Should -BeTrue
        $e.HasWindow | Should -BeFalse
    }
    It 'detecta la ventana' {
        Mock Get-Process { @([pscustomobject]@{ SessionId = $script:mySession; MainWindowHandle = [IntPtr]123 }) }
        (Get-AfEdgeInfo).HasWindow | Should -BeTrue
    }
    It 'ignora los procesos de otra sesión' {
        Mock Get-Process { @([pscustomobject]@{ SessionId = $script:mySession + 5; MainWindowHandle = [IntPtr]123 }) }
        $e = Get-AfEdgeInfo
        $e.Running | Should -BeFalse
        $e.HasWindow | Should -BeFalse
    }
}

Describe 'Get-AfDeliveryOptimizationInfo' {
    It 'sin el cmdlet: Available falso, sin lanzar' {
        Mock Get-DOConfig { throw 'no existe' }
        $d = Get-AfDeliveryOptimizationInfo
        $d.Available | Should -BeFalse
    }
    It 'con el cmdlet devuelve el modo' {
        Mock Get-DOConfig { [pscustomobject]@{ DownloadMode = 'Lan' } }
        $d = Get-AfDeliveryOptimizationInfo
        $d.Available | Should -BeTrue
        $d.Mode | Should -Be 'Lan'
    }
}

Describe 'Get-AfPagefileInfo' {
    It 'lee el tamaño máximo de cada archivo' {
        Mock Get-CimInstance { [pscustomobject]@{ AutomaticManagedPagefile = $false } } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' }
        Mock Get-CimInstance { [pscustomobject]@{ Name = 'C:\pagefile.sys'; MaximumSize = 4096 } } -ParameterFilter { $ClassName -eq 'Win32_PageFileSetting' }
        $p = Get-AfPagefileInfo
        $p.Automatic | Should -BeFalse
        @($p.Files)[0].MaxMB | Should -Be 4096
    }
}

Describe 'Get-AfPagefileInfo con fallos de lectura' {
    It 'lanza si falla Win32_ComputerSystem' {
        Mock Get-CimInstance { Write-Error 'falla a propósito' } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' }
        Mock Get-CimInstance { @() } -ParameterFilter { $ClassName -eq 'Win32_PageFileSetting' }
        # Como en la app: los errores no terminantes solo paran si la llamada pide Stop.
        $ErrorActionPreference = 'Continue'
        { Get-AfPagefileInfo } | Should -Throw
    }
    It 'lanza si falla Win32_PageFileSetting' {
        Mock Get-CimInstance { [pscustomobject]@{ AutomaticManagedPagefile = $true } } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' }
        Mock Get-CimInstance { Write-Error 'falla a propósito' } -ParameterFilter { $ClassName -eq 'Win32_PageFileSetting' }
        { Get-AfPagefileInfo } | Should -Throw
    }
    It 'sin instancias de Win32_PageFileSetting no es un fallo' {
        Mock Get-CimInstance { [pscustomobject]@{ AutomaticManagedPagefile = $true } } -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' }
        Mock Get-CimInstance { @() } -ParameterFilter { $ClassName -eq 'Win32_PageFileSetting' }
        $p = Get-AfPagefileInfo
        $p.Automatic | Should -BeTrue
        @($p.Files).Count | Should -Be 0
    }
}

Describe 'Get-AfEffectsInfo' {
    It 'lee la animación de ventanas' {
        Mock Get-AfSystemParameterValue { $true }
        (Get-AfEffectsInfo).ClientAreaAnimation | Should -BeTrue
    }
}

Describe 'Get-AfPromoApps con Copilot' {
    It 'Copilot lleva su StoreId y Widgets se detecta sin entrar en Promo' {
        Mock Get-AppxPackage {
            @(
                [pscustomobject]@{ Name = 'Microsoft.Copilot'; PackageFullName = 'Microsoft.Copilot_1_x64__8wekyb3d8bbwe'; PackageFamilyName = 'Microsoft.Copilot_8wekyb3d8bbwe' }
                [pscustomobject]@{ Name = 'MicrosoftWindows.Client.WebExperience'; PackageFullName = 'w_1'; PackageFamilyName = 'MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy' }
            )
        }
        $apps = Get-AfPromoApps -User $null
        $apps.Copilot.StoreId | Should -Be '9NHT9RB2F4HD'
        $apps.HasWidgets | Should -BeTrue
        @($apps.Promo).Count | Should -Be 0
    }
    It 'sin Copilot devuelve $null' {
        Mock Get-AppxPackage { @() }
        $apps = Get-AfPromoApps -User $null
        $apps.Copilot | Should -BeNullOrEmpty
        $apps.HasWidgets | Should -BeFalse
    }
}
