# Afina en PCs muy distintas: con gráfica integrada, sin gráfica dedicada, con la gráfica sin driver,
# máquinas virtuales e inventarios a medias. Ninguna revisión puede romperse y la ventana se tiene que dibujar.
BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    . "$PSScriptRoot\Helpers\Profiles.ps1"
    function Invoke-Catalog($Inventory) { @(Get-AfCatalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $Inventory }) }
    function Get-Detection($Results, [string]$Id) { (@($Results | Where-Object { $_.Check.Id -eq $Id })[0]).Detection }

    # Ninguna revisión en Error y la ventana completa se dibuja con ese inventario.
    function Assert-Healthy($Inventory, $Results) {
        $errors = @($Results | Where-Object { $_.Detection.State -eq 'Error' } | ForEach-Object { '{0}: {1}' -f $_.Check.Id, $_.Detection.Note })
        $errors | Should -BeNullOrEmpty
        $window = New-AfWindow -Theme Black
        try {
            Set-AfPcCard -Window $window -Inventory $Inventory
            Show-AfResults -Window $window -Results $Results -Animate $false
            Get-AfScore -Results $Results | Should -BeGreaterOrEqual 0
        } finally { $window.Close() }
    }

    $profiles = Get-AfProfileInventories
    $script:desktopIntel = $profiles.desktopIntel
    $script:laptopApu = $profiles.laptopApu
    $script:noDriver = $profiles.noDriver
    $script:virtualMachine = $profiles.virtualMachine
    $script:broken = $profiles.broken
}

Describe 'Afina en distintas PCs' {
    It 'escritorio con gráfica integrada Intel y Windows 10: no ofrece lo que esa PC no tiene' {
        $r = Invoke-Catalog $script:desktopIntel
        (Get-Detection $r 'gpu.hags').State | Should -Be 'NotApplicable'
        (Get-Detection $r 'gpu.hybrid').State | Should -Be 'NotApplicable'
        (Get-Detection $r 'gpu.driver-missing').State | Should -Be 'Ok'
        (Get-Detection $r 'gaming.windowed-optimizations').State | Should -Be 'NotApplicable'
        (Get-Detection $r 'storage.trim').State | Should -Be 'NotApplicable'
        (Get-Detection $r 'hardware.on-battery').State | Should -Be 'NotApplicable'
        (Get-Detection $r 'hardware.ram-single-channel').State | Should -Be 'Ok'
        (Get-Detection $r 'display.refresh').State | Should -Be 'Improvable'
        (Get-Detection $r 'network.ethernet-power').State | Should -Be 'Improvable'
        Assert-Healthy $script:desktopIntel $r
    }

    It 'laptop solo con gráfica integrada AMD, en batería y RAM soldada' {
        $r = Invoke-Catalog $script:laptopApu
        (Get-Detection $r 'gpu.hags').State | Should -Be 'NotApplicable'
        (Get-Detection $r 'gpu.hybrid').State | Should -Be 'NotApplicable'
        (Get-Detection $r 'hardware.on-battery').State | Should -Be 'Info'
        (Get-Detection $r 'hardware.ram-single-channel').State | Should -Be 'NotApplicable'
        (Get-Detection $r 'network.wifi-power').State | Should -Be 'Improvable'
        (Get-Detection $r 'network.ethernet-power').State | Should -Be 'NotApplicable'
        Assert-Healthy $script:laptopApu $r
    }

    It 'gráfica sin driver: lo dice primero y no culpa al cable ni sugiere cambios de GPU' {
        $r = Invoke-Catalog $script:noDriver
        $missing = Get-Detection $r 'gpu.driver-missing'
        $missing.State | Should -Be 'Manual'
        $missing.Title | Should -Be 'La gráfica de NVIDIA no tiene su driver'
        (Get-Detection $r 'gpu.driver-age').State | Should -Be 'NotApplicable'
        (Get-Detection $r 'gpu.hags').State | Should -Be 'NotApplicable'
        (Get-Detection $r 'display.cable-limit').State | Should -Be 'NotApplicable'
        Assert-Healthy $script:noDriver $r
        $window = New-AfWindow -Theme Black
        try {
            Set-AfPcCard -Window $window -Inventory $script:noDriver
            @($window.FindName('Specs').Children | ForEach-Object { $_.Children[1].Text }) | Should -Contain 'NVIDIA, sin driver'
        } finally { $window.Close() }
    }

    It 'máquina virtual o PC sin gráfica física ni red' {
        $r = Invoke-Catalog $script:virtualMachine
        foreach ($id in 'gpu.hags', 'gpu.driver-missing', 'gpu.driver-age', 'gpu.hybrid', 'network.ethernet-power', 'network.wifi-power', 'network.link-100', 'security.signatures', 'security.pua') {
            (Get-Detection $r $id).State | Should -Be 'NotApplicable' -Because $id
        }
        Assert-Healthy $script:virtualMachine $r
    }

    It 'con todas las partes del inventario fallidas, nada se rompe' {
        $r = Invoke-Catalog $script:broken
        $r.Count | Should -Be @(Get-AfCatalog).Count
        Assert-Healthy $script:broken $r
        (Get-AfSummary -Results $r) | Should -Not -BeNullOrEmpty
    }
}
