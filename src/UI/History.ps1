# Historial: sesiones guardadas en esta PC; se deshacen completas o cambio por cambio (diseño, sección 8, paso 7).

function Format-AfSessionDate {
    param([string]$Text)
    try { $date = [datetimeoffset]::Parse($Text, [System.Globalization.CultureInfo]::InvariantCulture).LocalDateTime } catch { return [string]$Text }
    if ((Get-AfLanguage) -eq 'en') { return '{0}, {1}' -f $date.ToString('MMM d, yyyy', (Get-AfCulture)), (Format-AfTime -Date $date) }
    $month = (Get-AfCulture).DateTimeFormat.GetAbbreviatedMonthName($date.Month).TrimEnd('.')
    '{0} {1} {2}, {3}' -f $date.Day, $month, $date.Year, (Format-AfTime -Date $date)
}

function Get-AfSessionStateText {
    param([Parameter(Mandatory)]$Session)
    $summary = Get-AfSessionSummary -Session $Session
    if ($summary.Applied + $summary.Undone -eq 0) { (T 'Sin cambios') }
    elseif ($summary.Applied -eq 0) { (T 'Deshecha') }
    elseif ($summary.Undone -gt 0) { (T 'Deshecha en parte') }
    else { (T 'Aplicada') }
}

function Get-AfChangeStateText {
    param([Parameter(Mandatory)]$Change)
    switch ($Change.Status) {
        'Applied' { if (Test-AfChangeUndoable -Change $Change) { (T 'Aplicado') } else { (T 'Aplicado, no se puede deshacer') } }
        'Undone' { (T 'Deshecho') }
        'UndoFailed' { (T 'No se pudo deshacer') }
        'Reverted' { (T 'Volvió al valor anterior') }
        default { (T 'No se pudo aplicar') }
    }
}

function New-AfUndoButton {
    param([string]$Text, [string]$SessionPath, [string[]]$Ids = @())
    $button = New-Object System.Windows.Controls.Button
    $button.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'SmallButton')
    $button.Content = $Text
    $button.Tag = [pscustomobject]@{ SessionPath = $SessionPath; Ids = @($Ids) }
    $button.Add_Click({
            param($sender, $e)
            Start-AfUndo -Window ([System.Windows.Window]::GetWindow($sender)) -SessionPath $sender.Tag.SessionPath -ChangeIds $sender.Tag.Ids -FromHistory
        })
    $button
}

# El título guardado si la sesión es del idioma actual; si no, el de la revisión en el idioma actual.
function Get-AfChangeTitle {
    param([Parameter(Mandatory)]$Change, $Session)
    if (-not $Session) { return [string]$Change.Title }
    # Las sesiones de antes de los idiomas no guardan Language: son en español.
    $language = if ($Session.Language) { $Session.Language } else { 'es' }
    if ($language -eq (Get-AfLanguage)) { return [string]$Change.Title }
    $check = @(Get-AfCatalog | Where-Object { $_.Id -eq $Change.CheckId })[0]
    if ($check) { [string]$check.Title } else { [string]$Change.Title }
}

function New-AfHistorySession {
    param([Parameter(Mandatory)]$Session)
    $card = New-Object System.Windows.Controls.Border
    $card.CornerRadius = 14
    $card.BorderThickness = 1
    $card.Padding = '18,14,18,8'
    $card.Margin = '0,0,0,14'
    $card.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Panel')
    $card.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Line')
    $card.Tag = $Session.Path
    $stack = New-Object System.Windows.Controls.StackPanel
    $changes = @($Session.Changes)

    $header = New-Object System.Windows.Controls.DockPanel
    $header.Margin = '0,0,0,8'
    if (@($changes | Where-Object { Test-AfChangeUndoable -Change $_ }).Count) {
        $all = New-AfUndoButton -Text (T 'Deshacer todo') -SessionPath $Session.Path
        [System.Windows.Controls.DockPanel]::SetDock($all, 'Right')
        [void]$header.Children.Add($all)
    }
    $titles = New-Object System.Windows.Controls.StackPanel
    $date = New-AfText -Text (Format-AfSessionDate -Text $Session.StartedAt) -Size 14 -Brush 'Text' -Display -Weight 'Medium'
    [void]$titles.Children.Add($date)
    $count = if ($changes.Count -eq 1) { (T '1 cambio') } else { (T '{0} cambios') -f $changes.Count }
    $sub = New-AfText -Text ('{0} · {1}' -f $count, (Get-AfSessionStateText -Session $Session)) -Size 12 -Brush 'Text3'
    $sub.Margin = '0,2,0,0'
    [void]$titles.Children.Add($sub)
    [void]$header.Children.Add($titles)
    [void]$stack.Children.Add($header)

    foreach ($change in $changes) {
        $line = New-Object System.Windows.Controls.DockPanel
        $line.Margin = '0,6,0,6'
        $line.Tag = $change.CheckId
        if (Test-AfChangeUndoable -Change $change) {
            $action = New-AfUndoButton -Text (T 'Deshacer') -SessionPath $Session.Path -Ids @($change.CheckId)
            [System.Windows.Controls.DockPanel]::SetDock($action, 'Right')
            [void]$line.Children.Add($action)
        } else {
            $state = New-AfText -Text (Get-AfChangeStateText -Change $change) -Size 12 -Brush 'Text3'
            [System.Windows.Controls.DockPanel]::SetDock($state, 'Right')
            [void]$line.Children.Add($state)
        }
        $icon = switch ($change.Status) {
            'Applied' { New-AfIcon -Name 'check-circle' -Variant Fill -Size 15 -Brush 'Text' }
            'Undone' { New-AfIcon -Name 'arrow-counter-clockwise' -Size 15 }
            default { New-AfIcon -Name 'warning-circle' -Size 15 -Brush 'RedText' }
        }
        $icon.Margin = '0,0,12,0'
        [System.Windows.Controls.DockPanel]::SetDock($icon, 'Left')
        [void]$line.Children.Add($icon)
        $title = New-AfText -Text (Get-AfChangeTitle -Change $change -Session $Session) -Size 12.5 -Brush 'Text2'
        $title.TextTrimming = 'CharacterEllipsis'
        $title.TextWrapping = 'NoWrap'
        if ($change.Message) { $title.ToolTip = $change.Message }
        [void]$line.Children.Add($title)
        [void]$stack.Children.Add($line)
    }
    $card.Child = $stack
    $card
}

# Mientras deshace desde el Historial: la línea del cambio cambia su botón por un indicador y el paso en curso.
function Set-AfHistoryLineBusy {
    param([Parameter(Mandatory)]$Window, [string]$SessionPath, [string]$Id)
    $Window.Tag.HistoryStepText = $null
    $card = @($Window.FindName('HistoryList').Children | Where-Object { $_.Tag -eq $SessionPath })[0]
    if (-not $card) { return }
    $line = @($card.Child.Children | Where-Object { $_.Tag -eq $Id })[0]
    if (-not $line) { return }
    foreach ($button in @($line.Children | Where-Object { $_ -is [System.Windows.Controls.Button] })) { $line.Children.Remove($button) }
    $busy = New-Object System.Windows.Controls.StackPanel
    $busy.Orientation = 'Horizontal'
    [System.Windows.Controls.DockPanel]::SetDock($busy, 'Right')
    $spinner = New-AfSpinner -Size 13
    $spinner.Margin = '0,0,8,0'
    [void]$busy.Children.Add($spinner)
    $text = New-AfText -Text '' -Size 12 -Brush 'Text3'
    [void]$busy.Children.Add($text)
    $line.Children.Insert(0, $busy)
    $Window.Tag.HistoryStepText = $text
}

function Show-AfHistory {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    if ($s.Phase -ne 'history' -and $s.Phase -ne 'undoing') { $s.PhaseBeforeHistory = $s.Phase }
    $s.Phase = 'history'
    $Window.FindName('Title').Text = (T 'Historial')
    $Window.FindName('GaugeArea').Visibility = 'Collapsed'
    $Window.FindName('PanelBorder').Visibility = 'Collapsed'
    $Window.FindName('EmptyState').Visibility = 'Collapsed'
    $Window.FindName('HistoryPanel').Visibility = 'Visible'
    $Window.FindName('Summary').Inlines.Clear()
    $Window.FindName('Summary').Text = (T 'Cada sesión guarda los valores originales. Se puede deshacer completa o cambio por cambio.')
    $list = $Window.FindName('HistoryList')
    $list.IsHitTestVisible = $true
    $list.Children.Clear()
    $sessions = @(Get-AfSessions -Directory $s.BackupDirectory)
    if (-not $sessions.Count) {
        $empty = New-Object System.Windows.Controls.Border
        $empty.CornerRadius = 14
        $empty.BorderThickness = 1
        $empty.Padding = '22,20,22,16'
        $empty.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Panel')
        $empty.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Line')
        $empty.Child = New-AfStateCard -Icon 'clock-counter-clockwise' -Title (T 'Todavía no hay cambios en esta PC') -Text (T 'Cada vez que optimizas, Afina guarda aquí los valores originales para deshacerlos cuando quieras.')
        [void]$list.Children.Add($empty)
    }
    foreach ($session in $sessions) { [void]$list.Children.Add((New-AfHistorySession -Session $session)) }
    $Window.FindName('ListScroll').ScrollToTop()
    $Window.FindName('Actions').Opacity = 1
    $Window.FindName('Actions').IsHitTestVisible = $true
    Set-AfFooter -Window $Window -Note (T 'Los respaldos quedan en ProgramData\Afina\respaldos.') -NoteIcon 'clock-counter-clockwise' -Ghost (T 'Volver') -Motion ([bool]$s.Motion)
}

function Hide-AfHistory {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $Window.FindName('HistoryPanel').Visibility = 'Collapsed'
    $Window.FindName('GaugeArea').Visibility = 'Visible'
    if ($Window.FindName('Groups').Children.Count) { $Window.FindName('PanelBorder').Visibility = 'Visible' }
    if ($s.NeedsRescan -or -not $s.Results -or -not @($s.Results).Count) {
        $s.NeedsRescan = $false
        Start-AfScan -Window $Window
        return
    }
    if ($s.PhaseBeforeHistory -eq 'done') { Set-AfDoneView -Window $Window } else { Set-AfReadyView -Window $Window }
    Update-AfEmptyState -Window $Window
    # Lo que llegó mientras se veía el Historial se evalúa ahora.
    Update-AfVerdict -Window $Window -Celebrate
}
