function Get-AfMedian {
    param([double[]]$Values)
    $sorted = @($Values | Sort-Object)
    $mid = [int][math]::Floor($sorted.Count / 2)
    if ($sorted.Count % 2) { $sorted[$mid] } else { ($sorted[$mid - 1] + $sorted[$mid]) / 2 }
}

# Estado de un disco: 2 = Manual, 1 = Info, 0 = Ok. Los errores solos nunca pasan de Info.
function Get-AfDiskState {
    param([Parameter(Mandatory)]$Disk)
    $name = $Disk.Name
    $rank = 0
    $line = $null
    $health = [string]$Disk.Health
    if ($health -and $health -notin 'Healthy', 'Unknown') {
        $text = switch ($health) {
            'Unhealthy' { T '{0}: Windows lo marca en mal estado' }
            'Warning' { T '{0}: Windows lo marca con advertencia' }
            default { T '{0}: Windows reporta un problema de salud' }
        }
        return @{ Rank = 2; Wear = -1; Line = ($text -f $name) }
    }
    $wear = $Disk.Wear
    if ($null -ne $wear) {
        if ($wear -ge 90) { return @{ Rank = 2; Wear = $wear; Line = ((T '{0}: desgaste {1} %') -f $name, $wear) } }
        if ($wear -ge 70) { $rank = 1; $line = (T '{0}: desgaste {1} %') -f $name, $wear }
    }
    if (-not $rank) {
        $errors = [long]$Disk.ReadErrors + [long]$Disk.WriteErrors
        if ($errors -gt 0) { $rank = 1; $line = (T '{0}: errores sin corregir ({1})') -f $name, $errors }
        elseif ($Disk.TemperatureMax -and $Disk.TemperatureMax -gt 0 -and $null -ne $Disk.Temperature -and $Disk.Temperature -ge $Disk.TemperatureMax) {
            $rank = 1; $line = (T '{0}: temperatura en su máximo ({1} °C)') -f $name, $Disk.Temperature
        }
    }
    if (-not $line) {
        $line = if ($health -eq 'Healthy' -and $null -eq $wear) { (T 'Buena, sin datos de desgaste') }
        elseif ($health -eq 'Healthy') { (T 'Buena, desgaste {0} %') -f $wear }
        elseif ($null -ne $wear) { (T 'Desgaste {0} %') -f $wear }
        else { (T 'Sin datos de desgaste') }
    }
    @{ Rank = $rank; Wear = $(if ($null -ne $wear) { $wear } else { -1 }); Line = $line }
}

function Get-AfDiskDetection {
    param($Health)
    $disks = @($Health.Disks | Where-Object { $_ })
    $steps = @((T 'Respalda tus archivos ya.'), (T 'Cambia el disco cuanto antes.'))
    if (-not $disks.Count) {
        # Sin lista de discos, una falla predicha sigue contando.
        if ($Health.PredictFailure) { return New-AfDetection -State Manual -Current (T 'Windows predice una falla de disco') -Steps $steps }
        return New-AfDetection -State NotApplicable
    }
    $states = @($disks | ForEach-Object {
            $state = Get-AfDiskState -Disk $_
            # Con varios discos, cada línea dice de cuál habla.
            if ($disks.Count -gt 1 -and -not $state.Line.StartsWith($_.Name + ':')) { $state.Line = '{0}: {1}' -f $_.Name, $state.Line }
            $state
        })
    $worst = $states | Sort-Object @{ Expression = { $_.Rank }; Descending = $true }, @{ Expression = { $_.Wear }; Descending = $true } | Select-Object -First 1
    $rank = $worst.Rank
    $current = $worst.Line
    if ($Health.PredictFailure) { $rank = 2; $current = (T 'Windows predice una falla de disco') }
    $details = if ($states.Count -gt 1) { ($states | ForEach-Object { $_.Line }) -join '; ' }
    $data = @{ Lines = @($states | ForEach-Object { $_.Line }) }
    switch ($rank) {
        2 { New-AfDetection -State Manual -Current $current -Note $details -Data $data -Steps $steps }
        1 { New-AfDetection -State Info -Current $current -Note $details -Data $data -Steps @((T 'Mantén un respaldo al día y vigila el disco.')) }
        default { New-AfDetection -State Ok -Current $current -Note $details -Data $data }
    }
}

function Get-AfBatteryDetection {
    param($Health)
    if (-not $Health -or $Health.DesignMWh -le 0 -or $Health.FullMWh -le 0) { return New-AfDetection -State NotApplicable }
    $percent = [int][math]::Min(100, [math]::Round(100.0 * $Health.FullMWh / $Health.DesignMWh, [MidpointRounding]::AwayFromZero))
    $current = (T 'Conserva el {0} % de su capacidad') -f $percent
    $note = if ($Health.Cycles -gt 0) { (T '{0} ciclos de carga') -f $Health.Cycles }
    if ($percent -ge 80) { return New-AfDetection -State Ok -Current $current -Note $note -Data @{ Percent = $percent } }
    if ($percent -ge 60) {
        return New-AfDetection -State Info -Current $current -Note $note -Data @{ Percent = $percent } -Steps @((T 'La batería ya dura menos que cuando era nueva.'))
    }
    New-AfDetection -State Manual -Current $current -Note $note -Data @{ Percent = $percent } `
        -Steps @((T 'La batería está muy gastada: conviene cambiarla.'), (T 'Mientras tanto, usa la laptop con el cargador conectado.'))
}

function Get-AfBootDetection {
    param($Boots)
    # Un lector sin salida entrega $null, y @($null) cuenta como un elemento.
    $boots = @($Boots | Where-Object { $_ })
    if (-not $boots.Count) { return New-AfDetection -State Info -Current (T 'Sin datos recientes') }
    $seconds = [int][math]::Round((Get-AfMedian -Values @($boots | ForEach-Object { [double]$_.MainPathMs })) / 1000, [MidpointRounding]::AwayFromZero)
    $last = ($boots | Sort-Object { $_.Time } -Descending | Select-Object -First 1).Time
    $note = (T 'Último arranque medido: {0}') -f $last.ToString('g', (Get-AfCulture))
    $current = (T '{0} s hasta el escritorio') -f $seconds
    if ($seconds -le 60) { return New-AfDetection -State Ok -Current $current -Note $note -Data @{ Seconds = $seconds } }
    New-AfDetection -State Info -Current $current -Note $note -Data @{ Seconds = $seconds } -Steps @((T 'Revisa los programas de la categoría Inicio: son lo que más alarga el arranque.'))
}

# Servicios que los "optimizadores" deshabilitan y Windows necesita, con el inicio que traen Windows 10 y 11.
# Se cambian con sc.exe y solo si están deshabilitados: nunca se apaga ni se pasa a manual ninguno.
function Get-AfServiceGroups {
    @(
        @{ Id = 'print'; Label = (T 'Impresión'); Services = [ordered]@{ Spooler = 'auto' } }
        @{ Id = 'update'; Label = 'Windows Update'; Services = [ordered]@{ wuauserv = 'demand'; UsoSvc = 'delayed-auto'; BITS = 'demand' } }
        @{ Id = 'store'; Label = 'Microsoft Store'; Services = [ordered]@{ ClipSVC = 'demand'; InstallService = 'demand'; wlidsvc = 'demand' } }
        @{ Id = 'xbox'; Label = (T 'Xbox (Game Pass, mandos)'); Services = [ordered]@{ XblAuthManager = 'demand'; XblGameSave = 'demand'; XboxNetApiSvc = 'demand'; XboxGipSvc = 'demand' } }
        @{ Id = 'bluetooth'; Label = 'Bluetooth'; Services = [ordered]@{ bthserv = 'demand' } }
        @{ Id = 'location'; Label = (T 'Ubicación'); Services = [ordered]@{ lfsvc = 'demand' } }
        @{ Id = 'history'; Label = (T 'Historial de archivos'); Services = [ordered]@{ fhsvc = 'demand' } }
        @{ Id = 'troubleshoot'; Label = (T 'Solucionador de problemas'); Services = [ordered]@{ DPS = 'auto'; diagsvc = 'demand' } }
        @{ Id = 'smartcard'; Label = (T 'Tarjetas inteligentes'); Services = [ordered]@{ SCardSvr = 'demand' } }
        # La directiva AllowGameDVR = 0 apaga las capturas de Game Bar: solo se borra, nunca se escribe.
        @{ Id = 'captures'; Label = (T 'Capturas de Game Bar'); Services = [ordered]@{}; Policy = $true }
    )
}

function Get-AfGameDvrPolicy { @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name = 'AllowGameDVR' } }

function Get-AfServiceRepairReads {
    foreach ($group in Get-AfServiceGroups) { foreach ($name in $group.Services.Keys) { "HKLM:\SYSTEM\CurrentControlSet\Services\$name|Start" } }
    $policy = Get-AfGameDvrPolicy
    '{0}|{1}' -f $policy.Path, $policy.Name
}

function Get-AfServiceRepairDetection {
    param([hashtable]$Registry = @{})
    $policy = Get-AfGameDvrPolicy
    $choices = @(foreach ($group in Get-AfServiceGroups) {
            $off = @(foreach ($name in $group.Services.Keys) {
                    if ($Registry["HKLM:\SYSTEM\CurrentControlSet\Services\$name|Start"] -eq 4) { [pscustomobject]@{ Name = $name; Mode = $group.Services[$name] } }
                })
            $blocked = [bool]$group.Policy -and $Registry[('{0}|{1}' -f $policy.Path, $policy.Name)] -eq 0
            if ($off.Count -or $blocked) {
                # Selected empieza igual que Preselected: la fila viene marcada y la interfaz solo lo cambia si el usuario toca una opción.
                [pscustomobject]@{ Name = $group.Id; Label = $group.Label; Path = (@($off.Name) -join ', '); Services = $off; Policy = $blocked; Preselected = $true; Selected = $true }
            }
        })
    if (-not $choices.Count) { return New-AfDetection -State Ok -Current (T 'Como vienen en Windows') }
    $title = if ($choices.Count -eq 1) { (T '1 función de Windows deshabilitada') } else { (T '{0} funciones de Windows deshabilitadas') -f $choices.Count }
    New-AfDetection -State Improvable -Title $title -Current (Join-AfNames @($choices.Label)) -Target (T 'Como vienen en Windows') `
        -Data @{ Choices = $choices; ChoicesLabel = (T 'Qué habilitar') } -What (T 'Vuelve a habilitar lo elegido con el inicio que trae Windows. Pide reiniciar.')
}

function Repair-AfServiceChoice {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)]$Choice)
    foreach ($service in @($Choice.Services | Where-Object { $_ })) { Set-AfServiceStart -Tx $Tx -Name $service.Name -Mode $service.Mode | Out-Null }
    if ($Choice.Policy) {
        $policy = Get-AfGameDvrPolicy
        Remove-AfRegistryValue -Tx $Tx -Path $policy.Path -Name $policy.Name | Out-Null
    }
}

function Get-AfDiagnosticsChecks {
    @{
        Id = 'hardware.disk-health'; Category = 'hardware'
        Title = (T 'Salud del disco')
        Why = (T 'Un disco con desgaste alto o fallas puede dejar de funcionar sin aviso y llevarse tus archivos.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Contadores de confiabilidad del almacenamiento de Windows'); Undo = (T 'No cambia nada')
        Reading = $true; Async = $true
        Detect = { param($inv) New-AfDetection -State Info -Current (T 'Revisando…') -Data @{ Async = $true } }
        AsyncDetect = {
            param($inv)
            try { Get-AfDiskDetection -Health (Get-AfDiskHealth) } catch { New-AfDetection -State NotApplicable }
        }
    }

    @{
        Id = 'hardware.battery-health'; Category = 'hardware'
        Title = (T 'Salud de la batería')
        Why = (T 'Una batería gastada dura menos y puede limitar el rendimiento de la laptop.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Capacidad de diseño y de carga completa de la batería'); Undo = (T 'No cambia nada')
        Reading = $true; Async = $true
        AppliesTo = { param($inv) $inv.Device -and $inv.Device.IsLaptop }
        Detect = { param($inv) New-AfDetection -State Info -Current (T 'Revisando…') -Data @{ Async = $true } }
        AsyncDetect = {
            param($inv)
            try { Get-AfBatteryDetection -Health (Get-AfBatteryHealth) } catch { New-AfDetection -State NotApplicable }
        }
    }

    @{
        Id = 'hardware.boot-time'; Category = 'hardware'
        Title = (T 'Tiempo de arranque')
        Why = (T 'Un arranque largo suele venir de programas que se abren con Windows.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Registro de rendimiento del arranque de Windows'); Undo = (T 'No cambia nada')
        Reading = $true; Async = $true
        Detect = { param($inv) New-AfDetection -State Info -Current (T 'Revisando…') -Data @{ Async = $true } }
        AsyncDetect = {
            param($inv)
            try { Get-AfBootDetection -Boots (Get-AfBootTimes -Max 5 -Days 30) } catch { New-AfDetection -State Info -Current (T 'Sin datos recientes') }
        }
    }

    @{
        Id = 'hardware.pagefile'; Category = 'hardware'
        Title = (T 'Archivo de paginación')
        Why = (T 'Si el archivo de paginación está apagado o es muy chico, los juegos y apps pesadas pueden cerrarse por falta de memoria.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $true
        Source = (T 'Configuración del archivo de paginación de Windows'); Undo = (T 'Vuelve a la configuración anterior')
        Reading = $true
        Detect = {
            param($inv)
            $page = $inv.Pagefile
            if (-not $page) { return New-AfDetection -State NotApplicable }
            if ($page.Automatic) { return New-AfDetection -State Ok -Current (T 'Automático') }
            $files = @($page.Files)
            # MaximumSize = 0 significa que el sistema maneja el tamaño.
            if ($files | Where-Object { $_.MaxMB -eq 0 }) { return New-AfDetection -State Ok -Current (T 'Lo maneja Windows') }
            $totalMB = 0
            foreach ($file in $files) { $totalMB += [int]$file.MaxMB }
            if ($files.Count -and $totalMB -ge 4096) { return New-AfDetection -State Ok -Current ((T '{0} MB fijos') -f $totalMB) }
            $current = if ($files.Count) { (T '{0} MB fijos') -f $totalMB } else { (T 'Apagado') }
            # Sin dato de espacio no se afirma nada del disco: el arreglo se ofrece, pero sin marcar.
            if ($null -eq $inv.Storage -or $null -eq $inv.Storage.FreeBytes) {
                return New-AfDetection -State Improvable -Current $current -Target (T 'Automático') -Preselect $false -What (T 'Deja que Windows maneje el archivo de paginación. Pide reiniciar.')
            }
            if ([long]$inv.Storage.FreeBytes -lt 4GB) {
                return New-AfDetection -State Manual -Current $current -Target (T 'Automático') -Steps @((T 'Libera espacio primero: hacen falta al menos 4 GB libres.'))
            }
            New-AfDetection -State Improvable -Current $current -Target (T 'Automático') -What (T 'Deja que Windows maneje el archivo de paginación. Pide reiniciar.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfPagefileAuto -Tx $tx | Out-Null }
    }

    @{
        Id = 'hardware.services'; Category = 'hardware'
        Title = (T 'Servicios de Windows habilitados')
        Why = (T 'Algunos "optimizadores" deshabilitan servicios que Windows necesita: después no se puede imprimir, actualizar o jugar con Game Pass.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $true
        Source = (T 'Inicio de fábrica de los servicios de Windows 10 y 11'); Undo = (T 'Se puede deshacer')
        Reads = @(Get-AfServiceRepairReads)
        AppliesTo = { param($inv) $null -ne $inv.Registry }
        Detect = { param($inv) Get-AfServiceRepairDetection -Registry $inv.Registry }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($choice in @($detected.Data.Choices | Where-Object { $_.Selected })) { Repair-AfServiceChoice -Tx $tx -Choice $choice }
        }
    }
}
