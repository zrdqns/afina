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
                return New-AfDetection -State Info -Current $size -Note (T 'En laptops no se reduce: sin hibernación completa, el trabajo sin guardar puede perderse al agotarse la batería')
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
}
