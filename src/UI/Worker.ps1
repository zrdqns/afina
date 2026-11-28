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
                    try {
                        if ($check.AppliesTo -and -not (& $check.AppliesTo $inventory)) { continue }
                        $detection = & $check.AsyncDetect $inventory
                    } catch { $detection = New-AfDetection -State Error -Note $_.Exception.Message }
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

# Estadísticas en vivo: un runspace liviano mide CPU, memoria, disco y red cada segundo y deja la última muestra en $Sync.
# Los contadores de Windows tardan en abrir la primera vez (hasta varios segundos): por eso no van en el hilo de la ventana.
function Start-AfLiveWorker {
    param([Parameter(Mandatory)]$Sync)
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable('AfLive', $Sync)
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript({
            $failed = New-Object System.Collections.ArrayList
            $open = { param($category, $counter) try { $c = New-Object System.Diagnostics.PerformanceCounter($category, $counter, '_Total'); [void]$c.NextValue(); $c } catch { $null } }
            $info = $null
            try { Add-Type -AssemblyName Microsoft.VisualBasic; $info = New-Object Microsoft.VisualBasic.Devices.ComputerInfo } catch { [void]$failed.Add('Mem') }
            $cpu = $null
            $disk = $null
            $opened = $false
            $last = $null
            while (-not $AfLive.Stop) {
                $sample = @{}
                if ($info) { try { $total = [double]$info.TotalPhysicalMemory; $sample.MemTotal = $total; $sample.MemUsed = $total - [double]$info.AvailablePhysicalMemory } catch { } }
                if ($cpu) { try { $sample.Cpu = [math]::Min(100.0, [math]::Max(0.0, $cpu.NextValue())) } catch { } }
                if ($disk) { try { $sample.Disk = [math]::Min(100.0, [math]::Max(0.0, 100 - $disk.NextValue())) } catch { } }
                # Solo adaptadores físicos conectados: los virtuales (Hyper-V, VPN) repiten el mismo tráfico.
                $rx = 0
                $tx = 0
                try {
                    foreach ($nic in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
                        if ($nic.OperationalStatus -ne 'Up' -or $nic.NetworkInterfaceType -in 'Loopback', 'Tunnel') { continue }
                        if ($nic.Description -match 'Hyper-V|Virtual|VMware|VirtualBox|TAP-|Loopback|WAN Miniport|Bluetooth') { continue }
                        $stats = $nic.GetIPStatistics()
                        $rx += $stats.BytesReceived
                        $tx += $stats.BytesSent
                    }
                    $now = [datetime]::UtcNow
                    if ($last) {
                        $seconds = ($now - $last.At).TotalSeconds
                        if ($seconds -gt 0) { $sample.Down = [math]::Max(0.0, ($rx - $last.Rx) * 8 / $seconds); $sample.Up = [math]::Max(0.0, ($tx - $last.Tx) * 8 / $seconds) }
                    }
                    $last = @{ At = $now; Rx = $rx; Tx = $tx }
                } catch { }
                $AfLive.Sample = $sample
                $AfLive.Seq = [int]$AfLive.Seq + 1
                if (-not $opened) {
                    $opened = $true
                    $cpu = & $open 'Processor Information' '% Processor Utility'
                    if (-not $cpu) { $cpu = & $open 'Processor' '% Processor Time' }
                    if (-not $cpu) { [void]$failed.Add('Cpu') }
                    $disk = & $open 'PhysicalDisk' '% Idle Time'
                    if (-not $disk) { [void]$failed.Add('Disk') }
                    $AfLive.Failed = $failed.ToArray()
                    continue
                }
                Start-Sleep -Milliseconds 1000
            }
        })
    $handle = $ps.BeginInvoke()
    [pscustomobject]@{ PowerShell = $ps; Runspace = $runspace; Handle = $handle; Sync = $Sync }
}

function Stop-AfLiveWorker {
    param($Worker)
    if (-not $Worker) { return }
    $Worker.Sync.Stop = $true
    # Sin esperar: si justo está abriendo los contadores, Stop() trabaría el cierre de la ventana unos segundos.
    try { [void]$Worker.PowerShell.BeginStop($null, $null) } catch { }
}
