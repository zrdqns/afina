BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
}

Describe 'Iconos' {
    It 'Get-AfIconData devuelve trazados que WPF acepta para todos los iconos' {
        foreach ($name in Get-AfIconNames) {
            $data = Get-AfIconData -Name $name -Variant Bold
            { [System.Windows.Media.Geometry]::Parse($data) } | Should -Not -Throw
        }
        foreach ($name in Get-AfFillIconNames) {
            $data = Get-AfIconData -Name $name -Variant Fill
            { [System.Windows.Media.Geometry]::Parse($data) } | Should -Not -Throw
        }
    }

    It 'usa la regla de relleno no cero (F1)' {
        Get-AfIconData -Name 'check' -Variant Bold | Should -Match '^F1 '
    }

    It 'lanza un error con un icono que no está incluido' {
        { Get-AfIconData -Name 'no-existe' -Variant Bold } | Should -Throw
    }
}

Describe 'Tema' {
    It 'Black y White se cargan con XamlReader y tienen las 16 brochas' {
        foreach ($theme in 'Black', 'White') {
            $dictionary = [System.Windows.Markup.XamlReader]::Parse((Get-AfThemeXaml -Name $theme))
            foreach ($key in 'Bg', 'Rail', 'Panel', 'Raised', 'Line', 'Line2', 'Text', 'Text2', 'Text3', 'Red', 'RedText', 'RedFill', 'CheckBg', 'CheckFg', 'Tick', 'TickMajor') {
                $dictionary[$key] | Should -BeOfType [System.Windows.Media.SolidColorBrush]
            }
        }
    }

    It 'el negro usa el fondo #0A0A0B y el rojo del botón #D11F2C' {
        $dictionary = [System.Windows.Markup.XamlReader]::Parse((Get-AfThemeXaml -Name Black))
        $dictionary['Bg'].Color.ToString() | Should -Be '#FF0A0A0B'
        $dictionary['RedFill'].Color.ToString() | Should -Be '#FFD11F2C'
    }

    It 'Resolve-AfTheme System sigue a AppsUseLightTheme' {
        Mock Get-AfRegistryValue { 1 } -ParameterFilter { $Name -eq 'AppsUseLightTheme' }
        Resolve-AfTheme -Setting System | Should -Be 'White'
    }

    It 'Resolve-AfTheme Black fija el negro' {
        Resolve-AfTheme -Setting Black | Should -Be 'Black'
    }
}

Describe 'Movimiento' {
    It 'Never es falso y Always es verdadero' {
        Test-AfMotionEnabled -Setting Never | Should -BeFalse
        Test-AfMotionEnabled -Setting Always | Should -BeTrue
    }

    It 'Auto sigue la opción de Windows' {
        Test-AfMotionEnabled -Setting Auto | Should -Be ([bool][System.Windows.SystemParameters]::ClientAreaAnimation)
    }

    It 'Start-AfAnimation con movimiento apagado deja el valor final' {
        $border = New-Object System.Windows.Controls.Border
        $border.Opacity = 0
        Start-AfAnimation -Target $border -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Enabled $false
        $border.Opacity | Should -Be 1
    }

    It 'Start-AfAnimation con movimiento usa la curva ease-out del diseño' {
        $border = New-Object System.Windows.Controls.Border
        $animation = Start-AfAnimation -Target $border -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Out -Enabled $true
        $spline = $animation.KeyFrames[0].KeySpline
        $spline.ControlPoint1.X | Should -Be 0.23
        $spline.ControlPoint2.X | Should -Be 0.32
        $animation.Duration.TimeSpan.TotalMilliseconds | Should -Be 300
    }
}
