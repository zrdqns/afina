function Get-AfWindowXaml {
    @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Afina" Width="1100" Height="720" MinWidth="960" MinHeight="600"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResize"
        Background="{DynamicResource Bg}" Foreground="{DynamicResource Text}"
        FontFamily="{DynamicResource TextFont}" FontSize="13"
        UseLayoutRounding="True" SnapsToDevicePixels="True"
        TextOptions.TextFormattingMode="Ideal">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="40" ResizeBorderThickness="6" GlassFrameThickness="0" CornerRadius="8" UseAeroCaptionButtons="False"/>
  </WindowChrome.WindowChrome>
  <Window.Resources>
    <Style x:Key="CaptionButton" TargetType="Button">
      <Setter Property="Width" Value="46"/>
      <Setter Property="Height" Value="40"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="FontFamily" Value="Segoe Fluent Icons, Segoe MDL2 Assets"/>
      <Setter Property="FontSize" Value="10"/>
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="WindowChrome.IsHitTestVisibleInChrome" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Background="{TemplateBinding Background}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Line}"/>
                <Setter Property="Foreground" Value="{DynamicResource Text}"/>
              </Trigger>
              <Trigger Property="Tag" Value="close">
                <Setter Property="FontSize" Value="10"/>
              </Trigger>
              <MultiTrigger>
                <MultiTrigger.Conditions>
                  <Condition Property="Tag" Value="close"/>
                  <Condition Property="IsMouseOver" Value="True"/>
                </MultiTrigger.Conditions>
                <Setter TargetName="Bd" Property="Background" Value="#FFC42B1C"/>
                <Setter Property="Foreground" Value="White"/>
              </MultiTrigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="TitleButton" TargetType="Button">
      <Setter Property="Height" Value="40"/>
      <Setter Property="Padding" Value="12,0"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="WindowChrome.IsHitTestVisibleInChrome" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
              <ContentPresenter VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Line}"/>
                <Setter Property="Foreground" Value="{DynamicResource Text}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PressButton" TargetType="Button">
      <Setter Property="Height" Value="36"/>
      <Setter Property="Padding" Value="16,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="Medium"/>
      <Setter Property="Foreground" Value="{DynamicResource Text}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderBrush" Value="{DynamicResource Line2}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="9" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}" RenderTransformOrigin="0.5,0.5" ClipToBounds="True">
              <Border.RenderTransform><ScaleTransform x:Name="Sc"/></Border.RenderTransform>
              <ContentPresenter VerticalAlignment="Center" HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Opacity" Value="0.92"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Trigger.EnterActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Sc" Storyboard.TargetProperty="ScaleX"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="0.97" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Sc" Storyboard.TargetProperty="ScaleY"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="0.97" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.EnterActions>
                <Trigger.ExitActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Sc" Storyboard.TargetProperty="ScaleX"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="1" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Sc" Storyboard.TargetProperty="ScaleY"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="1" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.ExitActions>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PrimaryButton" TargetType="Button" BasedOn="{StaticResource PressButton}">
      <Setter Property="Background" Value="{DynamicResource RedFill}"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Foreground" Value="White"/>
    </Style>

    <Style x:Key="SmallButton" TargetType="Button" BasedOn="{StaticResource PressButton}">
      <Setter Property="Height" Value="28"/>
      <Setter Property="Padding" Value="12,0"/>
      <Setter Property="FontSize" Value="12"/>
    </Style>

    <Style x:Key="NavButton" TargetType="Button">
      <Setter Property="Height" Value="32"/>
      <Setter Property="Margin" Value="0,0,0,2"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="8" Background="{TemplateBinding Background}" Padding="10,0,10,0">
              <ContentPresenter VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Line}"/>
                <Setter Property="Foreground" Value="{DynamicResource Text}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="AfCheck" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="Box" Width="18" Height="18" CornerRadius="5" BorderThickness="1.5" BorderBrush="{DynamicResource Line2}" Background="Transparent">
              <Path x:Name="Mark" Width="11" Height="11" Stretch="Uniform" Fill="{DynamicResource CheckFg}" Data="{DynamicResource CheckGeometry}" Opacity="0" RenderTransformOrigin="0.5,0.5">
                <Path.RenderTransform><ScaleTransform x:Name="MarkScale" ScaleX="0.25" ScaleY="0.25"/></Path.RenderTransform>
              </Path>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Box" Property="Background" Value="{DynamicResource CheckBg}"/>
                <Setter TargetName="Box" Property="BorderBrush" Value="{DynamicResource CheckBg}"/>
                <Trigger.EnterActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Mark" Storyboard.TargetProperty="Opacity"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="1" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="MarkScale" Storyboard.TargetProperty="ScaleX"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="1" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="MarkScale" Storyboard.TargetProperty="ScaleY"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="1" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.EnterActions>
                <Trigger.ExitActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Mark" Storyboard.TargetProperty="Opacity"><SplineDoubleKeyFrame KeyTime="0:0:0.12" Value="0" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="MarkScale" Storyboard.TargetProperty="ScaleX"><SplineDoubleKeyFrame KeyTime="0:0:0.12" Value="0.25" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="MarkScale" Storyboard.TargetProperty="ScaleY"><SplineDoubleKeyFrame KeyTime="0:0:0.12" Value="0.25" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Box" Property="BorderBrush" Value="{DynamicResource Text3}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Segment" TargetType="RadioButton">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="Bd" CornerRadius="7" Padding="6,5" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Raised}"/>
                <Setter Property="Foreground" Value="{DynamicResource Text}"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Foreground" Value="{DynamicResource Text}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="{DynamicResource CardBg}"/>
      <Setter Property="BorderBrush" Value="{DynamicResource Line}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="14"/>
    </Style>

    <Style x:Key="SectionLabel" TargetType="TextBlock">
      <Setter Property="FontSize" Value="12.5"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="Margin" Value="2,24,0,10"/>
    </Style>

    <Style x:Key="CardTitle" TargetType="TextBlock">
      <Setter Property="FontSize" Value="12.5"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="Margin" Value="8,0,0,0"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
    </Style>

    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Track x:Name="PART_Track" IsDirectionReversed="True">
              <Track.Thumb>
                <Thumb>
                  <Thumb.Template>
                    <ControlTemplate TargetType="Thumb">
                      <Border Margin="3,2" CornerRadius="3" Background="{DynamicResource Line2}"/>
                    </ControlTemplate>
                  </Thumb.Template>
                </Thumb>
              </Track.Thumb>
            </Track>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Grid x:Name="Root" Background="{DynamicResource Bg}">
    <Grid.RowDefinitions>
      <RowDefinition Height="40"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <Border x:Name="TitleBar" Grid.Row="0" Background="{DynamicResource Rail}" BorderBrush="{DynamicResource Line}" BorderThickness="0,0,0,1">
      <Grid>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="18,0,0,0">
          <Border x:Name="TitleMarkHost" Width="18" Height="18"/>
          <TextBlock Text="Afina" Margin="9,0,0,1" FontFamily="{DynamicResource DisplayFont}" FontSize="15" FontWeight="Medium" VerticalAlignment="Center"/>
          <TextBlock x:Name="Version" Margin="10,0,0,0" FontFamily="{DynamicResource DisplayFont}" FontSize="12" Foreground="{DynamicResource Text3}" VerticalAlignment="Center"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="HistoryButton" Style="{StaticResource TitleButton}" ToolTip="Sesiones anteriores y deshacer">
            <StackPanel Orientation="Horizontal">
              <Path x:Name="HistoryIcon" Width="14" Height="14" Stretch="Uniform" Fill="{DynamicResource Text2}" VerticalAlignment="Center"/>
              <TextBlock Text="Historial" Margin="7,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>
          </Button>
          <Button x:Name="PrefsButton" Style="{StaticResource CaptionButton}" ToolTip="Preferencias"/>
          <Button x:Name="MinButton" Style="{StaticResource CaptionButton}" Content="&#xE921;" ToolTip="Minimizar"/>
          <Button x:Name="MaxButton" Style="{StaticResource CaptionButton}" Content="&#xE922;" ToolTip="Maximizar"/>
          <Button x:Name="CloseButton" Style="{StaticResource CaptionButton}" Tag="close" Content="&#xE8BB;" ToolTip="Cerrar"/>
        </StackPanel>
      </Grid>
    </Border>

    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="64"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <Grid x:Name="ListView" Grid.Column="1" Visibility="Collapsed">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="32,26,32,14">
          <StackPanel Orientation="Horizontal">
            <TextBlock x:Name="Title" Text="Analizando esta PC" FontFamily="{DynamicResource DisplayFont}" FontSize="28" FontWeight="Light"/>
            <TextBlock x:Name="TitleCount" FontSize="13.5" Foreground="{DynamicResource Text2}" Margin="12,0,0,7" VerticalAlignment="Bottom" Visibility="Collapsed"/>
          </StackPanel>
          <StackPanel x:Name="GaugeArea">
          <Grid x:Name="Gauge" Height="46" Margin="0,22,0,0">
            <Canvas x:Name="Ticks" Height="20" VerticalAlignment="Bottom" Margin="0,0,0,8"/>
            <Canvas x:Name="LitTicks" Height="20" VerticalAlignment="Bottom" Margin="0,0,0,8" IsHitTestVisible="False"/>
            <Canvas x:Name="Needle" Width="2" Height="38" HorizontalAlignment="Left" VerticalAlignment="Bottom" Margin="0,0,0,2" Opacity="1">
              <Canvas.RenderTransform><TranslateTransform x:Name="NeedleTransform"/></Canvas.RenderTransform>
              <Ellipse x:Name="NeedleHalo" Width="146" Height="72" Canvas.Left="-72" Canvas.Top="-16" IsHitTestVisible="False" Opacity="0.26"/>
              <Rectangle Width="2" Height="38" RadiusX="1" RadiusY="1" Fill="{DynamicResource Red}"/>
              <Polygon Points="-3,-6 5,-6 1,0" Fill="{DynamicResource Red}"/>
            </Canvas>
          </Grid>
          <Grid Margin="0,6,0,0">
            <TextBlock Text="Desafinado" FontSize="11.5" Foreground="{DynamicResource Text3}"/>
            <TextBlock Text="Afinado" FontSize="11.5" Foreground="{DynamicResource Text3}" HorizontalAlignment="Right"/>
          </Grid>
          </StackPanel>
          <TextBlock x:Name="Summary" Margin="0,14,0,0" FontSize="13.5" Foreground="{DynamicResource Text2}" TextWrapping="Wrap" MinHeight="20"/>
        </StackPanel>
        <ScrollViewer x:Name="ListScroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="32,4,32,28" Focusable="False">
          <Grid>
            <StackPanel>
              <Border x:Name="EmptyState" Background="{DynamicResource Panel}" CornerRadius="14" BorderBrush="{DynamicResource Line}" BorderThickness="1" Padding="22,20,22,10" Margin="0,0,0,14" Visibility="Collapsed"/>
              <Border x:Name="PanelBorder" Background="{DynamicResource Panel}" CornerRadius="14" BorderBrush="{DynamicResource Line}" BorderThickness="1" Visibility="Collapsed">
                <StackPanel x:Name="Groups" Margin="0,0,0,6"/>
              </Border>
            </StackPanel>
            <Border x:Name="HistoryPanel" Visibility="Collapsed">
              <StackPanel x:Name="HistoryList"/>
            </Border>
          </Grid>
        </ScrollViewer>
        <Border x:Name="FollowChip" Grid.Row="1" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,18" Padding="14,7,14,7" CornerRadius="99" Background="{DynamicResource Raised}" BorderBrush="{DynamicResource Line2}" BorderThickness="1" Cursor="Hand" Visibility="Collapsed">
          <StackPanel Orientation="Horizontal">
            <Ellipse Width="7" Height="7" Fill="{DynamicResource Red}" VerticalAlignment="Center" Margin="0,0,8,0"/>
            <TextBlock Text="Seguir el avance" FontSize="12.5" Foreground="{DynamicResource Text}"/>
          </StackPanel>
        </Border>
      </Grid>

      <ScrollViewer x:Name="HomeScroll" Grid.Column="1" VerticalScrollBarVisibility="Auto" Focusable="False">
        <StackPanel Margin="28,22,28,26">
          <Grid x:Name="PcHeader" MinHeight="62">
            <StackPanel x:Name="PcSkeleton" Visibility="Collapsed"/>
            <StackPanel x:Name="PcCard" Opacity="0">
              <StackPanel Orientation="Horizontal">
                <TextBlock x:Name="PcName" FontFamily="{DynamicResource DisplayFont}" FontSize="26" FontWeight="Light" TextTrimming="CharacterEllipsis"/>
                <TextBlock x:Name="PcKind" FontSize="12.5" Foreground="{DynamicResource Text3}" Margin="12,0,0,5" VerticalAlignment="Bottom"/>
              </StackPanel>
              <WrapPanel x:Name="Specs" Margin="0,10,0,0"/>
            </StackPanel>
          </Grid>
          <Grid Margin="0,16,0,0">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="1.8*"/>
              <ColumnDefinition Width="14"/>
              <ColumnDefinition Width="*" MinWidth="250"/>
            </Grid.ColumnDefinitions>
            <Border x:Name="HeroCard" Style="{StaticResource Card}" Padding="16,16,22,18">
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="Auto"/>
                  <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Grid x:Name="HeroDialHost" Width="200" Height="200" VerticalAlignment="Center" Margin="4,0,0,0">
                  <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Margin="0,0,0,4" IsHitTestVisible="False">
                    <TextBlock x:Name="HeroNumber" Text="0" FontFamily="{DynamicResource DisplayFont}" FontSize="46" FontWeight="Light" HorizontalAlignment="Center"/>
                    <TextBlock x:Name="HeroUnit" FontSize="12.5" Foreground="{DynamicResource Text2}" HorizontalAlignment="Center" Margin="0,-4,0,0"/>
                  </StackPanel>
                </Grid>
                <Grid Grid.Column="1" Margin="28,2,0,0">
                  <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                  </Grid.RowDefinitions>
                  <StackPanel Orientation="Horizontal">
                    <Path x:Name="HeroIcon" Width="14" Height="14" Stretch="Uniform" Fill="{DynamicResource Text2}" VerticalAlignment="Center"/>
                    <TextBlock Text="Afinación" Style="{StaticResource CardTitle}"/>
                  </StackPanel>
                  <StackPanel Grid.Row="1" VerticalAlignment="Center" Margin="0,10,0,14">
                    <TextBlock x:Name="HeroTitle" FontFamily="{DynamicResource DisplayFont}" FontSize="21" FontWeight="Medium" TextWrapping="Wrap"/>
                    <TextBlock x:Name="HeroText" Margin="0,6,0,0" FontSize="13" Foreground="{DynamicResource Text2}" TextWrapping="Wrap"/>
                  </StackPanel>
                  <Button x:Name="HeroButton" Grid.Row="2" HorizontalAlignment="Left" Style="{StaticResource PrimaryButton}" Opacity="0" ToolTip="Se crea un punto de restauración antes de aplicar">
                    <StackPanel Orientation="Horizontal">
                      <TextBlock x:Name="HeroButtonText" Text="Ver el detalle" VerticalAlignment="Center"/>
                      <Path x:Name="HeroButtonIcon" Width="13" Height="13" Margin="8,0,0,0" Stretch="Uniform" Fill="White" VerticalAlignment="Center"/>
                    </StackPanel>
                  </Button>
                </Grid>
              </Grid>
            </Border>
            <Border x:Name="ProfileCard" Grid.Column="2" Style="{StaticResource Card}" Padding="18,18,18,12">
              <DockPanel>
                <StackPanel DockPanel.Dock="Top" Orientation="Horizontal">
                  <Path x:Name="ProfileIcon" Width="14" Height="14" Stretch="Uniform" Fill="{DynamicResource Text2}" VerticalAlignment="Center"/>
                  <TextBlock Text="Perfil por categoría" Style="{StaticResource CardTitle}"/>
                </StackPanel>
                <Viewbox Stretch="Uniform" StretchDirection="DownOnly" Margin="0,6,0,0" VerticalAlignment="Center">
                  <Canvas x:Name="Radar" Width="300" Height="192"/>
                </Viewbox>
              </DockPanel>
            </Border>
          </Grid>
          <TextBlock x:Name="QuickLabel" Text="Acciones rápidas" Style="{StaticResource SectionLabel}"/>
          <UniformGrid x:Name="Quick" Rows="1" Margin="-6,0,-6,0"/>
          <DockPanel x:Name="LiveHeader" Margin="2,24,0,10">
            <TextBlock x:Name="LiveNote" DockPanel.Dock="Right" Text="Se actualiza cada segundo" FontSize="11.5" Foreground="{DynamicResource Text3}" VerticalAlignment="Center"/>
            <StackPanel Orientation="Horizontal">
              <Ellipse x:Name="LiveDot" Width="6" Height="6" Fill="{DynamicResource Red}" VerticalAlignment="Center" Margin="0,1,8,0"/>
              <TextBlock Text="En vivo" FontSize="12.5" Foreground="{DynamicResource Text2}" VerticalAlignment="Center"/>
            </StackPanel>
          </DockPanel>
          <UniformGrid x:Name="Live" Rows="1" Margin="-6,0,-6,0"/>
        </StackPanel>
      </ScrollViewer>

      <Border x:Name="Rail" Grid.Column="0" Grid.ColumnSpan="2" Width="64" HorizontalAlignment="Left" Panel.ZIndex="5" ClipToBounds="True"
              Background="{DynamicResource Rail}" BorderBrush="{DynamicResource Line}" BorderThickness="0,0,1,0" Padding="12,16,12,12">
        <Border.Effect><DropShadowEffect x:Name="RailShadow" BlurRadius="28" ShadowDepth="0" Color="Black" Opacity="0"/></Border.Effect>
        <ScrollViewer x:Name="NavScroll" VerticalScrollBarVisibility="Hidden" Focusable="False"><Grid x:Name="NavHost">
          <StackPanel x:Name="Nav"/>
          <Border x:Name="NavIndicator" Width="2" Height="32" CornerRadius="2" Background="{DynamicResource Red}" HorizontalAlignment="Left" VerticalAlignment="Top">
            <Border.RenderTransform><TranslateTransform x:Name="NavIndicatorTransform"/></Border.RenderTransform>
          </Border>
        </Grid></ScrollViewer>
      </Border>
    </Grid>

    <Border x:Name="Footer" Grid.Row="2" Background="{DynamicResource Rail}" BorderBrush="{DynamicResource Line}" BorderThickness="0,1,0,0" Padding="32,14">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" VerticalAlignment="Center" Margin="0,0,24,0">
          <DockPanel>
            <Path x:Name="NoteIcon" DockPanel.Dock="Left" Width="16" Height="16" Stretch="Uniform" Fill="{DynamicResource Text3}" VerticalAlignment="Top" Margin="0,1,0,0"/>
            <TextBlock x:Name="NoteText" Text="Se crea un punto de restauración antes de aplicar" Margin="8,0,0,0" FontSize="12.5" Foreground="{DynamicResource Text2}" TextWrapping="Wrap" VerticalAlignment="Center"/>
          </DockPanel>
          <StackPanel x:Name="RestoreRow" Orientation="Horizontal" Margin="24,9,0,0" Visibility="Collapsed">
            <CheckBox x:Name="RestoreOption" Style="{StaticResource AfCheck}" IsChecked="True" VerticalAlignment="Center"/>
            <TextBlock x:Name="RestoreLabel" Text="Activar Restaurar sistema en C:" Margin="9,0,0,0" FontSize="12.5" Foreground="{DynamicResource Text}" VerticalAlignment="Center" Cursor="Hand"/>
          </StackPanel>
        </StackPanel>
        <StackPanel x:Name="Actions" Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Opacity="0" IsHitTestVisible="False">
          <Button x:Name="ExtraButton" Style="{StaticResource PressButton}" Margin="0,0,10,0" Visibility="Collapsed">
            <StackPanel Orientation="Horizontal">
              <Path x:Name="ExtraIcon" Width="15" Height="15" Stretch="Uniform" Fill="{DynamicResource Text}" VerticalAlignment="Center" Margin="0,0,8,0"/>
              <TextBlock x:Name="ExtraText" VerticalAlignment="Center"/>
            </StackPanel>
          </Button>
          <Button x:Name="GhostButton" Style="{StaticResource PressButton}" Margin="0,0,10,0">
            <StackPanel Orientation="Horizontal">
              <Path x:Name="GhostIcon" Width="15" Height="15" Stretch="Uniform" Fill="{DynamicResource Text}" VerticalAlignment="Center" Margin="0,0,8,0"/>
              <TextBlock x:Name="GhostText" Text="Volver a analizar" VerticalAlignment="Center"/>
            </StackPanel>
          </Button>
          <Button x:Name="PrimaryButton" Style="{StaticResource PrimaryButton}">
            <Grid>
              <StackPanel x:Name="PrimaryText" Orientation="Horizontal" ClipToBounds="True">
                <TextBlock x:Name="PrimaryLead"/>
                <TextBlock x:Name="PrimaryNumber">
                  <TextBlock.RenderTransform><TranslateTransform x:Name="PrimaryNumberShift"/></TextBlock.RenderTransform>
                </TextBlock>
                <TextBlock x:Name="PrimaryTail"/>
              </StackPanel>
              <Rectangle x:Name="PrimaryProgress" Height="2" VerticalAlignment="Bottom" Margin="-16,0,-16,-9" Fill="#E6FFFFFF" RenderTransformOrigin="0,0.5">
                <Rectangle.RenderTransform><ScaleTransform x:Name="PrimaryProgressScale" ScaleX="0"/></Rectangle.RenderTransform>
              </Rectangle>
            </Grid>
          </Button>
        </StackPanel>
      </Grid>
    </Border>

    <Grid x:Name="Splash" Grid.RowSpan="3" Panel.ZIndex="100" Background="{DynamicResource Bg}" ClipToBounds="True">
      <StackPanel x:Name="SplashContent" Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,20">
        <Border x:Name="SplashDialHost" Width="132" Height="132" VerticalAlignment="Center"/>
        <StackPanel VerticalAlignment="Center" Margin="30,0,0,8">
          <StackPanel x:Name="SplashLetters" Orientation="Horizontal"/>
          <TextBlock x:Name="SplashTag" Text="Análisis y optimización de Windows" FontSize="14" Foreground="{DynamicResource Text2}" Margin="4,0,0,0"/>
        </StackPanel>
      </StackPanel>
      <TextBlock x:Name="SplashVersion" FontFamily="{DynamicResource DisplayFont}" FontSize="12" Foreground="{DynamicResource Text3}" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,26"/>
    </Grid>

    <Popup x:Name="Prefs" StaysOpen="False" Placement="Bottom" AllowsTransparency="True" PopupAnimation="Fade" HorizontalOffset="-200" VerticalOffset="4">
      <Border Background="{DynamicResource Panel}" CornerRadius="12" BorderBrush="{DynamicResource Line2}" BorderThickness="1" Padding="14" Width="280">
        <StackPanel>
          <TextBlock Text="Tema" FontSize="12" Foreground="{DynamicResource Text3}"/>
          <Border Background="{DynamicResource Line}" CornerRadius="10" Padding="3" Margin="0,6,0,14">
            <UniformGrid Rows="1">
              <RadioButton x:Name="ThemeSystem" GroupName="Theme" Style="{StaticResource Segment}" Content="Sistema"/>
              <RadioButton x:Name="ThemeBlack" GroupName="Theme" Style="{StaticResource Segment}" Content="Negro"/>
              <RadioButton x:Name="ThemeWhite" GroupName="Theme" Style="{StaticResource Segment}" Content="Blanco"/>
            </UniformGrid>
          </Border>
          <TextBlock Text="Animaciones" FontSize="12" Foreground="{DynamicResource Text3}"/>
          <Border Background="{DynamicResource Line}" CornerRadius="10" Padding="3" Margin="0,6,0,0">
            <UniformGrid Rows="1">
              <RadioButton x:Name="MotionAuto" GroupName="Motion" Style="{StaticResource Segment}" Content="Automático"/>
              <RadioButton x:Name="MotionAlways" GroupName="Motion" Style="{StaticResource Segment}" Content="Siempre"/>
              <RadioButton x:Name="MotionNever" GroupName="Motion" Style="{StaticResource Segment}" Content="Nunca"/>
            </UniformGrid>
          </Border>
          <TextBlock Text="Automático sigue la opción Efectos de animación de Windows." FontSize="11.5" Foreground="{DynamicResource Text3}" TextWrapping="Wrap" Margin="0,8,0,0"/>
          <TextBlock Text="Idioma" FontSize="12" Foreground="{DynamicResource Text3}" Margin="0,16,0,0"/>
          <Border Background="{DynamicResource Line}" CornerRadius="10" Padding="3" Margin="0,6,0,0">
            <UniformGrid Rows="1">
              <RadioButton x:Name="LangAuto" GroupName="Lang" Style="{StaticResource Segment}" Content="Automático"/>
              <RadioButton x:Name="LangEs" GroupName="Lang" Style="{StaticResource Segment}" Content="Español"/>
              <RadioButton x:Name="LangEn" GroupName="Lang" Style="{StaticResource Segment}" Content="English"/>
            </UniformGrid>
          </Border>
          <TextBlock Text="Automático sigue el idioma de Windows." FontSize="11.5" Foreground="{DynamicResource Text3}" TextWrapping="Wrap" Margin="0,8,0,0"/>
        </StackPanel>
      </Border>
    </Popup>
  </Grid>
</Window>
'@
}

function New-AfIcon {
    param([Parameter(Mandatory)][string]$Name, [ValidateSet('Bold', 'Fill')][string]$Variant = 'Bold', [double]$Size = 16, [string]$Brush = 'Text3')
    $path = New-Object System.Windows.Shapes.Path
    $path.Data = [System.Windows.Media.Geometry]::Parse((Get-AfIconData -Name $Name -Variant $Variant))
    $path.Width = $Size
    $path.Height = $Size
    $path.Stretch = [System.Windows.Media.Stretch]::Uniform
    $path.VerticalAlignment = 'Center'
    $path.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $Brush)
    $path
}

function Set-AfIconData {
    param([Parameter(Mandatory)][System.Windows.Shapes.Path]$Path, [Parameter(Mandatory)][string]$Name, [string]$Variant = 'Bold')
    $Path.Data = [System.Windows.Media.Geometry]::Parse((Get-AfIconData -Name $Name -Variant $Variant))
}

function Set-AfTheme {
    param([Parameter(Mandatory)]$Window, [ValidateSet('Black', 'White')][string]$Theme = 'Black')
    $dictionary = [System.Windows.Markup.XamlReader]::Parse((Get-AfThemeXaml -Name $Theme))
    # .Add() y no $dictionary[...] = ...: el indexador guarda el objeto envuelto por PowerShell y WPF no lo reconoce.
    $dictionary.Add('CheckGeometry', [System.Windows.Media.Geometry]::Parse((Get-AfIconData -Name 'check' -Variant Bold)))
    # Halo de la aguja: el rojo del tema que se desvanece hacia transparente.
    $red = $dictionary['Red'].Color
    $halo = New-Object System.Windows.Media.RadialGradientBrush
    [void]$halo.GradientStops.Add((New-Object System.Windows.Media.GradientStop($red, 0)))
    [void]$halo.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromArgb(0, $red.R, $red.G, $red.B), 1)))
    $dictionary.Add('NeedleHaloBrush', $halo)
    # Resumen: tarjetas con un degradado muy leve, barras encendidas y rellenos de las gráficas, del color del texto del tema.
    $text = $dictionary['Text'].Color
    $fade = { param($top, $bottom) $b = New-Object System.Windows.Media.LinearGradientBrush; $b.StartPoint = '0,0'; $b.EndPoint = '0,1'; [void]$b.GradientStops.Add((New-Object System.Windows.Media.GradientStop($top, 0))); [void]$b.GradientStops.Add((New-Object System.Windows.Media.GradientStop($bottom, 1))); $b }
    $alpha = { param($a) [System.Windows.Media.Color]::FromArgb($a, $text.R, $text.G, $text.B) }
    $dictionary.Add('CardBg', $(if ($Theme -eq 'Black') { & $fade $dictionary['Raised'].Color $dictionary['Panel'].Color } else { $dictionary['Panel'] }))
    $beam = New-Object System.Windows.Media.LinearGradientBrush
    $beam.StartPoint = '0,0.7'
    $beam.EndPoint = '1,0.3'
    [void]$beam.GradientStops.Add((New-Object System.Windows.Media.GradientStop((& $alpha 0), 0)))
    [void]$beam.GradientStops.Add((New-Object System.Windows.Media.GradientStop((& $alpha 70), 1)))
    $dictionary.Add('BeamFill', $beam)
    $dictionary.Add('SparkFill', (& $fade (& $alpha 46) (& $alpha 0)))
    $dictionary.Add('RadarFill', (New-Object System.Windows.Media.SolidColorBrush((& $alpha 28))))
    $Window.Resources.MergedDictionaries.Clear()
    $Window.Resources.MergedDictionaries.Add($dictionary)
    $Window.Tag = if ($Window.Tag -is [hashtable]) { $Window.Tag } else { @{} }
    $Window.Tag.Theme = $Theme
}

# Textos fijos del XAML (escritos en español). La primera vez guarda el original de cada uno; siempre pone su traducción.
# Al cambiar de idioma se vuelve a llamar; los textos que pone el código se rehacen con el análisis nuevo.
function Set-AfStaticTexts {
    param([Parameter(Mandatory)]$Window)
    if ($Window.Tag -isnot [hashtable]) { $Window.Tag = @{} }
    $s = $Window.Tag
    if (-not $s.StaticTexts) {
        $found = New-Object System.Collections.ArrayList
        $pending = New-Object System.Collections.Stack
        $pending.Push($Window)
        while ($pending.Count) {
            $node = $pending.Pop()
            if ($node -is [System.Windows.Controls.TextBlock]) {
                $inlines = @($node.Inlines)
                if ($inlines.Count -gt 1) {
                    foreach ($run in $inlines) { if ($run -is [System.Windows.Documents.Run] -and $run.Text -match '\p{L}') { [void]$found.Add(@{ Element = $run; Property = 'Text'; Spanish = $run.Text }) } }
                } elseif ($node.Text -match '\p{L}') { [void]$found.Add(@{ Element = $node; Property = 'Text'; Spanish = $node.Text }) }
            }
            if ($node -is [System.Windows.Controls.ContentControl] -and $node.Content -is [string] -and $node.Content -match '\p{L}') { [void]$found.Add(@{ Element = $node; Property = 'Content'; Spanish = $node.Content }) }
            if ($node -is [System.Windows.FrameworkElement] -and $node.ToolTip -is [string] -and $node.ToolTip -match '\p{L}') { [void]$found.Add(@{ Element = $node; Property = 'ToolTip'; Spanish = $node.ToolTip }) }
            foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($node)) { if ($child -is [System.Windows.DependencyObject]) { $pending.Push($child) } }
        }
        $s.StaticTexts = $found
    }
    foreach ($item in $s.StaticTexts) { $item.Element.($item.Property) = T $item.Spanish }
}

function New-AfWindow {
    param([ValidateSet('Black', 'White')][string]$Theme = 'Black')
    $window = [System.Windows.Markup.XamlReader]::Parse((Get-AfWindowXaml))
    Set-AfTheme -Window $window -Theme $Theme
    Set-AfStaticTexts -Window $window
    $window.FindName('NeedleHalo').SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'NeedleHaloBrush')
    $window.FindName('PrefsButton').Content = New-AfIcon -Name 'gear-six' -Size 15 -Brush 'Text2'
    Set-AfIconData -Path $window.FindName('HistoryIcon') -Name 'clock-counter-clockwise'
    Set-AfIconData -Path $window.FindName('NoteIcon') -Name 'shield-check'
    Set-AfIconData -Path $window.FindName('GhostIcon') -Name 'arrow-clockwise'
    $window.FindName('Version').Text = 'v' + (Get-AfVersion)
    $window.FindName('TitleMarkHost').Child = New-AfLogoMark -Size 18
    try { $window.Icon = New-AfLogoImage } catch { }
    # Mover la lista a mano pausa el seguimiento del cambio en curso; la píldora lo retoma.
    $scroll = $window.FindName('ListScroll')
    $scroll.Add_PreviewMouseWheel({ param($sender, $e) Suspend-AfFollow -Window ([System.Windows.Window]::GetWindow($sender)) })
    $scroll.AddHandler([System.Windows.Controls.Primitives.Thumb]::DragStartedEvent, [System.Windows.Controls.Primitives.DragStartedEventHandler] { param($sender, $e) Suspend-AfFollow -Window ([System.Windows.Window]::GetWindow($sender)) })
    $window.FindName('FollowChip').Add_MouseLeftButtonUp({ param($sender, $e) Resume-AfFollow -Window ([System.Windows.Window]::GetWindow($sender)) })
    $window
}

# Deja correr la interfaz (animaciones, diseño) un rato sin bloquear el hilo de WPF.
function Wait-AfUi {
    param([int]$Milliseconds = 300)
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds($Milliseconds)
    $timer.Add_Tick({ $timer.Stop(); $frame.Continue = $false }.GetNewClosure())
    $timer.Start()
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

function Save-AfWindowSnapshot {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)][string]$Path, [double]$Scale = 1)
    if (-not $Window.IsVisible) {
        $Window.WindowStartupLocation = 'Manual'
        $Window.Left = -20000
        $Window.Top = -20000
        $Window.ShowActivated = $false
        $Window.Show()
    }
    Wait-AfUi -Milliseconds 450
    $Window.UpdateLayout()
    $root = $Window.Content
    $width = [int][math]::Round($root.ActualWidth * $Scale)
    $height = [int][math]::Round($root.ActualHeight * $Scale)
    $bitmap = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($width, $height, (96 * $Scale), (96 * $Scale), [System.Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($root)
    $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $stream = [System.IO.File]::Create($Path)
    try { $encoder.Save($stream) } finally { $stream.Dispose() }
}
