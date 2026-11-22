function Get-AfOverlayName {
    param([string]$Guid)
    switch ($Guid) {
        '00000000-0000-0000-0000-000000000000' { (T 'Equilibrado') }
        '961cc777-2547-4f9d-8174-7d86181b8a7a' { (T 'Mejor eficiencia energética') }
        'ded574b5-45a0-4f42-8737-46345c09c238' { (T 'Mejor rendimiento') }
        default { (T 'Otro modo') }
    }
}

function Get-AfVendorModeName {
    param([string]$Tool)
    switch ($Tool) {
        'Armoury Crate' { 'Turbo' }
        'G-Helper' { 'Turbo' }
        'MSI Center' { 'Extreme Performance' }
        'NitroSense' { 'Turbo' }
        default { (T 'Rendimiento') }
    }
}

function Get-AfEnergyChecks {
    @{
        Id = 'energy.power-mode'; Category = 'energy'
        Title = (T 'Modo de energía en Mejor rendimiento')
        Why = (T 'Con el cargador puesto, Windows deja trabajar al procesador y a la gráfica sin recortes.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: modos de energía de Windows'); SourceUrl = 'https://support.microsoft.com/en-us/windows/change-the-power-mode-for-your-windows-pc-c2aff038-22c9-f46d-5ca0-78696fdf2de8'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) $inv.Power -and $inv.Power.ActiveScheme }
        Detect = {
            param($inv)
            $balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
            $saver = 'a1841308-3541-4fab-bc81-f71556f20b4a'
            $best = 'ded574b5-45a0-4f42-8737-46345c09c238'
            $scheme = $inv.Power.ActiveScheme
            if ($scheme -eq $saver) {
                return New-AfDetection -State Improvable -Current (T 'Ahorro de energía') -Target (T 'Mejor rendimiento') -Note (T 'Solo con el cargador puesto') `
                    -What (T 'El plan pasa de Ahorro de energía a Equilibrado, y el modo con cargador a Mejor rendimiento. Con batería no cambia nada.')
            }
            # Los modos solo existen sobre el plan Equilibrado; otro plan es uno propio de alto rendimiento.
            if ($scheme -ne $balanced) { return New-AfDetection -State Ok -Current (T 'Plan de alto rendimiento') }
            $overlay = if ($inv.Power.OverlayAc) { $inv.Power.OverlayAc } else { '00000000-0000-0000-0000-000000000000' }
            if ($overlay -eq $best) { return New-AfDetection -State Ok -Current (T 'Mejor rendimiento') }
            $name = Get-AfOverlayName -Guid $overlay
            New-AfDetection -State Improvable -Current $name -Target (T 'Mejor rendimiento') -Note (T 'Solo con el cargador puesto') `
                -What ((T 'Modo de energía con cargador, de {0} a Mejor rendimiento. Con batería no cambia nada.') -f $name)
        }
        Apply = {
            param($inv, $detected, $tx)
            if ($inv.Power.ActiveScheme -eq 'a1841308-3541-4fab-bc81-f71556f20b4a') { Set-AfActivePowerScheme -Tx $tx -Guid '381b4222-f694-41f0-9685-ff5bb260df2e' | Out-Null }
            Set-AfPowerOverlay -Tx $tx -Guid 'ded574b5-45a0-4f42-8737-46345c09c238' | Out-Null
        }
    }

    @{
        Id = 'energy.vendor-mode'; Category = 'energy'
        Title = (T 'Modo de rendimiento del fabricante')
        Why = (T 'En estas laptops, los límites de potencia y los ventiladores los maneja la herramienta del fabricante, no Windows.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Herramienta del fabricante del equipo'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) @($inv.VendorTools).Count -gt 0 }
        Detect = {
            param($inv)
            $tool = @($inv.VendorTools)[0]
            $mode = Get-AfVendorModeName -Tool $tool
            New-AfDetection -State Manual -Title ((T 'Modo {0} en {1}') -f $mode, $tool) -Current $tool `
                -Note ((T 'Los límites de potencia y los ventiladores los maneja {0}') -f $tool) `
                -Steps @(((T 'Abre {0}.') -f $tool), ((T 'Busca el modo de rendimiento y elige {0}.') -f $mode), (T 'Déjalo así mientras juegas con el cargador puesto.'))
        }
    }
}
