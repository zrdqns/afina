function Format-AfSize {
    param([double]$Bytes)
    $culture = Get-AfCulture
    if ($Bytes -ge 1GB) { return ($Bytes / 1GB).ToString('0.0', $culture) + ' GB' }
    ([math]::Round($Bytes / 1MB)).ToString($culture) + ' MB'
}

function Get-AfStorageChecks {
    @{
        Id = 'storage.free-space'; Category = 'storage'
        Title = (T 'Poco espacio libre en el disco')
        Why = (T 'Windows y los juegos necesitan espacio libre para actualizarse y para su memoria virtual.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Espacio libre del disco del sistema'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Storage -and $inv.Storage.SizeGB }
        Detect = {
            param($inv)
            $current = (T '{0} GB libres') -f [math]::Round([double]$inv.Storage.FreeGB)
            if (-not (Test-AfLowDisk -Storage $inv.Storage)) { return New-AfDetection -State Ok -Current $current }
            New-AfDetection -State Info -Current $current -Steps @((T 'Borra los temporales (abajo) y desinstala los juegos que ya no usas.'))
        }
    }

    @{
        Id = 'storage.temp'; Category = 'storage'
        Title = (T 'Borrar archivos temporales')
        Why = (T 'Temporales y cachés viejas ocupan espacio que Windows y los juegos necesitan.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: liberar espacio en el disco'); SourceUrl = 'https://support.microsoft.com/en-us/windows/experience/storage-filemanagement/free-up-drive-space-in-windows'; Undo = (T 'No se puede deshacer: solo borra temporales'); NoUndo = $true
        AppliesTo = { param($inv) $inv.Storage -and $inv.Storage.TempBytes }
        Detect = {
            param($inv)
            $t = $inv.Storage.TempBytes
            $total = [double]($t.User + $t.Windows + $t.UpdateCache + $t.DeliveryOptimization + $t.ErrorReports)
            if ($total -lt 100MB) { return New-AfDetection -State Ok -Current (T 'Menos de 100 MB') }
            New-AfDetection -State Improvable -Current (Format-AfSize -Bytes $total) -Target (T 'Liberados') -Preselect ($total -gt 1GB) `
                -What (T 'Temporales de Windows y del usuario, y cachés de Windows Update y de Optimización de distribución.')
        }
        Apply = { param($inv, $detected, $tx) Clear-AfTempFiles -Tx $tx -Inventory $inv }
    }

    @{
        Id = 'storage.trim'; Category = 'storage'
        Title = (T 'TRIM del SSD activado')
        Why = (T 'Con TRIM, el SSD sabe qué bloques puede limpiar y mantiene su velocidad con el tiempo.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: fsutil behavior DisableDeleteNotify'); SourceUrl = 'https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-behavior'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) $inv.Storage -and $inv.Storage.MediaType -eq 'SSD' -and $null -ne $inv.Storage.TrimEnabled }
        Detect = {
            param($inv)
            if ($inv.Storage.TrimEnabled) { return New-AfDetection -State Ok -Current (T 'Activado') }
            New-AfDetection -State Improvable -Current (T 'Apagado') -Target (T 'Activado') -What (T 'DisableDeleteNotify de NTFS pasa de 1 a 0.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfTrim -Tx $tx -Enabled $true | Out-Null }
    }

    @{
        Id = 'storage.hibernation'; Category = 'storage'
        Title = (T 'Archivo de hibernación más chico')
        Why = (T 'Con poco espacio libre, hiberfil.sys ocupa cerca de la mitad de la memoria RAM en el disco.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft: powercfg y la hibernación'); SourceUrl = 'https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) $inv.Hibernation -and $inv.Hibernation.Enabled -and $inv.Hibernation.Type -eq 'Full' -and (Test-AfLowDisk -Storage $inv.Storage) }
        Detect = {
            param($inv)
            $size = Format-AfSize -Bytes ([double]$inv.Hibernation.FileBytes)
            # Solo se reduce en un escritorio confirmado; laptop, tipo desconocido o sin dato: no se toca.
            if (-not ($inv.Device -and $inv.Device.IsDesktop)) {
                return New-AfDetection -State Info -Current $size -Note (T 'Solo se reduce en escritorios confirmados; en laptops y equipos sin identificar no se toca.')
            }
            New-AfDetection -State Improvable -Current ((T 'Completo, {0}') -f $size) -Target (T 'Reducido') -Note (T 'Si se va la luz mientras duerme, se pierde lo no guardado') `
                -What (T 'El archivo baja de 40 % a 20 % de la RAM, cerca de la mitad. Se conserva el inicio rápido; se pierden hibernar y el sueño híbrido.')
        }
        Apply = {
            param($inv, $detected, $tx)
            if (-not ($inv.Device -and $inv.Device.IsDesktop)) { return }
            Set-AfHibernationType -Tx $tx -Type Reduced | Out-Null
        }
    }

    @{
        Id = 'storage.storage-sense'; Category = 'storage'
        Title = (T 'Sensor de almacenamiento activado')
        Why = (T 'Borra temporales solo cuando queda poco espacio, para que Windows no se quede sin lugar para actualizarse.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: Sensor de almacenamiento'); SourceUrl = 'https://support.microsoft.com/en-us/windows/manage-drive-space-with-storage-sense-654f6ada-7bfc-45e5-966b-e24aded96ad5'; Undo = (T 'Se puede deshacer')
        Reads = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy|01', 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense|AllowStorageSenseGlobal')
        Detect = {
            param($inv)
            if ($null -ne $inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense|AllowStorageSenseGlobal']) { return New-AfDetection -State Info -Note (T 'Lo fija una directiva') }
            $enabled = $inv.Registry['HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy|01']
            # Sin la clave, el usuario nunca lo tocó: Windows lo enciende solo cuando falta espacio (Microsoft Learn y soporte).
            if ($null -eq $enabled) { return New-AfDetection -State Ok -Current (T 'De fábrica') -Note (T 'Windows lo enciende solo cuando queda poco espacio') }
            if ($enabled -eq 1) { return New-AfDetection -State Ok -Current (T 'Activado') }
            New-AfDetection -State Improvable -Current (T 'Apagado') -Target (T 'Activado') `
                -What (T 'Corre solo con poco espacio libre y solo sobre temporales. No toca la Papelera ni Descargas.')
        }
        Apply = {
            param($inv, $detected, $tx)
            $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
            foreach ($pair in @(@('01', 1), @('2048', 0), @('04', 1), @('08', 0), @('32', 0))) {
                Set-AfRegistryValue -Tx $tx -Path $path -Name $pair[0] -Type DWord -Value $pair[1] | Out-Null
            }
            Add-AfUnverifiedNote -Tx $tx -Os $inv.Os
        }
    }

    @{
        Id = 'storage.games-hdd'; Category = 'storage'
        Title = (T 'Juegos en SSD')
        Why = (T 'En un disco mecánico los juegos tardan mucho más en cargar y los mundos abiertos dan tirones.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Bibliotecas de Steam y Epic Games'); Undo = (T 'No cambia nada')
        Reading = $true; Async = $true
        Detect = { param($inv) New-AfDetection -State Info -Current (T 'Revisando…') -Data @{ Async = $true } }
        AsyncDetect = { param($inv) Get-AfGamesHddDetection -Games @(Get-AfGameInstalls -User $inv.User) -Drives (Get-AfDriveKinds) }
    }
}

function Get-AfGamesHddDetection {
    param([object[]]$Games = @(), [hashtable]$Drives = @{})
    $games = @($Games | Where-Object { $_ -and $_.Path -match '^[A-Za-z]:' })
    if (-not $games.Count) { return New-AfDetection -State NotApplicable }
    $slow = @($games | Where-Object { $drive = $Drives[$_.Path.Substring(0, 1).ToUpperInvariant()]; $drive -and $drive.MediaType -eq 'HDD' })
    if (-not $slow.Count) { return New-AfDetection -State Ok -Current (T 'Ninguno en disco mecánico') }
    $title = if ($slow.Count -eq 1) { (T '1 juego en disco mecánico') } else { (T '{0} juegos en disco mecánico') -f $slow.Count }
    $names = Join-AfNames @($slow | Select-Object -First 3 | ForEach-Object { $_.Name })
    $ssd = @($Drives.Values | Where-Object { $_.MediaType -eq 'SSD' })
    if (-not $ssd.Count) { return New-AfDetection -State Info -Title $title -Current $names -Steps @((T 'Con un SSD estos juegos cargarían mucho más rápido.')) }
    $free = [long]($ssd | Measure-Object -Property FreeBytes -Maximum).Maximum
    $steps = @()
    if (([long]($slow | Measure-Object -Property Bytes -Minimum).Minimum) -gt $free) { $steps += (T 'Primero libera espacio en el SSD: ahora no entra ninguno de estos juegos.') }
    if (@($slow | Where-Object { $_.Launcher -eq 'Steam' }).Count) { $steps += (T 'En Steam: clic derecho en el juego > Propiedades > Archivos instalados > Mover carpeta de instalación, y elige el SSD.') }
    if (@($slow | Where-Object { $_.Launcher -eq 'Epic' }).Count) { $steps += (T 'En Epic Games no se pueden mover: desinstálalo e instálalo de nuevo en el SSD.') }
    New-AfDetection -State Manual -Title $title -Current $names -Note ((T '{0} GB libres en el SSD') -f [math]::Floor($free / 1GB)) -Steps $steps -Data @{ Games = @($slow.Name) }
}
