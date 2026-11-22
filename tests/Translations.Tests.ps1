BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\Language.ps1"
    # Todo src pasa por la guarda.
    $script:converted = @(Get-ChildItem $script:AfSrcRoot -Recurse -Filter *.ps1 | ForEach-Object { $_.FullName.Substring($script:AfSrcRoot.TrimEnd('\').Length + 1) })
    # Textos en español que pueden quedar sin T, con su motivo.
    $script:allowed = @{
        'Afina no puede correr aquí: PowerShell está limitado por Smart App Control o App Control.' = 'Main.ps1 lo muestra antes de cargar el código (todavía no hay T); al lado va el inglés.'
    }
}

Describe 'Traducciones' {
    It 'toda cadena que se pasa a T tiene traducción' {
        $missing = @(Get-AfTranslatedLiterals | Where-Object { -not $script:AfStringsEn.ContainsKey($_.Text) } | ForEach-Object { '{0}:{1} {2}' -f $_.File, $_.Line, $_.Text })
        $missing | Should -BeNullOrEmpty
    }

    It 'cada traducción conserva sus marcadores' {
        $bad = foreach ($key in @($script:AfStringsEn.Keys)) {
            $a = @([regex]::Matches($key, '\{\d+[^}]*\}') | ForEach-Object { $_.Value } | Sort-Object -Unique) -join ' '
            $b = @([regex]::Matches($script:AfStringsEn[$key], '\{\d+[^}]*\}') | ForEach-Object { $_.Value } | Sort-Object -Unique) -join ' '
            if ($a -ne $b) { '{0} → {1}' -f $key, $script:AfStringsEn[$key] }
        }
        @($bad) | Should -BeNullOrEmpty
    }

    It 'ninguna traducción tiene letras del español' {
        @($script:AfStringsEn.Values | Where-Object { $_ -match '[áéíóúñ¿¡]' }) | Should -BeNullOrEmpty
    }

    It 'los textos en español de los archivos convertidos pasan por T' {
        $files = @($script:converted | ForEach-Object { Join-Path $script:AfSrcRoot $_ })
        $left = @(Get-AfUntranslated -Files $files -Allowed $script:allowed | ForEach-Object { '{0}:{1} {2}' -f $_.File, $_.Line, $_.Text })
        $left | Should -BeNullOrEmpty
    }
}

Describe 'Revisiones en inglés' {
    BeforeAll {
        . "$PSScriptRoot\Helpers\FakeInventory.ps1"
        . "$PSScriptRoot\Helpers\Profiles.ps1"
        Initialize-AfVocabulary
        # Lo que viene de afuera (nombres de gráficas, apps, equipos) no se traduce: se quita antes de mirar.
        function Get-AfExternalNames($Inventory) {
            @(@($Inventory.Gpus | ForEach-Object { $_.Name }) + @($Inventory.Startup | ForEach-Object { $_.Name }) + @($Inventory.Security.Antivirus | ForEach-Object { $_.Name }) +
                @($Inventory.Apps.Promo | ForEach-Object { $_.Name }) + @($Inventory.VendorTools) + @($Inventory.Network | ForEach-Object { $_.Description }) +
                @($Inventory.Security.Defender.Threats | ForEach-Object { $_.Name; $_.Path }) | Where-Object { $_ })
        }
    }
    AfterEach { Set-AfLanguage -Language es }

    It 'en inglés, ninguna revisión muestra español' {
        Set-AfLanguage -Language en
        $inventories = @(@((Get-AfProfileInventories).Values) + @((New-AfFakeInventory), (New-AfDetunedInventory)))
        $catalog = @(Get-AfCatalog)
        $left = foreach ($inventory in $inventories) {
            $external = Get-AfExternalNames $inventory
            foreach ($check in $catalog) {
                $detection = (Invoke-AfCheck -Check $check -Inventory $inventory).Detection
                $texts = @($check.Title, $check.Why, $check.Source, $check.Undo)
                # Las notas de Error traen el texto de la excepción de Windows, que no es de Afina.
                if ($detection.State -ne 'Error') { $texts += @($detection.Title, $detection.Current, $detection.Target, $detection.Note, $detection.What) + @($detection.Steps) }
                if ($detection.Data -and $detection.Data.Choices) { $texts += @($detection.Data.Choices | ForEach-Object { $_.Label }) + @($detection.Data.ChoicesLabel) }
                foreach ($text in $texts) {
                    $clean = [string]$text
                    foreach ($name in $external) { $clean = $clean.Replace([string]$name, '') }
                    Get-AfSpanishLeftovers $clean | ForEach-Object { '{0}: {1}' -f $check.Id, $_ }
                }
            }
        }
        @($left | Select-Object -Unique) | Should -BeNullOrEmpty
    }

    It 'Format-AfSize usa el formato del idioma' {
        Set-AfLanguage -Language es
        Format-AfSize -Bytes (1.9GB) | Should -Be '1,9 GB'
        Set-AfLanguage -Language en
        Format-AfSize -Bytes (1.9GB) | Should -Be '1.9 GB'
    }

    It 'Join-AfNames une con "and" en inglés' {
        Set-AfLanguage -Language en
        Join-AfNames @('A', 'B', 'C') | Should -Be 'A, B and C'
        Set-AfLanguage -Language es
        Join-AfNames @('A', 'B') | Should -Be 'A y B'
    }

    It 'ningún T corre al cargar el código (el idioma todavía no está fijado)' {
        # Main.ps1 no se carga: corre después de Set-AfStartLanguage.
        $loose = foreach ($file in @(Get-AfSourceFiles | Where-Object { $_.Name -ne 'Main.ps1' })) {
            $ast = Get-AfAst $file.FullName
            $calls = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -in 'T', 'Get-AfText' }, $true)
            foreach ($call in $calls) {
                $inFunction = Test-AfAstInside $call { param($p) $p -is [System.Management.Automation.Language.FunctionDefinitionAst] -or $p -is [System.Management.Automation.Language.ScriptBlockExpressionAst] }
                if (-not $inFunction) { '{0}:{1}' -f $file.Name, $call.Extent.StartLineNumber }
            }
        }
        @($loose) | Should -BeNullOrEmpty
    }
}