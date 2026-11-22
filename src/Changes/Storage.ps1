function Get-AfTrimEnabled {
    $result = Invoke-AfProcess -FilePath 'fsutil.exe' -Arguments 'behavior query DisableDeleteNotify' -TimeoutMs 15000
    if ($result.TimedOut -or $result.ExitCode -ne 0) { throw (New-AfApplyError -Reason (T 'fsutil no respondió')) }
    -not (ConvertFrom-AfFsutilTrim -Text $result.Output).NtfsDisabled
}

function Invoke-AfTrimChange {
    param([bool]$Enabled)
    $flag = if ($Enabled) { 0 } else { 1 }
    $result = Invoke-AfProcess -FilePath 'fsutil.exe' -Arguments "behavior set DisableDeleteNotify NTFS $flag" -TimeoutMs 15000
    if ($result.TimedOut -or $result.ExitCode -ne 0) {
        Write-AfLog -Level Warn -Message ('fsutil DisableDeleteNotify {0}: código {1}. {2}' -f $flag, $result.ExitCode, $result.Output)
        throw (New-AfApplyError -Reason (T 'fsutil no aceptó el cambio'))
    }
}

function Set-AfTrim {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][bool]$Enabled)
    $previous = Get-AfTrimEnabled
    if ($previous -eq $Enabled) { return $false }
    Invoke-AfTrimChange -Enabled $Enabled
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'Trim'; Previous = $previous; New = $Enabled }
    $true
}

function Restore-AfTrim {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfTrimChange -Enabled ([bool]$Record.Previous)
}

function Get-AfTrimState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfTrimEnabled
}

# Carpetas de temporales (las mismas que mide el inventario). En Temp solo se borra lo que tiene más de 24 h.
function Get-AfTempFolders {
    param($Inventory)
    $profilePath = if ($Inventory -and $Inventory.User -and $Inventory.User.ProfilePath) { $Inventory.User.ProfilePath } else { $env:USERPROFILE }
    $wer = Join-Path $env:ProgramData 'Microsoft\Windows\WER'
    @(
        [pscustomobject]@{ Path = Join-Path $profilePath 'AppData\Local\Temp'; MinAgeHours = 24 }
        [pscustomobject]@{ Path = Join-Path $env:windir 'Temp'; MinAgeHours = 24 }
        [pscustomobject]@{ Path = Join-Path $env:windir 'SoftwareDistribution\Download'; MinAgeHours = 0 }
        [pscustomobject]@{ Path = Join-Path $wer 'ReportArchive'; MinAgeHours = 0 }
        [pscustomobject]@{ Path = Join-Path $wer 'ReportQueue'; MinAgeHours = 0 }
    )
}

# Borra el contenido de una carpeta sin seguir uniones ni enlaces y salta lo que esté en uso. Devuelve los bytes liberados.
function Remove-AfFolderContent {
    param([Parameter(Mandatory)][string]$Path, [int]$MinAgeHours = 0)
    if (-not [System.IO.Directory]::Exists($Path)) { return [long]0 }
    $limit = (Get-Date).AddHours(-$MinAgeHours)
    $freed = [long]0
    $folders = New-Object System.Collections.Generic.List[string]
    $pending = New-Object System.Collections.Generic.Stack[string]
    $pending.Push($Path)
    while ($pending.Count -gt 0) {
        $dir = $pending.Pop()
        $files = @()
        try { $files = [System.IO.Directory]::GetFiles($dir) } catch { }
        foreach ($file in $files) {
            try {
                $info = New-Object System.IO.FileInfo($file)
                if (($info.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
                if ($MinAgeHours -gt 0 -and $info.LastWriteTime -gt $limit) { continue }
                $length = $info.Length
                if ($info.IsReadOnly) { $info.IsReadOnly = $false }
                $info.Delete()
                $freed += $length
            } catch { }
        }
        $subs = @()
        try { $subs = [System.IO.Directory]::GetDirectories($dir) } catch { }
        foreach ($sub in $subs) {
            try { if (([System.IO.File]::GetAttributes($sub) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue } } catch { continue }
            $folders.Add($sub)
            $pending.Push($sub)
        }
    }
    # Las carpetas que quedaron vacías, de la más profunda a la menos (Delete sin recursión falla si no está vacía).
    foreach ($dir in @($folders | Sort-Object -Property Length -Descending)) {
        try { [System.IO.Directory]::Delete($dir) } catch { }
    }
    $freed
}

function Clear-AfDeliveryOptimizationCache {
    $path = Join-Path $env:windir 'ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache'
    if (-not (Get-Command -Name 'Delete-DeliveryOptimizationCache' -ErrorAction SilentlyContinue)) { return [long]0 }
    $before = Get-AfFolderBytes -Path $path
    try { Delete-DeliveryOptimizationCache -Force -ErrorAction Stop } catch { Write-AfLog -Level Warn -Message "Optimización de distribución: $($_.Exception.Message)" }
    [math]::Max([long]0, $before - (Get-AfFolderBytes -Path $path))
}

# Sin deshacer: queda un registro Action con lo liberado.
function Clear-AfTempFiles {
    param([Parameter(Mandatory)]$Tx, $Inventory)
    $freed = [long]0
    foreach ($folder in Get-AfTempFolders -Inventory $Inventory) { $freed += Remove-AfFolderContent -Path $folder.Path -MinAgeHours $folder.MinAgeHours }
    $freed += Clear-AfDeliveryOptimizationCache
    $detail = (T 'Se liberaron {0}') -f (Format-AfSize -Bytes $freed)
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'Action'; Name = 'Temporales'; Detail = $detail; FreedBytes = $freed }
    [void]$Tx.Notes.Add($detail + '.')
}
