function Get-AfAdapterByGuid {
    param([string]$InterfaceGuid)
    @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { [string]$_.InterfaceGuid -eq $InterfaceGuid })[0]
}

# Cambia una propiedad avanzada sin reiniciar el adaptador; Complete-AfTransaction lo reinicia una sola vez al final.
function Set-AfNetAdapterProperty {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Adapter, [Parameter(Mandatory)][string]$Keyword, [Parameter(Mandatory)][string]$Value)
    $reason = (T 'el adaptador {0} no respondió') -f $Adapter
    try {
        $nic = Get-NetAdapter -Name $Adapter -ErrorAction Stop
        $property = Get-NetAdapterAdvancedProperty -Name $Adapter -RegistryKeyword $Keyword -ErrorAction Stop
    } catch {
        Write-AfLog -Level Warn -Message "Adaptador $Adapter ($Keyword): $($_.Exception.Message)"
        throw (New-AfApplyError -Reason $reason)
    }
    $previous = [string](@($property.RegistryValue)[0])
    if ($previous -eq $Value) { return $false }
    try {
        Set-NetAdapterAdvancedProperty -Name $Adapter -RegistryKeyword $Keyword -RegistryValue $Value -NoRestart -ErrorAction Stop
    } catch {
        Write-AfLog -Level Warn -Message "Adaptador $Adapter ($Keyword = $Value): $($_.Exception.Message)"
        throw (New-AfApplyError -Reason $reason)
    }
    $guid = [string]$nic.InterfaceGuid
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'NetAdapterProperty'; InterfaceGuid = $guid; Adapter = $Adapter; Keyword = $Keyword; Previous = $previous; New = $Value }
    if (-not $Tx.RestartAdapters.Contains($guid)) { [void]$Tx.RestartAdapters.Add($guid) }
    $true
}

# Un reinicio por adaptador (la conexión se corta unos segundos). Si falla, se anota y el cambio queda para el próximo reinicio.
function Restart-AfAdapters {
    param([string[]]$InterfaceGuid = @())
    foreach ($guid in @($InterfaceGuid | Select-Object -Unique)) {
        $nic = Get-AfAdapterByGuid -InterfaceGuid $guid
        if (-not $nic) { Write-AfLog -Level Warn -Message "No se encontró el adaptador $guid para reiniciarlo."; continue }
        try { Restart-NetAdapter -Name $nic.Name -Confirm:$false -ErrorAction Stop } catch { Write-AfLog -Level Warn -Message "No se pudo reiniciar $($nic.Name): $($_.Exception.Message)" }
    }
}

function Restore-AfNetAdapterProperty {
    param([Parameter(Mandatory)]$Record, $User)
    # Por InterfaceGuid: el adaptador pudo cambiar de nombre desde que se aplicó.
    $nic = Get-AfAdapterByGuid -InterfaceGuid $Record.InterfaceGuid
    if (-not $nic) { throw (New-AfApplyError -Reason ((T 'no se encontró el adaptador {0}') -f $Record.Adapter)) }
    try {
        Set-NetAdapterAdvancedProperty -Name $nic.Name -RegistryKeyword $Record.Keyword -RegistryValue ([string]$Record.Previous) -NoRestart -ErrorAction Stop
    } catch {
        Write-AfLog -Level Warn -Message "Deshacer $($nic.Name) ($($Record.Keyword)): $($_.Exception.Message)"
        throw (New-AfApplyError -Reason ((T 'el adaptador {0} no respondió') -f $nic.Name))
    }
}

function Get-AfNetAdapterPropertyState {
    param([Parameter(Mandatory)]$Record, $User)
    $nic = Get-AfAdapterByGuid -InterfaceGuid $Record.InterfaceGuid
    if (-not $nic) { return $null }
    [string](@((Get-NetAdapterAdvancedProperty -Name $nic.Name -RegistryKeyword $Record.Keyword -ErrorAction SilentlyContinue).RegistryValue)[0])
}
