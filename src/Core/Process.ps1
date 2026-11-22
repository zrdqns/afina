function Invoke-AfProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string]$Arguments = '',
        [int]$TimeoutMs = 15000,
        [System.Text.Encoding]$Encoding
    )
    if (-not $Encoding) {
        # Las herramientas de consola de Windows escriben en la página OEM (850 en español).
        $Encoding = [System.Text.Encoding]::GetEncoding([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = $Encoding
    $psi.StandardErrorEncoding = $Encoding

    $process = [System.Diagnostics.Process]::Start($psi)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutMs)) {
        try { $process.Kill() } catch { }
        Write-AfLog -Level Warn -Message "Tiempo agotado ($TimeoutMs ms): $FilePath $Arguments"
        return [pscustomobject]@{ ExitCode = $null; Output = ''; Error = ''; TimedOut = $true }
    }
    $process.WaitForExit()
    [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $stdout.Result; Error = $stderr.Result; TimedOut = $false }
}
