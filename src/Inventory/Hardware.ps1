function Get-AfCpuInfo {
    $cpu = Get-CimInstance -ClassName Win32_Processor -OperationTimeoutSec 15 | Select-Object -First 1
    [pscustomobject]@{ Name = ([string]$cpu.Name).Trim(); Cores = [int]$cpu.NumberOfCores; Threads = [int]$cpu.NumberOfLogicalProcessors }
}

# Fabricante por el identificador PCI (no cambia con el idioma ni con el driver); si no está, por el nombre.
function Get-AfGpuVendor {
    param([string]$PnpId, [string]$Text)
    if ($PnpId -match 'VEN_10DE') { return 'NVIDIA' }
    if ($PnpId -match 'VEN_(1002|1022)') { return 'AMD' }
    if ($PnpId -match 'VEN_8086') { return 'Intel' }
    switch -Regex ($Text) {
        'NVIDIA' { 'NVIDIA'; break }
        'Advanced Micro Devices|AMD|ATI ' { 'AMD'; break }
        'Intel' { 'Intel'; break }
        default { 'Other' }
    }
}

# Solo gráficas físicas (PCI). Se saltan las virtuales, remotas o por USB: Hyper-V, VMware, VirtualBox, QEMU,
# Escritorio remoto, Parsec, DisplayLink. Una gráfica física con display.inf ("Adaptador de pantalla básico") no tiene su driver.
function Get-AfGpuInfo {
    $virtualName = 'Remote Display|Virtual|Hyper-V|VMware|VirtualBox|Parsec|Citrix|Mirage|DisplayLink'
    $virtualVendor = 'VEN_(15AD|80EE|1414|1234|1AF4|1B36|5333)'
    foreach ($gpu in @(Get-CimInstance -ClassName Win32_VideoController -OperationTimeoutSec 15)) {
        $name = ([string]$gpu.Name).Trim()
        $pnp = [string]$gpu.PNPDeviceID
        if ($pnp -notlike 'PCI\*' -or $pnp -match $virtualVendor -or $name -match $virtualName) { continue }
        $vendor = Get-AfGpuVendor -PnpId $pnp -Text (([string]$gpu.AdapterCompatibility) + ' ' + $name)
        [pscustomobject]@{
            Name = $name
            Vendor = $vendor
            IsDiscrete = $vendor -eq 'NVIDIA' -or $name -match 'Radeon RX|Radeon Pro|Arc A\d|Arc B\d'
            HasDriver = ([string]$gpu.InfFilename) -ne 'display.inf'
            DriverVersion = [string]$gpu.DriverVersion
            DriverDate = $gpu.DriverDate
            WddmVersion = Get-AfWddmVersion -DriverVersion $gpu.DriverVersion
            WindowMB = Get-AfGpuWindowMB -PnpId $pnp
        }
    }
}

function Get-AfMemoryInfo {
    $modules = @(Get-CimInstance -ClassName Win32_PhysicalMemory -OperationTimeoutSec 15 | ForEach-Object {
            [pscustomobject]@{
                CapacityGB = [math]::Round([double]$_.Capacity / 1GB, 1)
                Speed = [int]$_.Speed
                ConfiguredSpeed = [int]$_.ConfiguredClockSpeed
                FormFactor = [int]$_.FormFactor
                PartNumber = ([string]$_.PartNumber).Trim()
                Locator = ([string]$_.DeviceLocator).Trim()
            }
        })
    $total = ($modules | Measure-Object -Property CapacityGB -Sum).Sum
    [pscustomobject]@{
        TotalGB = [math]::Round([double]$total)
        # 8 = DIMM, 12 = SODIMM; lo demás es RAM soldada.
        Socketed = $modules.Count -gt 0 -and @($modules | Where-Object { $_.FormFactor -notin 8, 12 }).Count -eq 0
        Modules = $modules
    }
}
