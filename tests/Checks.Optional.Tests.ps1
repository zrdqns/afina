BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    $script:hvci = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
    $script:policy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard|HypervisorEnforcedCodeIntegrity'
    function Get-Check([string]$Id) { @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id } }
    function New-Security([bool]$Hvci = $false, $VmPlatform = $null, [bool]$UsesVirtualization = $false) {
        [pscustomobject]@{
            Antivirus = @(); Defender = $null; Firewall = @(); ThirdPartyFirewall = $false; HvciRunning = $Hvci
            VmPlatform = $VmPlatform; VmPlatformEnabled = [bool]($VmPlatform -and $VmPlatform.State -eq 'Enabled'); UsesVirtualization = $UsesVirtualization
        }
    }
    function Invoke-Detect([string]$Id, [hashtable]$Override) {
        (Invoke-AfCheck -Check (Get-Check $Id) -Inventory (New-AfFakeInventory -Override $Override)).Detection
    }
}

Describe 'advanced.memory-integrity' {
    It 'corriendo sin bloqueo se ofrece apagarla y Apply pone Enabled en 0' {
        Mock Set-AfRegistryValue { $true }
        $inv = New-AfFakeInventory -Override @{ Security = (New-Security -Hvci $true); Registry = @{ "$script:hvci|Enabled" = 1 } }
        $check = Get-Check 'advanced.memory-integrity'
        $result = Invoke-AfCheck -Check $check -Inventory $inv
        $result.Detection.State | Should -Be 'Improvable'
        & $check.Apply $inv $result.Detection (New-AfTransaction -User $inv.User)
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:hvci -and $Name -eq 'Enabled' -and $Type -eq 'DWord' -and $Value -eq 0 }
    }

    It 'con Locked = 1 queda a mano' {
        $d = Invoke-Detect 'advanced.memory-integrity' @{ Security = (New-Security -Hvci $true); Registry = @{ "$script:hvci|Enabled" = 1; "$script:hvci|Locked" = 1 } }
        $d.State | Should -Be 'Manual'
        @($d.Steps).Count | Should -BeGreaterThan 0
    }

    It 'activada por una directiva también queda a mano' {
        $d = Invoke-Detect 'advanced.memory-integrity' @{ Security = (New-Security -Hvci $true); Registry = @{ "$script:hvci|Enabled" = 1; $script:policy = 2 } }
        $d.State | Should -Be 'Manual'
    }

    It 'pendiente de reinicio no se ofrece otra vez' {
        $off = Invoke-Detect 'advanced.memory-integrity' @{ Security = (New-Security -Hvci $true); Registry = @{ "$script:hvci|Enabled" = 0 } }
        $off.State | Should -Be 'Info'
        $off.Current | Should -Be 'Se apaga al reiniciar'
        $on = Invoke-Detect 'advanced.memory-integrity' @{ Security = (New-Security -Hvci $false); Registry = @{ "$script:hvci|Enabled" = 1 } }
        $on.State | Should -Be 'Info'
        $on.Current | Should -Be 'Se activa al reiniciar'
    }

    It 'apagada queda en orden' {
        (Invoke-Detect 'advanced.memory-integrity' @{ Security = (New-Security -Hvci $false); Registry = @{} }).State | Should -Be 'Ok'
    }
}

Describe 'cleanup.promo-apps' {
    BeforeAll {
        $script:promo = [pscustomobject]@{ Promo = @(
                [pscustomobject]@{ Name = 'Noticias'; PackageName = 'Microsoft.BingNews'; PackageFullName = 'Microsoft.BingNews_1'; PackageFamilyName = 'Microsoft.BingNews_8wekyb3d8bbwe'; StoreId = '9WZDNCRFHVFW'; Provisioned = $true }
                [pscustomobject]@{ Name = 'Candy Crush'; PackageName = 'king.com.CandyCrushSodaSaga'; PackageFullName = 'king.com.CandyCrushSodaSaga_1'; PackageFamilyName = 'king.com.CandyCrushSodaSaga_kgqvnymyfvs32'; StoreId = $null; Provisioned = $false }
            ) }
    }

    It 'avisa que no se puede reinstalar y no la preselecciona' {
        $d = Invoke-Detect 'cleanup.promo-apps' @{ Apps = $script:promo }
        $d.State | Should -Be 'Improvable'
        $d.Data.ChoicesLabel | Should -Be 'Apps'
        $d.Data.Choices[0].Label | Should -Be 'Noticias'
        $d.Data.Choices[0].Preselected | Should -BeTrue
        $d.Data.Choices[1].Label | Should -Be 'Candy Crush (no se puede reinstalar)'
        $d.Data.Choices[1].Preselected | Should -BeFalse
        @($d.Data.Choices | Where-Object Selected).Count | Should -Be 0
    }

    It 'quita solo las elegidas' {
        Mock Remove-AfAppxPackage { $true }
        $inv = New-AfFakeInventory -Override @{ Apps = $script:promo }
        $check = Get-Check 'cleanup.promo-apps'
        $result = Invoke-AfCheck -Check $check -Inventory $inv
        $result.Detection.Data.Choices[0].Selected = $true
        & $check.Apply $inv $result.Detection (New-AfTransaction -User $inv.User)
        Should -Invoke Remove-AfAppxPackage -Times 1 -Exactly -ParameterFilter { $App.PackageName -eq 'Microsoft.BingNews' }
    }

    It 'con otra cuenta elevada no se ofrece' {
        $other = [pscustomobject]@{ Name = 'PC\Dueño'; Sid = 'S-1-5-21-9'; ProfilePath = 'C:\Users\Dueño'; IsSameAsProcess = $false; HkcuRoot = 'Registry::HKEY_USERS\S-1-5-21-9' }
        $d = Invoke-Detect 'cleanup.promo-apps' @{ Apps = $script:promo; User = $other }
        $d.State | Should -Be 'NotApplicable'
        $d.Note | Should -Be 'Abre Afina con la cuenta del dueño para quitarlas'
    }
}

Describe 'cleanup.ads' {
    It 'apaga solo las opciones activas' {
        Mock Set-AfRegistryValue { $true }
        $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
        $registry = @{}
        foreach ($read in Get-AfAdsReads) { $registry[$read] = 0 }
        $registry["$cdm|SilentInstalledAppsEnabled"] = 1
        $registry['HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo|Enabled'] = 1
        $inv = New-AfFakeInventory -Override @{ Registry = $registry }
        $check = Get-Check 'cleanup.ads'
        $result = Invoke-AfCheck -Check $check -Inventory $inv
        $result.Detection.State | Should -Be 'Improvable'
        & $check.Apply $inv $result.Detection (New-AfTransaction -User $inv.User)
        Should -Invoke Set-AfRegistryValue -Times 2 -Exactly
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $cdm -and $Name -eq 'SilentInstalledAppsEnabled' -and $Type -eq 'DWord' -and $Value -eq 0 }
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -and $Name -eq 'Enabled' -and $Value -eq 0 }
    }
}

Describe 'cleanup.diagnostics' {
    BeforeAll {
        $script:setting = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
        $script:tailored = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'
    }

    It 'pone el nivel obligatorio y apaga las experiencias personalizadas' {
        Mock Set-AfRegistryValue { $true }
        $inv = New-AfFakeInventory -Override @{ Registry = @{ "$script:setting|AllowTelemetry" = 3; "$script:tailored|TailoredExperiencesWithDiagnosticDataEnabled" = 1 } }
        $check = Get-Check 'cleanup.diagnostics'
        $result = Invoke-AfCheck -Check $check -Inventory $inv
        $result.Detection.State | Should -Be 'Improvable'
        $result.Detection.Current | Should -Be 'Opcionales'
        & $check.Apply $inv $result.Detection (New-AfTransaction -User $inv.User)
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:setting -and $Name -eq 'AllowTelemetry' -and $Type -eq 'DWord' -and $Value -eq 1 }
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:tailored -and $Name -eq 'TailoredExperiencesWithDiagnosticDataEnabled' -and $Type -eq 'DWord' -and $Value -eq 0 }
    }

    It 'con directiva no se ofrece como automático' {
        $d = Invoke-Detect 'cleanup.diagnostics' @{ Registry = @{ 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection|AllowTelemetry' = 3; "$script:tailored|TailoredExperiencesWithDiagnosticDataEnabled" = 0 } }
        $d.State | Should -Be 'Info'
        $d.Note | Should -Be 'Lo fija una directiva de la organización'
    }

    It 'en el nivel 0 no lo sube a 1' {
        Mock Set-AfRegistryValue { $true }
        $inv = New-AfFakeInventory -Override @{ Registry = @{ "$script:setting|AllowTelemetry" = 0; "$script:tailored|TailoredExperiencesWithDiagnosticDataEnabled" = 1 } }
        $check = Get-Check 'cleanup.diagnostics'
        $result = Invoke-AfCheck -Check $check -Inventory $inv
        $result.Detection.Current | Should -Be 'Con experiencias personalizadas'
        & $check.Apply $inv $result.Detection (New-AfTransaction -User $inv.User)
        Should -Invoke Set-AfRegistryValue -Times 0 -Exactly -ParameterFilter { $Name -eq 'AllowTelemetry' }
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Name -eq 'TailoredExperiencesWithDiagnosticDataEnabled' }
    }
}

Describe 'advanced.vm-platform' {
    It 'encendida y sin uso de virtualización se apaga con la pieza WindowsFeature' {
        Mock Set-AfWindowsFeature { $true }
        $inv = New-AfFakeInventory -Override @{ Security = (New-Security -VmPlatform ([pscustomobject]@{ State = 'Enabled'; Pending = $false })) }
        $check = Get-Check 'advanced.vm-platform'
        $result = Invoke-AfCheck -Check $check -Inventory $inv
        $result.Detection.State | Should -Be 'Improvable'
        & $check.Apply $inv $result.Detection (New-AfTransaction -User $inv.User)
        Should -Invoke Set-AfWindowsFeature -Times 1 -Exactly -ParameterFilter { $Name -eq 'VirtualMachinePlatform' -and $Enabled -eq $false }
    }

    It 'pendiente de reinicio no se ofrece otra vez' {
        $d = Invoke-Detect 'advanced.vm-platform' @{ Security = (New-Security -VmPlatform ([pscustomobject]@{ State = 'Disabled'; Pending = $true })) }
        $d.State | Should -Be 'Info'
        $d.Current | Should -Be 'Se apaga al reiniciar'
    }
}
