# Genera src\UI\Icons.ps1 a partir de los SVG de @phosphor-icons/core (licencia MIT).
# Uso: .\tools\Export-PhosphorIcons.ps1 -SourceDir <carpeta con los SVG> [-Download]
param([Parameter(Mandatory)][string]$SourceDir, [switch]$Download, [string]$Version = '2.1.1')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'src\UI\Theme.ps1')

$wanted = @(Get-AfIconNames | ForEach-Object { @{ Name = $_; Variant = 'Bold' } }) + @(Get-AfFillIconNames | ForEach-Object { @{ Name = $_; Variant = 'Fill' } })

if ($Download) {
    New-Item -ItemType Directory -Force -Path $SourceDir | Out-Null
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    foreach ($icon in $wanted) {
        $weight = $icon.Variant.ToLowerInvariant()
        $file = Join-Path $SourceDir ('{0}-{1}.svg' -f $icon.Name, $weight)
        if (-not (Test-Path $file)) {
            Invoke-WebRequest -Uri ('https://unpkg.com/@phosphor-icons/core@{0}/assets/{1}/{2}-{1}.svg' -f $Version, $weight, $icon.Name) -OutFile $file -UseBasicParsing
        }
    }
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# Generado por tools\Export-PhosphorIcons.ps1. No editar a mano.')
$lines.Add("# Iconos: Phosphor Icons $Version (https://phosphoricons.com). Licencia MIT.")
$lines.Add('# Copyright (c) 2023 Phosphor Icons. Se permite usar, copiar, modificar y distribuir con este aviso.')
$lines.Add('$script:AfIcons = @{')
foreach ($icon in $wanted) {
    $weight = $icon.Variant.ToLowerInvariant()
    $svg = [System.IO.File]::ReadAllText((Join-Path $SourceDir ('{0}-{1}.svg' -f $icon.Name, $weight)))
    $paths = @([regex]::Matches($svg, '\sd="([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
    if (-not $paths.Count) { throw "Sin trazados en $($icon.Name) $weight" }
    $lines.Add(("    '{0}|{1}' = 'F1 {2}'" -f $icon.Name, $icon.Variant, ($paths -join ' ')))
}
$lines.Add('}')
$out = Join-Path $root 'src\UI\Icons.ps1'
[System.IO.File]::WriteAllText($out, ($lines -join "`r`n") + "`r`n", (New-Object System.Text.UTF8Encoding($true)))
"Escrito $out con $($wanted.Count) iconos"
