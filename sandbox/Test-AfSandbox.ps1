# Corre dentro de Windows Sandbox: desafina, analiza, aplica todo lo que se puede, verifica, deshace y compara.
# Deja C:\resultados\informe.json. Lo lanza sandbox\Start-AfSandboxTest.ps1 desde la PC, que después cierra el Sandbox.
param([switch]$NoShutdown)
$ErrorActionPreference = 'Stop'
$out = 'C:\resultados'
$report = [ordered]@{
    Version = $null; StartedAt = (Get-Date).ToString('o'); Os = $null; Admin = $null; Detuned = @(); InventorySeconds = $null; Environment = $null
    Before = @(); Async = @(); Changes = @(); Undo = @(); Pieces = @(); Differences = @(); RecordsNotRestored = @(); Passed = $false; Error = $null
}
try {
    . 'C:\prueba\SandboxLib.ps1'
    . (Get-AfBuiltCode -Path 'C:\afina\Afina.ps1')
    [void](Start-AfLog -Directory $out)
    $report.Version = Get-AfVersion
    $report.Os = [string](Get-CimInstance Win32_OperatingSystem).Version
    $report.Admin = Test-AfAdmin
    # El inicio de fábrica de cada servicio que repara hardware.services, leído en un Windows limpio antes de desafinar.
    $report.ServiceDefaults = @(foreach ($group in Get-AfServiceGroups) {
            foreach ($name in $group.Services.Keys) {
                $start = Get-AfServiceStart -Name $name
                $actual = if ($start) { ConvertTo-AfServiceMode -Start $start.Start -Delayed $start.Delayed } else { '(no existe)' }
                [pscustomobject]@{ Name = $name; Expected = $group.Services[$name]; Actual = $actual; Same = $actual -eq $group.Services[$name] }
            }
        })
    $report.Detuned = @(Set-AfSandboxDetuned)
    Start-Sleep -Seconds 2
    $before = Get-AfSandboxState

    $catalog = @(Get-AfCatalog)
    $reads = Get-AfCatalogReads -Catalog $catalog
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $inventory = Get-AfInventory -Reads $reads
    $report.InventorySeconds = [math]::Round($watch.Elapsed.TotalSeconds, 1)
    $results = @($catalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $inventory })
    $report.Before = @($results | ForEach-Object { [pscustomobject]@{ Id = $_.Check.Id; State = $_.Detection.State; Current = $_.Detection.Current } })
    $report.Environment = Get-AfSandboxEnvironment

    # Las búsquedas en segundo plano (Windows Update y winget), como en la ventana. Raw: se escapó una excepción.
    $report.Async = @(foreach ($check in @($catalog | Where-Object { $_.Async })) {
            $watch = [System.Diagnostics.Stopwatch]::StartNew()
            $raw = $false
            try { $detection = & $check.AsyncDetect $inventory } catch { $raw = $true; $detection = New-AfDetection -State Error -Note $_.Exception.Message }
            [pscustomobject]@{ Id = $check.Id; State = $detection.State; Current = $detection.Current; Note = $detection.Note; Raw = $raw; Seconds = [math]::Round($watch.Elapsed.TotalSeconds, 1) }
        })

    # Aplica todo lo mejorable que tiene Apply (sin preguntar la pantalla: no hay nadie mirando).
    # Las actualizaciones no entran: su análisis es en segundo plano (arriba), no se deshacen y pueden tardar horas.
    $session = New-AfSession -Directory (Join-Path $out 'respaldos') -User $inventory.User
    $todo = Get-AfApplyOrder -Items @($results | Where-Object { $_.Detection.State -eq 'Improvable' -and (Test-AfCanApply -Check $_.Check) })
    # Cada cambio anota sus pasos reales (los que la ventana muestra en vivo).
    $stepsById = @{}
    $changes = foreach ($result in $todo) {
        $seen = New-Object System.Collections.ArrayList
        Invoke-AfChange -Session $session -Check $result.Check -Detection $result.Detection -Inventory $inventory -Step { param($name) [void]$seen.Add($name) }.GetNewClosure()
        $stepsById[$result.Check.Id] = @($seen) -join ','
    }

    # Verifica con un análisis nuevo.
    $after = @($catalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory (Get-AfInventory -Reads $reads) })
    $report.Changes = @($changes | ForEach-Object {
            $id = $_.CheckId
            $now = @($after | Where-Object { $_.Check.Id -eq $id })[0]
            $expected = if ($now.Check.NoUndo) { 'apply,backup' } else { 'save,apply,backup' }
            [pscustomobject]@{ Id = $id; Status = $_.Status; Message = $_.Message; Note = $_.Note; Records = @($_.Records).Count; StateAfter = $now.Detection.State; CurrentAfter = $now.Detection.Current; Steps = $stepsById[$id]; StepsOk = $stepsById[$id] -eq $expected }
        })

    # Deshace todo y compara con el estado de antes de aplicar.
    $user = Get-AfUserForSid -Sid $session.User.Sid
    $undoable = @($session.Changes | Where-Object { Test-AfChangeUndoable -Change $_ })
    [array]::Reverse($undoable)
    $report.Undo = @(foreach ($change in $undoable) {
            $seen = New-Object System.Collections.ArrayList
            $done = Undo-AfChange -Session $session -Change $change -Step { param($name) [void]$seen.Add($name) }.GetNewClosure()
            [pscustomobject]@{ Id = $done.CheckId; Status = $done.Status; Message = $done.Message; Steps = @($seen) -join ','; StepsOk = (@($seen) -join ',') -eq 'restore,backup' }
        })

    # Piezas que el catálogo no llega a aplicar aquí (sin VMP ni apps promocionales): ida y vuelta directa.
    $report.Pieces = @(Test-AfSandboxPieces -User $user)
    Start-Sleep -Seconds 2
    $report.Differences = @(Compare-AfSandboxState -Before $before -After (Get-AfSandboxState))
    $report.RecordsNotRestored = @(foreach ($change in $undoable) {
            foreach ($record in @($change.Records)) {
                if (-not (Test-AfRecordRestored -Record $record -User $user)) { [pscustomobject]@{ Id = $change.CheckId; Kind = $record.Kind; Name = $record.Name } }
            }
        })

    $applied = @($report.Changes | Where-Object { $_.Status -eq 'Applied' })
    $report.Passed = $report.Admin -and
        @($report.Changes | Where-Object { $_.Status -ne 'Applied' }).Count -eq 0 -and
        @($applied | Where-Object { $_.StateAfter -ne 'Ok' }).Count -eq 0 -and
        @($report.Undo | Where-Object { $_.Status -ne 'Undone' }).Count -eq 0 -and
        @($report.Changes | Where-Object { -not $_.StepsOk }).Count -eq 0 -and
        @($report.Undo | Where-Object { -not $_.StepsOk }).Count -eq 0 -and
        $report.Differences.Count -eq 0 -and
        $report.RecordsNotRestored.Count -eq 0 -and
        @($report.Pieces | Where-Object { -not $_.Restored }).Count -eq 0 -and
        @($report.Async | Where-Object { $_.Raw }).Count -eq 0
} catch {
    $report.Error = ($_ | Out-String)
} finally {
    $report.FinishedAt = (Get-Date).ToString('o')
    [System.IO.File]::WriteAllText((Join-Path $out 'informe.json'), (ConvertTo-Json -InputObject ([pscustomobject]$report) -Depth 8), (New-Object System.Text.UTF8Encoding($false)))
    [System.IO.File]::WriteAllText((Join-Path $out 'listo.txt'), 'listo')
    if (-not $NoShutdown) { & shutdown.exe /s /t 5 }
}
