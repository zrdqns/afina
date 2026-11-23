# Lecturas extra del inventario (solo lectura): paginación, entrega, Edge y efectos.
# Ninguna lanza hacia las revisiones: el inventario anota las partes que fallan.

function Test-AfLowDisk {
    param($Storage)
    if (-not $Storage) { return $false }
    $free = [double]$Storage.FreeGB
    $size = [double]$Storage.SizeGB
    $free -lt 20 -or ($size -gt 0 -and ($free / $size) -lt 0.15)
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

function Get-AfDeliveryOptimizationInfo {
    try {
        @{ Available = $true; Mode = (Get-AfDeliveryOptimizationMode) }
    } catch {
        @{ Available = $false; Mode = $null }
    }
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
