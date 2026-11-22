BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
}

Describe 'Invoke-AfIsolatedJob' {
    It 'devuelve el resultado del trabajo' {
        $r = Invoke-AfIsolatedJob -Script 'param($Sync) @{ Titles = @(''A'', ''B'') }' -StallSeconds 30
        $r.Done | Should -BeTrue
        $r.TimedOut | Should -BeFalse
        @($r.Result.Titles) | Should -Be @('A', 'B')
    }

    It 'pasa los parámetros con nombre' {
        $r = Invoke-AfIsolatedJob -Script 'param($Sync, $Name, $Count) "$Name-$Count"' -Parameters @{ Name = 'a'; Count = 2 } -StallSeconds 30
        $r.Result | Should -Be 'a-2'
    }

    It 'el trabajo recibe los datos iniciales en Sync' {
        $r = Invoke-AfIsolatedJob -Script 'param($Sync) $Sync.Texts.Hola' -State @{ Texts = @{ Hola = 'hello' } } -StallSeconds 30
        $r.Result | Should -Be 'hello'
    }

    It 'avisa cada etapa nueva una vez' {
        $seen = New-Object System.Collections.ArrayList
        $script = 'param($Sync) foreach ($s in ''A'', ''A'', ''B'') { $Sync.Stage = $s; $Sync.Beat = [datetime]::UtcNow; Start-Sleep -Milliseconds 600 }'
        Invoke-AfIsolatedJob -Script $script -StallSeconds 30 -OnStage { param($stage) [void]$seen.Add($stage) }.GetNewClosure() | Out-Null
        @($seen) | Should -Be @('A', 'B')
    }

    It 'devuelve el error y el HResult sin lanzar' {
        $r = Invoke-AfIsolatedJob -Script 'param($Sync) throw (New-Object System.Runtime.InteropServices.COMException(''servicio apagado'', -2147023838))' -StallSeconds 30
        $r.Done | Should -BeTrue
        $r.Error | Should -BeLike '*servicio apagado*'
        $r.HResult | Should -Be 0x80070422
    }

    It 'un error que no corta el script también se informa (como la falla de un método COM)' {
        $r = Invoke-AfIsolatedJob -Script 'param($Sync) [int]::Parse(''x''); ''sigue''' -StallSeconds 30
        $r.Error | Should -Not -BeNullOrEmpty
        $r.HResult | Should -Be -2146233033
    }

    It 'corta un trabajo que deja de avanzar' {
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-AfIsolatedJob -Script 'param($Sync) Start-Sleep -Seconds 30' -StallSeconds 1
        $watch.Elapsed.TotalSeconds | Should -BeLessThan 5
        $r.TimedOut | Should -BeTrue
        $r.Done | Should -BeFalse
    }

    It 'deja ver lo que el trabajo anotó antes de cortarse' {
        $r = Invoke-AfIsolatedJob -Script 'param($Sync) $Sync.Results = @(''KB1''); Start-Sleep -Seconds 30' -StallSeconds 1
        $r.TimedOut | Should -BeTrue
        @($r.Sync.Results) | Should -Be @('KB1')
    }

    It 'no corta un trabajo largo que sigue avanzando' {
        $script = 'param($Sync) for ($i = 0; $i -lt 6; $i++) { Start-Sleep -Milliseconds 500; $Sync.Beat = [datetime]::UtcNow }; ''ok'''
        $r = Invoke-AfIsolatedJob -Script $script -StallSeconds 1
        $r.TimedOut | Should -BeFalse
        $r.Result | Should -Be 'ok'
    }
}
