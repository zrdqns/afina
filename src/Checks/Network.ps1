function Get-AfEthernetPowerKeywords {
    [ordered]@{
        '*EEE' = 'Energy-Efficient Ethernet'
        'AdvancedEEE' = 'Advanced EEE'
        'EnableGreenEthernet' = 'Green Ethernet'
        'GigaLite' = 'Gigabit Lite'
        'PowerSavingMode' = 'Power Saving Mode'
    }
}

function Get-AfNetworkChecks {
    @{
        Id = 'network.ethernet-power'; Category = 'network'
        Title = (T 'Ethernet sin ahorro de energía')
        Why = (T 'El ahorro de energía del adaptador renegocia el enlace y puede meter pausas en la conexión.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'djdallmann, investigación de red'); SourceUrl = 'https://djdallmann.github.io/GamingPCSetup/CONTENT/RESEARCH/NETWORK'
        Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) @($inv.Network | Where-Object Kind -eq 'Ethernet').Count -gt 0 }
        Detect = {
            param($inv)
            $keywords = Get-AfEthernetPowerKeywords
            $changes = @()
            foreach ($nic in @($inv.Network | Where-Object Kind -eq 'Ethernet')) {
                foreach ($keyword in $keywords.Keys) {
                    if ($nic.Properties.ContainsKey($keyword) -and [string]$nic.Properties[$keyword] -ne '0') {
                        $changes += [pscustomobject]@{ Adapter = $nic.Name; Description = $nic.Description; Keyword = $keyword; Name = $keywords[$keyword] }
                    }
                }
            }
            if (-not $changes.Count) { return New-AfDetection -State Ok -Current (T 'Sin ahorro de energía') }
            $current = if ($changes.Count -eq 1) { (T '1 opción activa') } else { (T '{0} opciones activas') -f $changes.Count }
            New-AfDetection -State Improvable -Current $current -Target (T 'Apagadas') -Note (T 'La conexión se corta unos segundos al aplicar') -Data @{ Changes = $changes } `
                -What ((T '{0} del adaptador {1} pasan a apagado.') -f (Join-AfNames @($changes.Name)), $changes[0].Description)
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($change in @($detected.Data.Changes)) { Set-AfNetAdapterProperty -Tx $tx -Adapter $change.Adapter -Keyword $change.Keyword -Value '0' | Out-Null }
        }
    }

    @{
        Id = 'network.wifi-power'; Category = 'network'
        Title = (T 'Wi-Fi sin ahorro de energía')
        Why = (T 'Con el ahorro de energía, el adaptador inalámbrico se duerme entre paquetes y sube la latencia.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: ahorro de energía del Wi-Fi'); SourceUrl = 'https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/wi-fi-power-management-for-modern-standby-platforms'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) @($inv.Network | Where-Object Kind -eq 'WiFi').Count -gt 0 -and $null -ne $inv.Power.WifiPowerAc }
        Detect = {
            param($inv)
            $value = [int]$inv.Power.WifiPowerAc
            if ($value -eq 0) { return New-AfDetection -State Ok -Current (T 'Rendimiento máximo') }
            $name = switch ($value) { 1 { (T 'Ahorro bajo') } 2 { (T 'Ahorro medio') } default { (T 'Ahorro máximo') } }
            New-AfDetection -State Improvable -Current $name -Target (T 'Rendimiento máximo') -Note (T 'Solo con el cargador puesto') `
                -What ((T 'Plan de energía, adaptador inalámbrico con cargador: de {0} a Rendimiento máximo.') -f $name)
        }
        Apply = { param($inv, $detected, $tx) Set-AfPowerSetting -Tx $tx -Subgroup '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1' -Setting '12bbebe6-58d6-4636-95bb-3217ef867c1a' -Ac 0 | Out-Null }
    }

    @{
        Id = 'network.link-100'; Category = 'network'
        Title = (T 'La conexión por cable va a 100 Mbps')
        Why = (T 'El adaptador puede ir a 1 Gbps o más, pero el cable o el puerto lo limitan.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Velocidad de enlace del adaptador'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) @($inv.Network | Where-Object { $_.Kind -eq 'Ethernet' -and $_.Status -eq 'Up' }).Count -gt 0 }
        Detect = {
            param($inv)
            $slow = @($inv.Network | Where-Object { $_.Kind -eq 'Ethernet' -and $_.Status -eq 'Up' -and $_.LinkSpeedMbps -le 100 -and $_.MaxSpeedMbps -ge 1000 }) | Select-Object -First 1
            if (-not $slow) { return New-AfDetection -State Ok }
            New-AfDetection -State Manual -Current ('{0} Mbps' -f $slow.LinkSpeedMbps) -Target (T '1 Gbps') `
                -Steps @((T 'Cambia el cable por uno Cat 5e o mejor: los de 100 Mbps solo tienen 4 hilos.'), (T 'Prueba otro puerto del router o del switch.'), (T 'Si el router solo tiene puertos de 100 Mbps, ese es el límite.'))
        }
    }

    @{
        Id = 'network.wifi-band'; Category = 'network'
        Title = (T 'Wi-Fi en la banda de 2,4 GHz')
        Why = (T 'La banda de 5 GHz es más rápida y tiene menos interferencia, aunque llega un poco menos lejos.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Banda de la conexión Wi-Fi actual'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Wlan -and $inv.Wlan.Connected -and $inv.Wlan.BandGHz }
        Detect = {
            param($inv)
            if ($inv.Wlan.BandGHz -ge 5) { return New-AfDetection -State Ok -Current ('{0} GHz' -f $inv.Wlan.BandGHz) }
            New-AfDetection -State Info -Current (T '2,4 GHz') -Steps @((T 'Si el router tiene una red de 5 GHz, conéctate a esa para jugar.'))
        }
    }

    @{
        Id = 'network.delivery-optimization'; Category = 'network'
        Title = (T 'Optimización de entrega solo en la red local')
        Why = (T 'En modo Internet, Windows sube partes de sus actualizaciones a otros equipos y gasta tu conexión.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: Optimización de entrega'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/deployment/do/waas-delivery-optimization'; Undo = (T 'Se puede deshacer')
        Reads = @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization|DODownloadMode')
        AppliesTo = { param($inv) $inv.DeliveryOptimization -and $inv.DeliveryOptimization.Available }
        Detect = {
            param($inv)
            if ($null -ne $inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization|DODownloadMode']) { return New-AfDetection -State Info -Note (T 'Lo fija una directiva') }
            if (-not $inv.DeliveryOptimization.Mode) { return New-AfDetection -State NotApplicable }
            if ([string]$inv.DeliveryOptimization.Mode -ne 'Internet') { return New-AfDetection -State Ok -Current (T 'Solo red local o sin compartir') }
            New-AfDetection -State Improvable -Current (T 'Internet') -Target (T 'Red local') `
                -What (T 'El modo de descarga pasa de Internet a Red local. Se puede cambiar en Configuración, Windows Update, Opciones avanzadas.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfDeliveryOptimizationMode -Tx $tx -Mode Lan | Out-Null }
    }
}
