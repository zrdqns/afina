$script:AfPagingPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
$script:AfPowerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'

# --- Parámetros del sistema (ratón, animaciones del área de cliente) ---

# Envoltorios del código nativo: las pruebas los sustituyen para no tocar el sistema.
function Get-AfSystemParameterValue {
    param([Parameter(Mandatory)][ValidateSet('Mouse', 'ClientAreaAnimation')][string]$Name)
    if (-not (Initialize-AfNative)) { throw (New-AfApplyError -Reason (T 'Windows no dejó leer ese ajuste')) }
    if ($Name -eq 'Mouse') { , [int[]][Afina.Native]::GetMouseParams() } else { [Afina.Native]::GetClientAreaAnimation() }
}

function Invoke-AfSetSystemParameter {
    param([Parameter(Mandatory)][ValidateSet('Mouse', 'ClientAreaAnimation')][string]$Name, [Parameter(Mandatory)]$Value)
    if (-not (Initialize-AfNative)) { throw (New-AfApplyError -Reason (T 'Windows no aceptó el ajuste')) }
    $ok = if ($Name -eq 'Mouse') {
        $v = [int[]]@($Value)
        [Afina.Native]::SetMouseParams($v[0], $v[1], $v[2])
    } else {
        [Afina.Native]::SetClientAreaAnimation([bool]$Value)
    }
    if (-not $ok) { throw (New-AfApplyError -Reason (T 'Windows no aceptó el ajuste')) }
}

# Avisa al shell y a las ventanas de un cambio de ajustes. Solo corre dentro de Apply (hilo de aplicar, no el de WPF); si falla, el cambio sigue.
function Send-AfShellNotify {
    param([Parameter(Mandatory)][string]$Area)
    try {
        if (-not (Initialize-AfNative)) { throw (T 'El código nativo no está disponible') }
        [Afina.Native]::NotifyShell($Area)
    } catch {
        Write-AfLog -Level Warn -Message "No se pudo avisar al shell ($Area): $($_.Exception.Message)"
    }
}

# Área que hay que avisar al shell tras restaurar un registro; $null si no hace falta.
function Get-AfRecordNotifyArea {
    param([Parameter(Mandatory)]$Record)
    if ($Record.Kind -eq 'RegistryValue' -and $Record.Name -eq 'EnableTransparency' -and [string]$Record.Path -like '*\Themes\Personalize') { return 'ImmersiveColorSet' }
    if ($Record.Kind -eq 'RegistryValue' -and $Record.Name -eq 'HideFileExt' -and [string]$Record.Path -like '*\Explorer\Advanced') { return 'ShellState' }
    $null
}

function ConvertTo-AfSystemParameterValue {
    param([string]$Name, $Value)
    if ($Name -eq 'Mouse') { , [int[]]@($Value) } else { [bool]$Value }
}

# Los parámetros son del usuario de la sesión: con otra cuenta (elevación) no se escriben.
function Set-AfSystemParameter {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][ValidateSet('Mouse', 'ClientAreaAnimation')][string]$Name, [Parameter(Mandatory)]$Value)
    if ($Tx.User -and -not $Tx.User.IsSameAsProcess) { throw (New-AfApplyError -Reason (T 'abre Afina con la cuenta del dueño para este ajuste')) }
    $target = ConvertTo-AfSystemParameterValue -Name $Name -Value $Value
    $previous = Get-AfSystemParameterValue -Name $Name
    if ((ConvertTo-AfComparable $previous) -eq (ConvertTo-AfComparable $target)) { return $false }
    Invoke-AfSetSystemParameter -Name $Name -Value $target
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'SystemParameter'; Name = $Name; Previous = $previous; New = $target }
    if ((ConvertTo-AfComparable (Get-AfSystemParameterValue -Name $Name)) -ne (ConvertTo-AfComparable $target)) {
        throw (New-AfApplyError -Reason (T 'Windows no aceptó el ajuste'))
    }
    $true
}

function Restore-AfSystemParameter {
    param([Parameter(Mandatory)]$Record, $User)
    if ($User -and -not $User.IsSameAsProcess) { throw (New-AfApplyError -Reason (T 'abre Afina con la cuenta del dueño para deshacerlo')) }
    Invoke-AfSetSystemParameter -Name $Record.Name -Value (ConvertTo-AfSystemParameterValue -Name $Record.Name -Value $Record.Previous)
}

function Get-AfSystemParameterState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfSystemParameterValue -Name $Record.Name
}

# --- Optimización de entrega ---

# Solo se lee (inventario): la fila es a mano, Afina no cambia el modo.
function Get-AfDeliveryOptimizationMode {
    [string](Get-DOConfig -ErrorAction Stop).DownloadMode
}

# --- Archivo de paginación automático ---

function Get-AfPagefileAutomatic {
    [bool](Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).AutomaticManagedPagefile
}

function Set-AfPagefileAutomatic {
    param([Parameter(Mandatory)][bool]$Value)
    Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop | Set-CimInstance -Property @{ AutomaticManagedPagefile = $Value } -ErrorAction Stop
}

function Set-AfPagefileAuto {
    param([Parameter(Mandatory)]$Tx)
    if (Get-AfPagefileAutomatic) { return $false }
    $before = Get-AfRegistryState -Path $script:AfPagingPath -Name 'PagingFiles'
    Set-AfPagefileAutomatic -Value $true
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'PagefileAuto'; Path = $script:AfPagingPath; Name = 'PagingFiles'; KeyExisted = $true
        Previous = [pscustomobject]@{ Exists = $before.Exists; Type = $before.Type; Value = $before.Value }
    }
    if (-not (Get-AfPagefileAutomatic)) { throw (New-AfApplyError -Reason (T 'Windows no activó el archivo de paginación automático')) }
    $true
}

function Restore-AfPagefileAuto {
    param([Parameter(Mandatory)]$Record, $User)
    Set-AfPagefileAutomatic -Value $false
    # Si el original ya era el automático (?:\pagefile.sys), el indicador puede seguir activo sin que sea un fallo.
    $wasAutomatic = $Record.Previous.Exists -and ((@($Record.Previous.Value) -join ' ') -match '^\?:\\pagefile\.sys')
    if (-not $wasAutomatic -and (Get-AfPagefileAutomatic)) { throw (New-AfApplyError -Reason (T 'Windows no desactivó el archivo de paginación automático')) }
    # Windows reescribe PagingFiles al cambiar el modo: se vuelve a dejar el valor y el tipo originales.
    Restore-AfRegistryValue -Record $Record -User $User
}

function Get-AfPagefileAutoState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfRegistryValueState -Record $Record -User $User
}

# --- Archivo de hibernación ---

# Completa (Full) ocupa cerca de la RAM; reducida (Reduced), alrededor del 20 %.
function Get-AfHibernationType {
    param([Parameter(Mandatory)][long]$FileBytes, [Parameter(Mandatory)][long]$RamBytes, [Parameter(Mandatory)][int]$SizePercent)
    if ($FileBytes -le 0) { return $null }
    if (@(0, 20, 40) -notcontains $SizePercent) { return 'Custom' }
    if ($RamBytes -gt 0 -and $FileBytes -ge ($RamBytes * 0.3)) { return 'Full' }
    'Reduced'
}

function Get-AfHibernationInfo {
    $enabled = [bool](Get-AfRegistryValue -Path $script:AfPowerPath -Name 'HibernateEnabled')
    $percent = [int](Get-AfRegistryValue -Path $script:AfPowerPath -Name 'HiberFileSizePercent')
    $file = Get-Item -LiteralPath (Join-Path $env:SystemDrive 'hiberfil.sys') -Force -ErrorAction SilentlyContinue
    $bytes = if ($file) { [long]$file.Length } else { [long]0 }
    $ram = [long](Get-CimInstance -ClassName Win32_ComputerSystem -OperationTimeoutSec 15 -ErrorAction Stop).TotalPhysicalMemory
    @{ Enabled = $enabled; FileBytes = $bytes; RamBytes = $ram; Type = (Get-AfHibernationType -FileBytes $bytes -RamBytes $ram -SizePercent $percent) }
}

function Set-AfHibernationType {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][ValidateSet('Reduced', 'Full')][string]$Type)
    $info = Get-AfHibernationInfo
    if ($info.Type -eq $Type) { return $false }
    if (-not $info.Enabled -or -not $info.Type) { throw (New-AfApplyError -Reason (T 'la hibernación está desactivada')) }
    if ($info.Type -eq 'Custom') { throw (New-AfApplyError -Reason (T 'la hibernación tiene un tamaño personalizado')) }
    Invoke-AfPowercfg -Arguments ('/h /type {0}' -f $Type.ToLowerInvariant()) | Out-Null
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'HibernationType'; Previous = $info.Type; New = $Type }
    if ((Get-AfHibernationInfo).Type -ne $Type) { throw (New-AfApplyError -Reason (T 'Windows no aceptó el tipo de hibernación')) }
    $true
}

function Restore-AfHibernationType {
    param([Parameter(Mandatory)]$Record, $User)
    try {
        Invoke-AfPowercfg -Arguments ('/h /type {0}' -f ([string]$Record.Previous).ToLowerInvariant()) | Out-Null
    } catch {
        Write-AfLog -Level Warn -Message "Hibernación: $($_.Exception.Message)"
        if ($Record.Previous -eq 'Full') { throw (New-AfApplyError -Reason (T 'falta espacio en el disco para volver a la hibernación completa')) }
        throw
    }
}

function Get-AfHibernationTypeState {
    param([Parameter(Mandatory)]$Record, $User)
    (Get-AfHibernationInfo).Type
}

# --- Inicio de un servicio ---
# Lo cambia sc.exe: el administrador de servicios respeta los permisos de cada uno (la clave de DPS solo deja leer a los administradores).

function ConvertTo-AfServiceMode {
    param([int]$Start, [bool]$Delayed)
    switch ($Start) { 2 { if ($Delayed) { 'delayed-auto' } else { 'auto' } } 3 { 'demand' } 4 { 'disabled' } default { $null } }
}

# El inicio diferido solo cuenta en los automáticos. $null si el servicio no existe.
function Get-AfServiceStart {
    param([Parameter(Mandatory)][string]$Name)
    $key = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    $start = Get-AfRegistryValue -Path $key -Name 'Start'
    if ($null -eq $start) { return $null }
    [pscustomobject]@{ Start = [int]$start; Delayed = ([int]$start -eq 2 -and (Get-AfRegistryValue -Path $key -Name 'DelayedAutostart') -eq 1) }
}

function Invoke-AfServiceStart {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Mode)
    $result = Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\sc.exe') -Arguments ('config "{0}" start= {1}' -f $Name, $Mode) -TimeoutMs 15000
    if ($result.TimedOut -or $result.ExitCode -ne 0) {
        Write-AfLog -Level Warn -Message ('sc config {0} {1}: código {2}. {3}' -f $Name, $Mode, $result.ExitCode, $result.Output)
        throw (New-AfApplyError -Reason (T 'Windows no dejó cambiar el servicio'))
    }
}

function Set-AfServiceStart {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Mode)
    $previous = Get-AfServiceStart -Name $Name
    if (-not $previous -or (ConvertTo-AfServiceMode -Start $previous.Start -Delayed $previous.Delayed) -eq $Mode) { return $false }
    Invoke-AfServiceStart -Name $Name -Mode $Mode
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'ServiceStart'; Name = $Name; Previous = $previous; New = $Mode }
    $true
}

function Restore-AfServiceStart {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfServiceStart -Name $Record.Name -Mode (ConvertTo-AfServiceMode -Start ([int]$Record.Previous.Start) -Delayed ([bool]$Record.Previous.Delayed))
}

function Get-AfServiceStartState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfServiceStart -Name $Record.Name
}
