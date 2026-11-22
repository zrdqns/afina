function Format-AfCpuName {
    param([string]$Name)
    $n = $Name -replace '\((R|TM)\)', '' -replace '\s+with\s+Radeon.*$', '' -replace '\s+(CPU|Processor)\b.*$', '' -replace '\s+@.*$', ''
    $n = $n -replace '^\d+th Gen\s+', '' -replace '^Intel\s+', '' -replace '^AMD\s+', '' -replace '\s{2,}', ' '
    $n.Trim()
}

function Format-AfGpuName {
    param([string]$Name)
    ($Name -replace '^NVIDIA\s+(GeForce\s+)?', '' -replace '^AMD\s+', '' -replace '^Intel\(R\)\s+', '' -replace '\s+GPU$', '').Trim()
}

function Format-AfPcName {
    param($Device)
    $maker = switch -Regex ([string]$Device.Manufacturer) {
        '^LENOVO' { 'Lenovo'; break }
        '^ASUSTeK|^ASUS' { 'ASUS'; break }
        '^Hewlett|^HP' { 'HP'; break }
        '^Dell' { 'Dell'; break }
        '^Acer' { 'Acer'; break }
        '^Micro-Star|^MSI' { 'MSI'; break }
        '^(System manufacturer|To be filled|Default string)' { ''; break }
        default { [string]$Device.Manufacturer }
    }
    $model = ([string]$Device.Model -replace '_.*$', '' -replace '^(ASUS|Lenovo|HP|Dell|Acer|MSI)\s+', '').Trim()
    if ($model -match '^(System Product Name|To be filled|Default string)$') { $model = '' }
    $name = ('{0} {1}' -f $maker, $model).Trim()
    if ($name) { $name } else { (T 'Esta PC') }
}

function Get-AfUiState {
    param([Parameter(Mandatory)]$Window)
    if ($Window.Tag -isnot [hashtable]) { $Window.Tag = @{} }
    $s = $Window.Tag
    foreach ($key in 'Motion', 'Filter', 'NeedleF', 'Results') {
        if (-not $s.ContainsKey($key)) {
            $s[$key] = switch ($key) { 'Motion' { $false } 'Filter' { 'all' } 'NeedleF' { 0.0 } 'Results' { New-Object System.Collections.ArrayList } }
        }
    }
    if (-not $s.Initialized) {
        $s.Initialized = $true
        New-AfNav -Window $Window
        $Window.FindName('Gauge').Add_SizeChanged({ param($sender, $e) Update-AfGaugeLayout -Window ([System.Windows.Window]::GetWindow($sender)) })
        Update-AfGaugeLayout -Window $Window
    }
    $s
}

function New-AfSpecRow {
    param([string]$Icon, [string]$Text)
    $row = New-Object System.Windows.Controls.StackPanel
    $row.Orientation = 'Horizontal'
    $row.Margin = '0,0,0,9'
    [void]$row.Children.Add((New-AfIcon -Name $Icon -Size 15))
    $label = New-AfText -Text $Text -Size 12.5 -Brush 'Text2'
    $label.Margin = '9,0,0,0'
    $label.TextWrapping = 'NoWrap'
    $label.TextTrimming = 'CharacterEllipsis'
    $label.MaxWidth = 180
    [void]$row.Children.Add($label)
    $row
}

function Set-AfPcCard {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)]$Inventory, [bool]$Animate = $false)
    $inv = $Inventory
    $Window.FindName('PcName').Text = Format-AfPcName -Device $inv.Device
    $discrete = @($inv.Gpus | Where-Object IsDiscrete)[0]
    $kind = if ($inv.Device.IsLaptop) { (T 'Laptop') } else { (T 'Escritorio') }
    if ($discrete) { $kind += ' gamer' }
    $Window.FindName('PcKind').Text = $kind
    $specs = $Window.FindName('Specs')
    $specs.Children.Clear()
    if ($inv.Cpu) { [void]$specs.Children.Add((New-AfSpecRow -Icon 'cpu' -Text (Format-AfCpuName -Name $inv.Cpu.Name))) }
    $gpu = if ($discrete) { $discrete } else { @($inv.Gpus)[0] }
    if ($gpu) {
        $gpuText = if ($gpu.HasDriver -eq $false) { if ($gpu.Vendor -in 'NVIDIA', 'AMD', 'Intel') { (T '{0}, sin driver') -f $gpu.Vendor } else { (T 'Gráfica sin driver') } } else { Format-AfGpuName -Name $gpu.Name }
        [void]$specs.Children.Add((New-AfSpecRow -Icon 'graphics-card' -Text $gpuText))
    }
    if ($inv.Memory) {
        $channel = if ($inv.Memory.Socketed -and @($inv.Memory.Modules).Count -eq 1) { (T ', un canal') } elseif ($inv.Memory.Socketed -and @($inv.Memory.Modules).Count -ge 2) { ', doble canal' } else { '' }
        [void]$specs.Children.Add((New-AfSpecRow -Icon 'memory' -Text ('{0} GB{1}' -f $inv.Memory.TotalGB, $channel)))
    }
    if ($inv.Storage) {
        $media = if ($inv.Storage.MediaType -eq 'HDD') { (T 'Disco') } else { 'SSD' }
        [void]$specs.Children.Add((New-AfSpecRow -Icon 'hard-drives' -Text ((T '{0} {1} GB, {2} GB libres') -f $media, $inv.Storage.SizeGB, $inv.Storage.FreeGB)))
    }
    if ($inv.Os) { [void]$specs.Children.Add((New-AfSpecRow -Icon 'windows-logo' -Text (([string]$inv.Os.Caption -replace '^Microsoft\s+', '')))) }
    if ($inv.Device.IsLaptop) { [void]$specs.Children.Add((New-AfSpecRow -Icon 'plug-charging' -Text $(if ($inv.Device.OnBattery) { (T 'En batería') } else { (T 'Con cargador') }))) }
    $card = $Window.FindName('PcCard')
    Start-AfAnimation -Target $card -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Out -Enabled $Animate | Out-Null
}

function Get-AfNavEntries {
    @([pscustomobject]@{ Id = 'all'; Name = (T 'Todo'); Icon = 'squares-four' }) + @(Get-AfCategories) + @([pscustomobject]@{ Id = 'ok'; Name = (T 'En orden'); Icon = 'check-circle' })
}

function New-AfNav {
    param([Parameter(Mandatory)]$Window)
    $nav = $Window.FindName('Nav')
    $nav.Children.Clear()
    $refs = @{}
    foreach ($entry in Get-AfNavEntries) {
        $button = New-Object System.Windows.Controls.Button
        $button.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'NavButton')
        $button.Tag = $entry.Id
        $grid = New-Object System.Windows.Controls.Grid
        foreach ($width in 'Auto', '*', 'Auto') {
            $column = New-Object System.Windows.Controls.ColumnDefinition
            $column.Width = if ($width -eq '*') { New-Object System.Windows.GridLength(1, 'Star') } else { [System.Windows.GridLength]::Auto }
            [void]$grid.ColumnDefinitions.Add($column)
        }
        $iconHost = New-Object System.Windows.Controls.Grid
        $iconOff = New-AfIcon -Name $entry.Icon -Size 16 -Brush 'Text2'
        $iconOn = New-AfIcon -Name $entry.Icon -Variant Fill -Size 16 -Brush 'Text'
        $iconOn.Visibility = 'Collapsed'
        [void]$iconHost.Children.Add($iconOff)
        [void]$iconHost.Children.Add($iconOn)
        $label = New-AfText -Text $entry.Name -Size 13 -Brush 'Text2'
        $label.Margin = '10,0,0,0'
        $label.TextWrapping = 'NoWrap'
        [System.Windows.Controls.Grid]::SetColumn($label, 1)
        $countHost = New-Object System.Windows.Controls.Grid
        $countHost.MinWidth = 18
        $countHost.HorizontalAlignment = 'Right'
        [System.Windows.Controls.Grid]::SetColumn($countHost, 2)
        [void]$grid.Children.Add($iconHost)
        [void]$grid.Children.Add($label)
        [void]$grid.Children.Add($countHost)
        $button.Content = $grid
        $button.Add_Click({ param($sender, $e) Set-AfFilter -Window ([System.Windows.Window]::GetWindow($sender)) -Filter $sender.Tag })
        [void]$nav.Children.Add($button)
        $refs[$entry.Id] = @{ Button = $button; IconOff = $iconOff; IconOn = $iconOn; Label = $label; CountHost = $countHost; Count = 0 }
    }
    $Window.Tag.Nav = $refs
    Set-AfNavActive -Window $Window -Filter 'all' -Motion $false
}

function Set-AfNavSpinners {
    param([Parameter(Mandatory)]$Window)
    foreach ($id in $Window.Tag.Nav.Keys) {
        if ($id -eq 'all') { continue }
        $hostGrid = $Window.Tag.Nav[$id].CountHost
        $hostGrid.Children.Clear()
        [void]$hostGrid.Children.Add((New-AfSpinner -Size 12))
    }
}

function Get-AfPendingCount {
    param([string]$Category, [object[]]$Results = @())
    if ($Category -eq 'ok') { return @($Results | Where-Object { $_.Detection.State -eq 'Ok' }).Count }
    @($Results | Where-Object { $_.Check.Category -eq $Category -and ($_.Detection.State -eq 'Manual' -or ($_.Detection.State -eq 'Improvable' -and $_.Check.Kind -eq 'Auto')) }).Count
}

function Set-AfNavCount {
    param([Parameter(Mandatory)]$Window, [string]$Category, [int]$Count, [bool]$Motion = $false)
    $ref = $Window.Tag.Nav[$Category]
    if (-not $ref) { return }
    $ref.Count = $Count
    $hostGrid = $ref.CountHost
    $hostGrid.Children.Clear()
    if ($Count -gt 0 -or $Category -eq 'ok') {
        $text = New-AfText -Text ([string]$Count) -Size 12 -Brush $(if ($Category -eq 'ok') { 'Text3' } else { 'Text' }) -Display -Weight 'Medium'
        $text.HorizontalAlignment = 'Right'
        $element = $text
    } else {
        $element = New-AfIcon -Name 'check' -Size 13
        $element.HorizontalAlignment = 'Right'
    }
    [void]$hostGrid.Children.Add($element)
    Start-AfAnimation -Target $element -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Icon -Enabled $Motion | Out-Null
}

function Get-AfNavCount {
    param([Parameter(Mandatory)]$Window, [string]$Category)
    $Window.Tag.Nav[$Category].Count
}

function Update-AfNavCounts {
    param([Parameter(Mandatory)]$Window, [object[]]$Results = @(), [string[]]$Only, [bool]$Motion = $false)
    foreach ($entry in Get-AfNavEntries) {
        if ($entry.Id -eq 'all') { continue }
        if ($Only -and $entry.Id -notin $Only) { continue }
        Set-AfNavCount -Window $Window -Category $entry.Id -Count (Get-AfPendingCount -Category $entry.Id -Results $Results) -Motion $Motion
    }
}

function Set-AfNavActive {
    param([Parameter(Mandatory)]$Window, [string]$Filter, [bool]$Motion = $false)
    foreach ($id in $Window.Tag.Nav.Keys) {
        $ref = $Window.Tag.Nav[$id]
        $on = $id -eq $Filter
        if ($on) { $ref.Button.SetResourceReference([System.Windows.Controls.Control]::BackgroundProperty, 'Line') } else { $ref.Button.Background = [System.Windows.Media.Brushes]::Transparent }
        $ref.IconOn.Visibility = if ($on) { 'Visible' } else { 'Collapsed' }
        $ref.IconOff.Visibility = if ($on) { 'Collapsed' } else { 'Visible' }
        $ref.Label.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, $(if ($on) { 'Text' } else { 'Text2' }))
    }
    $index = @(Get-AfNavEntries).Id.IndexOf($Filter)
    $y = [math]::Max(0, $index) * 34
    Start-AfAnimation -Target $Window.FindName('NavIndicatorTransform') -Property ([System.Windows.Media.TranslateTransform]::YProperty) -To $y -DurationMs 200 -Ease InOut -Enabled $Motion | Out-Null
}

function Set-AfFilter {
    param([Parameter(Mandatory)]$Window, [string]$Filter)
    $state = $Window.Tag
    # Desde el Historial, elegir una categoría vuelve a la lista; mientras deshace, se queda.
    if ($Window.FindName('HistoryPanel').Visibility -eq 'Visible') {
        if (Test-AfBusyPhase -Phase $state.Phase) { return }
        Hide-AfHistory -Window $Window
    }
    $state.Filter = $Filter
    Set-AfNavActive -Window $Window -Filter $Filter -Motion $state.Motion
    foreach ($group in $Window.FindName('Groups').Children) {
        $show = $Filter -eq 'all' -or $group.Tag -eq $Filter
        $group.Visibility = if ($show) { 'Visible' } else { 'Collapsed' }
        if ($group.Tag -eq 'ok' -and $Filter -eq 'ok') { Set-AfOkGroupOpen -Group $group -Open $true -Motion $false }
    }
    $Window.FindName('ListScroll').ScrollToTop()
}

function Update-AfGaugeLayout {
    param([Parameter(Mandatory)]$Window)
    $gauge = $Window.FindName('Gauge')
    $width = $gauge.ActualWidth
    if ($width -le 0) { return }
    foreach ($canvasName in 'Ticks', 'LitTicks') {
        $canvas = $Window.FindName($canvasName)
        if ($canvas.Children.Count -ne 61) {
            $canvas.Children.Clear()
            for ($i = 0; $i -le 60; $i++) {
                $tick = New-Object System.Windows.Shapes.Rectangle
                $tick.Width = if ($i -eq 60) { 2 } else { 1 }
                $tick.Height = if ($i -eq 60) { 20 } elseif ($i % 10 -eq 0) { 13 } else { 7 }
                $tick.RadiusX = 0.5
                $tick.RadiusY = 0.5
                $brush = if ($canvasName -eq 'LitTicks' -or $i -eq 60) { 'Red' } elseif ($i % 10 -eq 0) { 'TickMajor' } else { 'Tick' }
                $tick.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $brush)
                if ($canvasName -eq 'LitTicks') { $tick.Opacity = 0 } elseif (-not $Window.Tag.TicksHidden) { $tick.Opacity = 1 } else { $tick.Opacity = 0 }
                [System.Windows.Controls.Canvas]::SetBottom($tick, 0)
                [void]$canvas.Children.Add($tick)
            }
        }
        for ($i = 0; $i -le 60; $i++) {
            $x = if ($i -eq 60) { $width - 2 } else { [math]::Round($i * ($width - 2) / 60) }
            [System.Windows.Controls.Canvas]::SetLeft($canvas.Children[$i], $x)
        }
    }
    $needle = $Window.FindName('NeedleTransform')
    $needle.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $null)
    $needle.X = $Window.Tag.NeedleF * ($width - 2)
}

function Show-AfTicks {
    param([Parameter(Mandatory)]$Window, [bool]$Motion = $false)
    $Window.Tag.TicksHidden = $false
    $i = 0
    foreach ($tick in $Window.FindName('Ticks').Children) {
        Start-AfAnimation -Target $tick -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 220 -DelayMs (120 + $i * 9) -Ease Linear -Enabled $Motion | Out-Null
        $i++
    }
}

function Set-AfNeedle {
    param([Parameter(Mandatory)]$Window, [double]$Fraction, [bool]$Motion = $false, [int]$DurationMs = 700, [string]$Ease = 'Out')
    $Window.Tag.NeedleF = $Fraction
    $width = $Window.FindName('Gauge').ActualWidth - 2
    Start-AfAnimation -Target $Window.FindName('NeedleTransform') -Property ([System.Windows.Media.TranslateTransform]::XProperty) -To ([math]::Max(0, $Fraction * $width)) -DurationMs $DurationMs -Ease $Ease -Enabled $Motion | Out-Null
}

# Autotest del arranque: la aguja recorre la escala hasta "Afinado" y vuelve.
function Start-AfNeedleSweep {
    param([Parameter(Mandatory)]$Window, [bool]$Motion = $false)
    $Window.Tag.NeedleF = 0
    $transform = $Window.FindName('NeedleTransform')
    if (-not $Motion) { $transform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $null); $transform.X = 0; return }
    $width = $Window.FindName('Gauge').ActualWidth - 2
    $animation = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
    $animation.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(1500))
    [void]$animation.KeyFrames.Add((New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame($width, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(780)), (New-AfKeySpline -Ease InOut))))
    [void]$animation.KeyFrames.Add((New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame(0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(1500)), (New-AfKeySpline -Ease InOut))))
    $transform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $animation)
}

function Start-AfCelebration {
    param([Parameter(Mandatory)]$Window, [bool]$Motion = $false)
    if (-not $Motion) { return }
    $i = 0
    foreach ($tick in $Window.FindName('LitTicks').Children) {
        $flash = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $flash.BeginTime = [TimeSpan]::FromMilliseconds($i * 9)
        $flash.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(560))
        [void]$flash.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame(1, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(196)))))
        [void]$flash.KeyFrames.Add((New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame(0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(560)), (New-AfKeySpline -Ease Out))))
        $tick.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $flash)
        $i++
    }
}

function Set-AfTextAnimated {
    param([Parameter(Mandatory)]$Block, [string]$Text, [bool]$Motion = $false)
    $Block.Text = $Text
    Start-AfAnimation -Target $Block -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 220 -Ease Out -Enabled $Motion | Out-Null
}

function Set-AfSummary {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)]$Summary, [bool]$Motion = $false)
    $block = $Window.FindName('Summary')
    $block.Inlines.Clear()
    if ($Summary.Ready -gt 0) {
        $lead = New-Object System.Windows.Documents.Run($(if ($Summary.Ready -eq 1) { (T '1 cambio listo') } else { (T '{0} cambios listos') -f $Summary.Ready }))
        $lead.FontWeight = 'Medium'
        $lead.SetResourceReference([System.Windows.Documents.TextElement]::ForegroundProperty, 'Text')
        $block.Inlines.Add($lead)
        $rest = (T ', {0} para hacer a mano y {1} en orden.') -f $Summary.Manual, $Summary.Ok
        $block.Inlines.Add((New-Object System.Windows.Documents.Run($rest)))
    } else {
        $block.Inlines.Add((New-Object System.Windows.Documents.Run(((T 'Todo lo que Afina puede ajustar ya está en orden. {0} para hacer a mano.') -f $Summary.Manual))))
    }
    Start-AfAnimation -Target $block -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 220 -Ease Out -Enabled $Motion | Out-Null
}

function Add-AfRowHandlers {
    param([Parameter(Mandatory)]$Row)
    $Row.Add_MouseLeftButtonUp({
            param($sender, $e)
            # Los clics dentro del detalle abierto (opciones, textos) no lo cierran.
            $detail = $sender.FindName('Detail')
            $source = $e.OriginalSource
            if ($detail.Tag -eq 'open' -and $source -is [System.Windows.Media.Visual] -and $detail.IsAncestorOf($source)) { return }
            $w = [System.Windows.Window]::GetWindow($sender)
            Switch-AfRowDetail -Row $sender -Motion ([bool]$w.Tag.Motion)
        })
    $box = Get-AfRowCheckBox -Row $Row
    if ($box) {
        $box.Tag = $Row
        $box.Add_Click({
                param($sender, $e)
                if ($sender.IsChecked -and $sender.Tag) { Reset-AfChoices -Row $sender.Tag }
                Update-AfPrimary -Window ([System.Windows.Window]::GetWindow($sender)) -Roll $true
            })
    }
}

function Add-AfCategoryGroup {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)]$Category, [object[]]$Results = @(), [bool]$Motion = $false)
    $visible = @($Results | Where-Object { $_.Detection.State -in 'Improvable', 'Manual', 'Info', 'Error' })
    if (-not $visible.Count) { return }
    $groups = $Window.FindName('Groups')
    $Window.FindName('PanelBorder').Visibility = 'Visible'
    $first = @($groups.Children | Where-Object { $_.Tag -ne 'ok' }).Count -eq 0
    $group = New-AfGroupElement -Category $Category -Results $visible -First:$first
    $filter = $Window.Tag.Filter
    $group.Visibility = if ($filter -eq 'all' -or $filter -eq $Category.Id) { 'Visible' } else { 'Collapsed' }
    $okGroup = @($groups.Children | Where-Object { $_.Tag -eq 'ok' })[0]
    if ($okGroup) { $groups.Children.Insert($groups.Children.IndexOf($okGroup), $group) } else { [void]$groups.Children.Add($group) }
    $k = 0
    foreach ($child in $group.Children) {
        if ($child -is [System.Windows.Controls.Border] -and $child.Tag) { Add-AfRowHandlers -Row $child }
        if ($Motion) {
            $child.Opacity = 0
            $shift = New-Object System.Windows.Media.TranslateTransform(0, 8)
            $child.RenderTransform = $shift
            Start-AfAnimation -Target $child -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -DelayMs ($k * 50) -Ease Out -Enabled $true | Out-Null
            Start-AfAnimation -Target $shift -Property ([System.Windows.Media.TranslateTransform]::YProperty) -From 8 -To 0 -DurationMs 300 -DelayMs ($k * 50) -Ease Out -Enabled $true | Out-Null
            $k++
        }
    }
}

function Set-AfOkGroupOpen {
    param([Parameter(Mandatory)]$Group, [bool]$Open, [bool]$Motion = $false)
    $list = $Group.Children[$Group.Children.Count - 1]
    $Group.Resources['Open'] = $Open
    $list.Visibility = if ($Open) { 'Visible' } else { 'Collapsed' }
    $caret = $Group.Resources['Caret']
    if ($caret) { Start-AfAnimation -Target $caret -Property ([System.Windows.Media.RotateTransform]::AngleProperty) -To $(if ($Open) { 180 } else { 0 }) -DurationMs 200 -Ease Out -Enabled $Motion | Out-Null }
    if ($Open) { Start-AfAnimation -Target $list -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 250 -Ease Out -Enabled $Motion | Out-Null }
}

function Add-AfOkGroup {
    param([Parameter(Mandatory)]$Window, [object[]]$Results = @(), [bool]$Motion = $false)
    $ok = @($Results | Where-Object { $_.Detection.State -eq 'Ok' })
    if (-not $ok.Count) { return }
    $groups = $Window.FindName('Groups')
    $Window.FindName('PanelBorder').Visibility = 'Visible'
    $group = New-Object System.Windows.Controls.StackPanel
    $group.Tag = 'ok'
    if ($groups.Children.Count) {
        $line = New-Object System.Windows.Shapes.Rectangle
        $line.Height = 1
        $line.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Line')
        [void]$group.Children.Add($line)
    }
    $header = New-Object System.Windows.Controls.Border
    $header.Padding = '18,12,18,12'
    $header.Background = [System.Windows.Media.Brushes]::Transparent
    $header.Cursor = 'Hand'
    $headerGrid = New-Object System.Windows.Controls.DockPanel
    $caretRotate = New-Object System.Windows.Media.RotateTransform
    $caret = New-AfIcon -Name 'caret-down' -Size 12
    $caret.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
    $caret.RenderTransform = $caretRotate
    [System.Windows.Controls.DockPanel]::SetDock($caret, 'Right')
    $count = New-AfText -Text ([string]$ok.Count) -Size 12 -Brush 'Text3' -Display
    $count.Margin = '0,0,12,0'
    [System.Windows.Controls.DockPanel]::SetDock($count, 'Right')
    [void]$headerGrid.Children.Add($caret)
    [void]$headerGrid.Children.Add($count)
    [void]$headerGrid.Children.Add((New-AfIcon -Name 'check-circle' -Size 17))
    $label = New-AfText -Text (T 'En orden') -Size 13 -Brush 'Text2'
    $label.Margin = '14,0,0,0'
    [void]$headerGrid.Children.Add($label)
    $header.Child = $headerGrid
    [void]$group.Children.Add($header)
    $list = New-Object System.Windows.Controls.StackPanel
    $list.Margin = '0,0,0,8'
    foreach ($result in $ok) {
        $item = New-Object System.Windows.Controls.StackPanel
        $item.Orientation = 'Horizontal'
        $item.Margin = '18,6,18,6'
        $mark = New-AfIcon -Name 'check' -Size 14
        $mark.Margin = '2,0,16,0'
        [void]$item.Children.Add($mark)
        $title = if ($result.Detection.Title) { $result.Detection.Title } else { $result.Check.Title }
        $text = New-AfText -Text $title -Size 12.5 -Brush 'Text2'
        [void]$item.Children.Add($text)
        if ($result.Detection.Current) {
            $value = New-AfText -Text ('  ' + $result.Detection.Current) -Size 12.5 -Brush 'Text3'
            [void]$item.Children.Add($value)
        }
        [void]$list.Children.Add($item)
    }
    [void]$group.Children.Add($list)
    $group.Resources['Caret'] = $caretRotate
    $header.Add_MouseLeftButtonUp({ param($sender, $e)
            $g = $sender.Parent
            $w = [System.Windows.Window]::GetWindow($sender)
            Set-AfOkGroupOpen -Group $g -Open (-not [bool]$g.Resources['Open']) -Motion ([bool]$w.Tag.Motion)
        })
    Set-AfOkGroupOpen -Group $group -Open $false
    $filter = $Window.Tag.Filter
    $group.Visibility = if ($filter -eq 'all' -or $filter -eq 'ok') { 'Visible' } else { 'Collapsed' }
    [void]$groups.Children.Add($group)
    if ($Motion) { Start-AfAnimation -Target $group -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Out -Enabled $true | Out-Null }
}

function Get-AfRows {
    param([Parameter(Mandatory)]$Window)
    foreach ($group in $Window.FindName('Groups').Children) {
        foreach ($child in $group.Children) {
            if ($child -is [System.Windows.Controls.Border] -and $child.Tag -and $child.Tag.Check) { $child }
        }
    }
}

function Get-AfRowById {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)][string]$Id)
    @(Get-AfRows -Window $Window | Where-Object { $_.Tag.Check.Id -eq $Id })[0]
}

# Resultados con la casilla marcada, en el orden de la lista.
function Get-AfSelectedResults {
    param([Parameter(Mandatory)]$Window)
    foreach ($row in @(Get-AfRows -Window $Window)) {
        $box = Get-AfRowCheckBox -Row $row
        if ($box -and $box.IsChecked) { $row.Tag }
    }
}

function Get-AfSelectedCount {
    param([Parameter(Mandatory)]$Window)
    @(Get-AfSelectedResults -Window $Window).Count
}

function Update-AfPrimary {
    param([Parameter(Mandatory)]$Window, [bool]$Roll = $false)
    # Fuera de "listo para optimizar", el botón lo maneja Set-AfFooter.
    if ($Window.Tag.Phase -and $Window.Tag.Phase -ne 'ready') { return }
    $n = Get-AfSelectedCount -Window $Window
    $lead = $Window.FindName('PrimaryLead')
    $number = $Window.FindName('PrimaryNumber')
    $tail = $Window.FindName('PrimaryTail')
    if ($n -eq 0) {
        $lead.Text = (T 'Elige qué optimizar')
        $number.Text = ''
        $tail.Text = ''
        return
    }
    # Los espacios van en el código: las traducciones no llevan espacios al principio ni al final.
    $lead.Text = (T 'Optimizar') + ' '
    $number.Text = [string]$n
    $tail.Text = ' ' + $(if ($n -eq 1) { (T 'cambio') } else { (T 'cambios') })
    if ($Roll -and $Window.Tag.Motion) {
        Start-AfAnimation -Target $number -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 180 -Ease Out | Out-Null
        Start-AfAnimation -Target $Window.FindName('PrimaryNumberShift') -Property ([System.Windows.Media.TranslateTransform]::YProperty) -From 8 -To 0 -DurationMs 180 -Ease Out | Out-Null
    }
}

function Show-AfResults {
    param([Parameter(Mandatory)]$Window, [object[]]$Results = @(), [bool]$Animate = $false)
    $state = Get-AfUiState -Window $Window
    $state.Phase = 'ready'
    $state.Results = New-Object System.Collections.ArrayList(, @($Results))
    $Window.FindName('Groups').Children.Clear()
    foreach ($category in Get-AfCategories) {
        Add-AfCategoryGroup -Window $Window -Category $category -Results @($Results | Where-Object { $_.Check.Category -eq $category.Id }) -Motion $Animate
    }
    Add-AfOkGroup -Window $Window -Results $Results -Motion $Animate
    Update-AfNavCounts -Window $Window -Results $Results -Motion $Animate
    Set-AfSummary -Window $Window -Summary (Get-AfSummary -Results $Results) -Motion $Animate
    $Window.FindName('Title').Text = (T 'Afinación')
    $Window.FindName('Actions').Opacity = 1
    $Window.FindName('Actions').IsHitTestVisible = $true
    $Window.FindName('PcCard').Opacity = 1
    Update-AfPrimary -Window $Window
    Set-AfNeedle -Window $Window -Fraction (Get-AfScore -Results $Results) -Motion $Animate
}
