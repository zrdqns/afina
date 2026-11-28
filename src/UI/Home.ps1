# Resumen (panel de inicio), logo, pantalla de entrada y barra lateral que se despliega.

# Esfera de instrumento: marcas alrededor del centro, aguja roja que gira sobre él y un eje rojo.
# Los ángulos se miden como en un reloj: 0 arriba y en sentido horario. -Fixed usa colores fijos (icono de la ventana).
function New-AfDial {
    param(
        [double]$Width = 64, [double]$Height = 64, [double]$CenterY = -1,
        [int]$Ticks = 12, [double]$Start = 0, [double]$Sweep = 360, [double]$Radius = 29,
        [double]$MinorLength = 6, [double]$MinorWidth = 3, [double]$MinorOpacity = 0.55,
        [int]$MajorEvery = 3, [double]$MajorLength = 9, [double]$MajorWidth = 4, [double]$MajorOpacity = 0.95,
        [double]$HandLength = 24, [double]$HandTail = 8, [double]$HandWidth = 5, [double]$HubSize = 9, [double]$HandAngle = 45,
        [switch]$Fixed
    )
    $cx = $Width / 2
    $cy = if ($CenterY -ge 0) { $CenterY } else { $Height / 2 }
    $canvas = New-Object System.Windows.Controls.Canvas
    $canvas.Width = $Width
    $canvas.Height = $Height
    $paint = {
        param($shape, [string]$Key)
        if (-not $Fixed) { $shape.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $Key); return }
        $shape.Fill = switch ($Key) { 'Red' { New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 59, 71)) } 'Bg' { New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(20, 20, 22)) } default { [System.Windows.Media.Brushes]::WhiteSmoke } }
    }
    $marks = New-Object System.Collections.ArrayList
    $steps = if ($Sweep -ge 360) { $Ticks } else { [math]::Max(1, $Ticks - 1) }
    for ($k = 0; $k -lt $Ticks; $k++) {
        $major = $MajorEvery -gt 0 -and $k % $MajorEvery -eq 0
        $length = if ($major) { $MajorLength } else { $MinorLength }
        $thick = if ($major) { $MajorWidth } else { $MinorWidth }
        $angle = $Start + $Sweep * $k / $steps
        $tick = New-Object System.Windows.Shapes.Rectangle
        $tick.Width = $thick
        $tick.Height = $length
        $tick.RadiusX = $thick / 2
        $tick.RadiusY = $thick / 2
        & $paint $tick 'Text'
        $tick.Opacity = if ($major) { $MajorOpacity } else { $MinorOpacity }
        [System.Windows.Controls.Canvas]::SetLeft($tick, $cx - $thick / 2)
        [System.Windows.Controls.Canvas]::SetTop($tick, $cy - $Radius)
        $tick.RenderTransform = New-Object System.Windows.Media.RotateTransform($angle, ($thick / 2), $Radius)
        [void]$canvas.Children.Add($tick)
        [void]$marks.Add([pscustomobject]@{ Shape = $tick; Angle = $angle; Major = $major; Base = $tick.Opacity })
    }
    # Aguja afinada hacia la punta, con una cola corta del otro lado del eje.
    $hand = New-Object System.Windows.Shapes.Polygon
    $w = $HandWidth
    foreach ($p in @(@((-$w * 0.32), $HandTail), @(($w * 0.32), $HandTail), @(($w / 2), 0), @(($w * 0.14), (-$HandLength)), @((-$w * 0.14), (-$HandLength)), @((-$w / 2), 0))) {
        $hand.Points.Add((New-Object System.Windows.Point(($cx + $p[0]), ($cy + $p[1]))))
    }
    & $paint $hand 'Red'
    $hand.RenderTransform = New-Object System.Windows.Media.RotateTransform($HandAngle, $cx, $cy)
    [void]$canvas.Children.Add($hand)
    $hub = New-Object System.Windows.Controls.Grid
    $hub.Width = $HubSize
    $hub.Height = $HubSize
    $outer = New-Object System.Windows.Shapes.Ellipse
    & $paint $outer 'Red'
    $inner = New-Object System.Windows.Shapes.Ellipse
    $inner.Width = $HubSize * 0.42
    $inner.Height = $HubSize * 0.42
    & $paint $inner 'Bg'
    [void]$hub.Children.Add($outer)
    [void]$hub.Children.Add($inner)
    [System.Windows.Controls.Canvas]::SetLeft($hub, $cx - $HubSize / 2)
    [System.Windows.Controls.Canvas]::SetTop($hub, $cy - $HubSize / 2)
    $hub.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
    $hub.RenderTransform = New-Object System.Windows.Media.ScaleTransform(1, 1)
    [void]$canvas.Children.Add($hub)
    $canvas.Tag = [pscustomobject]@{ Ticks = $marks; Hand = $hand; Hub = $hub; Center = (New-Object System.Windows.Point($cx, $cy)) }
    $canvas
}

# Marca de Afina: la esfera negra de un cronógrafo con doce marcas y la aguja roja apuntando arriba a la derecha.
function New-AfLogoMark {
    param([double]$Size = 64, [switch]$Fixed)
    $box = New-Object System.Windows.Controls.Viewbox
    $box.Width = $Size
    $box.Height = $Size
    $box.Child = New-AfDial -Fixed:$Fixed
    $box
}

# Icono de la ventana y de la barra de tareas: la marca sobre un cuadrado negro.
function New-AfLogoImage {
    $tile = New-Object System.Windows.Controls.Border
    $tile.Width = 64
    $tile.Height = 64
    $tile.CornerRadius = 14
    $tile.Background = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(20, 20, 22))
    $mark = New-AfLogoMark -Size 52 -Fixed
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

# Recorrido de una curva suave (seno): de 0 a 1 en el tiempo t de 0 a 1, y al revés.
function Get-AfSweepAt { param([double]$T) (1 - [math]::Cos([math]::PI * $T)) / 2 }
function Get-AfSweepTime { param([double]$Fraction) [math]::Acos(1 - 2 * [math]::Max(0.0, [math]::Min(1.0, $Fraction))) / [math]::PI }

function New-AfKeyFrame {
    param([double]$Value, [double]$At, [string]$Ease)
    $time = [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds($At))
    if ($Ease) { New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame($Value, $time, (New-AfKeySpline -Ease $Ease)) } else { New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame($Value, $time) }
}

# Pantalla de entrada: una esfera grande que se arma en el centro de la ventana, la aguja da una vuelta completa
# y se asienta; después la esfera se achica a la izquierda del nombre, que entra letra por letra.
function Initialize-AfSplash {
    param([Parameter(Mandatory)]$Window, [bool]$Motion = $false)
    $dial = New-AfDial -Width 360 -Height 360 -Ticks 60 -Radius 168 -MinorLength 14 -MinorWidth 2.4 -MinorOpacity 0.3 -MajorEvery 5 -MajorLength 30 -MajorWidth 5.5 -MajorOpacity 0.95 -HandLength 146 -HandTail 34 -HandWidth 9 -HubSize 24
    # Bisel: un aro fino que se dibuja en sentido horario desde arriba.
    $ring = New-Object System.Windows.Shapes.Path
    $ring.Data = [System.Windows.Media.Geometry]::Parse('M180,2 A178,178 0 1 1 179.99,2')
    $ring.StrokeThickness = 1.5
    $ring.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, 'Line2')
    $ring.StrokeDashArray = New-Object System.Windows.Media.DoubleCollection
    $ringLength = 2 * [math]::PI * 178 / 1.5
    $ring.StrokeDashArray.Add($ringLength)
    $ring.StrokeDashArray.Add($ringLength)
    $dial.Children.Insert(0, $ring)
    $box = New-Object System.Windows.Controls.Viewbox
    $box.Child = $dial
    $Window.FindName('SplashDialHost').Child = $box
    $letters = $Window.FindName('SplashLetters')
    $letters.Children.Clear()
    foreach ($char in 'Afina'.ToCharArray()) {
        $letter = New-Object System.Windows.Controls.TextBlock
        $letter.Text = [string]$char
        $letter.FontSize = 68
        $letter.FontWeight = 'Light'
        $letter.SetResourceReference([System.Windows.Controls.TextBlock]::FontFamilyProperty, 'DisplayFont')
        $letter.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Text')
        $letter.RenderTransform = New-Object System.Windows.Media.TranslateTransform(0, 0)
        [void]$letters.Children.Add($letter)
    }
    $Window.FindName('SplashVersion').Text = 'v' + (Get-AfVersion)
    $Window.Tag.SplashParts = [pscustomobject]@{ Dial = $dial.Tag; Ring = $ring; RingLength = $ringLength }
    if (-not $Motion) { return }
    # Todo empieza escondido; Start-AfSplash lo arma con el primer cuadro.
    foreach ($tick in $dial.Tag.Ticks) { $tick.Shape.Opacity = 0 }
    $dial.Tag.Hand.Opacity = 0
    $dial.Tag.Hand.RenderTransform.Angle = 0
    $dial.Tag.Hub.RenderTransform.ScaleX = 0
    $dial.Tag.Hub.RenderTransform.ScaleY = 0
    $ring.StrokeDashOffset = $ringLength
    foreach ($letter in $letters.Children) { $letter.Opacity = 0 }
    foreach ($name in 'SplashTag', 'SplashVersion') { $Window.FindName($name).Opacity = 0 }
    # El Resumen entra después, pieza por pieza (Start-AfHomeEntrance).
    foreach ($element in @(Get-AfHomeEntranceElements -Window $Window)) { $element.Opacity = 0 }
}

function Start-AfSplash {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $splash = $Window.FindName('Splash')
    if ($splash.Visibility -ne 'Visible') { return }
    $splash.Add_MouseLeftButtonUp({ param($sender, $e) Hide-AfSplash -Window ([System.Windows.Window]::GetWindow($sender)) })
    $parts = $s.SplashParts
    $hold = 1000
    if ($s.Motion -and $parts) {
        $hold = 3150
        $dial = $parts.Dial
        # La esfera empieza grande y centrada en la ventana; al final vuelve a su lugar junto al nombre.
        $splash.UpdateLayout()
        $dialHost = $Window.FindName('SplashDialHost')
        $origin = $dialHost.TranslatePoint((New-Object System.Windows.Point(0, 0)), $splash)
        $big = [math]::Min(3.2, [math]::Max(1.6, ($splash.ActualHeight * 0.6) / $dialHost.ActualHeight))
        $scale = New-Object System.Windows.Media.ScaleTransform($big, $big)
        $move = New-Object System.Windows.Media.TranslateTransform(($splash.ActualWidth / 2 - ($origin.X + $dialHost.ActualWidth / 2)), ($splash.ActualHeight / 2 - ($origin.Y + $dialHost.ActualHeight / 2)))
        $group = New-Object System.Windows.Media.TransformGroup
        $group.Children.Add($scale)
        $group.Children.Add($move)
        $dialHost.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
        $dialHost.RenderTransform = $group
        Start-AfAnimation -Target $parts.Ring -Property ([System.Windows.Shapes.Shape]::StrokeDashOffsetProperty) -From $parts.RingLength -To 0 -DurationMs 900 -Ease Out | Out-Null
        # Las marcas aparecen en sentido horario; la aguja da una vuelta y cuarto, y cada marca brilla cuando pasa.
        $sweepStart = 520
        $sweepMs = 1050
        $rest = 405
        foreach ($tick in $dial.Ticks) {
            $appear = 60 + 9 * [math]::Round($tick.Angle / 6)
            $frames = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
            [void]$frames.KeyFrames.Add((New-AfKeyFrame -Value 0 -At 0))
            [void]$frames.KeyFrames.Add((New-AfKeyFrame -Value 0 -At $appear))
            [void]$frames.KeyFrames.Add((New-AfKeyFrame -Value $tick.Base -At ($appear + 220) -Ease Out))
            foreach ($pass in @($tick.Angle, ($tick.Angle + 360))) {
                if ($pass -gt $rest) { continue }
                $at = $sweepStart + $sweepMs * (Get-AfSweepTime -Fraction ($pass / $rest))
                [void]$frames.KeyFrames.Add((New-AfKeyFrame -Value $tick.Base -At ([math]::Max($appear + 230, $at - 40))))
                [void]$frames.KeyFrames.Add((New-AfKeyFrame -Value 1 -At ([math]::Max($appear + 240, $at))))
                [void]$frames.KeyFrames.Add((New-AfKeyFrame -Value $tick.Base -At ([math]::Max($appear + 250, $at) + 560) -Ease Out))
            }
            $tick.Shape.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $frames)
        }
        $hand = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $hand.BeginTime = [TimeSpan]::FromMilliseconds($sweepStart)
        for ($i = 0; $i -le 24; $i++) { [void]$hand.KeyFrames.Add((New-AfKeyFrame -Value ($rest * (Get-AfSweepAt -T ($i / 24))) -At ($sweepMs * $i / 24))) }
        # Un tic mecánico al llegar: se pasa un poco y vuelve.
        [void]$hand.KeyFrames.Add((New-AfKeyFrame -Value ($rest + 5) -At ($sweepMs + 70) -Ease Out))
        [void]$hand.KeyFrames.Add((New-AfKeyFrame -Value $rest -At ($sweepMs + 240) -Ease Out))
        $dial.Hand.RenderTransform.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $hand)
        Start-AfAnimation -Target $dial.Hand -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 220 -DelayMs ($sweepStart - 120) -Ease Out | Out-Null
        foreach ($axis in [System.Windows.Media.ScaleTransform]::ScaleXProperty, [System.Windows.Media.ScaleTransform]::ScaleYProperty) {
            $pop = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
            $pop.BeginTime = [TimeSpan]::FromMilliseconds($sweepStart - 140)
            [void]$pop.KeyFrames.Add((New-AfKeyFrame -Value 1.25 -At 220 -Ease Out))
            [void]$pop.KeyFrames.Add((New-AfKeyFrame -Value 1 -At 420 -Ease Out))
            $dial.Hub.RenderTransform.BeginAnimation($axis, $pop)
        }
        # La esfera se achica hacia su lugar y entra el nombre, letra por letra.
        $settleAt = $sweepStart + $sweepMs + 220
        foreach ($axis in [System.Windows.Media.ScaleTransform]::ScaleXProperty, [System.Windows.Media.ScaleTransform]::ScaleYProperty) {
            Start-AfAnimation -Target $scale -Property $axis -To 1 -DurationMs 720 -DelayMs $settleAt -Ease InOut | Out-Null
        }
        Start-AfAnimation -Target $move -Property ([System.Windows.Media.TranslateTransform]::XProperty) -To 0 -DurationMs 720 -DelayMs $settleAt -Ease InOut | Out-Null
        Start-AfAnimation -Target $move -Property ([System.Windows.Media.TranslateTransform]::YProperty) -To 0 -DurationMs 720 -DelayMs $settleAt -Ease InOut | Out-Null
        $k = 0
        foreach ($letter in $Window.FindName('SplashLetters').Children) {
            $delay = $settleAt + 380 + 70 * $k
            Start-AfAnimation -Target $letter -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 380 -DelayMs $delay -Ease Out | Out-Null
            Start-AfAnimation -Target $letter.RenderTransform -Property ([System.Windows.Media.TranslateTransform]::YProperty) -From 26 -To 0 -DurationMs 620 -DelayMs $delay -Ease Out | Out-Null
            $k++
        }
        Start-AfAnimation -Target $Window.FindName('SplashTag') -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 520 -DelayMs ($settleAt + 760) -Ease Out | Out-Null
        Start-AfAnimation -Target $Window.FindName('SplashVersion') -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 520 -DelayMs ($settleAt + 860) -Ease Out | Out-Null
    }
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds($hold)
    $timer.Tag = $Window
    $timer.Add_Tick({ param($sender, $e) $sender.Stop(); Hide-AfSplash -Window $sender.Tag })
    $timer.Start()
}

function Hide-AfSplash {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    # SplashPinned: la deja fija para capturarla (tools\Show-AfDemo.ps1 -AutoPlay).
    if ($s.SplashGone -or $s.SplashPinned) { return }
    $s.SplashGone = $true
    $splash = $Window.FindName('Splash')
    if (-not $s.Motion) { $splash.Visibility = 'Collapsed'; return }
    $splash.IsHitTestVisible = $false
    $zoom = New-Object System.Windows.Media.ScaleTransform(1, 1)
    $content = $Window.FindName('SplashContent')
    $content.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
    $content.RenderTransform = $zoom
    Start-AfAnimation -Target $zoom -Property ([System.Windows.Media.ScaleTransform]::ScaleXProperty) -To 0.94 -DurationMs 460 -Ease Out | Out-Null
    Start-AfAnimation -Target $zoom -Property ([System.Windows.Media.ScaleTransform]::ScaleYProperty) -To 0.94 -DurationMs 460 -Ease Out | Out-Null
    Start-AfAnimation -Target $splash -Property ([System.Windows.UIElement]::OpacityProperty) -To 0 -DurationMs 460 -Ease Out | Out-Null
    Start-AfHomeEntrance -Window $Window -DelayMs 140
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(480)
    $timer.Tag = $splash
    $timer.Add_Tick({ param($sender, $e) $sender.Stop(); $sender.Tag.Visibility = 'Collapsed' })
    $timer.Start()
}

# Lo que entra pieza por pieza al aparecer el Resumen: encabezado, tarjetas, acciones y estadísticas.
function Get-AfHomeEntranceElements {
    param([Parameter(Mandatory)]$Window)
    foreach ($name in 'PcHeader', 'HeroCard', 'ProfileCard', 'QuickLabel') { $Window.FindName($name) }
    foreach ($card in $Window.FindName('Quick').Children) { $card }
    $Window.FindName('LiveHeader')
    foreach ($tile in $Window.FindName('Live').Children) { $tile }
}

function Start-AfHomeEntrance {
    param([Parameter(Mandatory)]$Window, [int]$DelayMs = 0)
    $k = 0
    foreach ($element in @(Get-AfHomeEntranceElements -Window $Window)) {
        $shift = New-Object System.Windows.Media.TranslateTransform(0, 18)
        $element.RenderTransform = $shift
        $delay = $DelayMs + 55 * $k
        Start-AfAnimation -Target $element -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 420 -DelayMs $delay -Ease Out | Out-Null
        Start-AfAnimation -Target $shift -Property ([System.Windows.Media.TranslateTransform]::YProperty) -From 18 -To 0 -DurationMs 560 -DelayMs $delay -Ease Out | Out-Null
        $k++
    }
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
    Initialize-AfHeroDial -Window $Window
    if (-not $s.HomeReady) {
        $s.HomeReady = $true
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

# Medidor principal: una esfera de 270° con 44 marcas que se encienden hasta la fracción y la aguja roja.
# Mientras analiza, un destello recorre el aro exterior y las marcas siguen el avance.
function Initialize-AfHeroDial {
    param([Parameter(Mandatory)]$Window)
    $hostGrid = $Window.FindName('HeroDialHost')
    $old = @($hostGrid.Children | Where-Object { $_ -is [System.Windows.Controls.Canvas] })
    foreach ($canvas in $old) { $hostGrid.Children.Remove($canvas) }
    $dial = New-AfDial -Width 212 -Height 200 -CenterY 102 -Ticks 44 -Start -135 -Sweep 270 -Radius 90 -MinorLength 13 -MinorWidth 4 -MinorOpacity 0.12 -MajorEvery 0 -HandLength 60 -HandTail 14 -HandWidth 6 -HubSize 15 -HandAngle -135
    $dial.IsHitTestVisible = $false
    $last = $dial.Tag.Ticks[$dial.Tag.Ticks.Count - 1].Shape
    $last.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Red')
    $last.Opacity = 1
    $arc = 'M{0},{1} A100,100 0 1 1 {2},{1}' -f (106 - 70.71).ToString([System.Globalization.CultureInfo]::InvariantCulture), (102 + 70.71).ToString([System.Globalization.CultureInfo]::InvariantCulture), (106 + 70.71).ToString([System.Globalization.CultureInfo]::InvariantCulture)
    $track = New-Object System.Windows.Shapes.Path
    $track.Data = [System.Windows.Media.Geometry]::Parse($arc)
    $track.StrokeThickness = 1.5
    $track.StrokeStartLineCap = 'Round'
    $track.StrokeEndLineCap = 'Round'
    $track.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, 'Line2')
    $comet = New-Object System.Windows.Shapes.Path
    $comet.Data = $track.Data
    $comet.StrokeThickness = 2.5
    $comet.StrokeStartLineCap = 'Round'
    $comet.StrokeEndLineCap = 'Round'
    $comet.StrokeDashCap = 'Round'
    $comet.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, 'Text')
    $length = (2 * [math]::PI * 100 * 0.75) / 2.5
    $comet.StrokeDashArray = New-Object System.Windows.Media.DoubleCollection
    $comet.StrokeDashArray.Add(14)
    $comet.StrokeDashArray.Add($length + 14)
    $comet.Opacity = 0
    $dial.Children.Insert(0, $track)
    $dial.Children.Insert(1, $comet)
    foreach ($label in @(@('Desafinado', 42), @('Afinado', 170))) {
        $text = New-AfText -Text (T $label[0]) -Size 11.5 -Brush 'Text3'
        $text.TextWrapping = 'NoWrap'
        $text.Measure((New-Object System.Windows.Size([double]::PositiveInfinity, [double]::PositiveInfinity)))
        [System.Windows.Controls.Canvas]::SetLeft($text, $label[1] - $text.DesiredSize.Width / 2)
        [System.Windows.Controls.Canvas]::SetTop($text, 182)
        [void]$dial.Children.Add($text)
    }
    $hostGrid.Children.Insert(0, $dial)
    $Window.Tag.HeroDial = [pscustomobject]@{ Ticks = $dial.Tag.Ticks; Hand = $dial.Tag.Hand; Comet = $comet; CometLength = $length; Fraction = 0.0 }
}

# Enciende las marcas hasta la fracción (más claras hacia el final) y lleva la aguja al mismo lugar.
function Set-AfHeroFraction {
    param([Parameter(Mandatory)]$Window, [double]$Fraction, [bool]$Motion = $false, [switch]$Force, [switch]$Scanning)
    $dial = $Window.Tag.HeroDial
    if (-not $dial) { return }
    $f = [math]::Max(0.0, [math]::Min(1.0, $Fraction))
    $previous = [double]$dial.Fraction
    $dial.Fraction = $f
    $count = $dial.Ticks.Count
    $upTo = [math]::Round($f * ($count - 1))
    $from = [math]::Round($previous * ($count - 1))
    for ($i = 0; $i -lt $count - 1; $i++) {
        $target = if ($i -le $upTo -and $f -gt 0) { 0.4 + 0.6 * $i / ($count - 1) } else { 0.12 }
        $shape = $dial.Ticks[$i].Shape
        if (-not $Force -and [math]::Abs($shape.Opacity - $target) -lt 0.01) { continue }
        $delay = if ($Motion) { [math]::Abs($i - $from) * 16 } else { 0 }
        Start-AfAnimation -Target $shape -Property ([System.Windows.UIElement]::OpacityProperty) -To $target -DurationMs 260 -DelayMs $delay -Ease Out -Enabled $Motion | Out-Null
    }
    Start-AfAnimation -Target $dial.Hand.RenderTransform -Property ([System.Windows.Media.RotateTransform]::AngleProperty) -To (-135 + 270 * $f) -DurationMs $(if ($Scanning) { 520 } else { 900 }) -Ease $(if ($Scanning) { 'Out' } else { 'InOut' }) -Enabled $Motion | Out-Null
    Set-AfHeroScanning -Window $Window -On ([bool]$Scanning) -Motion $Motion
}

# El destello del aro y el barrido del radar: solo mientras analiza y con animaciones.
function Set-AfHeroScanning {
    param([Parameter(Mandatory)]$Window, [bool]$On, [bool]$Motion = $false)
    $s = $Window.Tag
    $on = $On -and $Motion
    if ([bool]$s.ScanFx -eq $on) { return }
    $s.ScanFx = $on
    $dial = $s.HeroDial
    $beam = if ($s.Radar) { $s.Radar.Beam } else { $null }
    if ($on) {
        if ($dial) {
            $run = New-Object System.Windows.Media.Animation.DoubleAnimation(14, (-$dial.CometLength), (New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(1500))))
            $run.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $dial.Comet.BeginAnimation([System.Windows.Shapes.Shape]::StrokeDashOffsetProperty, $run)
            Start-AfAnimation -Target $dial.Comet -Property ([System.Windows.UIElement]::OpacityProperty) -To 0.9 -DurationMs 300 -Ease Out | Out-Null
        }
        if ($beam) {
            $spin = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 360, (New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(2200))))
            $spin.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $beam.RenderTransform.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $spin)
            Start-AfAnimation -Target $beam -Property ([System.Windows.UIElement]::OpacityProperty) -To 1 -DurationMs 300 -Ease Out | Out-Null
        }
    } else {
        if ($dial) { Start-AfAnimation -Target $dial.Comet -Property ([System.Windows.UIElement]::OpacityProperty) -To 0 -DurationMs 400 -Ease Out -Enabled $Motion | Out-Null }
        if ($beam) { Start-AfAnimation -Target $beam -Property ([System.Windows.UIElement]::OpacityProperty) -To 0 -DurationMs 500 -Ease Out -Enabled $Motion | Out-Null }
    }
}

# Al quedar afinada, una ola recorre las marcas encendidas.
function Start-AfHeroCelebration {
    param([Parameter(Mandatory)]$Window)
    $dial = $Window.Tag.HeroDial
    if (-not $dial) { return }
    $i = 0
    foreach ($tick in @($dial.Ticks | Select-Object -SkipLast 1)) {
        $wave = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $wave.BeginTime = [TimeSpan]::FromMilliseconds($i * 14)
        [void]$wave.KeyFrames.Add((New-AfKeyFrame -Value 1 -At 140 -Ease Out))
        [void]$wave.KeyFrames.Add((New-AfKeyFrame -Value $tick.Shape.Opacity -At 620 -Ease Out))
        $tick.Shape.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $wave)
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
        Set-AfHeroFraction -Window $Window -Fraction ($done / [math]::Max(1.0, $total)) -Motion $motion -Scanning
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
    # Barrido de radar mientras analiza: una cuña que gira con el borde delantero marcado.
    $beam = New-Object System.Windows.Controls.Canvas
    $wedge = New-Object System.Windows.Shapes.Path
    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    # Radio 64, el mismo de $r (escrito en el trazado).
    $wedge.Data = [System.Windows.Media.Geometry]::Parse(('M{0},{1} L{2},{3} A64,64 0 0 1 {0},{4} Z' -f $cx.ToString($inv), $cy.ToString($inv), ($cx - 0.866 * $r).ToString($inv), ($cy - 0.5 * $r).ToString($inv), ($cy - $r).ToString($inv)))
    $wedge.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'BeamFill')
    $edge = New-Object System.Windows.Shapes.Line
    $edge.X1 = $cx
    $edge.Y1 = $cy
    $edge.X2 = $cx
    $edge.Y2 = $cy - $r
    $edge.StrokeThickness = 1.2
    $edge.Opacity = 0.75
    $edge.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, 'Text')
    [void]$beam.Children.Add($wedge)
    [void]$beam.Children.Add($edge)
    $beam.RenderTransform = New-Object System.Windows.Media.RotateTransform(0, $cx, $cy)
    $beam.Opacity = 0
    $beam.IsHitTestVisible = $false
    [void]$canvas.Children.Add($beam)
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
        $dot.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
        $dot.RenderTransform = New-Object System.Windows.Media.ScaleTransform(1, 1)
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
    $Window.Tag.Radar = @{ Shape = $shape; Dots = $dots; Labels = $labels; Beam = $beam; Seen = @($false, $false, $false, $false, $false, $false); Values = @(0, 0, 0, 0, 0, 0); Center = (New-Object System.Windows.Point($cx, $cy)); Radius = $r }
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
        # Cada categoría que llega hace saltar su punto.
        if ($seen -and -not $radar.Seen[$k] -and $Motion) {
            foreach ($axis in [System.Windows.Media.ScaleTransform]::ScaleXProperty, [System.Windows.Media.ScaleTransform]::ScaleYProperty) {
                $pop = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
                [void]$pop.KeyFrames.Add((New-AfKeyFrame -Value 1.9 -At 160 -Ease Out))
                [void]$pop.KeyFrames.Add((New-AfKeyFrame -Value 1 -At 460 -Ease Out))
                $radar.Dots[$k].RenderTransform.BeginAnimation($axis, $pop)
            }
        }
        $radar.Seen[$k] = $seen
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
