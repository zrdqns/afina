function Test-AfCanApply {
    param([Parameter(Mandatory)][hashtable]$Check)
    $Check.Kind -eq 'Auto' -and $Check.Apply -is [scriptblock]
}

# La pantalla primero (pide confirmar), la red al final (corta la conexión unos segundos) y el resto en su orden.
function Get-AfApplyOrder {
    param([object[]]$Items = @())
    $index = 0
    $ranked = foreach ($item in $Items) {
        # Las actualizaciones necesitan internet: van antes de que se reinicie el adaptador.
        $group = if ($item.Check.Id -eq 'display.refresh') { 0 } elseif ($item.Check.Category -eq 'network') { 3 } elseif ($item.Check.Id -like 'updates.*') { 2 } else { 1 }
        [pscustomobject]@{ Item = $item; Group = $group; Index = $index }
        $index++
    }
    @($ranked | Sort-Object -Property Group, Index | ForEach-Object { $_.Item })
}

function Test-AfChangeUndoable {
    param([Parameter(Mandatory)]$Change)
    $Change.Status -notin 'Undone', 'Reverted' -and @($Change.Records | Where-Object { $_ -and $_.Kind -ne 'Action' }).Count -gt 0
}

# Aplica una revisión como un todo: si algo falla a mitad, se revierte lo de esa revisión.
function Invoke-AfChange {
    param([Parameter(Mandatory)]$Session, [Parameter(Mandatory)][hashtable]$Check, $Detection, $Inventory, [scriptblock]$ConfirmDisplay, [scriptblock]$Progress, [scriptblock]$Step)
    $user = if ($Inventory -and $Inventory.User) { $Inventory.User } else { Get-AfUserForSid -Sid $Session.User.Sid }
    $tx = New-AfTransaction -User $user -ConfirmDisplay $ConfirmDisplay -Progress $Progress -Step $Step
    # Sin valor original que guardar, el primer paso ya es aplicar.
    Send-AfTxStep -Tx $tx -Name $(if ($Check.NoUndo) { 'apply' } else { 'save' })
    $title = if ($Detection -and $Detection.Title) { $Detection.Title } else { $Check.Title }
    $change = [pscustomobject]@{
        CheckId = $Check.Id; Title = $title; NeedsReboot = [bool]$Check.NeedsReboot
        Status = 'Applied'; Message = $null; Note = $null; AppliedAt = $null; UndoneAt = $null; Records = @()
    }
    try {
        if (-not (Test-AfCanApply -Check $Check)) { throw (New-AfApplyError -Reason (T 'este cambio todavía no se aplica desde Afina')) }
        & $Check.Apply $Inventory $Detection $tx | Out-Null
        Complete-AfTransaction -Tx $tx
        $change.Records = @($tx.Records)
        if ($null -ne $tx.NeedsReboot) { $change.NeedsReboot = [bool]$tx.NeedsReboot }
        $change.AppliedAt = (Get-Date).ToString('o')
        if ($tx.Notes.Count) { $change.Note = @($tx.Notes) -join ' ' }
        Write-AfLog -Level Info -Message ('Aplicado {0} ({1} registros).' -f $Check.Id, $tx.Records.Count)
        Send-AfTxStep -Tx $tx -Name 'backup'
    } catch {
        $failure = $_
        $reason = Get-AfApplyReason -ErrorRecord $failure
        Write-AfLog -Level Warn -Message ('No se aplicó {0}: {1}' -f $Check.Id, $failure.Exception.Message)
        $left = @((Undo-AfRecords -Records @($tx.Records) -User $user).Failed)
        $change.Records = $left
        if ($left.Count) {
            $change.Status = 'Failed'
            $change.Message = (T 'No se pudo aplicar: {0}. Una parte quedó aplicada y se puede deshacer desde Historial.') -f $reason
        } elseif (Test-AfRevertError -ErrorRecord $failure) {
            $change.Status = 'Reverted'
            $change.Message = $reason + '.'
        } else {
            $change.Status = 'Failed'
            $change.Message = (T 'No se pudo aplicar: {0}. No se cambió nada.') -f $reason
        }
    }
    [void]$Session.Changes.Add($change)
    try {
        Save-AfSession -Session $Session
    } catch {
        # Sin respaldo no queda nada aplicado.
        Write-AfLog -Level Error -Message ('No se pudo guardar el respaldo tras {0}: {1}' -f $Check.Id, $_.Exception.Message)
        if ($change.Status -eq 'Applied') {
            $left = @((Undo-AfRecords -Records @($change.Records) -User $user).Failed)
            $change.Records = $left
            $change.Status = 'Failed'
            $change.Message = if ($left.Count) { (T 'No se pudo guardar el respaldo y una parte quedó aplicada.') } else { (T 'No se pudo aplicar: no se pudo guardar el respaldo. No se cambió nada.') }
        }
        try { Save-AfSession -Session $Session } catch { }
    }
    $change
}

# Lo que corre en el trabajo de aplicar. Habla con la ventana solo por la cola (eventos) y por $Shared (respuestas).
function Invoke-AfApplyPlan {
    param([Parameter(Mandatory)]$Plan, [Parameter(Mandatory)]$Queue, [Parameter(Mandatory)]$Shared, [object[]]$Catalog)
    # Los motivos y las notas salen en el idioma de la ventana (antes de armar el catálogo).
    if ($Plan.Language) { Set-AfLanguage -Language $Plan.Language }
    if (-not $PSBoundParameters.ContainsKey('Catalog')) { $Catalog = @(Get-AfCatalog) }
    $inventory = $Plan.Inventory
    $restore = $null
    if ($Plan.RestoreAction -in 'create', 'enable') {
        if ($Plan.RestoreAction -eq 'enable') {
            $Queue.Enqueue([pscustomobject]@{ Type = 'Stage'; Text = (T 'Activando Restaurar sistema…') })
            Enable-AfSystemRestore | Out-Null
        }
        $Queue.Enqueue([pscustomobject]@{ Type = 'Stage'; Text = (T 'Creando punto de restauración…') })
        $restore = New-AfRestorePoint
        $Queue.Enqueue([pscustomobject]@{ Type = 'RestorePoint'; Ok = $restore.Ok; At = $restore.At; Message = $restore.Message })
        if (-not $restore.Ok) {
            while ($null -eq $Shared.ContinueWithoutRestore) { Start-Sleep -Milliseconds 100 }
            if (-not $Shared.ContinueWithoutRestore) {
                Write-AfLog -Level Info -Message 'Se canceló: no hubo punto de restauración.'
                $Queue.Enqueue([pscustomobject]@{ Type = 'Cancelled' })
                return
            }
        }
    }
    $session = New-AfSession -Directory $Plan.BackupDirectory -User $inventory.User -Version $Plan.Version
    $session.RestorePoint = [pscustomobject]@{
        Created = [bool]($restore -and $restore.Ok)
        At = if ($restore) { $restore.At } else { $null }
        Message = if ($restore) { $restore.Message } else { $null }
        EnabledSystemRestore = $Plan.RestoreAction -eq 'enable'
    }
    Save-AfSession -Session $session
    $items = Get-AfApplyOrder -Items @(foreach ($planned in @($Plan.Items)) {
            $check = @($Catalog | Where-Object { $_.Id -eq $planned.Id })[0]
            if ($check) { [pscustomobject]@{ Id = $planned.Id; Check = $check; Detection = $planned.Detection } }
        })
    # La pantalla se confirma desde la ventana; sin respuesta en 15 s vuelve sola.
    $confirm = {
        param($records)
        $Shared.DisplayAnswer = $null
        $Queue.Enqueue([pscustomobject]@{ Type = 'ConfirmDisplay'; Id = $Shared.Current; Records = @($records) })
        $deadline = (Get-Date).AddSeconds(15)
        while ((Get-Date) -lt $deadline -and -not $Shared.DisplayAnswer) { Start-Sleep -Milliseconds 100 }
        if ($Shared.DisplayAnswer) { $Shared.DisplayAnswer } else { 'timeout' }
    }.GetNewClosure()
    $progress = {
        param($text)
        $Queue.Enqueue([pscustomobject]@{ Type = 'ChangeProgress'; Id = $Shared.Current; Text = [string]$text })
    }.GetNewClosure()
    $step = {
        param($name)
        $Queue.Enqueue([pscustomobject]@{ Type = 'ChangeStep'; Id = $Shared.Current; Step = [string]$name })
    }.GetNewClosure()
    foreach ($item in $items) {
        $Shared.Current = $item.Id
        $Queue.Enqueue([pscustomobject]@{ Type = 'ChangeStart'; Id = $item.Id })
        $change = Invoke-AfChange -Session $session -Check $item.Check -Detection $item.Detection -Inventory $inventory -ConfirmDisplay $confirm -Progress $progress -Step $step
        $Queue.Enqueue([pscustomobject]@{ Type = 'ChangeDone'; Id = $item.Id; Change = $change })
    }
    $Queue.Enqueue([pscustomobject]@{ Type = 'ApplyDone'; SessionPath = $session.Path })
}

# Deshace en el orden inverso al aplicado; sin ChangeIds, todo lo que se pueda de la sesión.
function Invoke-AfUndoPlan {
    param([Parameter(Mandatory)]$Plan, [Parameter(Mandatory)]$Queue)
    if ($Plan.Language) { Set-AfLanguage -Language $Plan.Language }
    $session = Import-AfSession -Path $Plan.SessionPath
    $ids = @($Plan.ChangeIds | Where-Object { $_ })
    $changes = @($session.Changes | Where-Object { ($ids.Count -eq 0 -or $ids -contains $_.CheckId) -and (Test-AfChangeUndoable -Change $_) })
    [array]::Reverse($changes)
    foreach ($change in $changes) {
        $Queue.Enqueue([pscustomobject]@{ Type = 'UndoStart'; Id = $change.CheckId })
        $id = $change.CheckId
        $step = { param($name) $Queue.Enqueue([pscustomobject]@{ Type = 'ChangeStep'; Id = $id; Step = [string]$name }) }.GetNewClosure()
        Undo-AfChange -Session $session -Change $change -Step $step | Out-Null
        $Queue.Enqueue([pscustomobject]@{ Type = 'UndoDone'; Id = $change.CheckId; Change = $change })
    }
    $Queue.Enqueue([pscustomobject]@{ Type = 'UndoFinished'; SessionPath = $session.Path })
}

function Undo-AfChange {
    param([Parameter(Mandatory)]$Session, [Parameter(Mandatory)]$Change, [scriptblock]$Step)
    if (-not (Test-AfChangeUndoable -Change $Change)) { return $Change }
    $steps = [pscustomobject]@{ Step = $Step; ApplySent = $true }
    Send-AfTxStep -Tx $steps -Name 'restore'
    $user = Get-AfUserForSid -Sid $Session.User.Sid
    $result = Undo-AfRecords -Records @($Change.Records) -User $user
    $left = @($result.Failed)
    if ($left.Count) {
        $Change.Status = 'UndoFailed'
        $Change.Records = @($left)
        $Change.Message = (T 'No se pudo deshacer: {0}.') -f $result.Reason
    } else {
        $Change.Status = 'Undone'
        $Change.UndoneAt = (Get-Date).ToString('o')
        $Change.Message = $null
    }
    Write-AfLog -Level Info -Message ('Deshacer {0}: {1}' -f $Change.CheckId, $Change.Status)
    if ($Change.Status -eq 'Undone') { Send-AfTxStep -Tx $steps -Name 'backup' }
    Save-AfSession -Session $Session
    $Change
}
