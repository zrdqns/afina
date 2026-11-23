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
