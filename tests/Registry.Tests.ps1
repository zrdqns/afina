BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
}

Describe 'Resolve-AfRegistryPath' {
    It 'deja HKCU si es el mismo usuario' {
        $u = [pscustomobject]@{ Sid = 'S-1-5-21-1'; IsSameAsProcess = $true; HkcuRoot = 'HKCU:' }
        Resolve-AfRegistryPath -Path 'HKCU:\Software\Microsoft\GameBar' -User $u | Should -Be 'HKCU:\Software\Microsoft\GameBar'
    }

    It 'usa HKEY_USERS si el usuario es otro' {
        $u = [pscustomobject]@{ Sid = 'S-1-5-21-1'; IsSameAsProcess = $false; HkcuRoot = 'Registry::HKEY_USERS\S-1-5-21-1' }
        Resolve-AfRegistryPath -Path 'HKCU:\Software\Microsoft\GameBar' -User $u | Should -Be 'Registry::HKEY_USERS\S-1-5-21-1\Software\Microsoft\GameBar'
    }

    It 'no toca HKLM' {
        $u = [pscustomobject]@{ Sid = 'S-1-5-21-1'; IsSameAsProcess = $false; HkcuRoot = 'Registry::HKEY_USERS\S-1-5-21-1' }
        Resolve-AfRegistryPath -Path 'HKLM:\SYSTEM\X' -User $u | Should -Be 'HKLM:\SYSTEM\X'
    }
}

Describe 'Get-AfRegistrySnapshot' {
    BeforeAll {
        $script:u = [pscustomobject]@{ Sid = 'S-1-5-21-1'; IsSameAsProcess = $true; HkcuRoot = 'HKCU:' }
        $script:hags = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode'
    }

    It 'da null si falta el valor' {
        Mock Get-ItemProperty { throw 'no existe' }
        $s = Get-AfRegistrySnapshot -Reads @($script:hags) -User $script:u
        $s.ContainsKey($script:hags) | Should -BeTrue
        $s[$script:hags] | Should -BeNullOrEmpty
    }

    It 'lee un DWORD' {
        Mock Get-ItemProperty { [pscustomobject]@{ HwSchMode = 2 } }
        $s = Get-AfRegistrySnapshot -Reads @($script:hags) -User $script:u
        $s[$script:hags] | Should -Be 2
    }

    It 'lee de la colmena del otro usuario' {
        $other = [pscustomobject]@{ Sid = 'S-1-5-21-9'; IsSameAsProcess = $false; HkcuRoot = 'Registry::HKEY_USERS\S-1-5-21-9' }
        Mock Get-ItemProperty { throw 'ruta equivocada' }
        Mock Get-ItemProperty { [pscustomobject]@{ AutoGameModeEnabled = 0 } } -ParameterFilter { $LiteralPath -eq 'Registry::HKEY_USERS\S-1-5-21-9\Software\Microsoft\GameBar' }
        $s = Get-AfRegistrySnapshot -Reads @('HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled') -User $other
        $s['HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled'] | Should -Be 0
    }
}

Describe 'Get-AfInteractiveUser' -Tag 'Integration' {
    It 'devuelve el usuario de esta sesión con SID y raíz de HKCU' {
        $u = Get-AfInteractiveUser
        $u.Sid | Should -Match '^S-1-5-'
        $u.HkcuRoot | Should -Not -BeNullOrEmpty
    }
}
