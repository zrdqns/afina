function Get-AfFirewallProfileName {
    param([string]$Profile)
    switch ($Profile) { 'Domain' { (T 'Dominio') } 'Private' { (T 'Privado') } 'Public' { (T 'Público') } default { $Profile } }
}

function Test-AfDefenderActive {
    param($Inventory)
    $s = $Inventory.Security
    $s -and $s.Defender.Available -and (@($s.Antivirus | Where-Object { $_.Enabled -and -not $_.IsDefender }).Count -eq 0)
}

function Get-AfSecurityChecks {
    @{
        Id = 'security.antivirus'; Category = 'security'
        Title = (T 'Antivirus activo')
        Why = (T 'Sin protección en tiempo real, cualquier descarga o mod puede infectar la PC.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Centro de seguridad de Windows'); Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) $null -ne $inv.Security }
        Detect = {
            param($inv)
            $active = @($inv.Security.Antivirus | Where-Object { $_.Enabled -and $_.UpToDate })
            if ($active.Count) { return New-AfDetection -State Ok -Current (Join-AfNames @($active.Name)) }
            $outdated = @($inv.Security.Antivirus | Where-Object { $_.Enabled -and -not $_.UpToDate -and -not $_.IsDefender }) | Select-Object -First 1
            if ($outdated) {
                return New-AfDetection -State Manual -Title ((T '{0} no está al día') -f $outdated.Name) -Current $outdated.Name -Steps @(((T 'Abre {0} y busca actualizaciones.') -f $outdated.Name))
            }
            if ($inv.Security.Defender.Available -and -not $inv.Security.Defender.RealTime) {
                return New-AfDetection -State Improvable -Current (T 'Sin protección activa') -Target (T 'Defender en tiempo real') -What (T 'Se enciende la protección en tiempo real de Microsoft Defender.')
            }
            if ($inv.Security.Defender.Available) { return New-AfDetection -State Ok -Current (T 'Microsoft Defender') }
            New-AfDetection -State Manual -Title (T 'No hay antivirus activo') -Steps @((T 'Abre Seguridad de Windows, Protección contra virus y amenazas, y actívala.'), (T 'Si usas otro antivirus, revisa que esté encendido y al día.'))
        }
        Apply = { param($inv, $detected, $tx) Enable-AfDefenderRealtime -Tx $tx }
    }

    @{
        Id = 'security.signatures'; Category = 'security'
        Title = (T 'Firmas de Microsoft Defender al día')
        Why = (T 'Con firmas viejas, Defender no reconoce las amenazas recientes.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft Defender: actualizaciones de firmas'); SourceUrl = 'https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-updates'; Undo = (T 'No se deshace: solo descarga firmas nuevas')
        AppliesTo = { param($inv) Test-AfDefenderActive $inv }
        Detect = {
            param($inv)
            $age = [int]$inv.Security.Defender.SignatureAgeDays
            if ($age -le 3) { return New-AfDetection -State Ok -Current (T 'Al día') }
            $current = if ($age -eq 1) { (T 'Hace 1 día') } else { (T 'Hace {0} días') -f $age }
            New-AfDetection -State Improvable -Current $current -Target (T 'Al día') -What (T 'Se descargan las firmas nuevas de Microsoft Defender.')
        }
        Apply = { param($inv, $detected, $tx) Update-AfDefenderSignatures -Tx $tx }
    }

    @{
        Id = 'security.threats'; Category = 'security'
        Title = (T 'Amenazas activas')
        Why = (T 'Defender encontró algo que sigue en la PC.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft Defender: amenazas detectadas'); SourceUrl = 'https://learn.microsoft.com/en-us/powershell/module/defender/get-mpthreat'; Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Security -and $inv.Security.Defender.Available }
        Detect = {
            param($inv)
            $active = @($inv.Security.Defender.Threats | Where-Object Active)
            if (-not $active.Count) { return New-AfDetection -State Ok -Current (T 'Sin amenazas activas') }
            $title = if ($active.Count -eq 1) { (T '1 amenaza activa') } else { (T '{0} amenazas activas') -f $active.Count }
            New-AfDetection -State Manual -Title $title -Current $active[0].Name -Note $active[0].Path -Data @{ Threats = $active } `
                -Steps @((T 'Abre Seguridad de Windows, Protección contra virus y amenazas.'), (T 'En Amenazas actuales, quita o pon en cuarentena cada una.'))
        }
    }

    @{
        Id = 'security.pua'; Category = 'security'
        Title = (T 'Bloqueo de aplicaciones no deseadas')
        Why = (T 'Defender frena los instaladores que meten adware o barras en el navegador.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft Defender: protección contra aplicaciones potencialmente no deseadas'); SourceUrl = 'https://learn.microsoft.com/en-us/defender-endpoint/detect-block-potentially-unwanted-apps-microsoft-defender-antivirus'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) Test-AfDefenderActive $inv }
        Detect = {
            param($inv)
            if ($inv.Security.Defender.PuaProtection -eq 1) { return New-AfDetection -State Ok -Current (T 'Activado') }
            New-AfDetection -State Improvable -Current (T 'Apagado') -Target (T 'Activado') -What (T 'PUAProtection pasa a 1: Defender bloquea instaladores con adware.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfMpPreference -Tx $tx -Name 'PUAProtection' -Value 1 | Out-Null }
    }

    @{
        Id = 'security.firewall'; Category = 'security'
        Title = (T 'Firewall de Windows activado')
        Why = (T 'Sin firewall, cualquier programa o equipo de la red puede intentar conectarse a la PC.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Firewall de Windows'); Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) $inv.Security -and @($inv.Security.Firewall).Count -gt 0 -and -not $inv.Security.ThirdPartyFirewall }
        Detect = {
            param($inv)
            $off = @($inv.Security.Firewall | Where-Object { -not $_.Enabled })
            if (-not $off.Count) { return New-AfDetection -State Ok -Current (T 'Activado') }
            $names = Join-AfNames @($off | ForEach-Object { Get-AfFirewallProfileName -Profile $_.Profile })
            New-AfDetection -State Improvable -Current ((T 'Apagado en {0}') -f $names) -Target (T 'Activado') -What ((T 'Se activa el Firewall de Windows en: {0}.') -f $names) -Data @{ Profiles = @($off.Profile) }
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($name in @($detected.Data.Profiles)) { Set-AfFirewallProfile -Tx $tx -Profile $name -Enabled $true | Out-Null }
        }
    }

    @{
        Id = 'security.uac'; Category = 'security'
        Title = (T 'Control de cuentas de usuario')
        Why = (T 'Sin él, cualquier programa puede hacer cambios de administrador sin pedir permiso.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $true
        Source = (T 'Microsoft: Control de cuentas de usuario'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/security/application-security/application-control/user-account-control/'; Undo = (T 'Se puede deshacer')
        Reads = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System|EnableLUA')
        Detect = {
            param($inv)
            if ($inv.Registry['HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System|EnableLUA'] -ne 0) { return New-AfDetection -State Ok -Current (T 'Activado') }
            New-AfDetection -State Improvable -Current (T 'Apagado') -Target (T 'Activado') -What (T 'EnableLUA pasa de 0 a 1. Pide reiniciar.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -Type DWord -Value 1 | Out-Null }
    }

    @{
        Id = 'security.unsigned-autostart'; Category = 'security'
        Title = (T 'Programas sin firma que arrancan solos')
        Why = (T 'Casi todo el software legítimo está firmado; lo que arranca solo y sin firma merece una mirada.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Firmas Authenticode de los ejecutables'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $null -ne $inv.Autostart }
        Detect = {
            param($inv)
            $items = @($inv.Autostart | Where-Object { -not $_.IsSigned -and $_.Path })
            if (-not $items.Count) { return New-AfDetection -State Ok -Current (T 'Todos firmados') }
            $title = if ($items.Count -eq 1) { (T '1 programa sin firma arranca solo') } else { (T '{0} programas sin firma arrancan solos') -f $items.Count }
            New-AfDetection -State Info -Title $title -Current (Join-AfNames @($items.Name | Select-Object -First 3)) -Data @{ Items = $items } `
                -Steps @((T 'Revisa la lista: si no reconoces alguno, consúltalo en VirusTotal desde "Analizar seguridad".'))
        }
    }
}
