# Características opcionales de Windows con dism.exe: /English deja la salida igual en cualquier idioma.
# Por su ruta completa: por nombre, Windows lo buscaría antes en la carpeta actual (por ejemplo, la USB).
function Get-AfDismPath { Join-Path $env:SystemRoot 'System32\dism.exe' }

function Get-AfFeatureInfo {
    param([Parameter(Mandatory)][string]$Name)
    $result = Invoke-AfProcess -FilePath (Get-AfDismPath) -Arguments ('/Online /English /Get-FeatureInfo /FeatureName:{0}' -f $Name) -TimeoutMs 120000
    if ($result.TimedOut) { throw (New-AfApplyError -Reason (T 'DISM no respondió')) }
    $info = ConvertFrom-AfDismFeatureInfo -Text $result.Output
    if ($result.ExitCode -ne 0 -or -not $info.State) { throw (New-AfApplyError -Reason ((T 'DISM no pudo leer {0} (código {1})') -f $Name, $result.ExitCode)) }
    $info
}

function Invoke-AfFeatureChange {
    param([Parameter(Mandatory)][string]$Name, [bool]$Enabled)
    $verb = if ($Enabled) { 'Enable' } else { 'Disable' }
    $result = Invoke-AfProcess -FilePath (Get-AfDismPath) -Arguments ('/Online /English /{0}-Feature /FeatureName:{1} /NoRestart /Quiet' -f $verb, $Name) -TimeoutMs 600000
    if ($result.TimedOut) { throw (New-AfApplyError -Reason (T 'DISM no terminó a tiempo')) }
    # 3010: hecho, falta reiniciar.
    if ($result.ExitCode -notin 0, 3010) {
        Write-AfLog -Level Warn -Message ('dism {0}-Feature {1}: código {2}. {3}' -f $verb, $Name, $result.ExitCode, $result.Output)
        throw (New-AfApplyError -Reason ((T 'DISM no aceptó el cambio (código {0})') -f $result.ExitCode))
    }
}

function Set-AfWindowsFeature {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][bool]$Enabled)
    $target = if ($Enabled) { 'Enabled' } else { 'Disabled' }
    $previous = (Get-AfFeatureInfo -Name $Name).State
    if ($previous -eq $target) { return $false }
    Invoke-AfFeatureChange -Name $Name -Enabled $Enabled
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'WindowsFeature'; Name = $Name; Previous = $previous; New = $target }
    $Tx.NeedsReboot = $true
    $true
}

function Restore-AfWindowsFeature {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfFeatureChange -Name $Record.Name -Enabled ($Record.Previous -eq 'Enabled')
}

function Get-AfWindowsFeatureState {
    param([Parameter(Mandatory)]$Record, $User)
    (Get-AfFeatureInfo -Name $Record.Name).State
}
