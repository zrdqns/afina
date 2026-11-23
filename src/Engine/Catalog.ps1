function Get-AfCategories {
    @(
        [pscustomobject]@{ Id = 'energy'; Name = (T 'Energía'); Icon = 'lightning' }
        [pscustomobject]@{ Id = 'gaming'; Name = (T 'Juegos y gráficos'); Icon = 'game-controller' }
        [pscustomobject]@{ Id = 'network'; Name = (T 'Red'); Icon = 'wifi-high' }
        [pscustomobject]@{ Id = 'startup'; Name = (T 'Inicio'); Icon = 'rocket-launch' }
        [pscustomobject]@{ Id = 'storage'; Name = (T 'Almacenamiento'); Icon = 'hard-drives' }
        [pscustomobject]@{ Id = 'security'; Name = (T 'Seguridad'); Icon = 'shield-check' }
        [pscustomobject]@{ Id = 'hardware'; Name = (T 'Diagnóstico'); Icon = 'wrench' }
        [pscustomobject]@{ Id = 'optional'; Name = (T 'Opcional'); Icon = 'sliders-horizontal' }
        [pscustomobject]@{ Id = 'windows'; Name = (T 'Ajustes de Windows'); Icon = 'windows-logo' }
    )
}

function New-AfDetection {
    param(
        [Parameter(Mandatory)][ValidateSet('Ok', 'Improvable', 'Manual', 'Info', 'NotApplicable', 'Error')][string]$State,
        [string]$Title,
        [string]$Current,
        [string]$Target,
        [string]$Note,
        [string]$What,
        [string[]]$Steps = @(),
        [hashtable]$Data = @{},
        $Preselect = $null
    )
    [pscustomobject]@{ State = $State; Title = $Title; Current = $Current; Target = $Target; Note = $Note; What = $What; Steps = $Steps; Data = $Data; Preselect = $Preselect }
}

$script:AfRequiredCheckKeys = 'Id', 'Category', 'Title', 'Why', 'Impact', 'Risk', 'Kind', 'Preselect', 'NeedsReboot', 'Source', 'Undo', 'Detect'

function Test-AfCheckDefinition {
    param([Parameter(Mandatory)][hashtable]$Check)
    $errors = @()
    foreach ($key in $script:AfRequiredCheckKeys) {
        $value = $Check[$key]
        if (-not $Check.ContainsKey($key) -or $null -eq $value -or ($value -is [string] -and -not $value)) { $errors += "Falta $key" }
    }
    if ($Check.Impact -and $Check.Impact -notin 'High', 'Medium', 'Low') { $errors += "Impact inválido: $($Check.Impact)" }
    if ($Check.Risk -and $Check.Risk -notin 'Safe', 'Advanced') { $errors += "Risk inválido: $($Check.Risk)" }
    if ($Check.Kind -and $Check.Kind -notin 'Auto', 'Manual', 'Info') { $errors += "Kind inválido: $($Check.Kind)" }
    if ($Check.Category -and $Check.Category -notin (Get-AfCategories).Id) { $errors += "Category inválida: $($Check.Category)" }
    if ($Check.Detect -and $Check.Detect -isnot [scriptblock]) { $errors += 'Detect debe ser un scriptblock' }
    if ($Check.ContainsKey('AppliesTo') -and $Check.AppliesTo -isnot [scriptblock]) { $errors += 'AppliesTo debe ser un scriptblock' }
    if ($Check.ContainsKey('Apply') -and $Check.Apply -isnot [scriptblock]) { $errors += 'Apply debe ser un scriptblock' }
    foreach ($read in @($Check.Reads)) { if ($read -and $read -notmatch '^HK(LM|CU):\\.+\|.+$') { $errors += "Lectura inválida: $read" } }
    $errors
}

# Una entrada por categoría; cada tarea de revisiones agrega la suya.
function Get-AfCatalogProviders {
    @(
        { Get-AfEnergyChecks }
        { Get-AfGamingChecks }
        { Get-AfNetworkChecks }
        { Get-AfStartupChecks }
        { Get-AfStorageChecks }
        { Get-AfDiagnosticsChecks }
        { Get-AfHardwareChecks }
        { Get-AfSecurityChecks }
        { Get-AfOptionalChecks }
    )
}

function Get-AfCatalog {
    param([scriptblock[]]$Providers)
    if (-not $PSBoundParameters.ContainsKey('Providers')) { $Providers = @(Get-AfCatalogProviders) }
    $catalog = @()
    $ids = @{}
    foreach ($provider in $Providers) {
        foreach ($check in @(& $provider)) {
            if ($ids.ContainsKey($check.Id)) { throw "Id repetido en el catálogo: $($check.Id)" }
            $ids[$check.Id] = $true
            $catalog += $check
        }
    }
    $catalog
}

function Get-AfCatalogReads {
    param([object[]]$Catalog = @())
    @($Catalog | ForEach-Object { if ($_.Reads) { $_.Reads } }) | Select-Object -Unique
}
