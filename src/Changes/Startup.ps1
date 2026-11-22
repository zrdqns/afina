# Igual que el Administrador de tareas: StartupApproved = 03 00 00 00 + FILETIME UTC de cuándo se desactivó.
function Get-AfStartupDisabledBytes {
    param([datetime]$Time = (Get-Date))
    $bytes = New-Object byte[] 12
    $bytes[0] = 3
    [System.BitConverter]::GetBytes($Time.ToFileTimeUtc()).CopyTo($bytes, 4)
    , $bytes
}

function Disable-AfStartupEntry {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)]$Entry)
    if (-not $Entry.ApprovedKey -or -not $Entry.ApprovedName) { throw (New-AfApplyError -Reason ((T 'no se encontró dónde desactivar {0}') -f $Entry.Name)) }
    $state = Get-AfRegistryState -Path $Entry.ApprovedKey -Name $Entry.ApprovedName -User $Tx.User
    # Primer byte impar = ya desactivado: no se reescribe la fecha.
    if ($state.Exists -and $state.Type -eq 'Binary' -and @($state.Value).Count -gt 0 -and ([int]@($state.Value)[0] -band 1) -eq 1) { return $false }
    Set-AfRegistryValue -Tx $Tx -Path $Entry.ApprovedKey -Name $Entry.ApprovedName -Type Binary -Value (Get-AfStartupDisabledBytes)
}
