BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
}

Describe 'Get-AfRelaunchArguments' {
    It 'con ruta usa -File y Bypass' {
        $a = Get-AfRelaunchArguments -ScriptPath 'D:\Mis herramientas\Afina.ps1' -OneLinerUrl 'https://example.test/afina.ps1'
        $a[0..4] | Should -Be @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', '"D:\Mis herramientas\Afina.ps1"')
    }

    It 'sin ruta usa -Command con irm' {
        $a = Get-AfRelaunchArguments -ScriptPath $null -OneLinerUrl 'https://example.test/afina.ps1'
        $a | Should -Contain '-Command'
        ($a -join ' ') | Should -Match ([regex]::Escape('"irm https://example.test/afina.ps1 | iex"'))
    }

    It 'pasa los parámetros extra al final' {
        $a = Get-AfRelaunchArguments -ScriptPath 'C:\A.ps1' -OneLinerUrl 'https://x.test' -Extra @('-Scan')
        $a[-1] | Should -Be '-Scan'
    }
}

Describe 'Comprobaciones del entorno' {
    It 'con PowerShell limitado, Main.ps1 avisa en el idioma de Windows y sale sin cargar Afina' {
        $probe = Join-Path $TestDrive 'limitado.ps1'
        $main = Join-Path $PSScriptRoot '..\src\Main.ps1'
        Set-Content -LiteralPath $probe -Value @('$ExecutionContext.SessionState.LanguageMode = ''ConstrainedLanguage''', ("& '{0}' -NoElevate -Scan" -f $main), 'exit $LASTEXITCODE')
        $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $probe) -join "`n"
        $LASTEXITCODE | Should -Be 2
        $expected = if ((Get-UICulture).TwoLetterISOLanguageName -eq 'es') { 'Afina no puede correr' } else { "Afina can't run here" }
        $output | Should -Match ([regex]::Escape($expected))
    }

    It 'Test-AfAdmin devuelve un booleano' {
        Test-AfAdmin | Should -BeOfType [bool]
    }
}
