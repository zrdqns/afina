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

Describe 'cleanup.widgets' {
    BeforeAll {
        $script:dsh = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh|AllowNewsAndInterests'
        $script:taskbarDa = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|TaskbarDa'
        $script:feeds = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds|ShellFeedsTaskbarViewMode'
        function New-WidgetOs([string]$Edition, [int]$Build = 26100) {
            [pscustomobject]@{ Caption = 'Windows'; Build = $Build; Edition = $Edition; IsWin11 = ($Build -ge 22000); IsInsider = $false; Ubr = 7019 }
        }
        $script:withWidgets = [pscustomobject]@{ Promo = @(); Copilot = $null; HasWidgets = $true }
    }

    It 'Windows 11 Pro se ofrece, sin marcar y con reinicio' {
        $inv = New-AfFakeInventory -Override @{ Os = (New-WidgetOs 'Professional'); Apps = $script:withWidgets }
        $r = Invoke-AfCheck -Check (Get-Check 'cleanup.widgets') -Inventory $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeFalse
        $r.Check.NeedsReboot | Should -BeTrue
    }

    It 'con la directiva avisa que Configuración puede mostrarla como administrada y no repite el reinicio en la nota' {
        $d = Invoke-Detect 'cleanup.widgets' @{ Os = (New-WidgetOs 'Professional'); Apps = $script:withWidgets }
        $d.What | Should -BeLike '*Configuración puede mostrar que una organización administra este ajuste hasta que lo deshagas.'
        $d.Note | Should -Not -Be 'Pide reiniciar'
    }

    It 'Windows 11 Home da pasos' {
        $d = Invoke-Detect 'cleanup.widgets' @{ Os = (New-WidgetOs 'Core'); Apps = $script:withWidgets; Registry = @{ $script:taskbarDa = 1 } }
        $d.State | Should -Be 'Info'
        @($d.Steps).Count | Should -BeGreaterThan 0
    }

    It 'Windows 11 Home con los widgets ya ocultos queda en orden' {
        (Invoke-Detect 'cleanup.widgets' @{ Os = (New-WidgetOs 'Core'); Apps = $script:withWidgets; Registry = @{ $script:taskbarDa = 0 } }).State | Should -Be 'Ok'
    }

    It 'Windows 10 da pasos' {
        $d = Invoke-Detect 'cleanup.widgets' @{ Os = (New-WidgetOs 'Professional' 19045); Apps = $script:withWidgets }
        $d.State | Should -Be 'Info'
        @($d.Steps).Count | Should -BeGreaterThan 0
    }

    It 'Windows 10 con Noticias e intereses apagadas queda en orden' {
        (Invoke-Detect 'cleanup.widgets' @{ Os = (New-WidgetOs 'Professional' 19045); Apps = $script:withWidgets; Registry = @{ $script:feeds = 2 } }).State | Should -Be 'Ok'
    }

    It 'con la directiva puesta queda en orden' {
        (Invoke-Detect 'cleanup.widgets' @{ Os = (New-WidgetOs 'Professional'); Apps = $script:withWidgets; Registry = @{ $script:dsh = 0 } }).State | Should -Be 'Ok'
    }

    It 'en Windows 11 Home la directiva no cuenta' {
        $d = Invoke-Detect 'cleanup.widgets' @{ Os = (New-WidgetOs 'Core'); Apps = $script:withWidgets; Registry = @{ $script:dsh = 0 } }
        $d.State | Should -Be 'Info'
    }

    It 'en Windows 10 la directiva no cuenta' {
        $d = Invoke-Detect 'cleanup.widgets' @{ Os = (New-WidgetOs 'Professional' 19045); Apps = $script:withWidgets; Registry = @{ $script:dsh = 0 } }
        $d.State | Should -Be 'Info'
    }

    It 'sin el paquete de Widgets en Windows 11 no aplica' {
        $d = Invoke-Detect 'cleanup.widgets' @{ Os = (New-WidgetOs 'Professional'); Apps = [pscustomobject]@{ Promo = @(); Copilot = $null; HasWidgets = $false } }
        $d.State | Should -Be 'NotApplicable'
    }

    It 'sin lectura de apps no aplica' {
        (Invoke-Detect 'cleanup.widgets' @{ Os = (New-WidgetOs 'Professional'); Apps = $null }).State | Should -Be 'NotApplicable'
    }

    It 'Apply escribe solo la directiva de Widgets' {
        Mock Set-AfRegistryValue { $true }
        $inv = New-AfFakeInventory -Override @{ Os = (New-WidgetOs 'Professional'); Apps = $script:withWidgets }
        $check = Get-Check 'cleanup.widgets'
        $result = Invoke-AfCheck -Check $check -Inventory $inv
        & $check.Apply $inv $result.Detection (New-AfTransaction -User $inv.User)
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -and $Name -eq 'AllowNewsAndInterests' -and $Type -eq 'DWord' -and $Value -eq 0 }
    }
}

Describe 'cleanup.copilot' {
    BeforeAll {
        $script:copilot = [pscustomobject]@{ Name = 'Copilot'; PackageName = 'Microsoft.Copilot'; PackageFullName = 'Microsoft.Copilot_1'; PackageFamilyName = 'Microsoft.Copilot_8wekyb3d8bbwe'; StoreId = '9NHT9RB2F4HD'; Provisioned = $false }
    }

    It 'instalado se ofrece sin marcar y Apply lo quita' {
        Mock Remove-AfAppxPackage { $true }
        $inv = New-AfFakeInventory -Override @{ Apps = [pscustomobject]@{ Promo = @(); Copilot = $script:copilot; HasWidgets = $false } }
        $check = Get-Check 'cleanup.copilot'
        $r = Invoke-AfCheck -Check $check -Inventory $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeFalse
        & $check.Apply $inv $r.Detection (New-AfTransaction -User $inv.User)
        Should -Invoke Remove-AfAppxPackage -Times 1 -Exactly -ParameterFilter { $App.PackageName -eq 'Microsoft.Copilot' }
    }

    It 'sin Copilot no aplica' {
        (Invoke-Detect 'cleanup.copilot' @{ Apps = [pscustomobject]@{ Promo = @(); Copilot = $null; HasWidgets = $false } }).State | Should -Be 'NotApplicable'
    }

    It 'con otra cuenta elevada no aplica' {
        $other = [pscustomobject]@{ Name = 'PC\Dueño'; Sid = 'S-1-5-21-9'; ProfilePath = 'C:\Users\Dueño'; IsSameAsProcess = $false; HkcuRoot = 'Registry::HKEY_USERS\S-1-5-21-9' }
        (Invoke-Detect 'cleanup.copilot' @{ Apps = [pscustomobject]@{ Promo = @(); Copilot = $script:copilot; HasWidgets = $false }; User = $other }).State | Should -Be 'NotApplicable'
    }
}

Describe 'cleanup.recall' {
    BeforeAll {
        $script:aiPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI|DisableAIDataAnalysis'
        function New-RecallInv([string]$Edition = 'Professional', [int]$Build = 26100, [int]$Ubr = 3915, $Gb = 16, [hashtable]$Registry = @{}) {
            New-AfFakeInventory -Override @{
                Os = [pscustomobject]@{ Caption = 'Windows'; Build = $Build; Edition = $Edition; IsWin11 = $true; IsInsider = $false; Ubr = $Ubr }
                Memory = [pscustomobject]@{ TotalGB = $Gb; Socketed = $true; Modules = @() }
                Registry = $Registry
            }
        }
        function Invoke-Recall($Inv) { & (Get-Check 'cleanup.recall').AsyncDetect $Inv }
    }

    It 'va primero en la lista y es asíncrona' {
        @(Get-AfOptionalChecks)[0].Id | Should -Be 'cleanup.recall'
        $r = Invoke-AfCheck -Check (Get-Check 'cleanup.recall') -Inventory (New-RecallInv)
        $r.Detection.State | Should -Be 'Info'
        $r.Detection.Data.Async | Should -BeTrue
    }

    It 'activo en Pro se ofrece con el aviso en rojo' {
        Mock Get-AfRecallState { 'Enabled' }
        $d = Invoke-Recall (New-RecallInv)
        $d.State | Should -Be 'Improvable'
        $d.Note | Should -Be 'Borra las capturas guardadas y no se recuperan'
        (Get-Check 'cleanup.recall').Risk | Should -Be 'Advanced'
        (Get-Check 'cleanup.recall').Preselect | Should -BeFalse
    }

    It 'instalado se muestra como Disponible (InstallState 1 no dice que guarde capturas)' {
        Mock Get-AfRecallState { 'Enabled' }
        (Invoke-Recall (New-RecallInv)).Current | Should -Be 'Disponible'
        (Invoke-Recall (New-RecallInv -Edition 'Core')).Current | Should -Be 'Disponible'
    }

    It 'en Pro avisa que Configuración puede mostrar la directiva como administrada; en Home no hay directiva' {
        Mock Get-AfRecallState { 'Enabled' }
        (Invoke-Recall (New-RecallInv)).What | Should -BeLike '*Configuración puede mostrar que una organización administra este ajuste hasta que lo deshagas.'
        (Invoke-Recall (New-RecallInv -Edition 'Core')).What | Should -Not -BeLike '*organización administra*'
    }

    It 'activo en Home da pasos' {
        Mock Get-AfRecallState { 'Enabled' }
        $d = Invoke-Recall (New-RecallInv -Edition 'Core')
        $d.State | Should -Be 'Info'
        @($d.Steps).Count | Should -BeGreaterThan 0
    }

    It 'ausente no aplica' {
        Mock Get-AfRecallState { 'Absent' }
        (Invoke-Recall (New-RecallInv)).State | Should -Be 'NotApplicable'
    }

    It 'desactivado queda en orden' {
        Mock Get-AfRecallState { 'Disabled' }
        (Invoke-Recall (New-RecallInv)).State | Should -Be 'Ok'
    }

    It 'si la lectura falla no aplica y no dice que está apagado' {
        Mock Get-AfRecallState { throw 'sin respuesta' }
        (Invoke-Recall (New-RecallInv)).State | Should -Be 'NotApplicable'
    }

    It 'con la directiva puesta queda en orden sin leer la característica' {
        Mock Get-AfRecallState { 'Enabled' }
        (Invoke-Recall (New-RecallInv -Registry @{ $script:aiPolicy = 1 })).State | Should -Be 'Ok'
        Should -Invoke Get-AfRecallState -Times 0 -Exactly
    }

    It 'en Home la directiva no se respeta: se sigue a la característica' {
        Mock Get-AfRecallState { 'Enabled' }
        $d = Invoke-Recall (New-RecallInv -Edition 'Core' -Registry @{ $script:aiPolicy = 1 })
        $d.State | Should -Be 'Info'
        Should -Invoke Get-AfRecallState -Times 1 -Exactly
        Mock Get-AfRecallState { 'Disabled' }
        (Invoke-Recall (New-RecallInv -Edition 'Core' -Registry @{ $script:aiPolicy = 1 })).State | Should -Be 'Ok'
    }

    It 'sin los requisitos no aplica y no lee la característica' {
        Mock Get-AfRecallState { 'Enabled' }
        $check = Get-Check 'cleanup.recall'
        foreach ($inv in (New-RecallInv -Gb 8), (New-RecallInv -Gb 0), (New-RecallInv -Ubr 3914), (New-RecallInv -Build 22631 -Ubr 9999)) {
            (Invoke-AfCheck -Check $check -Inventory $inv).Detection.State | Should -Be 'NotApplicable'
        }
        (Invoke-AfCheck -Check $check -Inventory (New-RecallInv -Build 26200 -Ubr 1)).Detection.State | Should -Be 'Info'
        Should -Invoke Get-AfRecallState -Times 0 -Exactly
    }

    It 'Apply escribe DisableAIDataAnalysis y nada de AllowRecallEnablement' {
        Mock Set-AfRegistryValue { $true }
        $inv = New-RecallInv
        $check = Get-Check 'cleanup.recall'
        & $check.Apply $inv ([pscustomobject]@{ Data = @{} }) (New-AfTransaction -User $inv.User)
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -and $Name -eq 'DisableAIDataAnalysis' -and $Type -eq 'DWord' -and $Value -eq 1 }
        Should -Not -Invoke Set-AfRegistryValue -ParameterFilter { $Name -eq 'AllowRecallEnablement' }
    }
}

Describe 'Get-AfRecallState' {
    It 'traduce InstallState de Win32_OptionalFeature' {
        Mock Get-CimInstance { [pscustomobject]@{ Name = 'Recall'; InstallState = 1 } }
        Get-AfRecallState | Should -Be 'Enabled'
        Mock Get-CimInstance { [pscustomobject]@{ Name = 'Recall'; InstallState = 2 } }
        Get-AfRecallState | Should -Be 'Disabled'
        Mock Get-CimInstance { $null }
        Get-AfRecallState | Should -Be 'Absent'
    }

    It 'si la lectura falla, lanza' {
        Mock Get-CimInstance { throw 'tiempo agotado' }
        { Get-AfRecallState } | Should -Throw
    }
}
