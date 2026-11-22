BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
}

Describe 'Configuración' {
    BeforeEach { $script:cfgPath = Join-Path $TestDrive ('cfg-' + [guid]::NewGuid().ToString('N') + '.json') }

    It 'Get-AfConfig devuelve los valores por defecto si no hay archivo' {
        $c = Get-AfConfig -Path $script:cfgPath
        $c.Theme | Should -Be 'System'
        $c.Motion | Should -Be 'Auto'
        $c.VirusTotalKey | Should -BeNullOrEmpty
    }

    It 'Get-AfConfig ignora un JSON inválido y lo anota como Warn' {
        Set-Content -Path $script:cfgPath -Value '{ esto no es json'
        $c = Get-AfConfig -Path $script:cfgPath
        $c.Theme | Should -Be 'System'
        @(Get-AfLogLines | Where-Object { $_ -match 'WARN' }).Count | Should -BeGreaterThan 0
    }

    It 'Set-AfConfig y Get-AfConfig conservan Theme Black' {
        $c = Get-AfConfig -Path $script:cfgPath
        $c.Theme = 'Black'
        Set-AfConfig -Path $script:cfgPath -Config $c
        (Get-AfConfig -Path $script:cfgPath).Theme | Should -Be 'Black'
    }
}

Describe 'Get-AfConfigPath' {
    It 'usa la carpeta del script si se puede escribir' {
        Get-AfConfigPath -ScriptRoot $TestDrive | Should -Be (Join-Path $TestDrive 'afina.config.json')
    }

    It 'usa LOCALAPPDATA si no hay carpeta del script' {
        Get-AfConfigPath -ScriptRoot $null | Should -Be (Join-Path $env:LOCALAPPDATA 'Afina\afina.config.json')
    }
}

Describe 'Invoke-AfProcess' {
    It 'devuelve la salida de cmd /c echo hola' {
        $r = Invoke-AfProcess -FilePath 'cmd.exe' -Arguments '/c echo hola' -TimeoutMs 10000
        $r.TimedOut | Should -BeFalse
        $r.ExitCode | Should -Be 0
        $r.Output.Trim() | Should -Be 'hola'
    }

    It 'corta al tiempo límite' {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-AfProcess -FilePath 'powershell.exe' -Arguments '-NoProfile -Command Start-Sleep 5' -TimeoutMs 1000
        $sw.Stop()
        $r.TimedOut | Should -BeTrue
        $sw.Elapsed.TotalSeconds | Should -BeLessThan 3
    }
}

Describe 'Registro de actividad' {
    It 'Write-AfLog guarda el nivel y el mensaje' {
        Write-AfLog -Level Info -Message 'prueba de registro'
        (Get-AfLogLines)[-1] | Should -Match 'INFO.*prueba de registro'
    }

    It 'Start-AfLog crea el archivo en la carpeta indicada' {
        $p = Start-AfLog -Directory (Join-Path $TestDrive 'logs')
        Write-AfLog -Level Warn -Message 'al archivo'
        Get-Content $p -Raw | Should -Match 'al archivo'
    }
}
