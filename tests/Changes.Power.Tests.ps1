BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
    $script:saver = 'a1841308-3541-4fab-bc81-f71556f20b4a'
    $script:best = 'ded574b5-45a0-4f42-8737-46345c09c238'
    $script:none = '00000000-0000-0000-0000-000000000000'
    $script:sub = '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1'
    $script:set = '12bbebe6-58d6-4636-95bb-3217ef867c1a'
    function New-Query([int]$Ac, [int]$Dc) {
        "    Índice de configuración de corriente alterna actual: 0x{0:x8}`r`n    Índice de configuración de corriente continua actual: 0x{1:x8}" -f $Ac, $Dc
    }
    function New-Ok([string]$Output = '') { [pscustomobject]@{ ExitCode = 0; Output = $Output; Error = ''; TimedOut = $false } }
}

Describe 'Set-AfPowerSetting' {
    BeforeEach {
        Mock Get-AfRegistryValue { $script:balanced } -ParameterFilter { $Name -eq 'ActivePowerScheme' }
        Mock Invoke-AfProcess { New-Ok (New-Query 2 2) } -ParameterFilter { $Arguments -like '/q *' }
        Mock Invoke-AfProcess { New-Ok } -ParameterFilter { $Arguments -notlike '/q *' }
    }

    It 'guarda el valor AC anterior y llama a setacvalueindex y setactive con el esquema activo' {
        $tx = New-AfTransaction
        Set-AfPowerSetting -Tx $tx -Subgroup $script:sub -Setting $script:set -Ac 0 | Should -BeTrue
        $tx.Records[0].Kind | Should -Be 'PowerSetting'
        $tx.Records[0].Previous | Should -Be 2
        $tx.Records[0].Scheme | Should -Be $script:balanced
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq "/setacvalueindex $script:balanced $script:sub $script:set 0" }
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq "/setactive $script:balanced" }
    }

    It 'no hace nada si ya vale el objetivo' {
        $tx = New-AfTransaction
        Set-AfPowerSetting -Tx $tx -Subgroup $script:sub -Setting $script:set -Ac 2 | Should -BeFalse
        $tx.Records.Count | Should -Be 0
        Should -Invoke Invoke-AfProcess -Times 0 -Exactly -ParameterFilter { $Arguments -like '/setacvalueindex*' }
    }

    It 'Restore vuelve al valor anterior y reactiva el plan si sigue activo' {
        $record = [pscustomobject]@{ Kind = 'PowerSetting'; Scheme = $script:balanced; Subgroup = $script:sub; Setting = $script:set; Previous = 2; New = 0 }
        Restore-AfPowerSetting -Record $record
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq "/setacvalueindex $script:balanced $script:sub $script:set 2" }
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq "/setactive $script:balanced" }
    }

    It 'Get-AfPowerSettingState lee el valor AC actual' {
        $record = [pscustomobject]@{ Kind = 'PowerSetting'; Scheme = $script:balanced; Subgroup = $script:sub; Setting = $script:set; Previous = 2; New = 0 }
        Get-AfPowerSettingState -Record $record | Should -Be 2
    }

    It 'powercfg con código distinto de 0 da un motivo amable' {
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 1; Output = 'Parámetros no válidos'; Error = ''; TimedOut = $false } } -ParameterFilter { $Arguments -like '/setacvalueindex*' }
        $tx = New-AfTransaction
        { Set-AfPowerSetting -Tx $tx -Subgroup $script:sub -Setting $script:set -Ac 0 } | Should -Throw -ExpectedMessage 'Windows no aceptó el ajuste de energía'
        $tx.Records.Count | Should -Be 0
    }
}

Describe 'Set-AfActivePowerScheme' {
    It 'pasa de Ahorro a Equilibrado y Restore vuelve' {
        Mock Get-AfRegistryValue { $script:saver } -ParameterFilter { $Name -eq 'ActivePowerScheme' }
        Mock Invoke-AfProcess { New-Ok }
        $tx = New-AfTransaction
        Set-AfActivePowerScheme -Tx $tx -Guid $script:balanced | Should -BeTrue
        $tx.Records[0].Kind | Should -Be 'PowerScheme'
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq "/setactive $script:balanced" }
        Restore-AfPowerScheme -Record $tx.Records[0]
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq "/setactive $script:saver" }
    }
}

Describe 'Set-AfPowerOverlay' {
    It 'en batería sin la función de Windows 11 da el motivo del cargador' {
        Mock Get-AfPowerOverlay { $script:none }
        Mock Invoke-AfSetAcOverlay { [uint32]4294967295 }
        $tx = New-AfTransaction
        { Set-AfPowerOverlay -Tx $tx -Guid $script:best } | Should -Throw -ExpectedMessage 'conecta el cargador*'
        $tx.Records.Count | Should -Be 0
    }

    It 'con código 0 deja el registro con Previous y New' {
        $script:overlay = $script:none
        Mock Get-AfPowerOverlay { $script:overlay }
        Mock Invoke-AfSetAcOverlay { $script:overlay = $Guid; [uint32]0 }
        $tx = New-AfTransaction
        Set-AfPowerOverlay -Tx $tx -Guid $script:best | Should -BeTrue
        $tx.Records[0].Kind | Should -Be 'PowerOverlay'
        $tx.Records[0].Previous | Should -Be $script:none
        $tx.Records[0].New | Should -Be $script:best
    }

    It 'si Windows acepta pero el modo no cambia, deja el registro y lanza para que se revierta' {
        Mock Get-AfPowerOverlay { $script:none }
        Mock Invoke-AfSetAcOverlay { [uint32]0 }
        $tx = New-AfTransaction
        { Set-AfPowerOverlay -Tx $tx -Guid $script:best } | Should -Throw -ExpectedMessage 'Windows no aceptó el modo de energía'
        $tx.Records.Count | Should -Be 1
    }

    It 'no hace nada si ya está en Mejor rendimiento' {
        Mock Get-AfPowerOverlay { $script:best }
        Mock Invoke-AfSetAcOverlay { [uint32]0 }
        Set-AfPowerOverlay -Tx (New-AfTransaction) -Guid $script:best | Should -BeFalse
        Should -Invoke Invoke-AfSetAcOverlay -Times 0 -Exactly
    }
}

Describe 'Código nativo de energía' -Tag 'Integration' {
    It 'el tipo nativo tiene SetAcOverlay e IsOnAcPower' {
        Initialize-AfNative | Should -BeTrue
        [Afina.Native].GetMethod('SetAcOverlay') | Should -Not -BeNullOrEmpty
        [Afina.Native].GetMethod('IsOnAcPower') | Should -Not -BeNullOrEmpty
        { Test-AfOnAcPower } | Should -Not -Throw
    }
}
