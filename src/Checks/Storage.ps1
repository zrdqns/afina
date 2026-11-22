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
            $free = [double]$inv.Storage.FreeGB
            $current = (T '{0} GB libres') -f [math]::Round($free)
            if ($free -ge 20 -and ($free / $inv.Storage.SizeGB) -ge 0.15) { return New-AfDetection -State Ok -Current $current }
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
}
