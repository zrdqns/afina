function Get-AfPowerInfo {
    $active = Get-AfRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActivePowerScheme'
    $wifiAc = $null
    # Adaptador inalámbrico > Modo de ahorro de energía (0 = rendimiento máximo).
    $query = Invoke-AfProcess -FilePath 'powercfg.exe' -Arguments '/q SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a' -TimeoutMs 15000
    if (-not $query.TimedOut -and $query.ExitCode -eq 0) {
        $values = ConvertFrom-AfPowercfgQuery -Text $query.Output
        if ($values) { $wifiAc = $values.Ac }
    }
    [pscustomobject]@{
        ActiveScheme = if ($active) { ([string]$active).ToLowerInvariant() } else { $null }
        OverlayAc = Get-AfPowerOverlay
        WifiPowerAc = $wifiAc
    }
}

# Herramientas de fabricante que manejan límites de potencia y ventiladores.
# Nombres de servicio y proceso por conocimiento común: verificarlos en equipos reales de cada marca.
$script:AfVendorToolList = @(
    @{ Name = 'Armoury Crate'; Services = @('ArmouryCrateService', 'ArmouryCrateControlInterface'); Processes = @('ArmouryCrate') }
    @{ Name = 'G-Helper'; Services = @(); Processes = @('GHelper') }
    @{ Name = 'Lenovo Vantage'; Services = @('ImControllerService', 'LenovoVantageService'); Processes = @('LenovoVantage') }
    @{ Name = 'Legion Toolkit'; Services = @(); Processes = @('Lenovo Legion Toolkit', 'LenovoLegionToolkit') }
    @{ Name = 'MSI Center'; Services = @('MSI Central Service'); Processes = @('MSI Center', 'MSI.CentralServer') }
    @{ Name = 'NitroSense'; Services = @('NitroSenseService'); Processes = @('NitroSense') }
    @{ Name = 'OMEN Gaming Hub'; Services = @('HPOmenCap', 'HP Omen HSA Service'); Processes = @('OmenCommandCenterBackground') }
    @{ Name = 'Alienware Command Center'; Services = @('AWCCService'); Processes = @() }
)

function Get-AfVendorTools {
    $services = @(Get-Service -ErrorAction SilentlyContinue | ForEach-Object { $_.Name; $_.DisplayName })
    $processes = @(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $_.ProcessName })
    foreach ($tool in $script:AfVendorToolList) {
        $found = @($tool.Services | Where-Object { $services -contains $_ }).Count -gt 0 -or
            @($tool.Processes | Where-Object { $processes -contains $_ }).Count -gt 0
        if ($found) { $tool.Name }
    }
}
