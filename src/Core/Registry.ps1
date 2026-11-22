function Resolve-AfRegistryPath {
    param([Parameter(Mandatory)][string]$Path, $User)
    if ($User -and -not $User.IsSameAsProcess -and $Path -match '^HKCU:\\?(.*)$') {
        return ($User.HkcuRoot + '\' + $Matches[1]).TrimEnd('\')
    }
    $Path
}

function Get-AfRegistryValue {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Name, $User)
    $resolved = Resolve-AfRegistryPath -Path $Path -User $User
    try {
        (Get-ItemProperty -LiteralPath $resolved -Name $Name -ErrorAction Stop).$Name
    } catch {
        $null
    }
}

# Lee una lista de 'Ruta|Nombre' y devuelve un hashtable con la misma clave (ruta sin resolver).
function Get-AfRegistrySnapshot {
    param([string[]]$Reads = @(), $User)
    $snapshot = @{}
    foreach ($read in ($Reads | Select-Object -Unique)) {
        $parts = $read -split '\|', 2
        $snapshot[$read] = Get-AfRegistryValue -Path $parts[0] -Name $parts[1] -User $User
    }
    $snapshot
}
