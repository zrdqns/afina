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
        # MSFT_PhysicalDisk por CIM (con tiempo límite): HealthStatus 0 Healthy, 1 Warning, 2 Unhealthy, 5 Unknown; BusType 7 es USB.
        $disks = @(Get-CimInstance -Namespace 'root\Microsoft\Windows\Storage' -ClassName MSFT_PhysicalDisk -OperationTimeoutSec 15 -ErrorAction Stop | Where-Object { [int]$_.BusType -ne 7 })
        $busNames = @{ 3 = 'ATA'; 6 = 'FireWire'; 8 = 'RAID'; 9 = 'iSCSI'; 10 = 'SAS'; 11 = 'SATA'; 12 = 'SD'; 13 = 'MMC'; 16 = 'Spaces'; 17 = 'NVMe' }
        $healthNames = @{ 0 = 'Healthy'; 1 = 'Warning'; 2 = 'Unhealthy'; 5 = 'Unknown' }
        foreach ($disk in $disks) {
            $counter = $null
            try { $counter = @(Get-CimAssociatedInstance -InputObject $disk -ResultClassName MSFT_StorageReliabilityCounter -OperationTimeoutSec 10 -ErrorAction Stop)[0] } catch { $counter = $null }
            $health = $healthNames[[int]$disk.HealthStatus]
            $bus = $busNames[[int]$disk.BusType]
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

function Get-AfBatteryHealth {
    $static = @(Get-CimInstance -Namespace 'root\wmi' -ClassName BatteryStaticData -OperationTimeoutSec 15 -ErrorAction Stop)
    $full = @(Get-CimInstance -Namespace 'root\wmi' -ClassName BatteryFullChargedCapacity -OperationTimeoutSec 15 -ErrorAction Stop)
    $cycleRows = @()
    try { $cycleRows = @(Get-CimInstance -Namespace 'root\wmi' -ClassName BatteryCycleCount -OperationTimeoutSec 15 -ErrorAction Stop) } catch { $cycleRows = @() }
    # Se empareja por InstanceName; 0 y 0xFFFFFFFF son "sin dato" y la carga nunca pasa de su diseño.
    $design = 0L; $charge = 0L; $cycles = 0L; $found = $false
    foreach ($battery in $static) {
        $d = [long]$battery.DesignedCapacity
        $match = $full | Where-Object { $_.InstanceName -eq $battery.InstanceName } | Select-Object -First 1
        if (-not $match) { continue }
        $f = [long]$match.FullChargedCapacity
        if ($d -le 0 -or $d -ge 4294967295 -or $f -le 0 -or $f -ge 4294967295) { continue }
        $found = $true
        $design += $d
        $charge += [math]::Min($f, $d)
        $cycle = $cycleRows | Where-Object { $_.InstanceName -eq $battery.InstanceName } | Select-Object -First 1
        if ($cycle -and [long]$cycle.CycleCount -lt 4294967295) { $cycles += [long]$cycle.CycleCount }
    }
    if (-not $found) { return $null }
    @{ DesignMWh = [int]$design; FullMWh = [int]$charge; Cycles = [int]$cycles }
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
