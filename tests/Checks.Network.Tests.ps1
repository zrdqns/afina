BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    function Test-Check([string]$Id, $Inventory) {
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id }
        if (-not $check) { throw "No existe la revisión $Id" }
        Invoke-AfCheck -Check $check -Inventory $Inventory
    }
    function New-Nic([string]$Kind = 'Ethernet', [hashtable]$Properties = @{}, [int]$Link = 1000, [int]$Max = 1000, [string]$Status = 'Up') {
        [pscustomobject]@{ Name = $Kind; Kind = $Kind; Description = 'Realtek PCIe GbE Family Controller'; Status = $Status; LinkSpeedMbps = $Link; MaxSpeedMbps = $Max; Properties = $Properties }
    }
}

Describe 'network.ethernet-power' {
    It "Improvable con *EEE=1 y GigaLite=1, y el texto '2 opciones activas'" {
        $inv = New-AfFakeInventory -Override @{ Network = @(New-Nic -Properties @{ '*EEE' = '1'; 'GigaLite' = '1'; 'EnableGreenEthernet' = '0' }) }
        $r = Test-Check 'network.ethernet-power' $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Detection.Current | Should -Be '2 opciones activas'
        $r.Detection.Target | Should -Be 'Apagadas'
        @($r.Detection.Data.Changes).Count | Should -Be 2
    }

    It 'Ok si las claves no existen' {
        $inv = New-AfFakeInventory -Override @{ Network = @(New-Nic -Properties @{ '*JumboPacket' = '1514' }) }
        (Test-Check 'network.ethernet-power' $inv).Detection.State | Should -Be 'Ok'
    }

    It 'NotApplicable sin Ethernet' {
        $inv = New-AfFakeInventory -Override @{ Network = @(New-Nic -Kind 'WiFi') }
        (Test-Check 'network.ethernet-power' $inv).Detection.State | Should -Be 'NotApplicable'
    }
}

Describe 'network.wifi-power' {
    It 'Improvable con ahorro medio en CA' {
        $inv = New-AfFakeInventory -Override @{ Network = @(New-Nic -Kind 'WiFi'); Power = [pscustomobject]@{ ActiveScheme = '381b4222-f694-41f0-9685-ff5bb260df2e'; OverlayAc = $null; WifiPowerAc = 2 } }
        $r = Test-Check 'network.wifi-power' $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Detection.Current | Should -Be 'Ahorro medio'
    }
}

Describe 'network.link-100' {
    It 'Manual con 100 Mbps en un GbE' {
        $inv = New-AfFakeInventory -Override @{ Network = @(New-Nic -Link 100 -Max 1000) }
        $r = Test-Check 'network.link-100' $inv
        $r.Detection.State | Should -Be 'Manual'
        $r.Detection.Current | Should -Be '100 Mbps'
    }

    It 'Ok a 1 Gbps' {
        (Test-Check 'network.link-100' (New-AfFakeInventory)).Detection.State | Should -Be 'Ok'
    }
}

Describe 'network.wifi-band' {
    It 'Info conectado a 2,4 GHz' {
        $inv = New-AfFakeInventory -Override @{ Wlan = [pscustomobject]@{ Connected = $true; BandGHz = 2.4; Channel = 6; Ssid = 'Casa' } }
        $r = Test-Check 'network.wifi-band' $inv
        $r.Detection.State | Should -Be 'Info'
        $r.Detection.Current | Should -Be '2,4 GHz'
    }

    It 'NotApplicable sin Wi-Fi conectado' {
        (Test-Check 'network.wifi-band' (New-AfFakeInventory)).Detection.State | Should -Be 'NotApplicable'
    }
}
