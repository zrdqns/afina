function Get-AfMpPreferenceValue {
    param([Parameter(Mandatory)][string]$Name)
    try { (Get-MpPreference -ErrorAction Stop).$Name } catch {
        Write-AfLog -Level Warn -Message "Get-MpPreference: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'Microsoft Defender no respondió'))
    }
}

function Invoke-AfMpPreference {
    param([Parameter(Mandatory)][string]$Name, $Value)
    $arguments = @{ $Name = $Value; ErrorAction = 'Stop' }
    try { Set-MpPreference @arguments } catch {
        Write-AfLog -Level Warn -Message "Set-MpPreference ${Name}: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'Microsoft Defender no aceptó el cambio'))
    }
}

function Set-AfMpPreference {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)]$Value)
    $previous = Get-AfMpPreferenceValue -Name $Name
    if ((ConvertTo-AfComparable $previous) -eq (ConvertTo-AfComparable $Value)) { return $false }
    Invoke-AfMpPreference -Name $Name -Value $Value
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'MpPreference'; Name = $Name; Previous = $previous; New = $Value }
    $true
}

function Restore-AfMpPreference {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfMpPreference -Name $Record.Name -Value $Record.Previous
}

function Get-AfMpPreferenceState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfMpPreferenceValue -Name $Record.Name
}

# Con la protección contra alteraciones, Set-MpPreference no falla pero tampoco cambia nada: se comprueba.
function Enable-AfDefenderRealtime {
    param([Parameter(Mandatory)]$Tx, [int]$WaitSeconds = 5)
    Set-AfMpPreference -Tx $Tx -Name 'DisableRealtimeMonitoring' -Value $false | Out-Null
    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    do {
        try { if ((Get-MpComputerStatus -ErrorAction Stop).RealTimeProtectionEnabled) { return } } catch { }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)
    throw (New-AfApplyError -Reason (T 'la protección contra alteraciones no dejó encenderla; actívala en Seguridad de Windows, Protección contra virus y amenazas'))
}

function Update-AfDefenderSignatures {
    param([Parameter(Mandatory)]$Tx)
    $tool = Join-Path $env:ProgramFiles 'Windows Defender\MpCmdRun.exe'
    $ok = $true
    if (Test-Path -LiteralPath $tool) {
        $result = Invoke-AfProcess -FilePath $tool -Arguments '-SignatureUpdate' -TimeoutMs 300000
        $ok = -not $result.TimedOut -and $result.ExitCode -eq 0
        if (-not $ok) { Write-AfLog -Level Warn -Message ('MpCmdRun -SignatureUpdate: código {0}. {1}' -f $result.ExitCode, $result.Output) }
    } else {
        try { Update-MpSignature -ErrorAction Stop } catch { $ok = $false; Write-AfLog -Level Warn -Message "Update-MpSignature: $($_.Exception.Message)" }
    }
    if (-not $ok) { throw (New-AfApplyError -Reason (T 'no se pudieron descargar las firmas; revisa la conexión a internet')) }
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'Action'; Name = 'Firmas'; Detail = (T 'Firmas al día') }
    [void]$Tx.Notes.Add((T 'Firmas al día.'))
}

function Get-AfFirewallProfileEnabled {
    param([Parameter(Mandatory)][string]$Profile)
    try { [string](Get-NetFirewallProfile -Name $Profile -ErrorAction Stop).Enabled } catch {
        Write-AfLog -Level Warn -Message "Get-NetFirewallProfile ${Profile}: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'el Firewall de Windows no respondió'))
    }
}

function Invoke-AfFirewallProfile {
    param([Parameter(Mandatory)][string]$Profile, [Parameter(Mandatory)][string]$Enabled)
    try { Set-NetFirewallProfile -Name $Profile -Enabled $Enabled -ErrorAction Stop } catch {
        Write-AfLog -Level Warn -Message "Set-NetFirewallProfile $Profile ${Enabled}: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'el Firewall de Windows no aceptó el cambio'))
    }
}

function Set-AfFirewallProfile {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Profile, [Parameter(Mandatory)][bool]$Enabled)
    $previous = Get-AfFirewallProfileEnabled -Profile $Profile
    $target = if ($Enabled) { 'True' } else { 'False' }
    if ($previous -eq $target) { return $false }
    Invoke-AfFirewallProfile -Profile $Profile -Enabled $target
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'FirewallProfile'; Profile = $Profile; Previous = $previous; New = $target }
    $true
}

function Restore-AfFirewallProfile {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfFirewallProfile -Profile $Record.Profile -Enabled ([string]$Record.Previous)
}

function Get-AfFirewallProfileState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfFirewallProfileEnabled -Profile $Record.Profile
}
