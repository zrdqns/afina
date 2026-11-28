function Get-AfRegistryState {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][AllowEmptyString()][string]$Name, $User)
    $resolved = Resolve-AfRegistryPath -Path $Path -User $User
    $key = $null
    try { $key = Get-Item -LiteralPath $resolved -ErrorAction Stop } catch { }
    if (-not $key) { return [pscustomobject]@{ KeyExists = $false; Exists = $false; Type = $null; Value = $null } }
    try {
        if (@($key.GetValueNames()) -notcontains $Name) { return [pscustomobject]@{ KeyExists = $true; Exists = $false; Type = $null; Value = $null } }
        $value = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        [pscustomobject]@{ KeyExists = $true; Exists = $true; Type = [string]$key.GetValueKind($Name); Value = $value }
    } finally {
        $key.Close()
    }
}

# Convierte un valor (también uno leído de JSON) al tipo .NET que espera el registro.
function ConvertTo-AfRegistryData {
    param([string]$Type, $Value)
    switch ($Type) {
        'DWord' { [int]$Value }
        'QWord' { [long]$Value }
        'Binary' { , [byte[]]@($Value) }
        'MultiString' { , [string[]]@($Value) }
        default { [string]$Value }
    }
}

function Set-AfRegistryValue {
    param(
        [Parameter(Mandatory)]$Tx,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Name,
        [Parameter(Mandatory)][ValidateSet('DWord', 'QWord', 'String', 'ExpandString', 'MultiString', 'Binary')][string]$Type,
        [Parameter(Mandatory)][AllowEmptyString()][AllowEmptyCollection()]$Value
    )
    $before = Get-AfRegistryState -Path $Path -Name $Name -User $Tx.User
    $target = ConvertTo-AfRegistryData -Type $Type -Value $Value
    if ($before.Exists -and $before.Type -eq $Type -and (ConvertTo-AfComparable $before.Value) -eq (ConvertTo-AfComparable $target)) { return $false }
    $resolved = Resolve-AfRegistryPath -Path $Path -User $Tx.User
    # Claves que no existían, de la más profunda a la más alta, tal como llegaron (sin resolver).
    $created = @()
    $cursor = $Path
    while ($cursor -and -not (Test-Path -LiteralPath (Resolve-AfRegistryPath -Path $cursor -User $Tx.User))) {
        $created += $cursor
        $cursor = Split-Path -Path $cursor -Parent
    }
    try {
        if ($created.Count) { New-Item -Path $resolved -Force -ErrorAction Stop | Out-Null }
        if ($Name -eq '') {
            if ($Type -ne 'String') { throw 'The default value only supports String' }
            Set-Item -LiteralPath $resolved -Value $target -ErrorAction Stop
        } else {
            New-ItemProperty -LiteralPath $resolved -Name $Name -PropertyType $Type -Value $target -Force -ErrorAction Stop | Out-Null
        }
    } catch {
        Write-AfLog -Level Warn -Message "Registro $resolved\$Name`: $($_.Exception.Message)"
        if ($created.Count) { Remove-Item -LiteralPath (Resolve-AfRegistryPath -Path $created[-1] -User $Tx.User) -Recurse -Force -ErrorAction SilentlyContinue }
        throw (New-AfApplyError -Reason (T 'Windows no dejó escribir en el registro'))
    }
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'RegistryValue'; Path = $Path; Name = $Name; KeyExisted = $before.KeyExists; CreatedKeys = $created
        Previous = [pscustomobject]@{ Exists = $before.Exists; Type = $before.Type; Value = $before.Value }
        New = [pscustomobject]@{ Exists = $true; Type = $Type; Value = $target }
    }
    $true
}

# Borra un valor que dejó otro programa (p. ej. una directiva). Deshacer lo vuelve a escribir.
function Remove-AfRegistryValue {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Name)
    $before = Get-AfRegistryState -Path $Path -Name $Name -User $Tx.User
    if (-not $before.Exists) { return $false }
    $resolved = Resolve-AfRegistryPath -Path $Path -User $Tx.User
    try {
        Remove-ItemProperty -LiteralPath $resolved -Name $Name -Force -ErrorAction Stop
    } catch {
        Write-AfLog -Level Warn -Message "Registro $resolved\$Name`: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'Windows no dejó escribir en el registro'))
    }
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'RegistryValue'; Path = $Path; Name = $Name; KeyExisted = $true; CreatedKeys = @()
        Previous = [pscustomobject]@{ Exists = $true; Type = $before.Type; Value = $before.Value }
        New = [pscustomobject]@{ Exists = $false; Type = $null; Value = $null }
    }
    $true
}

function Restore-AfRegistryValue {
    param([Parameter(Mandatory)]$Record, $User)
    $resolved = Resolve-AfRegistryPath -Path $Record.Path -User $User
    $previous = $Record.Previous
    try {
        if ($previous.Exists) {
            if (-not (Test-Path -LiteralPath $resolved)) { New-Item -Path $resolved -Force -ErrorAction Stop | Out-Null }
            if ($Record.Name -eq '') {
                Set-Item -LiteralPath $resolved -Value ([string]$previous.Value) -ErrorAction Stop
            } else {
                New-ItemProperty -LiteralPath $resolved -Name $Record.Name -PropertyType $previous.Type -Value (ConvertTo-AfRegistryData -Type $previous.Type -Value $previous.Value) -Force -ErrorAction Stop | Out-Null
            }
            return
        }
        $state = Get-AfRegistryState -Path $Record.Path -Name $Record.Name -User $User
        if ($state.Exists) {
            if ($Record.Name -eq '') {
                # Remove-ItemProperty no acepta el nombre vacío ni '(default)' en 5.1: se borra por .NET.
                $writable = (Get-Item -LiteralPath $resolved -ErrorAction Stop).OpenSubKey('', $true)
                try { $writable.DeleteValue('') } finally { $writable.Close() }
            } else {
                Remove-ItemProperty -LiteralPath $resolved -Name $Record.Name -Force -ErrorAction Stop
            }
        }
        # Los registros viejos no tienen CreatedKeys (y en JSON una sola clave vuelve como texto): se usa KeyExisted.
        $created = @($Record.CreatedKeys | Where-Object { $_ })
        if (-not $created.Count -and -not $Record.KeyExisted) { $created = @($Record.Path) }
        foreach ($createdPath in $created) {
            $createdResolved = Resolve-AfRegistryPath -Path $createdPath -User $User
            if (-not (Test-Path -LiteralPath $createdResolved)) { continue }
            $key = Get-Item -LiteralPath $createdResolved -ErrorAction Stop
            $empty = $key.SubKeyCount -eq 0 -and $key.ValueCount -eq 0
            $key.Close()
            if (-not $empty) { break }
            Remove-Item -LiteralPath $createdResolved -Force -ErrorAction Stop
        }
    } catch {
        Write-AfLog -Level Warn -Message "Deshacer registro $resolved\$($Record.Name): $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'Windows no dejó escribir en el registro'))
    }
}

function Get-AfRegistryValueState {
    param([Parameter(Mandatory)]$Record, $User)
    $state = Get-AfRegistryState -Path $Record.Path -Name $Record.Name -User $User
    [pscustomobject]@{ Exists = $state.Exists; Type = $state.Type; Value = $state.Value }
}
