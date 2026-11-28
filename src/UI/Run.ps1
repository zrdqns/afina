function Get-AfPartPhrase {
    param([string]$Part)
    switch ($Part) {
        'Memory' { (T 'Revisando las pantallas…') }
        { $_ -in 'Displays', 'Power' } { (T 'Revisando la energía…') }
        { $_ -in 'VendorTools', 'Network' } { (T 'Revisando la red…') }
        'Wlan' { (T 'Revisando la seguridad…') }
        { $_ -in 'Security', 'Apps', 'Startup' } { (T 'Revisando lo que arranca con Windows…') }
        'Autostart' { (T 'Revisando el almacenamiento…') }
        'Storage' { (T 'Revisando la configuración de Windows…') }
        'Registry' { (T 'Comparando con lo recomendado…') }
        default { (T 'Revisando el hardware…') }
    }
}

function Set-AfActionsVisible {
    param([Parameter(Mandatory)]$Window, [bool]$Visible, [bool]$Motion = $false)
    $actions = $Window.FindName('Actions')
    $actions.IsHitTestVisible = $Visible
    Start-AfAnimation -Target $actions -Property ([System.Windows.UIElement]::OpacityProperty) -To $(if ($Visible) { 1 } else { 0 }) -DurationMs 300 -Ease Out -Enabled $Motion | Out-Null
}

function Start-AfScan {
    param([Parameter(Mandatory)]$Window)
    $s = Get-AfUiState -Window $Window
    Stop-AfScanWorker -Worker $s.Worker
    $s.Phase = 'scanning'
    $s.ScanDone = $false
    $s.Applied = @{}
    $s.RebootPending = $false
    $s.NeedsRescan = $false
    $Window.FindName('HistoryPanel').Visibility = 'Collapsed'
    $Window.FindName('GaugeArea').Visibility = 'Visible'
    $Window.FindName('Groups').IsHitTestVisible = $true
    $Window.FindName('PrimaryProgressScale').BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $null)
    $Window.FindName('PrimaryProgressScale').ScaleX = 0
    $s.Pending = New-Object System.Collections.Queue
    $s.AsyncHold = New-Object System.Collections.Queue
    $s.LastReveal = [datetime]::MinValue
    $s.Results = New-Object System.Collections.ArrayList
    $s.Filter = 'all'
    $s.StartedAt = Get-Date
    $s.Celebrated = $false
    $s.Revealed = 0
    $s.PartPhrase = $null
    Set-AfNavActive -Window $Window -Filter 'home' -Motion $false
    Set-AfView -Window $Window -View 'home'
    $Window.FindName('Groups').Children.Clear()
    $Window.FindName('PanelBorder').Visibility = 'Collapsed'
    Show-AfSkeleton -Window $Window
    $Window.FindName('Title').Text = (T 'Analizando esta PC')
    Set-AfTextAnimated -Block $Window.FindName('Summary') -Text (T 'Revisando el hardware…') -Motion $s.Motion
    Set-AfActionsVisible -Window $Window -Visible $false
    Set-AfNavSpinners -Window $Window
    $s.TicksHidden = $true
    Update-AfGaugeLayout -Window $Window
    foreach ($tick in $Window.FindName('Ticks').Children) { $tick.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null); $tick.Opacity = 0 }
    Show-AfTicks -Window $Window -Motion $s.Motion
    $needle = $Window.FindName('Needle')
    $needle.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
    $needle.Opacity = 1
    Start-AfNeedleSweep -Window $Window -Motion $s.Motion
    # Tras el autotest, la aguja queda atenuada mientras se analiza.
    Start-AfAnimation -Target $needle -Property ([System.Windows.UIElement]::OpacityProperty) -To 0.4 -DurationMs 300 -DelayMs $(if ($s.Motion) { 1500 } else { 0 }) -Ease Out -Enabled $true | Out-Null
    $s.Queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    $s.Worker = Start-AfScanWorker -Code $Global:AfCode -Queue $s.Queue -Language (Get-AfLanguage)
    Update-AfFooterVisibility -Window $Window
    Update-AfHome -Window $Window
}

function Update-AfAsyncResult {
    param([Parameter(Mandatory)]$Window, [string]$Id, $Detection)
    foreach ($group in $Window.FindName('Groups').Children) {
        for ($i = 0; $i -lt $group.Children.Count; $i++) {
            $row = $group.Children[$i]
            if ($row -isnot [System.Windows.Controls.Border] -or -not $row.Tag -or -not $row.Tag.Check -or $row.Tag.Check.Id -ne $Id) { continue }
            $old = $row.Tag
            $result = [pscustomobject]@{ Check = $old.Check; Detection = $Detection; Weight = $old.Weight; Preselected = $false }
            $index = $Window.Tag.Results.IndexOf($old)
            if ($index -ge 0) { $Window.Tag.Results[$index] = $result }
            if ($Detection.State -notin 'Improvable', 'Manual', 'Info', 'Error' -and -not ($Detection.State -eq 'Ok' -and $old.Check.Reading)) {
                $group.Children.RemoveAt($i)
                # Un grupo sin filas no queda como un encabezado suelto.
                if (-not @($group.Children | Where-Object { $_ -is [System.Windows.Controls.Border] -and $_.Tag }).Count) { $Window.FindName('Groups').Children.Remove($group) }
            } else {
                $newRow = New-AfRowElement -Result $result -First:($row.FindName('Divider').Visibility -ne 'Visible')
                Add-AfRowHandlers -Row $newRow
                $group.Children.RemoveAt($i)
                $group.Children.Insert($i, $newRow)
                Start-AfAnimation -Target $newRow -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Out -Enabled ([bool]$Window.Tag.Motion) | Out-Null
            }
            Update-AfNavCounts -Window $Window -Results @($Window.Tag.Results) -Only @($old.Check.Category)
            Update-AfPrimary -Window $Window
            Update-AfEmptyState -Window $Window
            # Una lectura tardía puede cambiar el veredicto, pero no mientras se aplica.
            if ($Window.Tag.Phase -in 'ready', 'done') { Update-AfVerdict -Window $Window -Celebrate }
            return
        }
    }
}

function Complete-AfScan {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $s.Phase = 'ready'
    Update-AfFooterVisibility -Window $Window
    $results = @($s.Results)
    $groups = $Window.FindName('Groups')
    foreach ($ghost in @($groups.Children | Where-Object { "$($_.Tag)" -like 'skeleton*' })) { $groups.Children.Remove($ghost) }
    $Window.FindName('PcSkeleton').Visibility = 'Collapsed'
    Add-AfOkGroup -Window $Window -Results $results -Motion $s.Motion
    Update-AfNavCounts -Window $Window -Results $results -Only @('ok') -Motion $s.Motion
    $summary = Get-AfSummary -Results $results
    $score = Get-AfScore -Results $results
    Update-AfVerdict -Window $Window -Motion $s.Motion
    Set-AfSummary -Window $Window -Summary $summary -Motion $s.Motion
    $needle = $Window.FindName('Needle')
    Start-AfAnimation -Target $needle -Property ([System.Windows.UIElement]::OpacityProperty) -To 1 -DurationMs 200 -Ease Out -Enabled $s.Motion | Out-Null
    Set-AfNeedle -Window $Window -Fraction $score -Motion $s.Motion -DurationMs 700 -Ease Out
    Update-AfVerdict -Window $Window -Celebrate
    Set-AfFooter -Window $Window -Note (Get-AfReadyNote) -NoteIcon 'shield-check' -Ghost (T 'Volver a analizar') -GhostIcon 'arrow-clockwise' -PrimaryOptimize
    Set-AfActionsVisible -Window $Window -Visible $true -Motion $s.Motion
    Update-AfEmptyState -Window $Window
    Write-AfLog -Level Info -Message ('Análisis terminado en {0:N1} s: {1} listos, {2} a mano, {3} en orden.' -f ((Get-Date) - $s.StartedAt).TotalSeconds, $summary.Ready, $summary.Manual, $summary.Ok)
    if ($s.Snapshot) {
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(1200)
        $timer.Tag = $Window
        $timer.Add_Tick({ param($sender, $e) $sender.Stop(); $w = $sender.Tag; Save-AfWindowSnapshot -Window $w -Path $w.Tag.Snapshot; $w.Close() })
        $timer.Start()
    }
}

function Receive-AfEvents {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $item = $null
    if ($s.ApplyQueue) {
        # Cada evento se deja ver un momento (Set-AfApplyHold); con seis o más en cola, la ventana se pone al día de golpe.
        $catchUp = $s.ApplyQueue.Count -ge 6
        while (($catchUp -or -not $s.ApplyHoldUntil -or (Get-Date) -ge $s.ApplyHoldUntil) -and $s.ApplyQueue.TryDequeue([ref]$item)) { Receive-AfApplyEvent -Window $Window -Item $item }
    }
    if (-not $s.Queue) { return }
    while ($s.Queue.TryDequeue([ref]$item)) {
        switch ($item.Type) {
            'Part' {
                if ($s.Phase -eq 'scanning') {
                    $s.PartPhrase = Get-AfPartPhrase -Part $item.Part
                    $Window.FindName('Summary').Text = $s.PartPhrase
                    Update-AfHome -Window $Window
                }
            }
            'Inventory' { $s.Inventory = $item.Inventory; Set-AfPcCard -Window $Window -Inventory $item.Inventory -Animate $s.Motion; Update-AfLiveTiles -Window $Window }
            'Category' { $s.Pending.Enqueue($item) }
            'Done' { $s.ScanDone = $true }
            'Async' {
                # Un resultado que llega antes de revelar las categorías espera: su fila aún no existe.
                if ($s.Pending.Count -gt 0) {
                    if (-not $s.AsyncHold) { $s.AsyncHold = New-Object System.Collections.Queue }
                    $s.AsyncHold.Enqueue($item)
                } else { Update-AfAsyncResult -Window $Window -Id $item.Id -Detection $item.Detection }
            }
            'Error' {
                $s.ScanDone = $true
                Write-AfLog -Level Error -Message "El análisis falló: $($item.Message)"
                $Window.FindName('Summary').Text = (T 'El análisis no pudo terminar. Revisa el registro en ProgramData\Afina.')
            }
        }
    }
    $revealed = $false
    if ($s.Pending.Count -gt 0) {
        $gap = if ($s.Motion) { 260 } else { 0 }
        if (((Get-Date) - $s.LastReveal).TotalMilliseconds -ge $gap) {
            $next = $s.Pending.Dequeue()
            foreach ($result in $next.Results) { [void]$s.Results.Add($result) }
            $category = Get-AfCategories | Where-Object Id -eq $next.Category
            Add-AfCategoryGroup -Window $Window -Category $category -Results $next.Results -Motion $s.Motion
            Update-AfNavCounts -Window $Window -Results @($s.Results) -Only @($next.Category) -Motion $s.Motion
            $s.Revealed = [int]$s.Revealed + 1
            Update-AfHome -Window $Window
            $s.LastReveal = Get-Date
            $revealed = $true
        }
    }
    if ($s.Pending.Count -eq 0) {
        while ($s.AsyncHold -and $s.AsyncHold.Count -gt 0) {
            $held = $s.AsyncHold.Dequeue()
            Update-AfAsyncResult -Window $Window -Id $held.Id -Detection $held.Detection
        }
        if ($s.ScanDone -and $s.Phase -eq 'scanning' -and -not $revealed) { Complete-AfScan -Window $Window }
    }
}

function Initialize-AfPrefs {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $map = @{ ThemeSystem = 'System'; ThemeBlack = 'Black'; ThemeWhite = 'White'; MotionAuto = 'Auto'; MotionAlways = 'Always'; MotionNever = 'Never'; LangAuto = 'Auto'; LangEs = 'es'; LangEn = 'en' }
    # Un idioma guardado que no se conoce cuenta como Automático.
    $language = if ($s.Config.Language -in 'es', 'en') { $s.Config.Language } else { 'Auto' }
    foreach ($name in $map.Keys) {
        $radio = $Window.FindName($name)
        $radio.IsChecked = switch -Wildcard ($name) {
            'Theme*' { $s.Config.Theme -eq $map[$name] }
            'Motion*' { $s.Config.Motion -eq $map[$name] }
            default { $language -eq $map[$name] }
        }
        $radio.Tag = $map[$name]
        $radio.Add_Checked({
                param($sender, $e)
                $w = [System.Windows.Window]::GetWindow($sender)
                $state = $w.Tag
                if ($sender.GroupName -eq 'Theme') {
                    $state.Config.Theme = $sender.Tag
                    Set-AfTheme -Window $w -Theme (Resolve-AfTheme -Setting $sender.Tag -User $state.User)
                } elseif ($sender.GroupName -eq 'Motion') {
                    $state.Config.Motion = $sender.Tag
                    $state.Motion = Test-AfMotionEnabled -Setting $sender.Tag
                } else {
                    $state.Config.Language = $sender.Tag
                    $chosen = Resolve-AfLanguage -Setting $sender.Tag
                    # Todo se vuelve a armar en el idioma nuevo: los textos fijos ahora y los resultados con un análisis nuevo.
                    if ($chosen -ne (Get-AfLanguage)) {
                        Set-AfLanguage -Language $chosen
                        Set-AfStaticTexts -Window $w
                        if ($state.Nav) { foreach ($entry in Get-AfNavEntries) { if ($state.Nav[$entry.Id]) { $state.Nav[$entry.Id].Label.Text = $entry.Name } } }
                        # Las tarjetas del Resumen se arman en código: se rehacen en el idioma nuevo.
                        Initialize-AfHome -Window $w
                        if ($state.Phase -in 'ready', 'done', 'history') { Start-AfScan -Window $w }
                    }
                }
                if ($state.ConfigPath) { try { Set-AfConfig -Path $state.ConfigPath -Config $state.Config } catch { Write-AfLog -Level Warn -Message "No se pudo guardar la configuración: $($_.Exception.Message)" } }
            })
    }
}

# Mientras analiza, confirma, aplica o deshace no se cambia de idioma: lo que está en pantalla tiene que seguir siendo de ese proceso.
function Update-AfLanguageAvailability {
    param([Parameter(Mandatory)]$Window)
    $busy = $Window.Tag.Phase -in 'scanning', 'confirm', 'applying', 'display', 'restore', 'undoing'
    foreach ($name in 'LangAuto', 'LangEs', 'LangEn') {
        $radio = $Window.FindName($name)
        $radio.IsEnabled = -not $busy
        [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($radio, $true)
        $radio.ToolTip = if ($busy) { T 'Disponible al terminar' } else { $null }
    }
}

function Test-AfBusyPhase {
    param([string]$Phase)
    $Phase -in 'applying', 'display', 'restore', 'undoing'
}

function Invoke-AfPrimaryAction {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    switch ($s.Phase) {
        'ready' { Enter-AfConfirm -Window $Window }
        'confirm' { Start-AfApply -Window $Window }
        'display' { $s.Shared.DisplayAnswer = 'keep'; $s.Phase = 'applying'; Stop-AfDisplayCountdown -Window $Window; Set-AfApplyingFooter -Window $Window }
        'restore' { $s.Shared.ContinueWithoutRestore = $true; $s.Phase = 'applying'; $s.ApplyNote = (T 'Sin punto de restauración; los valores originales se guardan en Afina.'); Set-AfApplyingFooter -Window $Window }
        'done' {
            if (-not $s.RebootPending) { Start-AfScan -Window $Window }
            elseif ($s.DemoCode) { Set-AfNote -Window $Window -Text (T 'En la demostración no se reinicia la PC.') -Icon 'info' -Motion $s.Motion }
            else { Restart-AfComputer }
        }
    }
}

function Invoke-AfGhostAction {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    switch ($s.Phase) {
        'ready' { Start-AfScan -Window $Window }
        'confirm' { Exit-AfConfirm -Window $Window }
        'display' { $s.Shared.DisplayAnswer = 'revert'; $s.Phase = 'applying'; Stop-AfDisplayCountdown -Window $Window; Set-AfApplyingFooter -Window $Window }
        'restore' { $s.Shared.ContinueWithoutRestore = $false; $s.Phase = 'applying'; Set-AfApplyingFooter -Window $Window }
        'done' { $s.RebootPending = $false; Set-AfDoneView -Window $Window }
        'history' { Hide-AfHistory -Window $Window }
    }
}

function Show-AfApp {
    # OnShown es para automatizar (tools\Show-AfDemo.ps1 -AutoPlay): recibe la ventana, que abre fuera de la pantalla.
    param([hashtable]$Config = (Get-AfConfigDefaults), [string]$ConfigPath, [string]$Snapshot, [string]$BackupDirectory = (Get-AfBackupDirectory), [string]$DemoCode, [scriptblock]$OnShown)
    $user = Get-AfInteractiveUser
    Set-AfStartLanguage -Config $Config
    $window = New-AfWindow -Theme (Resolve-AfTheme -Setting $Config.Theme -User $user)
    $s = Get-AfUiState -Window $window
    $s.Motion = Test-AfMotionEnabled -Setting $Config.Motion
    # La pantalla de entrada no va en la captura automática (-Snapshot).
    if ($Snapshot) { $window.FindName('Splash').Visibility = 'Collapsed'; $s.SplashGone = $true } else { Initialize-AfSplash -Window $window -Motion $s.Motion }
    if ($s.Motion) {
        $pulse = New-Object System.Windows.Media.Animation.DoubleAnimation(1, 0.3, (New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(1100))))
        $pulse.AutoReverse = $true
        $pulse.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $window.FindName('LiveDot').BeginAnimation([System.Windows.UIElement]::OpacityProperty, $pulse)
    }
    $s.Config = $Config
    $s.ConfigPath = $ConfigPath
    $s.Snapshot = $Snapshot
    $s.User = $user
    $s.BackupDirectory = $BackupDirectory
    $s.DemoCode = $DemoCode
    if ($DemoCode) { $window.FindName('Version').Text += '  ·  ' + (T 'Demostración') }

    $area = [System.Windows.SystemParameters]::WorkArea
    if ($area.Width -lt $window.Width) { $window.Width = [math]::Max($window.MinWidth, $area.Width) }
    if ($area.Height -lt $window.Height) { $window.Height = [math]::Max($window.MinHeight, $area.Height) }
    $s.OnShown = $OnShown
    if ($Snapshot -or $OnShown) {
        $window.WindowStartupLocation = 'Manual'
        $window.Left = -20000
        $window.Top = -20000
        $window.ShowActivated = $false
    }

    $window.FindName('MinButton').Add_Click({ param($sender, $e) [System.Windows.Window]::GetWindow($sender).WindowState = 'Minimized' })
    $window.FindName('MaxButton').Add_Click({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            $w.WindowState = if ($w.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' }
        })
    $window.Add_StateChanged({ param($sender, $e) $sender.FindName('MaxButton').Content = if ($sender.WindowState -eq 'Maximized') { [string][char]0xE923 } else { [string][char]0xE922 } })
    $window.FindName('CloseButton').Add_Click({ param($sender, $e) [System.Windows.Window]::GetWindow($sender).Close() })
    $prefs = $window.FindName('Prefs')
    $prefs.PlacementTarget = $window.FindName('PrefsButton')
    $window.FindName('PrefsButton').Add_Click({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            Update-AfLanguageAvailability -Window $w
            $w.FindName('Prefs').IsOpen = $true
        })
    Initialize-AfPrefs -Window $window
    $window.FindName('GhostButton').Add_Click({ param($sender, $e) Invoke-AfGhostAction -Window ([System.Windows.Window]::GetWindow($sender)) })
    $window.FindName('PrimaryButton').Add_Click({ param($sender, $e) Invoke-AfPrimaryAction -Window ([System.Windows.Window]::GetWindow($sender)) })
    $window.FindName('ExtraButton').Add_Click({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            if ($w.Tag.Phase -eq 'done' -and $w.Tag.SessionPath) { Start-AfUndo -Window $w -SessionPath $w.Tag.SessionPath }
        })
    $window.FindName('HistoryButton').Add_Click({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            if ($w.Tag.Phase -in 'ready', 'done') { Show-AfHistory -Window $w }
        })
    $window.FindName('RestoreOption').Add_Click({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            if ($w.Tag.Phase -eq 'confirm') { Set-AfNote -Window $w -Text (Get-AfConfirmNote -Window $w) -Motion ([bool]$w.Tag.Motion) }
        })
    $window.FindName('RestoreLabel').Add_MouseLeftButtonUp({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            $option = $w.FindName('RestoreOption')
            $option.IsChecked = -not $option.IsChecked
            if ($w.Tag.Phase -eq 'confirm') { Set-AfNote -Window $w -Text (Get-AfConfirmNote -Window $w) -Motion ([bool]$w.Tag.Motion) }
        })
    # Nunca se cierra con cambios a medio aplicar o deshacer.
    $window.Add_Closing({ param($sender, $e)
            if (Test-AfBusyPhase -Phase $sender.Tag.Phase) {
                $e.Cancel = $true
                Set-AfNote -Window $sender -Text (T 'Espera a que termine: hay cambios a medio aplicar.') -Icon 'warning-circle'
            }
        })

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(50)
    $timer.Tag = $window
    $timer.Add_Tick({ param($sender, $e) Receive-AfEvents -Window $sender.Tag; Receive-AfLiveSample -Window $sender.Tag })
    $s.Timer = $timer
    $s.LiveSync = [hashtable]::Synchronized(@{ Stop = $false; Seq = 0; Sample = $null; Failed = $null })
    $s.LiveWorker = Start-AfLiveWorker -Sync $s.LiveSync
    $window.Add_ContentRendered({ param($sender, $e)
            # Primero arranca el análisis (abre su runspace en este hilo) y después la entrada, para que su animación no se trabe.
            Start-AfScan -Window $sender
            Start-AfSplash -Window $sender
            if ($sender.Tag.OnShown) { & $sender.Tag.OnShown $sender }
        })
    $window.Add_Closed({ param($sender, $e) $sender.Tag.Timer.Stop(); Stop-AfScanWorker -Worker $sender.Tag.Worker; Stop-AfLiveWorker -Worker $sender.Tag.LiveWorker })
    $timer.Start()
    [void]$window.ShowDialog()
}
