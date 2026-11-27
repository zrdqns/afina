BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    function Test-Check([string]$Id, $Inventory) {
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id }
        if (-not $check) { throw "No existe la revisión $Id" }
        Invoke-AfCheck -Check $check -Inventory $Inventory
    }
    function Get-Apply([string]$Id) { (@(Get-AfCatalog) | Where-Object { $_.Id -eq $Id }).Apply }
    $script:sense = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
    $script:otherUser = [pscustomobject]@{ Name = 'LOQ\Otro'; Sid = 'S-1-5-21-2'; ProfilePath = 'C:\Users\Otro'; IsSameAsProcess = $false; HkcuRoot = 'Registry::HKEY_USERS\S-1-5-21-2' }
    $script:lowDisk = [pscustomobject]@{ SystemDrive = 'C:'; FreeBytes = [long]10GB; FreeGB = 10; SizeGB = 476; MediaType = 'SSD'; BusType = 'NVMe'; TrimEnabled = $true; TempBytes = $null }
    $script:desktop = [pscustomobject]@{ Manufacturer = 'ASUS'; Model = 'PRIME'; IsLaptop = $false; IsDesktop = $true; OnBattery = $false }
    $script:unknown = [pscustomobject]@{ Manufacturer = 'ASUS'; Model = 'PRIME'; IsLaptop = $false; IsDesktop = $false; OnBattery = $false }
}

Describe 'startup.edge-background' {
    It 'Manual con pasos si Edge corre sin ventanas' {
        $inv = New-AfFakeInventory -Override @{ Edge = @{ Installed = $true; Running = $true; HasWindow = $false } }
        $r = Test-Check 'startup.edge-background' $inv
        $r.Detection.State | Should -Be 'Manual'
        ($r.Detection.Steps -join ' ') | Should -Match 'edge://settings/system'
    }

    It 'NotApplicable con ventanas abiertas' {
        $inv = New-AfFakeInventory -Override @{ Edge = @{ Installed = $true; Running = $true; HasWindow = $true } }
        (Test-Check 'startup.edge-background' $inv).Detection.State | Should -Be 'NotApplicable'
    }

    It 'Ok si Edge no corre' {
        (Test-Check 'startup.edge-background' (New-AfFakeInventory)).Detection.State | Should -Be 'Ok'
    }

    It 'NotApplicable sin Edge o si la lectura falló' {
        (Test-Check 'startup.edge-background' (New-AfFakeInventory -Override @{ Edge = @{ Installed = $false; Running = $false; HasWindow = $false } })).Detection.State | Should -Be 'NotApplicable'
        (Test-Check 'startup.edge-background' (New-AfFakeInventory -Override @{ Edge = $null })).Detection.State | Should -Be 'NotApplicable'
    }

    It 'Info con una directiva de Edge' {
        $inv = New-AfFakeInventory -Override @{ Edge = @{ Installed = $true; Running = $true; HasWindow = $false }; Registry = @{ 'HKLM:\SOFTWARE\Policies\Microsoft\Edge|StartupBoostEnabled' = 0 } }
        (Test-Check 'startup.edge-background' $inv).Detection.State | Should -Be 'Info'
    }
}

Describe 'network.delivery-optimization' {
    It 'es a mano: Kind Manual, sin Apply y sin marcar' {
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq 'network.delivery-optimization' }
        $check.Kind | Should -Be 'Manual'
        $check.ContainsKey('Apply') | Should -BeFalse
        $check.Preselect | Should -BeFalse
        $check.Undo | Should -Be 'No cambia nada'
    }

    It 'Manual con pasos de Configuración en modo Internet, según la versión de Windows' {
        $win11 = [pscustomobject]@{ Caption = 'Microsoft Windows 11'; Build = 26300; Edition = 'Professional'; IsWin11 = $true; IsInsider = $false; Ubr = 1000 }
        $r = Test-Check 'network.delivery-optimization' (New-AfFakeInventory -Override @{ Os = $win11; DeliveryOptimization = @{ Available = $true; Mode = 'Internet' } })
        $r.Detection.State | Should -Be 'Manual'
        $r.Preselected | Should -BeFalse
        $r.Detection.Steps[0] | Should -Be 'Abre Configuración > Windows Update > Opciones avanzadas > Optimización de distribución.'
        $r.Detection.Steps[1] | Should -Be 'Elige "Dispositivos de mi red local" o apaga "Permitir descargas de otros dispositivos".'
        $win10 = [pscustomobject]@{ Caption = 'Microsoft Windows 10'; Build = 19045; Edition = 'Professional'; IsWin11 = $false; IsInsider = $false; Ubr = 1000 }
        $d = (Test-Check 'network.delivery-optimization' (New-AfFakeInventory -Override @{ Os = $win10; DeliveryOptimization = @{ Available = $true; Mode = 'Internet' } })).Detection
        $d.Steps[0] | Should -Be 'Abre Configuración > Actualización y seguridad > Optimización de distribución.'
        (@($d.Steps) -join ' ') | Should -Not -Match 'Se puede cambiar'
    }

    It 'Ok en Lan, CdnOnly, Group y Simple' {
        foreach ($mode in 'Lan', 'CdnOnly', 'Group', 'Simple') {
            (Test-Check 'network.delivery-optimization' (New-AfFakeInventory -Override @{ DeliveryOptimization = @{ Available = $true; Mode = $mode } })).Detection.State | Should -Be 'Ok' -Because $mode
        }
    }

    It 'Info con directiva' {
        $inv = New-AfFakeInventory -Override @{ DeliveryOptimization = @{ Available = $true; Mode = 'Internet' }; Registry = @{ 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization|DODownloadMode' = 3 } }
        (Test-Check 'network.delivery-optimization' $inv).Detection.State | Should -Be 'Info'
    }

    It 'NotApplicable sin cmdlet o con la lectura fallida' {
        (Test-Check 'network.delivery-optimization' (New-AfFakeInventory -Override @{ DeliveryOptimization = @{ Available = $false; Mode = $null } })).Detection.State | Should -Be 'NotApplicable'
        (Test-Check 'network.delivery-optimization' (New-AfFakeInventory -Override @{ DeliveryOptimization = $null })).Detection.State | Should -Be 'NotApplicable'
    }

    It 'Info si el modo Internet lo fija MDM o el registro, no si es de Configuración' {
        foreach ($case in @(@('MdmProvider', 'Info'), @('RegistryProvider', 'Info'), @('SettingsProvider', 'Manual'), @('DefaultProvider', 'Manual'))) {
            $inv = New-AfFakeInventory -Override @{ DeliveryOptimization = @{ Available = $true; Mode = 'Internet'; Provider = $case[0] } }
            (Test-Check 'network.delivery-optimization' $inv).Detection.State | Should -Be $case[1] -Because $case[0]
        }
    }

    It 'con el modo ya en Lan no mira el proveedor' {
        $inv = New-AfFakeInventory -Override @{ DeliveryOptimization = @{ Available = $true; Mode = 'Lan'; Provider = 'MdmProvider' } }
        (Test-Check 'network.delivery-optimization' $inv).Detection.State | Should -Be 'Ok'
    }

    It 'ya no existe la pieza que cambiaba el modo' {
        foreach ($name in 'Set-AfDeliveryOptimizationMode', 'Restore-AfDeliveryOptimizationMode', 'Get-AfDeliveryOptimizationModeState', 'Invoke-AfSetDeliveryOptimizationMode') {
            Get-Command -Name $name -ErrorAction SilentlyContinue | Should -BeNullOrEmpty -Because $name
        }
        Get-Command -Name 'Get-AfDeliveryOptimizationMode' | Should -Not -BeNullOrEmpty
    }
}

Describe 'gaming.mouse-acceleration' {
    It 'Improvable y sin marcar con aceleración' {
        $r = Test-Check 'gaming.mouse-acceleration' (New-AfFakeInventory -Override @{ Registry = @{ 'HKCU:\Control Panel\Mouse|MouseSpeed' = '1' } })
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeFalse
    }

    It 'Ok sin aceleración' {
        (Test-Check 'gaming.mouse-acceleration' (New-AfFakeInventory -Override @{ Registry = @{ 'HKCU:\Control Panel\Mouse|MouseSpeed' = '0' } })).Detection.State | Should -Be 'Ok'
    }

    It 'NotApplicable con otra cuenta o sin lectura' {
        $other = (New-AfFakeInventory).User.PSObject.Copy(); $other.IsSameAsProcess = $false
        (Test-Check 'gaming.mouse-acceleration' (New-AfFakeInventory -Override @{ User = $other; Registry = @{ 'HKCU:\Control Panel\Mouse|MouseSpeed' = '1' } })).Detection.State | Should -Be 'NotApplicable'
        (Test-Check 'gaming.mouse-acceleration' (New-AfFakeInventory)).Detection.State | Should -Be 'NotApplicable'
    }

    It 'Apply usa la pieza del parámetro y escribe las tres claves' {
        Mock Set-AfSystemParameter { $true }
        Mock Set-AfRegistryValue { $true }
        & (Get-Apply 'gaming.mouse-acceleration') (New-AfFakeInventory) $null (New-AfTransaction -User (New-AfFakeInventory).User)
        Should -Invoke Set-AfSystemParameter -Times 1 -Exactly -ParameterFilter { $Name -eq 'Mouse' -and (@($Value) -join ',') -eq '0,0,0' }
        foreach ($n in 'MouseSpeed', 'MouseThreshold1', 'MouseThreshold2') {
            Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Name -eq $n -and $Value -eq '0' -and $Type -eq 'String' }
        }
    }
}

Describe 'gaming.visual-effects' {
    BeforeAll {
        function New-Weak($Ram, $Media, $Anim, $Transparency) {
            $memory = [pscustomobject]@{ TotalGB = $Ram; Socketed = $true; Modules = @() }
            $storage = (New-AfFakeInventory).Storage.PSObject.Copy(); $storage.MediaType = $Media
            $registry = @{}
            if ($null -ne $Transparency) { $registry['HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize|EnableTransparency'] = $Transparency }
            New-AfFakeInventory -Override @{ Memory = $memory; Storage = $storage; Effects = @{ ClientAreaAnimation = $Anim }; Registry = $registry }
        }
    }

    It 'NotApplicable en una PC fuerte (16 GB y SSD)' {
        (Test-Check 'gaming.visual-effects' (New-Weak 16 'SSD' $true 1)).Detection.State | Should -Be 'NotApplicable'
    }

    It 'Improvable y marcado con 8 GB y animación encendida' {
        $r = Test-Check 'gaming.visual-effects' (New-Weak 8 'SSD' $true 0)
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeTrue
    }

    It 'NotApplicable con 0 GB de RAM leídos y SSD; con HDD sigue siendo débil' {
        (Test-Check 'gaming.visual-effects' (New-Weak 0 'SSD' $true 1)).Detection.State | Should -Be 'NotApplicable'
        (Test-Check 'gaming.visual-effects' (New-Weak 0 'HDD' $true 1)).Detection.State | Should -Be 'Improvable'
    }

    It 'Improvable en HDD con 16 GB y transparencia encendida' {
        (Test-Check 'gaming.visual-effects' (New-Weak 16 'HDD' $false 1)).Detection.State | Should -Be 'Improvable'
    }

    It 'Ok si ambos ya están apagados' {
        (Test-Check 'gaming.visual-effects' (New-Weak 8 'SSD' $false 0)).Detection.State | Should -Be 'Ok'
    }

    It 'NotApplicable con otra cuenta o con la lectura fallida' {
        $inv = New-Weak 8 'SSD' $true 1
        $inv.User = $script:otherUser
        (Test-Check 'gaming.visual-effects' $inv).Detection.State | Should -Be 'NotApplicable'
        $inv = New-Weak 8 'SSD' $true 1
        $inv.Effects = $null
        (Test-Check 'gaming.visual-effects' $inv).Detection.State | Should -Be 'NotApplicable'
    }

    It 'Apply escribe la transparencia, apaga la animación y avisa al shell' {
        Mock Set-AfRegistryValue { $true }
        Mock Set-AfSystemParameter { $true }
        Mock Send-AfShellNotify { }
        & (Get-Apply 'gaming.visual-effects') (New-Weak 8 'SSD' $true 1) $null (New-AfTransaction -User (New-AfFakeInventory).User)
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Name -eq 'EnableTransparency' -and $Value -eq 0 -and $Type -eq 'DWord' }
        Should -Invoke Set-AfSystemParameter -Times 1 -Exactly -ParameterFilter { $Name -eq 'ClientAreaAnimation' -and $Value -eq $false }
        Should -Invoke Send-AfShellNotify -Times 1 -Exactly -ParameterFilter { $Area -eq 'ImmersiveColorSet' }
    }
}

Describe 'Send-AfShellNotify' {
    It 'registra el fallo y no lanza' {
        Mock Initialize-AfNative { throw 'sin compilador' }
        Mock Write-AfLog { }
        { Send-AfShellNotify -Area 'ImmersiveColorSet' } | Should -Not -Throw
        Should -Invoke Write-AfLog -Times 1 -Exactly -ParameterFilter { $Level -eq 'Warn' }
    }

    It 'no lanza si el código nativo no está' {
        Mock Initialize-AfNative { $false }
        Mock Write-AfLog { }
        { Send-AfShellNotify -Area 'x' } | Should -Not -Throw
    }
}

Describe 'storage.hibernation' {
    BeforeAll {
        function New-Hib($Type = 'Full', $Storage = $script:lowDisk, $Device = $null) {
            $o = @{ Hibernation = @{ Enabled = $true; FileBytes = [long]12GB; RamBytes = [long]32GB; Type = $Type }; Storage = $Storage }
            if ($Device) { $o.Device = $Device }
            New-AfFakeInventory -Override $o
        }
    }

    It 'NotApplicable con disco sobrado' {
        (Test-Check 'storage.hibernation' (New-Hib 'Full' (New-AfFakeInventory).Storage $script:desktop)).Detection.State | Should -Be 'NotApplicable'
    }

    It 'en escritorio con poco disco: Improvable, sin marcar y con aviso de la luz' {
        $r = Test-Check 'storage.hibernation' (New-Hib 'Full' $script:lowDisk $script:desktop)
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeFalse
        $r.Detection.Note | Should -Match 'se va la luz'
    }

    It 'en laptop con poco disco: Info con el tamaño, sin casilla' {
        $r = Test-Check 'storage.hibernation' (New-Hib 'Full')
        $r.Detection.State | Should -Be 'Info'
        $r.Detection.Current | Should -Match 'GB'
        $r.Preselected | Should -BeFalse
        $r.Detection.Note | Should -Be 'Solo se reduce en escritorios confirmados; en laptops y equipos sin identificar no se toca.'
    }

    It 'con tipo de equipo desconocido o sin datos: Info y Apply no hace nada' {
        Mock Set-AfHibernationType { $true }
        foreach ($device in $script:unknown, $null) {
            $inv = New-AfFakeInventory -Override @{ Hibernation = @{ Enabled = $true; FileBytes = [long]12GB; RamBytes = [long]32GB; Type = 'Full' }; Storage = $script:lowDisk; Device = $device }
            $d = (Test-Check 'storage.hibernation' $inv).Detection
            $d.State | Should -Be 'Info'
            $d.Note | Should -Be 'Solo se reduce en escritorios confirmados; en laptops y equipos sin identificar no se toca.'
            & (Get-Apply 'storage.hibernation') $inv $null (New-AfTransaction -User $inv.User)
        }
        Should -Invoke Set-AfHibernationType -Times 0 -Exactly
    }

    It 'NotApplicable con un disco sin leer (0 GB de 0 GB)' {
        $empty = $script:lowDisk.PSObject.Copy(); $empty.FreeGB = 0; $empty.SizeGB = 0
        (Test-Check 'storage.hibernation' (New-Hib 'Full' $empty $script:desktop)).Detection.State | Should -Be 'NotApplicable'
    }

    It 'NotApplicable con Reduced, Custom o lectura fallida' {
        foreach ($type in 'Reduced', 'Custom') { (Test-Check 'storage.hibernation' (New-Hib $type)).Detection.State | Should -Be 'NotApplicable' -Because $type }
        (Test-Check 'storage.hibernation' (New-AfFakeInventory -Override @{ Hibernation = $null; Storage = $script:lowDisk })).Detection.State | Should -Be 'NotApplicable'
    }

    It 'Apply en escritorio pasa a Reduced y en laptop no hace nada' {
        Mock Set-AfHibernationType { $true }
        $tx = New-AfTransaction -User (New-AfFakeInventory).User
        & (Get-Apply 'storage.hibernation') (New-Hib 'Full' $script:lowDisk $script:desktop) $null $tx
        Should -Invoke Set-AfHibernationType -Times 1 -Exactly -ParameterFilter { $Type -eq 'Reduced' }
        & (Get-Apply 'storage.hibernation') (New-Hib 'Full') $null $tx
        Should -Invoke Set-AfHibernationType -Times 1 -Exactly
    }
}

Describe 'storage.free-space' {
    It 'usa el mismo umbral que Test-AfLowDisk' {
        (Test-Check 'storage.free-space' (New-AfFakeInventory -Override @{ Storage = $script:lowDisk })).Detection.State | Should -Be 'Info'
        (Test-Check 'storage.free-space' (New-AfFakeInventory)).Detection.State | Should -Be 'Ok'
    }
}

Describe 'storage.storage-sense' {
    It 'Improvable y marcado con el sensor apagado' {
        $r = Test-Check 'storage.storage-sense' (New-AfFakeInventory -Override @{ Registry = @{ "$($script:sense)|01" = 0 } })
        $r.Detection.State | Should -Be 'Improvable'
        $r.Detection.Current | Should -Be (T 'Apagado')
        $r.Preselected | Should -BeTrue
    }

    It 'Ok con el sensor encendido' {
        $r = Test-Check 'storage.storage-sense' (New-AfFakeInventory -Override @{ Registry = @{ "$($script:sense)|01" = 1 } })
        $r.Detection.State | Should -Be 'Ok'
        $r.Detection.Current | Should -Be (T 'Activado')
    }

    It 'Ok de fábrica sin la clave 01, con la nota de que Windows lo enciende solo' {
        $r = Test-Check 'storage.storage-sense' (New-AfFakeInventory)
        $r.Detection.State | Should -Be 'Ok'
        $r.Detection.Current | Should -Be (T 'De fábrica')
        $r.Detection.Note | Should -Be (T 'Windows lo enciende solo cuando queda poco espacio')
        $r.Preselected | Should -BeFalse
    }

    It 'Info con directiva aunque falte la clave 01' {
        $inv = New-AfFakeInventory -Override @{ Registry = @{ 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense|AllowStorageSenseGlobal' = 1 } }
        (Test-Check 'storage.storage-sense' $inv).Detection.State | Should -Be 'Info'
    }

    It 'Info con directiva' {
        $inv = New-AfFakeInventory -Override @{ Registry = @{ "$($script:sense)|01" = 0; 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense|AllowStorageSenseGlobal' = 0 } }
        (Test-Check 'storage.storage-sense' $inv).Detection.State | Should -Be 'Info'
    }

    It 'Apply escribe 01, 2048, 04, 08 y 32, y no 256 ni 512' {
        Mock Set-AfRegistryValue { $true }
        $inv = New-AfFakeInventory
        $tx = New-AfTransaction -User $inv.User
        & (Get-Apply 'storage.storage-sense') $inv $null $tx
        $expected = @{ '01' = 1; '2048' = 0; '04' = 1; '08' = 0; '32' = 0 }
        foreach ($name in $expected.Keys) {
            $n = $name; $v = $expected[$name]
            Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:sense -and $Name -eq $n -and $Value -eq $v -and $Type -eq 'DWord' }
        }
        Should -Invoke Set-AfRegistryValue -Times 0 -Exactly -ParameterFilter { $Name -in '256', '512' }
        Should -Invoke Set-AfRegistryValue -Times 5 -Exactly
    }

    It 'Apply en la build 26100 deja el aviso y en la 26300 no' {
        Mock Set-AfRegistryValue { $true }
        $inv = New-AfFakeInventory
        $tx = New-AfTransaction -User $inv.User
        & (Get-Apply 'storage.storage-sense') $inv $null $tx
        @($tx.Notes) | Should -Contain (T 'Escrito, comprueba que se vea el cambio')
        $os = $inv.Os.PSObject.Copy(); $os.Build = 26300
        $tx2 = New-AfTransaction -User $inv.User
        & (Get-Apply 'storage.storage-sense') (New-AfFakeInventory -Override @{ Os = $os }) $null $tx2
        $tx2.Notes.Count | Should -Be 0
    }
}

Describe 'Test-AfWeakPc' {
    It 'es débil con 8 GB o menos, o con HDD' {
        Test-AfWeakPc -Inventory (New-AfFakeInventory) | Should -BeFalse
        Test-AfWeakPc -Inventory (New-AfFakeInventory -Override @{ Memory = [pscustomobject]@{ TotalGB = 8 } }) | Should -BeTrue
        $hdd = (New-AfFakeInventory).Storage.PSObject.Copy(); $hdd.MediaType = 'HDD'
        Test-AfWeakPc -Inventory (New-AfFakeInventory -Override @{ Storage = $hdd }) | Should -BeTrue
    }
}
