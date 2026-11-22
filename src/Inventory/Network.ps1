function Get-AfNetworkInfo {
    foreach ($adapter in @(Get-NetAdapter -Physical -ErrorAction Stop)) {
        $kind = switch -Regex ([string]$adapter.PhysicalMediaType) {
            '^802\.3$' { 'Ethernet'; break }
            '802\.11|Wireless' { 'WiFi'; break }
            default { $null }
        }
        if (-not $kind) { continue }

        $properties = @{}
        $speedDuplexValues = @()
        foreach ($p in @(Get-NetAdapterAdvancedProperty -Name $adapter.Name -ErrorAction SilentlyContinue)) {
            if ($p.RegistryKeyword) { $properties[$p.RegistryKeyword] = [string](@($p.RegistryValue)[0]) }
            if ($p.RegistryKeyword -eq '*SpeedDuplex') { $speedDuplexValues = @($p.ValidRegistryValues) }
        }

        $linkMbps = [int]([double]$adapter.ReceiveLinkSpeed / 1e6)
        $description = [string]$adapter.InterfaceDescription
        $maxMbps = $linkMbps
        if ($description -match '2\.5\s*G') { $maxMbps = 2500 }
        elseif ($description -match '\b10\s*G') { $maxMbps = 10000 }
        elseif ($description -match 'GbE|Gigabit|1000') { $maxMbps = [math]::Max($maxMbps, 1000) }
        # *SpeedDuplex = 6 es 1 Gbps dúplex completo.
        if ($speedDuplexValues -contains '6') { $maxMbps = [math]::Max($maxMbps, 1000) }

        [pscustomobject]@{
            Name = $adapter.Name
            Kind = $kind
            Description = $description
            Status = [string]$adapter.Status
            LinkSpeedMbps = $linkMbps
            MaxSpeedMbps = $maxMbps
            Properties = $properties
        }
    }
}

function Get-AfWlanInfo {
    $result = Invoke-AfProcess -FilePath 'netsh.exe' -Arguments 'wlan show interfaces' -TimeoutMs 15000 -Encoding ([System.Text.Encoding]::UTF8)
    if ($result.TimedOut) { return [pscustomobject]@{ Connected = $false; BandGHz = $null; Channel = $null; Ssid = $null } }
    ConvertFrom-AfNetshWlan -Text $result.Output
}
