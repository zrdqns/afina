# Lectores de salidas de comandos. Solo usan posiciones, números y palabras que no cambian con el idioma.

# powercfg /q <plan> <subgrupo> <ajuste>: los dos últimos 0x... son CA y CC, en ese orden.
function ConvertFrom-AfPowercfgQuery {
    param([string]$Text)
    $hex = [regex]::Matches([string]$Text, '0x([0-9a-fA-F]+)')
    if ($hex.Count -lt 2) { return $null }
    [pscustomobject]@{
        Ac = [Convert]::ToInt32($hex[$hex.Count - 2].Groups[1].Value, 16)
        Dc = [Convert]::ToInt32($hex[$hex.Count - 1].Groups[1].Value, 16)
    }
}

# netsh wlan show interfaces: conectado si hay línea SSID; banda por "GHz" o, si falta, por el canal.
function ConvertFrom-AfNetshWlan {
    param([string]$Text)
    $text = [string]$Text
    $ssid = [regex]::Match($text, '(?m)^\s*SSID\s*:\s*(.+?)\s*$')
    $band = $null
    $channel = $null
    if ($ssid.Success) {
        $bandMatch = [regex]::Match($text, '(?m):\s*(\d+(?:[.,]\d+)?)\s*GHz\s*$')
        if ($bandMatch.Success) {
            $band = [double]::Parse($bandMatch.Groups[1].Value.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
        }
        # Etiqueta del canal en los idiomas más comunes; solo se usa si falta la banda.
        $channelMatch = [regex]::Match($text, '(?mi)^\s*(?:Channel|Canal|Kanal|Canale)\s*:\s*(\d+)\s*$')
        if ($channelMatch.Success) { $channel = [int]$channelMatch.Groups[1].Value }
        if (-not $band -and $channel) { $band = if ($channel -le 14) { 2.4 } else { 5.0 } }
    }
    [pscustomobject]@{
        Connected = $ssid.Success
        BandGHz = $band
        Channel = $channel
        Ssid = if ($ssid.Success) { $ssid.Groups[1].Value } else { $null }
    }
}

function ConvertFrom-AfFsutilTrim {
    param([string]$Text)
    $m = [regex]::Match([string]$Text, 'NTFS\s+DisableDeleteNotify\s*=\s*(\d)')
    [pscustomobject]@{ NtfsDisabled = $m.Success -and $m.Groups[1].Value -eq '1' }
}

# productState de root\SecurityCenter2: bits 12-15 = activado (1); bits 4-7 = firmas (0 = al día).
function ConvertFrom-AfProductState {
    param([int]$State)
    [pscustomobject]@{
        Enabled = (($State -shr 12) -band 0xF) -eq 1
        UpToDate = (($State -shr 4) -band 0xF) -eq 0
    }
}

# winget upgrade: las columnas se cortan por donde empieza cada palabra del encabezado sobre la línea de guiones.
function ConvertFrom-AfWingetUpgrade {
    param([string]$Text)
    $lines = @(([string]$Text) -split "`r?`n" | ForEach-Object { ($_ -split "`r")[-1] })
    $dash = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^-{10,}\s*$') { $dash = $i; break }
    }
    if ($dash -lt 1) { return @() }

    $starts = @([regex]::Matches($lines[$dash - 1], '(?<=^|\s)\S') | ForEach-Object { $_.Index })
    if ($starts.Count -lt 4) { return @() }

    $apps = @()
    for ($i = $dash + 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { break }
        if ($line.Length -le $starts[3]) { continue }
        $availableEnd = if ($starts.Count -ge 5 -and $line.Length -gt $starts[4]) { $starts[4] } else { $line.Length }
        $id = $line.Substring($starts[1], $starts[2] - $starts[1]).Trim()
        if (-not $id -or $id -match '\s') { continue }
        $apps += [pscustomobject]@{
            Name = $line.Substring(0, $starts[1]).Trim()
            Id = $id
            Version = $line.Substring($starts[2], $starts[3] - $starts[2]).Trim()
            Available = $line.Substring($starts[3], $availableEnd - $starts[3]).Trim()
            Source = if ($starts.Count -ge 5 -and $line.Length -gt $starts[4]) { $line.Substring($starts[4]).Trim() } else { '' }
        }
    }
    $apps
}

# Salida de "dism /English /Get-FeatureInfo": el estado se normaliza a Enabled o Disabled, con su reinicio pendiente.
function ConvertFrom-AfDismFeatureInfo {
    param([string]$Text)
    $raw = $null
    $match = [regex]::Match([string]$Text, '(?m)^\s*State\s*:\s*(.+?)\s*$')
    if ($match.Success) { $raw = $match.Groups[1].Value }
    $state = $null; $pending = $false
    switch ($raw) {
        'Enabled' { $state = 'Enabled' }
        'Enable Pending' { $state = 'Enabled'; $pending = $true }
        'Disabled' { $state = 'Disabled' }
        'Disable Pending' { $state = 'Disabled'; $pending = $true }
        'Disabled with Payload Removed' { $state = 'Disabled' }
    }
    [pscustomobject]@{ State = $state; Pending = $pending; Raw = $raw }
}

# La primera cifra de la versión del driver indica el WDDM: 27 = 2.7, 32 = 3.2.
function Get-AfWddmVersion {
    param([string]$DriverVersion)
    $first = ([string]$DriverVersion -split '\.')[0]
    $number = 0
    if (-not [int]::TryParse($first, [ref]$number)) { return 0 }
    [math]::Round($number / 10, 1)
}
