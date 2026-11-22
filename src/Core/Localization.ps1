# Idioma de lo que se ve. El español es la base: T devuelve el mismo texto o, en inglés, su traducción.
# El registro de actividad (Write-AfLog) queda en español: no pasa por aquí.
$script:AfLanguage = 'es'

function Set-AfLanguage {
    param([Parameter(Mandatory)][ValidateSet('es', 'en')][string]$Language)
    $script:AfLanguage = $Language.ToLowerInvariant()
}

function Get-AfLanguage { $script:AfLanguage }

function Get-AfText {
    param([string]$Text)
    if ($script:AfLanguage -eq 'en' -and $Text -and $script:AfStringsEn.ContainsKey($Text)) { return $script:AfStringsEn[$Text] }
    $Text
}
Set-Alias -Name T -Value Get-AfText

# Automático (o un valor desconocido): el idioma de pantalla de Windows, español o, si es otro, inglés.
function Resolve-AfLanguage {
    param([string]$Setting)
    if ($Setting -in 'es', 'en') { return $Setting.ToLowerInvariant() }
    if ((Get-UICulture).TwoLetterISOLanguageName -eq 'es') { 'es' } else { 'en' }
}

# Al abrir: el idioma guardado en la configuración (Automático si no hay o no se conoce).
function Set-AfStartLanguage {
    param([hashtable]$Config)
    Set-AfLanguage -Language (Resolve-AfLanguage -Setting $(if ($Config) { $Config.Language } else { $null }))
}

# La hora como se escribe en el idioma: 16:42 o 4:42 PM.
function Format-AfTime {
    param([Parameter(Mandatory)][datetime]$Date)
    if ($script:AfLanguage -eq 'en') { $Date.ToString('h:mm tt', (Get-AfCulture)) } else { $Date.ToString('HH:mm') }
}

# Formato de fechas y números del idioma actual.
function Get-AfCulture {
    [System.Globalization.CultureInfo]::GetCultureInfo($(if ($script:AfLanguage -eq 'en') { 'en-US' } else { 'es-ES' }))
}
