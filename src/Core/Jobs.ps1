# Corre código que se puede colgar (Windows Update) en un runspace aparte y deja de esperarlo si no avanza.
# El script recibe -Sync (Stage y Beat en UTC) y los -Parameters por nombre; lo último que devuelve es Result.
# Lo que anota en Sync se puede leer aunque se corte (para no perder lo que ya hizo).
function Invoke-AfIsolatedJob {
    param(
        [Parameter(Mandatory)][string]$Script,
        [hashtable]$Parameters = @{},
        # Datos iniciales que el trabajo encuentra en $Sync (por ejemplo, los textos ya traducidos).
        [hashtable]$State = @{},
        [Parameter(Mandatory)][int]$StallSeconds,
        [scriptblock]$OnStage,
        [int]$PollMs = 250
    )
    $sync = [hashtable]::Synchronized(@{ Stage = $null; Beat = [datetime]::UtcNow })
    foreach ($key in $State.Keys) { $sync[$key] = $State[$key] }
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = 'STA'
    $runspace.ThreadOptions = 'ReuseThread'
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript($Script).AddParameter('Sync', $sync)
    foreach ($key in $Parameters.Keys) { [void]$ps.AddParameter($key, $Parameters[$key]) }
    $handle = $ps.BeginInvoke()

    $stage = $null
    $notify = {
        if ($sync.Stage -and $sync.Stage -ne $stage) {
            $stage = $sync.Stage
            if ($OnStage) { try { & $OnStage $stage } catch { Write-AfLog -Level Warn -Message "Aviso de etapa: $($_.Exception.Message)" } }
        }
    }
    while (-not $handle.IsCompleted) {
        . $notify
        if (([datetime]::UtcNow - [datetime]$sync.Beat).TotalSeconds -gt $StallSeconds) {
            # No se puede cortar una llamada COM trabada: el runspace queda abandonado y muere con el proceso.
            Write-AfLog -Level Warn -Message ('Trabajo aislado sin avance por más de {0} s; se deja de esperar (etapa: {1}).' -f $StallSeconds, $stage)
            try { [void]$ps.BeginStop($null, $null) } catch { }
            return [pscustomobject]@{ Done = $false; TimedOut = $true; Result = $null; Error = $null; HResult = $null; Sync = $sync }
        }
        Start-Sleep -Milliseconds $PollMs
    }
    . $notify

    $result = $null; $message = $null; $hresult = $null
    $failure = $null
    try {
        $output = $ps.EndInvoke($handle)
        if ($output.Count) { $result = $output[$output.Count - 1] }
        # La falla de un método (por ejemplo COM) solo corta esa línea: el script sigue, pero el error cuenta.
        if ($ps.Streams.Error.Count) { $failure = $ps.Streams.Error[0].Exception }
    } catch {
        $failure = $_.Exception
    } finally {
        if ($failure) {
            while ($failure.InnerException) { $failure = $failure.InnerException }
            $message = $failure.Message
            $hresult = $failure.HResult
            Write-AfLog -Level Warn -Message "Trabajo aislado: $message"
        }
        $ps.Dispose()
        $runspace.Dispose()
    }
    [pscustomobject]@{ Done = $true; TimedOut = $false; Result = $result; Error = $message; HResult = $hresult; Sync = $sync }
}
