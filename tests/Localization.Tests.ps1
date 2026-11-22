BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
}

Describe 'Idioma' {
    AfterEach { Set-AfLanguage -Language es }

    It 'T devuelve el español tal cual en español' {
        Set-AfLanguage -Language es
        T 'Volver a analizar' | Should -Be 'Volver a analizar'
        Get-AfLanguage | Should -Be 'es'
    }

    It 'T traduce en inglés y sin traducción devuelve el español' {
        $script:AfStringsEn['Texto de prueba para T'] = 'Test text for T'
        try {
            Set-AfLanguage -Language en
            T 'Texto de prueba para T' | Should -Be 'Test text for T'
            T 'Texto que nadie tradujo' | Should -Be 'Texto que nadie tradujo'
        } finally { $script:AfStringsEn.Remove('Texto de prueba para T') }
    }

    It 'distingue mayúsculas' {
        $script:AfStringsEn['Prueba Mayúscula'] = 'Capital Test'
        try {
            Set-AfLanguage -Language en
            T 'prueba mayúscula' | Should -Be 'prueba mayúscula'
            T 'Prueba Mayúscula' | Should -Be 'Capital Test'
        } finally { $script:AfStringsEn.Remove('Prueba Mayúscula') }
    }

    It 'Automático sigue a Windows: español si Windows está en español, si no inglés' {
        foreach ($culture in 'es-ES', 'es-MX', 'es-419') {
            Mock Get-UICulture { [System.Globalization.CultureInfo]::GetCultureInfo($culture) }.GetNewClosure()
            Resolve-AfLanguage -Setting 'Auto' | Should -Be 'es' -Because $culture
        }
        foreach ($culture in 'en-US', 'pt-BR') {
            Mock Get-UICulture { [System.Globalization.CultureInfo]::GetCultureInfo($culture) }.GetNewClosure()
            Resolve-AfLanguage -Setting 'Auto' | Should -Be 'en' -Because $culture
        }
        Resolve-AfLanguage -Setting 'es' | Should -Be 'es'
        Resolve-AfLanguage -Setting 'en' | Should -Be 'en'
    }

    It 'un valor desconocido cuenta como Automático' {
        Mock Get-UICulture { [System.Globalization.CultureInfo]::GetCultureInfo('pt-BR') }
        Resolve-AfLanguage -Setting 'fr' | Should -Be 'en'
        Resolve-AfLanguage -Setting $null | Should -Be 'en'
    }

    It 'Get-AfCulture da es-ES o en-US' {
        Set-AfLanguage -Language es
        (Get-AfCulture).Name | Should -Be 'es-ES'
        Set-AfLanguage -Language en
        (Get-AfCulture).Name | Should -Be 'en-US'
    }

    It 'la configuración trae Language = Auto' {
        (Get-AfConfigDefaults).Language | Should -Be 'Auto'
    }
}
