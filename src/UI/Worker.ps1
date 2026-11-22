# El análisis corre en un runspace aparte y solo encola eventos; la ventana los lee con un DispatcherTimer.
function Start-AfScanWorker {
    param([Parameter(Mandatory)][string]$Code, [Parameter(Mandatory)]$Queue, [ValidateSet('es', 'en')][string]$Language = 'es')
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = 'STA'
    $runspace.ThreadOptions = 'ReuseThread'
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable('AfQueue', $Queue)
    $runspace.SessionStateProxy.SetVariable('AfCodeText', $Code)
    $runspace.SessionStateProxy.SetVariable('AfLanguageName', $Language)
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript({
            try {
                . ([scriptblock]::Create($AfCodeText))
                # Los textos del catálogo y de las detecciones salen en el idioma de la ventana.
                Set-AfLanguage -Language $AfLanguageName
                $catalog = @(Get-AfCatalog)
                $inventory = Get-AfInventory -Reads (Get-AfCatalogReads -Catalog $catalog) -OnProgress { param($part) $AfQueue.Enqueue([pscustomobject]@{ Type = 'Part'; Part = $part }) }
                $AfQueue.Enqueue([pscustomobject]@{ Type = 'Inventory'; Inventory = $inventory })
                foreach ($category in Get-AfCategories) {
                    $results = @($catalog | Where-Object { $_.Category -eq $category.Id } | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $inventory })
                    $AfQueue.Enqueue([pscustomobject]@{ Type = 'Category'; Category = $category.Id; Results = $results })
                }
                $AfQueue.Enqueue([pscustomobject]@{ Type = 'Done' })
                foreach ($check in @($catalog | Where-Object { $_.Async })) {
                    try { $detection = & $check.AsyncDetect $inventory } catch { $detection = New-AfDetection -State Error -Note $_.Exception.Message }
                    $AfQueue.Enqueue([pscustomobject]@{ Type = 'Async'; Id = $check.Id; Detection = $detection })
                }
            } catch {
                $AfQueue.Enqueue([pscustomobject]@{ Type = 'Error'; Message = $_.Exception.Message })
            }
        })
    $handle = $ps.BeginInvoke()
    [pscustomobject]@{ PowerShell = $ps; Runspace = $runspace; Handle = $handle }
}

# Aplicar y deshacer también corren aparte: recargan el código y buscan las revisiones por Id (sin pasar scriptblocks entre hilos).
function Start-AfApplyWorker {
    param([Parameter(Mandatory)][string]$Code, [Parameter(Mandatory)]$Queue, [Parameter(Mandatory)]$Shared, [Parameter(Mandatory)]$Plan)
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = 'STA'
    $runspace.ThreadOptions = 'ReuseThread'
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable('AfQueue', $Queue)
    $runspace.SessionStateProxy.SetVariable('AfShared', $Shared)
    $runspace.SessionStateProxy.SetVariable('AfPlan', $Plan)
    $runspace.SessionStateProxy.SetVariable('AfCodeText', $Code)
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript({
            try {
                . ([scriptblock]::Create($AfCodeText))
                if ($AfPlan.LogPath) { Set-AfLogPath -Path $AfPlan.LogPath }
                if ($AfPlan.Mode -eq 'Undo') { Invoke-AfUndoPlan -Plan $AfPlan -Queue $AfQueue }
                else { Invoke-AfApplyPlan -Plan $AfPlan -Queue $AfQueue -Shared $AfShared }
            } catch {
                $reason = (T 'Windows no aceptó el cambio')
                try { $reason = Get-AfApplyReason -ErrorRecord $_; Write-AfLog -Level Error -Message "Trabajo de aplicar: $($_.Exception.Message)" } catch { }
                $AfQueue.Enqueue([pscustomobject]@{ Type = 'Error'; Message = $reason })
            }
        })
    $handle = $ps.BeginInvoke()
    [pscustomobject]@{ PowerShell = $ps; Runspace = $runspace; Handle = $handle }
}

function Stop-AfScanWorker {
    param($Worker)
    if (-not $Worker) { return }
    try { [void]$Worker.PowerShell.BeginStop($null, $null) } catch { }
}
