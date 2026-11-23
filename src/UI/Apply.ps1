# Confirmación, aplicando, listo y deshacer (diseño, sección 8, pasos 4 a 8).

function Set-AfFooterButton {
    param($Button, $TextBlock, $IconPath, [string]$Text, [string]$Icon)
    if (-not $Text) { $Button.Visibility = 'Collapsed'; return }
    $Button.Visibility = 'Visible'
    $TextBlock.Text = $Text
    if ($Icon) { Set-AfIconData -Path $IconPath -Name $Icon; $IconPath.Visibility = 'Visible' } else { $IconPath.Visibility = 'Collapsed' }
}

# Pie de la ventana: nota, opción de Restaurar sistema y hasta tres botones. Un botón sin texto se oculta.
function Set-AfFooter {
    param(
        [Parameter(Mandatory)]$Window,
        [string]$Note,
        [string]$NoteIcon = 'shield-check',
        [string]$Ghost,
        [string]$GhostIcon,
        [string]$Extra,
        [string]$ExtraIcon,
        [string]$Primary,
        [switch]$PrimaryOptimize,
        [switch]$Busy,
        $RestoreOption = $null,
        [bool]$Motion = $false
    )
    if ($PSBoundParameters.ContainsKey('Note')) {
        $block = $Window.FindName('NoteText')
        if ($block.Text -ne $Note) { Set-AfTextAnimated -Block $block -Text $Note -Motion $Motion }
        Set-AfIconData -Path $Window.FindName('NoteIcon') -Name $NoteIcon
    }
    $restoreRow = $Window.FindName('RestoreRow')
    if ($null -ne $RestoreOption) {
        $restoreRow.Visibility = 'Visible'
        $Window.FindName('RestoreOption').IsChecked = [bool]$RestoreOption
    } else {
        $restoreRow.Visibility = 'Collapsed'
    }
    Set-AfFooterButton -Button $Window.FindName('GhostButton') -TextBlock $Window.FindName('GhostText') -IconPath $Window.FindName('GhostIcon') -Text $Ghost -Icon $GhostIcon
    Set-AfFooterButton -Button $Window.FindName('ExtraButton') -TextBlock $Window.FindName('ExtraText') -IconPath $Window.FindName('ExtraIcon') -Text $Extra -Icon $ExtraIcon
    $button = $Window.FindName('PrimaryButton')
    $button.IsHitTestVisible = -not $Busy
    if ($PrimaryOptimize) {
        $button.Visibility = 'Visible'
        Update-AfPrimary -Window $Window
    } elseif ($Primary) {
        $button.Visibility = 'Visible'
        $Window.FindName('PrimaryLead').Text = $Primary
        $Window.FindName('PrimaryNumber').Text = ''
        $Window.FindName('PrimaryTail').Text = ''
    } else {
        $button.Visibility = 'Collapsed'
    }
}

function Get-AfConfirmText {
    param([int]$Count, [bool]$Network = $false, [bool]$Display = $false, [int]$Reboot = 0, [ValidateSet('create', 'enable', 'off', 'blocked')][string]$Restore = 'create', [bool]$Updates = $false, [int]$Advanced = 0, [bool]$DeletesRecall = $false)
    $parts = @()
    $parts += if ($Count -eq 1) { (T 'Se aplicará 1 cambio.') } else { (T 'Se aplicarán {0} cambios.') -f $Count }
    if ($Updates) { $parts += (T 'Las actualizaciones pueden tardar varios minutos.') }
    if ($Advanced -eq 1) { $parts += (T '1 cambio baja la seguridad de Windows.') } elseif ($Advanced -gt 1) { $parts += (T '{0} cambios bajan la seguridad de Windows.') -f $Advanced }
    if ($DeletesRecall) { $parts += (T 'Borra las capturas guardadas de Recall y no se recuperan.') }
    if ($Display) { $parts += (T 'La pantalla cambia y pide confirmar.') }
    if ($Network) { $parts += (T 'La red se cortará unos segundos.') }
    if ($Reboot -gt 0) { $parts += (T 'Al final pide reiniciar.') }
    $parts += switch ($Restore) {
        'create' { (T 'Se crea un punto de restauración antes.') }
        'enable' { (T 'Se activa Restaurar sistema y se crea un punto antes.') }
        'off' { (T 'Sin punto de restauración: Restaurar sistema está apagado. Los valores originales igual se guardan.') }
        'blocked' { (T 'Restaurar sistema está bloqueado en esta PC; los valores originales igual se guardan.') }
    }
    $parts -join ' '
}

function Get-AfDoneText {
    param([int]$Applied, [int]$Failed = 0, [int]$Reboot = 0, [int]$Manual = 0)
    $lead = switch ($Applied) { 0 { (T 'Ningún cambio aplicado') } 1 { (T '1 cambio aplicado') } default { (T '{0} cambios aplicados') -f $Applied } }
    # Los espacios van en el código: las traducciones no llevan espacios al principio ni al final.
    $rest = ''
    if ($Failed -eq 1) { $rest += ' ' + (T 'y 1 no se pudo') } elseif ($Failed -gt 1) { $rest += ' ' + ((T 'y {0} no se pudieron') -f $Failed) }
    $rest += '.'
    if ($Reboot -eq 1) { $rest += ' ' + (T 'Reinicia para terminar 1.') } elseif ($Reboot -gt 1) { $rest += ' ' + ((T 'Reinicia para terminar {0}.') -f $Reboot) }
    if ($Manual -eq 1) { $rest += ' ' + (T 'Queda 1 para hacer a mano.') } elseif ($Manual -gt 1) { $rest += ' ' + ((T 'Quedan {0} para hacer a mano.') -f $Manual) }
    [pscustomobject]@{ Lead = $lead; Rest = $rest; Text = $lead + $rest }
}

function Get-AfDisplayPrompt {
    param([int]$Seconds = 15)
    (T '¿Se ve bien la pantalla? Vuelve sola al modo anterior en {0} s.') -f $Seconds
}

function Set-AfLeadSummary {
    param([Parameter(Mandatory)]$Window, [string]$Lead, [string]$Rest, [bool]$Motion = $false)
    $block = $Window.FindName('Summary')
    $block.Inlines.Clear()
    $run = New-Object System.Windows.Documents.Run($Lead)
    $run.FontWeight = 'Medium'
    $run.SetResourceReference([System.Windows.Documents.TextElement]::ForegroundProperty, 'Text')
    $block.Inlines.Add($run)
    if ($Rest) { $block.Inlines.Add((New-Object System.Windows.Documents.Run($Rest))) }
    Start-AfAnimation -Target $block -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 220 -Ease Out -Enabled $Motion | Out-Null
}

# Los resultados con lo ya aplicado como "en orden": así se mueven la aguja, el resumen y los contadores.
function Get-AfEffectiveResults {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    foreach ($result in @($s.Results)) {
        $change = if ($s.Applied) { $s.Applied[$result.Check.Id] } else { $null }
        if ($change -and $change.Status -eq 'Applied') {
            [pscustomobject]@{ Check = $result.Check; Detection = (New-AfDetection -State Ok -Title $result.Detection.Title -Current $result.Detection.Target); Weight = $result.Weight; Preselected = $false }
        } else {
            $result
        }
    }
}

function Update-AfProgressView {
    param([Parameter(Mandatory)]$Window, [bool]$Motion = $false)
    $effective = @(Get-AfEffectiveResults -Window $Window)
    Set-AfNeedle -Window $Window -Fraction (Get-AfScore -Results $effective) -Motion $Motion -DurationMs 460 -Ease InOut
    Update-AfNavCounts -Window $Window -Results $effective -Motion $Motion
}

function Set-AfProgress {
    param([Parameter(Mandatory)]$Window, [double]$Fraction, [bool]$Motion = $false)
    Start-AfAnimation -Target $Window.FindName('PrimaryProgressScale') -Property ([System.Windows.Media.ScaleTransform]::ScaleXProperty) -To ([math]::Min(1, [math]::Max(0, $Fraction))) -DurationMs 460 -Ease InOut -Enabled $Motion | Out-Null
}

function Get-AfReadyNote { (T 'Se crea un punto de restauración antes de aplicar') }

function Set-AfReadyView {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $s.Phase = 'ready'
    $Window.FindName('Groups').IsHitTestVisible = $true
    Stop-AfFollow -Window $Window
    $effective = @(Get-AfEffectiveResults -Window $Window)
    $summary = Get-AfSummary -Results $effective
    Update-AfVerdict -Window $Window
    Set-AfSummary -Window $Window -Summary $summary -Motion $s.Motion
    Set-AfProgress -Window $Window -Fraction 0 -Motion $s.Motion
    Set-AfFooter -Window $Window -Note (Get-AfReadyNote) -NoteIcon 'shield-check' -Ghost (T 'Volver a analizar') -GhostIcon 'arrow-clockwise' -PrimaryOptimize -Motion $s.Motion
}

function Set-AfDoneSummary {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $changes = @($s.Applied.Values)
    $applied = @($changes | Where-Object { $_.Status -eq 'Applied' })
    $notApplied = @($changes | Where-Object { $_.Status -in 'Failed', 'Reverted' }).Count
    $reboot = @($applied | Where-Object { $_.NeedsReboot }).Count
    $summary = Get-AfSummary -Results @(Get-AfEffectiveResults -Window $Window)
    $text = Get-AfDoneText -Applied $applied.Count -Failed $notApplied -Reboot $reboot -Manual $summary.Manual
    Set-AfLeadSummary -Window $Window -Lead $text.Lead -Rest $text.Rest -Motion $s.Motion
}

function Set-AfDoneView {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $s.Phase = 'done'
    $Window.FindName('Groups').IsHitTestVisible = $true
    Stop-AfFollow -Window $Window
    $changes = @($s.Applied.Values)
    Update-AfVerdict -Window $Window
    Set-AfProgress -Window $Window -Fraction 0 -Motion $s.Motion
    $extra = if (@($changes | Where-Object { Test-AfChangeUndoable -Change $_ }).Count) { (T 'Deshacer') } else { $null }
    $note = (T 'Valores originales guardados. Se puede deshacer desde Historial.')
    if ($s.RebootPending) {
        Set-AfFooter -Window $Window -Note $note -NoteIcon 'shield-check' -Extra $extra -ExtraIcon 'arrow-counter-clockwise' -Ghost (T 'Más tarde') -Primary (T 'Reiniciar ahora') -Motion $s.Motion
    } else {
        Set-AfFooter -Window $Window -Note $note -NoteIcon 'shield-check' -Extra $extra -ExtraIcon 'arrow-counter-clockwise' -Primary (T 'Volver a analizar') -Motion $s.Motion
    }
}

function Enter-AfConfirm {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $selected = @(Get-AfSelectedResults -Window $Window)
    if (-not $selected.Count) { return }
    if (-not $s.DemoCode -and -not (Test-AfAdmin)) {
        Set-AfFooter -Window $Window -Note (T 'Para aplicar cambios, abre Afina como administrador.') -NoteIcon 'warning-circle' -Ghost (T 'Volver a analizar') -GhostIcon 'arrow-clockwise' -PrimaryOptimize -Motion $s.Motion
        return
    }
    $status = Get-AfRestoreStatus
    $restore = if ($status.Enabled) { 'create' } elseif ($status.Blocked) { 'blocked' } else { 'enable' }
    $s.Confirm = [pscustomobject]@{
        Selected = $selected
        Restore = $restore
        Count = $selected.Count
        Network = @($selected | Where-Object { $_.Check.Category -eq 'network' }).Count -gt 0
        Display = @($selected | Where-Object { $_.Check.Id -eq 'display.refresh' }).Count -gt 0
        Reboot = @($selected | Where-Object { $_.Check.NeedsReboot }).Count
        Updates = @($selected | Where-Object { $_.Check.Id -like 'updates.*' }).Count -gt 0
        Advanced = @($selected | Where-Object { $_.Check.Risk -eq 'Advanced' -and $_.Check.Id -ne 'cleanup.recall' }).Count
        DeletesRecall = @($selected | Where-Object { $_.Check.Id -eq 'cleanup.recall' }).Count -gt 0
    }
    $s.Phase = 'confirm'
    $Window.FindName('Groups').IsHitTestVisible = $false
    $option = if ($restore -eq 'enable') { $true } else { $null }
    Set-AfFooter -Window $Window -Note (Get-AfConfirmNote -Window $Window) -NoteIcon 'shield-check' -Ghost (T 'Cancelar') -Primary (T 'Aplicar') -RestoreOption $option -Motion $s.Motion
}

# El texto de la confirmación según lo elegido y la casilla de Restaurar sistema.
function Get-AfConfirmNote {
    param([Parameter(Mandatory)]$Window)
    $c = $Window.Tag.Confirm
    $restore = $c.Restore
    if ($restore -eq 'enable' -and $Window.FindName('RestoreRow').Visibility -eq 'Visible' -and -not $Window.FindName('RestoreOption').IsChecked) { $restore = 'off' }
    Get-AfConfirmText -Count $c.Count -Network $c.Network -Display $c.Display -Reboot $c.Reboot -Restore $restore -Updates ([bool]$c.Updates) -Advanced ([int]$c.Advanced) -DeletesRecall ([bool]$c.DeletesRecall)
}

function Exit-AfConfirm {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $s.Phase = 'ready'
    $Window.FindName('Groups').IsHitTestVisible = $true
    Set-AfFooter -Window $Window -Note (Get-AfReadyNote) -NoteIcon 'shield-check' -Ghost (T 'Volver a analizar') -GhostIcon 'arrow-clockwise' -PrimaryOptimize -Motion $s.Motion
    # Lo que llegó mientras se confirmaba se evalúa ahora.
    Update-AfVerdict -Window $Window -Celebrate
}

function Get-AfWorkerCode {
    param([Parameter(Mandatory)]$Window)
    if ($Window.Tag.DemoCode) { $Global:AfCode + "`r`n" + $Window.Tag.DemoCode } else { $Global:AfCode }
}

function Start-AfApply {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $c = $s.Confirm
    $restore = $c.Restore
    if ($restore -eq 'enable' -and -not $Window.FindName('RestoreOption').IsChecked) { $restore = 'off' }
    $action = if ($restore -in 'create', 'enable') { $restore } else { 'none' }
    $s.Phase = 'applying'
    $s.Applied = @{}
    $s.RebootPending = $false
    $s.ApplyTotal = $c.Count
    $s.ApplyIndex = 0
    $s.ApplyCount = 0
    $s.ApplyNote = (T 'Preparando…')
    $s.Follow = $true
    $s.FollowId = $null
    $s.ApplyHoldUntil = [datetime]::MinValue
    $s.Shared = [hashtable]::Synchronized(@{ DisplayAnswer = $null; ContinueWithoutRestore = $null; Current = $null })
    $s.ApplyQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    $plan = [pscustomobject]@{
        Mode = 'Apply'
        Items = @($c.Selected | ForEach-Object { [pscustomobject]@{ Id = $_.Check.Id; Detection = $_.Detection } })
        Inventory = $s.Inventory
        RestoreAction = $action
        BackupDirectory = $s.BackupDirectory
        Version = Get-AfVersion
        LogPath = Get-AfLogPath
        Language = Get-AfLanguage
    }
    Set-AfFooter -Window $Window -Note $s.ApplyNote -NoteIcon 'shield-check' -Primary (T 'Preparando…') -Busy -Motion $s.Motion
    Set-AfProgress -Window $Window -Fraction 0
    Write-AfLog -Level Info -Message ('Aplicar {0} cambios: {1}' -f $c.Count, (@($plan.Items.Id) -join ', '))
    $s.ApplyWorker = Start-AfApplyWorker -Code (Get-AfWorkerCode -Window $Window) -Queue $s.ApplyQueue -Shared $s.Shared -Plan $plan
}

function Set-AfApplyingFooter {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $label = if ($s.ApplyIndex -gt 0) { (T 'Aplicando {0} de {1}') -f $s.ApplyIndex, $s.ApplyTotal } else { (T 'Preparando…') }
    Set-AfFooter -Window $Window -Note $s.ApplyNote -NoteIcon 'shield-check' -Primary $label -Busy -Motion $s.Motion
}

# Arriba, mientras aplica: "Optimizando 2 de 5" y el cambio en curso con su paso.
function Set-AfApplyingHeader {
    param([Parameter(Mandatory)]$Window, [string]$Step)
    $s = $Window.Tag
    $Window.FindName('Title').Text = (T 'Optimizando')
    $count = $Window.FindName('TitleCount')
    $count.Text = (T '{0} de {1}') -f $s.ApplyIndex, [math]::Max($s.ApplyIndex, $s.ApplyTotal)
    $count.Visibility = 'Visible'
    $rest = ' · ' + $(if ($Step) { Get-AfStepText -Key $Step } else { '' }) + '…'
    Set-AfLeadSummary -Window $Window -Lead $s.FollowTitle -Rest $rest
}

# Con animaciones, la ventana deja ver cada evento un momento. El motor no espera: solo la lectura de la cola.
function Set-AfApplyHold {
    param([Parameter(Mandatory)]$Window, [int]$Milliseconds)
    $s = $Window.Tag
    if ($s.Motion) { $s.ApplyHoldUntil = (Get-Date).AddMilliseconds($Milliseconds) }
}

# Fin del seguimiento: sin píldora ni cuenta junto al título.
function Stop-AfFollow {
    param([Parameter(Mandatory)]$Window)
    $Window.FindName('FollowChip').Visibility = 'Collapsed'
    $Window.FindName('TitleCount').Visibility = 'Collapsed'
}

function Start-AfDisplayCountdown {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    if ($s.DisplayTimer) { $s.DisplayTimer.Stop() }
    $s.DisplaySeconds = 15
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Tag = $Window
    $timer.Add_Tick({
            param($sender, $e)
            $w = $sender.Tag
            $w.Tag.DisplaySeconds--
            if ($w.Tag.DisplaySeconds -le 0 -or $w.Tag.Phase -ne 'display') { $sender.Stop(); return }
            $w.FindName('NoteText').Text = Get-AfDisplayPrompt -Seconds $w.Tag.DisplaySeconds
        })
    $s.DisplayTimer = $timer
    $timer.Start()
}

function Stop-AfDisplayCountdown {
    param([Parameter(Mandatory)]$Window)
    if ($Window.Tag.DisplayTimer) { $Window.Tag.DisplayTimer.Stop() }
}

function Start-AfUndo {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)][string]$SessionPath, [string[]]$ChangeIds = @(), [switch]$FromHistory)
    $s = $Window.Tag
    $s.UndoFromHistory = [bool]$FromHistory
    $s.Phase = 'undoing'
    $s.UndoIndex = 0
    $s.UndoSessionPath = $SessionPath
    $s.Follow = $true
    $s.FollowId = $null
    $s.ApplyHoldUntil = [datetime]::MinValue
    $session = Import-AfSession -Path $SessionPath
    $s.UndoTotal = @($session.Changes | Where-Object { ($ChangeIds.Count -eq 0 -or $ChangeIds -contains $_.CheckId) -and (Test-AfChangeUndoable -Change $_) }).Count
    if ($FromHistory) { $Window.FindName('HistoryList').IsHitTestVisible = $false } else { $Window.FindName('Groups').IsHitTestVisible = $false }
    Set-AfFooter -Window $Window -Note (T 'Deshaciendo con los valores originales guardados…') -NoteIcon 'arrow-counter-clockwise' -Primary (T 'Deshaciendo…') -Busy -Motion $s.Motion
    $s.Shared = [hashtable]::Synchronized(@{})
    $s.ApplyQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    $plan = [pscustomobject]@{ Mode = 'Undo'; SessionPath = $SessionPath; ChangeIds = @($ChangeIds); LogPath = Get-AfLogPath; Language = Get-AfLanguage }
    Write-AfLog -Level Info -Message "Deshacer $SessionPath ($(if ($ChangeIds.Count) { $ChangeIds -join ', ' } else { 'todo' }))"
    $s.ApplyWorker = Start-AfApplyWorker -Code (Get-AfWorkerCode -Window $Window) -Queue $s.ApplyQueue -Shared $s.Shared -Plan $plan
}

function Complete-AfUndo {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    if ($s.UndoFromHistory) {
        $s.NeedsRescan = $true
        Show-AfHistory -Window $Window
        return
    }
    Set-AfReadyView -Window $Window
    Update-AfProgressView -Window $Window -Motion $s.Motion
}

function Receive-AfApplyEvent {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)]$Item)
    $s = $Window.Tag
    switch ($Item.Type) {
        'Stage' {
            $s.ApplyNote = $Item.Text
            Set-AfApplyingFooter -Window $Window
        }
        'RestorePoint' {
            if ($Item.Ok) {
                $s.ApplyNote = (T 'Punto de restauración creado a las {0}.') -f (Format-AfTime -Date ([datetime]$Item.At))
                Set-AfApplyingFooter -Window $Window
            } else {
                $s.Phase = 'restore'
                Set-AfFooter -Window $Window -Note ((T 'No se pudo crear el punto de restauración: {0}. Los valores originales igual se guardan en Afina.') -f $Item.Message) -NoteIcon 'warning-circle' -Ghost (T 'Cancelar') -Primary (T 'Seguir sin punto') -Motion $s.Motion
            }
        }
        'Cancelled' { Set-AfReadyView -Window $Window }
        'ChangeStart' {
            $s.ApplyIndex++
            $s.FollowId = $Item.Id
            $s.FollowStep = $null
            $row = Get-AfRowById -Window $Window -Id $Item.Id
            if ($row) {
                Set-AfRowStatus -Row $row -Status Applying -Motion $s.Motion
                $s.FollowTitle = if ($row.Tag.Detection.Title) { $row.Tag.Detection.Title } else { $row.Tag.Check.Title }
                # La vista va sola a la fila en curso y la abre con sus pasos reales.
                Move-AfFollow -Window $Window -Id $Item.Id
                Open-AfRowSteps -Row $row -Keys $(if ($row.Tag.Check.NoUndo) { @('apply', 'backup') } else { @('save', 'apply', 'backup') }) -Motion $s.Motion
            }
            Set-AfApplyingHeader -Window $Window
            Set-AfApplyingFooter -Window $Window
            Set-AfApplyHold -Window $Window -Milliseconds 300
        }
        'ChangeStep' {
            # Desde el Historial, el paso se escribe en la línea del cambio.
            if ($s.Phase -eq 'undoing' -and $s.UndoFromHistory) {
                if ($s.HistoryStepText) { $s.HistoryStepText.Text = Get-AfStepText -Key $Item.Step }
                Set-AfApplyHold -Window $Window -Milliseconds 250
                break
            }
            $row = Get-AfRowById -Window $Window -Id $Item.Id
            if ($row) {
                if ($s.FollowStep) { Set-AfRowStepState -Row $row -Key $s.FollowStep -State Done }
                Set-AfRowStepState -Row $row -Key $Item.Step -State Running
            }
            $s.FollowStep = $Item.Step
            if ($s.Phase -ne 'undoing') { Set-AfApplyingHeader -Window $Window -Step $Item.Step }
            Set-AfApplyHold -Window $Window -Milliseconds 250
        }
        'ChangeProgress' {
            # Avance de un cambio largo (actualizaciones): va en el paso Aplicando; el indicador sigue girando.
            $row = Get-AfRowById -Window $Window -Id $Item.Id
            if ($row) { Set-AfRowStepState -Row $row -Key 'apply' -State Running -Detail $Item.Text }
        }
        'ConfirmDisplay' {
            $s.Phase = 'display'
            Set-AfFooter -Window $Window -Note (Get-AfDisplayPrompt -Seconds 15) -NoteIcon 'info' -Ghost (T 'Volver al anterior') -Primary (T 'Mantener') -Motion $s.Motion
            Start-AfDisplayCountdown -Window $Window
        }
        'ChangeDone' {
            Stop-AfDisplayCountdown -Window $Window
            $s.Phase = 'applying'
            $change = $Item.Change
            $s.Applied[$Item.Id] = $change
            $s.ApplyCount++
            if ($change.Status -eq 'Applied' -and $change.NeedsReboot) { $s.RebootPending = $true }
            $row = Get-AfRowById -Window $Window -Id $Item.Id
            if ($row) {
                $message = if ($change.Status -eq 'Applied') { $change.Note } else { $change.Message }
                # Aplicado: los pasos se cierran. Si no, el paso en curso queda marcado como fallido a la vista.
                if ($change.Status -eq 'Applied') { Close-AfRowSteps -Row $row -Motion $s.Motion }
                elseif ($s.FollowStep) { Set-AfRowStepState -Row $row -Key $s.FollowStep -State Failed }
                Set-AfRowStatus -Row $row -Status $change.Status -Message $message -Motion $s.Motion
            }
            $s.FollowStep = $null
            Set-AfProgress -Window $Window -Fraction ($s.ApplyCount / [math]::Max(1, $s.ApplyTotal)) -Motion $s.Motion
            Update-AfProgressView -Window $Window -Motion $s.Motion
            Set-AfApplyingFooter -Window $Window
        }
        'ApplyDone' {
            $s.SessionPath = $Item.SessionPath
            # Siguiendo, la vista vuelve a Todo; si la persona eligió otra, se queda ahí.
            if ($s.Follow) { Set-AfFilter -Window $Window -Filter 'all' }
            $s.Celebrated = $false
            Set-AfDoneView -Window $Window
            $score = Get-AfScore -Results @(Get-AfEffectiveResults -Window $Window)
            Set-AfNeedle -Window $Window -Fraction $score -Motion $s.Motion -DurationMs 700 -Ease Out
            Update-AfVerdict -Window $Window -Celebrate
            Write-AfLog -Level Info -Message "Sesión guardada en $($Item.SessionPath)"
        }
        'UndoStart' {
            $s.UndoIndex++
            $s.FollowId = $Item.Id
            $s.FollowStep = $null
            if (-not $s.UndoFromHistory) {
                $row = Get-AfRowById -Window $Window -Id $Item.Id
                if ($row) {
                    Set-AfRowStatus -Row $row -Status Undoing -Motion $s.Motion
                    Move-AfFollow -Window $Window -Id $Item.Id
                    Open-AfRowSteps -Row $row -Keys @('restore', 'backup') -Motion $s.Motion
                }
            } else {
                Set-AfHistoryLineBusy -Window $Window -SessionPath $s.UndoSessionPath -Id $Item.Id
            }
            Set-AfApplyHold -Window $Window -Milliseconds 300
            Set-AfFooter -Window $Window -Primary ((T 'Deshaciendo {0} de {1}') -f $s.UndoIndex, [math]::Max($s.UndoIndex, $s.UndoTotal)) -Busy
        }
        'UndoDone' {
            if (-not $s.UndoFromHistory) {
                $row = Get-AfRowById -Window $Window -Id $Item.Id
                if ($Item.Change.Status -eq 'Undone') {
                    if ($s.Applied) { $s.Applied.Remove($Item.Id) }
                    if ($row) { Reset-AfRow -Row $row -Motion $s.Motion | Out-Null }
                } elseif ($row) {
                    if ($s.FollowStep) { Set-AfRowStepState -Row $row -Key $s.FollowStep -State Failed }
                    Set-AfRowStatus -Row $row -Status Failed -Message $Item.Change.Message -Motion $s.Motion
                }
                $s.FollowStep = $null
                Update-AfProgressView -Window $Window -Motion $s.Motion
            }
        }
        'UndoFinished' { Complete-AfUndo -Window $Window }
        'Error' {
            Stop-AfDisplayCountdown -Window $Window
            Write-AfLog -Level Error -Message "Aplicar o deshacer falló: $($Item.Message)"
            $undoing = $s.Phase -eq 'undoing'
            if ($undoing -and $s.UndoFromHistory) { Show-AfHistory -Window $Window }
            elseif ($s.Applied -and @($s.Applied.Values).Count) { Set-AfDoneView -Window $Window }
            else { Set-AfReadyView -Window $Window }
            $text = if ($undoing) { (T 'No se pudo deshacer: {0}.') -f $Item.Message } else { (T 'No se pudo aplicar: {0}. Lo que no aparece como hecho no se cambió.') -f $Item.Message }
            Set-AfNote -Window $Window -Text $text -Icon 'warning-circle' -Motion $s.Motion
        }
    }
}

# Cambia solo la nota del pie, sin tocar los botones.
function Set-AfNote {
    param([Parameter(Mandatory)]$Window, [string]$Text, [string]$Icon = 'shield-check', [bool]$Motion = $false)
    Set-AfTextAnimated -Block $Window.FindName('NoteText') -Text $Text -Motion $Motion
    Set-AfIconData -Path $Window.FindName('NoteIcon') -Name $Icon
}

function Restart-AfComputer {
    Write-AfLog -Level Info -Message 'Reinicio pedido desde Afina.'
    Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\shutdown.exe') -Arguments '/r /t 0' -TimeoutMs 15000 | Out-Null
}
