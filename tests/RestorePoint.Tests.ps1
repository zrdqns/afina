BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:frequency = 'SystemRestorePointCreationFrequency'
}

Describe 'Get-AfRestoreStatus' {
    It 'Enabled con (C%3A) en SPP\Clients' {
        Mock Get-AfRegistryValue { @('\\?\Volume{1b2c3d4e-0000-0000-0000-100000000000}\:(C%3A)') } -ParameterFilter { $Path -like '*SPP\Clients' }
        Mock Get-AfRegistryValue { $null } -ParameterFilter { $Path -like '*Policies*' }
        $s = Get-AfRestoreStatus -Drive 'C:'
        $s.Enabled | Should -BeTrue
        $s.Blocked | Should -BeFalse
    }

    It 'apagado si SPP\Clients no tiene el disco' {
        Mock Get-AfRegistryValue { $null }
        (Get-AfRestoreStatus -Drive 'C:').Enabled | Should -BeFalse
    }

    It 'Blocked con DisableSR 1' {
        Mock Get-AfRegistryValue { @('\\?\Volume{x}\:(C%3A)') } -ParameterFilter { $Path -like '*SPP\Clients' }
        Mock Get-AfRegistryValue { 1 } -ParameterFilter { $Name -eq 'DisableSR' }
        Mock Get-AfRegistryValue { $null } -ParameterFilter { $Name -eq 'DisableConfig' }
        $s = Get-AfRestoreStatus -Drive 'C:'
        $s.Blocked | Should -BeTrue
        $s.Enabled | Should -BeFalse
    }
}

Describe 'New-AfRestorePoint' {
    BeforeEach {
        Mock Get-AfRestoreStatus { [pscustomobject]@{ Enabled = $true; Blocked = $false } }
        Mock Set-ItemProperty { }
        Mock Remove-ItemProperty { }
    }

    It 'deja la frecuencia como estaba aunque falle' {
        Mock Get-AfRegistryValue { 1440 } -ParameterFilter { $Name -eq $script:frequency }
        Mock Invoke-CimMethod { throw 'error crudo de WMI' }
        $r = New-AfRestorePoint
        $r.Ok | Should -BeFalse
        $r.Message | Should -Be 'Windows no permitió crearlo'
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq $script:frequency -and $Value -eq 0 }
        Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq $script:frequency -and $Value -eq 1440 }
    }

    It 'borra la frecuencia si no existía' {
        Mock Get-AfRegistryValue { $null } -ParameterFilter { $Name -eq $script:frequency }
        Mock Invoke-CimMethod { [pscustomobject]@{ ReturnValue = 0 } }
        $r = New-AfRestorePoint
        $r.Ok | Should -BeTrue
        $r.At | Should -Not -BeNullOrEmpty
        Should -Invoke Remove-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq $script:frequency }
        Should -Invoke Invoke-CimMethod -Times 1 -Exactly -ParameterFilter { $MethodName -eq 'CreateRestorePoint' -and $Arguments.RestorePointType -eq 12 -and $Arguments.EventType -eq 100 }
    }

    It 'ReturnValue distinto de 0 da Ok false y un mensaje amable' {
        Mock Get-AfRegistryValue { $null } -ParameterFilter { $Name -eq $script:frequency }
        Mock Invoke-CimMethod { [pscustomobject]@{ ReturnValue = 1058 } }
        $r = New-AfRestorePoint
        $r.Ok | Should -BeFalse
        $r.Message | Should -Be 'Windows no permitió crearlo'
    }

    It 'si Restaurar sistema está apagado no intenta crearlo' {
        Mock Get-AfRestoreStatus { [pscustomobject]@{ Enabled = $false; Blocked = $false } }
        Mock Invoke-CimMethod { }
        $r = New-AfRestorePoint -Drive 'C:'
        $r.Ok | Should -BeFalse
        $r.Message | Should -Be 'Restaurar sistema está apagado en C:'
        Should -Invoke Invoke-CimMethod -Times 0 -Exactly
    }
}
