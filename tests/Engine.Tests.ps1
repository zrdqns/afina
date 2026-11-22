BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"

    function New-TestCheck {
        param([string]$Id = 'test.check', [string]$Category = 'energy', [string]$Kind = 'Auto', [string]$Impact = 'Medium', [scriptblock]$Detect, [scriptblock]$AppliesTo)
        $check = @{
            Id = $Id; Category = $Category; Title = 'Prueba'; Why = 'Porque sí.'; Impact = $Impact; Risk = 'Safe'; Kind = $Kind
            Preselect = $true; NeedsReboot = $false; Source = 'https://example.test'; Undo = 'Se puede deshacer'
            Detect = if ($Detect) { $Detect } else { { param($inv) New-AfDetection -State Ok } }
            Apply = { param($inv, $detected, $tx) }
        }
        if ($AppliesTo) { $check.AppliesTo = $AppliesTo }
        $check
    }

    function New-TestResult([string]$State, [string]$Impact = 'Medium', [string]$Kind = 'Auto', [string]$Category = 'energy') {
        Invoke-AfCheck -Check (New-TestCheck -Kind $Kind -Impact $Impact -Category $Category -Detect ([scriptblock]::Create("param(`$inv) New-AfDetection -State $State"))) -Inventory (New-AfFakeInventory)
    }
}

Describe 'Invoke-AfCheck' {
    It 'convierte una excepción en Error' {
        $r = Invoke-AfCheck -Check (New-TestCheck -Detect { param($inv) throw 'se rompió' }) -Inventory (New-AfFakeInventory)
        $r.Detection.State | Should -Be 'Error'
        $r.Detection.Note | Should -Match 'se rompió'
    }

    It 'AppliesTo falso da NotApplicable' {
        $r = Invoke-AfCheck -Check (New-TestCheck -AppliesTo { param($inv) $false }) -Inventory (New-AfFakeInventory)
        $r.Detection.State | Should -Be 'NotApplicable'
    }

    It 'da el peso según el impacto' {
        (New-TestResult -State Ok -Impact High).Weight | Should -Be 3
        (New-TestResult -State Ok -Impact Low).Weight | Should -Be 1
    }

    It 'Preselected usa el valor de la detección si lo trae' {
        $r = Invoke-AfCheck -Check (New-TestCheck -Detect { param($inv) New-AfDetection -State Improvable -Preselect $false }) -Inventory (New-AfFakeInventory)
        $r.Preselected | Should -BeFalse
        (New-TestResult -State Improvable).Preselected | Should -BeTrue
    }
}

Describe 'Get-AfScore' {
    It '30 en orden y 14 pendientes = 30/44' {
        $results = @()
        1..10 | ForEach-Object { $results += New-TestResult -State Ok -Impact High }
        1..7 | ForEach-Object { $results += New-TestResult -State Improvable -Impact Medium }
        Get-AfScore -Results $results | Should -Be (30 / 44)
    }

    It 'ignora optional, Manual e Info' {
        $results = @(
            New-TestResult -State Ok -Impact High
            New-TestResult -State Improvable -Impact High -Category 'optional'
            New-TestResult -State Manual -Impact High -Kind 'Manual'
            New-TestResult -State Info -Impact High -Kind 'Info'
        )
        Get-AfScore -Results $results | Should -Be 1
    }

    It 'vale 1 si no hay nada que contar' {
        Get-AfScore -Results @() | Should -Be 1
    }
}

Describe 'Get-AfSummary' {
    It 'cuenta listos, a mano, en orden y opcionales' {
        $results = @(
            New-TestResult -State Improvable
            New-TestResult -State Improvable
            New-TestResult -State Manual -Kind 'Manual'
            New-TestResult -State Ok
            New-TestResult -State Improvable -Category 'optional'
        )
        $s = Get-AfSummary -Results $results
        $s.Ready | Should -Be 2
        $s.Manual | Should -Be 1
        $s.Ok | Should -Be 1
        $s.Optional | Should -Be 1
    }
}

Describe 'Catálogo' {
    It 'Get-AfCatalog falla con Id repetido' {
        { Get-AfCatalog -Providers @({ New-TestCheck -Id 'a.b' }, { New-TestCheck -Id 'a.b' }) } | Should -Throw '*a.b*'
    }

    It 'Test-AfCheckDefinition detecta campos que faltan y valores inválidos' {
        $bad = New-TestCheck
        $bad.Remove('Title')
        $bad.Impact = 'Enorme'
        $errors = Test-AfCheckDefinition -Check $bad
        $errors | Should -Contain 'Falta Title'
        ($errors -join ' ') | Should -Match 'Impact'
    }

    It 'Get-AfCategories trae las 8 categorías en orden' {
        (Get-AfCategories).Id | Should -Be @('energy', 'gaming', 'network', 'startup', 'storage', 'security', 'hardware', 'optional')
    }

    It 'cada revisión del catálogo real pasa Test-AfCheckDefinition' {
        foreach ($check in @(Get-AfCatalog)) {
            $errors = @(Test-AfCheckDefinition -Check $check)
            if ($errors.Count) { throw "$($check.Id): $($errors -join '; ')" }
        }
    }

    It 'Get-AfCatalogReads junta las lecturas sin duplicados' {
        $reads = Get-AfCatalogReads -Catalog @(@{ Reads = @('HKLM:\A|B', 'HKLM:\A|C') }, @{ Reads = @('HKLM:\A|B') })
        @($reads).Count | Should -Be 2
    }
}

Describe 'Fuentes del catálogo' {
    It 'toda revisión con fuente de Microsoft tiene su enlace https de Microsoft' {
        foreach ($check in Get-AfCatalog) {
            if ($check.Source -like 'Microsoft*') {
                $check.SourceUrl | Should -Match '^https://([a-z0-9-]+\.)*(microsoft|xbox)\.com/' -Because $check.Id
            }
        }
    }
}