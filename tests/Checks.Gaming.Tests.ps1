BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    function Test-Check([string]$Id, $Inventory) {
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id }
        if (-not $check) { throw "No existe la revisión $Id" }
        Invoke-AfCheck -Check $check -Inventory $Inventory
    }
    function New-Display([string]$Name, [int]$Hz, [int]$Max, $Edid = $null, [bool]$Primary = $false) {
        [pscustomobject]@{ DeviceName = $Name; IsPrimary = $Primary; Width = 1920; Height = 1080; Hz = $Hz; MaxHzAtCurrentRes = $Max; EdidMaxHz = $Edid; Modes = @() }
    }
}

Describe 'display.refresh' {
    It 'con dos pantallas, una a 60 de 144, da Improvable con el detalle de esa pantalla' {
        $inv = New-AfFakeInventory -Override @{ Displays = @((New-Display '\\.\DISPLAY1' 165 165 $null $true), (New-Display '\\.\DISPLAY2' 60 144)) }
        $r = Test-Check 'display.refresh' $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Detection.Current | Should -Be '60 Hz'
        $r.Detection.Target | Should -Be '144 Hz'
        @($r.Detection.Data.Displays).Count | Should -Be 1
    }

    It 'Ok si todas están en su máximo' {
        (Test-Check 'display.refresh' (New-AfFakeInventory)).Detection.State | Should -Be 'Ok'
    }
}

Describe 'display.cable-limit' {
    It 'Manual si el EDID anuncia 165 y Windows solo ofrece 60' {
        $inv = New-AfFakeInventory -Override @{ Displays = @(New-Display '\\.\DISPLAY1' 60 60 165 $true) }
        $r = Test-Check 'display.cable-limit' $inv
        $r.Detection.State | Should -Be 'Manual'
        $r.Detection.Target | Should -Be '165 Hz'
    }

    It 'NotApplicable sin datos EDID' {
        $inv = New-AfFakeInventory -Override @{ Displays = @(New-Display '\\.\DISPLAY1' 60 60 $null $true) }
        (Test-Check 'display.cable-limit' $inv).Detection.State | Should -Be 'NotApplicable'
    }
}

Describe 'gpu.hags' {
    It 'NotApplicable con WDDM 2.6' {
        $inv = New-AfFakeInventory -Override @{ Gpus = @([pscustomobject]@{ Name = 'NVIDIA GeForce GTX 1050'; Vendor = 'NVIDIA'; IsDiscrete = $true; DriverVersion = '26.21.14.4250'; DriverDate = (Get-Date); WddmVersion = 2.6 }) }
        (Test-Check 'gpu.hags' $inv).Detection.State | Should -Be 'NotApplicable'
    }

    It 'Improvable con HwSchMode 1 y pide reinicio' {
        $inv = New-AfFakeInventory -Override @{ Registry = @{ 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode' = 1 } }
        $r = Test-Check 'gpu.hags' $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Check.NeedsReboot | Should -BeTrue
    }

    It 'Ok con HwSchMode 2' {
        $inv = New-AfFakeInventory -Override @{ Registry = @{ 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode' = 2 } }
        (Test-Check 'gpu.hags' $inv).Detection.State | Should -Be 'Ok'
    }
}

Describe 'gaming.game-mode' {
    It 'Ok si falta el valor, porque viene activado' {
        (Test-Check 'gaming.game-mode' (New-AfFakeInventory)).Detection.State | Should -Be 'Ok'
    }

    It 'Improvable con AutoGameModeEnabled 0' {
        $inv = New-AfFakeInventory -Override @{ Registry = @{ 'HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled' = 0 } }
        (Test-Check 'gaming.game-mode' $inv).Detection.State | Should -Be 'Improvable'
    }
}

Describe 'gaming.background-recording' {
    It 'Improvable con HistoricalCaptureEnabled 1' {
        $inv = New-AfFakeInventory -Override @{ Registry = @{ 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR|HistoricalCaptureEnabled' = 1 } }
        $r = Test-Check 'gaming.background-recording' $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Detection.Current | Should -Be 'Activa'
    }
}

Describe 'gaming.windowed-optimizations' {
    It 'NotApplicable en Windows 10' {
        $inv = New-AfFakeInventory -Override @{ Os = [pscustomobject]@{ Caption = 'Microsoft Windows 10 Home'; Build = 19045; Edition = 'Core'; IsWin11 = $false; IsInsider = $false } }
        (Test-Check 'gaming.windowed-optimizations' $inv).Detection.State | Should -Be 'NotApplicable'
    }

    It 'Ok si la cadena tiene SwapEffectUpgradeEnable=1' {
        $inv = New-AfFakeInventory -Override @{ Registry = @{ 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences|DirectXUserGlobalSettings' = 'VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;' } }
        (Test-Check 'gaming.windowed-optimizations' $inv).Detection.State | Should -Be 'Ok'
    }

    It 'Improvable si falta' {
        (Test-Check 'gaming.windowed-optimizations' (New-AfFakeInventory)).Detection.State | Should -Be 'Improvable'
    }
}

Describe 'gpu.driver-age' {
    It "Manual con un driver de hace 270 días y el texto 'hace 9 meses'" {
        $inv = New-AfFakeInventory -Override @{ Gpus = @([pscustomobject]@{ Name = 'NVIDIA GeForce RTX 4060 Laptop GPU'; Vendor = 'NVIDIA'; IsDiscrete = $true; DriverVersion = '32.0.15.6094'; DriverDate = (Get-Date).AddDays(-270); WddmVersion = 3.2 }) }
        $r = Test-Check 'gpu.driver-age' $inv
        $r.Detection.State | Should -Be 'Manual'
        $r.Detection.Title | Should -Be 'Driver de NVIDIA de hace 9 meses'
    }

    It 'Ok con un driver de hace un mes' {
        (Test-Check 'gpu.driver-age' (New-AfFakeInventory)).Detection.State | Should -Be 'Ok'
    }
}

Describe 'gpu.hybrid' {
    It 'Info en una laptop con gráfica integrada y dedicada' {
        (Test-Check 'gpu.hybrid' (New-AfFakeInventory)).Detection.State | Should -Be 'Info'
    }
}
