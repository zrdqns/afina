# Restaurar sistema: si está activo en el disco y si una política lo bloquea.
function Get-AfRestoreStatus {
    param([string]$Drive = $env:SystemDrive)
    $letter = $Drive.TrimEnd(':', '\').ToUpperInvariant()
    # Volúmenes protegidos: "\\?\Volume{…}\:(C%3A)".
    $clients = Get-AfRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SPP\Clients' -Name '{09F7EDC5-294E-4180-AF6A-FB0E6A0E9513}'
    $enabled = @($clients | Where-Object { ([string]$_).ToUpperInvariant().Contains("($letter%3A)") }).Count -gt 0
    $policy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore'
    $disabled = (Get-AfRegistryValue -Path $policy -Name 'DisableSR') -eq 1
    $locked = (Get-AfRegistryValue -Path $policy -Name 'DisableConfig') -eq 1
    [pscustomobject]@{ Enabled = $enabled -and -not $disabled; Blocked = $disabled -or (-not $enabled -and $locked) }
}

function Enable-AfSystemRestore {
    param([string]$Drive = $env:SystemDrive)
    try {
        Enable-ComputerRestore -Drive ($Drive.TrimEnd('\') + '\') -ErrorAction Stop
        Write-AfLog -Level Info -Message "Restaurar sistema activado en $Drive."
        $true
    } catch {
        Write-AfLog -Level Warn -Message "No se pudo activar Restaurar sistema: $($_.Exception.Message)"
        $false
    }
}

function New-AfRestorePoint {
    param([string]$Description = 'Afina', [string]$Drive = $env:SystemDrive)
    $letter = $Drive.TrimEnd(':', '\').ToUpperInvariant()
    if (-not (Get-AfRestoreStatus -Drive $Drive).Enabled) { return [pscustomobject]@{ Ok = $false; At = $null; Message = ((T 'Restaurar sistema está apagado en {0}:') -f $letter) } }
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    $name = 'SystemRestorePointCreationFrequency'
    $previous = Get-AfRegistryValue -Path $key -Name $name
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        # Windows crea uno cada 24 h como máximo; con 0 se salta ese límite solo mientras se crea este.
        Set-ItemProperty -LiteralPath $key -Name $name -Value 0 -Type DWord -ErrorAction Stop
        $arguments = @{ Description = $Description; RestorePointType = [uint32]12; EventType = [uint32]100 }
        $result = Invoke-CimMethod -Namespace 'root/default' -ClassName 'SystemRestore' -MethodName 'CreateRestorePoint' -Arguments $arguments -OperationTimeoutSec 600 -ErrorAction Stop
        if ([int]$result.ReturnValue -ne 0) {
            Write-AfLog -Level Warn -Message "CreateRestorePoint: código $($result.ReturnValue)"
            return [pscustomobject]@{ Ok = $false; At = $null; Message = (T 'Windows no permitió crearlo') }
        }
        Write-AfLog -Level Info -Message ('Punto de restauración creado en {0:N1} s.' -f $watch.Elapsed.TotalSeconds)
        [pscustomobject]@{ Ok = $true; At = (Get-Date).ToString('o'); Message = $null }
    } catch {
        Write-AfLog -Level Warn -Message "Punto de restauración: $($_.Exception.Message)"
        $message = if ($watch.Elapsed.TotalSeconds -ge 590) { (T 'Windows no respondió a tiempo') } else { (T 'Windows no permitió crearlo') }
        [pscustomobject]@{ Ok = $false; At = $null; Message = $message }
    } finally {
        try {
            if ($null -eq $previous) { Remove-ItemProperty -LiteralPath $key -Name $name -ErrorAction Stop }
            else { Set-ItemProperty -LiteralPath $key -Name $name -Value $previous -Type DWord -ErrorAction Stop }
        } catch {
            Write-AfLog -Level Warn -Message "No se pudo dejar $name como estaba: $($_.Exception.Message)"
        }
    }
}
