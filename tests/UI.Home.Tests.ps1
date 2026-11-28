BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    function Get-HomeResults {
        $inv = New-AfFakeInventory
        @(Get-AfCatalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $inv })
    }
    # Una ventana mostrada fuera de la pantalla: las barras del medidor se arman con el primer diseño.
    function New-ShownWindow {
        $window = New-AfWindow -Theme Black
        $null = Get-AfUiState -Window $window
        $window.WindowStartupLocation = 'Manual'
        $window.Left = -20000
        $window.Top = -20000
        $window.ShowActivated = $false
        $window.Show()
        Wait-AfUi -Milliseconds 200
        $window
    }
}

Describe 'Resumen' {
    It 'la ventana abre en el Resumen, con la lista y el pie escondidos' {
        $window = New-AfWindow -Theme Black
        try {
            $s = Get-AfUiState -Window $window
            $s.View | Should -Be 'home'
            $window.FindName('HomeScroll').Visibility | Should -Be 'Visible'
            $window.FindName('ListView').Visibility | Should -Be 'Collapsed'
            $s.Phase = 'ready'
            Update-AfFooterVisibility -Window $window
            $window.FindName('Footer').Visibility | Should -Be 'Collapsed'
        } finally { $window.Close() }
    }

    It 'elegir una categoría pasa a la lista y Resumen vuelve' {
        $window = New-AfWindow -Theme Black
        try {
            Show-AfResults -Window $window -Results (Get-HomeResults)
            Set-AfFilter -Window $window -Filter 'gaming'
            $window.Tag.View | Should -Be 'list'
            $window.FindName('Footer').Visibility | Should -Be 'Visible'
            Set-AfFilter -Window $window -Filter 'home'
            $window.Tag.View | Should -Be 'home'
            $window.Tag.Filter | Should -Be 'gaming'
        } finally { $window.Close() }
    }

    It 'el número grande cuenta lo que está en orden, como el resumen' {
        $window = New-AfWindow -Theme Black
        try {
            $results = Get-HomeResults
            Show-AfResults -Window $window -Results $results
            $window.FindName('HeroNumber').Text | Should -Be ([string](Get-AfSummary -Results $results).Ok)
            $window.FindName('HeroButton').IsHitTestVisible | Should -BeTrue
        } finally { $window.Close() }
    }

    It 'mientras analiza, llena el anillo hasta la parte revisada' {
        $window = New-ShownWindow
        try {
            $s = $window.Tag
            $s.Phase = 'scanning'
            $s.Revealed = 3
            Update-AfHome -Window $window
            # 3 de 9 categorías: el anillo lleno en un tercio y el punto rojo en el mismo lugar.
            [math]::Round($s.HeroDial.Fill.StrokeDashOffset, 3) | Should -Be ([math]::Round($s.HeroDial.Units * 2 / 3, 3))
            $s.HeroDial.Knob.Angle | Should -Be (-150 + 300 / 3)
            $s.HeroDial.Fill.Opacity | Should -Be 1
            $window.FindName('HeroUnit').Text | Should -Be 'revisados'
        } finally { $window.Close() }
    }

    It 'el perfil marca en rojo la categoría con algo pendiente' {
        $window = New-AfWindow -Theme Black
        try {
            Show-AfResults -Window $window -Results (Get-HomeResults)
            $radar = $window.Tag.Radar
            $radar.Labels.Count | Should -Be 6
            $axes = @(Get-AfRadarAxes)
            for ($k = 0; $k -lt 6; $k++) {
                $pending = Get-AfPendingCount -Category $axes[$k] -Results @($window.Tag.Results)
                $expected = if ($pending -gt 0) { $window.FindResource('Red') } else { $window.FindResource('Text') }
                $radar.Dots[$k].Fill | Should -Be $expected
            }
        } finally { $window.Close() }
    }

    It 'la barra lateral se abre con nombres y se cierra con solo iconos' {
        $window = New-AfWindow -Theme Black
        try {
            $null = Get-AfUiState -Window $window
            $window.FindName('Rail').Width | Should -Be 64
            $window.Tag.Nav['energy'].Label.Opacity | Should -Be 0
            Set-AfRailOpen -Window $window -Open $true
            $window.FindName('Rail').Width | Should -Be 236
            $window.Tag.Nav['energy'].Label.Opacity | Should -Be 1
            Set-AfRailOpen -Window $window -Open $false
            $window.FindName('Rail').Width | Should -Be 64
        } finally { $window.Close() }
    }

    It 'Historial abierto desde el Resumen vuelve al Resumen' {
        $window = New-AfWindow -Theme Black
        try {
            Show-AfResults -Window $window -Results (Get-HomeResults)
            $window.Tag.BackupDirectory = Join-Path $TestDrive 'respaldos'
            Invoke-AfQuickAction -Window $window -Id 'history'
            $window.Tag.View | Should -Be 'list'
            $window.Tag.Phase | Should -Be 'history'
            Hide-AfHistory -Window $window
            $window.Tag.View | Should -Be 'home'
        } finally { $window.Close() }
    }

    It 'la red se muestra en bits por segundo' {
        (Format-AfRate -BitsPerSecond 2500000)[1] | Should -Be 'Mbps'
        (Format-AfRate -BitsPerSecond 64000)[1] | Should -Be 'Kbps'
    }

    It 'una muestra en vivo llena el historial y dibuja la gráfica' {
        $window = New-ShownWindow
        try {
            $s = $window.Tag
            $s.LiveSync = [hashtable]::Synchronized(@{ Stop = $false; Seq = 0; Sample = $null; Failed = $null })
            foreach ($cpu in 20, 40, 60) {
                $s.LiveSync.Sample = @{ Cpu = $cpu; Disk = 5; MemUsed = 4GB; MemTotal = 16GB; Down = 3e6; Up = 1e5 }
                $s.LiveSync.Seq++
                Receive-AfLiveSample -Window $window
            }
            @($s.LiveHistory.Cpu).Count | Should -Be 3
            $s.LiveTiles['Cpu'].Value.Text | Should -Be '60'
            $s.LiveTiles['Mem'].Value.Text | Should -Be '25'
            $s.LiveTiles['Cpu'].Line.Points.Count | Should -Be 3
        } finally { $window.Close() }
    }

    It 'el logo se dibuja sin el tema (icono de la ventana)' {
        $image = New-AfLogoImage
        $image.PixelWidth | Should -Be 64
    }
}
