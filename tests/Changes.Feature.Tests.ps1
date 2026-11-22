BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:me = Get-AfUserForSid
    function Get-DismSample([string]$State) {
        @(
            'Deployment Image Servicing and Management tool'
            'Version: 10.0.26100.1'
            ''
            'Feature Information:'
            ''
            'Feature Name : VirtualMachinePlatform'
            'Display Name : Virtual Machine Platform'
            'Restart Required : Possible'
            "State : $State"
            ''
            'The operation completed successfully.'
        ) -join "`r`n"
    }
    function New-DismResult([int]$ExitCode = 0, [string]$Output = '') { [pscustomobject]@{ ExitCode = $ExitCode; Output = $Output; Error = ''; TimedOut = $false } }
}

Describe 'ConvertFrom-AfDismFeatureInfo' {
    It 'entiende los cinco estados de DISM en inglés' {
        $cases = @(
            @{ Raw = 'Enabled'; State = 'Enabled'; Pending = $false }
            @{ Raw = 'Enable Pending'; State = 'Enabled'; Pending = $true }
            @{ Raw = 'Disabled'; State = 'Disabled'; Pending = $false }
            @{ Raw = 'Disable Pending'; State = 'Disabled'; Pending = $true }
            @{ Raw = 'Disabled with Payload Removed'; State = 'Disabled'; Pending = $false }
        )
        foreach ($case in $cases) {
            $info = ConvertFrom-AfDismFeatureInfo -Text (Get-DismSample $case.Raw)
            $info.State | Should -Be $case.State -Because $case.Raw
            $info.Pending | Should -Be $case.Pending -Because $case.Raw
            $info.Raw | Should -Be $case.Raw
        }
    }

    It 'lee la salida real de una PC en español (nombre y descripción traducidos, estado en inglés)' {
        $real = @(
            'Deployment Image Servicing and Management tool'
            'Version: 10.0.26100.10068'
            ''
            'Image Version: 10.0.26300.10075'
            ''
            'Feature Information:'
            ''
            'Feature Name : VirtualMachinePlatform'
            'Display Name : Plataforma de máquina virtual'
            'Description : Habilita la compatibilidad con plataformas para máquinas virtuales'
            'Restart Required : Possible'
            'State : Enabled'
            ''
            'Custom Properties:'
            ''
            '(No custom properties found)'
            ''
            'The operation completed successfully.'
        ) -join "`r`n"
        $info = ConvertFrom-AfDismFeatureInfo -Text $real
        $info.State | Should -Be 'Enabled'
        $info.Pending | Should -BeFalse
    }

    It 'un estado desconocido o una salida traducida dan State $null' {
        (ConvertFrom-AfDismFeatureInfo -Text (Get-DismSample 'Staged')).State | Should -BeNullOrEmpty
        (ConvertFrom-AfDismFeatureInfo -Text "Nombre de característica : VirtualMachinePlatform`r`nEstado : Habilitado").State | Should -BeNullOrEmpty
    }
}

Describe 'Pieza WindowsFeature' {
    It 'Set-AfWindowsFeature apaga y deshacer la vuelve a encender' {
        Mock Invoke-AfProcess { New-DismResult -Output (Get-DismSample 'Enabled') } -ParameterFilter { $Arguments -like '*/Get-FeatureInfo*' }
        Mock Invoke-AfProcess { New-DismResult -ExitCode 3010 } -ParameterFilter { $Arguments -notlike '*/Get-FeatureInfo*' }
        $tx = New-AfTransaction -User $script:me
        Set-AfWindowsFeature -Tx $tx -Name 'VirtualMachinePlatform' -Enabled $false | Should -BeTrue
        $tx.Records[0].Kind | Should -Be 'WindowsFeature'
        $tx.Records[0].Previous | Should -Be 'Enabled'
        $tx.Records[0].New | Should -Be 'Disabled'
        $tx.NeedsReboot | Should -BeTrue
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $FilePath -eq (Join-Path $env:SystemRoot 'System32\dism.exe') -and $Arguments -eq '/Online /English /Disable-Feature /FeatureName:VirtualMachinePlatform /NoRestart /Quiet' }
        Undo-AfRecord -Record $tx.Records[0] -User $script:me
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq '/Online /English /Enable-Feature /FeatureName:VirtualMachinePlatform /NoRestart /Quiet' }
        Get-AfRecordState -Record $tx.Records[0] -User $script:me | Should -Be 'Enabled'
    }

    It 'no deja registro si ya está en el estado pedido' {
        Mock Invoke-AfProcess { New-DismResult -Output (Get-DismSample 'Disable Pending') }
        $tx = New-AfTransaction -User $script:me
        Set-AfWindowsFeature -Tx $tx -Name 'VirtualMachinePlatform' -Enabled $false | Should -BeFalse
        @($tx.Records).Count | Should -Be 0
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly
    }

    It 'un código distinto de 0 y 3010 lanza un error amable' {
        Mock Invoke-AfProcess { New-DismResult -Output (Get-DismSample 'Enabled') } -ParameterFilter { $Arguments -like '*/Get-FeatureInfo*' }
        Mock Invoke-AfProcess { New-DismResult -ExitCode 50 } -ParameterFilter { $Arguments -notlike '*/Get-FeatureInfo*' }
        { Set-AfWindowsFeature -Tx (New-AfTransaction -User $script:me) -Name 'VirtualMachinePlatform' -Enabled $false } | Should -Throw -ExpectedMessage 'DISM no aceptó el cambio (código 50)'
    }

    It 'si DISM no responde lo dice' {
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = $null; Output = ''; Error = ''; TimedOut = $true } }
        { Get-AfFeatureInfo -Name 'VirtualMachinePlatform' } | Should -Throw -ExpectedMessage 'DISM no respondió'
    }

    It 'Get-AfFeatureInfo lee VirtualMachinePlatform sin cambiarla (solo lectura)' -Tag 'Integration' {
        if (-not (Test-AfAdmin)) { Set-ItResult -Skipped -Because 'DISM necesita administrador' }
        (Get-AfFeatureInfo -Name 'VirtualMachinePlatform').State | Should -BeIn @('Enabled', 'Disabled')
    }
}
