# Ayudas para vigilar las traducciones (las usan Translations.Tests y las pruebas de interfaz en inglés).
# Requiere src\Load.ps1 cargado antes.
$script:AfSrcRoot = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'src'
$script:AfSpanishPattern = '(?i)(\b(de|del|la|las|el|los|se|no|que|con|para|por|una|un|en|y|al|a|abre|entra|elige|busca|descarga|instala|reinicia|activa|apaga|revisa|cambia|usa|conecta|cierra|marca|deja|pantalla|ahorro|medio|bajo|principal|sin|hay|cada|nada|ninguna|desde|hasta|como|pero|o|son|ya|muy|tiene|mano|antes|cuando|si|lo|le|sus|su|esta|este|otra|otro)\b|[áéíóúñ¿¡])'

function Get-AfSourceFiles {
    Get-ChildItem $script:AfSrcRoot -Recurse -Filter *.ps1 | Where-Object { $_.Name -ne 'Strings.en.ps1' }
}

function Get-AfAst([string]$Path) {
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
}

function Test-AfAstInside($Node, [scriptblock]$Match) {
    $parent = $Node.Parent
    while ($parent) {
        if (& $Match $parent) { return $true }
        $parent = $parent.Parent
    }
    $false
}

# Literales que el código pasa a T (o Get-AfText).
function Get-AfTranslatedLiterals {
    foreach ($file in Get-AfSourceFiles) {
        $ast = Get-AfAst $file.FullName
        $calls = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -in 'T', 'Get-AfText' }, $true)
        foreach ($call in $calls) {
            $argument = @($call.CommandElements)[1]
            if ($argument -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                [pscustomobject]@{ File = $file.Name; Line = $argument.Extent.StartLineNumber; Text = $argument.Value }
            }
        }
    }
}

# Textos en español que no pasan por T. Fuera quedan el registro de actividad, los here-strings de XAML y los mensajes para quien programa (Test-AfCheckDefinition y Get-AfCatalog).
function Get-AfUntranslated {
    param([string[]]$Files, [hashtable]$Allowed = @{})
    foreach ($path in $Files) {
        $ast = Get-AfAst $path
        $strings = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -or $n -is [System.Management.Automation.Language.ExpandableStringExpressionAst] }, $true)
        foreach ($node in $strings) {
            $text = [string]$node.Value
            if ($text -notmatch ' ' -or $text -notmatch $script:AfSpanishPattern) { continue }
            if ($node -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $node.StringConstantType -in 'BareWord', 'SingleQuotedHereString', 'DoubleQuotedHereString') { continue }
            if (Test-AfAstInside $node { param($p) $p -is [System.Management.Automation.Language.CommandAst] -and $p.GetCommandName() -in 'T', 'Get-AfText', 'Write-AfLog' }) { continue }
            if (Test-AfAstInside $node { param($p) $p -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $p.Name -in 'Get-AfWindowXaml', 'Get-AfThemeXaml', 'Test-AfCheckDefinition', 'Get-AfCatalog', 'Get-AfIconData' }) { continue }
            # Operando de una comparación o de un -match: es un dato, no un texto visible.
            if ($node.Parent -is [System.Management.Automation.Language.BinaryExpressionAst] -and $node.Parent.Operator.ToString() -match '^[IC](eq|ne|like|notlike|match|notmatch|in|notin|contains|notcontains|replace|split)$') { continue }
            if ($Allowed.ContainsKey($text)) { continue }
            [pscustomobject]@{ File = Split-Path $path -Leaf; Line = $node.Extent.StartLineNumber; Text = $text }
        }
    }
}

function Get-AfWordSet([string[]]$Texts) {
    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($text in $Texts) { foreach ($word in [regex]::Matches([string]$text, '\p{L}{3,}')) { [void]$set.Add($word.Value) } }
    , $set
}

# Vocabularios: las palabras de los textos del código (español) y las de las traducciones (inglés).
function Initialize-AfVocabulary {
    param([string[]]$ExtraEnglish = @())
    # Español: las claves de la tabla y los textos del código que se ven en español (no los nombres en inglés, como "Turbo").
    $spanish = @($script:AfStringsEn.Keys) + @(foreach ($file in Get-AfSourceFiles) {
            $ast = Get-AfAst $file.FullName
            $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $n.StringConstantType -ne 'BareWord' }, $true) |
                ForEach-Object { $_.Value } | Where-Object { $_ -notmatch '^https?://' -and $_ -match $script:AfSpanishPattern }
        })
    $script:AfSpanishWords = Get-AfWordSet @($spanish)
    $script:AfEnglishWords = Get-AfWordSet (@($script:AfStringsEn.Values) + $ExtraEnglish)
}

# Lo que, en un texto mostrado en inglés, delata español: letras propias o palabras que solo aparecen en los textos en español.
function Get-AfSpanishLeftovers([string]$Text) {
    if (-not $Text) { return }
    # Las direcciones de las fuentes no son texto de Afina.
    $Text = [regex]::Replace($Text, 'https?://\S+', '')
    if ($Text -match '[áéíóúñ¿¡]') { $Text; return }
    foreach ($word in [regex]::Matches($Text, '\p{L}{3,}')) {
        if ($script:AfSpanishWords.Contains($word.Value) -and -not $script:AfEnglishWords.Contains($word.Value)) { $Text; return }
    }
}
