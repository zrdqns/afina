function Get-AfDisplayLabel {
    param($Display, [int]$Index)
    if ($Display.IsPrimary) { (T 'Pantalla principal') } else { (T 'Pantalla {0}') -f ($Index + 1) }
}

# Pone SwapEffectUpgradeEnable=1 en la cadena de DirectX y conserva el resto de las claves.
function Get-AfWindowedOptimizationsValue {
    param([string]$Current)
    if ($Current -match 'SwapEffectUpgradeEnable=\d;') { return $Current -replace 'SwapEffectUpgradeEnable=\d;', 'SwapEffectUpgradeEnable=1;' }
    $base = if ($Current -and -not $Current.EndsWith(';')) { $Current + ';' } else { [string]$Current }
    $base + 'SwapEffectUpgradeEnable=1;'
}

# PC débil: 8 GB de RAM o menos, o Windows en un disco HDD.
function Test-AfWeakPc {
    param([Parameter(Mandatory)]$Inventory)
    ($Inventory.Memory -and [double]$Inventory.Memory.TotalGB -gt 0 -and [double]$Inventory.Memory.TotalGB -le 8) -or
    ($Inventory.Storage -and $Inventory.Storage.MediaType -eq 'HDD')
}

function Get-AfGamingChecks {
    @{
        Id = 'display.refresh'; Category = 'gaming'
        Title = (T 'Pantalla a su frecuencia máxima')
        Why = (T 'Muchas pantallas de 144 Hz o más vienen puestas a 60 Hz; con más Hz el juego se ve y se siente más fluido.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: frecuencia de actualización de la pantalla'); SourceUrl = 'https://support.microsoft.com/en-us/windows/hardware/display-graphics/change-the-refresh-rate-on-your-monitor-in-windows'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) @($inv.Displays).Count -gt 0 }
        Detect = {
            param($inv)
            $displays = @($inv.Displays)
            $slow = @()
            for ($i = 0; $i -lt $displays.Count; $i++) {
                $d = $displays[$i]
                if ($d.MaxHzAtCurrentRes -gt $d.Hz) {
                    $slow += [pscustomobject]@{ Label = Get-AfDisplayLabel -Display $d -Index $i; DeviceName = $d.DeviceName; Width = $d.Width; Height = $d.Height; Hz = $d.Hz; MaxHz = $d.MaxHzAtCurrentRes }
                }
            }
            if (-not $slow.Count) { return New-AfDetection -State Ok -Current ('{0} Hz' -f $displays[0].Hz) }
            $first = $slow[0]
            New-AfDetection -State Improvable -Current ('{0} Hz' -f $first.Hz) -Target ('{0} Hz' -f $first.MaxHz) -Data @{ Displays = $slow } `
                -What ((T '{0} a {1} × {2}, de {3} a {4} Hz. Pregunta si se ve bien y vuelve sola al modo anterior a los 15 s si nadie responde.') -f $first.Label, $first.Width, $first.Height, $first.Hz, $first.MaxHz)
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($d in @($detected.Data.Displays)) { Set-AfDisplayMode -Tx $tx -DeviceName $d.DeviceName -Label $d.Label -Width $d.Width -Height $d.Height -Hz $d.MaxHz | Out-Null }
            Confirm-AfDisplayChange -Tx $tx
        }
    }

    @{
        Id = 'display.cable-limit'; Category = 'gaming'
        Title = (T 'El cable o el puerto limita la pantalla')
        Why = (T 'El monitor anuncia más Hz de los que Windows puede usar con esta conexión.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Datos EDID del monitor'); Undo = (T 'No cambia nada')
        # Con una gráfica sin driver, el límite es el driver básico, no el cable (lo dice gpu.driver-missing).
        AppliesTo = { param($inv) @($inv.Displays | Where-Object { $_.EdidMaxHz }).Count -gt 0 -and @($inv.Gpus | Where-Object { $_.HasDriver -eq $false }).Count -eq 0 }
        Detect = {
            param($inv)
            $limited = @($inv.Displays | Where-Object { $_.EdidMaxHz -and $_.EdidMaxHz -gt ($_.MaxHzAtCurrentRes + 1) }) | Select-Object -First 1
            if (-not $limited) { return New-AfDetection -State Ok }
            New-AfDetection -State Manual -Current ('{0} Hz' -f $limited.MaxHzAtCurrentRes) -Target ('{0} Hz' -f $limited.EdidMaxHz) `
                -Steps @((T 'Usa un cable DisplayPort, o HDMI 2.0 o superior.'), (T 'En laptops, conecta el monitor al puerto que va a la gráfica dedicada (suele ser el HDMI o un USB-C con DisplayPort).'), (T 'Revisa en el menú del monitor que la entrada no esté en un modo de compatibilidad.'))
        }
    }

    @{
        Id = 'gpu.hags'; Category = 'gaming'
        Title = (T 'Programación de GPU por hardware')
        Why = (T 'La gráfica organiza su propio trabajo y baja la latencia; DLSS Frame Generation la necesita.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $true
        Source = (T 'Microsoft DirectX: programación de GPU por hardware'); SourceUrl = 'https://devblogs.microsoft.com/directx/hardware-accelerated-gpu-scheduling/'; Undo = (T 'Se puede deshacer')
        Reads = @('HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode')
        AppliesTo = { param($inv) $inv.Os.Build -ge 19041 -and @($inv.Gpus | Where-Object { $_.IsDiscrete -and $_.WddmVersion -ge 2.7 }).Count -gt 0 }
        Detect = {
            param($inv)
            $value = $inv.Registry['HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode']
            if ($value -eq 2) { return New-AfDetection -State Ok -Current (T 'Activada') }
            $from = if ($null -eq $value) { (T 'sin valor') } else { $value }
            New-AfDetection -State Improvable -Current (T 'Apagada') -Target (T 'Activada') -What ((T 'HwSchMode pasa de {0} a 2. Pide reiniciar.') -f $from)
        }
        Apply = { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -Type DWord -Value 2 | Out-Null }
    }

    @{
        Id = 'gaming.game-mode'; Category = 'gaming'
        Title = (T 'Modo de juego activado')
        Why = (T 'Windows da prioridad al juego y frena tareas de fondo como las actualizaciones mientras juegas.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: modo de juego'); SourceUrl = 'https://support.microsoft.com/en-us/help/4028293/windows-using-game-mode-on-your-pc'; Undo = (T 'Se puede deshacer')
        Reads = @('HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled')
        Detect = {
            param($inv)
            $value = $inv.Registry['HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled']
            if ($null -eq $value -or $value -eq 1) { return New-AfDetection -State Ok -Current (T 'Activado') }
            New-AfDetection -State Improvable -Current (T 'Apagado') -Target (T 'Activado') -What (T 'AutoGameModeEnabled pasa de 0 a 1.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Type DWord -Value 1 | Out-Null }
    }

    @{
        Id = 'gaming.background-recording'; Category = 'gaming'
        Title = (T 'Grabación en segundo plano apagada')
        Why = (T 'Con la grabación de fondo, Xbox Game Bar graba todo el tiempo y le quita rendimiento a la gráfica.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft, blog de Xbox: grabación en segundo plano'); SourceUrl = 'https://news.xbox.com/en-us/2016/10/14/tips-on-windows-10-and-game-dvr-optimization/'; Undo = (T 'Se puede deshacer')
        Reads = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR|HistoricalCaptureEnabled')
        Detect = {
            param($inv)
            $value = $inv.Registry['HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR|HistoricalCaptureEnabled']
            if ($value -ne 1) { return New-AfDetection -State Ok -Current (T 'Apagada') }
            New-AfDetection -State Improvable -Current (T 'Activa') -Target (T 'Apagada') -Note (T 'Xbox Game Bar graba todo el tiempo') `
                -What (T 'Se apaga "Grabar lo que pasó" de Xbox Game Bar. Las capturas manuales siguen funcionando.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'HistoricalCaptureEnabled' -Type DWord -Value 0 | Out-Null }
    }

    @{
        Id = 'gaming.windowed-optimizations'; Category = 'gaming'
        Title = (T 'Optimizaciones para juegos en ventana')
        Why = (T 'Los juegos DirectX 10 y 11 en ventana o sin bordes usan el mismo camino rápido que en pantalla completa: menos latencia.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: optimizaciones para juegos en ventana'); SourceUrl = 'https://support.microsoft.com/en-us/windows/hardware/display-graphics/optimizations-for-windowed-games-in-windows-11'; Undo = (T 'Se puede deshacer')
        Reads = @('HKCU:\Software\Microsoft\DirectX\UserGpuPreferences|DirectXUserGlobalSettings')
        AppliesTo = { param($inv) $inv.Os.IsWin11 }
        Detect = {
            param($inv)
            $value = [string]$inv.Registry['HKCU:\Software\Microsoft\DirectX\UserGpuPreferences|DirectXUserGlobalSettings']
            if ($value -match 'SwapEffectUpgradeEnable=1;') { return New-AfDetection -State Ok -Current (T 'Activadas') }
            New-AfDetection -State Improvable -Current (T 'Apagadas') -Target (T 'Activadas') -What (T 'Se agrega SwapEffectUpgradeEnable=1 a la configuración de DirectX, sin tocar lo demás.')
        }
        Apply = {
            param($inv, $detected, $tx)
            $path = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
            $current = [string](Get-AfRegistryValue -Path $path -Name 'DirectXUserGlobalSettings' -User $tx.User)
            Set-AfRegistryValue -Tx $tx -Path $path -Name 'DirectXUserGlobalSettings' -Type String -Value (Get-AfWindowedOptimizationsValue -Current $current) | Out-Null
        }
    }

    @{
        Id = 'gaming.mouse-acceleration'; Category = 'gaming'
        Title = (T 'Aceleración del mouse apagada')
        Why = (T '"Mejorar la precisión del puntero" mueve el cursor según la velocidad del mouse, y apuntar se vuelve menos predecible en los juegos.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft: opciones del puntero del mouse'); SourceUrl = 'https://support.microsoft.com/en-us/windows/change-mouse-settings-e81356a4-0e74-fe38-7d01-9d79fbf8712b'; Undo = (T 'Se puede deshacer')
        Reads = @('HKCU:\Control Panel\Mouse|MouseSpeed')
        AppliesTo = { param($inv) $inv.User -and $inv.User.IsSameAsProcess -and $null -ne $inv.Registry['HKCU:\Control Panel\Mouse|MouseSpeed'] }
        Detect = {
            param($inv)
            if ([string]$inv.Registry['HKCU:\Control Panel\Mouse|MouseSpeed'] -eq '0') { return New-AfDetection -State Ok -Current (T 'Apagada') }
            New-AfDetection -State Improvable -Current (T 'Activa') -Target (T 'Apagada') -Note (T 'Cambia cómo se siente el mouse') `
                -What (T 'Se apaga "Mejorar la precisión del puntero". La velocidad del puntero no cambia.')
        }
        Apply = {
            param($inv, $detected, $tx)
            Set-AfSystemParameter -Tx $tx -Name Mouse -Value @(0, 0, 0) | Out-Null
            foreach ($name in 'MouseSpeed', 'MouseThreshold1', 'MouseThreshold2') {
                Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Control Panel\Mouse' -Name $name -Type String -Value '0' | Out-Null
            }
        }
    }

    @{
        Id = 'gaming.visual-effects'; Category = 'gaming'
        Title = (T 'Menos efectos visuales en esta PC')
        Why = (T 'Con poca memoria o con disco HDD, las animaciones y la transparencia le quitan fluidez a Windows.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: efectos visuales de Windows'); SourceUrl = 'https://support.microsoft.com/en-us/windows/experience/performance-optimization/tips-to-improve-pc-performance-in-windows'; Undo = (T 'Se puede deshacer')
        Reads = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize|EnableTransparency')
        AppliesTo = { param($inv) $inv.User -and $inv.User.IsSameAsProcess -and $inv.Effects -and (Test-AfWeakPc -Inventory $inv) }
        Detect = {
            param($inv)
            $transparency = $inv.Registry['HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize|EnableTransparency'] -ne 0
            if (-not $inv.Effects.ClientAreaAnimation -and -not $transparency) { return New-AfDetection -State Ok -Current (T 'Apagados') }
            New-AfDetection -State Improvable -Current (T 'Activos') -Target (T 'Apagados') `
                -What (T 'Se apagan "Efectos de animación" y "Efectos de transparencia" de Accesibilidad. El suavizado de fuentes se queda como está.')
        }
        Apply = {
            param($inv, $detected, $tx)
            Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Type DWord -Value 0 | Out-Null
            Set-AfSystemParameter -Tx $tx -Name ClientAreaAnimation -Value $false | Out-Null
            Send-AfShellNotify -Area 'ImmersiveColorSet'
        }
    }

    @{
        Id = 'gpu.driver-missing'; Category = 'gaming'
        Title = (T 'La gráfica no tiene su driver')
        Why = (T 'Sin su driver, Windows usa uno básico: los juegos casi no funcionan y la pantalla no llega a sus Hz.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Fabricante de la gráfica'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) @($inv.Gpus).Count -gt 0 }
        Detect = {
            param($inv)
            $gpu = @($inv.Gpus | Where-Object { $_.HasDriver -eq $false })[0]
            if (-not $gpu) { return New-AfDetection -State Ok -Current (T 'Instalado') }
            $steps = switch ($gpu.Vendor) {
                'NVIDIA' { @((T 'Descarga NVIDIA App desde nvidia.com.'), (T 'Instala el driver Game Ready que proponga.'), (T 'Reinicia la PC.')) }
                'AMD' { @((T 'Descarga AMD Software: Adrenalin Edition desde amd.com; detecta la gráfica sola.'), (T 'Instala el driver recomendado.'), (T 'Reinicia la PC.')) }
                'Intel' { @((T 'Descarga Intel Driver & Support Assistant desde intel.com.'), (T 'Instala el driver de gráficos que proponga.'), (T 'Reinicia la PC.')) }
                default { @((T 'Abre Configuración, Windows Update, Opciones avanzadas, Actualizaciones opcionales, e instala el driver de pantalla.'), (T 'Si no aparece, descárgalo del sitio del fabricante de la PC.')) }
            }
            $title = if ($gpu.Vendor -in 'NVIDIA', 'AMD', 'Intel') { (T 'La gráfica de {0} no tiene su driver') -f $gpu.Vendor } else { (T 'La gráfica no tiene su driver') }
            New-AfDetection -State Manual -Title $title -Current (T 'Driver básico de Windows') -Target (T 'Driver del fabricante') -Steps $steps
        }
    }

    @{
        Id = 'gpu.driver-age'; Category = 'gaming'
        Title = (T 'Driver de gráficos al día')
        Why = (T 'Los drivers nuevos traen mejoras de rendimiento y arreglos para los juegos recientes.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Fabricante de la gráfica'); Undo = (T 'No cambia nada')
        # Solo gráficas con su driver; las que no lo tienen las ve gpu.driver-missing.
        AppliesTo = { param($inv) @($inv.Gpus | Where-Object { $_.HasDriver -ne $false }).Count -gt 0 }
        Detect = {
            param($inv)
            $gpus = @($inv.Gpus | Where-Object { $_.HasDriver -ne $false })
            $gpu = @($gpus | Where-Object IsDiscrete)[0]
            if (-not $gpu) { $gpu = $gpus[0] }
            if (-not $gpu.DriverDate) { return New-AfDetection -State NotApplicable }
            $days = ((Get-Date) - [datetime]$gpu.DriverDate).TotalDays
            if ($days -le 180) { return New-AfDetection -State Ok -Current (T 'Al día') }
            $months = [math]::Floor($days / 30)
            $steps = switch ($gpu.Vendor) {
                'NVIDIA' { @((T 'Abre NVIDIA App.'), (T 'Entra a Controladores.'), (T 'Instala el Game Ready más reciente sin instalación limpia.')) }
                'AMD' { @((T 'Abre AMD Software: Adrenalin Edition.'), (T 'Entra a Controladores y software.'), (T 'Instala la versión recomendada.')) }
                'Intel' { @((T 'Abre Intel Driver & Support Assistant, o descárgalo de intel.com.'), (T 'Instala el driver de gráficos que proponga.')) }
                default { @((T 'Descarga el driver más reciente desde el sitio del fabricante de la gráfica.')) }
            }
            $who = if ($gpu.Vendor -in 'NVIDIA', 'AMD', 'Intel') { $gpu.Vendor } else { (T 'la gráfica') }
            New-AfDetection -State Manual -Title ((T 'Driver de {0} de hace {1} meses') -f $who, $months) -Current ((T 'Hace {0} meses') -f $months) -Steps $steps
        }
    }

    @{
        Id = 'gpu.hybrid'; Category = 'gaming'
        Title = (T 'Esta laptop tiene dos gráficas')
        Why = (T 'Si un juego corre en la gráfica integrada, rinde mucho menos.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft: preferencia de gráficos por app'); SourceUrl = 'https://devblogs.microsoft.com/directx/navigating-the-redesigned-graphics-settings-page/'; Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Device.IsLaptop -and @($inv.Gpus | Where-Object IsDiscrete).Count -gt 0 -and @($inv.Gpus | Where-Object { -not $_.IsDiscrete }).Count -gt 0 }
        Detect = {
            param($inv)
            New-AfDetection -State Info -Steps @((T 'Abre Configuración, Sistema, Pantalla, Gráficos.'), (T 'Elige cada juego y márcalo en Alto rendimiento.'), (T 'En NVIDIA App o en el panel de la gráfica, revisa que la dedicada sea la preferida.'))
        }
    }

    @{
        Id = 'gpu.rebar'; Category = 'gaming'
        Title = (T 'Resizable BAR activo')
        Why = (T 'Con Resizable BAR el procesador usa toda la memoria de la gráfica de una vez; en muchos juegos sube los FPS.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Tamaño de la ventana de memoria de la gráfica'); Undo = (T 'No cambia nada')
        # Solo escritorios con una gráfica que lo admite (RTX 30 o más nueva, RX 6000 o más nueva, Intel Arc): en laptops lo decide el fabricante.
        AppliesTo = { param($inv) $inv.Device -and -not $inv.Device.IsLaptop -and [bool](Get-AfRebarGpu -Inventory $inv) }
        Detect = {
            param($inv)
            $gpu = Get-AfRebarGpu -Inventory $inv
            if ($gpu.WindowMB -ge 1024) { return New-AfDetection -State Ok -Current (T 'Activo') }
            # Windows en modo heredado (BIOS con CSM): sin UEFI la opción no se puede usar.
            $steps = if ($inv.Device.Firmware -eq 'BIOS') {
                @((T 'Windows arranca en modo heredado: Resizable BAR necesita UEFI.'), (T 'Antes de apagar CSM hay que convertir el disco a GPT con mbr2gpt; al revés, Windows no arranca.'))
            } else {
                @((T 'Entra a la BIOS: pulsa Supr o F2 al encender la PC.'), (T 'Activa Above 4G Decoding y Re-Size BAR Support (en AMD puede llamarse Smart Access Memory).'), (T 'Si no aparece, actualiza la BIOS de la placa.'))
            }
            New-AfDetection -State Manual -Title (T 'Resizable BAR apagado') -Current $gpu.Name -Steps $steps
        }
    }
}

function Get-AfRebarGpu {
    param($Inventory)
    @($Inventory.Gpus | Where-Object { $_.IsDiscrete -and $null -ne $_.WindowMB -and $_.Name -match 'RTX\s?(30|40|50)\d{2}|RX\s?(6|7|9)\d{3}|Arc\b' })[0]
}
