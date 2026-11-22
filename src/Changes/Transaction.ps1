# Transacción de un cambio: cada pieza guarda el valor original antes de escribir (diseño, sección 11).
function New-AfTransaction {
    param($User, [scriptblock]$ConfirmDisplay, [scriptblock]$Progress, [scriptblock]$Step)
    [pscustomobject]@{
        User = $User
        Records = New-Object System.Collections.ArrayList
        RestartAdapters = New-Object System.Collections.ArrayList
        Notes = New-Object System.Collections.ArrayList
        ConfirmDisplay = $ConfirmDisplay
        Progress = $Progress
        Step = $Step
        ApplySent = $false
        # $null: vale el NeedsReboot de la revisión; una pieza lo fija si depende de lo que pasó.
        NeedsReboot = $null
    }
}

# Texto de avance de un cambio largo (la fila lo muestra mientras aplica). Nunca corta el cambio.
function Set-AfTxProgress {
    param([Parameter(Mandatory)]$Tx, [string]$Text)
    if (-not $Tx.Progress) { return }
    try { & $Tx.Progress $Text } catch { Write-AfLog -Level Warn -Message "No se pudo mostrar el avance: $($_.Exception.Message)" }
}

# Paso real del cambio para la ventana: save, apply, backup o restore. 'apply' sale una sola vez. Nunca corta el cambio.
function Send-AfTxStep {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Name)
    if ($Name -eq 'apply') {
        if ($Tx.ApplySent) { return }
        $Tx.ApplySent = $true
    }
    if (-not $Tx.Step) { return }
    try { & $Tx.Step $Name } catch { Write-AfLog -Level Warn -Message "No se pudo mostrar el paso: $($_.Exception.Message)" }
}

function Add-AfTxRecord {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][hashtable]$Record)
    if (-not $Record.Kind) { throw (T 'El registro del cambio necesita Kind.') }
    [void]$Tx.Records.Add([pscustomobject]$Record)
    # El valor original ya está guardado: lo que sigue es escribir.
    Send-AfTxStep -Tx $Tx -Name 'apply'
}

# Error con un motivo que se puede mostrar en la fila. Uso: throw (New-AfApplyError -Reason '…').
function New-AfApplyError {
    param([Parameter(Mandatory)][string]$Reason, [switch]$Reverted)
    $exception = New-Object System.Exception($Reason)
    $exception.Data['AfReason'] = $Reason
    $exception.Data['AfReverted'] = [bool]$Reverted
    $exception
}

function Get-AfErrorData {
    param($ErrorRecord, [string]$Key)
    $exception = $ErrorRecord.Exception
    while ($exception) {
        if ($exception.Data -and $exception.Data.Contains($Key)) { return $exception.Data[$Key] }
        $exception = $exception.InnerException
    }
    $null
}

function Get-AfApplyReason {
    param([Parameter(Mandatory)]$ErrorRecord)
    $reason = Get-AfErrorData -ErrorRecord $ErrorRecord -Key 'AfReason'
    if ($reason) { [string]$reason } else { (T 'Windows no aceptó el cambio') }
}

function Test-AfRevertError {
    param([Parameter(Mandatory)]$ErrorRecord)
    [bool](Get-AfErrorData -ErrorRecord $ErrorRecord -Key 'AfReverted')
}

# Usuario de una sesión guardada: si no es el del proceso, su HKCU es HKEY_USERS\<SID>.
function Get-AfUserForSid {
    param([string]$Sid)
    $current = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    if (-not $Sid) { $Sid = $current }
    $same = $Sid -eq $current
    [pscustomobject]@{ Sid = $Sid; IsSameAsProcess = $same; HkcuRoot = if ($same) { 'HKCU:' } else { "Registry::HKEY_USERS\$Sid" } }
}

# Texto estable para comparar valores que vienen del sistema o de un JSON (claves ordenadas, números normalizados).
function ConvertTo-AfComparable {
    param($Value)
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [string]) { return 's:' + $Value }
    if ($Value -is [bool]) { return 'b:' + $Value }
    if ($Value -is [System.Collections.IDictionary]) {
        $keys = @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)
        return '{' + (($keys | ForEach-Object { $_ + '=' + (ConvertTo-AfComparable $Value[$_]) }) -join ',') + '}'
    }
    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $names = @($Value.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object)
        return '{' + (($names | ForEach-Object { $_ + '=' + (ConvertTo-AfComparable $Value.$_) }) -join ',') + '}'
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        return '[' + ((@($Value) | ForEach-Object { ConvertTo-AfComparable $_ }) -join ',') + ']'
    }
    if ($Value -is [ValueType] -and $Value -isnot [char] -and $Value -isnot [datetime] -and $Value -isnot [guid]) {
        try { return 'n:' + ([decimal]$Value).ToString([System.Globalization.CultureInfo]::InvariantCulture) } catch { }
    }
    'o:' + [string]$Value
}

function Undo-AfRecord {
    param([Parameter(Mandatory)]$Record, $User)
    $command = 'Restore-Af{0}' -f $Record.Kind
    if (-not (Get-Command -Name $command -CommandType Function -ErrorAction SilentlyContinue)) { throw (New-AfApplyError -Reason (T 'Afina no sabe deshacer este cambio')) }
    & $command -Record $Record -User $User
}

# Deshace al revés. Sigue si uno falla y devuelve los que quedaron sin deshacer.
function Undo-AfRecords {
    param([object[]]$Records = @(), $User)
    $failed = New-Object System.Collections.ArrayList
    $adapters = New-Object System.Collections.ArrayList
    $reason = $null
    for ($i = $Records.Count - 1; $i -ge 0; $i--) {
        $record = $Records[$i]
        if ($record.Kind -eq 'Action') { continue }
        try {
            Undo-AfRecord -Record $record -User $User
            if ($record.Kind -eq 'NetAdapterProperty' -and $record.InterfaceGuid -and -not $adapters.Contains([string]$record.InterfaceGuid)) { [void]$adapters.Add([string]$record.InterfaceGuid) }
        } catch {
            Write-AfLog -Level Warn -Message ('No se pudo deshacer {0} {1}: {2}' -f $record.Kind, $record.Name, $_.Exception.Message)
            if (-not $reason) { $reason = Get-AfApplyReason -ErrorRecord $_ }
            [void]$failed.Insert(0, $record)
        }
    }
    if ($adapters.Count) { Restart-AfAdapters -InterfaceGuid @($adapters) }
    [pscustomobject]@{ Failed = @($failed); Reason = $reason }
}

function Get-AfRecordState {
    param([Parameter(Mandatory)]$Record, $User)
    & ('Get-Af{0}State' -f $Record.Kind) -Record $Record -User $User
}

function Test-AfRecordRestored {
    param([Parameter(Mandatory)]$Record, $User)
    if ($Record.Kind -eq 'Action') { return $true }
    (ConvertTo-AfComparable (Get-AfRecordState -Record $Record -User $User)) -eq (ConvertTo-AfComparable $Record.Previous)
}

function Complete-AfTransaction {
    param([Parameter(Mandatory)]$Tx)
    if ($Tx.RestartAdapters.Count) { Restart-AfAdapters -InterfaceGuid @($Tx.RestartAdapters) }
}
