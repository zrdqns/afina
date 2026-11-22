BeforeAll {
    $script:root = Split-Path $PSScriptRoot -Parent
    $script:out = Join-Path $TestDrive 'dist'
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $script:root 'build.ps1') -OutDir $script:out | Out-Null
    # La USB (y el release) usan dist\usb; la línea de internet lee dist\Afina.ps1.
    $script:built = Join-Path $script:out 'usb\Afina.ps1'
    $script:web = Join-Path $script:out 'Afina.ps1'
}

Describe 'Build' {
    It 'genera Afina.ps1 para la línea y Afina.ps1 con Afina.cmd para la USB' {
        Test-Path $script:built | Should -BeTrue
        Test-Path (Join-Path $script:out 'usb\Afina.cmd') | Should -BeTrue
        Test-Path $script:web | Should -BeTrue
    }

    It 'Afina.cmd deja la ventana abierta si Afina sale con error (el aviso se puede leer)' {
        Get-Content (Join-Path $script:out 'usb\Afina.cmd') | Should -Contain 'if errorlevel 1 pause'
    }

    It 'el de la línea es el mismo texto sin BOM (irm lo dejaría pegado al primer comentario)' {
        $web = [System.IO.File]::ReadAllBytes($script:web)
        $web[0] | Should -Not -Be 0xEF
        [System.IO.File]::ReadAllText($script:web) | Should -BeExactly ([System.IO.File]::ReadAllText($script:built))
    }

    It 'con PowerShell limitado, el Afina.ps1 armado avisa y sale con 2 antes de cargar el código' {
        $probe = Join-Path $TestDrive 'limitado.ps1'
        Set-Content -LiteralPath $probe -Value @('$ExecutionContext.SessionState.LanguageMode = ''ConstrainedLanguage''', ("& '{0}' -NoElevate -Scan" -f $script:built), 'exit $LASTEXITCODE')
        $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $probe) -join "`n"
        $LASTEXITCODE | Should -Be 2
        $output | Should -Match 'Smart App Control'
    }

    It 'el build parsea sin errores' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($script:built, [ref]$null, [ref]$errors)
        @($errors).Count | Should -Be 0
    }

    It 'pesa menos de 500 KB' {
        (Get-Item $script:built).Length | Should -BeLessThan 500KB
    }

    It 'está en UTF-8 con BOM' {
        $bytes = [System.IO.File]::ReadAllBytes($script:built)
        $bytes[0..2] | Should -Be @(0xEF, 0xBB, 0xBF)
    }

    It 'contiene todas las funciones de los archivos fuente' {
        . (Join-Path $script:root 'src\Load.ps1')
        $text = [System.IO.File]::ReadAllText($script:built)
        $functions = @(Get-Command -CommandType Function | Where-Object { $_.ScriptBlock.File -and $_.ScriptBlock.File -like (Join-Path $script:root 'src\*') })
        $functions.Count | Should -BeGreaterThan 50
        foreach ($f in $functions) { $text | Should -Match ('function ' + [regex]::Escape($f.Name)) }
    }

    It '-Scan -Json -NoElevate devuelve más de 30 resultados en menos de 30 s' -Tag 'Integration' {
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        $json = & powershell -NoProfile -ExecutionPolicy Bypass -File $script:built -Scan -Json -NoElevate | Out-String
        $watch.Stop()
        $data = $json | ConvertFrom-Json
        @($data.Results).Count | Should -BeGreaterThan 30
        $watch.Elapsed.TotalSeconds | Should -BeLessThan 30
    }
}
