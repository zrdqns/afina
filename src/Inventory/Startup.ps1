$script:AfSignatureCache = @{}

function Get-AfCommandPath {
    param([string]$Command)
    $text = [Environment]::ExpandEnvironmentVariables(([string]$Command).Trim())
    if (-not $text) { return $null }
    if ($text.StartsWith('"')) {
        $end = $text.IndexOf('"', 1)
        if ($end -gt 1) { return $text.Substring(1, $end - 1) }
    }
    $m = [regex]::Match($text, '^(.+?\.(exe|com|bat|cmd|ps1|vbs|lnk))(\s|$)', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    ($text -split '\s+')[0]
}

function Test-AfUserWritablePath {
    param([string]$Path)
    if (-not $Path) { return $false }
    $Path -match '^[A-Za-z]:\\(Users|ProgramData)\\' -or $Path -match '\\(AppData|Temp)\\'
}

function Get-AfFileSignature {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return [pscustomobject]@{ IsSigned = $false; Signer = $null } }
    if ($script:AfSignatureCache.ContainsKey($Path)) { return $script:AfSignatureCache[$Path] }
    $result = [pscustomobject]@{ IsSigned = $false; Signer = $null }
    try {
        $signature = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
        $signer = $null
        if ($signature.SignerCertificate -and $signature.SignerCertificate.Subject -match 'CN="?([^",]+)') { $signer = $Matches[1] }
        $result = [pscustomobject]@{ IsSigned = [string]$signature.Status -eq 'Valid'; Signer = $signer }
    } catch { }
    $script:AfSignatureCache[$Path] = $result
    $result
}

function Get-AfRunValues {
    param($User)
    $skip = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'
    $sources = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'; Scope = 'Machine'; Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' }
        @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Scope = 'Machine'; Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32' }
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'; Scope = 'User'; Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' }
    )
    foreach ($source in $sources) {
        try { $item = Get-ItemProperty -LiteralPath (Resolve-AfRegistryPath -Path $source.Path -User $User) -ErrorAction Stop } catch { continue }
        foreach ($p in $item.PSObject.Properties) {
            if ($skip -contains $p.Name) { continue }
            [pscustomobject]@{ Name = $p.Name; Command = [string]$p.Value; Scope = $source.Scope; ApprovedPath = $source.Approved; ApprovedName = $p.Name; Source = 'Run' }
        }
    }
}

function Get-AfStartupFolderItems {
    param($User)
    $profilePath = if ($User -and $User.ProfilePath) { $User.ProfilePath } else { $env:USERPROFILE }
    $folders = @(
        @{ Path = Join-Path $profilePath 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'; Scope = 'User'; Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder' }
        @{ Path = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\StartUp'; Scope = 'Machine'; Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder' }
    )
    $shell = $null
    foreach ($folder in $folders) {
        foreach ($file in @(Get-ChildItem -LiteralPath $folder.Path -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' })) {
            $command = $file.FullName
            if ($file.Extension -eq '.lnk') {
                try {
                    if (-not $shell) { $shell = New-Object -ComObject WScript.Shell }
                    $target = $shell.CreateShortcut($file.FullName).TargetPath
                    if ($target) { $command = '"{0}"' -f $target }
                } catch { }
            }
            [pscustomobject]@{ Name = $file.BaseName; Command = $command; Scope = $folder.Scope; ApprovedPath = $folder.Approved; ApprovedName = $file.Name; Source = 'Folder' }
        }
    }
}

function Get-AfStartupEntries {
    param($User)
    foreach ($item in @(@(Get-AfRunValues -User $User) + @(Get-AfStartupFolderItems -User $User))) {
        $approvedName = if ($item.PSObject.Properties['ApprovedName'] -and $item.ApprovedName) { $item.ApprovedName } else { $item.Name }
        # StartupApproved: primer byte impar = desactivado (como lo deja el Administrador de tareas).
        $approved = @(Get-AfRegistryValue -Path $item.ApprovedPath -Name $approvedName -User $User)
        $disabled = $approved.Count -gt 0 -and $null -ne $approved[0] -and ([int]$approved[0] -band 1) -eq 1
        $path = Get-AfCommandPath -Command $item.Command
        $signature = Get-AfFileSignature -Path $path
        [pscustomobject]@{
            Name = $item.Name
            Command = $item.Command
            Path = $path
            Source = if ($item.PSObject.Properties['Source'] -and $item.Source) { $item.Source } else { 'Run' }
            Scope = $item.Scope
            Enabled = -not $disabled
            ApprovedKey = $item.ApprovedPath
            ApprovedName = $approvedName
            IsSigned = $signature.IsSigned
            Signer = $signature.Signer
            InUserWritablePath = Test-AfUserWritablePath -Path $path
        }
    }
}

# Todo lo que arranca solo: inicio, servicios automáticos y tareas programadas que no son de Microsoft.
function Get-AfAutostartBinaries {
    param($User)
    $windows = $env:windir.TrimEnd('\') + '\'
    $result = @(Get-AfStartupEntries -User $User | Where-Object Enabled)

    foreach ($service in @(Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto'" -OperationTimeoutSec 15 -ErrorAction SilentlyContinue)) {
        $path = Get-AfCommandPath -Command $service.PathName
        if (-not $path -or $path.StartsWith($windows, [StringComparison]::OrdinalIgnoreCase)) { continue }
        $signature = Get-AfFileSignature -Path $path
        if ($signature.Signer -match 'Microsoft') { continue }
        $result += [pscustomobject]@{ Name = [string]$service.DisplayName; Command = [string]$service.PathName; Path = $path; Source = 'Service'; Scope = 'Machine'; Enabled = $true; IsSigned = $signature.IsSigned; Signer = $signature.Signer; InUserWritablePath = Test-AfUserWritablePath -Path $path }
    }

    foreach ($task in @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -ne 'Disabled' -and $_.TaskPath -notlike '\Microsoft\*' })) {
        foreach ($action in @($task.Actions | Where-Object { $_.Execute })) {
            $path = Get-AfCommandPath -Command $action.Execute
            if (-not $path -or $path.StartsWith($windows, [StringComparison]::OrdinalIgnoreCase)) { continue }
            $signature = Get-AfFileSignature -Path $path
            if ($signature.Signer -match 'Microsoft') { continue }
            $result += [pscustomobject]@{ Name = [string]$task.TaskName; Command = [string]$action.Execute; Path = $path; Source = 'Task'; Scope = 'Machine'; Enabled = $true; IsSigned = $signature.IsSigned; Signer = $signature.Signer; InUserWritablePath = Test-AfUserWritablePath -Path $path }
        }
    }
    $result
}
