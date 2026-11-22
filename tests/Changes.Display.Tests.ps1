BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
}

Describe 'Set-AfDisplayMode' {
    BeforeEach {
        Mock Get-AfCurrentDisplayMode { [pscustomobject]@{ Width = 1920; Height = 1080; Hz = 60 } }
        Mock Invoke-AfDisplayModeChange { 0 }
    }

    It 'guarda el modo anterior y cambia a 144 Hz' {
        $tx = New-AfTransaction
        Set-AfDisplayMode -Tx $tx -DeviceName '\\.\DISPLAY2' -Label 'Pantalla 2' -Width 1920 -Height 1080 -Hz 144 | Should -BeTrue
        $r = $tx.Records[0]
        $r.Kind | Should -Be 'DisplayMode'
        $r.Previous.Hz | Should -Be 60
        $r.New.Hz | Should -Be 144
        Should -Invoke Invoke-AfDisplayModeChange -Times 1 -Exactly -ParameterFilter { $DeviceName -eq '\\.\DISPLAY2' -and $Hz -eq 144 }
    }

    It 'no hace nada si ya está en ese modo' {
        $tx = New-AfTransaction
        Set-AfDisplayMode -Tx $tx -DeviceName '\\.\DISPLAY2' -Width 1920 -Height 1080 -Hz 60 | Should -BeFalse
        Should -Invoke Invoke-AfDisplayModeChange -Times 0 -Exactly
    }

    It 'con código -2 da el motivo amable y no deja registro' {
        Mock Invoke-AfDisplayModeChange { -2 }
        $tx = New-AfTransaction
        { Set-AfDisplayMode -Tx $tx -DeviceName '\\.\DISPLAY2' -Width 1920 -Height 1080 -Hz 144 } | Should -Throw -ExpectedMessage 'Windows no aceptó 144 Hz en esa pantalla'
        $tx.Records.Count | Should -Be 0
    }

    It 'Restore vuelve al modo anterior' {
        $record = [pscustomobject]@{ Kind = 'DisplayMode'; DeviceName = '\\.\DISPLAY2'; Label = 'Pantalla 2'; Previous = [pscustomobject]@{ Width = 1920; Height = 1080; Hz = 60 }; New = [pscustomobject]@{ Width = 1920; Height = 1080; Hz = 144 } }
        Restore-AfDisplayMode -Record $record
        Should -Invoke Invoke-AfDisplayModeChange -Times 1 -Exactly -ParameterFilter { $Hz -eq 60 }
    }
}

Describe 'Confirm-AfDisplayChange' {
    BeforeEach {
        Mock Get-AfCurrentDisplayMode { [pscustomobject]@{ Width = 1920; Height = 1080; Hz = 60 } }
        Mock Invoke-AfDisplayModeChange { 0 }
    }

    It 'sin respuesta vuelve al modo anterior y marca Reverted' {
        $tx = New-AfTransaction -ConfirmDisplay { param($records) 'timeout' }
        Set-AfDisplayMode -Tx $tx -DeviceName '\\.\DISPLAY1' -Width 1920 -Height 1080 -Hz 144 | Out-Null
        $caught = $null
        try { Confirm-AfDisplayChange -Tx $tx } catch { $caught = $_ }
        $caught | Should -Not -BeNullOrEmpty
        Test-AfRevertError -ErrorRecord $caught | Should -BeTrue
        Get-AfApplyReason -ErrorRecord $caught | Should -Be 'Se volvió a 60 Hz porque nadie confirmó la pantalla'
        $result = Undo-AfRecords -Records @($tx.Records)
        @($result.Failed).Count | Should -Be 0
        Should -Invoke Invoke-AfDisplayModeChange -Times 1 -Exactly -ParameterFilter { $Hz -eq 60 }
    }

    It 'Volver da el texto corto' {
        $tx = New-AfTransaction -ConfirmDisplay { param($records) 'revert' }
        Set-AfDisplayMode -Tx $tx -DeviceName '\\.\DISPLAY1' -Width 1920 -Height 1080 -Hz 144 | Out-Null
        { Confirm-AfDisplayChange -Tx $tx } | Should -Throw -ExpectedMessage 'Se volvió a 60 Hz'
    }

    It 'keep no lanza y recibe los registros de pantalla' {
        $script:seen = $null
        $tx = New-AfTransaction -ConfirmDisplay { param($records) $script:seen = @($records).Count; 'keep' }
        Set-AfDisplayMode -Tx $tx -DeviceName '\\.\DISPLAY1' -Width 1920 -Height 1080 -Hz 144 | Out-Null
        { Confirm-AfDisplayChange -Tx $tx } | Should -Not -Throw
        $script:seen | Should -Be 1
    }

    It 'sin ConfirmDisplay no pregunta (prueba en Sandbox)' {
        $tx = New-AfTransaction
        Set-AfDisplayMode -Tx $tx -DeviceName '\\.\DISPLAY1' -Width 1920 -Height 1080 -Hz 144 | Out-Null
        { Confirm-AfDisplayChange -Tx $tx } | Should -Not -Throw
    }
}

Describe 'Código nativo de pantalla' -Tag 'Integration' {
    It 'GetCurrentMode lee la pantalla principal sin cambiarla' {
        Initialize-AfNative | Should -BeTrue
        [Afina.Native].GetMethod('ChangeMode') | Should -Not -BeNullOrEmpty
        $primary = @(Get-AfDisplayModes | Where-Object IsPrimary)[0]
        $mode = Get-AfCurrentDisplayMode -DeviceName $primary.DeviceName
        $mode.Hz | Should -Be $primary.Hz
    }
}
