function Get-AfSystemInfo {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -OperationTimeoutSec 15
    $build = [int]$os.BuildNumber
    [pscustomobject]@{
        Caption = ([string]$os.Caption).Trim()
        Build = $build
        Edition = Get-AfRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID'
        IsWin11 = $build -ge 22000
        IsInsider = [bool](Get-AfRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Applicability' -Name 'BranchName')
        Ubr = [int](Get-AfRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'UBR')
    }
}

# Las directivas solo se respetan fuera de Home.
function Test-AfPolicyEdition {
    param($Os)
    -not ([string]$Os.Edition).StartsWith('Core')
}

function Test-AfEnterpriseEdition {
    param($Os)
    ([string]$Os.Edition) -match '^(Enterprise|Education|IoTEnterprise)'
}

# El porcentaje de batería en la bandeja llegó con la 26100.7019.
function Test-AfBatteryPercentBuild {
    param($Os)
    $build = [int]$Os.Build
    $build -gt 26200 -or ($build -in 26100, 26200 -and [int]$Os.Ubr -ge 7019)
}

function Get-AfDeviceInfo {
    $laptopChassis = @(8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32)
    $system = Get-CimInstance -ClassName Win32_ComputerSystem -OperationTimeoutSec 15
    $product = Get-CimInstance -ClassName Win32_ComputerSystemProduct -OperationTimeoutSec 15
    $enclosure = Get-CimInstance -ClassName Win32_SystemEnclosure -OperationTimeoutSec 15 | Select-Object -First 1
    $battery = @(Get-CimInstance -ClassName Win32_Battery -OperationTimeoutSec 15)

    $manufacturer = ([string]$system.Manufacturer).Trim()
    # Lenovo pone el tipo de máquina (83DV) en Model y el nombre comercial en Version.
    $model = if ($manufacturer -match 'LENOVO' -and $product.Version) { ([string]$product.Version).Trim() } else { ([string]$system.Model).Trim() }
    $hasLaptopChassis = @($enclosure.ChassisTypes | Where-Object { $laptopChassis -contains [int]$_ }).Count -gt 0

    [pscustomobject]@{
        Manufacturer = $manufacturer
        Model = $model
        IsLaptop = $hasLaptopChassis -or $battery.Count -gt 0
        OnBattery = $battery.Count -gt 0 -and [int]$battery[0].BatteryStatus -eq 1
    }
}
