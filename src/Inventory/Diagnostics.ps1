# Convierte un contador sin lanzar: lo que no cabe en Int64 (UInt64 basura) o no es número queda en $null.
function ConvertTo-AfCounter {
    param($Value)
    if ($null -eq $Value) { return $null }
    try {
        $number = [decimal]$Value
        if ($number -lt 0 -or $number -gt [decimal][long]::MaxValue) { return $null }
        [long]$number
    } catch { $null }
}

function Get-AfFailurePrediction {
    try {
        [bool]@(Get-CimInstance -Namespace 'root\wmi' -ClassName MSStorageDriver_FailurePredictStatus -OperationTimeoutSec 15 -ErrorAction Stop | Where-Object { $_.PredictFailure }).Count
    } catch { $false }
}

function Get-AfDiskHealth {
    # La predicción se lee aparte: no debe perderse si la lista de discos falla.
    $predict = Get-AfFailurePrediction
    $list = @()
    try {
        # MSFT_PhysicalDisk por CIM (con tiempo límite): HealthStatus 0 Healthy, 1 Warning, 2 Unhealthy, 5 Unknown.
        $disks = @(Get-CimInstance -Namespace 'root\Microsoft\Windows\Storage' -ClassName MSFT_PhysicalDisk -OperationTimeoutSec 15 -ErrorAction Stop)
        $busNames = @{ 3 = 'ATA'; 6 = 'FireWire'; 8 = 'RAID'; 9 = 'iSCSI'; 10 = 'SAS'; 11 = 'SATA'; 12 = 'SD'; 13 = 'MMC'; 16 = 'Spaces'; 17 = 'NVMe' }
        $healthNames = @{ 0 = 'Healthy'; 1 = 'Warning'; 2 = 'Unhealthy'; 5 = 'Unknown' }
        foreach ($disk in $disks) {
            # Después de Get-PhysicalDisk (lo usa el inventario), el módulo Storage muestra BusType y HealthStatus como texto: se leen los números crudos.
            $raw = $disk.CimInstanceProperties
            $busType = if ($raw -and $raw['BusType']) { [int]$raw['BusType'].Value } else { [int]$disk.BusType }
            $healthStatus = if ($raw -and $raw['HealthStatus']) { [int]$raw['HealthStatus'].Value } else { [int]$disk.HealthStatus }
            # 7 es USB y 15 es un disco virtual de archivo (Docker o WSL): no son discos de la PC.
            if ($busType -in 7, 15) { continue }
            $counter = $null
            try { $counter = @(Get-CimAssociatedInstance -InputObject $disk -ResultClassName MSFT_StorageReliabilityCounter -OperationTimeoutSec 10 -ErrorAction Stop)[0] } catch { $counter = $null }
            $health = $healthNames[$healthStatus]
            $bus = $busNames[$busType]
            $list += @{
                Name = [string]$disk.FriendlyName; BusType = $(if ($bus) { $bus } else { 'Other' }); Health = $(if ($health) { $health } else { 'Unknown' })
                Wear = $(if ($counter) { ConvertTo-AfCounter $counter.Wear } else { $null })
                Temperature = $(if ($counter) { ConvertTo-AfCounter $counter.Temperature } else { $null })
                TemperatureMax = $(if ($counter) { ConvertTo-AfCounter $counter.TemperatureMax } else { $null })
                ReadErrors = $(if ($counter) { ConvertTo-AfCounter $counter.ReadErrorsUncorrected } else { $null })
                WriteErrors = $(if ($counter) { ConvertTo-AfCounter $counter.WriteErrorsUncorrected } else { $null })
            }
        }
    } catch { $list = @() }
    @{ Disks = @($list); PredictFailure = $predict }
}

# Suma las baterías: 0 y 0xFFFFFFFF son "sin dato" y la carga nunca pasa de su diseño. Sin ninguna válida, $null.
function Get-AfBatteryTotals {
    param([object[]]$Batteries)
    $design = 0L; $charge = 0L; $cycles = 0L; $found = $false
    foreach ($battery in @($Batteries | Where-Object { $_ })) {
        $d = [long](ConvertTo-AfCounter $battery.Design)
        $f = [long](ConvertTo-AfCounter $battery.Full)
        if ($d -le 0 -or $d -ge 4294967295 -or $f -le 0 -or $f -ge 4294967295) { continue }
        $found = $true
        $design += $d
        $charge += [math]::Min($f, $d)
        $cycle = ConvertTo-AfCounter $battery.Cycles
        if ($null -ne $cycle -and $cycle -lt 4294967295) { $cycles += $cycle }
    }
    if (-not $found) { return $null }
    @{ DesignMWh = [int]$design; FullMWh = [int]$charge; Cycles = [int]$cycles }
}

# Las baterías según WMI, emparejadas por InstanceName.
function Get-AfBatteryWmi {
    $static = @(Get-CimInstance -Namespace 'root\wmi' -ClassName BatteryStaticData -OperationTimeoutSec 15 -ErrorAction Stop)
    $full = @(Get-CimInstance -Namespace 'root\wmi' -ClassName BatteryFullChargedCapacity -OperationTimeoutSec 15 -ErrorAction Stop)
    $cycleRows = @()
    try { $cycleRows = @(Get-CimInstance -Namespace 'root\wmi' -ClassName BatteryCycleCount -OperationTimeoutSec 15 -ErrorAction Stop) } catch { $cycleRows = @() }
    foreach ($battery in $static) {
        $match = $full | Where-Object { $_.InstanceName -eq $battery.InstanceName } | Select-Object -First 1
        if (-not $match) { continue }
        $cycle = $cycleRows | Where-Object { $_.InstanceName -eq $battery.InstanceName } | Select-Object -First 1
        @{ Design = $battery.DesignedCapacity; Full = $match.FullChargedCapacity; Cycles = $(if ($cycle) { $cycle.CycleCount }) }
    }
}

# Las baterías según el informe de powercfg (XML en %TEMP%, se borra siempre). Funciona sin administrador.
function Get-AfBatteryReport {
    $path = Join-Path $env:TEMP ('afina-bateria-{0}.xml' -f [guid]::NewGuid().ToString('N'))
    try {
        $result = Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\powercfg.exe') -Arguments ('/batteryreport /xml /output "{0}"' -f $path) -TimeoutMs 15000
        if ($result.TimedOut -or $result.ExitCode -ne 0 -or -not [System.IO.File]::Exists($path)) { return }
        $xml = New-Object System.Xml.XmlDocument
        $xml.Load($path)
        foreach ($battery in @($xml.BatteryReport.Batteries.Battery | Where-Object { $_ })) {
            @{ Design = $battery.DesignCapacity; Full = $battery.FullChargeCapacity; Cycles = $battery.CycleCount }
        }
    } finally {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    }
}

function Get-AfBatteryHealth {
    # En algunas laptops (una ASUS) BatteryStaticData falla con "Error genérico" aun como administrador: entonces se usa el informe de powercfg.
    $health = try { Get-AfBatteryTotals -Batteries @(Get-AfBatteryWmi) } catch { $null }
    if ($health) { return $health }
    Get-AfBatteryTotals -Batteries @(Get-AfBatteryReport)
}
function Get-AfBootTimes {
    param([int]$Max = 5, [int]$Days = 30)
    try {
        $events = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 100; StartTime = (Get-Date).AddDays(-$Days) } -ErrorAction Stop)
    } catch {
        # Sin eventos que coincidan no es un fallo: es "sin datos".
        if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*' -or $_.Exception.Message -like '*No events were found*') { return @() }
        throw
    }
    $boots = foreach ($event in $events) {
        # Los campos se leen por nombre: su posición cambia entre versiones de Windows.
        $fields = @{}
        foreach ($data in @(([xml]$event.ToXml()).Event.EventData.Data)) { $fields[[string]$data.Name] = [string]$data.'#text' }
        if ($fields['BootIsRebootAfterInstall'] -eq 'true') { continue }
        if (-not $fields.ContainsKey('MainPathBootTime')) { continue }
        @{ Time = [datetime]$event.TimeCreated; MainPathMs = [int]$fields['MainPathBootTime'] }
    }
    @($boots | Sort-Object { $_.Time } -Descending | Select-Object -First $Max)
}
