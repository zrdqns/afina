function Set-AfDisplayMode {
    param(
        [Parameter(Mandatory)]$Tx,
        [Parameter(Mandatory)][string]$DeviceName,
        [string]$Label = 'Pantalla',
        [Parameter(Mandatory)][int]$Width,
        [Parameter(Mandatory)][int]$Height,
        [Parameter(Mandatory)][int]$Hz
    )
    $current = Get-AfCurrentDisplayMode -DeviceName $DeviceName
    if (-not $current) { throw (New-AfApplyError -Reason (T 'no se encontró esa pantalla')) }
    if ($current.Width -eq $Width -and $current.Height -eq $Height -and $current.Hz -eq $Hz) { return $false }
    $code = Invoke-AfDisplayModeChange -DeviceName $DeviceName -Width $Width -Height $Height -Hz $Hz
    if ($code -ne 0) {
        Write-AfLog -Level Warn -Message ('Pantalla {0} a {1}x{2}@{3}: código {4}' -f $DeviceName, $Width, $Height, $Hz, $code)
        throw (New-AfApplyError -Reason ((T 'Windows no aceptó {0} Hz en esa pantalla') -f $Hz))
    }
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'DisplayMode'; DeviceName = $DeviceName; Label = $Label
        Previous = [pscustomobject]@{ Width = $current.Width; Height = $current.Height; Hz = $current.Hz }
        New = [pscustomobject]@{ Width = $Width; Height = $Height; Hz = $Hz }
    }
    $true
}

# Como Windows: pregunta si se ve bien. Sin un "keep" lanza y el motor vuelve al modo anterior.
function Confirm-AfDisplayChange {
    param([Parameter(Mandatory)]$Tx)
    $records = @($Tx.Records | Where-Object { $_.Kind -eq 'DisplayMode' })
    if (-not $records.Count -or -not $Tx.ConfirmDisplay) { return }
    $answer = & $Tx.ConfirmDisplay $records
    if ($answer -eq 'keep') { return }
    $hz = $records[0].Previous.Hz
    $reason = if ($answer -eq 'revert') { (T 'Se volvió a {0} Hz') -f $hz } else { (T 'Se volvió a {0} Hz porque nadie confirmó la pantalla') -f $hz }
    throw (New-AfApplyError -Reason $reason -Reverted)
}

function Restore-AfDisplayMode {
    param([Parameter(Mandatory)]$Record, $User)
    $previous = $Record.Previous
    $code = Invoke-AfDisplayModeChange -DeviceName $Record.DeviceName -Width $previous.Width -Height $previous.Height -Hz $previous.Hz
    if ($code -ne 0) {
        Write-AfLog -Level Warn -Message ('Deshacer pantalla {0}: código {1}' -f $Record.DeviceName, $code)
        throw (New-AfApplyError -Reason (T 'Windows no aceptó el modo anterior de la pantalla'))
    }
}

function Get-AfDisplayModeState {
    param([Parameter(Mandatory)]$Record, $User)
    $mode = Get-AfCurrentDisplayMode -DeviceName $Record.DeviceName
    if ($mode) { [pscustomobject]@{ Width = $mode.Width; Height = $mode.Height; Hz = $mode.Hz } }
}
