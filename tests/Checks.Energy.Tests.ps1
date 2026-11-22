BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    function Test-Check([string]$Id, $Inventory) {
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id }
        if (-not $check) { throw "No existe la revisión $Id" }
        Invoke-AfCheck -Check $check -Inventory $Inventory
    }
}

Describe 'energy.power-mode' {
    It 'Improvable con overlay 0000 en Equilibrado' {
        $inv = New-AfFakeInventory -Override @{ Power = [pscustomobject]@{ ActiveScheme = '381b4222-f694-41f0-9685-ff5bb260df2e'; OverlayAc = '00000000-0000-0000-0000-000000000000'; WifiPowerAc = 0 } }
        $r = Test-Check 'energy.power-mode' $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Detection.Current | Should -Be 'Equilibrado'
        $r.Detection.Target | Should -Be 'Mejor rendimiento'
        $r.Preselected | Should -BeTrue
    }

    It 'Ok con Mejor rendimiento' {
        (Test-Check 'energy.power-mode' (New-AfFakeInventory)).Detection.State | Should -Be 'Ok'
    }

    It 'Improvable con el plan Ahorro de energía' {
        $inv = New-AfFakeInventory -Override @{ Power = [pscustomobject]@{ ActiveScheme = 'a1841308-3541-4fab-bc81-f71556f20b4a'; OverlayAc = $null; WifiPowerAc = 0 } }
        $r = Test-Check 'energy.power-mode' $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Detection.Current | Should -Be 'Ahorro de energía'
    }

    It 'Ok con un plan propio de alto rendimiento' {
        $inv = New-AfFakeInventory -Override @{ Power = [pscustomobject]@{ ActiveScheme = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'; OverlayAc = $null; WifiPowerAc = 0 } }
        (Test-Check 'energy.power-mode' $inv).Detection.State | Should -Be 'Ok'
    }
}

Describe 'energy.vendor-mode' {
    It 'Manual si VendorTools tiene Lenovo Vantage, con el nombre en el título' {
        $r = Test-Check 'energy.vendor-mode' (New-AfFakeInventory -Override @{ VendorTools = @('Lenovo Vantage') })
        $r.Detection.State | Should -Be 'Manual'
        $r.Detection.Title | Should -Be 'Modo Rendimiento en Lenovo Vantage'
        @($r.Detection.Steps).Count | Should -BeGreaterThan 1
    }

    It 'NotApplicable sin herramientas del fabricante' {
        (Test-Check 'energy.vendor-mode' (New-AfFakeInventory)).Detection.State | Should -Be 'NotApplicable'
    }
}
