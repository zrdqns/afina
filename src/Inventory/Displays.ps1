function Get-AfDisplayInfo {
    # Hz máximos que anuncia cada monitor (EDID), por código de monitor.
    $edid = @{}
    try {
        foreach ($monitor in @(Get-CimInstance -Namespace 'root\wmi' -ClassName WmiMonitorListedSupportedSourceModes -OperationTimeoutSec 15 -ErrorAction Stop)) {
            $code = ([string]$monitor.InstanceName -split '\\')[1]
            $rates = @($monitor.MonitorSourceModes | Where-Object { $_.VerticalRefreshRateDenominator } |
                    ForEach-Object { [math]::Round($_.VerticalRefreshRateNumerator / $_.VerticalRefreshRateDenominator) })
            if ($code -and $rates.Count) { $edid[$code] = [int]($rates | Measure-Object -Maximum).Maximum }
        }
    } catch {
        Write-AfLog -Level Warn -Message "No se pudieron leer los modos EDID: $($_.Exception.Message)"
    }

    foreach ($display in @(Get-AfDisplayModes)) {
        $sameRes = @($display.Modes | Where-Object { $_.Width -eq $display.Width -and $_.Height -eq $display.Height } | ForEach-Object { $_.Hz })
        $maxHz = (@($sameRes) + $display.Hz | Measure-Object -Maximum).Maximum
        [pscustomobject]@{
            DeviceName = $display.DeviceName
            MonitorCode = $display.MonitorCode
            IsPrimary = $display.IsPrimary
            Width = $display.Width
            Height = $display.Height
            Hz = $display.Hz
            MaxHzAtCurrentRes = [int]$maxHz
            EdidMaxHz = if ($display.MonitorCode -and $edid.ContainsKey($display.MonitorCode)) { $edid[$display.MonitorCode] } else { $null }
            Modes = $display.Modes
        }
    }
}
