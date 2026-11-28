# Resumen (panel de inicio), logo, pantalla de entrada y barra lateral que se despliega.

# Marca de Afina en una cuadrícula de 64: la escala de un afinador con la aguja roja al centro (afinado).
# -Fixed usa colores fijos (para el icono de la ventana, que se dibuja fuera del árbol y no ve el tema).
function New-AfLogoMark {
    param([double]$Size = 64, [switch]$Fixed)
    $canvas = New-Object System.Windows.Controls.Canvas
    $canvas.Width = 64
    $canvas.Height = 64
    $bars = New-Object System.Collections.ArrayList
    # Marcas de afuera hacia adentro a cada lado: mayor, menor, media.
    foreach ($tick in @(@(6, 18), @(15, 11), @(24, 14), @(36, 14), @(45, 11), @(54, 18))) {
        $bar = New-Object System.Windows.Shapes.Rectangle
        $bar.Width = 4
        $bar.Height = $tick[1]
        $bar.RadiusX = 1.5
        $bar.RadiusY = 1.5
        $bar.Opacity = if ($tick[1] -eq 18) { 0.95 } else { 0.6 }
        if ($Fixed) { $bar.Fill = [System.Windows.Media.Brushes]::WhiteSmoke } else { $bar.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Text') }
        [System.Windows.Controls.Canvas]::SetLeft($bar, $tick[0])
        [System.Windows.Controls.Canvas]::SetTop($bar, 52 - $tick[1])
        $bar.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 1)
        $bar.RenderTransform = New-Object System.Windows.Media.ScaleTransform(1, 1)
        [void]$canvas.Children.Add($bar)
        [void]$bars.Add($bar)
    }
    $needle = New-Object System.Windows.Controls.Canvas
    $line = New-Object System.Windows.Shapes.Rectangle
    $line.Width = 4
    $line.Height = 47
    $line.RadiusX = 2
    $line.RadiusY = 2
    [System.Windows.Controls.Canvas]::SetLeft($line, 30)
    [System.Windows.Controls.Canvas]::SetTop($line, 9)
    $head = New-Object System.Windows.Shapes.Polygon
    $head.Points = [System.Windows.Media.PointCollection]::Parse('26.5,2 37.5,2 32,8.5')
    foreach ($shape in $line, $head) {
        if ($Fixed) { $shape.Fill = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 59, 71)) } else { $shape.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Red') }
        [void]$needle.Children.Add($shape)
    }
    # Gira sobre su base, como la aguja de un afinador que se asienta.
    $needle.RenderTransform = New-Object System.Windows.Media.RotateTransform(0, 32, 56)
    [void]$canvas.Children.Add($needle)
    $canvas.Tag = @{ Bars = $bars; Needle = $needle }
    $box = New-Object System.Windows.Controls.Viewbox
    $box.Width = $Size
    $box.Height = $Size
    $box.Child = $canvas
    $box
}

# Icono de la ventana y de la barra de tareas: la marca sobre un cuadrado negro.
function New-AfLogoImage {
    $tile = New-Object System.Windows.Controls.Border
    $tile.Width = 64
    $tile.Height = 64
    $tile.CornerRadius = 14
    $tile.Background = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(20, 20, 22))
    $mark = New-AfLogoMark -Size 48 -Fixed
    $mark.HorizontalAlignment = 'Center'
    $mark.VerticalAlignment = 'Center'
    $tile.Child = $mark
    $tile.Measure((New-Object System.Windows.Size(64, 64)))
    $tile.Arrange((New-Object System.Windows.Rect(0, 0, 64, 64)))
    $bitmap = New-Object System.Windows.Media.Imaging.RenderTargetBitmap(64, 64, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($tile)
    $bitmap.Freeze()
    $bitmap
}

# Pantalla de entrada: se prepara antes de mostrar la ventana y se anima con el primer cuadro.
function Initialize-AfSplash {
    param([Parameter(Mandatory)]$Window, [bool]$Motion = $false)
    $mark = New-AfLogoMark -Size 84
    $Window.FindName('SplashMarkHost').Child = $mark
    $Window.FindName('SplashVersion').Text = 'v' + (Get-AfVersion)
    $Window.Tag.SplashParts = $mark.Child.Tag
    if (-not $Motion) { return }
    foreach ($bar in $mark.Child.Tag.Bars) { $bar.RenderTransform.ScaleY = 0 }
    $mark.Child.Tag.Needle.Opacity = 0
    $mark.Child.Tag.Needle.RenderTransform.Angle = -28
    foreach ($name in 'SplashName', 'SplashTag', 'SplashVersion') { $Window.FindName($name).Opacity = 0 }
}

function Start-AfSplash {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $splash = $Window.FindName('Splash')
    if ($splash.Visibility -ne 'Visible') { return }
    $splash.Add_MouseLeftButtonUp({ param($sender, $e) Hide-AfSplash -Window ([System.Windows.Window]::GetWindow($sender)) })
    $parts = $s.SplashParts
    if ($s.Motion -and $parts) {
        # Las marcas suben de adentro hacia afuera; la aguja entra torcida y se asienta al centro.
        $order = @(2, 1, 0, 0, 1, 2)
        for ($k = 0; $k -lt $parts.Bars.Count; $k++) {
            Start-AfAnimation -Target $parts.Bars[$k].RenderTransform -Property ([System.Windows.Media.ScaleTransform]::ScaleYProperty) -From 0 -To 1 -DurationMs 460 -DelayMs (120 + 90 * $order[$k]) -Ease Out | Out-Null
        }
        Start-AfAnimation -Target $parts.Needle -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 200 -DelayMs 300 -Ease Out | Out-Null
        $settle = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $settle.BeginTime = [TimeSpan]::FromMilliseconds(300)
        foreach ($frame in @(@(-28, 0), @(14, 380), @(-6, 640), @(2, 840), @(0, 1000))) {
            [void]$settle.KeyFrames.Add((New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame($frame[0], [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds($frame[1])), (New-AfKeySpline -Ease InOut))))
        }
        $parts.Needle.RenderTransform.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $settle)
        $name = $Window.FindName('SplashName')
        $shift = New-Object System.Windows.Media.TranslateTransform(0, 12)
        $name.RenderTransform = $shift
        Start-AfAnimation -Target $name -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 520 -DelayMs 520 -Ease Out | Out-Null
        Start-AfAnimation -Target $shift -Property ([System.Windows.Media.TranslateTransform]::YProperty) -From 12 -To 0 -DurationMs 620 -DelayMs 520 -Ease Out | Out-Null
        Start-AfAnimation -Target $Window.FindName('SplashTag') -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 520 -DelayMs 760 -Ease Out | Out-Null
        Start-AfAnimation -Target $Window.FindName('SplashVersion') -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 520 -DelayMs 900 -Ease Out | Out-Null
    }
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds($(if ($s.Motion) { 2300 } else { 900 }))
    $timer.Tag = $Window
    $timer.Add_Tick({ param($sender, $e) $sender.Stop(); Hide-AfSplash -Window $sender.Tag })
    $timer.Start()
}

function Hide-AfSplash {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    if ($s.SplashGone) { return }
    $s.SplashGone = $true
    $splash = $Window.FindName('Splash')
    if (-not $s.Motion) { $splash.Visibility = 'Collapsed'; return }
    $splash.IsHitTestVisible = $false
    $zoom = New-Object System.Windows.Media.ScaleTransform(1, 1)
    $content = $Window.FindName('SplashContent')
    $content.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
    $content.RenderTransform = $zoom
    Start-AfAnimation -Target $zoom -Property ([System.Windows.Media.ScaleTransform]::ScaleXProperty) -To 1.04 -DurationMs 420 -Ease Out | Out-Null
    Start-AfAnimation -Target $zoom -Property ([System.Windows.Media.ScaleTransform]::ScaleYProperty) -To 1.04 -DurationMs 420 -Ease Out | Out-Null
    Start-AfAnimation -Target $splash -Property ([System.Windows.UIElement]::OpacityProperty) -To 0 -DurationMs 420 -Ease Out | Out-Null
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(440)
    $timer.Tag = $splash
    $timer.Add_Tick({ param($sender, $e) $sender.Stop(); $sender.Tag.Visibility = 'Collapsed' })
    $timer.Start()
}

# Barra lateral: solo iconos; al pasar el mouse se despliega sobre el contenido con nombres y números.
function Set-AfRailOpen {
    param([Parameter(Mandatory)]$Window, [bool]$Open)
    $s = $Window.Tag
    if ($s.RailOpen -eq $Open) { return }
    $s.RailOpen = $Open
    $motion = [bool]$s.Motion
    Start-AfAnimation -Target $Window.FindName('Rail') -Property ([System.Windows.FrameworkElement]::WidthProperty) -To $(if ($Open) { 236 } else { 64 }) -DurationMs $(if ($Open) { 260 } else { 200 }) -Ease Out -Enabled $motion | Out-Null
    Start-AfAnimation -Target $Window.FindName('RailShadow') -Property ([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty) -To $(if ($Open) { 0.55 } else { 0 }) -DurationMs 220 -Ease Out -Enabled $motion | Out-Null
    if (-not $s.Nav) { return }
    foreach ($ref in $s.Nav.Values) {
        foreach ($element in $ref.Label, $ref.CountHost) {
            Start-AfAnimation -Target $element -Property ([System.Windows.UIElement]::OpacityProperty) -To $(if ($Open) { 1 } else { 0 }) -DurationMs $(if ($Open) { 220 } else { 120 }) -DelayMs $(if ($Open) { 70 } else { 0 }) -Ease Out -Enabled $motion | Out-Null
        }
        Start-AfAnimation -Target $ref.Dot -Property ([System.Windows.UIElement]::OpacityProperty) -To $(if ($Open) { 0 } else { 1 }) -DurationMs 160 -Ease Out -Enabled $motion | Out-Null
    }
}

function Initialize-AfRail {
    param([Parameter(Mandatory)]$Window)
    $rail = $Window.FindName('Rail')
    $hover = New-Object System.Windows.Threading.DispatcherTimer
    $hover.Interval = [TimeSpan]::FromMilliseconds(140)
    $hover.Tag = $Window
    $hover.Add_Tick({ param($sender, $e) $sender.Stop(); Set-AfRailOpen -Window $sender.Tag -Open $true })
    $Window.Tag.RailHover = $hover
    $rail.Add_MouseEnter({ param($sender, $e) [System.Windows.Window]::GetWindow($sender).Tag.RailHover.Start() })
    $rail.Add_MouseLeave({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            $w.Tag.RailHover.Stop()
            Set-AfRailOpen -Window $w -Open $false
        })
    Set-AfRailOpen -Window $Window -Open $false
}

# Resumen o lista. El pie (nota y botones) se esconde en el Resumen mientras no hay nada en curso: ahí el botón va en la tarjeta.
function Set-AfView {
    param([Parameter(Mandatory)]$Window, [ValidateSet('home', 'list')][string]$View)
    $s = $Window.Tag
    $changed = $s.View -ne $View
    $s.View = $View
    $homeScroll = $Window.FindName('HomeScroll')
    $homeScroll.Visibility = if ($View -eq 'home') { 'Visible' } else { 'Collapsed' }
    $Window.FindName('ListView').Visibility = if ($View -eq 'home') { 'Collapsed' } else { 'Visible' }
    Update-AfFooterVisibility -Window $Window
    if ($View -eq 'home' -and $changed) {
        Update-AfHome -Window $Window
        Update-AfLiveTiles -Window $Window
        Start-AfAnimation -Target $homeScroll -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 240 -Ease Out -Enabled ([bool]$s.Motion) | Out-Null
    }
}

function Update-AfFooterVisibility {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $Window.FindName('Footer').Visibility = if ($s.View -eq 'home' -and $s.Phase -in 'scanning', 'ready') { 'Collapsed' } else { 'Visible' }
}

function Get-AfRadarAxes { 'gaming', 'network', 'security', 'storage', 'startup', 'energy' }

function Initialize-AfHome {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    Set-AfIconData -Path $Window.FindName('HeroIcon') -Name 'gauge'
    Set-AfIconData -Path $Window.FindName('ProfileIcon') -Name 'squares-four'
    Set-AfIconData -Path $Window.FindName('HeroButtonIcon') -Name 'arrow-right'
    Set-AfIconData -Path $Window.FindName('HeroNoteIcon') -Name 'shield-check'
    $quick = $Window.FindName('Quick')
    $quick.Children.Clear()
    $s.QuickCards = @{}
    foreach ($q in @(
            @{ Id = 'hardware'; Icon = 'wrench'; Title = (T 'Diagnóstico'); Text = (T 'Disco, batería y memoria') }
            @{ Id = 'windows'; Icon = 'windows-logo'; Title = (T 'Ajustes de Windows'); Text = (T 'Menú y Explorador') }
            @{ Id = 'history'; Icon = 'clock-counter-clockwise'; Title = (T 'Historial'); Text = (T 'Deshacer cambios') }
            @{ Id = 'rescan'; Icon = 'arrow-clockwise'; Title = (T 'Volver a analizar'); Text = (T 'Revisar otra vez') }
        )) {
        $card = New-AfQuickCard @q
        [void]$quick.Children.Add($card)
        $s.QuickCards[$q.Id] = $card
    }
    $live = $Window.FindName('Live')
    $live.Children.Clear()
    $s.LiveTiles = [ordered]@{}
    foreach ($t in @(
            @{ Key = 'Cpu'; Icon = 'cpu'; Label = 'CPU' }
            @{ Key = 'Mem'; Icon = 'memory'; Label = (T 'Memoria') }
            @{ Key = 'Disk'; Icon = 'hard-drives'; Label = (T 'Disco') }
            @{ Key = 'Net'; Icon = 'wifi-high'; Label = (T 'Red') }
        )) {
        $tile = New-AfLiveTile -Icon $t.Icon -Label $t.Label
        $tile.Spark.Tag = $t.Key
        [void]$live.Children.Add($tile.Element)
        $s.LiveTiles[$t.Key] = $tile
    }
    if (-not $s.LiveHistory) { $s.LiveHistory = @{ Cpu = New-Object System.Collections.ArrayList; Mem = New-Object System.Collections.ArrayList; Disk = New-Object System.Collections.ArrayList; Net = New-Object System.Collections.ArrayList } }
    New-AfRadar -Window $Window
    if (-not $s.HomeReady) {
        $s.HomeReady = $true
        $Window.FindName('HeroMeter').Add_SizeChanged({ param($sender, $e) Update-AfHeroLayout -Window ([System.Windows.Window]::GetWindow($sender)) })
        $Window.FindName('HeroButton').Add_Click({ param($sender, $e) Set-AfFilter -Window ([System.Windows.Window]::GetWindow($sender)) -Filter 'all' })
    }
    Update-AfLiveTiles -Window $Window
}

function New-AfQuickCard {
    param([string]$Id, [string]$Icon, [string]$Title, [string]$Text)
    $card = New-Object System.Windows.Controls.Border
    $card.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'Card')
    $card.Margin = '6,0,6,0'
    $card.Padding = '14,12,14,12'
    $card.Cursor = 'Hand'
    $card.Tag = $Id
    [System.Windows.Automation.AutomationProperties]::SetName($card, $Title)
    $dock = New-Object System.Windows.Controls.DockPanel
    $badge = New-Object System.Windows.Controls.Border
    $badge.Width = 34
    $badge.Height = 34
    $badge.CornerRadius = 9
    $badge.BorderThickness = 1
    $badge.Margin = '0,0,12,0'
    $badge.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Raised')
    $badge.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Line2')
    $glyph = New-AfIcon -Name $Icon -Size 16 -Brush 'Text'
    $glyph.HorizontalAlignment = 'Center'
    $badge.Child = $glyph
    [System.Windows.Controls.DockPanel]::SetDock($badge, 'Left')
    [void]$dock.Children.Add($badge)
    $texts = New-Object System.Windows.Controls.StackPanel
    $texts.VerticalAlignment = 'Center'
    $head = New-AfText -Text $Title -Size 13 -Brush 'Text' -Weight 'Medium'
    $head.TextWrapping = 'NoWrap'
    $head.TextTrimming = 'CharacterEllipsis'
    [void]$texts.Children.Add($head)
    $sub = New-AfText -Text $Text -Size 11.5 -Brush 'Text3'
    $sub.Margin = '0,2,0,0'
    $sub.TextWrapping = 'NoWrap'
    $sub.TextTrimming = 'CharacterEllipsis'
    [void]$texts.Children.Add($sub)
    [void]$dock.Children.Add($texts)
    $card.Child = $dock
    $card.Add_MouseEnter({ param($sender, $e)
            $sender.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Raised')
            $sender.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Line2')
        })
    $card.Add_MouseLeave({ param($sender, $e)
            $sender.ClearValue([System.Windows.Controls.Border]::BackgroundProperty)
            $sender.ClearValue([System.Windows.Controls.Border]::BorderBrushProperty)
        })
    $card.Add_MouseLeftButtonUp({ param($sender, $e) Invoke-AfQuickAction -Window ([System.Windows.Window]::GetWindow($sender)) -Id $sender.Tag })
    $card
}

function Invoke-AfQuickAction {
    param([Parameter(Mandatory)]$Window, [string]$Id)
    $s = $Window.Tag
    switch ($Id) {
        'history' { if ($s.Phase -in 'ready', 'done') { Show-AfHistory -Window $Window } }
        'rescan' { if ($s.Phase -in 'ready', 'done') { Start-AfScan -Window $Window } }
        default { Set-AfFilter -Window $Window -Filter $Id }
    }
}

function New-AfLiveTile {
    param([string]$Icon, [string]$Label)
    $card = New-Object System.Windows.Controls.Border
    $card.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'Card')
    $card.Margin = '6,0,6,0'
    $card.Padding = '16,14,16,12'
    $stack = New-Object System.Windows.Controls.StackPanel
    $head = New-Object System.Windows.Controls.DockPanel
    $values = New-Object System.Windows.Controls.StackPanel
    $values.Orientation = 'Horizontal'
    [System.Windows.Controls.DockPanel]::SetDock($values, 'Right')
    $value = New-AfText -Text '—' -Size 22 -Brush 'Text' -Display -Weight 'Medium'
    $value.TextWrapping = 'NoWrap'
    $unit = New-AfText -Text '' -Size 12 -Brush 'Text2'
    $unit.Margin = '3,0,0,3'
    $unit.VerticalAlignment = 'Bottom'
    [void]$values.Children.Add($value)
    [void]$values.Children.Add($unit)
    [void]$head.Children.Add($values)
    $name = New-Object System.Windows.Controls.StackPanel
    $name.Orientation = 'Horizontal'
    $name.VerticalAlignment = 'Center'
    [void]$name.Children.Add((New-AfIcon -Name $Icon -Size 14 -Brush 'Text2'))
    $caption = New-AfText -Text $Label -Size 12.5 -Brush 'Text2'
    $caption.Margin = '8,0,0,0'
    [void]$name.Children.Add($caption)
    [void]$head.Children.Add($name)
    [void]$stack.Children.Add($head)
    $spark = New-Object System.Windows.Controls.Grid
    $spark.Height = 44
    $spark.Margin = '0,12,0,8'
    $spark.Background = [System.Windows.Media.Brushes]::Transparent
    $spark.ToolTip = ''
    $area = New-Object System.Windows.Shapes.Polygon
    $area.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'SparkFill')
    $line = New-Object System.Windows.Shapes.Polyline
    $line.StrokeThickness = 1.5
    $line.StrokeLineJoin = 'Round'
    $line.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, 'Text')
    $dot = New-Object System.Windows.Shapes.Ellipse
    $dot.Width = 5
    $dot.Height = 5
    $dot.HorizontalAlignment = 'Left'
    $dot.VerticalAlignment = 'Top'
    $dot.Visibility = 'Collapsed'
    $dot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Text')
    $base = New-Object System.Windows.Shapes.Rectangle
    $base.Height = 1
    $base.VerticalAlignment = 'Bottom'
    $base.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Line')
    foreach ($part in $base, $area, $line, $dot) { [void]$spark.Children.Add($part) }
    $spark.Add_SizeChanged({ param($sender, $e) Update-AfLiveTiles -Window ([System.Windows.Window]::GetWindow($sender)) })
    $spark.Add_ToolTipOpening({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            $sender.ToolTip = Get-AfLiveTip -Window $w -Key $sender.Tag
            if (-not $sender.ToolTip) { $e.Handled = $true }
        })
    [void]$stack.Children.Add($spark)
    $foot = New-AfText -Text ' ' -Size 11.5 -Brush 'Text3'
    $foot.TextWrapping = 'NoWrap'
    $foot.TextTrimming = 'CharacterEllipsis'
    [void]$stack.Children.Add($foot)
    $card.Child = $stack
    [pscustomobject]@{ Element = $card; Value = $value; Unit = $unit; Spark = $spark; Area = $area; Line = $line; Dot = $dot; Foot = $foot }
}

# Velocidad de red en bits por segundo, como el Administrador de tareas.
function Format-AfRate {
    param([double]$BitsPerSecond)
    $culture = Get-AfCulture
    if ($BitsPerSecond -ge 1e6) { @(($BitsPerSecond / 1e6).ToString('N1', $culture), 'Mbps') } else { @(($BitsPerSecond / 1e3).ToString('N0', $culture), 'Kbps') }
}

function Get-AfLiveTip {
    param([Parameter(Mandatory)]$Window, [string]$Key)
    $values = @($Window.Tag.LiveHistory[$Key])
    if ($values.Count -lt 2) { return $null }
    $avg = ($values | Measure-Object -Average).Average
    $max = ($values | Measure-Object -Maximum).Maximum
    if ($Key -eq 'Net') {
        $a = Format-AfRate -BitsPerSecond $avg
        $m = Format-AfRate -BitsPerSecond $max
        return (T 'Último minuto: promedio {0}, máximo {1}') -f ('{0} {1}' -f $a[0], $a[1]), ('{0} {1}' -f $m[0], $m[1])
    }
    (T 'Último minuto: promedio {0}, máximo {1}') -f ('{0:N0} %' -f $avg), ('{0:N0} %' -f $max)
}

# Lee la última muestra del trabajo en segundo plano y la guarda; solo dibuja si el Resumen está a la vista.
function Receive-AfLiveSample {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $sync = $s.LiveSync
    if (-not $sync -or $sync.Seq -eq $s.LiveSeq) { return }
    $s.LiveSeq = $sync.Seq
    $sample = $sync.Sample
    if (-not $sample -or -not $s.LiveHistory) { return }
    $s.LiveLast = $sample
    $map = @{ Cpu = $sample.Cpu; Disk = $sample.Disk; Net = $sample.Down }
    if ($sample.MemTotal) { $map.Mem = 100 * $sample.MemUsed / $sample.MemTotal }
    foreach ($key in $map.Keys) {
        if ($null -eq $map[$key]) { continue }
        $list = $s.LiveHistory[$key]
        [void]$list.Add([double]$map[$key])
        while ($list.Count -gt 60) { $list.RemoveAt(0) }
    }
    if ($s.View -eq 'home' -and $Window.WindowState -ne 'Minimized') { Update-AfLiveTiles -Window $Window }
}

function Update-AfLiveTiles {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    if (-not $s.LiveTiles) { return }
    $last = $s.LiveLast
    $inv = $s.Inventory
    $culture = Get-AfCulture
    foreach ($key in @($s.LiveTiles.Keys)) {
        $tile = $s.LiveTiles[$key]
        $history = @($s.LiveHistory[$key])
        $max = 100
        $foot = ''
        $has = $history.Count -gt 0
        switch ($key) {
            'Cpu' {
                if ($has) { $tile.Value.Text = '{0:N0}' -f $history[-1]; $tile.Unit.Text = '%' }
                if ($inv -and $inv.Cpu) { $foot = Format-AfCpuName -Name $inv.Cpu.Name }
            }
            'Mem' {
                if ($has) { $tile.Value.Text = '{0:N0}' -f $history[-1]; $tile.Unit.Text = '%' }
                if ($last -and $last.MemTotal) { $foot = (T '{0} de {1} GB en uso') -f ($last.MemUsed / 1GB).ToString('N1', $culture), ($last.MemTotal / 1GB).ToString('N1', $culture) }
            }
            'Disk' {
                if ($has) { $tile.Value.Text = '{0:N0}' -f $history[-1]; $tile.Unit.Text = '%' }
                $foot = (T 'Tiempo activo')
                if ($inv -and $inv.Storage) { $foot = (T 'Tiempo activo · {0} GB libres') -f $inv.Storage.FreeGB }
            }
            'Net' {
                if ($has) {
                    $rate = Format-AfRate -BitsPerSecond $history[-1]
                    $tile.Value.Text = $rate[0]
                    $tile.Unit.Text = $rate[1]
                    # La escala sigue lo más alto del último minuto, con un piso de 1 Mbps para que el ruido no llene la gráfica.
                    $max = [math]::Max(1e6, ($history | Measure-Object -Maximum).Maximum * 1.15)
                }
                if ($last -and $null -ne $last.Up) { $up = Format-AfRate -BitsPerSecond $last.Up; $foot = (T 'Descarga · subida {0} {1}') -f $up[0], $up[1] } else { $foot = (T 'Descarga') }
            }
        }
        if (-not $has -and $s.LiveSync -and $s.LiveSync.Failed -and $s.LiveSync.Failed.Contains($key)) { $foot = (T 'Windows no da este dato') }
        $tile.Foot.Text = if ($foot) { $foot } else { ' ' }
        Set-AfSpark -Tile $tile -Values $history -Max $max
    }
}

function Set-AfSpark {
    param([Parameter(Mandatory)]$Tile, [double[]]$Values = @(), [double]$Max = 100)
    $width = $Tile.Spark.ActualWidth
    $height = $Tile.Spark.ActualHeight
    if ($width -le 0 -or $Values.Count -lt 2) { $Tile.Line.Points = $null; $Tile.Area.Points = $null; $Tile.Dot.Visibility = 'Collapsed'; return }
    $step = $width / 59
    $points = New-Object System.Windows.Media.PointCollection
    $n = $Values.Count
    for ($i = 0; $i -lt $n; $i++) {
        $x = $width - ($n - 1 - $i) * $step
        $y = $height - 1 - ([math]::Min($Max, [math]::Max(0.0, $Values[$i])) / $Max) * ($height - 5)
        $points.Add((New-Object System.Windows.Point($x, $y)))
    }
    $Tile.Line.Points = $points
    $area = $points.Clone()
    $area.Add((New-Object System.Windows.Point($width, $height)))
    $area.Add((New-Object System.Windows.Point(($width - ($n - 1) * $step), $height)))
    $Tile.Area.Points = $area
    $lastPoint = $points[$n - 1]
    $Tile.Dot.Margin = New-Object System.Windows.Thickness(($lastPoint.X - 2.5), ($lastPoint.Y - 2.5), 0, 0)
    $Tile.Dot.Visibility = 'Visible'
}

# Medidor grande del Resumen: 48 barras que suben de izquierda a derecha; la última es roja, como la marca final del medidor.
function Update-AfHeroLayout {
    param([Parameter(Mandatory)]$Window)
    $meter = $Window.FindName('HeroMeter')
    $width = $meter.ActualWidth
    $height = $meter.ActualHeight
    if ($width -le 0 -or $height -le 0) { return }
    $n = 48
    $gap = if ($width / $n -ge 7) { 3 } else { 2 }
    $barWidth = ($width - $gap * ($n - 1)) / $n
    foreach ($canvasName in 'HeroBars', 'HeroLit') {
        $canvas = $Window.FindName($canvasName)
        if ($canvas.Children.Count -ne $n) {
            $canvas.Children.Clear()
            for ($i = 0; $i -lt $n; $i++) {
                $bar = New-Object System.Windows.Shapes.Rectangle
                $bar.RadiusX = 1.5
                $bar.RadiusY = 1.5
                $brush = if ($i -eq $n - 1) { 'Red' } elseif ($canvasName -eq 'HeroLit') { 'BarLit' } else { 'Tick' }
                $bar.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $brush)
                if ($canvasName -eq 'HeroLit') { $bar.Opacity = 0 }
                [void]$canvas.Children.Add($bar)
            }
        }
        for ($i = 0; $i -lt $n; $i++) {
            $bar = $canvas.Children[$i]
            $bar.Width = [math]::Max(1.0, $barWidth)
            $bar.Height = 10 + ($height - 22) * [math]::Pow($i / ($n - 1), 1.35)
            [System.Windows.Controls.Canvas]::SetLeft($bar, $i * ($barWidth + $gap))
            [System.Windows.Controls.Canvas]::SetTop($bar, $height - $bar.Height)
        }
    }
    $Window.Tag.HeroStep = $barWidth + $gap
    $Window.Tag.HeroBarWidth = $barWidth
    $Window.FindName('HeroNeedleLine').Height = $height - 6
    [System.Windows.Controls.Canvas]::SetTop($Window.FindName('HeroNeedleHead'), 3 - $height)
    $needle = $Window.FindName('HeroNeedleTransform')
    $needle.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $null)
    $needle.X = Get-AfHeroNeedleX -Window $Window -Fraction ([double]$Window.Tag.HeroF)
    Set-AfHeroFraction -Window $Window -Fraction ([double]$Window.Tag.HeroF) -Motion $false -Force
}

function Get-AfHeroNeedleX {
    param([Parameter(Mandatory)]$Window, [double]$Fraction)
    $index = [math]::Round([math]::Max(0.0, [math]::Min(1.0, $Fraction)) * 47)
    $index * [double]$Window.Tag.HeroStep + [double]$Window.Tag.HeroBarWidth / 2 - 1
}

# Enciende las barras hasta la fracción, una tras otra; la aguja va al mismo lugar.
function Set-AfHeroFraction {
    param([Parameter(Mandatory)]$Window, [double]$Fraction, [bool]$Motion = $false, [switch]$Force, [switch]$HideNeedle)
    $s = $Window.Tag
    $previous = [double]$s.HeroF
    $s.HeroF = $Fraction
    $lit = $Window.FindName('HeroLit').Children
    if (-not $lit.Count) { return }
    $upTo = [math]::Round([math]::Max(0.0, [math]::Min(1.0, $Fraction)) * 47)
    $from = [math]::Round([math]::Max(0.0, [math]::Min(1.0, $previous)) * 47)
    for ($i = 0; $i -lt $lit.Count; $i++) {
        $target = if ($i -le $upTo -and $Fraction -gt 0) { 1 } else { 0 }
        $bar = $lit[$i]
        if (-not $Force -and $bar.Opacity -eq $target) { continue }
        $delay = if ($Motion) { [math]::Abs($i - $from) * 14 } else { 0 }
        Start-AfAnimation -Target $bar -Property ([System.Windows.UIElement]::OpacityProperty) -To $target -DurationMs 220 -DelayMs $delay -Ease Out -Enabled $Motion | Out-Null
    }
    $needle = $Window.FindName('HeroNeedle')
    Start-AfAnimation -Target $needle -Property ([System.Windows.UIElement]::OpacityProperty) -To $(if ($HideNeedle) { 0 } else { 1 }) -DurationMs 260 -Ease Out -Enabled $Motion | Out-Null
    if ($s.HeroStep) {
        Start-AfAnimation -Target $Window.FindName('HeroNeedleTransform') -Property ([System.Windows.Media.TranslateTransform]::XProperty) -To (Get-AfHeroNeedleX -Window $Window -Fraction $Fraction) -DurationMs 700 -Ease Out -Enabled $Motion | Out-Null
    }
}

# Al quedar afinada, una ola recorre las barras encendidas.
function Start-AfHeroCelebration {
    param([Parameter(Mandatory)]$Window)
    $i = 0
    foreach ($bar in $Window.FindName('HeroLit').Children) {
        $wave = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $wave.BeginTime = [TimeSpan]::FromMilliseconds($i * 12)
        $wave.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(520))
        [void]$wave.KeyFrames.Add((New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame(0.3, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(180)), (New-AfKeySpline -Ease Out))))
        [void]$wave.KeyFrames.Add((New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame(1, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(520)), (New-AfKeySpline -Ease Out))))
        $bar.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $wave)
        $i++
    }
}

# Número grande que cuenta hasta su valor.
function Set-AfCountUp {
    param([Parameter(Mandatory)]$Block, [int]$To, [bool]$Motion = $false)
    $from = 0
    [void][int]::TryParse($Block.Text, [ref]$from)
    if ($Block.Tag -is [System.Windows.Threading.DispatcherTimer]) { $Block.Tag.Stop() }
    if (-not $Motion -or $from -eq $To) { $Block.Text = [string]$To; return }
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(16)
    $timer.Tag = @{ Block = $Block; From = $from; To = $To; Start = Get-Date }
    $timer.Add_Tick({ param($sender, $e)
            $st = $sender.Tag
            $t = [math]::Min(1.0, ((Get-Date) - $st.Start).TotalMilliseconds / 500)
            $st.Block.Text = [string][math]::Round($st.From + ($st.To - $st.From) * (1 - [math]::Pow(1 - $t, 3)))
            if ($t -ge 1) { $sender.Stop() }
        })
    $Block.Tag = $timer
    $timer.Start()
}

# Texto plano de un TextBlock armado con Runs (el título y el resumen de la lista).
function Get-AfBlockText {
    param([Parameter(Mandatory)]$Block)
    $runs = @($Block.Inlines | Where-Object { $_ -is [System.Windows.Documents.Run] })
    if ($runs.Count) { ($runs | ForEach-Object { $_.Text }) -join '' } else { $Block.Text }
}

# Tarjeta principal, perfil y acciones según la fase y los resultados.
function Update-AfHome {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    if (-not $s.HomeReady) { return }
    $motion = [bool]$s.Motion -and $s.View -eq 'home'
    $results = @(Get-AfEffectiveResults -Window $Window)
    $button = $Window.FindName('HeroButton')
    if ($s.Phase -eq 'scanning') {
        $total = @(Get-AfCategories).Count
        $done = [int]$s.Revealed
        Set-AfCountUp -Block $Window.FindName('HeroNumber') -To $results.Count -Motion $motion
        $Window.FindName('HeroUnit').Text = (T 'revisados')
        $Window.FindName('HeroTitle').Text = (T 'Analizando esta PC')
        $Window.FindName('HeroText').Text = if ($done -gt 0) { (T '{0} de {1} categorías revisadas') -f $done, $total } elseif ($s.PartPhrase) { $s.PartPhrase } else { (T 'Revisando el hardware…') }
        $button.Opacity = 0
        $button.IsHitTestVisible = $false
        Set-AfHeroFraction -Window $Window -Fraction ($done / [math]::Max(1.0, $total)) -Motion $motion -HideNeedle
    } else {
        $summary = Get-AfSummary -Results $results
        $verdict = Get-AfVerdict -Results $results
        Set-AfCountUp -Block $Window.FindName('HeroNumber') -To $summary.Ok -Motion $motion
        $Window.FindName('HeroUnit').Text = (T 'en orden')
        if ($s.Phase -eq 'ready') {
            $title = if ($verdict.Celebrate) { (T 'Esta PC está afinada') } elseif ($summary.Ready -eq 1) { (T '1 cambio listo') } elseif ($summary.Ready -gt 1) { (T '{0} cambios listos') -f $summary.Ready } else { $verdict.Title }
            $text = switch ($summary.Manual) { 0 { (T 'Nada para hacer a mano.') } 1 { (T '1 para hacer a mano.') } default { (T '{0} para hacer a mano.') -f $summary.Manual } }
            if ($verdict.Title -eq (T 'Revisa el disco')) { $title = $verdict.Title }
        } else {
            $title = $Window.FindName('Title').Text
            $text = Get-AfBlockText -Block $Window.FindName('Summary')
        }
        $Window.FindName('HeroTitle').Text = $title
        $Window.FindName('HeroText').Text = $text
        $Window.FindName('HeroButtonText').Text = if ($summary.Ready -gt 0 -and $s.Phase -eq 'ready') { (T 'Revisar y optimizar') } else { (T 'Ver el detalle') }
        $button.IsHitTestVisible = $true
        Start-AfAnimation -Target $button -Property ([System.Windows.UIElement]::OpacityProperty) -To 1 -DurationMs 300 -Ease Out -Enabled $motion | Out-Null
        Set-AfHeroFraction -Window $Window -Fraction (Get-AfScore -Results $results) -Motion $motion
    }
    foreach ($id in 'history', 'rescan') {
        $card = $s.QuickCards[$id]
        if (-not $card) { continue }
        $on = $s.Phase -in 'ready', 'done'
        $card.IsHitTestVisible = $on
        $card.Opacity = if ($on) { 1 } else { 0.45 }
    }
    Update-AfRadar -Window $Window -Results $results -Motion $motion
}

# Perfil por categoría: qué parte de lo que Afina ajusta en cada una ya está en orden (la misma cuenta que la aguja).
function New-AfRadar {
    param([Parameter(Mandatory)]$Window)
    $canvas = $Window.FindName('Radar')
    $canvas.Children.Clear()
    $axes = @(Get-AfRadarAxes)
    $cx = 150
    $cy = 96
    $r = 64
    $vertex = { param($k, $f) New-Object System.Windows.Point(($cx + $r * $f * [math]::Cos((-90 + 60 * $k) * [math]::PI / 180)), ($cy + $r * $f * [math]::Sin((-90 + 60 * $k) * [math]::PI / 180))) }
    foreach ($f in 0.25, 0.5, 0.75, 1) {
        $ring = New-Object System.Windows.Shapes.Polygon
        $ring.StrokeThickness = 1
        $ring.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, $(if ($f -eq 1) { 'Line2' } else { 'Line' }))
        for ($k = 0; $k -lt 6; $k++) { $ring.Points.Add((& $vertex $k $f)) }
        [void]$canvas.Children.Add($ring)
    }
    for ($k = 0; $k -lt 6; $k++) {
        $spoke = New-Object System.Windows.Shapes.Line
        $end = & $vertex $k 1
        $spoke.X1 = $cx
        $spoke.Y1 = $cy
        $spoke.X2 = $end.X
        $spoke.Y2 = $end.Y
        $spoke.StrokeThickness = 1
        $spoke.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, 'Line')
        [void]$canvas.Children.Add($spoke)
    }
    $shape = New-Object System.Windows.Shapes.Polygon
    $shape.StrokeThickness = 1.5
    $shape.StrokeLineJoin = 'Round'
    $shape.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'RadarFill')
    $shape.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, 'Text')
    [void]$canvas.Children.Add($shape)
    $dots = @()
    $labels = @()
    $categories = @(Get-AfCategories)
    for ($k = 0; $k -lt 6; $k++) {
        $dot = New-Object System.Windows.Shapes.Ellipse
        $dot.Width = 7
        $dot.Height = 7
        $dot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Text')
        [void]$canvas.Children.Add($dot)
        $dots += $dot
        $category = @($categories | Where-Object { $_.Id -eq $axes[$k] })[0]
        $label = New-AfText -Text $category.Name -Size 11.5 -Brush 'Text2'
        $label.TextWrapping = 'NoWrap'
        $label.Cursor = 'Hand'
        $label.Tag = $category.Id
        $label.ToolTip = ''
        $label.Add_MouseLeftButtonUp({ param($sender, $e) Set-AfFilter -Window ([System.Windows.Window]::GetWindow($sender)) -Filter $sender.Tag })
        $label.Add_MouseEnter({ param($sender, $e) $sender.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Text') })
        $label.Add_MouseLeave({ param($sender, $e) $sender.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Text2') })
        $label.Measure((New-Object System.Windows.Size([double]::PositiveInfinity, [double]::PositiveInfinity)))
        $at = & $vertex $k 1.2
        $angle = -90 + 60 * $k
        $left = if ($angle -eq -90 -or $angle -eq 90) { $at.X - $label.DesiredSize.Width / 2 } elseif ([math]::Cos($angle * [math]::PI / 180) -gt 0) { $at.X } else { $at.X - $label.DesiredSize.Width }
        $top = if ($angle -eq -90) { $at.Y - $label.DesiredSize.Height + 2 } elseif ($angle -eq 90) { $at.Y - 2 } else { $at.Y - $label.DesiredSize.Height / 2 }
        [System.Windows.Controls.Canvas]::SetLeft($label, $left)
        [System.Windows.Controls.Canvas]::SetTop($label, $top)
        [void]$canvas.Children.Add($label)
        $labels += $label
    }
    $Window.Tag.Radar = @{ Shape = $shape; Dots = $dots; Labels = $labels; Values = @(0, 0, 0, 0, 0, 0); Center = (New-Object System.Windows.Point($cx, $cy)); Radius = $r }
    Set-AfRadarShape -Window $Window -Values @(0, 0, 0, 0, 0, 0)
}

function Set-AfRadarShape {
    param([Parameter(Mandatory)]$Window, [double[]]$Values)
    $radar = $Window.Tag.Radar
    $points = New-Object System.Windows.Media.PointCollection
    for ($k = 0; $k -lt 6; $k++) {
        $f = [math]::Max(0.04, $Values[$k])
        $angle = (-90 + 60 * $k) * [math]::PI / 180
        $p = New-Object System.Windows.Point(($radar.Center.X + $radar.Radius * $f * [math]::Cos($angle)), ($radar.Center.Y + $radar.Radius * $f * [math]::Sin($angle)))
        $points.Add($p)
        [System.Windows.Controls.Canvas]::SetLeft($radar.Dots[$k], $p.X - 3.5)
        [System.Windows.Controls.Canvas]::SetTop($radar.Dots[$k], $p.Y - 3.5)
    }
    $radar.Shape.Points = $points
    $radar.Values = $Values
}

function Update-AfRadar {
    param([Parameter(Mandatory)]$Window, [object[]]$Results = @(), [bool]$Motion = $false)
    $s = $Window.Tag
    $radar = $s.Radar
    if (-not $radar) { return }
    $axes = @(Get-AfRadarAxes)
    $target = New-Object double[] 6
    for ($k = 0; $k -lt 6; $k++) {
        $id = $axes[$k]
        $mine = @($Results | Where-Object { $_.Check.Category -eq $id })
        $counted = @($mine | Where-Object { Test-AfCountsForScore $_ })
        $seen = $mine.Count -gt 0 -or $s.Phase -ne 'scanning'
        $target[$k] = if (-not $seen) { 0 } else { Get-AfScore -Results $mine }
        $pending = Get-AfPendingCount -Category $id -Results $Results
        $radar.Dots[$k].SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $(if ($pending -gt 0) { 'Red' } else { 'Text' }))
        $ok = @($counted | Where-Object { $_.Detection.State -eq 'Ok' }).Count
        $radar.Labels[$k].ToolTip = if ($counted.Count) { (T '{0} de {1} en orden') -f $ok, $counted.Count } elseif ($seen) { (T 'Nada para ajustar') } else { $null }
    }
    if ($radar.Timer) { $radar.Timer.Stop() }
    if (-not $Motion) { Set-AfRadarShape -Window $Window -Values $target; return }
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(16)
    $timer.Tag = @{ Window = $Window; From = @($radar.Values); To = $target; Start = Get-Date }
    $timer.Add_Tick({ param($sender, $e)
            $st = $sender.Tag
            $t = [math]::Min(1.0, ((Get-Date) - $st.Start).TotalMilliseconds / 520)
            $ease = 1 - [math]::Pow(1 - $t, 3)
            $now = New-Object double[] 6
            for ($k = 0; $k -lt 6; $k++) { $now[$k] = $st.From[$k] + ($st.To[$k] - $st.From[$k]) * $ease }
            Set-AfRadarShape -Window $st.Window -Values $now
            if ($t -ge 1) { $sender.Stop() }
        })
    $radar.Timer = $timer
    $timer.Start()
}
