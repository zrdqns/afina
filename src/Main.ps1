param(
    [switch]$Scan,
    [switch]$Json,
    [string]$Snapshot,
    [switch]$NoElevate
)
$ErrorActionPreference = 'Stop'

# Antes de cargar nada: con PowerShell limitado (Smart App Control o App Control) el código de Afina no llega a cargar.
# Todavía no hay T ni configuración: el aviso sale en el idioma de Windows.
if ([string]$ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    if ((Get-UICulture).TwoLetterISOLanguageName -eq 'es') { Write-Host 'Afina no puede correr aquí: PowerShell está limitado por Smart App Control o App Control.' }
    else { Write-Host "Afina can't run here: PowerShell is restricted by Smart App Control or App Control." }
    # Con "irm … | iex", exit cerraría la ventana antes de leer el aviso.
    if ($PSCommandPath) { exit 2 } else { return }
}

# <afina:code>
. (Join-Path $PSScriptRoot 'Load.ps1')
# </afina:code>

$scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $null }
$configPath = Get-AfConfigPath -ScriptRoot $(if ($scriptPath) { Split-Path $scriptPath -Parent } else { $null })
$config = Get-AfConfig -Path $configPath
# Los avisos de la consola, -Scan y la ventana salen en el idioma guardado.
Set-AfStartLanguage -Config $config

$extra = @()
if ($Scan) { $extra += '-Scan' }
if ($Json) { $extra += '-Json' }
if ($Snapshot) { $extra += @('-Snapshot', ('"{0}"' -f $Snapshot)) }
$needsSta = [System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA' -and -not $Scan
if ((-not $NoElevate -and -not (Test-AfAdmin)) -or $needsSta) {
    # Abierto con "irm … | iex" no se relanza: un PowerShell elevado que descarga y ejecuta código es lo que Defender bloquea como malware.
    if (-not $scriptPath) {
        Write-Host (T 'Afina necesita permisos de administrador. Abre PowerShell como administrador (clic derecho en Inicio) y vuelve a pegar la línea.')
        return
    }
    Restart-AfElevated -Arguments (@('-STA') + (Get-AfRelaunchArguments -ScriptPath $scriptPath -Extra $extra))
    exit
}

[void](Start-AfLog -Directory (Join-Path $env:ProgramData 'Afina\registros'))
Write-AfLog -Level Info -Message ('Afina {0} en {1}' -f (Get-AfVersion), $env:COMPUTERNAME)

if ($Scan) {
    $catalog = @(Get-AfCatalog)
    $inventory = Get-AfInventory -Reads (Get-AfCatalogReads -Catalog $catalog)
    $results = @($catalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $inventory })
    $rows = @($results | ForEach-Object {
            [pscustomobject]@{
                Id = $_.Check.Id
                Category = $_.Check.Category
                State = $_.Detection.State
                Title = if ($_.Detection.Title) { $_.Detection.Title } else { $_.Check.Title }
                Current = $_.Detection.Current
                Target = $_.Detection.Target
                Note = $_.Detection.Note
                Preselected = $_.Preselected
            }
        })
    if ($Json) {
        [pscustomobject]@{ Version = Get-AfVersion; Score = Get-AfScore -Results $results; Summary = Get-AfSummary -Results $results; InventoryErrors = $inventory.Errors; Results = $rows } | ConvertTo-Json -Depth 5
    } else {
        $rows | Format-Table State, Id, Title, Current, Target -AutoSize
    }
    exit 0
}

Show-AfApp -Config $config -ConfigPath $configPath -Snapshot $Snapshot
# Sale en el acto: la búsqueda de Windows Update en segundo plano puede tardar minutos y no se puede cortar.
[Environment]::Exit(0)
