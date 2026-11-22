# Apps de la Store para el usuario del proceso. Deshacer las registra de nuevo si siguen en la PC
# (aprovisionadas o de otra cuenta) o las reinstala desde la Microsoft Store con winget.
function Test-AfAppxStaged {
    param([Parameter(Mandatory)][string]$PackageName)
    try { if (@(Get-AppxPackage -AllUsers -Name $PackageName -ErrorAction Stop).Count) { return $true } } catch { }
    try { return [bool]@(Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object { $_.DisplayName -eq $PackageName }).Count } catch { }
    $false
}

function Remove-AfAppxPackage {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)]$App)
    $installed = @(Get-AppxPackage -Name $App.PackageName -ErrorAction SilentlyContinue)
    if (-not $installed.Count) { return $false }
    try {
        Remove-AppxPackage -Package $installed[0].PackageFullName -ErrorAction Stop
    } catch {
        Write-AfLog -Level Warn -Message ('Remove-AppxPackage {0}: {1}' -f $installed[0].PackageFullName, $_.Exception.Message)
        throw (New-AfApplyError -Reason ((T 'Windows no dejó quitar {0}') -f $App.Name))
    }
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'AppxPackage'; Name = $App.Name; PackageName = $App.PackageName; PackageFamilyName = $installed[0].PackageFamilyName
        StoreId = $App.StoreId; Previous = 'Installed'; New = 'Removed'
    }
    $true
}

function Restore-AfAppxPackage {
    param([Parameter(Mandatory)]$Record, $User)
    if (@(Get-AppxPackage -Name $Record.PackageName -ErrorAction SilentlyContinue).Count) { return }
    if (Test-AfAppxStaged -PackageName $Record.PackageName) {
        try {
            Add-AppxPackage -RegisterByFamilyName -MainPackage $Record.PackageFamilyName -ErrorAction Stop
            return
        } catch {
            Write-AfLog -Level Warn -Message ('No se pudo registrar {0}: {1}' -f $Record.PackageFamilyName, $_.Exception.Message)
        }
    }
    $winget = if ($Record.StoreId) { Get-AfWingetPath }
    if (-not $winget) { throw (New-AfApplyError -Reason (T 'ya no está en la PC; se reinstala desde la Microsoft Store')) }
    $arguments = 'install --id {0} --source msstore --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' -f $Record.StoreId
    $result = Invoke-AfProcess -FilePath $winget -Arguments $arguments -TimeoutMs 900000 -Encoding ([System.Text.Encoding]::UTF8)
    $outcome = if ($result.TimedOut) { [pscustomobject]@{ Ok = $false; Reason = (T 'winget no terminó en 15 min') } } else { Get-AfWingetOutcome -ExitCode $result.ExitCode }
    if (-not $outcome.Ok) { throw (New-AfApplyError -Reason ((T 'no se pudo reinstalar {0} desde la Microsoft Store: {1}') -f $Record.Name, $outcome.Reason)) }
}

function Get-AfAppxPackageState {
    param([Parameter(Mandatory)]$Record, $User)
    if (@(Get-AppxPackage -Name $Record.PackageName -ErrorAction SilentlyContinue).Count) { 'Installed' } else { 'Removed' }
}
