function Get-AfFolderBytes {
    param([string]$Path)
    # Directory.Exists y no Test-Path: Test-Path lanza "Acceso denegado" en carpetas de servicio como la de NetworkService.
    if (-not $Path -or -not [System.IO.Directory]::Exists($Path)) { return [long]0 }
    $total = [long]0
    $pending = New-Object System.Collections.Generic.Stack[string]
    $pending.Push($Path)
    while ($pending.Count -gt 0) {
        $dir = $pending.Pop()
        try { foreach ($file in [System.IO.Directory]::EnumerateFiles($dir)) { try { $total += (New-Object System.IO.FileInfo($file)).Length } catch { } } } catch { }
        try {
            foreach ($sub in [System.IO.Directory]::EnumerateDirectories($dir)) {
                # Las uniones y enlaces simbólicos no se siguen, para no contar dos veces ni entrar en bucles.
                if (([System.IO.File]::GetAttributes($sub) -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) { $pending.Push($sub) }
            }
        } catch { }
    }
    $total
}

function Get-AfSystemDiskType {
    try {
        $partition = Get-Partition -DriveLetter ($env:SystemDrive.TrimEnd(':')) -ErrorAction Stop
        $disk = Get-PhysicalDisk -ErrorAction Stop | Where-Object { $_.DeviceId -eq [string]$partition.DiskNumber } | Select-Object -First 1
        [pscustomobject]@{ MediaType = [string]$disk.MediaType; BusType = [string]$disk.BusType }
    } catch {
        [pscustomobject]@{ MediaType = $null; BusType = $null }
    }
}

function Get-AfStorageInfo {
    param($User)
    $drive = $env:SystemDrive
    $logical = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$drive'" -OperationTimeoutSec 15
    $type = Get-AfSystemDiskType
    $profilePath = if ($User -and $User.ProfilePath) { $User.ProfilePath } else { $env:USERPROFILE }
    $windows = $env:windir
    $wer = Join-Path $env:ProgramData 'Microsoft\Windows\WER'
    $temp = [pscustomobject]@{
        User = Get-AfFolderBytes -Path (Join-Path $profilePath 'AppData\Local\Temp')
        Windows = Get-AfFolderBytes -Path (Join-Path $windows 'Temp')
        UpdateCache = Get-AfFolderBytes -Path (Join-Path $windows 'SoftwareDistribution\Download')
        DeliveryOptimization = Get-AfFolderBytes -Path (Join-Path $windows 'ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache')
        ErrorReports = (Get-AfFolderBytes -Path (Join-Path $wer 'ReportArchive')) + (Get-AfFolderBytes -Path (Join-Path $wer 'ReportQueue'))
    }
    $trim = Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\fsutil.exe') -Arguments 'behavior query DisableDeleteNotify' -TimeoutMs 15000
    [pscustomobject]@{
        SystemDrive = $drive
        FreeBytes = [long]$logical.FreeSpace
        FreeGB = [math]::Round([double]$logical.FreeSpace / 1GB)
        SizeGB = [math]::Round([double]$logical.Size / 1GB)
        MediaType = $type.MediaType
        BusType = $type.BusType
        TempBytes = $temp
        TrimEnabled = if ($trim.TimedOut -or $trim.ExitCode -ne 0) { $null } else { -not (ConvertFrom-AfFsutilTrim -Text $trim.Output).NtfsDisabled }
    }
}
