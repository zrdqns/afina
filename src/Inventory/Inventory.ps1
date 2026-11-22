function Get-AfInventoryPartNames {
    'User', 'Os', 'Device', 'Cpu', 'Gpus', 'Memory', 'Displays', 'Power', 'VendorTools', 'Network', 'Wlan',
    'Security', 'Apps', 'Startup', 'Autostart', 'Storage', 'Registry'
}

# Lee la PC una sola vez. Si una parte falla, queda en $null, se anota en Errors y el resto sigue.
function Get-AfInventory {
    param([string[]]$Reads = @(), [scriptblock]$OnProgress)
    $user = $null
    $parts = [ordered]@{
        User = { Get-AfInteractiveUser }
        Os = { Get-AfSystemInfo }
        Device = { Get-AfDeviceInfo }
        Cpu = { Get-AfCpuInfo }
        Gpus = { , @(Get-AfGpuInfo) }
        Memory = { Get-AfMemoryInfo }
        Displays = { , @(Get-AfDisplayInfo) }
        Power = { Get-AfPowerInfo }
        VendorTools = { , @(Get-AfVendorTools) }
        Network = { , @(Get-AfNetworkInfo) }
        Wlan = { Get-AfWlanInfo }
        Security = { Get-AfSecurityInfo -User $user }
        Apps = { Get-AfPromoApps -User $user }
        Startup = { , @(Get-AfStartupEntries -User $user) }
        Autostart = { , @(Get-AfAutostartBinaries -User $user) }
        Storage = { Get-AfStorageInfo -User $user }
        Registry = { Get-AfRegistrySnapshot -Reads $Reads -User $user }
    }

    $inventory = [ordered]@{}
    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($name in $parts.Keys) {
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $inventory[$name] = & $parts[$name]
        } catch {
            $inventory[$name] = $null
            $errors.Add($name)
            Write-AfLog -Level Warn -Message "Inventario: falló $name. $($_.Exception.Message)"
        }
        if ($name -eq 'User') { $user = $inventory.User }
        Write-AfLog -Level Info -Message ('Inventario: {0} en {1} ms' -f $name, $watch.ElapsedMilliseconds)
        if ($OnProgress) { & $OnProgress $name }
    }
    $inventory.Errors = $errors.ToArray()
    [pscustomobject]$inventory
}
