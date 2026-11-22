function Get-AfActivePowerScheme {
    $value = Get-AfRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActivePowerScheme'
    if ($value) { ([string]$value).ToLowerInvariant() } else { $null }
}

function Invoke-AfPowercfg {
    param([Parameter(Mandatory)][string]$Arguments)
    $result = Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\powercfg.exe') -Arguments $Arguments -TimeoutMs 15000
    if ($result.TimedOut -or $result.ExitCode -ne 0) {
        Write-AfLog -Level Warn -Message ('powercfg {0}: código {1}. {2} {3}' -f $Arguments, $result.ExitCode, $result.Output, $result.Error)
        throw (New-AfApplyError -Reason (T 'Windows no aceptó el ajuste de energía'))
    }
    $result
}

function Set-AfActivePowerScheme {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Guid)
    $target = $Guid.ToLowerInvariant()
    $previous = Get-AfActivePowerScheme
    if ($previous -eq $target) { return $false }
    Invoke-AfPowercfg -Arguments "/setactive $target" | Out-Null
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'PowerScheme'; Previous = $previous; New = $target }
    $true
}

function Restore-AfPowerScheme {
    param([Parameter(Mandatory)]$Record, $User)
    if ($Record.Previous) { Invoke-AfPowercfg -Arguments "/setactive $($Record.Previous)" | Out-Null }
}

function Get-AfPowerSchemeState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfActivePowerScheme
}

function Get-AfPowerSettingAc {
    param([string]$Scheme, [string]$Subgroup, [string]$Setting)
    $result = Invoke-AfPowercfg -Arguments "/q $Scheme $Subgroup $Setting"
    $values = ConvertFrom-AfPowercfgQuery -Text $result.Output
    if (-not $values) { throw (New-AfApplyError -Reason (T 'Windows no mostró ese ajuste de energía')) }
    [int]$values.Ac
}

# Ajuste del plan activo con cargador (CA). La batería queda como estaba.
function Set-AfPowerSetting {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Subgroup, [Parameter(Mandatory)][string]$Setting, [Parameter(Mandatory)][int]$Ac)
    $scheme = Get-AfActivePowerScheme
    if (-not $scheme) { throw (New-AfApplyError -Reason (T 'no se encontró el plan de energía activo')) }
    $previous = Get-AfPowerSettingAc -Scheme $scheme -Subgroup $Subgroup -Setting $Setting
    if ($previous -eq $Ac) { return $false }
    Invoke-AfPowercfg -Arguments "/setacvalueindex $scheme $Subgroup $Setting $Ac" | Out-Null
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'PowerSetting'; Scheme = $scheme; Subgroup = $Subgroup; Setting = $Setting; Previous = $previous; New = $Ac }
    Invoke-AfPowercfg -Arguments "/setactive $scheme" | Out-Null
    $true
}

function Restore-AfPowerSetting {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfPowercfg -Arguments ('/setacvalueindex {0} {1} {2} {3}' -f $Record.Scheme, $Record.Subgroup, $Record.Setting, $Record.Previous) | Out-Null
    if ((Get-AfActivePowerScheme) -eq $Record.Scheme) { Invoke-AfPowercfg -Arguments "/setactive $($Record.Scheme)" | Out-Null }
}

function Get-AfPowerSettingState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfPowerSettingAc -Scheme $Record.Scheme -Subgroup $Record.Subgroup -Setting $Record.Setting
}

function Get-AfCurrentOverlay {
    $value = Get-AfPowerOverlay
    if ($value) { ([string]$value).ToLowerInvariant() } else { '00000000-0000-0000-0000-000000000000' }
}

function Invoke-AfOverlayChange {
    param([Parameter(Mandatory)][string]$Guid)
    $code = [uint32](Invoke-AfSetAcOverlay -Guid $Guid)
    if ($code -eq 4294967295) { throw (New-AfApplyError -Reason (T 'conecta el cargador y vuelve a aplicar')) }
    if ($code -ne 0) {
        Write-AfLog -Level Warn -Message ('Modo de energía {0}: código {1}' -f $Guid, $code)
        throw (New-AfApplyError -Reason (T 'Windows no aceptó el modo de energía'))
    }
}

# Modo de energía con cargador (superposición de CA del plan Equilibrado).
function Set-AfPowerOverlay {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Guid)
    $target = $Guid.ToLowerInvariant()
    $previous = Get-AfCurrentOverlay
    if ($previous -eq $target) { return $false }
    Invoke-AfOverlayChange -Guid $target
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'PowerOverlay'; Previous = $previous; New = $target }
    # Se verifica con la misma lectura que usa el análisis; si no cambió, el motor lo revierte.
    if ((Get-AfCurrentOverlay) -ne $target) { throw (New-AfApplyError -Reason (T 'Windows no aceptó el modo de energía')) }
    $true
}

function Restore-AfPowerOverlay {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfOverlayChange -Guid $Record.Previous
}

function Get-AfPowerOverlayState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfCurrentOverlay
}
