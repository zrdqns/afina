function ConvertFrom-AfThreatResource {
    param([string]$Resource)
    # Defender anota los recursos como "file:_C:\ruta" o "regkey:_HKLM\...".
    ([string]$Resource) -replace '^[a-zA-Z]+:_', ''
}

function Test-AfUsesVirtualization {
    param($User)
    $lxss = Resolve-AfRegistryPath -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -User $User
    $wslDistros = @(Get-ChildItem -LiteralPath $lxss -ErrorAction SilentlyContinue).Count -gt 0
    $docker = Test-Path -LiteralPath (Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe')
    $bluestacks = Test-Path -LiteralPath 'HKLM:\SOFTWARE\BlueStacks_nxt'
    $wslDistros -or $docker -or $bluestacks
}

function Get-AfSecurityInfo {
    param($User)
    $antivirus = @()
    try {
        foreach ($av in @(Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName AntiVirusProduct -OperationTimeoutSec 15 -ErrorAction Stop)) {
            $state = ConvertFrom-AfProductState -State ([int]$av.productState)
            $antivirus += [pscustomobject]@{
                Name = [string]$av.displayName
                Enabled = $state.Enabled
                UpToDate = $state.UpToDate
                IsDefender = [string]$av.displayName -match 'Defender'
            }
        }
    } catch {
        Write-AfLog -Level Warn -Message "No se pudo leer el Centro de seguridad: $($_.Exception.Message)"
    }

    $defender = [pscustomobject]@{ Available = $false; RealTime = $null; SignatureAgeDays = $null; TamperProtected = $null; PuaProtection = $null; Threats = @() }
    try {
        $status = Get-MpComputerStatus -ErrorAction Stop
        $preference = Get-MpPreference -ErrorAction Stop
        $threats = @()
        try {
            $threats = @(Get-MpThreat -ErrorAction Stop | ForEach-Object {
                    [pscustomobject]@{ Name = [string]$_.ThreatName; Active = [bool]$_.IsActive; Path = ConvertFrom-AfThreatResource -Resource (@($_.Resources)[0]) }
                })
        } catch { }
        $defender = [pscustomobject]@{
            Available = [bool]$status.AMServiceEnabled
            RealTime = [bool]$status.RealTimeProtectionEnabled
            SignatureAgeDays = [int]$status.AntivirusSignatureAge
            TamperProtected = [bool]$status.IsTamperProtected
            PuaProtection = [int]$preference.PUAProtection
            Threats = $threats
        }
    } catch {
        Write-AfLog -Level Info -Message 'Defender no está disponible (otro antivirus o modo pasivo).'
    }

    $firewall = @()
    try {
        $firewall = @(Get-NetFirewallProfile -ErrorAction Stop | ForEach-Object {
                [pscustomobject]@{ Profile = [string]$_.Name; Enabled = [string]$_.Enabled -eq 'True' }
            })
    } catch { }

    $thirdPartyFirewall = $false
    try {
        $products = @(Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName FirewallProduct -OperationTimeoutSec 15 -ErrorAction Stop)
        $thirdPartyFirewall = @($products | Where-Object { [string]$_.displayName -notmatch 'Windows|Microsoft' }).Count -gt 0
    } catch { }

    $hvci = $false
    try {
        $guard = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard -OperationTimeoutSec 15 -ErrorAction Stop
        $hvci = @($guard.SecurityServicesRunning) -contains 2
    } catch { }

    # InstallState 1 = activada. Con Hyper-V o la Plataforma del hipervisor activadas, apagar VMP no cambia nada.
    $features = @{}
    try {
        $filter = "Name='VirtualMachinePlatform' OR Name='Microsoft-Hyper-V-All' OR Name='HypervisorPlatform'"
        foreach ($feature in @(Get-CimInstance -ClassName Win32_OptionalFeature -Filter $filter -OperationTimeoutSec 15 -ErrorAction Stop)) { $features[[string]$feature.Name] = [int]$feature.InstallState }
    } catch { }
    $hypervisor = $features['Microsoft-Hyper-V-All'] -eq 1 -or $features['HypervisorPlatform'] -eq 1
    $vmPlatform = [pscustomobject]@{ State = $(if ($features['VirtualMachinePlatform'] -eq 1) { 'Enabled' } else { 'Disabled' }); Pending = $false }
    # DISM tarda unos segundos: solo se le pregunta si CIM la ve activada, para saber si ya se apaga al reiniciar.
    if ($vmPlatform.State -eq 'Enabled') {
        try {
            $info = Get-AfFeatureInfo -Name 'VirtualMachinePlatform'
            $vmPlatform = [pscustomobject]@{ State = $info.State; Pending = $info.Pending }
        } catch { }
    }

    [pscustomobject]@{
        Antivirus = $antivirus
        Defender = $defender
        Firewall = $firewall
        ThirdPartyFirewall = $thirdPartyFirewall
        HvciRunning = $hvci
        VmPlatform = $vmPlatform
        VmPlatformEnabled = $vmPlatform.State -eq 'Enabled'
        UsesVirtualization = $hypervisor -or (Test-AfUsesVirtualization -User $User)
    }
}
