BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    function Test-Check([string]$Id, $Inventory) {
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id }
        if (-not $check) { throw "No existe la revisión $Id" }
        Invoke-AfCheck -Check $check -Inventory $Inventory
    }
    function New-Security([object[]]$Antivirus, $Defender, [object[]]$Firewall, [bool]$Hvci = $false, [bool]$Vmp = $false, [bool]$Virt = $false, [bool]$ThirdPartyFirewall = $false) {
        if (-not $Defender) { $Defender = [pscustomobject]@{ Available = $true; RealTime = $true; SignatureAgeDays = 0; TamperProtected = $true; PuaProtection = 1; Threats = @() } }
        if (-not $Firewall) { $Firewall = @([pscustomobject]@{ Profile = 'Domain'; Enabled = $true }, [pscustomobject]@{ Profile = 'Private'; Enabled = $true }, [pscustomobject]@{ Profile = 'Public'; Enabled = $true }) }
        [pscustomobject]@{ Antivirus = $Antivirus; Defender = $Defender; Firewall = $Firewall; ThirdPartyFirewall = $ThirdPartyFirewall; HvciRunning = $Hvci; VmPlatformEnabled = $Vmp; UsesVirtualization = $Virt }
    }
    $script:defenderOn = [pscustomobject]@{ Name = 'Microsoft Defender Antivirus'; Enabled = $true; UpToDate = $true; IsDefender = $true }
}

Describe 'security.antivirus' {
    It 'Ok con un antivirus de terceros activo y al día' {
        $inv = New-AfFakeInventory -Override @{ Security = New-Security -Antivirus @([pscustomobject]@{ Name = 'ESET Security'; Enabled = $true; UpToDate = $true; IsDefender = $false }) }
        $r = Test-Check 'security.antivirus' $inv
        $r.Detection.State | Should -Be 'Ok'
        $r.Detection.Current | Should -Be 'ESET Security'
    }

    It 'Improvable si ninguno está activo y Defender está disponible' {
        $defender = [pscustomobject]@{ Available = $true; RealTime = $false; SignatureAgeDays = 0; TamperProtected = $false; PuaProtection = 1; Threats = @() }
        $inv = New-AfFakeInventory -Override @{ Security = New-Security -Antivirus @([pscustomobject]@{ Name = 'Windows Defender'; Enabled = $false; UpToDate = $true; IsDefender = $true }) -Defender $defender }
        $r = Test-Check 'security.antivirus' $inv
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeTrue
    }
}

Describe 'security.signatures' {
    It 'Improvable con firmas de hace 5 días' {
        $defender = [pscustomobject]@{ Available = $true; RealTime = $true; SignatureAgeDays = 5; TamperProtected = $true; PuaProtection = 1; Threats = @() }
        $r = Test-Check 'security.signatures' (New-AfFakeInventory -Override @{ Security = New-Security -Antivirus @($script:defenderOn) -Defender $defender })
        $r.Detection.State | Should -Be 'Improvable'
        $r.Detection.Current | Should -Be 'Hace 5 días'
    }
}

Describe 'security.threats' {
    It 'Manual con una amenaza activa y el nombre en Current' {
        $defender = [pscustomobject]@{ Available = $true; RealTime = $true; SignatureAgeDays = 0; TamperProtected = $true; PuaProtection = 1
            Threats = @([pscustomobject]@{ Name = 'Trojan:Win32/Prueba'; Active = $true; Path = 'C:\Users\Cliente\AppData\Local\malo.exe' }) }
        $r = Test-Check 'security.threats' (New-AfFakeInventory -Override @{ Security = New-Security -Antivirus @($script:defenderOn) -Defender $defender })
        $r.Detection.State | Should -Be 'Manual'
        $r.Detection.Current | Should -Be 'Trojan:Win32/Prueba'
        $r.Detection.Title | Should -Be '1 amenaza activa'
    }

    It 'Ok si las amenazas ya están resueltas' {
        $defender = [pscustomobject]@{ Available = $true; RealTime = $true; SignatureAgeDays = 0; TamperProtected = $true; PuaProtection = 1
            Threats = @([pscustomobject]@{ Name = 'PUA:Win32/Vieja'; Active = $false; Path = 'C:\x.exe' }) }
        (Test-Check 'security.threats' (New-AfFakeInventory -Override @{ Security = New-Security -Antivirus @($script:defenderOn) -Defender $defender })).Detection.State | Should -Be 'Ok'
    }
}

Describe 'security.pua y security.firewall y security.uac' {
    It 'pua Improvable con PUAProtection 0' {
        $defender = [pscustomobject]@{ Available = $true; RealTime = $true; SignatureAgeDays = 0; TamperProtected = $true; PuaProtection = 0; Threats = @() }
        (Test-Check 'security.pua' (New-AfFakeInventory -Override @{ Security = New-Security -Antivirus @($script:defenderOn) -Defender $defender })).Detection.State | Should -Be 'Improvable'
    }

    It 'firewall Improvable con el perfil Público apagado' {
        $fw = @([pscustomobject]@{ Profile = 'Domain'; Enabled = $true }, [pscustomobject]@{ Profile = 'Private'; Enabled = $true }, [pscustomobject]@{ Profile = 'Public'; Enabled = $false })
        $r = Test-Check 'security.firewall' (New-AfFakeInventory -Override @{ Security = New-Security -Antivirus @($script:defenderOn) -Firewall $fw })
        $r.Detection.State | Should -Be 'Improvable'
        $r.Detection.Current | Should -Be 'Apagado en Público'
    }

    It 'firewall no aplica si hay un firewall de terceros' {
        $fw = @([pscustomobject]@{ Profile = 'Public'; Enabled = $false })
        (Test-Check 'security.firewall' (New-AfFakeInventory -Override @{ Security = New-Security -Antivirus @($script:defenderOn) -Firewall $fw -ThirdPartyFirewall $true })).Detection.State | Should -Be 'NotApplicable'
    }

    It 'uac Improvable con EnableLUA 0 y pide reinicio' {
        $r = Test-Check 'security.uac' (New-AfFakeInventory -Override @{ Registry = @{ 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System|EnableLUA' = 0 } })
        $r.Detection.State | Should -Be 'Improvable'
        $r.Check.NeedsReboot | Should -BeTrue
    }
}

Describe 'security.unsigned-autostart' {
    It 'Info con 2 binarios sin firma en AppData' {
        $auto = @(
            [pscustomobject]@{ Name = 'upd'; Path = 'C:\Users\Cliente\AppData\Roaming\upd\upd.exe'; Source = 'Run'; IsSigned = $false; Signer = $null; InUserWritablePath = $true; Enabled = $true }
            [pscustomobject]@{ Name = 'helper'; Path = 'C:\Users\Cliente\AppData\Local\h\h.exe'; Source = 'Task'; IsSigned = $false; Signer = $null; InUserWritablePath = $true; Enabled = $true }
            [pscustomobject]@{ Name = 'Discord'; Path = 'C:\Users\Cliente\AppData\Local\Discord\Update.exe'; Source = 'Run'; IsSigned = $true; Signer = 'Discord Inc.'; InUserWritablePath = $true; Enabled = $true }
        )
        $r = Test-Check 'security.unsigned-autostart' (New-AfFakeInventory -Override @{ Autostart = $auto })
        $r.Detection.State | Should -Be 'Info'
        $r.Detection.Title | Should -Be '2 programas sin firma arrancan solos'
        @($r.Detection.Data.Items).Count | Should -Be 2
    }
}

Describe 'Opcionales' {
    It 'cleanup.diagnostics NotApplicable en Insider' {
        $inv = New-AfFakeInventory -Override @{ Os = [pscustomobject]@{ Caption = 'Microsoft Windows 11 Pro'; Build = 26300; Edition = 'Professional'; IsWin11 = $true; IsInsider = $true } }
        (Test-Check 'cleanup.diagnostics' $inv).Detection.State | Should -Be 'NotApplicable'
    }

    It 'updates.windows marca Async' {
        $r = Test-Check 'updates.windows' (New-AfFakeInventory)
        $r.Detection.Data.Async | Should -BeTrue
        $r.Check.Category | Should -Be 'optional'
    }

    It 'advanced.memory-integrity Improvable con HVCI corriendo, sin marcar y con riesgo Advanced' {
        $r = Test-Check 'advanced.memory-integrity' (New-AfFakeInventory -Override @{ Security = New-Security -Antivirus @($script:defenderOn) -Hvci $true })
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeFalse
        $r.Check.Risk | Should -Be 'Advanced'
    }

    It 'advanced.vm-platform no aplica si hay WSL, Docker o un emulador' {
        (Test-Check 'advanced.vm-platform' (New-AfFakeInventory -Override @{ Security = New-Security -Antivirus @($script:defenderOn) -Vmp $true -Virt $true })).Detection.State | Should -Be 'NotApplicable'
    }

    It 'cleanup.promo-apps Improvable con Candy Crush y TikTok' {
        $apps = [pscustomobject]@{ Promo = @([pscustomobject]@{ Name = 'Candy Crush'; PackageName = 'king.com.CandyCrushSaga' }, [pscustomobject]@{ Name = 'TikTok'; PackageName = 'BytedancePte.Ltd.TikTok' }) }
        $r = Test-Check 'cleanup.promo-apps' (New-AfFakeInventory -Override @{ Apps = $apps })
        $r.Detection.State | Should -Be 'Improvable'
        $r.Detection.Current | Should -Be 'Candy Crush y TikTok'
    }
}
