function Get-AfConfigPath {
    param([string]$ScriptRoot)
    if ($ScriptRoot -and (Test-Path -LiteralPath $ScriptRoot)) {
        $probe = Join-Path $ScriptRoot ('.afina-' + [guid]::NewGuid().ToString('N'))
        try {
            [System.IO.File]::WriteAllText($probe, '')
            Remove-Item -LiteralPath $probe -Force
            return (Join-Path $ScriptRoot 'afina.config.json')
        } catch { }
    }
    Join-Path $env:LOCALAPPDATA 'Afina\afina.config.json'
}

function Get-AfConfigDefaults {
    @{ Theme = 'System'; Motion = 'Auto'; Language = 'Auto'; VirusTotalKey = $null }
}

function Get-AfConfig {
    param([string]$Path)
    $config = Get-AfConfigDefaults
    if ($Path -and (Test-Path -LiteralPath $Path)) {
        try {
            $data = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            foreach ($property in $data.PSObject.Properties) {
                if ($config.ContainsKey($property.Name)) { $config[$property.Name] = $property.Value }
            }
        } catch {
            Write-AfLog -Level Warn -Message "Configuración inválida en $Path; se usan los valores por defecto."
        }
    }
    $config
}

function Set-AfConfig {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][hashtable]$Config)
    $dir = Split-Path -Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($Path, ($Config | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))
}
