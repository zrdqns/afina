function Get-AfRegistryState {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Name, $User)
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
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('DWord', 'QWord', 'String', 'ExpandString', 'MultiString', 'Binary')][string]$Type,
        [Parameter(Mandatory)][AllowEmptyString()][AllowEmptyCollection()]$Value
    )
    $before = Get-AfRegistryState -Path $Path -Name $Name -User $Tx.User
    $target = ConvertTo-AfRegistryData -Type $Type -Value $Value
    if ($before.Exists -and $before.Type -eq $Type -and (ConvertTo-AfComparable $before.Value) -eq (ConvertTo-AfComparable $target)) { return $false }
    $resolved = Resolve-AfRegistryPath -Path $Path -User $Tx.User
    try {
        if (-not $before.KeyExists) { New-Item -Path $resolved -Force -ErrorAction Stop | Out-Null }
        New-ItemProperty -LiteralPath $resolved -Name $Name -PropertyType $Type -Value $target -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-AfLog -Level Warn -Message "Registro $resolved\$Name`: $($_.Exception.Message)"
        if (-not $before.KeyExists) { Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue }
        throw (New-AfApplyError -Reason (T 'Windows no dejó escribir en el registro'))
    }
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'RegistryValue'; Path = $Path; Name = $Name; KeyExisted = $before.KeyExists
        Previous = [pscustomobject]@{ Exists = $before.Exists; Type = $before.Type; Value = $before.Value }
        New = [pscustomobject]@{ Exists = $true; Type = $Type; Value = $target }
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
            New-ItemProperty -LiteralPath $resolved -Name $Record.Name -PropertyType $previous.Type -Value (ConvertTo-AfRegistryData -Type $previous.Type -Value $previous.Value) -Force -ErrorAction Stop | Out-Null
            return
        }
        $state = Get-AfRegistryState -Path $Record.Path -Name $Record.Name -User $User
        if ($state.Exists) { Remove-ItemProperty -LiteralPath $resolved -Name $Record.Name -Force -ErrorAction Stop }
        if (-not $Record.KeyExisted -and $state.KeyExists) {
            $key = Get-Item -LiteralPath $resolved -ErrorAction Stop
            $empty = $key.SubKeyCount -eq 0 -and $key.ValueCount -eq 0
            $key.Close()
            if ($empty) { Remove-Item -LiteralPath $resolved -Force -ErrorAction Stop }
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
