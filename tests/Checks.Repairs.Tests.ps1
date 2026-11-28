BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    function Get-Check([string]$Id) { @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id } }
    function New-ScResult([int]$Code = 0) { [pscustomobject]@{ ExitCode = $Code; Output = ''; Error = ''; TimedOut = $false } }
    $script:svc = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    $script:dvr = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR|AllowGameDVR'
    function Invoke-Services([hashtable]$Registry) {
        Invoke-AfCheck -Check (Get-Check 'hardware.services') -Inventory (New-AfFakeInventory -Override @{ Registry = $Registry })
    }
    function New-Desktop([string]$Gpu, $WindowMB, [string]$Firmware = 'UEFI') {
        New-AfFakeInventory -Override @{
            Device = [pscustomobject]@{ Manufacturer = 'ASUS'; Model = 'PRIME'; IsLaptop = $false; IsDesktop = $true; OnBattery = $false; Firmware = $Firmware }
            Gpus = @([pscustomobject]@{ Name = $Gpu; Vendor = 'NVIDIA'; IsDiscrete = $true; HasDriver = $true; WindowMB = $WindowMB })
        }
    }
    function New-Game([string]$Name, [string]$Path, [long]$Bytes = 50GB, [string]$Launcher = 'Steam') {
        [pscustomobject]@{ Name = $Name; Path = $Path; Bytes = $Bytes; Launcher = $Launcher }
    }
    function New-Drive([string]$Media, [long]$Free = 300GB) { [pscustomobject]@{ MediaType = $Media; FreeBytes = $Free } }
}

AfterAll {
    $root = 'HKCU:\Software\AfinaTest'
    if (Test-Path $root) { Remove-Item $root -Recurse -Force }
}

Describe 'Servicios que deshabilitó otro programa' {
    It 'todo como viene en Windows: Ok' {
        (Invoke-Services @{ "$svc\Spooler|Start" = 2; "$svc\XblAuthManager|Start" = 3 }).Detection.State | Should -Be 'Ok'
    }

    It 'agrupa lo deshabilitado por función, solo con los servicios apagados, y viene marcado' {
        $r = Invoke-Services @{ "$svc\Spooler|Start" = 4; "$svc\UsoSvc|Start" = 4; "$svc\XblAuthManager|Start" = 4; "$svc\XblGameSave|Start" = 3; $dvr = 0 }
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeTrue
        $choices = @($r.Detection.Data.Choices)
        @($choices.Name) | Should -Be @('print', 'update', 'xbox', 'captures')
        @($choices[2].Services.Name) | Should -Be @('XblAuthManager')
        $choices[1].Services[0].Mode | Should -Be 'delayed-auto'
        $choices[0].Services[0].Mode | Should -Be 'auto'
        $choices[3].Policy | Should -BeTrue
        $r.Detection.Title | Should -Be '4 funciones de Windows deshabilitadas'
        $r.Detection.Current | Should -Be 'Impresión, Windows Update, Xbox (Game Pass, mandos) y Capturas de Game Bar'
    }

    It 'la directiva de Game Bar en 1 o sin poner no cuenta' {
        (Invoke-Services @{ $dvr = 1 }).Detection.State | Should -Be 'Ok'
    }

    It 'lee el inicio de cada servicio y la directiva' {
        $reads = @((Get-Check 'hardware.services').Reads)
        $reads | Should -Contain "$svc\Spooler|Start"
        $reads | Should -Contain "$svc\DPS|Start"
        $reads | Should -Contain $dvr
    }

    It 'aplica solo lo elegido: sc.exe para los servicios y borra la directiva' {
        Mock Get-AfServiceStart { [pscustomobject]@{ Start = 4; Delayed = $false } }
        Mock Invoke-AfProcess { New-ScResult }
        Mock Remove-AfRegistryValue { $true }
        $r = Invoke-Services @{ "$svc\Spooler|Start" = 4; "$svc\bthserv|Start" = 4; $dvr = 0 }
        $choices = @($r.Detection.Data.Choices)
        # La fila viene marcada con todas sus opciones; aquí el usuario deja solo dos.
        @($choices | Where-Object { -not $_.Selected }).Count | Should -Be 0
        foreach ($choice in $choices) { $choice.Selected = $false }
        ($choices | Where-Object Name -eq 'print').Selected = $true
        ($choices | Where-Object Name -eq 'captures').Selected = $true
        $tx = New-AfTransaction
        & $r.Check.Apply $null $r.Detection $tx
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $FilePath -like '*\sc.exe' -and $Arguments -eq 'config "Spooler" start= auto' }
        Should -Invoke Remove-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -and $Name -eq 'AllowGameDVR' }
    }
}

Describe 'Set-AfServiceStart' {
    It 'guarda el inicio anterior y deshacer lo devuelve' {
        Mock Get-AfServiceStart { [pscustomobject]@{ Start = 4; Delayed = $false } }
        Mock Invoke-AfProcess { New-ScResult }
        $tx = New-AfTransaction
        Set-AfServiceStart -Tx $tx -Name 'UsoSvc' -Mode 'delayed-auto' | Should -BeTrue
        $tx.Records[0].Kind | Should -Be 'ServiceStart'
        $tx.Records[0].Previous.Start | Should -Be 4
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq 'config "UsoSvc" start= delayed-auto' }
        Restore-AfServiceStart -Record $tx.Records[0]
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq 'config "UsoSvc" start= disabled' }
    }

    It 'no hace nada si ya está así o si el servicio no existe' {
        Mock Invoke-AfProcess { New-ScResult }
        Mock Get-AfServiceStart { [pscustomobject]@{ Start = 3; Delayed = $false } }
        Set-AfServiceStart -Tx (New-AfTransaction) -Name 'bthserv' -Mode 'demand' | Should -BeFalse
        Mock Get-AfServiceStart { $null }
        Set-AfServiceStart -Tx (New-AfTransaction) -Name 'NoExiste' -Mode 'demand' | Should -BeFalse
        Should -Invoke Invoke-AfProcess -Times 0 -Exactly
    }

    It 'si sc.exe falla da un motivo y no deja registro' {
        Mock Get-AfServiceStart { [pscustomobject]@{ Start = 4; Delayed = $false } }
        Mock Invoke-AfProcess { New-ScResult -Code 5 }
        $tx = New-AfTransaction
        { Set-AfServiceStart -Tx $tx -Name 'DPS' -Mode 'auto' } | Should -Throw -ExpectedMessage 'Windows no dejó cambiar el servicio'
        $tx.Records.Count | Should -Be 0
    }

    It 'lee el inicio real de un servicio; el diferido solo cuenta en los automáticos' {
        $state = Get-AfServiceStart -Name 'Spooler'
        $state.Start | Should -BeIn 2, 3, 4
        Get-AfServiceStart -Name 'AfinaNoExiste' | Should -BeNullOrEmpty
        ConvertTo-AfServiceMode -Start 3 -Delayed $true | Should -Be 'demand'
        ConvertTo-AfServiceMode -Start 2 -Delayed $true | Should -Be 'delayed-auto'
    }
}

Describe 'Remove-AfRegistryValue' {
    It 'borra el valor, guarda el anterior y deshacer lo vuelve a escribir' {
        $path = 'HKCU:\Software\AfinaTest\Directiva'
        New-Item -Path $path -Force | Out-Null
        New-ItemProperty -LiteralPath $path -Name 'AllowX' -PropertyType DWord -Value 0 -Force | Out-Null
        $tx = New-AfTransaction -User (Get-AfUserForSid)
        Remove-AfRegistryValue -Tx $tx -Path $path -Name 'AllowX' | Should -BeTrue
        (Get-AfRegistryState -Path $path -Name 'AllowX').Exists | Should -BeFalse
        Remove-AfRegistryValue -Tx (New-AfTransaction) -Path $path -Name 'AllowX' | Should -BeFalse
        Undo-AfRecord -Record $tx.Records[0]
        (Get-AfRegistryState -Path $path -Name 'AllowX').Value | Should -Be 0
        Test-AfRecordRestored -Record $tx.Records[0] | Should -BeTrue
    }
}

Describe 'Resizable BAR' {
    It 'RTX 3060 de escritorio con ventana de 256 MB: pasos de BIOS' {
        $r = Invoke-AfCheck -Check (Get-Check 'gpu.rebar') -Inventory (New-Desktop 'NVIDIA GeForce RTX 3060' 256)
        $r.Detection.State | Should -Be 'Manual'
        $r.Detection.Title | Should -Be 'Resizable BAR apagado'
        @($r.Detection.Steps)[1] | Should -BeLike '*Above 4G Decoding*'
    }
    It 'ventana grande: Ok' {
        (Invoke-AfCheck -Check (Get-Check 'gpu.rebar') -Inventory (New-Desktop 'AMD Radeon RX 7800 XT' 16384)).Detection.State | Should -Be 'Ok'
    }
    It 'con Windows en modo heredado avisa que hace falta UEFI primero' {
        $d = (Invoke-AfCheck -Check (Get-Check 'gpu.rebar') -Inventory (New-Desktop 'Intel(R) Arc(TM) A770 Graphics' 256 'BIOS')).Detection
        $d.State | Should -Be 'Manual'
        @($d.Steps)[0] | Should -BeLike '*modo heredado*'
    }
    It 'no aplica en laptops, gráficas viejas ni sin dato' {
        (Invoke-AfCheck -Check (Get-Check 'gpu.rebar') -Inventory (New-AfFakeInventory)).Detection.State | Should -Be 'NotApplicable'
        (Invoke-AfCheck -Check (Get-Check 'gpu.rebar') -Inventory (New-Desktop 'NVIDIA GeForce GTX 1660 SUPER' 256)).Detection.State | Should -Be 'NotApplicable'
        (Invoke-AfCheck -Check (Get-Check 'gpu.rebar') -Inventory (New-Desktop 'NVIDIA GeForce RTX 4070' $null)).Detection.State | Should -Be 'NotApplicable'
    }
    It 'una gráfica que Windows no encuentra no tiene dato' {
        Get-AfGpuWindowMB -PnpId 'PCI\VEN_FFFF&DEV_FFFF\0' | Should -BeNullOrEmpty
    }
}

Describe 'Juegos en disco mecánico' {
    It 'sin juegos no aplica; todos en SSD es Ok' {
        (Get-AfGamesHddDetection -Games @() -Drives @{ C = (New-Drive 'SSD') }).State | Should -Be 'NotApplicable'
        (Get-AfGamesHddDetection -Games @(New-Game 'Hades' 'C:\Steam\common\Hades') -Drives @{ C = (New-Drive 'SSD') }).State | Should -Be 'Ok'
    }
    It 'un juego de Steam en HDD con SSD libre: mover desde Steam' {
        $d = Get-AfGamesHddDetection -Games @((New-Game 'Hades' 'C:\Steam\common\Hades'), (New-Game 'Cyberpunk 2077' 'D:\SteamLibrary\steamapps\common\Cyberpunk 2077')) -Drives @{ C = (New-Drive 'SSD' 120GB); D = (New-Drive 'HDD') }
        $d.State | Should -Be 'Manual'
        $d.Title | Should -Be '1 juego en disco mecánico'
        $d.Current | Should -Be 'Cyberpunk 2077'
        @($d.Steps).Count | Should -Be 1
        @($d.Steps)[0] | Should -BeLike 'En Steam:*'
        $d.Note | Should -Be '120 GB libres en el SSD'
    }
    It 'Epic sin espacio en el SSD: primero liberar, después reinstalar' {
        $d = Get-AfGamesHddDetection -Games @(New-Game 'Fortnite' 'E:\Epic\Fortnite' 90GB 'Epic') -Drives @{ C = (New-Drive 'SSD' 40GB); E = (New-Drive 'HDD') }
        @($d.Steps)[0] | Should -BeLike 'Primero libera espacio*'
        @($d.Steps)[1] | Should -BeLike 'En Epic Games*'
    }
    It 'sin SSD en la PC: solo informa' {
        (Get-AfGamesHddDetection -Games @(New-Game 'Hades' 'D:\Juegos\Hades') -Drives @{ D = (New-Drive 'HDD') }).State | Should -Be 'Info'
    }
    It 'lee las bibliotecas de Steam y los juegos de Epic' {
        $steam = Join-Path $TestDrive 'Steam'
        $second = Join-Path $TestDrive 'Biblioteca'
        foreach ($dir in "$steam\steamapps", "$second\steamapps") { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $vdf = "`"libraryfolders`"`n{`n`t`"0`"`n`t{`n`t`t`"path`"`t`t`"$($steam.Replace('\', '\\'))`"`n`t}`n`t`"1`"`n`t{`n`t`t`"path`"`t`t`"$($second.Replace('\', '\\'))`"`n`t}`n}"
        Set-Content -LiteralPath "$steam\steamapps\libraryfolders.vdf" -Value $vdf -Encoding UTF8
        $acf = { param($id, $name, $size) "`"AppState`"`n{`n`t`"appid`"`t`t`"$id`"`n`t`"name`"`t`t`"$name`"`n`t`"installdir`"`t`t`"$name`"`n`t`"SizeOnDisk`"`t`t`"$size`"`n}" }
        Set-Content -LiteralPath "$steam\steamapps\appmanifest_228980.acf" -Value (& $acf 228980 'Steamworks Common Redistributables' 1000) -Encoding UTF8
        Set-Content -LiteralPath "$second\steamapps\appmanifest_1091500.acf" -Value (& $acf 1091500 'Cyberpunk 2077' 70000000000) -Encoding UTF8
        $epic = Join-Path $TestDrive 'Epic'
        New-Item -ItemType Directory -Path $epic -Force | Out-Null
        Set-Content -LiteralPath "$epic\a.item" -Value '{ "DisplayName": "Fortnite", "InstallLocation": "E:\\Epic\\Fortnite", "InstallSize": 9000, "AppCategories": ["public", "games"] }' -Encoding UTF8
        Set-Content -LiteralPath "$epic\b.item" -Value '{ "DisplayName": "Unreal Engine", "InstallLocation": "E:\\UE", "InstallSize": 1, "AppCategories": ["engines"] }' -Encoding UTF8
        # Una biblioteca en una unidad que ya no existe (un disco que se quitó) se salta sin error.
        $vdf = $vdf.Replace("`n`t}`n}", "`n`t}`n`t`"2`"`n`t{`n`t`t`"path`"`t`t`"Q:\\SteamLibrary`"`n`t}`n}")
        $vdf | Should -BeLike '*Q:\\SteamLibrary*'
        Set-Content -LiteralPath "$steam\steamapps\libraryfolders.vdf" -Value $vdf -Encoding UTF8
        $ErrorActionPreference = 'Stop'
        $games = @(Get-AfGameInstalls -SteamPath $steam -EpicPath $epic)
        @($games.Name) | Should -Be @('Cyberpunk 2077', 'Fortnite')
        $games[0].Path | Should -Be "$second\steamapps\common\Cyberpunk 2077"
        $games[0].Bytes | Should -Be 70000000000
        $games[1].Launcher | Should -Be 'Epic'
    }
}

Describe 'Programas que estorban' {
    It 'nombra los "aceleradores" y deja el resto' {
        $d = Get-AfJunkDetection -Programs @('Driver Booster 12', 'Google Chrome', 'CCleaner', 'Steam')
        $d.State | Should -Be 'Manual'
        $d.Title | Should -Be '2 programas que estorban'
        $d.Current | Should -Be 'Driver Booster 12 y CCleaner'
        @($d.Steps)[1] | Should -Be 'Desinstala Driver Booster 12 y CCleaner.'
    }
    It 'un antivirus apagado que sigue instalado cuenta; un registro viejo sin programa no' {
        $av = @(
            [pscustomobject]@{ Name = 'McAfee LiveSafe'; Enabled = $false; UpToDate = $false; IsDefender = $false }
            [pscustomobject]@{ Name = 'Norton 360'; Enabled = $false; UpToDate = $false; IsDefender = $false }
            [pscustomobject]@{ Name = 'Microsoft Defender Antivirus'; Enabled = $true; UpToDate = $true; IsDefender = $true }
        )
        $d = Get-AfJunkDetection -Programs @('McAfee LiveSafe', 'Steam') -Antivirus $av
        $d.State | Should -Be 'Manual'
        $d.Title | Should -Be 'McAfee LiveSafe instalado'
        @($d.Steps)[-1] | Should -BeLike 'McAfee LiveSafe está apagado*'
    }
    It 'sin nada de la lista: Ok' {
        (Get-AfJunkDetection -Programs @('Steam', 'Discord')).State | Should -Be 'Ok'
    }
    It 'lista los programas instalados sin los componentes del sistema' {
        $root = 'HKCU:\Software\AfinaTest\Uninstall'
        New-Item -Path "$root\a" -Force | Out-Null
        New-Item -Path "$root\b" -Force | Out-Null
        New-ItemProperty -LiteralPath "$root\a" -Name 'DisplayName' -Value 'Driver Booster 12' -Force | Out-Null
        New-ItemProperty -LiteralPath "$root\b" -Name 'DisplayName' -Value 'Componente' -Force | Out-Null
        New-ItemProperty -LiteralPath "$root\b" -Name 'SystemComponent' -PropertyType DWord -Value 1 -Force | Out-Null
        @(Get-AfInstalledPrograms -Roots @($root)) | Should -Be @('Driver Booster 12')
    }
}
