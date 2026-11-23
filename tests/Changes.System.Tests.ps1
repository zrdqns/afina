BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:user = [pscustomobject]@{ Sid = 'S-1-5-21-1'; IsSameAsProcess = $true; HkcuRoot = 'HKCU:' }
    $script:otherUser = [pscustomobject]@{ Sid = 'S-1-5-21-2'; IsSameAsProcess = $false; HkcuRoot = 'Registry::HKEY_USERS\S-1-5-21-2' }
    function New-Ok([string]$Output = '') { [pscustomobject]@{ ExitCode = 0; Output = $Output; Error = ''; TimedOut = $false } }
}

# Todas las pruebas de este archivo sustituyen los envoltorios y cmdlets que tocan el sistema real.
Describe 'Set-AfSystemParameter' {
    BeforeEach {
        $script:mouse = @(0, 0, 0)
        $script:anim = $true
        Mock Get-AfSystemParameterValue { if ($Name -eq 'Mouse') { , [int[]]$script:mouse } else { $script:anim } }
        Mock Invoke-AfSetSystemParameter { if ($Name -eq 'Mouse') { $script:mouse = [int[]]$Value } else { $script:anim = [bool]$Value } }
    }

    It 'guarda, escribe, verifica y deshace' {
        $script:mouse = @(1, 6, 10)
        $tx = New-AfTransaction -User $script:user
        Set-AfSystemParameter -Tx $tx -Name Mouse -Value @(0, 0, 0) | Should -BeTrue
        $tx.Records[0].Kind | Should -Be 'SystemParameter'
        @($tx.Records[0].Previous) | Should -Be @(1, 6, 10)
        @($script:mouse) | Should -Be @(0, 0, 0)
        Undo-AfRecords -Records @($tx.Records) -User $script:user | ForEach-Object { $_.Failed.Count } | Should -Be 0
        Should -Invoke Invoke-AfSetSystemParameter -Times 1 -Exactly -ParameterFilter { $Name -eq 'Mouse' -and (@($Value) -join ',') -eq '1,6,10' }
    }

    It 'no deja registro si ya está en el valor' {
        $tx = New-AfTransaction -User $script:user
        Set-AfSystemParameter -Tx $tx -Name ClientAreaAnimation -Value $true | Should -BeFalse
        $tx.Records.Count | Should -Be 0
        Should -Invoke Invoke-AfSetSystemParameter -Times 0 -Exactly
    }

    It 'compara bien tras pasar por JSON' {
        $script:mouse = @(1, 6, 10)
        $tx = New-AfTransaction -User $script:user
        Set-AfSystemParameter -Tx $tx -Name Mouse -Value @(0, 0, 0) | Out-Null
        $record = ConvertTo-Json -InputObject @($tx.Records[0]) -Depth 6 | ConvertFrom-Json | Select-Object -First 1
        Test-AfRecordRestored -Record $record -User $script:user | Should -BeFalse
        $script:mouse = @(1, 6, 10)
        Test-AfRecordRestored -Record $record -User $script:user | Should -BeTrue
    }

    It 'no toca nada con otra cuenta' {
        $tx = New-AfTransaction -User $script:otherUser
        { Set-AfSystemParameter -Tx $tx -Name ClientAreaAnimation -Value $false } | Should -Throw
        Should -Invoke Invoke-AfSetSystemParameter -Times 0 -Exactly
        $tx.Records.Count | Should -Be 0
    }

    It 'deshecho con otra cuenta falla con motivo' {
        $record = [pscustomobject]@{ Kind = 'SystemParameter'; Name = 'Mouse'; Previous = @(1, 6, 10); New = @(0, 0, 0) }
        $thrown = $null
        try { Restore-AfSystemParameter -Record $record -User $script:otherUser } catch { $thrown = $_ }
        $thrown | Should -Not -BeNullOrEmpty
        (Get-AfApplyReason -ErrorRecord $thrown) | Should -Not -BeNullOrEmpty
        Should -Invoke Invoke-AfSetSystemParameter -Times 0 -Exactly
    }

    It 'revierte si Windows no lo tomó' {
        Mock Invoke-AfSetSystemParameter { }
        $script:anim = $true
        $tx = New-AfTransaction -User $script:user
        { Set-AfSystemParameter -Tx $tx -Name ClientAreaAnimation -Value $false } | Should -Throw
        $tx.Records.Count | Should -Be 1
    }
}

Describe 'Set-AfDeliveryOptimizationMode' {
    BeforeEach {
        $script:doMode = 'Internet'
        Mock Get-AfRegistryValue { $null } -ParameterFilter { $Name -eq 'DODownloadMode' }
        Mock Get-DOConfig { [pscustomobject]@{ DownloadMode = $script:doMode } }
        Mock Invoke-AfSetDeliveryOptimizationMode { $script:doMode = $Mode }
    }

    It 'de Internet a Lan y vuelta' {
        $tx = New-AfTransaction -User $script:user
        Set-AfDeliveryOptimizationMode -Tx $tx -Mode Lan | Should -BeTrue
        $tx.Records[0].Kind | Should -Be 'DeliveryOptimizationMode'
        $tx.Records[0].Previous | Should -Be 'Internet'
        $script:doMode | Should -Be 'Lan'
        (Undo-AfRecords -Records @($tx.Records) -User $script:user).Failed.Count | Should -Be 0
        $script:doMode | Should -Be 'Internet'
        Test-AfRecordRestored -Record $tx.Records[0] -User $script:user | Should -BeTrue
    }

    It 'si ya está en Lan no deja registro' {
        $script:doMode = 'Lan'
        $tx = New-AfTransaction -User $script:user
        Set-AfDeliveryOptimizationMode -Tx $tx -Mode Lan | Should -BeFalse
        $tx.Records.Count | Should -Be 0
        Should -Invoke Invoke-AfSetDeliveryOptimizationMode -Times 0 -Exactly
    }

    It 'si Windows no lo tomó, lanza' {
        Mock Invoke-AfSetDeliveryOptimizationMode { }
        $tx = New-AfTransaction -User $script:user
        { Set-AfDeliveryOptimizationMode -Tx $tx -Mode Lan } | Should -Throw
    }

    It 'si al deshacer el modo no vuelve, falla y conserva el registro' {
        $tx = New-AfTransaction -User $script:user
        Set-AfDeliveryOptimizationMode -Tx $tx -Mode Lan | Out-Null
        Mock Invoke-AfSetDeliveryOptimizationMode { }
        $result = Undo-AfRecords -Records @($tx.Records) -User $script:user
        $result.Failed.Count | Should -Be 1
        $result.Reason | Should -Not -BeNullOrEmpty
    }

    It 'no escribe si el modo actual no se sabe volver a poner' {
        foreach ($mode in 'Group', 'Simple', 'Bypass', '') {
            $script:doMode = $mode
            $tx = New-AfTransaction -User $script:user
            { Set-AfDeliveryOptimizationMode -Tx $tx -Mode Lan } | Should -Throw
            $tx.Records.Count | Should -Be 0
        }
        Should -Invoke Invoke-AfSetDeliveryOptimizationMode -Times 0 -Exactly
    }

    It 'al deshacer con una directiva puesta avisa y conserva el registro' {
        $tx = New-AfTransaction -User $script:user
        Set-AfDeliveryOptimizationMode -Tx $tx -Mode Lan | Out-Null
        Mock Get-AfRegistryValue { 1 } -ParameterFilter { $Name -eq 'DODownloadMode' }
        $result = Undo-AfRecords -Records @($tx.Records) -User $script:user
        $result.Failed.Count | Should -Be 1
        $result.Reason | Should -Match 'directiva'
        $script:doMode | Should -Be 'Lan'
        Should -Invoke Invoke-AfSetDeliveryOptimizationMode -Times 1 -Exactly
    }
}

Describe 'Set-AfPagefileAuto' {
    BeforeEach {
        $script:auto = $false
        $script:pagingState = [pscustomobject]@{ KeyExists = $true; Exists = $true; Type = 'String'; Value = 'C:\pagefile.sys 4096 8192' }
        Mock Get-AfRegistryState { $script:pagingState }
        Mock Get-CimInstance { New-CimInstance -ClassName Win32_ComputerSystem -ClientOnly -Property @{ AutomaticManagedPagefile = $script:auto } }
        Mock Set-CimInstance { $script:auto = [bool]$Property.AutomaticManagedPagefile }
        Mock New-ItemProperty { }
    }

    It 'guarda PagingFiles y activa el automático' {
        $tx = New-AfTransaction -User $script:user
        Set-AfPagefileAuto -Tx $tx | Should -BeTrue
        $tx.Records[0].Kind | Should -Be 'PagefileAuto'
        $tx.Records[0].Previous.Type | Should -Be 'String'
        $tx.Records[0].Previous.Value | Should -Be 'C:\pagefile.sys 4096 8192'
        Should -Invoke Set-CimInstance -Times 1 -Exactly -ParameterFilter { $Property.AutomaticManagedPagefile -eq $true }
    }

    It 'si ya es automático no deja registro' {
        $script:auto = $true
        $tx = New-AfTransaction -User $script:user
        Set-AfPagefileAuto -Tx $tx | Should -BeFalse
        $tx.Records.Count | Should -Be 0
        Should -Invoke Set-CimInstance -Times 0 -Exactly
    }

    It 'si no quedó automático, lanza' {
        Mock Set-CimInstance { }
        $tx = New-AfTransaction -User $script:user
        { Set-AfPagefileAuto -Tx $tx } | Should -Throw
    }

    It 'deshacer restaura el valor y el tipo' {
        $tx = New-AfTransaction -User $script:user
        Set-AfPagefileAuto -Tx $tx | Out-Null
        $script:pagingState = [pscustomobject]@{ KeyExists = $true; Exists = $true; Type = 'String'; Value = '?:\pagefile.sys' }
        Mock New-ItemProperty { $script:pagingState = [pscustomobject]@{ KeyExists = $true; Exists = $true; Type = [string]$PropertyType; Value = $Value } }
        (Undo-AfRecords -Records @($tx.Records) -User $script:user).Failed.Count | Should -Be 0
        Should -Invoke New-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq 'PagingFiles' -and $PropertyType -eq 'String' -and $Value -eq 'C:\pagefile.sys 4096 8192' }
        Should -Invoke Set-CimInstance -Times 1 -Exactly -ParameterFilter { $Property.AutomaticManagedPagefile -eq $false }
        Test-AfRecordRestored -Record $tx.Records[0] -User $script:user | Should -BeTrue
    }

    It 'si al deshacer el automático sigue activo, falla y conserva el registro' {
        $tx = New-AfTransaction -User $script:user
        Set-AfPagefileAuto -Tx $tx | Out-Null
        Mock Set-CimInstance { }
        $result = Undo-AfRecords -Records @($tx.Records) -User $script:user
        $result.Failed.Count | Should -Be 1
        $result.Reason | Should -Not -BeNullOrEmpty
        Should -Invoke New-ItemProperty -Times 0 -Exactly
    }

    It 'si el PagingFiles original ya era automático, el indicador activo no es fallo' {
        $script:pagingState = [pscustomobject]@{ KeyExists = $true; Exists = $true; Type = 'String'; Value = '?:\pagefile.sys' }
        $tx = New-AfTransaction -User $script:user
        Set-AfPagefileAuto -Tx $tx | Out-Null
        Mock Set-CimInstance { }
        (Undo-AfRecords -Records @($tx.Records) -User $script:user).Failed.Count | Should -Be 0
    }

    It 'conserva MultiString al deshacer' {
        $script:pagingState = [pscustomobject]@{ KeyExists = $true; Exists = $true; Type = 'MultiString'; Value = [string[]]@('C:\pagefile.sys 0 0') }
        $tx = New-AfTransaction -User $script:user
        Set-AfPagefileAuto -Tx $tx | Out-Null
        Restore-AfPagefileAuto -Record $tx.Records[0] -User $script:user
        Should -Invoke New-ItemProperty -Times 1 -Exactly -ParameterFilter { $PropertyType -eq 'MultiString' -and $Value -is [string[]] }
    }
}

Describe 'Hibernación' {
    It 'Get-AfHibernationType' {
        $ram = 16GB
        Get-AfHibernationType -FileBytes ([long]($ram * 0.4)) -RamBytes $ram -SizePercent 0 | Should -Be 'Full'
        Get-AfHibernationType -FileBytes ([long]($ram * 0.4)) -RamBytes $ram -SizePercent 40 | Should -Be 'Full'
        Get-AfHibernationType -FileBytes ([long]($ram * 0.2)) -RamBytes $ram -SizePercent 0 | Should -Be 'Reduced'
        Get-AfHibernationType -FileBytes ([long]($ram * 0.4)) -RamBytes $ram -SizePercent 60 | Should -Be 'Custom'
        Get-AfHibernationType -FileBytes ([long]($ram * 0.2)) -RamBytes $ram -SizePercent 20 | Should -Be 'Reduced'
        Get-AfHibernationType -FileBytes ([long]($ram * 0.4)) -RamBytes $ram -SizePercent 20 | Should -Be 'Full'
        Get-AfHibernationType -FileBytes 0 -RamBytes $ram -SizePercent 0 | Should -BeNullOrEmpty
    }

    It 'Get-AfHibernationInfo lanza si falla la lectura de la RAM' {
        Mock Get-AfRegistryValue { 1 }
        Mock Get-CimInstance { Write-Error 'falla a propósito' }
        { Get-AfHibernationInfo } | Should -Throw
    }

    Context 'Set-AfHibernationType' {
        BeforeEach {
            $script:hiber = 'Full'
            Mock Get-AfHibernationInfo { @{ Enabled = $true; FileBytes = 1GB; RamBytes = 16GB; Type = $script:hiber } }
            Mock Invoke-AfPowercfg { $script:hiber = if ($Arguments -match 'reduced') { 'Reduced' } else { 'Full' }; New-Ok }
        }

        It 'reduced y vuelta a full' {
            $tx = New-AfTransaction -User $script:user
            Set-AfHibernationType -Tx $tx -Type Reduced | Should -BeTrue
            $tx.Records[0].Kind | Should -Be 'HibernationType'
            $tx.Records[0].Previous | Should -Be 'Full'
            Should -Invoke Invoke-AfPowercfg -Times 1 -Exactly -ParameterFilter { $Arguments -eq '/h /type reduced' }
            (Undo-AfRecords -Records @($tx.Records) -User $script:user).Failed.Count | Should -Be 0
            Should -Invoke Invoke-AfPowercfg -Times 1 -Exactly -ParameterFilter { $Arguments -eq '/h /type full' }
            Test-AfRecordRestored -Record $tx.Records[0] -User $script:user | Should -BeTrue
        }

        It 'si ya está en el tipo no deja registro' {
            $tx = New-AfTransaction -User $script:user
            Set-AfHibernationType -Tx $tx -Type Full | Should -BeFalse
            $tx.Records.Count | Should -Be 0
            Should -Invoke Invoke-AfPowercfg -Times 0 -Exactly
        }

        It 'sin espacio para volver dice por qué y conserva el registro' {
            $tx = New-AfTransaction -User $script:user
            Set-AfHibernationType -Tx $tx -Type Reduced | Out-Null
            Mock Invoke-AfPowercfg { throw (New-AfApplyError -Reason 'powercfg') }
            $result = Undo-AfRecords -Records @($tx.Records) -User $script:user
            $result.Failed.Count | Should -Be 1
            $result.Reason | Should -Be (T 'falta espacio en el disco para volver a la hibernación completa')
        }
    }
}

Describe 'Get-AfRecordNotifyArea' {
    It 'da ImmersiveColorSet solo para EnableTransparency de Personalize' {
        $theme = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        Get-AfRecordNotifyArea -Record ([pscustomobject]@{ Kind = 'RegistryValue'; Path = $theme; Name = 'EnableTransparency' }) | Should -Be 'ImmersiveColorSet'
        Get-AfRecordNotifyArea -Record ([pscustomobject]@{ Kind = 'RegistryValue'; Path = $theme; Name = 'Otro' }) | Should -BeNullOrEmpty
        Get-AfRecordNotifyArea -Record ([pscustomobject]@{ Kind = 'RegistryValue'; Path = 'HKCU:\Software\X'; Name = 'EnableTransparency' }) | Should -BeNullOrEmpty
        Get-AfRecordNotifyArea -Record ([pscustomobject]@{ Kind = 'SystemParameter'; Name = 'Mouse' }) | Should -BeNullOrEmpty
    }

    It 'da ShellState solo para HideFileExt de Explorer\Advanced' {
        $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Get-AfRecordNotifyArea -Record ([pscustomobject]@{ Kind = 'RegistryValue'; Path = $adv; Name = 'HideFileExt' }) | Should -Be 'ShellState'
        Get-AfRecordNotifyArea -Record ([pscustomobject]@{ Kind = 'RegistryValue'; Path = $adv; Name = 'Otro' }) | Should -BeNullOrEmpty
        Get-AfRecordNotifyArea -Record ([pscustomobject]@{ Kind = 'RegistryValue'; Path = 'HKCU:\Software\X'; Name = 'HideFileExt' }) | Should -BeNullOrEmpty
    }
}

Describe 'Add-AfUnverifiedNote' {
    It 'solo agrega fuera de la build probada' {
        Get-AfTestedBuild | Should -Be 26300
        $tx = New-AfTransaction
        Add-AfUnverifiedNote -Tx $tx -Os ([pscustomobject]@{ Build = 26300 })
        $tx.Notes.Count | Should -Be 0
        Add-AfUnverifiedNote -Tx $tx -Os ([pscustomobject]@{ Build = 26100 })
        $tx.Notes.Count | Should -Be 1
        $tx.Notes[0] | Should -Be 'Escrito, comprueba que se vea el cambio'
    }
}
