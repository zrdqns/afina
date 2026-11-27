BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:user = [pscustomobject]@{ Name = 'PC\Cliente'; Sid = 'S-1-5-21-1' }
}

Describe 'Sesiones y respaldos' {
    It 'New-AfSession escribe el archivo al crearse' {
        $dir = Join-Path $TestDrive 'uno'
        $s = New-AfSession -Directory $dir -User $script:user -Version '0.2.0' -Now ([datetime]'2026-11-21 16:42:33')
        $s.Id | Should -Be '2026-11-21_164233'
        Test-Path -LiteralPath $s.Path | Should -BeTrue
        $data = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($s.Path))
        $data.User.Sid | Should -Be 'S-1-5-21-1'
        $data.Version | Should -Be '0.2.0'
        $data.PSObject.Properties['Path'] | Should -BeNullOrEmpty
    }

    It 'New-AfSession lanza un error amable si no puede escribir' {
        $file = Join-Path $TestDrive 'soy-un-archivo'
        [System.IO.File]::WriteAllText($file, 'x')
        { New-AfSession -Directory $file -User $script:user } | Should -Throw -ExpectedMessage 'no se pudo guardar el respaldo*'
    }

    It 'Save e Import dan los mismos cambios y registros' {
        $s = New-AfSession -Directory (Join-Path $TestDrive 'dos') -User $script:user
        $record = [pscustomobject]@{
            Kind = 'RegistryValue'; Path = 'HKLM:\SYSTEM\X'; Name = 'HwSchMode'; KeyExisted = $true
            Previous = [pscustomobject]@{ Exists = $true; Type = 'DWord'; Value = 1 }
            New = [pscustomobject]@{ Exists = $true; Type = 'DWord'; Value = 2 }
        }
        [void]$s.Changes.Add([pscustomobject]@{ CheckId = 'gpu.hags'; Title = 'Programación de GPU por hardware'; NeedsReboot = $true; Status = 'Applied'; Message = $null; Note = $null; AppliedAt = (Get-Date).ToString('o'); UndoneAt = $null; Records = @($record) })
        Save-AfSession -Session $s
        $back = Import-AfSession -Path $s.Path
        $back.Path | Should -Be $s.Path
        $back.Changes -is [System.Collections.ArrayList] | Should -BeTrue
        $back.Changes.Count | Should -Be 1
        @($back.Changes[0].Records).Count | Should -Be 1
        $back.Changes[0].Records[0].Previous.Value | Should -Be 1
        $back.Changes[0].Title | Should -Be 'Programación de GPU por hardware'
        Test-Path -LiteralPath ($s.Path + '.tmp') | Should -BeFalse
    }

    It 'Get-AfSessions ordena por fecha y salta un JSON roto' {
        $dir = Join-Path $TestDrive 'tres'
        New-AfSession -Directory $dir -User $script:user -Now ([datetime]'2026-11-20 10:00:00') | Out-Null
        New-AfSession -Directory $dir -User $script:user -Now ([datetime]'2026-11-21 10:00:00') | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $dir 'roto.json'), '{ esto no es json')
        $list = @(Get-AfSessions -Directory $dir)
        $list.Count | Should -Be 2
        $list[0].Id | Should -Be '2026-11-21_100000'
    }

    It 'dos sesiones en el mismo segundo no se pisan' {
        $dir = Join-Path $TestDrive 'cuatro'
        $now = [datetime]'2026-11-21 12:00:00'
        $a = New-AfSession -Directory $dir -User $script:user -Now $now
        $b = New-AfSession -Directory $dir -User $script:user -Now $now
        $b.Path | Should -Not -Be $a.Path
        $b.Id | Should -Be '2026-11-21_120000-2'
    }

    # Un antivirus o el indexador abren el respaldo un instante: Replace falla con IOException (pasó en el Sandbox).
    It 'Save-AfSession reintenta si el respaldo está bloqueado un instante' {
        $s = New-AfSession -Directory (Join-Path $TestDrive 'bloqueo-breve') -User $script:user
        $script:lock = [System.IO.File]::Open($s.Path, 'Open', 'Read', 'None')
        try {
            # La primera espera suelta el bloqueo: el segundo intento tiene que funcionar.
            Mock Start-Sleep { $script:lock.Dispose() }
            [void]$s.Changes.Add([pscustomobject]@{ CheckId = 'gpu.hags'; Status = 'Applied' })
            { Save-AfSession -Session $s } | Should -Not -Throw
            Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 200 }
            (Import-AfSession -Path $s.Path).Changes[0].CheckId | Should -Be 'gpu.hags'
            Test-Path -LiteralPath ($s.Path + '.tmp') | Should -BeFalse
        } finally { $script:lock.Dispose() }
    }

    It 'Save-AfSession lanza el error al tercer intento si el bloqueo sigue' {
        $s = New-AfSession -Directory (Join-Path $TestDrive 'bloqueo-largo') -User $script:user
        $lock = [System.IO.File]::Open($s.Path, 'Open', 'Read', 'None')
        try {
            Mock Start-Sleep { }
            $err = $null
            try { Save-AfSession -Session $s } catch { $err = $_ }
            $err.Exception.GetBaseException() | Should -BeOfType ([System.IO.IOException])
            Should -Invoke Start-Sleep -Times 2 -Exactly
        } finally { $lock.Dispose() }
    }

    It 'Save-AfSession no reintenta un error que no es de bloqueo' {
        $s = New-AfSession -Directory (Join-Path $TestDrive 'solo-lectura') -User $script:user
        (Get-Item -LiteralPath $s.Path).IsReadOnly = $true
        try {
            Mock Start-Sleep { }
            # Un destino de solo lectura da UnauthorizedAccessException, que no es IOException.
            $err = $null
            try { Save-AfSession -Session $s } catch { $err = $_ }
            $err.Exception.GetBaseException() | Should -BeOfType ([System.UnauthorizedAccessException])
            Should -Invoke Start-Sleep -Times 0 -Exactly
        } finally { (Get-Item -LiteralPath $s.Path).IsReadOnly = $false }
    }

    It 'Get-AfSessions sin carpeta da una lista vacía' {
        @(Get-AfSessions -Directory (Join-Path $TestDrive 'no-existe')).Count | Should -Be 0
    }
}
