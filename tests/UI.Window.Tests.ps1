BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    $script:names = 'TitleBar', 'PrefsButton', 'MinButton', 'MaxButton', 'CloseButton', 'PcName', 'PcKind', 'Specs', 'Nav', 'NavIndicator',
    'HistoryButton', 'Version', 'Title', 'Gauge', 'Ticks', 'LitTicks', 'Needle', 'Summary', 'ListScroll', 'Groups', 'NoteText',
    'GhostButton', 'GhostText', 'PrimaryButton', 'PrimaryText', 'PrimaryProgress', 'Prefs'
    function Get-FakeResults {
        $inv = New-AfFakeInventory -Override @{ Registry = @{ 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode' = 1 } }
        @(Get-AfCatalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $inv })
    }
}

Describe 'Ventana' {
    It 'New-AfWindow Black y White cargan y tienen todos los nombres' {
        foreach ($theme in 'Black', 'White') {
            $window = New-AfWindow -Theme $theme
            foreach ($name in $script:names) { $window.FindName($name) | Should -Not -BeNullOrEmpty -Because "falta $name en $theme" }
            $window.Close()
        }
    }

    It 'Set-AfTheme cambia las brochas de la ventana' {
        $window = New-AfWindow -Theme Black
        Set-AfTheme -Window $window -Theme White
        $window.Background.Color.ToString() | Should -Be '#FFF5F5F3'
        $window.Close()
    }

    It 'una ventana con resultados de mentira se dibuja a PNG de 1100 × 720' {
        $window = New-AfWindow -Theme Black
        Set-AfPcCard -Window $window -Inventory (New-AfFakeInventory)
        Show-AfResults -Window $window -Results (Get-FakeResults) -Animate $false
        $png = Join-Path $TestDrive 'ventana.png'
        Save-AfWindowSnapshot -Window $window -Path $png
        $window.Close()
        Test-Path $png | Should -BeTrue
        Add-Type -AssemblyName System.Drawing
        $image = [System.Drawing.Image]::FromFile($png)
        try { $image.Width | Should -Be 1100; $image.Height | Should -Be 720 } finally { $image.Dispose() }
    }
}

Describe 'Filas' {
    It 'New-AfRowElement con Manual no tiene casilla' {
        $result = Get-FakeResults | Where-Object { $_.Check.Kind -eq 'Manual' -and $_.Detection.State -eq 'Manual' } | Select-Object -First 1
        $row = New-AfRowElement -Result $result
        $row.Tag | Should -Be $result
        (Get-AfRowCheckBox -Row $row) | Should -BeNullOrEmpty
    }

    It 'New-AfRowElement con Auto mejorable trae la casilla marcada si viene preseleccionada' {
        $result = Get-FakeResults | Where-Object { $_.Check.Id -eq 'gpu.hags' }
        $row = New-AfRowElement -Result $result
        (Get-AfRowCheckBox -Row $row).IsChecked | Should -BeTrue
    }
}

Describe 'Navegación' {
    It 'Update-AfNavCounts muestra check en categorías sin pendientes y el número en las que tienen' {
        $window = New-AfWindow -Theme Black
        $results = Get-FakeResults
        Show-AfResults -Window $window -Results $results -Animate $false
        Update-AfNavCounts -Window $window -Results $results
        (Get-AfNavCount -Window $window -Category 'gaming') | Should -BeGreaterThan 0
        (Get-AfNavCount -Window $window -Category 'network') | Should -Be 0
        $window.Close()
    }
}
