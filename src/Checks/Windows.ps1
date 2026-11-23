function Get-AfWindowsChecks {
    $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

    @{
        Id = 'windows.file-extensions'; Category = 'windows'
        Title = (T 'Extensiones de archivo visibles')
        Why = (T 'Ver la extensión ayuda a notar un archivo disfrazado, como factura.pdf.exe.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft: Explorador de archivos'); SourceUrl = 'https://support.microsoft.com/en-us/windows/experience/fileexplorer/file-explorer-in-windows'
        Undo = (T 'Se puede deshacer')
        Reads = @("$adv|HideFileExt")
        Detect = {
            param($inv)
            $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            if ($inv.Registry["$adv|HideFileExt"] -eq 0) { return New-AfDetection -State Ok -Current (T 'Visibles') }
            New-AfDetection -State Improvable -Current (T 'Ocultas') -Target (T 'Visibles') `
                -What (T 'El Explorador de archivos muestra la extensión de todos los archivos.')
        }
        Apply = {
            param($inv, $detected, $tx)
            Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Type DWord -Value 0 | Out-Null
            Send-AfShellNotify -Area 'ShellState'
        }
    }

    @{
        Id = 'windows.end-task'; Category = 'windows'
        Title = (T 'Finalizar tarea en la barra de tareas')
        Why = (T 'Agrega "Finalizar tarea" al menú de cada app de la barra, para cerrar una que no responde sin abrir el Administrador de tareas.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Microsoft: configuración avanzada de Windows'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/advanced-settings/'
        Undo = (T 'Se puede deshacer')
        Reads = @("$adv\TaskbarDeveloperSettings|TaskbarEndTask")
        AppliesTo = { param($inv) [bool]($inv.Os.IsWin11 -and [int]$inv.Os.Build -ge 22631) }
        Detect = {
            param($inv)
            $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            if ($inv.Registry["$adv\TaskbarDeveloperSettings|TaskbarEndTask"] -eq 1) { return New-AfDetection -State Ok -Current (T 'Activado') }
            New-AfDetection -State Improvable -Current (T 'Apagado') -Target (T 'Activado') -Note (T 'Pide reiniciar') `
                -What (T 'Se activa "Finalizar tarea" en Configuración > Sistema > Para programadores.')
        }
        Apply = {
            param($inv, $detected, $tx)
            Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Name 'TaskbarEndTask' -Type DWord -Value 1 | Out-Null
            Add-AfUnverifiedNote -Tx $tx -Os $inv.Os
        }
    }

    @{
        Id = 'windows.battery-percent'; Category = 'windows'
        Title = (T 'Porcentaje de batería en la barra')
        Why = (T 'Muestra el porcentaje junto al icono de la batería, sin pasar el mouse por encima.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Microsoft: KB5067036'); SourceUrl = 'https://support.microsoft.com/help/5067036'
        Undo = (T 'Se puede deshacer')
        Reads = @("$adv|IsBatteryPercentageEnabled")
        AppliesTo = { param($inv) [bool]($inv.Device.IsLaptop -and (Test-AfBatteryPercentBuild -Os $inv.Os)) }
        Detect = {
            param($inv)
            $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            if ($inv.Registry["$adv|IsBatteryPercentageEnabled"] -eq 1) { return New-AfDetection -State Ok -Current (T 'Visible') }
            New-AfDetection -State Improvable -Current (T 'Oculto') -Target (T 'Visible') -Note (T 'Pide reiniciar') `
                -What (T 'Se activa el porcentaje de batería en la bandeja del sistema.')
        }
        Apply = {
            param($inv, $detected, $tx)
            Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'IsBatteryPercentageEnabled' -Type DWord -Value 1 | Out-Null
            Add-AfUnverifiedNote -Tx $tx -Os $inv.Os
        }
    }

    @{
        Id = 'windows.classic-menu'; Category = 'windows'
        Title = (T 'Menú contextual clásico')
        Why = (T 'Vuelve el menú de clic derecho completo de Windows 10, sin tener que pulsar "Mostrar más opciones".')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Pureinfotech (sin fuente de Microsoft)'); SourceUrl = 'https://pureinfotech.com/bring-back-classic-context-menu-windows-11/'
        Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) [bool]$inv.Os.IsWin11 }
        Detect = {
            param($inv)
            # Reads no admite el nombre vacío (valor por defecto): se lee la clave directo.
            $both = $true
            foreach ($path in @(
                    'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
                    'HKCU:\Software\Classes\CLSID\{51668040-5e31-4023-bbe3-149163bd80f1}\InprocServer32'
                )) {
                $state = Get-AfRegistryState -Path $path -Name '' -User $inv.User
                if (-not ($state.Exists -and $state.Type -eq 'String' -and [string]$state.Value -eq '')) { $both = $false }
            }
            $note = T 'Una actualización de Windows puede volver a romperlo'
            if ($both) { return New-AfDetection -State Ok -Current (T 'Clásico') -Note $note }
            New-AfDetection -State Improvable -Current (T 'Nuevo') -Target (T 'Clásico') -Note $note `
                -What (T 'Se crean dos claves vacías en tu usuario que devuelven el menú clásico. Pide reiniciar.')
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($id in '{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}', '{51668040-5e31-4023-bbe3-149163bd80f1}') {
                Set-AfRegistryValue -Tx $tx -Path "HKCU:\Software\Classes\CLSID\$id\InprocServer32" -Name '' -Type String -Value '' | Out-Null
            }
            Add-AfUnverifiedNote -Tx $tx -Os $inv.Os
        }
    }

    @{
        Id = 'windows.search-web'; Category = 'windows'
        Title = (T 'Búsqueda sin resultados de internet')
        Why = (T 'El cuadro de búsqueda de Windows manda lo que escribes a Bing y mezcla resultados de la web con los de tu PC.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Microsoft: política de búsqueda'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-search'
        Undo = (T 'Se puede deshacer')
        Reads = @(
            'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search|ConnectedSearchUseWeb'
            'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer|DisableSearchBoxSuggestions'
        )
        Detect = {
            param($inv)
            # Las directivas no se respetan en Home: un valor olvidado ahí no cuenta como hecho.
            if (-not (Test-AfPolicyEdition -Os $inv.Os)) {
                return New-AfDetection -State Info -Current (T 'Activa') -Steps @(
                    (T 'Abre Configuración > Privacidad y seguridad > Permisos de búsqueda.')
                    (T 'Apaga "Búsqueda de contenido en la nube" y "Mostrar aspectos destacados de la búsqueda".')
                    (T 'Esto no quita Bing del todo: Windows Home no tiene un ajuste para eso.')
                )
            }
            if (Test-AfEnterpriseEdition -Os $inv.Os) {
                if ($inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search|ConnectedSearchUseWeb'] -eq 0) { return New-AfDetection -State Ok -Current (T 'Apagada') }
                return New-AfDetection -State Improvable -Current (T 'Activa') -Target (T 'Apagada') -Note (T 'Pide reiniciar') `
                    -What (T 'Se apaga la búsqueda web con la directiva de Windows. Pide reiniciar.')
            }
            if ($inv.Registry['HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer|DisableSearchBoxSuggestions'] -eq 1) { return New-AfDetection -State Ok -Current (T 'Apagada') }
            New-AfDetection -State Improvable -Current (T 'Activa') -Target (T 'Apagada') -Note (T 'Pide reiniciar') `
                -What (T 'Se apagan las sugerencias del cuadro de búsqueda con la directiva de Windows. Microsoft solo documenta que quita las búsquedas recientes del Explorador; su efecto en Inicio viene de la comunidad.')
        }
        Apply = {
            param($inv, $detected, $tx)
            if (Test-AfEnterpriseEdition -Os $inv.Os) {
                Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'ConnectedSearchUseWeb' -Type DWord -Value 0 | Out-Null
            } else {
                Set-AfRegistryValue -Tx $tx -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Type DWord -Value 1 | Out-Null
            }
        }
    }

    @{
        Id = 'windows.start-recommendations'; Category = 'windows'
        Title = (T 'Inicio sin recomendaciones')
        Why = (T 'El menú Inicio muestra archivos recientes, apps sugeridas y avisos de la cuenta que casi nadie usa.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Microsoft: política de Inicio'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-start'
        Undo = (T 'Se puede deshacer')
        Reads = @(
            "$adv|Start_TrackDocs"
            "$adv|Start_TrackProgs"
            "$adv|Start_IrisRecommendations"
            "$adv|Start_RecoPersonalizedSites"
            "$adv|Start_AccountNotifications"
            'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer|HideRecommendedSection'
        )
        AppliesTo = { param($inv) [bool]$inv.Os.IsWin11 }
        Detect = {
            param($inv)
            $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            $off =@('Start_TrackDocs', 'Start_TrackProgs', 'Start_IrisRecommendations', 'Start_RecoPersonalizedSites', 'Start_AccountNotifications' | Where-Object { $inv.Registry["$adv|$_"] -ne 0 }).Count -eq 0
            # La directiva solo se respeta fuera de Home.
            if ($off -and (-not (Test-AfPolicyEdition -Os $inv.Os) -or $inv.Registry['HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer|HideRecommendedSection'] -eq 1)) {
                return New-AfDetection -State Ok -Current (T 'Apagadas')
            }
            New-AfDetection -State Improvable -Current (T 'Activas') -Target (T 'Apagadas') -Note (T 'Pide reiniciar') `
                -What (T 'Se apagan los archivos recientes, los programas recomendados y los avisos de la cuenta en Inicio. En Pro y superiores también se oculta la sección Recomendado.')
        }
        Apply = {
            param($inv, $detected, $tx)
            $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            foreach ($name in 'Start_TrackDocs', 'Start_TrackProgs', 'Start_IrisRecommendations', 'Start_RecoPersonalizedSites', 'Start_AccountNotifications') {
                Set-AfRegistryValue -Tx $tx -Path $path -Name $name -Type DWord -Value 0 | Out-Null
            }
            if (Test-AfPolicyEdition -Os $inv.Os) {
                Set-AfRegistryValue -Tx $tx -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'HideRecommendedSection' -Type DWord -Value 1 | Out-Null
            }
        }
    }
}
