function Get-AfInteractiveUser {
    $current = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $sid = $current.User.Value
    $name = $current.Name
    try {
        $sessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
        $explorer = Get-CimInstance -ClassName Win32_Process -Filter "Name='explorer.exe'" -OperationTimeoutSec 15 |
            Where-Object { $_.SessionId -eq $sessionId } | Select-Object -First 1
        if ($explorer) {
            $ownerSid = Invoke-CimMethod -InputObject $explorer -MethodName GetOwnerSid -OperationTimeoutSec 15
            if ($ownerSid.Sid) {
                $sid = $ownerSid.Sid
                $owner = Invoke-CimMethod -InputObject $explorer -MethodName GetOwner -OperationTimeoutSec 15
                if ($owner.User) { $name = if ($owner.Domain) { '{0}\{1}' -f $owner.Domain, $owner.User } else { $owner.User } }
            }
        }
    } catch {
        Write-AfLog -Level Warn -Message "No se pudo leer el usuario de la sesión: $($_.Exception.Message)"
    }

    $isSame = $sid -eq $current.User.Value
    $profilePath = $null
    try {
        $profilePath = (Get-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid" -ErrorAction Stop).ProfileImagePath
    } catch { }

    [pscustomobject]@{
        Name = $name
        Sid = $sid
        ProfilePath = $profilePath
        IsSameAsProcess = $isSame
        HkcuRoot = if ($isSame) { 'HKCU:' } else { "Registry::HKEY_USERS\$sid" }
    }
}
