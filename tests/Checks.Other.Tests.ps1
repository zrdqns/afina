BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    function Test-Check([string]$Id, $Inventory) {
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id }
        if (-not $check) { throw "No existe la revisión $Id" }
        Invoke-AfCheck -Check $check -Inventory $Inventory
    }
    function New-Entry([string]$Name, [string]$Path, [bool]$Enabled = $true) {
        [pscustomobject]@{ Name = $Name; Command = $Path; Path = $Path; Source = 'Run'; Scope = 'User'; Enabled = $Enabled; IsSigned = $true; Signer = 'X'; InUserWritablePath = $false }
    }
    function New-Storage([long]$TempUser = 0, [double]$Free = 200, [double]$Size = 476, [string]$Media = 'SSD', $Trim = $true) {
        [pscustomobject]@{ SystemDrive = 'C:'; FreeGB = $Free; SizeGB = $Size; MediaType = $Media; BusType = 'NVMe'; TrimEnabled = $Trim
            TempBytes = [pscustomobject]@{ User = $TempUser; Windows = 0; UpdateCache = 0; DeliveryOptimization = 0; ErrorReports = 0 } }
    }
}

Describe 'startup.apps' {
    It 'preselecciona Epic y no Steam' {
        $inv = New-AfFakeInventory -Override @{ Startup = @(
                New-Entry 'EpicGamesLauncher' 'C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe'
                New-Entry 'Steam' 'C:\Program Files (x86)\Steam\steam.exe'
            ) }
        $r = Test-Check 'startup.apps' $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeTrue
        $r.Detection.Title | Should -Be '1 programa menos al arrancar'
        $epic = $r.Detection.Data.Entries | Where-Object Name -eq 'EpicGamesLauncher'
        $steam = $r.Detection.Data.Entries | Where-Object Name -eq 'Steam'
        $epic.Preselected | Should -BeTrue
        $steam.Preselected | Should -BeFalse
    }

    It 'Ok si solo arrancan programas que no sobran' {
        $inv = New-AfFakeInventory -Override @{ Startup = @(New-Entry 'Discord' 'C:\Users\Cliente\AppData\Local\Discord\Update.exe') }
        (Test-Check 'startup.apps' $inv).Detection.State | Should -Be 'Ok'
    }

    It 'ignora las entradas ya desactivadas' {
        $inv = New-AfFakeInventory -Override @{ Startup = @(New-Entry 'Spotify' 'C:\Users\Cliente\AppData\Roaming\Spotify\Spotify.exe' $false) }
        (Test-Check 'startup.apps' $inv).Detection.State | Should -Be 'Ok'
    }
}

Describe 'storage.temp' {
    It 'preselect solo si es mayor que 1 GB' {
        $big = Test-Check 'storage.temp' (New-AfFakeInventory -Override @{ Storage = New-Storage -TempUser 6657199308 })
        $big.Detection.State | Should -Be 'Improvable'
        $big.Detection.Current | Should -Be '6,2 GB'
        $big.Preselected | Should -BeTrue
        $small = Test-Check 'storage.temp' (New-AfFakeInventory -Override @{ Storage = New-Storage -TempUser 524288000 })
        $small.Detection.State | Should -Be 'Improvable'
        $small.Preselected | Should -BeFalse
    }

    It 'Ok con menos de 100 MB' {
        (Test-Check 'storage.temp' (New-AfFakeInventory -Override @{ Storage = New-Storage -TempUser 1048576 })).Detection.State | Should -Be 'Ok'
    }
}

Describe 'storage.free-space' {
    It 'Info con menos de 20 GB libres' {
        $r = Test-Check 'storage.free-space' (New-AfFakeInventory -Override @{ Storage = New-Storage -Free 12 -Size 476 })
        $r.Detection.State | Should -Be 'Info'
        $r.Detection.Current | Should -Be '12 GB libres'
    }
}

Describe 'storage.trim' {
    It 'Improvable si TRIM está apagado en un SSD' {
        (Test-Check 'storage.trim' (New-AfFakeInventory -Override @{ Storage = New-Storage -Trim $false })).Detection.State | Should -Be 'Improvable'
    }

    It 'NotApplicable en un disco duro' {
        (Test-Check 'storage.trim' (New-AfFakeInventory -Override @{ Storage = New-Storage -Media 'HDD' })).Detection.State | Should -Be 'NotApplicable'
    }
}

Describe 'hardware' {
    It 'ram-single-channel es Manual con un solo módulo' {
        $r = Test-Check 'hardware.ram-single-channel' (New-AfFakeInventory)
        $r.Detection.State | Should -Be 'Manual'
        $r.Detection.Current | Should -Be '16 GB en un módulo'
    }

    It 'ram-single-channel no aplica con RAM soldada' {
        $inv = New-AfFakeInventory -Override @{ Memory = [pscustomobject]@{ TotalGB = 16; Socketed = $false; Modules = @([pscustomobject]@{ CapacityGB = 16; Speed = 6400; ConfiguredSpeed = 6400; FormFactor = 0; PartNumber = 'LP'; Locator = 'A' }) } }
        (Test-Check 'hardware.ram-single-channel' $inv).Detection.State | Should -Be 'NotApplicable'
    }

    It 'ram-xmp es Manual en un escritorio con DDR4 a 2133 y número de parte de 3200' {
        $inv = New-AfFakeInventory -Override @{
            Device = [pscustomobject]@{ Manufacturer = 'ASUS'; Model = 'Torre'; IsLaptop = $false; OnBattery = $false }
            Memory = [pscustomobject]@{ TotalGB = 16; Socketed = $true; Modules = @(
                    [pscustomobject]@{ CapacityGB = 8; Speed = 2133; ConfiguredSpeed = 2133; FormFactor = 8; PartNumber = 'F4-3200C16-8GVKB'; Locator = 'A1' }
                    [pscustomobject]@{ CapacityGB = 8; Speed = 2133; ConfiguredSpeed = 2133; FormFactor = 8; PartNumber = 'F4-3200C16-8GVKB'; Locator = 'B1' }) }
        }
        $r = Test-Check 'hardware.ram-xmp' $inv
        $r.Detection.State | Should -Be 'Manual'
        $r.Detection.Target | Should -Be '3200 MT/s'
    }

    It 'ram-low es Info con 8 GB o menos' {
        $inv = New-AfFakeInventory -Override @{ Memory = [pscustomobject]@{ TotalGB = 4; Socketed = $true; Modules = @() } }
        (Test-Check 'hardware.ram-low' $inv).Detection.State | Should -Be 'Info'
    }

    It 'on-battery es Info si la laptop está en batería' {
        $inv = New-AfFakeInventory -Override @{ Device = [pscustomobject]@{ Manufacturer = 'LENOVO'; Model = 'LOQ 15'; IsLaptop = $true; OnBattery = $true } }
        (Test-Check 'hardware.on-battery' $inv).Detection.State | Should -Be 'Info'
    }
}
