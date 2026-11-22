# Junta todo Afina en un solo archivo: dist\Afina.ps1 (más dist\Afina.cmd para la USB).
param([string]$OutDir = (Join-Path $PSScriptRoot 'dist'))
$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'src'
. (Join-Path $src 'Load.ps1')

$main = [System.IO.File]::ReadAllText((Join-Path $src 'Main.ps1'), [System.Text.Encoding]::UTF8)
$pattern = '(?s)# <afina:code>.*?# </afina:code>'
if ($main -notmatch $pattern) { throw 'Main.ps1 no tiene las marcas <afina:code>.' }

# El código va en un bloque de script literal (no en un here-string, que chocaría con los here-strings del XAML).
# Sirve para cargarlo aquí y como texto para el runspace del análisis.
$block = "`$Global:AfCodeBlock = {`r`n" + $Global:AfCode + "`r`n}`r`n`$Global:AfCode = `$Global:AfCodeBlock.ToString()`r`n. `$Global:AfCodeBlock"
$body = [regex]::Replace($main, $pattern, [System.Text.RegularExpressions.MatchEvaluator] { param($m) $block })
$header = "# Afina $(Get-AfVersion): análisis y optimización de Windows. Generado por build.ps1; no editar a mano.`r`n# Iconos: Phosphor Icons (https://phosphoricons.com), licencia MIT.`r`n"

$usb = Join-Path $OutDir 'usb'
New-Item -ItemType Directory -Force -Path $usb | Out-Null
# USB: con BOM, porque powershell -File lee sin BOM como ANSI y rompe los acentos.
$ps1 = Join-Path $usb 'Afina.ps1'
[System.IO.File]::WriteAllText($ps1, $header + $body, (New-Object System.Text.UTF8Encoding($true)))
# Si Afina sale con error (o con PowerShell limitado), la ventana espera para que se lea el aviso.
$cmd = "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File `"%~dp0Afina.ps1`" %*`r`nif errorlevel 1 pause`r`n"
[System.IO.File]::WriteAllText((Join-Path $usb 'Afina.cmd'), $cmd, [System.Text.Encoding]::ASCII)
# Línea de internet: sin BOM (GitHub lo sirve como UTF-8 y irm dejaría el BOM pegado al primer comentario).
[System.IO.File]::WriteAllText((Join-Path $OutDir 'Afina.ps1'), $header + $body, (New-Object System.Text.UTF8Encoding($false)))
'dist\usb\Afina.ps1: {0:N0} KB' -f ((Get-Item $ps1).Length / 1KB)
