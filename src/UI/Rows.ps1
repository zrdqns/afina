function Get-AfRowXaml {
    @'
<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="RowRoot" Padding="18,11,18,11" Cursor="Hand">
  <Border.Style>
    <Style TargetType="Border">
      <Setter Property="Background" Value="Transparent"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="{DynamicResource Raised}"/>
        </Trigger>
      </Style.Triggers>
    </Style>
  </Border.Style>
  <Border.RenderTransform><TranslateTransform x:Name="RowShift"/></Border.RenderTransform>
  <Grid>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="18"/>
      <ColumnDefinition Width="14"/>
      <ColumnDefinition Width="*"/>
      <ColumnDefinition Width="Auto"/>
    </Grid.ColumnDefinitions>
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <Rectangle x:Name="Divider" Grid.ColumnSpan="4" Grid.Column="1" Height="1" VerticalAlignment="Top" Margin="0,-11,0,0" Fill="{DynamicResource Line}" Visibility="Collapsed"/>
    <Grid x:Name="Lead" Grid.Column="0" Width="18" Height="18" VerticalAlignment="Top" Margin="0,1,0,0"/>
    <StackPanel Grid.Column="2">
      <TextBlock x:Name="RowTitle" FontSize="13.5" FontWeight="Medium" Foreground="{DynamicResource Text}" TextWrapping="Wrap"/>
      <WrapPanel x:Name="RowSub" Margin="0,3,0,0"/>
      <TextBlock x:Name="RowNote" FontSize="12" Foreground="{DynamicResource Text3}" Margin="0,2,0,0" TextWrapping="Wrap" Visibility="Collapsed"/>
    </StackPanel>
    <StackPanel Grid.Column="3" Orientation="Horizontal" VerticalAlignment="Top" Margin="12,1,0,0">
      <StackPanel x:Name="RowTag" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,14,0" Visibility="Collapsed"/>
      <StackPanel x:Name="Bars" Orientation="Horizontal" VerticalAlignment="Center" Height="12"/>
      <Border x:Name="Caret" Width="24" Height="24" CornerRadius="6" Margin="10,-3,0,0" RenderTransformOrigin="0.5,0.5" Background="Transparent">
        <Border.RenderTransform><RotateTransform x:Name="CaretRotate"/></Border.RenderTransform>
      </Border>
    </StackPanel>
    <Border x:Name="Detail" Grid.Row="1" Grid.Column="2" Grid.ColumnSpan="2" Visibility="Collapsed" ClipToBounds="True" MaxHeight="0"/>
    <StackPanel x:Name="Steps" Grid.Row="2" Grid.Column="2" Grid.ColumnSpan="2" Margin="0,8,0,0" Visibility="Collapsed" ClipToBounds="True" MaxHeight="0"/>
  </Grid>
</Border>
'@
}

function New-AfText {
    param([string]$Text, [double]$Size = 12.5, [string]$Brush = 'Text2', [switch]$Display, [string]$Weight = 'Normal')
    $block = New-Object System.Windows.Controls.TextBlock
    $block.Text = $Text
    $block.FontSize = $Size
    $block.FontWeight = $Weight
    $block.TextWrapping = 'Wrap'
    $block.VerticalAlignment = 'Center'
    if ($Display) { $block.SetResourceReference([System.Windows.Controls.TextBlock]::FontFamilyProperty, 'DisplayFont') }
    $block.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, $Brush)
    $block
}

function New-AfSpinner {
    param([double]$Size = 14)
    $arc = New-Object System.Windows.Shapes.Ellipse
    $arc.Width = $Size
    $arc.Height = $Size
    $arc.StrokeThickness = 1.5
    $arc.StrokeDashArray = [System.Windows.Media.DoubleCollection]::Parse('6 3')
    $arc.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, 'Text2')
    $arc.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
    $rotate = New-Object System.Windows.Media.RotateTransform
    $arc.RenderTransform = $rotate
    $spin = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 360, (New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(700))))
    $spin.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $rotate.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $spin)
    $arc
}

function Get-AfRowCheckBox {
    param([Parameter(Mandatory)]$Row)
    $lead = $Row.FindName('Lead')
    @($lead.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] })[0]
}

function New-AfRowElement {
    param([Parameter(Mandatory)]$Result, [switch]$First)
    $row = [System.Windows.Markup.XamlReader]::Parse((Get-AfRowXaml))
    $row.Tag = $Result
    $check = $Result.Check
    $d = $Result.Detection
    if (-not $First) { $row.FindName('Divider').Visibility = 'Visible' }

    $lead = $row.FindName('Lead')
    $nextVersion = $check.Kind -eq 'Auto' -and $d.State -eq 'Improvable' -and -not (Test-AfCanApply -Check $check)
    if ($d.Data -and $d.Data.Async -and $d.State -eq 'Info') {
        [void]$lead.Children.Add((New-AfSpinner -Size 16))
    } elseif ($nextVersion) {
        [void]$lead.Children.Add((New-AfIcon -Name 'info' -Size 16))
    } elseif ($check.Kind -eq 'Auto' -and $d.State -eq 'Improvable') {
        $box = New-Object System.Windows.Controls.CheckBox
        $box.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'AfCheck')
        $box.IsChecked = [bool]$Result.Preselected
        $box.ToolTip = (T 'Incluir este cambio')
        [void]$lead.Children.Add($box)
    } else {
        $icon = switch ($d.State) {
            'Manual' { New-AfIcon -Name 'wrench' -Size 16 }
            'Info' { New-AfIcon -Name 'info' -Size 16 }
            'Error' { New-AfIcon -Name 'warning-circle' -Size 16 -Brush 'RedText' }
            default { New-AfIcon -Name 'check' -Size 15 }
        }
        [void]$lead.Children.Add($icon)
    }

    $row.FindName('RowTitle').Text = if ($d.Title) { $d.Title } else { $check.Title }

    $sub = $row.FindName('RowSub')
    $note = $d.Note
    if ($check.Risk -eq 'Advanced' -and $d.Note) {
        $risk = New-Object System.Windows.Controls.StackPanel
        $risk.Orientation = 'Horizontal'
        [void]$risk.Children.Add((New-AfIcon -Name 'shield-warning' -Size 14 -Brush 'RedText'))
        $text = New-AfText -Text $d.Note -Brush 'RedText'
        $text.Margin = '6,0,0,0'
        [void]$risk.Children.Add($text)
        [void]$sub.Children.Add($risk)
        $note = $null
    } elseif ($d.Current -and $d.Target) {
        $numeric = $d.Current -match '^\d' -and $d.Target -match '^\d'
        [void]$sub.Children.Add((New-AfText -Text $d.Current -Display:$numeric))
        $arrow = New-AfIcon -Name 'arrow-right' -Size 12
        $arrow.Margin = '7,0,7,0'
        [void]$sub.Children.Add($arrow)
        [void]$sub.Children.Add((New-AfText -Text $d.Target -Brush 'Text' -Display:$numeric))
    } elseif ($d.Current -and $d.State -ne 'Ok') {
        [void]$sub.Children.Add((New-AfText -Text $d.Current))
    } else {
        $sub.Visibility = 'Collapsed'
    }
    if ($note -and $d.State -ne 'Error') {
        $noteBlock = $row.FindName('RowNote')
        $noteBlock.Text = $note
        $noteBlock.Visibility = 'Visible'
    }

    $tag = $row.FindName('RowTag')
    $tagText = $null
    if ($nextVersion) { $tagText = (T 'En la próxima versión'); $tagIcon = 'info' }
    # Que no se deshace va antes que el reinicio: el reinicio ya lo dice la confirmación (diseño, sección 5).
    elseif ($check.NoUndo -and $d.State -eq 'Improvable') { $tagText = (T 'No se puede deshacer'); $tagIcon = 'warning-circle' }
    elseif ($check.NeedsReboot -and $d.State -eq 'Improvable') { $tagText = (T 'Pide reiniciar'); $tagIcon = 'arrow-clockwise' }
    if ($tagText) {
        [void]$tag.Children.Add((New-AfIcon -Name $tagIcon -Size 13))
        $t = New-AfText -Text $tagText -Size 12 -Brush 'Text3'
        $t.Margin = '5,0,0,0'
        [void]$tag.Children.Add($t)
        $tag.Visibility = 'Visible'
    }

    $bars = $row.FindName('Bars')
    $heights = 5, 8, 12
    for ($i = 0; $i -lt 3; $i++) {
        $bar = New-Object System.Windows.Shapes.Rectangle
        $bar.Width = 3
        $bar.Height = $heights[$i]
        $bar.RadiusX = 1
        $bar.RadiusY = 1
        $bar.Margin = '0,0,2,0'
        $bar.VerticalAlignment = 'Bottom'
        $bar.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $(if ($i -lt $Result.Weight) { 'Text' } else { 'Line2' }))
        [void]$bars.Children.Add($bar)
    }
    $bars.ToolTip = @('', (T 'Impacto bajo'), (T 'Impacto medio'), (T 'Impacto alto'))[$Result.Weight]

    $row.FindName('Caret').Child = New-AfIcon -Name 'caret-down' -Size 12
    $row.FindName('Detail').Child = New-AfDetailContent -Result $Result -Row $row
    $row
}

# Opciones dentro del detalle (por ejemplo, qué programas de inicio desactivar). Marcan Selected en los datos de la detección.
function New-AfChoiceList {
    param([Parameter(Mandatory)]$Result, $Row)
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Margin = '0,4,0,2'
    $boxes = New-Object System.Collections.ArrayList
    foreach ($choice in @($Result.Detection.Data.Choices)) {
        $line = New-Object System.Windows.Controls.StackPanel
        $line.Orientation = 'Horizontal'
        $line.Margin = '0,0,0,7'
        $box = New-Object System.Windows.Controls.CheckBox
        $box.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'AfCheck')
        $box.IsChecked = [bool]$choice.Selected
        $box.Tag = @{ Choice = $choice; Row = $Row }
        $box.Add_Click({ param($sender, $e) Sync-AfChoice -Box $sender })
        $label = New-AfText -Text $choice.Label -Size 12.5 -Brush 'Text2'
        $label.Margin = '10,0,0,0'
        $label.Cursor = 'Hand'
        $label.Tag = $box
        if ($choice.Path) { $label.ToolTip = $choice.Path }
        $label.Add_MouseLeftButtonUp({ param($sender, $e) $sender.Tag.IsChecked = -not $sender.Tag.IsChecked; Sync-AfChoice -Box $sender.Tag; $e.Handled = $true })
        [void]$line.Children.Add($box)
        [void]$line.Children.Add($label)
        [void]$panel.Children.Add($line)
        [void]$boxes.Add($box)
    }
    if ($Row) { $Row.Resources['ChoiceBoxes'] = $boxes }
    $panel
}

# Una opción cambió: la casilla de la fila queda marcada si hay alguna elegida.
function Sync-AfChoice {
    param([Parameter(Mandatory)]$Box)
    $Box.Tag.Choice.Selected = [bool]$Box.IsChecked
    $row = $Box.Tag.Row
    if (-not $row) { return }
    $parent = Get-AfRowCheckBox -Row $row
    if ($parent) { $parent.IsChecked = @($row.Resources['ChoiceBoxes'] | Where-Object { $_.IsChecked }).Count -gt 0 }
    $window = [System.Windows.Window]::GetWindow($row)
    if ($window) { Update-AfPrimary -Window $window -Roll $true }
}

# Se marcó la fila sin opciones elegidas: vuelven las preseleccionadas.
function Reset-AfChoices {
    param([Parameter(Mandatory)]$Row)
    # Sin opciones, el recurso no existe: @($null) contaría como una casilla.
    $boxes = @($Row.Resources['ChoiceBoxes'] | Where-Object { $_ })
    if (-not $boxes.Count -or @($boxes | Where-Object { $_.IsChecked }).Count) { return }
    foreach ($box in $boxes) {
        $choice = $box.Tag.Choice
        $choice.Selected = [bool]$choice.Preselected
        $box.IsChecked = $choice.Selected
    }
}

function New-AfDetailContent {
    param([Parameter(Mandatory)]$Result, $Row)
    $d = $Result.Detection
    $check = $Result.Check
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Margin = '0,10,0,2'
    $whyBlock = New-AfText -Text $check.Why -Size 12.5 -Brush 'Text2'
    $whyBlock.Margin = '0,0,0,8'
    [void]$panel.Children.Add($whyBlock)

    if ($check.Kind -eq 'Auto' -and $d.State -eq 'Improvable') {
        $grid = New-Object System.Windows.Controls.Grid
        $labelColumn = New-Object System.Windows.Controls.ColumnDefinition
        $labelColumn.Width = New-Object System.Windows.GridLength(92)
        [void]$grid.ColumnDefinitions.Add($labelColumn)
        [void]$grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
        # El tercer valor dice qué fila es: el texto de la etiqueta cambia con el idioma.
        $rows = @(@((T 'Qué cambia'), $d.What, 'what'), @((T 'Deshacer'), $check.Undo, 'undo'), @((T 'Fuente'), $check.Source, 'source')) | Where-Object { $_[1] }
        $i = 0
        foreach ($pair in $rows) {
            $gridRow = New-Object System.Windows.Controls.RowDefinition
            $gridRow.Height = [System.Windows.GridLength]::Auto
            [void]$grid.RowDefinitions.Add($gridRow)
            $label = New-AfText -Text $pair[0] -Size 12.5 -Brush 'Text3'
            $label.Margin = '0,0,0,6'
            $label.VerticalAlignment = 'Top'
            [System.Windows.Controls.Grid]::SetRow($label, $i)
            $value = New-AfText -Text $pair[1] -Size 12.5 -Brush $(if ($pair[2] -eq 'source') { 'Text' } else { 'Text2' })
            $value.Margin = '0,0,0,6'
            $value.VerticalAlignment = 'Top'
            if ($pair[2] -eq 'source' -and $check.SourceUrl) { $value.TextDecorations = [System.Windows.TextDecorations]::Underline; $value.ToolTip = $check.SourceUrl }
            [System.Windows.Controls.Grid]::SetRow($value, $i)
            [System.Windows.Controls.Grid]::SetColumn($value, 1)
            [void]$grid.Children.Add($label)
            [void]$grid.Children.Add($value)
            $i++
        }
        [void]$panel.Children.Add($grid)
        if ($d.Data -and $d.Data.Choices -and (Test-AfCanApply -Check $check)) {
            $choicesLabel = New-AfText -Text $(if ($d.Data.ChoicesLabel) { $d.Data.ChoicesLabel } else { (T 'Programas') }) -Size 12.5 -Brush 'Text3'
            $choicesLabel.Margin = '0,4,0,8'
            [void]$panel.Children.Add($choicesLabel)
            [void]$panel.Children.Add((New-AfChoiceList -Result $Result -Row $Row))
        }
    } elseif (@($d.Steps).Count) {
        $n = 1
        foreach ($step in $d.Steps) {
            $line = New-AfText -Text ('{0}. {1}' -f $n, $step) -Size 12.5 -Brush 'Text2'
            $line.Margin = '0,0,0,4'
            [void]$panel.Children.Add($line)
            $n++
        }
    }
    $panel
}

function Switch-AfRowDetail {
    param([Parameter(Mandatory)]$Row, [bool]$Motion = $true)
    $detail = $Row.FindName('Detail')
    $caret = $Row.FindName('CaretRotate')
    $opening = $detail.Tag -ne 'open'
    if ($opening) {
        $detail.Tag = 'open'
        $detail.Visibility = 'Visible'
        $detail.Child.Measure((New-Object System.Windows.Size([double]::PositiveInfinity, [double]::PositiveInfinity)))
        $height = $detail.Child.DesiredSize.Height + 4
        Start-AfAnimation -Target $detail -Property ([System.Windows.FrameworkElement]::MaxHeightProperty) -From 0 -To $height -DurationMs 250 -Ease Out -Enabled $Motion | Out-Null
        Start-AfAnimation -Target $detail -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 200 -Ease Out -Enabled $Motion | Out-Null
        Start-AfAnimation -Target $caret -Property ([System.Windows.Media.RotateTransform]::AngleProperty) -To 180 -DurationMs 200 -Ease Out -Enabled $Motion | Out-Null
    } else {
        $detail.Tag = 'closed'
        Start-AfAnimation -Target $detail -Property ([System.Windows.FrameworkElement]::MaxHeightProperty) -To 0 -DurationMs 150 -Ease Out -Enabled $Motion | Out-Null
        Start-AfAnimation -Target $detail -Property ([System.Windows.UIElement]::OpacityProperty) -To 0 -DurationMs 120 -Ease Out -Enabled $Motion | Out-Null
        Start-AfAnimation -Target $caret -Property ([System.Windows.Media.RotateTransform]::AngleProperty) -To 0 -DurationMs 150 -Ease Out -Enabled $Motion | Out-Null
        if (-not $Motion) { $detail.Visibility = 'Collapsed' }
    }
}

# Estado de una fila mientras se aplica o se deshace: casilla → indicador giratorio → hecho, no se pudo o vuelta atrás.
function Set-AfRowStatus {
    param(
        [Parameter(Mandatory)]$Row,
        [Parameter(Mandatory)][ValidateSet('Applying', 'Applied', 'Failed', 'Reverted', 'Undoing')][string]$Status,
        [string]$Message,
        [bool]$Motion = $false
    )
    $lead = $Row.FindName('Lead')
    $lead.Children.Clear()
    $element = switch ($Status) {
        'Applied' { New-AfIcon -Name 'check-circle' -Variant Fill -Size 17 -Brush 'Text' }
        'Failed' { New-AfIcon -Name 'warning-circle' -Size 16 -Brush 'RedText' }
        'Reverted' { New-AfIcon -Name 'arrow-counter-clockwise' -Size 16 -Brush 'Text3' }
        default { New-AfSpinner -Size 16 }
    }
    [void]$lead.Children.Add($element)
    Start-AfAnimation -Target $element -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Icon -Enabled $Motion | Out-Null
    # El check entra con un pequeño impulso.
    if ($Status -eq 'Applied' -and $Motion) {
        $scale = New-Object System.Windows.Media.ScaleTransform(0.6, 0.6)
        $element.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
        $element.RenderTransform = $scale
        foreach ($axis in [System.Windows.Media.ScaleTransform]::ScaleXProperty, [System.Windows.Media.ScaleTransform]::ScaleYProperty) {
            Start-AfAnimation -Target $scale -Property $axis -From 0.6 -To 1 -DurationMs 300 -Ease Icon | Out-Null
        }
    }
    if ($Message) { Set-AfRowNote -Row $Row -Text $Message }
}

# Pasos reales de un cambio en curso (diseño "Afina en vivo"): save, apply, backup o restore.
function Get-AfStepText {
    param([string]$Key)
    switch ($Key) {
        'save' { (T 'Guardando el valor original') }
        'apply' { (T 'Aplicando') }
        'backup' { (T 'Guardando el respaldo') }
        'restore' { (T 'Restaurando el valor original') }
        default { $Key }
    }
}

function Open-AfRowSteps {
    param([Parameter(Mandatory)]$Row, [string[]]$Keys = @(), [bool]$Motion = $false)
    $panel = $Row.FindName('Steps')
    $panel.Children.Clear()
    foreach ($key in $Keys) {
        $line = New-Object System.Windows.Controls.StackPanel
        $line.Orientation = 'Horizontal'
        $line.Margin = '0,0,0,4'
        $line.Tag = $key
        $dot = New-Object System.Windows.Shapes.Ellipse
        $dot.Width = 7
        $dot.Height = 7
        $dot.Margin = '1,0,10,0'
        $dot.VerticalAlignment = 'Center'
        $dot.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Line2')
        [void]$line.Children.Add($dot)
        [void]$line.Children.Add((New-AfText -Text (Get-AfStepText -Key $key) -Size 12 -Brush 'Text3'))
        [void]$panel.Children.Add($line)
    }
    $panel.Visibility = 'Visible'
    # Se mide sin el MaxHeight de 0 (la medida sale recortada a ese límite) y después se abre desde 0.
    $panel.BeginAnimation([System.Windows.FrameworkElement]::MaxHeightProperty, $null)
    $panel.MaxHeight = [double]::PositiveInfinity
    $panel.Measure((New-Object System.Windows.Size([double]::PositiveInfinity, [double]::PositiveInfinity)))
    Start-AfAnimation -Target $panel -Property ([System.Windows.FrameworkElement]::MaxHeightProperty) -From 0 -To ($panel.DesiredSize.Height + 4) -DurationMs 250 -Ease Out -Enabled $Motion | Out-Null
    Start-AfAnimation -Target $panel -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 200 -Ease Out -Enabled $Motion | Out-Null
}

function Set-AfRowStepState {
    param([Parameter(Mandatory)]$Row, [Parameter(Mandatory)][string]$Key, [Parameter(Mandatory)][ValidateSet('Running', 'Done', 'Failed')][string]$State, [string]$Detail)
    $line = @($Row.FindName('Steps').Children | Where-Object { $_.Tag -eq $Key })[0]
    if (-not $line) { return }
    $line.Resources['State'] = $State
    $label = Get-AfStepText -Key $Key
    $line.Children[1].Text = if ($State -eq 'Running' -and $Detail) { '{0} · {1}' -f $label, $Detail } else { $label }
    $dotBrush = switch ($State) { 'Running' { 'Red' } 'Done' { 'Text' } default { 'RedText' } }
    $textBrush = switch ($State) { 'Running' { 'Text' } 'Done' { 'Text2' } default { 'RedText' } }
    $line.Children[0].SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $dotBrush)
    $line.Children[1].SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, $textBrush)
}

function Close-AfRowSteps {
    param([Parameter(Mandatory)]$Row, [bool]$Motion = $false)
    $panel = $Row.FindName('Steps')
    if (-not $Motion) {
        $panel.BeginAnimation([System.Windows.FrameworkElement]::MaxHeightProperty, $null)
        $panel.MaxHeight = 0
        $panel.Children.Clear()
        $panel.Visibility = 'Collapsed'
        return
    }
    # Con animación se cierra y queda vacío a la vista; Open-AfRowSteps lo rearma la próxima vez.
    Start-AfAnimation -Target $panel -Property ([System.Windows.FrameworkElement]::MaxHeightProperty) -To 0 -DurationMs 200 -Ease Out | Out-Null
    Start-AfAnimation -Target $panel -Property ([System.Windows.UIElement]::OpacityProperty) -To 0 -DurationMs 150 -Ease Out | Out-Null
}

function Set-AfRowNote {
    param([Parameter(Mandatory)]$Row, [string]$Text)
    $note = $Row.FindName('RowNote')
    $note.Text = $Text
    $note.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Text2')
    $note.Visibility = 'Visible'
}

# Vuelve a dibujar la fila como antes de aplicar (tras deshacer), con la casilla marcada.
function Reset-AfRow {
    param([Parameter(Mandatory)]$Row, [bool]$Motion = $false)
    $group = $Row.Parent
    $index = $group.Children.IndexOf($Row)
    $first = $Row.FindName('Divider').Visibility -ne 'Visible'
    $new = New-AfRowElement -Result $Row.Tag -First:$first
    $box = Get-AfRowCheckBox -Row $new
    if ($box) { $box.IsChecked = $true }
    Add-AfRowHandlers -Row $new
    # WPF no deja reemplazar por índice sin soltar antes la fila vieja.
    $group.Children.RemoveAt($index)
    $group.Children.Insert($index, $new)
    Start-AfAnimation -Target $new -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Out -Enabled $Motion | Out-Null
    $new
}

function New-AfGroupElement {
    param([Parameter(Mandatory)]$Category, [object[]]$Results = @(), [switch]$First)
    $group = New-Object System.Windows.Controls.StackPanel
    $group.Tag = $Category.Id
    if (-not $First) {
        $line = New-Object System.Windows.Shapes.Rectangle
        $line.Height = 1
        $line.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Line')
        [void]$group.Children.Add($line)
    }
    $header = New-Object System.Windows.Controls.StackPanel
    $header.Orientation = 'Horizontal'
    $header.Margin = '18,14,18,4'
    [void]$header.Children.Add((New-AfIcon -Name $Category.Icon -Size 14))
    $label = New-AfText -Text $Category.Name -Size 12 -Brush 'Text3'
    $label.Margin = '8,0,0,0'
    [void]$header.Children.Add($label)
    [void]$group.Children.Add($header)
    $firstRow = $true
    foreach ($result in $Results) {
        [void]$group.Children.Add((New-AfRowElement -Result $result -First:$firstRow))
        $firstRow = $false
    }
    $group
}
