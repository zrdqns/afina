function Get-AfAdsReads {
    $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    @(
        "$cdm|SilentInstalledAppsEnabled"
        "$cdm|SystemPaneSuggestionsEnabled"
        "$cdm|SubscribedContent-338388Enabled"
        "$cdm|SubscribedContent-338389Enabled"
        "$cdm|SubscribedContent-353694Enabled"
        "$cdm|SubscribedContent-353696Enabled"
        "$cdm|SoftLandingEnabled"
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo|Enabled'
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|Start_IrisRecommendations'
    )
}

function Get-AfOptionalChecks {
    # Recall va primero: su lectura tarda unos 6 s y así corre antes que Windows Update.
    @{
        Id = 'cleanup.recall'; Category = 'optional'
        Title = (T 'Recall apagado')
        Why = (T 'Recall guarda capturas de lo que haces en pantalla para poder buscarlas después.')
        Impact = 'Low'; Risk = 'Advanced'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft: administrar Recall'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/client-management/manage-recall'
        Undo = (T 'Se deshace el ajuste; las capturas borradas no vuelven')
        Reads = @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI|DisableAIDataAnalysis')
        Async = $true
        AppliesTo = {
            param($inv)
            $build = [int]$inv.Os.Build
            $ubr = [int]$inv.Os.Ubr
            # Sin dato de memoria no se sabe si cumple: no se ofrece.
            $gb = if ($inv.Memory) { [double]$inv.Memory.TotalGB } else { 0 }
            [bool]($inv.Os.IsWin11 -and ($build -gt 26100 -or ($build -eq 26100 -and $ubr -ge 3915)) -and $gb -ge 16)
        }
        Detect = { param($inv) New-AfDetection -State Info -Current (T 'Comprobando Recall…') -Data @{ Async = $true } }
        AsyncDetect = {
            param($inv)
            $policyEdition = Test-AfPolicyEdition -Os $inv.Os
            # Con la directiva puesta no hace falta la lectura lenta; en Home no se respeta, así que no cuenta.
            if ($policyEdition -and $inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI|DisableAIDataAnalysis'] -eq 1) { return New-AfDetection -State Ok -Current (T 'Apagado') }
            try { $state = Get-AfRecallState } catch { return New-AfDetection -State NotApplicable -Note (T 'No se pudo leer el estado de Recall') }
            if ($state -eq 'Absent') { return New-AfDetection -State NotApplicable }
            if ($state -eq 'Disabled') { return New-AfDetection -State Ok -Current (T 'Apagado') }
            # InstallState 1 solo dice que Recall está instalado, no que guarde capturas: se muestra como Disponible.
            if (-not $policyEdition) {
                return New-AfDetection -State Info -Current (T 'Disponible') -Steps @(
                    (T 'Abre Configuración > Privacidad y seguridad > Recall y capturas.')
                    (T 'Apaga Guardar capturas.')
                )
            }
            New-AfDetection -State Improvable -Current (T 'Disponible') -Target (T 'Apagado') -Note (T 'Borra las capturas guardadas y no se recuperan') `
                -What ((T 'Se apaga el análisis de lo que hay en pantalla con la directiva de Windows. Las capturas guardadas se borran y no se recuperan.') + ' ' + (T 'Configuración puede mostrar que una organización administra este ajuste hasta que lo deshagas.'))
        }
        Apply = {
            param($inv, $detected, $tx)
            Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis' -Type DWord -Value 1 | Out-Null
        }
    }

    @{
        Id = 'updates.windows'; Category = 'optional'
        Title = (T 'Actualizaciones de Windows')
        Why = (T 'Traen arreglos de seguridad y a veces drivers nuevos.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Windows Update'); Undo = (T 'No se puede deshacer desde Afina; se desinstalan en Configuración'); NoUndo = $true
        Async = $true
        Detect = { param($inv) New-AfDetection -State Info -Current (T 'Buscando actualizaciones…') -Data @{ Async = $true } }
        AsyncDetect = {
            param($inv)
            $updates = Find-AfWindowsUpdates
            if ($updates.Reason) { return New-AfDetection -State Error -Note $updates.Reason }
            if (-not $updates.Count) { return New-AfDetection -State Ok -Current (T 'Al día') }
            $current = if ($updates.Count -eq 1) { '1 disponible' } else { (T '{0} disponibles') -f $updates.Count }
            New-AfDetection -State Improvable -Current $current -Target (T 'Instaladas') -Note (T 'Puede tardar unos minutos') -Data @{ Titles = $updates.Titles } `
                -What (T 'Descarga e instala las actualizaciones que Windows instalaría solo, con su avance. No incluye versiones nuevas de Windows.')
        }
        Apply = { param($inv, $detected, $tx) Install-AfWindowsUpdates -Tx $tx | Out-Null }
    }

    @{
        Id = 'updates.apps'; Category = 'optional'
        Title = (T 'Apps con actualización')
        Why = (T 'Las apps al día corrigen fallos y huecos de seguridad.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'winget'); Undo = (T 'No se puede deshacer desde Afina'); NoUndo = $true
        Async = $true
        Detect = { param($inv) New-AfDetection -State Info -Current (T 'Buscando actualizaciones de apps…') -Data @{ Async = $true } }
        AsyncDetect = {
            param($inv)
            $result = Get-AfWingetUpgrades
            if (-not $result.Available) { return New-AfDetection -State NotApplicable -Note (T 'winget no está instalado') }
            if ($result.TimedOut) { return New-AfDetection -State Error -Note (T 'winget no respondió a tiempo') }
            $apps = @($result.Apps)
            if (-not $apps.Count) { return New-AfDetection -State Ok -Current (T 'Al día') }
            # Cada app es una opción del detalle; al marcar la fila se eligen todas.
            $choices = @($apps | ForEach-Object {
                    [pscustomobject]@{ Name = $_.Name; Id = $_.Id; Source = $_.Source; Label = ('{0} ({1} → {2})' -f $_.Name, $_.Version, $_.Available); Preselected = $true; Selected = $false }
                })
            New-AfDetection -State Improvable -Current (Join-AfNames @($apps.Name | Select-Object -First 3)) -Target (T 'Actualizadas') -Note (T 'Cierra las apps antes de actualizarlas') `
                -Data @{ Apps = $apps; Choices = $choices; ChoicesLabel = (T 'Apps') } `
                -Title $(if ($apps.Count -eq 1) { (T '1 app con actualización') } else { (T '{0} apps con actualización') -f $apps.Count }) `
                -What (T 'Actualiza las apps elegidas con winget, sin ventanas.')
        }
        Apply = { param($inv, $detected, $tx) Update-AfWingetApps -Tx $tx -Apps @($detected.Data.Choices | Where-Object { $_.Selected }) | Out-Null }
    }

    @{
        Id = 'advanced.memory-integrity'; Category = 'optional'
        Title = (T 'Integridad de memoria apagada')
        Why = (T 'Microsoft reconoce que en algunos equipos baja el rendimiento en juegos.')
        Impact = 'Medium'; Risk = 'Advanced'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Microsoft: virtualización y rendimiento en juegos'); SourceUrl = 'https://support.microsoft.com/en-us/topic/a255f612-2949-4373-a566-ff6f3f474613'
        Undo = (T 'Se puede deshacer')
        Reads = @(
            'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity|Enabled'
            'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity|Locked'
            'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard|HypervisorEnforcedCodeIntegrity'
        )
        AppliesTo = { param($inv) $null -ne $inv.Security }
        Detect = {
            param($inv)
            $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
            $enabled = $inv.Registry["$key|Enabled"]
            # Con bloqueo UEFI o activada por directiva, cambiar Enabled no hace nada.
            $locked = $inv.Registry["$key|Locked"] -eq 1
            $policy = $inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard|HypervisorEnforcedCodeIntegrity'] -in 1, 2
            if ($inv.Security.HvciRunning) {
                if ($locked -or $policy) {
                    return New-AfDetection -State Manual -Current (T 'Activa') -Note (T 'Bloqueada por UEFI o por una directiva') -Steps @(
                        (T 'Abre Seguridad de Windows > Seguridad del dispositivo > Aislamiento del núcleo.')
                        (T 'Si el interruptor está gris, la activó una directiva de la organización: se quita desde ahí.')
                        (T 'Si tiene bloqueo UEFI, Microsoft indica que para apagarla hay que desactivar el arranque seguro desde la BIOS.')
                    )
                }
                if ($enabled -eq 0) { return New-AfDetection -State Info -Current (T 'Se apaga al reiniciar') }
                return New-AfDetection -State Improvable -Current (T 'Activa') -Target (T 'Apagada') -Note (T 'Puede dar más FPS, pero baja la seguridad') `
                    -What (T 'Apaga la protección de Windows contra drivers maliciosos. Pide reiniciar.')
            }
            if ($enabled -eq 1) { return New-AfDetection -State Info -Current (T 'Se activa al reiniciar') }
            New-AfDetection -State Ok -Current (T 'Apagada')
        }
        Apply = {
            param($inv, $detected, $tx)
            Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Name 'Enabled' -Type DWord -Value 0 | Out-Null
        }
    }

    @{
        Id = 'advanced.vm-platform'; Category = 'optional'
        Title = (T 'Plataforma de máquina virtual apagada')
        Why = (T 'Microsoft reconoce que junto con la integridad de memoria puede bajar el rendimiento en juegos.')
        Impact = 'Medium'; Risk = 'Advanced'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Microsoft: virtualización y rendimiento en juegos'); SourceUrl = 'https://support.microsoft.com/en-us/topic/a255f612-2949-4373-a566-ff6f3f474613'
        Undo = (T 'Se puede deshacer')
        AppliesTo = {
            param($inv)
            $vmp = if ($inv.Security) { $inv.Security.VmPlatform }
            [bool]($vmp -and ($vmp.State -eq 'Enabled' -or $vmp.Pending) -and -not $inv.Security.UsesVirtualization)
        }
        Detect = {
            param($inv)
            $vmp = $inv.Security.VmPlatform
            if ($vmp.Pending) { return New-AfDetection -State Info -Current $(if ($vmp.State -eq 'Enabled') { (T 'Se activa al reiniciar') } else { (T 'Se apaga al reiniciar') }) }
            New-AfDetection -State Improvable -Current (T 'Activada') -Target (T 'Apagada') -Note (T 'WSL, Docker y los emuladores de Android dejarían de funcionar') `
                -What (T 'Se desactiva la característica VirtualMachinePlatform. Pide reiniciar.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfWindowsFeature -Tx $tx -Name 'VirtualMachinePlatform' -Enabled $false | Out-Null }
    }

    @{
        Id = 'cleanup.promo-apps'; Category = 'optional'
        Title = (T 'Apps promocionales preinstaladas')
        Why = (T 'Vienen con Windows, ocupan espacio y algunas se actualizan solas en segundo plano.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Lista cerrada de apps promocionales'); Undo = (T 'Se vuelven a instalar; algunas desde la Microsoft Store, con internet')
        AppliesTo = { param($inv) $null -ne $inv.Apps }
        Detect = {
            param($inv)
            # Quitarlas se hace para la cuenta del proceso: con otra cuenta elevada no se podrían volver a registrar para el dueño.
            if ($inv.User -and -not $inv.User.IsSameAsProcess) { return New-AfDetection -State NotApplicable -Note (T 'Abre Afina con la cuenta del dueño para quitarlas') }
            $promo = @($inv.Apps.Promo)
            if (-not $promo.Count) { return New-AfDetection -State Ok -Current (T 'Ninguna') }
            $choices = @($promo | ForEach-Object {
                    $restorable = [bool]($_.Provisioned -or $_.StoreId)
                    [pscustomobject]@{
                        Name = $_.Name; PackageName = $_.PackageName; PackageFullName = $_.PackageFullName; PackageFamilyName = $_.PackageFamilyName; StoreId = $_.StoreId
                        Label = $(if ($restorable) { $_.Name } else { (T '{0} (no se puede reinstalar)') -f $_.Name }); Preselected = $restorable; Selected = $false
                    }
                })
            New-AfDetection -State Improvable -Current (Join-AfNames @($promo.Name)) -Target (T 'Quitadas') -Data @{ Apps = $promo; Choices = $choices; ChoicesLabel = (T 'Apps') } `
                -Title $(if ($promo.Count -eq 1) { '1 app promocional' } else { (T '{0} apps promocionales') -f $promo.Count }) `
                -What (T 'Se quitan para esta cuenta con Remove-AppxPackage.')
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($app in @($detected.Data.Choices | Where-Object { $_.Selected })) { Remove-AfAppxPackage -Tx $tx -App $app | Out-Null }
        }
    }

    @{
        Id = 'cleanup.widgets'; Category = 'optional'
        Title = (T 'Widgets apagados')
        Why = (T 'Los widgets y las noticias de la barra de tareas usan memoria y red en segundo plano.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Microsoft: política NewsAndInterests'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-newsandinterests'
        Undo = (T 'Se puede deshacer')
        Reads = @(
            'HKLM:\SOFTWARE\Policies\Microsoft\Dsh|AllowNewsAndInterests'
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|TaskbarDa'
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds|ShellFeedsTaskbarViewMode'
        )
        AppliesTo = { param($inv) $null -ne $inv.Apps }
        Detect = {
            param($inv)
            $win11 = [bool]$inv.Os.IsWin11
            if ($win11 -and -not $inv.Apps.HasWidgets) { return New-AfDetection -State NotApplicable }
            if (-not $win11) {
                if ($inv.Registry['HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds|ShellFeedsTaskbarViewMode'] -eq 2) { return New-AfDetection -State Ok -Current (T 'Apagados') }
                return New-AfDetection -State Info -Current (T 'Activos') -Steps @(
                    (T 'Haz clic derecho en la barra de tareas.')
                    (T 'Abre Noticias e intereses y elige Desactivar.')
                )
            }
            if (Test-AfPolicyEdition -Os $inv.Os) {
                # La directiva solo se respeta en Windows 11 Pro y superiores.
                if ($inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Dsh|AllowNewsAndInterests'] -eq 0) { return New-AfDetection -State Ok -Current (T 'Apagados') }
                return New-AfDetection -State Improvable -Current (T 'Activos') -Target (T 'Apagados') `
                    -What ((T 'Se apagan los widgets con la directiva de Windows. Pide reiniciar.') + ' ' + (T 'Configuración puede mostrar que una organización administra este ajuste hasta que lo deshagas.'))
            }
            if ($inv.Registry['HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|TaskbarDa'] -eq 0) { return New-AfDetection -State Ok -Current (T 'Apagados') }
            New-AfDetection -State Info -Current (T 'Activos') -Steps @(
                (T 'Abre Configuración > Personalización > Barra de tareas.')
                (T 'Apaga Widgets.')
            )
        }
        Apply = {
            param($inv, $detected, $tx)
            Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Type DWord -Value 0 | Out-Null
        }
    }

    @{
        Id = 'cleanup.copilot'; Category = 'optional'
        Title = (T 'Copilot quitado')
        Why = (T 'La app de Copilot viene con Windows y se ejecuta en segundo plano.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft: administrar Copilot'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/client-management/manage-windows-copilot'
        Undo = (T 'Se vuelve a instalar; desde la Microsoft Store, con internet')
        AppliesTo = { param($inv) $null -ne $inv.Apps }
        Detect = {
            param($inv)
            # Se quita para la cuenta del proceso: con otra cuenta elevada no se podría volver a registrar para el dueño.
            if ($inv.User -and -not $inv.User.IsSameAsProcess) { return New-AfDetection -State NotApplicable -Note (T 'Abre Afina con la cuenta del dueño para quitarlo') }
            if (-not $inv.Apps.Copilot) { return New-AfDetection -State NotApplicable }
            New-AfDetection -State Improvable -Current (T 'Instalado') -Target (T 'Quitado') `
                -What (T 'Se quita la app de Copilot para esta cuenta con Remove-AppxPackage.')
        }
        Apply = { param($inv, $detected, $tx) Remove-AfAppxPackage -Tx $tx -App $inv.Apps.Copilot | Out-Null }
    }

    @{
        Id = 'cleanup.ads'; Category = 'optional'
        Title = (T 'Sin anuncios ni sugerencias de Windows')
        Why = (T 'Windows muestra sugerencias en Inicio, la pantalla de bloqueo y Configuración, e instala apps promocionadas.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Configuración de privacidad de Windows'); Undo = (T 'Se puede deshacer')
        Reads = Get-AfAdsReads
        Detect = {
            param($inv)
            $on = @(Get-AfAdsReads | Where-Object { $inv.Registry[$_] -ne 0 })
            if (-not $on.Count) { return New-AfDetection -State Ok -Current (T 'Apagados') }
            New-AfDetection -State Improvable -Current ((T '{0} opciones activas') -f $on.Count) -Target (T 'Apagadas') -Note (T 'Inicio, pantalla de bloqueo y Configuración') -Data @{ Values = $on } `
                -What (T 'Se apagan las sugerencias, las apps promocionadas que se instalan solas y el ID de publicidad.')
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($read in @($detected.Data.Values)) {
                $path, $name = $read -split '\|', 2
                Set-AfRegistryValue -Tx $tx -Path $path -Name $name -Type DWord -Value 0 | Out-Null
            }
        }
    }

    @{
        Id = 'cleanup.diagnostics'; Category = 'optional'
        Title = (T 'Datos de diagnóstico al mínimo')
        Why = (T 'Windows manda menos datos de uso a Microsoft y deja de personalizar sugerencias con ellos.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft: datos de diagnóstico de Windows'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization'
        Undo = (T 'Se puede deshacer')
        Reads = @(
            'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection|AllowTelemetry'
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection|AllowTelemetry'
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy|TailoredExperiencesWithDiagnosticDataEnabled'
        )
        AppliesTo = { param($inv) -not $inv.Os.IsInsider }
        Detect = {
            param($inv)
            $policy = $inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection|AllowTelemetry']
            # La elección de Configuración (no es una directiva, aunque la clave se llame Policies).
            $setting = $inv.Registry['HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection|AllowTelemetry']
            $tailored = $inv.Registry['HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy|TailoredExperiencesWithDiagnosticDataEnabled']
            $level = if ($null -ne $policy) { $policy } else { $setting }
            $levelOk = $null -ne $level -and $level -le 1
            if ($levelOk -and $tailored -eq 0) { return New-AfDetection -State Ok -Current (T 'Mínimo') }
            # Afina no escribe directivas.
            if ($null -ne $policy) { return New-AfDetection -State Info -Current $(if ($levelOk) { (T 'Mínimo') } else { (T 'Opcionales') }) -Note (T 'Lo fija una directiva de la organización') }
            New-AfDetection -State Improvable -Current $(if ($levelOk) { (T 'Con experiencias personalizadas') } else { (T 'Opcionales') }) -Target (T 'Mínimo') `
                -What (T 'Datos de diagnóstico obligatorios (el mínimo que ofrece Configuración) y sin experiencias personalizadas.')
        }
        Apply = {
            param($inv, $detected, $tx)
            $level = $inv.Registry['HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection|AllowTelemetry']
            if ($null -eq $level -or $level -gt 1) { Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'AllowTelemetry' -Type DWord -Value 1 | Out-Null }
            Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Type DWord -Value 0 | Out-Null
        }
    }
}
