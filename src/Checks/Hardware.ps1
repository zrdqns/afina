function Get-AfRatedMemorySpeed {
    param([string]$PartNumber)
    # Velocidad que suele ir en el número de parte (F4-3200C16, CMK16GX4M2B3200C16): de 2400 a 8999.
    $speeds = @([regex]::Matches([string]$PartNumber, '(?<!\d)(2[4-9]\d{2}|[3-8]\d{3})(?!\d)') | ForEach-Object { [int]$_.Value })
    if ($speeds.Count) { ($speeds | Measure-Object -Maximum).Maximum } else { $null }
}

function Get-AfHardwareChecks {
    @{
        Id = 'hardware.ram-single-channel'; Category = 'hardware'
        Title = (T 'RAM en un solo canal')
        Why = (T 'Con un solo módulo la RAM rinde la mitad: en juegos se nota, sobre todo con gráficos integrados.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Configuración de módulos de memoria'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Memory -and $inv.Memory.Socketed }
        Detect = {
            param($inv)
            $modules = @($inv.Memory.Modules)
            if ($modules.Count -ne 1) { return New-AfDetection -State Ok -Current ((T '{0} módulos') -f $modules.Count) }
            $m = $modules[0]
            New-AfDetection -State Manual -Current ((T '{0} GB en un módulo') -f $m.CapacityGB) -Target (T 'Dos módulos iguales') `
                -Steps @(((T 'Compra un módulo igual al actual: {0} GB a {1} MT/s.') -f $m.CapacityGB, $m.Speed), (T 'Instálalo en la ranura libre.'), (T 'Con dos módulos la RAM trabaja en doble canal.'))
        }
    }

    @{
        Id = 'hardware.ram-xmp'; Category = 'hardware'
        Title = (T 'XMP o EXPO apagado')
        Why = (T 'La RAM está trabajando más lento de lo que permite: el perfil de velocidad se activa en la BIOS.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Velocidad de la memoria contra su número de parte'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Device -and -not $inv.Device.IsLaptop -and $inv.Memory -and $inv.Memory.Socketed }
        Detect = {
            param($inv)
            $m = @($inv.Memory.Modules)[0]
            $rated = Get-AfRatedMemorySpeed -PartNumber $m.PartNumber
            if (-not $rated -or $rated -le ($m.ConfiguredSpeed + 100)) { return New-AfDetection -State Ok -Current ('{0} MT/s' -f $m.ConfiguredSpeed) }
            New-AfDetection -State Manual -Current ('{0} MT/s' -f $m.ConfiguredSpeed) -Target ('{0} MT/s' -f $rated) `
                -Steps @((T 'Entra a la BIOS: suele ser con Supr o F2 al encender.'), (T 'Activa XMP (Intel) o EXPO (AMD) en las opciones de memoria.'), (T 'Guarda y reinicia.'))
        }
    }

    @{
        Id = 'hardware.ram-low'; Category = 'hardware'
        Title = (T 'Poca memoria RAM')
        Why = (T 'Con poca RAM, Windows usa el disco como memoria y los juegos se traban.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Memoria instalada'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Memory -and $inv.Memory.TotalGB }
        Detect = {
            param($inv)
            $current = '{0} GB' -f $inv.Memory.TotalGB
            if ($inv.Memory.TotalGB -gt 8) { return New-AfDetection -State Ok -Current $current }
            New-AfDetection -State Info -Current $current -Steps @((T 'Para jugar hoy se recomiendan 16 GB.'))
        }
    }

    @{
        Id = 'hardware.on-battery'; Category = 'hardware'
        Title = (T 'Laptop en batería')
        Why = (T 'En batería, Windows y el fabricante recortan la potencia para que dure más.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Estado de la batería'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Device -and $inv.Device.IsLaptop }
        Detect = {
            param($inv)
            if (-not $inv.Device.OnBattery) { return New-AfDetection -State Ok -Current (T 'Con cargador') }
            New-AfDetection -State Info -Current (T 'En batería') -Steps @((T 'Conecta el cargador para jugar y para que este análisis refleje el rendimiento real.'))
        }
    }
}
