function Join-AfNames {
    param([string[]]$Names)
    $unique = @($Names | Where-Object { $_ } | Select-Object -Unique)
    switch ($unique.Count) {
        0 { '' }
        1 { $unique[0] }
        default { ($unique[0..($unique.Count - 2)] -join ', ') + ' ' + (T 'y') + ' ' + $unique[-1] }
    }
}

# Programas que no hace falta arrancar con Windows (lista cerrada; Steam, Discord y el resto se muestran sin marcar).
function Get-AfStartupBloatName {
    param($Entry)
    $text = '{0} {1}' -f $Entry.Name, [System.IO.Path]::GetFileNameWithoutExtension([string]$Entry.Path)
    switch -Regex ($text) {
        'EpicGamesLauncher' { 'Epic Games'; break }
        'EADesktop' { 'EA app'; break }
        '\bOrigin\b' { 'Origin'; break }
        'UbisoftConnect|\bupc\b' { 'Ubisoft Connect'; break }
        'AdobeGCInvoker|CCXProcess|AdobeARM|Adobe Creative Cloud' { (T 'el actualizador de Adobe'); break }
        'Spotify' { 'Spotify'; break }
        'Skype' { 'Skype'; break }
        default { $null }
    }
}

function Get-AfStartupChecks {
    @{
        Id = 'startup.apps'; Category = 'startup'
        Title = (T 'Programas que arrancan con Windows')
        Why = (T 'Cada programa que arranca solo alarga el encendido y ocupa memoria mientras juegas.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: apps de inicio'); SourceUrl = 'https://support.microsoft.com/en-us/windows/experience/startup-boot/configure-startup-applications-in-windows'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) @($inv.Startup).Count -gt 0 }
        Detect = {
            param($inv)
            # Cada entrada es también una opción del detalle: Selected empieza igual que Preselected y la interfaz lo cambia.
            $entries = @($inv.Startup | Where-Object Enabled | ForEach-Object {
                    $bloat = Get-AfStartupBloatName -Entry $_
                    [pscustomobject]@{
                        Name = $_.Name; Label = $_.Name; Path = $_.Path; Friendly = $bloat; Preselected = [bool]$bloat; Selected = [bool]$bloat
                        ApprovedKey = $_.ApprovedKey; ApprovedName = $_.ApprovedName
                    }
                })
            $bloat = @($entries | Where-Object Preselected)
            if (-not $bloat.Count) {
                $note = if ($entries.Count) { (T '{0} programas arrancan con Windows; ninguno sobra') -f $entries.Count } else { $null }
                return New-AfDetection -State Ok -Note $note -Data @{ Entries = $entries }
            }
            $title = if ($bloat.Count -eq 1) { (T '1 programa menos al arrancar') } else { (T '{0} programas menos al arrancar') -f $bloat.Count }
            $names = Join-AfNames @($bloat.Friendly)
            New-AfDetection -State Improvable -Title $title -Current $names -Data @{ Entries = $entries; Choices = $entries } `
                -What (T 'Se desactivan igual que en el Administrador de tareas los programas marcados abajo. Los demás siguen arrancando.')
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($choice in @($detected.Data.Choices | Where-Object Selected)) { Disable-AfStartupEntry -Tx $tx -Entry $choice | Out-Null }
        }
    }

    @{
        Id = 'startup.edge-background'; Category = 'startup'
        Title = (T 'Edge sigue activo en segundo plano')
        Why = (T 'Edge se queda en memoria aunque cierres todas sus ventanas, y arranca con Windows para abrir más rápido.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft: Aumento de inicio de Edge'); SourceUrl = 'https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies'; Undo = (T 'No cambia nada')
        Reads = @('HKLM:\SOFTWARE\Policies\Microsoft\Edge|StartupBoostEnabled', 'HKLM:\SOFTWARE\Policies\Microsoft\Edge|BackgroundModeEnabled')
        AppliesTo = { param($inv) $inv.Edge -and $inv.Edge.Installed }
        Detect = {
            param($inv)
            $policy = $null -ne $inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Edge|StartupBoostEnabled'] -or $null -ne $inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Edge|BackgroundModeEnabled']
            if ($policy) { return New-AfDetection -State Info -Note (T 'Lo fija una directiva') }
            if ($inv.Edge.HasWindow) { return New-AfDetection -State NotApplicable -Note (T 'Cierra Edge para revisarlo') }
            if (-not $inv.Edge.Running) { return New-AfDetection -State Ok -Current (T 'Cerrado') }
            New-AfDetection -State Manual -Current (T 'Edge corre sin ventanas') -Target (T 'Cerrado') `
                -Steps @((T 'Abre Edge y entra a edge://settings/system.'), (T 'Apaga "Aumento de inicio".'), (T 'Apaga "Seguir ejecutando extensiones y aplicaciones en segundo plano".'))
        }
    }

    @{
        Id = 'startup.junk'; Category = 'startup'
        Title = (T 'Sin "aceleradores" ni limpiadores')
        Why = (T 'Los actualizadores de drivers pueden instalar drivers equivocados, y los limpiadores y "aceleradores" corren de fondo sin hacer la PC más rápida.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Programas instalados'); Undo = (T 'No cambia nada')
        Reading = $true; Async = $true
        Detect = { param($inv) New-AfDetection -State Info -Current (T 'Revisando…') -Data @{ Async = $true } }
        AsyncDetect = {
            param($inv)
            $antivirus = if ($inv.Security) { @($inv.Security.Antivirus) } else { @() }
            Get-AfJunkDetection -Programs @(Get-AfInstalledPrograms -User $inv.User) -Antivirus $antivirus
        }
    }
}

# "Aceleradores", limpiadores y actualizadores de drivers conocidos (lista cerrada), por el nombre en Programas instalados.
function Get-AfJunkPattern {
    '^(Driver ?(Booster|Easy|Genius|Reviver|Support|Max)|DriverPack|Auslogics (Driver Updater|BoostSpeed)|Outbyte (Driver Updater|PC Repair)|(Avast|AVG) (Driver Updater|Cleanup|TuneUp)|CCleaner|Advanced SystemCare|Wise (Care 365|Registry Cleaner)|Glary Utilities|Restoro|Reimage|Fortect|Ashampoo WinOptimizer|Norton Utilities)'
}

function Get-AfJunkDetection {
    param([string[]]$Programs = @(), [object[]]$Antivirus = @())
    $junk = @($Programs | Where-Object { $_ -match (Get-AfJunkPattern) } | Select-Object -Unique)
    # Un antivirus apagado que sigue instalado (como una prueba vencida). Un registro viejo sin el programa no cuenta.
    $off = @($Antivirus | Where-Object { $_ -and -not $_.IsDefender -and -not $_.Enabled } | Where-Object {
            $brand = @(([string]$_.Name).Split(' '))[0]
            $brand -and @($Programs | Where-Object { $_ -like "$brand*" }).Count
        } | ForEach-Object { [string]$_.Name } | Select-Object -Unique)
    $names = @($junk) + @($off)
    if (-not $names.Count) { return New-AfDetection -State Ok -Current (T 'Ninguno') }
    $title = if ($names.Count -eq 1) { (T '{0} instalado') -f $names[0] } else { (T '{0} programas que estorban') -f $names.Count }
    $steps = @((T 'Abre Configuración > Aplicaciones > Aplicaciones instaladas.'))
    if ($junk.Count) { $steps += (T 'Desinstala {0}.') -f (Join-AfNames $junk) }
    if ($off.Count) { $steps += (T '{0} está apagado: si era una prueba que venció, desinstálalo y Microsoft Defender se activa solo.') -f (Join-AfNames $off) }
    New-AfDetection -State Manual -Title $title -Current (Join-AfNames $names) -Steps $steps -Data @{ Programs = $names }
}
