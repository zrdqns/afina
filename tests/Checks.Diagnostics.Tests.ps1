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
    function Invoke-Pagefile($Pagefile, [long]$FreeBytes = 200GB) {
        $inv = New-AfFakeInventory -Override @{ Pagefile = $Pagefile; Storage = [pscustomobject]@{ FreeBytes = $FreeBytes; FreeGB = [math]::Round($FreeBytes / 1GB) } }
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
    It 'Unknown con desgaste conocido muestra el desgaste, no "Sin datos de desgaste"' {
        $d = Get-Disk @(New-Disk -Health 'Unknown' -Wear 20)
        $d.State | Should -Be 'Ok'
        $d.Current | Should -Be 'Desgaste 20 %'
        (Get-Disk @(New-Disk -Health 'Unknown')).Current | Should -Be 'Sin datos de desgaste'
    }
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
    BeforeAll {
        # Formas reales de MSFT_PhysicalDisk: HealthStatus y BusType son números (UInt16).
        # Un CimInstance real (solo cliente): Get-CimAssociatedInstance no acepta otra cosa.
        function New-CimDisk([string]$Name, [uint16]$Health = 0, [uint16]$Bus = 17) {
            New-CimInstance -ClassName 'MSFT_PhysicalDisk' -Namespace 'root/Microsoft/Windows/Storage' -ClientOnly -Property @{ FriendlyName = $Name; HealthStatus = $Health; BusType = $Bus }
        }
    }
    It 'si fallan los contadores el disco conserva su salud y lo demás queda en null' {
        Mock Get-CimInstance { if ($ClassName -eq 'MSFT_PhysicalDisk') { @((New-CimDisk 'NVMe'), (New-CimDisk 'Pendrive' 0 7)) } else { throw 'sin permiso' } }
        Mock Get-CimAssociatedInstance { throw 'sin permiso' }
        $h = Get-AfDiskHealth
        @($h.Disks).Count | Should -Be 1
        $h.Disks[0].Health | Should -Be 'Healthy'
        $h.Disks[0].BusType | Should -Not -Be 'USB'
        $h.Disks[0].Wear | Should -BeNullOrEmpty
        $h.PredictFailure | Should -BeFalse
    }
    It 'un contador fuera de rango en un disco no borra el diagnóstico de los demás' {
        Mock Get-CimInstance { if ($ClassName -eq 'MSFT_PhysicalDisk') { @((New-CimDisk 'Malo' 2), (New-CimDisk 'RAID')) } else { throw 'x' } }
        Mock Get-CimAssociatedInstance {
            if ($InputObject.FriendlyName -eq 'RAID') { [pscustomobject]@{ Wear = [uint16]5; Temperature = [uint16]40; TemperatureMax = [uint16]70; ReadErrorsUncorrected = [uint64]::MaxValue; WriteErrorsUncorrected = [uint64]3 } }
        }
        $h = Get-AfDiskHealth
        @($h.Disks).Count | Should -Be 2
        $h.Disks[1].ReadErrors | Should -BeNullOrEmpty
        $h.Disks[1].WriteErrors | Should -Be 3
        (Get-AfDiskDetection -Health $h).State | Should -Be 'Manual'
    }
    It 'lee los discos y contadores con tiempo límite' {
        Mock Get-CimInstance { if ($ClassName -eq 'MSFT_PhysicalDisk') { @(New-CimDisk 'NVMe') } else { throw 'x' } }
        Mock Get-CimAssociatedInstance { $null }
        Get-AfDiskHealth | Out-Null
        Should -Invoke Get-CimInstance -ParameterFilter { $ClassName -eq 'MSFT_PhysicalDisk' -and $OperationTimeoutSec -gt 0 }
        Should -Invoke Get-CimAssociatedInstance -ParameterFilter { $ResultClassName -eq 'MSFT_StorageReliabilityCounter' -and $OperationTimeoutSec -gt 0 }
    }
    It 'la predicción de falla se lee aunque falle la lectura de discos' {
        Mock Get-CimInstance { if ($ClassName -eq 'MSStorageDriver_FailurePredictStatus') { @([pscustomobject]@{ PredictFailure = $true }) } else { throw 'colgado' } }
        $h = Get-AfDiskHealth
        $h.PredictFailure | Should -BeTrue
        @($h.Disks).Count | Should -Be 0
        (Get-AfDiskDetection -Health $h).State | Should -Be 'Manual'
    }
    It 'con BusType y HealthStatus visibles como texto (tras Get-PhysicalDisk) usa los números crudos' {
        # Así llegan después del inventario: el módulo Storage cambia lo visible, el valor crudo sigue siendo el número.
        $script:textDisk = New-CimDisk 'NVMe WD' 0 17
        $script:textDisk | Add-Member -MemberType ScriptProperty -Name BusType -Value { 'NVMe' } -Force
        $script:textDisk | Add-Member -MemberType ScriptProperty -Name HealthStatus -Value { 'Healthy' } -Force
        Mock Get-CimInstance { if ($ClassName -eq 'MSFT_PhysicalDisk') { @($script:textDisk) } else { throw 'x' } }
        Mock Get-CimAssociatedInstance { $null }
        $h = Get-AfDiskHealth
        @($h.Disks).Count | Should -Be 1
        $h.Disks[0].BusType | Should -Be 'NVMe'
        $h.Disks[0].Health | Should -Be 'Healthy'
    }
    It 'deja fuera los discos USB (7) y los virtuales de archivo (15, Docker o WSL)' {
        Mock Get-CimInstance { if ($ClassName -eq 'MSFT_PhysicalDisk') { @((New-CimDisk 'Msft Virtual Disk' 0 15), (New-CimDisk 'Pendrive' 0 7), (New-CimDisk 'NVMe')) } else { throw 'x' } }
        Mock Get-CimAssociatedInstance { $null }
        @((Get-AfDiskHealth).Disks | ForEach-Object { $_.Name }) | Should -Be @('NVMe')
    }
    It 'en esta PC, después del inventario, lee al menos un disco (solo lectura)' -Tag 'Integration' {
        $null = Get-AfInventory
        @((Get-AfDiskHealth).Disks).Count | Should -BeGreaterThan 0
    }
}

Describe 'Get-AfDiskDetection: casos de la revisión' {
    It 'sin discos pero con falla predicha: Manual' { (Get-Disk @() $true).State | Should -Be 'Manual' }
    It 'el estado del disco sale en el idioma de la interfaz, no en crudo' {
        (Get-Disk @(New-Disk -Health 'Unhealthy' -Name 'E:')).Current | Should -Not -Match 'Unhealthy'
        (Get-Disk @(New-Disk -Health 'Warning' -Name 'E:')).Current | Should -Not -Match 'Warning'
        $d = Get-Disk @(New-Disk -Health 'Raro' -Name 'E:')
        $d.State | Should -Be 'Manual'
        $d.Current | Should -Not -Match 'Raro'
    }
}

Describe 'Get-AfBatteryHealth' {
    BeforeAll {
        function New-Static([string]$Name, $Design) { [pscustomobject]@{ InstanceName = $Name; DesignedCapacity = [uint32]$Design } }
        function New-Full([string]$Name, $Full) { [pscustomobject]@{ InstanceName = $Name; FullChargedCapacity = [uint32]$Full } }
        # El informe de powercfg queda simulado sin datos: ninguna prueba corre el powercfg real.
        function Set-BatteryMocks($Static, $Full, $Cycles = @()) {
            $script:bat = @{ BatteryStaticData = $Static; BatteryFullChargedCapacity = $Full; BatteryCycleCount = $Cycles }
            Mock Get-CimInstance { $script:bat[$ClassName] }
            Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 1; Output = ''; Error = ''; TimedOut = $false } }
        }
        # Simula powercfg /batteryreport: escribe el XML de ejemplo donde pide /output.
        function Set-ReportMock([string]$Xml) {
            $script:reportXml = $Xml
            Mock Invoke-AfProcess {
                $out = [regex]::Match($Arguments, '/output "([^"]+)"').Groups[1].Value
                [System.IO.File]::WriteAllText($out, $script:reportXml, (New-Object System.Text.UTF8Encoding($true)))
                [pscustomobject]@{ ExitCode = 0; Output = ''; Error = ''; TimedOut = $false }
            }
        }
        function New-ReportXml([string[]]$Batteries) {
            $items = @($Batteries | ForEach-Object { $d, $f, $c = $_ -split ','; "<Battery><Id>B</Id><DesignCapacity>$d</DesignCapacity><FullChargeCapacity>$f</FullChargeCapacity><CycleCount>$c</CycleCount></Battery>" }) -join ''
            '<?xml version="1.0" encoding="utf-8"?><BatteryReport xmlns="http://schemas.microsoft.com/battery/2012"><Batteries>{0}</Batteries><RuntimeEstimates><DesignCapacity><Capacity>1</Capacity></DesignCapacity></RuntimeEstimates></BatteryReport>' -f $items
        }
    }
    BeforeEach {
        $script:savedTemp = $env:TEMP
        $env:TEMP = "$TestDrive"
    }
    AfterEach { $env:TEMP = $script:savedTemp }
    It 'una batería' {
        Set-BatteryMocks @(New-Static 'A' 50000) @(New-Full 'A' 48000) @([pscustomobject]@{ InstanceName = 'A'; CycleCount = [uint32]120 })
        $h = Get-AfBatteryHealth
        $h.DesignMWh | Should -Be 50000
        $h.FullMWh | Should -Be 48000
        $h.Cycles | Should -Be 120
    }
    It 'dos de diseño y una con carga: se empareja por InstanceName (no 48 %)' {
        Set-BatteryMocks @((New-Static 'A' 50000), (New-Static 'B' 50000)) @(New-Full 'A' 48000)
        $h = Get-AfBatteryHealth
        $h.DesignMWh | Should -Be 50000
        $h.FullMWh | Should -Be 48000
    }
    It 'una segunda batería con carga 0 o desconocida se descarta' {
        Set-BatteryMocks @((New-Static 'A' 50000), (New-Static 'B' 50000)) @((New-Full 'A' 48000), (New-Full 'B' 0))
        (Get-AfBatteryHealth).DesignMWh | Should -Be 50000
        Set-BatteryMocks @((New-Static 'A' 50000), (New-Static 'B' 50000)) @((New-Full 'A' 48000), (New-Full 'B' 4294967295))
        (Get-AfBatteryHealth).FullMWh | Should -Be 48000
    }
    It 'la carga de cada batería se limita a su diseño antes de sumar' {
        Set-BatteryMocks @((New-Static 'A' 50000), (New-Static 'B' 50000)) @((New-Full 'A' 20000), (New-Full 'B' 80000))
        $h = Get-AfBatteryHealth
        $h.DesignMWh | Should -Be 100000
        $h.FullMWh | Should -Be 70000
    }
    It 'diseño desconocido o sin pareja: null' {
        Set-BatteryMocks @(New-Static 'A' 4294967295) @(New-Full 'A' 48000)
        Get-AfBatteryHealth | Should -BeNullOrEmpty
        Set-BatteryMocks @() @()
        Get-AfBatteryHealth | Should -BeNullOrEmpty
    }
    It 'si WMI lanza (Error genérico), lee el informe de powercfg con tiempo límite y lo borra' {
        Mock Get-CimInstance { throw 'Error genérico' }
        Set-ReportMock (New-ReportXml '55997,50326,0')
        $h = Get-AfBatteryHealth
        $h.DesignMWh | Should -Be 55997
        $h.FullMWh | Should -Be 50326
        $h.Cycles | Should -Be 0
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $FilePath -like '*\powercfg.exe' -and $Arguments -like '/batteryreport /xml /output *' -and $TimeoutMs -ge 10000 }
        @(Get-ChildItem -LiteralPath "$TestDrive" -File).Count | Should -Be 0
    }
    It 'si WMI no trae ninguna batería válida, también cae al informe' {
        Set-BatteryMocks @(New-Static 'A' 4294967295) @(New-Full 'A' 48000)
        Set-ReportMock (New-ReportXml '50000,40000,12')
        (Get-AfBatteryHealth).FullMWh | Should -Be 40000
    }
    It 'con WMI válido no corre powercfg' {
        Set-BatteryMocks @(New-Static 'A' 50000) @(New-Full 'A' 48000)
        (Get-AfBatteryHealth).FullMWh | Should -Be 48000
        Should -Invoke Invoke-AfProcess -Times 0 -Exactly
    }
    It 'el informe se suma como WMI: ignora ceros y 0xFFFFFFFF y limita la carga a su diseño' {
        Mock Get-CimInstance { throw 'Error genérico' }
        Set-ReportMock (New-ReportXml '55997,50326,3', '0,40000,9', '50000,4294967295,9', '50000,60000,12')
        $h = Get-AfBatteryHealth
        $h.DesignMWh | Should -Be 105997
        $h.FullMWh | Should -Be 100326
        $h.Cycles | Should -Be 15
    }
    It 'sin baterías en el informe, o si powercfg falla, devuelve null y no deja archivos' {
        Mock Get-CimInstance { throw 'Error genérico' }
        Set-ReportMock (New-ReportXml @())
        Get-AfBatteryHealth | Should -BeNullOrEmpty
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = $null; Output = ''; Error = ''; TimedOut = $true } }
        Get-AfBatteryHealth | Should -BeNullOrEmpty
        @(Get-ChildItem -LiteralPath "$TestDrive" -File).Count | Should -Be 0
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
    It 'sin salida del lector ($null, como lo entrega la tubería): Info con Sin datos recientes' {
        $d = Get-AfBootDetection -Boots $null
        $d.State | Should -Be 'Info'
        $d.Current | Should -Be 'Sin datos recientes'
    }
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
        (Invoke-Pagefile @{ Automatic = $false; Files = @() } (4GB - 1)).State | Should -Be 'Manual'
        (Invoke-Pagefile @{ Automatic = $false; Files = @() } 4GB).State | Should -Be 'Improvable'
    }
    It 'el umbral usa los bytes reales: 3,6 GB llegan como FreeGB 4 y siguen siendo Manual' {
        $inv = New-AfFakeInventory -Override @{ Pagefile = @{ Automatic = $false; Files = @() }; Storage = [pscustomobject]@{ FreeGB = 4; FreeBytes = [long](3.6GB) } }
        (Invoke-AfCheck -Check (Get-Check 'hardware.pagefile') -Inventory $inv).Detection.State | Should -Be 'Manual'
    }
    It 'sin dato de espacio: Improvable, sin marcar y sin decir nada del disco' {
        $inv = New-AfFakeInventory -Override @{ Pagefile = @{ Automatic = $false; Files = @() }; Storage = $null }
        $r = Invoke-AfCheck -Check (Get-Check 'hardware.pagefile') -Inventory $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeFalse
        $inv2 = New-AfFakeInventory -Override @{ Pagefile = @{ Automatic = $false; Files = @() }; Storage = [pscustomobject]@{ FreeGB = $null } }
        (Invoke-AfCheck -Check (Get-Check 'hardware.pagefile') -Inventory $inv2).Detection.State | Should -Be 'Improvable'
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
