BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
}

Describe 'Get-AfInventory' {
    BeforeEach {
        Mock Get-AfInteractiveUser { [pscustomobject]@{ Name = 'PC\Cliente'; Sid = 'S-1-5-21-1'; ProfilePath = 'C:\Users\Cliente'; IsSameAsProcess = $true; HkcuRoot = 'HKCU:' } }
        Mock Get-AfSystemInfo { [pscustomobject]@{ Build = 26100; IsWin11 = $true } }
        Mock Get-AfDeviceInfo { [pscustomobject]@{ IsLaptop = $true } }
        Mock Get-AfCpuInfo { [pscustomobject]@{ Name = 'CPU' } }
        Mock Get-AfGpuInfo { [pscustomobject]@{ Name = 'RTX 4060' } }
        Mock Get-AfMemoryInfo { [pscustomobject]@{ TotalGB = 16 } }
        Mock Get-AfDisplayInfo { [pscustomobject]@{ Hz = 144 } }
        Mock Get-AfPowerInfo { [pscustomobject]@{ ActiveScheme = 'x' } }
        Mock Get-AfVendorTools { }
        Mock Get-AfNetworkInfo { }
        Mock Get-AfWlanInfo { [pscustomobject]@{ Connected = $false } }
        Mock Get-AfSecurityInfo { [pscustomobject]@{ Antivirus = @() } }
        Mock Get-AfPromoApps { [pscustomobject]@{ Promo = @() } }
        Mock Get-AfStartupEntries { }
        Mock Get-AfAutostartBinaries { }
        Mock Get-AfStorageInfo { [pscustomobject]@{ FreeGB = 100 } }
        Mock Get-AfRegistrySnapshot { @{ 'HKLM:\X|Y' = 1 } }
        Mock Get-AfPagefileInfo { @{ Automatic = $true; Files = @() } }
        Mock Get-AfHibernationInfo { @{ Enabled = $false } }
        Mock Get-AfDeliveryOptimizationInfo { @{ Available = $true; Mode = 'Lan' } }
        Mock Get-AfEdgeInfo { @{ Installed = $true; Running = $false; HasWindow = $false } }
        Mock Get-AfEffectsInfo { @{ ClientAreaAnimation = $false } }
    }

    It 'sigue si una parte falla' {
        Mock Get-AfSecurityInfo { throw 'falla a propósito' }
        $inv = Get-AfInventory -Reads @('HKLM:\X|Y')
        $inv.Security | Should -BeNullOrEmpty
        $inv.Errors | Should -Contain 'Security'
        @($inv.Gpus).Count | Should -Be 1
        $inv.Registry['HKLM:\X|Y'] | Should -Be 1
    }

    It 'si la lectura de paginación falla, la parte queda en $null y en Errors' {
        Mock Get-AfPagefileInfo { throw 'falla a propósito' }
        $inv = Get-AfInventory
        $inv.Pagefile | Should -BeNullOrEmpty
        $inv.Errors | Should -Contain 'Pagefile'
    }

    It 'conserva como lista una parte con un solo elemento o vacía' {
        $inv = Get-AfInventory
        , $inv.Gpus | Should -BeOfType [object[]]
        , $inv.Network | Should -BeOfType [object[]]
        @($inv.Network).Count | Should -Be 0
    }

    It 'OnProgress se llama una vez por parte' {
        $script:calls = New-Object System.Collections.Generic.List[string]
        $null = Get-AfInventory -OnProgress { param($part) $script:calls.Add($part) }
        $script:calls.Count | Should -Be @(Get-AfInventoryPartNames).Count
        $script:calls[0] | Should -Be 'User'
    }
}

Describe 'Inventario real de esta PC' -Tag 'Integration' {
    It 'termina en menos de 25 s sin partes fallidas' {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $inv = Get-AfInventory -Reads @('HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode')
        $sw.Stop()
        Write-Host ("Inventario real: {0:N1} s; partes fallidas: {1}" -f $sw.Elapsed.TotalSeconds, ($inv.Errors -join ', '))
        $sw.Elapsed.TotalSeconds | Should -BeLessThan 25
        @($inv.Errors).Count | Should -Be 0
        @($inv.Displays).Count | Should -BeGreaterThan 0
    }
}
