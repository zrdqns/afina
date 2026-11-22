$script:AfPagingPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
$script:AfPolicyDoPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
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

function Get-AfDeliveryOptimizationMode {
    [string](Get-DOConfig).DownloadMode
}

# Envoltorio: el cmdlet usa un enum que Pester no puede copiar al sustituirlo.
function Invoke-AfSetDeliveryOptimizationMode {
    param([Parameter(Mandatory)][string]$Mode)
    Set-DODownloadMode -downloadMode $Mode
}

function Set-AfDeliveryOptimizationMode {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][ValidateSet('Lan', 'Internet', 'CdnOnly')][string]$Mode)
    $previous = Get-AfDeliveryOptimizationMode
    if ($previous -eq $Mode) { return $false }
    Invoke-AfSetDeliveryOptimizationMode -Mode $Mode
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'DeliveryOptimizationMode'; Previous = $previous; New = $Mode }
    if ((Get-AfDeliveryOptimizationMode) -ne $Mode) { throw (New-AfApplyError -Reason (T 'Windows no aceptó el modo de Optimización de entrega')) }
    $true
}

function Restore-AfDeliveryOptimizationMode {
    param([Parameter(Mandatory)]$Record, $User)
    if ($null -ne (Get-AfRegistryValue -Path $script:AfPolicyDoPath -Name 'DODownloadMode')) {
        throw (New-AfApplyError -Reason (T 'una directiva fija el modo de Optimización de entrega; quítala para deshacerlo'))
    }
    Invoke-AfSetDeliveryOptimizationMode -Mode $Record.Previous
}

function Get-AfDeliveryOptimizationModeState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfDeliveryOptimizationMode
}

# --- Archivo de paginación automático ---

function Get-AfPagefileAutomatic {
    [bool](Get-CimInstance -ClassName Win32_ComputerSystem).AutomaticManagedPagefile
}

function Set-AfPagefileAutomatic {
    param([Parameter(Mandatory)][bool]$Value)
    Get-CimInstance -ClassName Win32_ComputerSystem | Set-CimInstance -Property @{ AutomaticManagedPagefile = $Value }
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
    if ($SizePercent -ne 0 -and $SizePercent -ne 40) { return 'Custom' }
    if ($RamBytes -gt 0 -and $FileBytes -ge ($RamBytes * 0.3)) { return 'Full' }
    'Reduced'
}

function Get-AfHibernationInfo {
    $enabled = [bool](Get-AfRegistryValue -Path $script:AfPowerPath -Name 'HibernateEnabled')
    $percent = [int](Get-AfRegistryValue -Path $script:AfPowerPath -Name 'HiberFileSizePercent')
    $file = Get-Item -LiteralPath (Join-Path $env:SystemDrive 'hiberfil.sys') -Force -ErrorAction SilentlyContinue
    $bytes = if ($file) { [long]$file.Length } else { [long]0 }
    $ram = [long](Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory
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
