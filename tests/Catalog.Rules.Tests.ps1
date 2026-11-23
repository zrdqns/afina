Describe 'Reglas del catálogo' {
    BeforeAll {
        . "$PSScriptRoot\..\src\Load.ps1"
        . "$PSScriptRoot\Helpers\FakeInventory.ps1"
        $script:catalog = @(Get-AfCatalog)
        $script:code = (Get-ChildItem "$PSScriptRoot\..\src\Checks", "$PSScriptRoot\..\src\Changes" -Filter *.ps1 | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"
        # Las cuatro claves permitidas (sección 8 del diseño), completas: 'ExplorerX' no pasa.
        $script:allowedKeys = 'Dsh', 'Windows\WindowsAI', 'Windows\Windows Search', 'Windows\Explorer'
        # Las cinco filas de la sección 8: hive, clave completa, valor y ediciones donde se escribe.
        $script:allowedRows = @(
            @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests'; Editions = 'Professional', 'Enterprise', 'Education'; Win11Only = $true }
            @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableAIDataAnalysis'; Editions = 'Professional', 'Enterprise', 'Education'; Win11Only = $true }
            @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'ConnectedSearchUseWeb'; Editions = 'Enterprise', 'Education'; Win11Only = $false }
            @{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Editions = @('Professional'); Win11Only = $false }
            @{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'HideRecommendedSection'; Editions = 'Professional', 'Enterprise', 'Education'; Win11Only = $true }
        )
    }

    It 'por lectura: ningún Apply nombra directivas fuera de la lista' {
        foreach ($check in @($script:catalog | Where-Object { $_.Apply })) {
            foreach ($m in [regex]::Matches($check.Apply.ToString(), '(?i)Policies\\Microsoft\\([^''"|]+)')) {
                $script:allowedKeys -contains $m.Groups[1].Value | Should -BeTrue -Because "$($check.Id): $($m.Value)"
            }
        }
    }

    It 'por ejecución: lo que escriben las seis revisiones de directivas está en la lista y en su edición' {
        Mock Set-AfRegistryValue { $script:writes.Add([pscustomobject]@{ Path = $Path; Name = $Name; Value = $Value; Type = $Type }); $true }
        Mock Send-AfShellNotify { }
        Mock Add-AfUnverifiedNote { }
        Mock Get-AfRecallState { 'Enabled' }
        $script:writes = [System.Collections.Generic.List[object]]::new()
        $seen = @{}
        $ids = 'cleanup.widgets', 'cleanup.recall', 'cleanup.ads', 'cleanup.diagnostics', 'windows.search-web', 'windows.start-recommendations'
        foreach ($edition in 'Core', 'Professional', 'Enterprise', 'Education') {
            foreach ($build in 19045, 26100) {
                $os = [pscustomobject]@{ Caption = 'Microsoft Windows'; Build = $build; Edition = $edition; IsWin11 = ($build -ge 22000); IsInsider = $false; Ubr = 7019 }
                $inv = New-AfFakeInventory -Override @{ Os = $os; Apps = [pscustomobject]@{ Promo = @(); Copilot = $null; HasWidgets = $true } }
                foreach ($id in $ids) {
                    $check = $script:catalog | Where-Object { $_.Id -eq $id }
                    if ($check.AppliesTo -and -not (& $check.AppliesTo $inv)) { continue }
                    $detection = if ($check.AsyncDetect) { & $check.AsyncDetect $inv } else { & $check.Detect $inv }
                    if ($detection.State -ne 'Improvable') { continue }
                    $script:writes.Clear()
                    & $check.Apply $inv $detection (New-AfTransaction -User $inv.User)
                    foreach ($w in @($script:writes | Where-Object { $_.Path -match '(?i)\\Policies\\Microsoft\\' })) {
                        $row = @($script:allowedRows | Where-Object { $_.Path -ceq $w.Path -and $_.Name -ceq $w.Name })
                        $row.Count | Should -Be 1 -Because "$id ($edition $build): $($w.Path)|$($w.Name)"
                        $row[0].Editions -contains $edition | Should -BeTrue -Because "$id escribe $($w.Name) en $edition"
                        if ($row[0].Win11Only) { $os.IsWin11 | Should -BeTrue -Because "$id escribe $($w.Name) en Windows 10" }
                        $w.Type | Should -Be 'DWord'
                        $seen["$($w.Path)|$($w.Name)"] = $true
                    }
                }
            }
        }
        # La prueba tiene dientes: se vieron escrituras de las cinco filas.
        foreach ($row in $script:allowedRows) { $seen.ContainsKey("$($row.Path)|$($row.Name)") | Should -BeTrue -Because "nunca se escribió $($row.Name)" }
    }

    It 'nada toca lo que no se recomienda' {
        $script:code | Should -Not -Match '(?i)Set-Service|Disable-NetAdapterBinding|teredo|WSearch|SvcHostSplitThresholdInKB|e9a42b02-d5df-448d-aa00-03f14749eb61|OneDriveSetup'
    }
    It 'ninguna ruta de Edge se escribe: solo se lee, con |' {
        $script:code | Should -Not -Match '(?i)Policies\\Microsoft\\Edge(?!\|)'
    }
    It 'todo lo de windows viene sin marcar' {
        @($script:catalog | Where-Object { $_.Category -eq 'windows' -and $_.Preselect }).Count | Should -Be 0
    }
    It 'aplicar todo lo marcado lleva la aguja a 1 y lo sin marcar no cuenta' {
        # Temporales entre 100 MB y 1 GB: mejorable, puntuada y sin marcar (el caso que dejaba la aguja corta).
        $base = New-AfFakeInventory
        $storage = $base.Storage.PSObject.Copy()
        $storage.TempBytes = [pscustomobject]@{ User = [long]500MB; Windows = 0; UpdateCache = 0; DeliveryOptimization = 0; ErrorReports = 0 }
        $inv = New-AfFakeInventory -Override @{ Storage = $storage }
        $results = @($script:catalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $inv })
        $scored = @($results | Where-Object { $_.Check.Kind -eq 'Auto' -and (Test-AfIsScoredCategory -Category $_.Check.Category) -and $_.Detection.State -eq 'Improvable' })
        $marked = @($scored | Where-Object { $_.Preselected })
        $unmarked = @($scored | Where-Object { -not $_.Preselected })
        $marked.Count | Should -BeGreaterThan 0
        $unmarked.Count | Should -BeGreaterThan 0
        (Get-AfScore -Results $results) | Should -BeLessThan 1
        foreach ($r in $unmarked) { Test-AfCountsForScore -Result $r | Should -BeFalse -Because $r.Check.Id }
        foreach ($r in $marked) { Test-AfCountsForScore -Result $r | Should -BeTrue -Because $r.Check.Id }
        $after = @($results | ForEach-Object {
                if ($_.Preselected) { [pscustomobject]@{ Check = $_.Check; Detection = (New-AfDetection -State Ok); Weight = $_.Weight; Preselected = $false } } else { $_ }
            })
        (Get-AfScore -Results $after) | Should -Be 1
    }
}
