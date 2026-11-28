# Lecturas extra del inventario (solo lectura): paginación, entrega, Edge y efectos.
# Ninguna lanza hacia las revisiones: el inventario anota las partes que fallan.

function Test-AfLowDisk {
    param($Storage)
    if (-not $Storage) { return $false }
    $free = [double]$Storage.FreeGB
    $size = [double]$Storage.SizeGB
    # Un disco sin leer (tamaño 0) no es un disco lleno.
    if ($size -le 0) { return $false }
    $free -lt 20 -or ($free / $size) -lt 0.15
}

function Get-AfPagefileInfo {
    $system = Get-CimInstance -ClassName Win32_ComputerSystem -OperationTimeoutSec 15 -ErrorAction Stop
    # Sin instancias es válido (paginación automática); un fallo de lectura lanza.
    $files = @(Get-CimInstance -ClassName Win32_PageFileSetting -OperationTimeoutSec 15 -ErrorAction Stop)
    @{
        Automatic = [bool]$system.AutomaticManagedPagefile
        # MaximumSize = 0 significa que el sistema maneja el tamaño.
        Files = @($files | ForEach-Object { @{ Name = [string]$_.Name; MaxMB = [int]$_.MaximumSize } })
    }
}

# Recall: 'Enabled', 'Disabled' o 'Absent' (sin fila). Tarda unos 6 s y lanza si la lectura falla.
function Get-AfRecallState {
    $feature = Get-CimInstance -ClassName Win32_OptionalFeature -Filter "Name='Recall'" -OperationTimeoutSec 15 -ErrorAction Stop | Select-Object -First 1
    if (-not $feature) { return 'Absent' }
    switch ([int]$feature.InstallState) { 1 { 'Enabled' } 2 { 'Disabled' } default { 'Absent' } }
}

function Get-AfDeliveryOptimizationInfo {
    try {
        $mode = Get-AfDeliveryOptimizationMode
    } catch {
        return @{ Available = $false; Mode = $null; Provider = $null }
    }
    # El proveedor (Settings, MDM, registro...) dice quién fijó el modo; si no se lee, queda en null.
    $provider = try { [string](Get-DOConfig -ErrorAction Stop).DownloadModeProvider } catch { $null }
    @{ Available = $true; Mode = $mode; Provider = $provider }
}

function Get-AfEdgeInfo {
    $roots = @(${env:ProgramFiles(x86)}, $env:ProgramFiles) | Where-Object { $_ }
    $installed = [bool]@($roots | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'Microsoft\Edge\Application\msedge.exe') }).Count
    $session = [Diagnostics.Process]::GetCurrentProcess().SessionId
    $mine = @(Get-Process -Name msedge -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -eq $session })
    @{
        Installed = $installed
        Running = $mine.Count -gt 0
        HasWindow = @($mine | Where-Object { [int64]$_.MainWindowHandle -ne 0 }).Count -gt 0
    }
}

function Get-AfEffectsInfo {
    @{ ClientAreaAnimation = [bool](Get-AfSystemParameterValue -Name ClientAreaAnimation) }
}

# --- Juegos instalados (Steam y Epic): se leen sus archivos de texto, sin abrir los programas ---

function Get-AfSteamLibraryPaths {
    param([string]$Text)
    foreach ($m in [regex]::Matches([string]$Text, '"path"\s+"([^"]+)"')) { $m.Groups[1].Value.Replace('\\', '\') }
}

function ConvertFrom-AfSteamManifest {
    param([string]$Text)
    $field = { param($Key) $m = [regex]::Match($Text, '"' + $Key + '"\s+"([^"]*)"', 'IgnoreCase'); if ($m.Success) { $m.Groups[1].Value } }
    [pscustomobject]@{ AppId = (& $field 'appid'); Name = (& $field 'name'); InstallDir = (& $field 'installdir'); Bytes = [long](& $field 'SizeOnDisk') }
}

function Get-AfSteamPath {
    param($User)
    $path = Get-AfRegistryValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -Name 'InstallPath'
    if (-not $path) { $path = Get-AfRegistryValue -Path 'HKCU:\Software\Valve\Steam' -Name 'SteamPath' -User $User }
    if ($path) { ([string]$path).Replace('/', '\') }
}

function Get-AfGameInstalls {
    param($User, [string]$SteamPath = (Get-AfSteamPath -User $User), [string]$EpicPath = (Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'))
    $games = New-Object System.Collections.ArrayList
    if ($SteamPath -and [System.IO.Directory]::Exists($SteamPath)) {
        $libraries = @($SteamPath)
        $vdf = [System.IO.Path]::Combine($SteamPath, 'steamapps\libraryfolders.vdf')
        if ([System.IO.File]::Exists($vdf)) { $libraries += @(Get-AfSteamLibraryPaths -Text ([System.IO.File]::ReadAllText($vdf))) }
        foreach ($library in @($libraries | ForEach-Object { $_.TrimEnd('\') } | Sort-Object -Unique)) {
            # Path.Combine y no Join-Path: una biblioteca en un disco que ya no está (D:) haría fallar a Join-Path.
            $apps = [System.IO.Path]::Combine($library, 'steamapps')
            if (-not [System.IO.Directory]::Exists($apps)) { continue }
            foreach ($file in [System.IO.Directory]::GetFiles($apps, 'appmanifest_*.acf')) {
                $app = ConvertFrom-AfSteamManifest -Text ([System.IO.File]::ReadAllText($file))
                # 228980 son los redistribuibles de Steamworks, no un juego.
                if (-not $app.Name -or $app.AppId -eq '228980') { continue }
                [void]$games.Add([pscustomobject]@{ Name = $app.Name; Path = [System.IO.Path]::Combine($apps, 'common', $app.InstallDir); Bytes = $app.Bytes; Launcher = 'Steam' })
            }
        }
    }
    if ($EpicPath -and [System.IO.Directory]::Exists($EpicPath)) {
        foreach ($file in [System.IO.Directory]::GetFiles($EpicPath, '*.item')) {
            $item = try { [System.IO.File]::ReadAllText($file) | ConvertFrom-Json } catch { $null }
            if (-not $item -or -not $item.DisplayName -or -not $item.InstallLocation) { continue }
            # Epic también guarda aquí Unreal Engine y otras herramientas.
            if ($item.AppCategories -and @($item.AppCategories) -notcontains 'games') { continue }
            [void]$games.Add([pscustomobject]@{ Name = [string]$item.DisplayName; Path = [string]$item.InstallLocation; Bytes = [long]$item.InstallSize; Launcher = 'Epic' })
        }
    }
    @($games)
}

# Discos fijos por letra: tipo (HDD, SSD o Unspecified) y espacio libre.
function Get-AfDriveKinds {
    $media = @{}
    try { foreach ($disk in @(Get-PhysicalDisk -ErrorAction Stop)) { $media[[string]$disk.DeviceId] = [string]$disk.MediaType } } catch { }
    $drives = @{}
    foreach ($volume in @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' -OperationTimeoutSec 15 -ErrorAction SilentlyContinue)) {
        $letter = ([string]$volume.DeviceID).TrimEnd(':').ToUpperInvariant()
        $type = try { $media[[string](Get-Partition -DriveLetter $letter -ErrorAction Stop | Select-Object -First 1).DiskNumber] } catch { $null }
        $drives[$letter] = [pscustomobject]@{ MediaType = $type; FreeBytes = [long]$volume.FreeSpace }
    }
    $drives
}

# Nombres de Programas instalados (sin los componentes del sistema), de la máquina y del usuario.
function Get-AfInstalledPrograms {
    param($User, [string[]]$Roots)
    if (-not $Roots) {
        $Roots = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
            (Resolve-AfRegistryPath -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall' -User $User)
        )
    }
    $names = foreach ($root in $Roots) {
        foreach ($key in @(Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue)) {
            $name = $key.GetValue('DisplayName')
            if ($name -and $key.GetValue('SystemComponent') -ne 1) { ([string]$name).Trim() }
        }
    }
    @($names | Select-Object -Unique)
}
