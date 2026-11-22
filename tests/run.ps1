param([switch]$Integration, [string[]]$Path)
# With -File, several paths arrive as one comma-separated string.
if ($Path) { $Path = @($Path | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

# Windows PowerShell 5.1 needs UTF-8 with BOM to read accented strings correctly.
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$files = @(Get-ChildItem -Path (Join-Path $root 'src'), (Join-Path $root 'tests'), (Join-Path $root 'tools'), (Join-Path $root 'sandbox') -Recurse -Include *.ps1 -ErrorAction SilentlyContinue)
$files += @(Get-Item (Join-Path $root 'build.ps1') -ErrorAction SilentlyContinue)
foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    if (-not $hasBom) {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        [System.IO.File]::WriteAllText($f.FullName, $text, $utf8Bom)
    }
}

Import-Module (Join-Path $root '.dev\modules\Pester\5.7.1\Pester.psd1') -Force
$cfg = New-PesterConfiguration
$cfg.Run.Path = if ($Path) { $Path } else { $PSScriptRoot }
$cfg.Run.PassThru = $true
$cfg.Output.Verbosity = 'Detailed'
if (-not $Integration) { $cfg.Filter.ExcludeTag = 'Integration' }
$result = Invoke-Pester -Configuration $cfg
"RESUMEN: $($result.Result) - pasaron $($result.PassedCount), fallaron $($result.FailedCount), omitidas $($result.SkippedCount)"
if ($result.Result -ne 'Passed') { exit 1 }
