BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    function New-Disk([string]$Health = 'Healthy', $Wear = $null, $Temp = $null, $TempMax = $null, $ReadErrors = $null, $WriteErrors = $null, [string]$Name = 'Disco 1') {
        @{ Name = $Name; BusType = 'NVMe'; Health = $Health; Wear = $Wear; Temperature = $Temp; TemperatureMax = $TempMax; ReadErrors = $ReadErrors; WriteErrors = $WriteErrors }
    }
    function Get-Disk([object[]]$Disks, [bool]$Predict = $false) { Get-AfDiskDetection -Health @{ Disks = $Disks; PredictFailure = $Predict } }
    function New-Battery([int]$Design, [int]$Full, [int]$Cycles = 100) { @{ DesignMWh = $Design; FullMWh = $Full; Cycles = $Cycles } }
    function New-Boots([int[]]$Ms) { $i = 0; @($Ms | ForEach-Object { $i++; @{ Time = ([datetime]'2026-11-20 08:00:00').AddDays(-$i); MainPathMs = $_ } }) }
    function Get-Check([string]$Id) { @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id } }
    function Invoke-Pagefile($Pagefile, [double]$FreeGB = 200) {
        $inv = New-AfFakeInventory -Override @{ Pagefile = $Pagefile; Storage = [pscustomobject]@{ FreeGB = $FreeGB } }
        (Invoke-AfCheck -Check (Get-Check 'hardware.pagefile') -Inventory $inv).Detection
    }
}

Describe 'Get-AfDiskDetection' {
    It 'sano y sin datos de desgaste' {
        $d = Get-Disk @(New-Disk)
        $d.State | Should -Be 'Ok'
        $d.Current | Should -Be 'Buena, sin datos de desgaste'
    }
    It 'desgaste 69 Ok' { (Get-Disk @(New-Disk -Wear 69)).State | Should -Be 'Ok' }
    It 'desgaste 70 Info' { (Get-Disk @(New-Disk -Wear 70)).State | Should -Be 'Info' }
    It 'desgaste 89 Info' { (Get-Disk @(New-Disk -Wear 89)).State | Should -Be 'Info' }
    It 'desgaste 90 Manual' { (Get-Disk @(New-Disk -Wear 90)).State | Should -Be 'Manual' }
    It 'Warning y Unhealthy son Manual' {
        (Get-Disk @(New-Disk -Health 'Warning')).State | Should -Be 'Manual'
        (Get-Disk @(New-Disk -Health 'Unhealthy')).State | Should -Be 'Manual'
    }
    It 'Unknown sin más datos no alarma' { (Get-Disk @(New-Disk -Health 'Unknown')).State | Should -Be 'Ok' }
    It 'errores sin corregir solos nunca pasan de Info' {
        (Get-Disk @(New-Disk -Wear 10 -ReadErrors 5000 -WriteErrors 9000)).State | Should -Be 'Info'
        (Get-Disk @(New-Disk -Wear 10 -ReadErrors 0 -WriteErrors 0)).State | Should -Be 'Ok'
    }
    It 'temperatura en su máximo es Info; TemperatureMax 0 no cuenta' {
        (Get-Disk @(New-Disk -Temp 70 -TempMax 70)).State | Should -Be 'Info'
        (Get-Disk @(New-Disk -Temp 69 -TempMax 70)).State | Should -Be 'Ok'
        (Get-Disk @(New-Disk -Temp 70 -TempMax 0)).State | Should -Be 'Ok'
    }
    It 'PredictFailure es Manual' { (Get-Disk @(New-Disk) $true).State | Should -Be 'Manual' }
    It 'con varios discos muestra el peor' {
        $d = Get-Disk @((New-Disk -Wear 5 -Name 'A'), (New-Disk -Wear 95 -Name 'B'))
        $d.State | Should -Be 'Manual'
        $d.Current | Should -BeLike 'B:*'
        $d.Note | Should -BeLike '*A:*'
    }
    It 'sin discos: NotApplicable' {
        (Get-Disk @()).State | Should -Be 'NotApplicable'
        (Get-Disk $null).State | Should -Be 'NotApplicable'
    }
}

Describe 'Get-AfDiskHealth' {
    It 'si fallan los contadores el disco conserva su salud y lo demás queda en null' {
        # Funciones de prueba en lugar de Mock: el módulo Storage no se deja simular.
        function Get-PhysicalDisk { @([pscustomobject]@{ FriendlyName = 'NVMe'; BusType = 'NVMe'; HealthStatus = 'Healthy' }, [pscustomobject]@{ FriendlyName = 'Pendrive'; BusType = 'USB'; HealthStatus = 'Healthy' }) }
        function Get-StorageReliabilityCounter { param([Parameter(ValueFromPipeline)]$InputObject) process { throw 'sin permiso' } }
        Mock Get-CimInstance { throw 'sin permiso' }
        $h = Get-AfDiskHealth
        @($h.Disks).Count | Should -Be 1
        $h.Disks[0].Health | Should -Be 'Healthy'
        $h.Disks[0].Wear | Should -BeNullOrEmpty
        $h.PredictFailure | Should -BeFalse
    }
}

Describe 'Get-AfBatteryDetection' {
    It '80 Ok' { (Get-AfBatteryDetection -Health (New-Battery 100 80)).State | Should -Be 'Ok' }
    It '79 Info' { (Get-AfBatteryDetection -Health (New-Battery 100 79)).State | Should -Be 'Info' }
    It '60 Info' { (Get-AfBatteryDetection -Health (New-Battery 100 60)).State | Should -Be 'Info' }
    It '59 Manual' { (Get-AfBatteryDetection -Health (New-Battery 100 59)).State | Should -Be 'Manual' }
    It 'null, diseño 0 o carga 0: NotApplicable' {
        (Get-AfBatteryDetection -Health $null).State | Should -Be 'NotApplicable'
        (Get-AfBatteryDetection -Health (New-Battery 0 50)).State | Should -Be 'NotApplicable'
        (Get-AfBatteryDetection -Health (New-Battery 100 0)).State | Should -Be 'NotApplicable'
    }
    It 'carga mayor que el diseño queda en 100 %' {
        $d = Get-AfBatteryDetection -Health (New-Battery 100 120)
        $d.State | Should -Be 'Ok'
        $d.Data.Percent | Should -Be 100
    }
}

Describe 'Get-AfBootDetection' {
    It 'usa la mediana: 30, 40, 200, 35, 38 s da 38 s y Ok' {
        $d = Get-AfBootDetection -Boots (New-Boots 30000, 40000, 200000, 35000, 38000)
        $d.State | Should -Be 'Ok'
        $d.Data.Seconds | Should -Be 38
    }
    It 'mediana de 60 s es Ok' { (Get-AfBootDetection -Boots (New-Boots 60000)).State | Should -Be 'Ok' }
    It 'mediana de 61 s es Info, nunca Manual' { (Get-AfBootDetection -Boots (New-Boots 61000)).State | Should -Be 'Info' }
    It 'sin eventos: Info con Sin datos recientes' {
        $d = Get-AfBootDetection -Boots @()
        $d.State | Should -Be 'Info'
        $d.Current | Should -Be 'Sin datos recientes'
    }
    It 'la nota trae la fecha del último arranque' {
        $d = Get-AfBootDetection -Boots (New-Boots 30000, 40000)
        $d.Note | Should -BeLike ('*' + ([datetime]'2026-11-19 08:00:00').ToString('g', (Get-AfCulture)))
    }
}

Describe 'Get-AfBootTimes' {
    It 'lee los campos por nombre, descarta los de después de instalar y ordena' {
        function New-Event([datetime]$Time, [string]$Xml) {
            $e = [pscustomobject]@{ TimeCreated = $Time }
            $e | Add-Member -MemberType ScriptMethod -Name ToXml -Value ([scriptblock]::Create("'$Xml'"))
            $e
        }
        $a = '<Event><EventData><Data Name="BootIsRebootAfterInstall">false</Data><Data Name="MainPathBootTime">31000</Data></EventData></Event>'
        $b = '<Event><EventData><Data Name="MainPathBootTime">99000</Data><Data Name="BootIsRebootAfterInstall">true</Data></EventData></Event>'
        $c = '<Event><EventData><Data Name="MainPathBootTime">45000</Data></EventData></Event>'
        Mock Get-WinEvent { @((New-Event ([datetime]'2026-11-10') $a), (New-Event ([datetime]'2026-11-15') $b), (New-Event ([datetime]'2026-11-18') $c)) }
        $boots = @(Get-AfBootTimes)
        $boots.Count | Should -Be 2
        $boots[0].MainPathMs | Should -Be 45000
        $boots[1].MainPathMs | Should -Be 31000
    }
    It 'sin eventos que coincidan devuelve vacío' {
        Mock Get-WinEvent { Write-Error 'No events were found that match the specified selection criteria.' -ErrorId 'NoMatchingEventsFound' }
        @(Get-AfBootTimes).Count | Should -Be 0
    }
}

Describe 'filas de diagnóstico' {
    It 'las tres lecturas asincrónicas se anuncian como Reading + Async' {
        foreach ($id in 'hardware.disk-health', 'hardware.battery-health', 'hardware.boot-time') {
            $check = Get-Check $id
            $check.Reading | Should -BeTrue
            $check.Async | Should -BeTrue
            $d = & $check.Detect (New-AfFakeInventory)
            $d.State | Should -Be 'Info'
            $d.Data.Async | Should -BeTrue
        }
    }
    It 'la batería solo aplica en laptops' {
        $inv = New-AfFakeInventory -Override @{ Device = [pscustomobject]@{ IsLaptop = $false; OnBattery = $false } }
        (Invoke-AfCheck -Check (Get-Check 'hardware.battery-health') -Inventory $inv).Detection.State | Should -Be 'NotApplicable'
    }
    It 'si falla la lectura, disco y batería son NotApplicable y arranque Sin datos recientes' {
        Mock Get-AfDiskHealth { throw 'x' }
        Mock Get-AfBatteryHealth { throw 'x' }
        Mock Get-AfBootTimes { throw 'x' }
        $inv = New-AfFakeInventory
        (& (Get-Check 'hardware.disk-health').AsyncDetect $inv).State | Should -Be 'NotApplicable'
        (& (Get-Check 'hardware.battery-health').AsyncDetect $inv).State | Should -Be 'NotApplicable'
        (& (Get-Check 'hardware.boot-time').AsyncDetect $inv).Current | Should -Be 'Sin datos recientes'
    }
    It 'van antes que las de RAM' {
        $ids = @(Get-AfCatalog | Where-Object { $_.Category -eq 'hardware' } | ForEach-Object { $_.Id })
        $ids.IndexOf('hardware.pagefile') | Should -BeLessThan $ids.IndexOf('hardware.ram-single-channel')
    }
}

Describe 'hardware.pagefile' {
    It 'no es Async, es Auto, marcado y pide reinicio' {
        $c = Get-Check 'hardware.pagefile'
        $c.Async | Should -BeFalse
        $c.Kind | Should -Be 'Auto'
        $c.Preselect | Should -BeTrue
        $c.NeedsReboot | Should -BeTrue
        $c.Reading | Should -BeTrue
    }
    It 'automático: Ok' { (Invoke-Pagefile @{ Automatic = $true; Files = @() }).State | Should -Be 'Ok' }
    It 'apagado: Improvable y marcado' {
        $inv = New-AfFakeInventory -Override @{ Pagefile = @{ Automatic = $false; Files = @() } }
        $r = Invoke-AfCheck -Check (Get-Check 'hardware.pagefile') -Inventory $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeTrue
    }
    It 'fijo de 2048 MB: Improvable' { (Invoke-Pagefile @{ Automatic = $false; Files = @(@{ Name = 'C:\pagefile.sys'; MaxMB = 2048 }) }).State | Should -Be 'Improvable' }
    It 'propio de 4096 MB o más: Ok' {
        (Invoke-Pagefile @{ Automatic = $false; Files = @(@{ Name = 'C:\pagefile.sys'; MaxMB = 4096 }) }).State | Should -Be 'Ok'
        (Invoke-Pagefile @{ Automatic = $false; Files = @(@{ Name = 'C:\pagefile.sys'; MaxMB = 4095 }) }).State | Should -Be 'Improvable'
    }
    It 'MaximumSize 0 (del sistema): Ok' { (Invoke-Pagefile @{ Automatic = $false; Files = @(@{ Name = 'C:\pagefile.sys'; MaxMB = 0 }) }).State | Should -Be 'Ok' }
    It 'apagado con menos de 4 GB libres: Manual; con 4 GB, Improvable' {
        (Invoke-Pagefile @{ Automatic = $false; Files = @() } 3.9).State | Should -Be 'Manual'
        (Invoke-Pagefile @{ Automatic = $false; Files = @() } 4).State | Should -Be 'Improvable'
    }
    It 'lectura fallida (null): NotApplicable, nunca apagado' {
        $inv = New-AfFakeInventory -Override @{ Pagefile = $null }
        (Invoke-AfCheck -Check (Get-Check 'hardware.pagefile') -Inventory $inv).Detection.State | Should -Be 'NotApplicable'
    }
    It 'Apply llama a Set-AfPagefileAuto con la transacción' {
        Mock Set-AfPagefileAuto { $true }
        $inv = New-AfFakeInventory
        $tx = New-AfTransaction -User $inv.User
        & (Get-Check 'hardware.pagefile').Apply $inv $null $tx
        Should -Invoke Set-AfPagefileAuto -Times 1 -Exactly
    }
}
