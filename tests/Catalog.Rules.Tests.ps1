Describe 'Reglas del catálogo' {
    BeforeAll {
        . "$PSScriptRoot\..\src\Load.ps1"
        $script:catalog = @(Get-AfCatalog)
        $script:code = (Get-ChildItem "$PSScriptRoot\..\src\Checks", "$PSScriptRoot\..\src\Changes" -Filter *.ps1 | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"
        $script:allowed = 'Policies\Microsoft\Dsh', 'Policies\Microsoft\Windows\WindowsAI', 'Policies\Microsoft\Windows\Windows Search', 'Policies\Microsoft\Windows\Explorer'
    }
    It 'ningún Apply escribe directivas fuera de la lista' {
        foreach ($check in @($script:catalog | Where-Object { $_.Apply })) {
            foreach ($m in [regex]::Matches($check.Apply.ToString(), 'Policies\\Microsoft\\[^''"|]+')) {
                @($script:allowed | Where-Object { $m.Value -like "$_*" }).Count | Should -BeGreaterThan 0 -Because "$($check.Id): $($m.Value)"
            }
        }
    }
    It 'nada toca lo que no se recomienda' {
        $script:code | Should -Not -Match '(?i)Set-Service|Disable-NetAdapterBinding|teredo|WSearch|SvcHostSplitThresholdInKB|e9a42b02-d5df-448d-aa00-03f14749eb61|Policies\\Microsoft\\Edge''|OneDriveSetup'
    }
    It 'todo lo de windows viene sin marcar' {
        @($script:catalog | Where-Object { $_.Category -eq 'windows' -and $_.Preselect }).Count | Should -Be 0
    }
    It 'aplicar todo lo marcado lleva la aguja a 1' {
        . "$PSScriptRoot\Helpers\FakeInventory.ps1"
        $results = @($script:catalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory (New-AfFakeInventory) })
        $after = @($results | ForEach-Object {
                if ($_.Preselected) { [pscustomobject]@{ Check = $_.Check; Detection = (New-AfDetection -State Ok); Weight = $_.Weight; Preselected = $false } } else { $_ }
            })
        Get-AfScore -Results $after | Should -Be 1
    }
}
