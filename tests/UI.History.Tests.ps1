BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    $script:user = [pscustomobject]@{ Name = 'PC\Cliente'; Sid = 'S-1-5-21-1' }
    function New-ResultsWindow {
        $inv = New-AfFakeInventory -Override @{ Registry = @{ 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode' = 1 } }
        $window = New-AfWindow -Theme Black
        Show-AfResults -Window $window -Results @(Get-AfCatalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $inv }) -Animate $false
        $window.Tag.BackupDirectory = Join-Path $TestDrive 'navegacion'
        $window
    }
    function New-Change([string]$Id, [string]$Status, [string]$Kind = 'RegistryValue') {
        [pscustomobject]@{ CheckId = $Id; Title = "Cambio $Id"; NeedsReboot = $false; Status = $Status; Message = $null; Note = $null; AppliedAt = $null; UndoneAt = $null; Records = @([pscustomobject]@{ Kind = $Kind }) }
    }
    function New-FakeSession([object[]]$Changes) { [pscustomobject]@{ Id = 'x'; StartedAt = (Get-Date).ToString('o'); Changes = $Changes } }
    function Get-Buttons($Element) {
        foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($Element)) {
            if ($child -is [System.Windows.Controls.Button]) { $child }
            if ($child -is [System.Windows.DependencyObject]) { Get-Buttons $child }
        }
    }
}

Describe 'Historial' {
    It 'Format-AfSessionDate da "21 nov 2026, 16:42"' {
        Format-AfSessionDate -Text ([datetime]'2026-11-21 16:42:33').ToString('o') | Should -Be '21 nov 2026, 16:42'
    }

    It 'Get-AfSessionStateText con cada caso' {
        Get-AfSessionStateText -Session (New-FakeSession @((New-Change 'a' 'Applied'), (New-Change 'b' 'Applied'))) | Should -Be 'Aplicada'
        Get-AfSessionStateText -Session (New-FakeSession @((New-Change 'a' 'Undone'), (New-Change 'b' 'Undone'))) | Should -Be 'Deshecha'
        Get-AfSessionStateText -Session (New-FakeSession @((New-Change 'a' 'Applied'), (New-Change 'b' 'Undone'))) | Should -Be 'Deshecha en parte'
        Get-AfSessionStateText -Session (New-FakeSession @((New-Change 'a' 'Failed'))) | Should -Be 'Sin cambios'
    }

    It 'Show-AfHistory muestra una sesión por archivo, la más nueva primero' {
        $dir = Join-Path $TestDrive 'dos'
        $old = New-AfSession -Directory $dir -User $script:user -Now ([datetime]'2026-11-20 10:00:00')
        $new = New-AfSession -Directory $dir -User $script:user -Now ([datetime]'2026-11-21 16:42:00')
        foreach ($s in $old, $new) { [void]$s.Changes.Add((New-Change 'gpu.hags' 'Applied')); Save-AfSession -Session $s }
        $w = New-AfWindow -Theme Black
        $state = Get-AfUiState -Window $w
        $state.BackupDirectory = $dir
        $state.Phase = 'ready'
        Show-AfHistory -Window $w
        $list = $w.FindName('HistoryList')
        $list.Children.Count | Should -Be 2
        $list.Children[0].Tag | Should -Be $new.Path
        $w.FindName('Title').Text | Should -Be 'Historial'
        $w.FindName('GaugeArea').Visibility | Should -Be 'Collapsed'
        $w.FindName('GhostText').Text | Should -Be 'Volver'
        $w.Tag.Phase | Should -Be 'history'
        @(Get-Buttons $list.Children[0] | ForEach-Object Content) | Should -Be @('Deshacer todo', 'Deshacer')
        $w.Close()
    }

    It 'un cambio de temporales dice que no se puede deshacer y no tiene botón' {
        $card = New-AfHistorySession -Session (New-FakeSession @(New-Change 'storage.temp' 'Applied' 'Action'))
        @(Get-Buttons $card).Count | Should -Be 0
        Get-AfChangeStateText -Change (New-Change 'storage.temp' 'Applied' 'Action') | Should -Be 'Aplicado, no se puede deshacer'
    }

    It 'elegir una categoría desde el Historial vuelve a la lista con esa categoría' {
        $w = New-ResultsWindow
        Show-AfHistory -Window $w
        Set-AfFilter -Window $w -Filter 'gaming'
        $w.FindName('HistoryPanel').Visibility | Should -Be 'Collapsed'
        $w.FindName('PanelBorder').Visibility | Should -Be 'Visible'
        $w.FindName('GaugeArea').Visibility | Should -Be 'Visible'
        $w.FindName('Title').Text | Should -Not -Be 'Historial'
        $w.Tag.Phase | Should -Be 'ready'
        $w.Tag.Filter | Should -Be 'gaming'
        @($w.FindName('Groups').Children | Where-Object { $_.Visibility -eq 'Visible' } | ForEach-Object Tag) | Should -Be @('gaming')
        $w.Close()
    }

    It 'mientras deshace desde el Historial, la navegación no lo cierra' {
        $w = New-ResultsWindow
        Show-AfHistory -Window $w
        $w.Tag.Phase = 'undoing'
        Set-AfFilter -Window $w -Filter 'gaming'
        $w.FindName('HistoryPanel').Visibility | Should -Be 'Visible'
        $w.Tag.Phase | Should -Be 'undoing'
        $w.Close()
    }

    It 'sin sesiones muestra el texto vacío' {
        $w = New-AfWindow -Theme Black
        $state = Get-AfUiState -Window $w
        $state.BackupDirectory = Join-Path $TestDrive 'vacia'
        Show-AfHistory -Window $w
        $list = $w.FindName('HistoryList')
        $list.Children.Count | Should -Be 1
        $list.Children[0].Text | Should -Be 'Todavía no se aplicaron cambios en esta PC.'
        $w.Close()
    }
}
