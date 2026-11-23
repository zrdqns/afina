function Get-AfDiskHealth {
    # Sin discos USB. Los contadores de desgaste pueden fallar (sin permisos o sin soporte): el disco sigue con su salud.
    $disks = @(Get-PhysicalDisk -ErrorAction Stop | Where-Object { [string]$_.BusType -ne 'USB' })
    $list = foreach ($disk in $disks) {
        $counter = $null
        try { $counter = $disk | Get-StorageReliabilityCounter -ErrorAction Stop } catch { $counter = $null }
        @{
            Name = [string]$disk.FriendlyName; BusType = [string]$disk.BusType; Health = [string]$disk.HealthStatus
            Wear = $(if ($counter -and $null -ne $counter.Wear) { [int]$counter.Wear } else { $null })
            Temperature = $(if ($counter -and $null -ne $counter.Temperature) { [int]$counter.Temperature } else { $null })
            TemperatureMax = $(if ($counter -and $null -ne $counter.TemperatureMax) { [int]$counter.TemperatureMax } else { $null })
            ReadErrors = $(if ($counter -and $null -ne $counter.ReadErrorsUncorrected) { [long]$counter.ReadErrorsUncorrected } else { $null })
            WriteErrors = $(if ($counter -and $null -ne $counter.WriteErrorsUncorrected) { [long]$counter.WriteErrorsUncorrected } else { $null })
        }
    }
    $predict = $false
    try {
        $status = @(Get-CimInstance -Namespace 'root\wmi' -ClassName MSStorageDriver_FailurePredictStatus -OperationTimeoutSec 15 -ErrorAction Stop)
        $predict = [bool]@($status | Where-Object { $_.PredictFailure }).Count
    } catch { $predict = $false }
    @{ Disks = @($list); PredictFailure = $predict }
}

function Get-AfBatteryHealth {
    $static = @(Get-CimInstance -Namespace 'root\wmi' -ClassName BatteryStaticData -OperationTimeoutSec 15 -ErrorAction Stop)
    $full = @(Get-CimInstance -Namespace 'root\wmi' -ClassName BatteryFullChargedCapacity -OperationTimeoutSec 15 -ErrorAction Stop)
    if (-not $static.Count -or -not $full.Count) { return $null }
    $cycles = 0
    try { $cycles = [int](@(Get-CimInstance -Namespace 'root\wmi' -ClassName BatteryCycleCount -OperationTimeoutSec 15 -ErrorAction Stop) | Measure-Object -Property CycleCount -Sum).Sum } catch { $cycles = 0 }
    @{
        DesignMWh = [int](($static | Measure-Object -Property DesignedCapacity -Sum).Sum)
        FullMWh = [int](($full | Measure-Object -Property FullChargedCapacity -Sum).Sum)
        Cycles = $cycles
    }
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
