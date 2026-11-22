# Windows Update por su API COM, en un trabajo aislado: si un paso se traba, Afina deja de esperarlo (Core\Jobs.ps1).
# BrowseOnly=0: solo las que Windows no considera opcionales, o sea las que instalaría solo.
$script:AfUpdateCriteria = "IsInstalled=0 and IsHidden=0 and Type='Software' and BrowseOnly=0"

# Corre en otro runspace: no usa funciones de Afina. Anota en $Sync lo que va haciendo (Found, Results, Stage, Beat).
$script:AfWindowsUpdateJob = @'
param($Sync, [string]$Mode, [string]$Criteria)
# Cualquier falla corta el trabajo (sin esto, una llamada COM que falla solo corta su línea y la búsqueda diría "Al día").
$ErrorActionPreference = 'Stop'
# Clasificación Upgrades (versiones nuevas de Windows): no se instalan desde Afina.
$upgrades = '3689bdc8-b205-4af4-8d4a-a63924c5e9d5'
$Sync.Results = @()
# Textos del avance: llegan traducidos desde afuera (aquí no hay funciones de Afina).
$texts = if ($Sync.Texts) { $Sync.Texts } else { @{ Search = 'Buscando actualizaciones'; Download = 'Descargando {0} de {1}'; Install = 'Instalando {0} de {1}' } }
$Sync.Stage = $texts.Search
$Sync.Beat = [datetime]::UtcNow
$session = New-Object -ComObject Microsoft.Update.Session
$session.ClientApplicationID = 'Afina'
$found = $session.CreateUpdateSearcher().Search($Criteria).Updates
$updates = @()
for ($i = 0; $i -lt $found.Count; $i++) {
    $update = $found.Item($i)
    $isUpgrade = $false
    foreach ($category in $update.Categories) { if ([string]$category.CategoryID -eq $upgrades) { $isUpgrade = $true } }
    if (-not $isUpgrade -and -not $update.InstallationBehavior.CanRequestUserInput) { $updates += $update }
}
$Sync.Found = $updates.Count
if ($Mode -eq 'Search') { return @{ Titles = @($updates | ForEach-Object { [string]$_.Title }) } }
for ($i = 0; $i -lt $updates.Count; $i++) {
    $update = $updates[$i]
    $one = New-Object -ComObject Microsoft.Update.UpdateColl
    if (-not $update.EulaAccepted) { $update.AcceptEula() }
    [void]$one.Add($update)
    $entry = @{ Title = [string]$update.Title; Ok = $false; HResult = 0; RebootRequired = $false }
    if (-not $update.IsDownloaded) {
        $Sync.Stage = $texts.Download -f ($i + 1), $updates.Count
        $Sync.Beat = [datetime]::UtcNow
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $one
        $download = $downloader.Download()
        # ResultCode 2 = bien, 3 = bien con errores.
        if ($download.ResultCode -notin 2, 3) {
            $entry.HResult = [int]$download.HResult
            $Sync.Results = @($Sync.Results) + @($entry)
            continue
        }
    }
    $Sync.Stage = $texts.Install -f ($i + 1), $updates.Count
    $Sync.Beat = [datetime]::UtcNow
    $installer = $session.CreateUpdateInstaller()
    $installer.AllowSourcePrompts = $false
    $installer.Updates = $one
    $install = $installer.Install()
    $entry.Ok = $install.ResultCode -in 2, 3
    $entry.HResult = [int]$install.HResult
    $entry.RebootRequired = [bool]$install.RebootRequired
    $Sync.Results = @($Sync.Results) + @($entry)
}
'@

function ConvertTo-AfUpdateReason {
    param($HResult)
    if (-not $HResult) { return (T 'Windows Update no respondió como se esperaba') }
    $code = [int64]$HResult -band 0xFFFFFFFFL
    switch ($code) {
        0x80070422L { return (T 'el servicio de Windows Update está desactivado') }
        { $_ -in 0x8024402CL, 0x80072EE2L, 0x80072EE7L, 0x80072EFDL } { return (T 'no hay conexión con Windows Update') }
        0x80072F8FL { return (T 'no se pudo abrir una conexión segura con Windows Update') }
        0x80240016L { return (T 'Windows Update está instalando otra cosa o espera un reinicio') }
        0x8024001EL { return (T 'Windows Update se detuvo') }
    }
    (T 'Windows Update devolvió el código 0x{0:X8}') -f $code
}

# Lento (de segundos a minutos): lo usa la búsqueda en segundo plano del análisis.
function Find-AfWindowsUpdates {
    param([string]$Script = $script:AfWindowsUpdateJob, [int]$StallSeconds = 300)
    $job = Invoke-AfIsolatedJob -Script $Script -Parameters @{ Mode = 'Search'; Criteria = $script:AfUpdateCriteria } -StallSeconds $StallSeconds
    $none = [pscustomobject]@{ Count = 0; Titles = @(); TimedOut = [bool]$job.TimedOut; Reason = $null }
    if ($job.TimedOut) { $none.Reason = (T 'Windows Update no respondió a tiempo'); return $none }
    if ($job.Error) { $none.Reason = ConvertTo-AfUpdateReason -HResult $job.HResult; return $none }
    $titles = @($job.Result.Titles | Where-Object { $_ })
    [pscustomobject]@{ Count = $titles.Count; Titles = $titles; TimedOut = $false; Reason = $null }
}

# Sin deshacer: queda un registro Action con lo instalado. Si un paso se traba, lo ya instalado queda anotado.
function Install-AfWindowsUpdates {
    param([Parameter(Mandatory)]$Tx, [string]$Script = $script:AfWindowsUpdateJob, [int]$StallSeconds = 3600)
    # El avance va directo: un closure (GetNewClosure) no encuentra las funciones de Afina fuera del ámbito global.
    $texts = @{ Search = (T 'Buscando actualizaciones'); Download = (T 'Descargando {0} de {1}'); Install = (T 'Instalando {0} de {1}') }
    $job = Invoke-AfIsolatedJob -Script $Script -Parameters @{ Mode = 'Install'; Criteria = $script:AfUpdateCriteria } -State @{ Texts = $texts } -StallSeconds $StallSeconds -OnStage $Tx.Progress
    $results = @($job.Sync.Results | Where-Object { $_ })
    $found = $job.Sync.Found
    if ($job.Done -and -not $job.Error -and $found -eq 0) {
        $Tx.NeedsReboot = $false
        [void]$Tx.Notes.Add((T 'Ya estaba al día.'))
        return $false
    }
    $ok = @($results | Where-Object { $_.Ok })
    $failed = @($results | Where-Object { -not $_.Ok })
    if (-not $ok.Count) {
        $reason = if ($failed.Count) { ConvertTo-AfUpdateReason -HResult $failed[0].HResult } elseif ($job.TimedOut) { (T 'Windows Update dejó de responder') } else { ConvertTo-AfUpdateReason -HResult $job.HResult }
        throw (New-AfApplyError -Reason $reason)
    }
    $total = if ($found) { [int]$found } else { $results.Count }
    $detail = (T 'Se instalaron {0} de {1}') -f $ok.Count, $total
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'Action'; Name = (T 'Actualizaciones de Windows'); Detail = $detail
        Installed = @($ok | ForEach-Object { $_.Title }); Failed = @($failed | ForEach-Object { $_.Title })
    }
    [void]$Tx.Notes.Add($detail + '.')
    if ($failed.Count) { [void]$Tx.Notes.Add((T 'No se pudieron: {0}.') -f (@($failed | ForEach-Object { $_.Title }) -join ', ')) }
    if ($job.TimedOut) { [void]$Tx.Notes.Add((T 'Windows Update dejó de responder; lo que falta sigue en Configuración.')) }
    elseif ($job.Error) { [void]$Tx.Notes.Add((T 'Windows Update se detuvo ({0}); lo que falta sigue en Configuración.') -f (ConvertTo-AfUpdateReason -HResult $job.HResult)) }
    $Tx.NeedsReboot = [bool]@($ok | Where-Object { $_.RebootRequired }).Count
    $true
}

# Códigos de salida de winget (tabla oficial: winget-cli, doc\windows\package-manager\winget\returnCodes.md).
function Get-AfWingetOutcome {
    param([int]$ExitCode)
    $outcome = { param($Ok, $Reboot, $Reason) [pscustomobject]@{ Ok = $Ok; Reboot = $Reboot; Reason = $Reason } }
    switch ($ExitCode) {
        0 { return & $outcome $true $false $null }
        -1978335189 { return & $outcome $true $false (T 'ya estaba al día') }               # 0x8A15002B UPDATE_NOT_APPLICABLE
        { $_ -in -1978334967, -1978334965 } { return & $outcome $true $true $null }    # 0x8A150109 y 0x8A15010B: reinicio
        -1978334966 { return & $outcome $false $false (T 'hay que reiniciar la PC antes') } # 0x8A15010A
        { $_ -in -1978334975, -1978334973 } { return & $outcome $false $false (T 'la app está abierta') }  # 0x8A150101, 0x8A150103
        -1978334974 { return & $outcome $false $false (T 'hay otra instalación en curso') } # 0x8A150102
        -1978334971 { return & $outcome $false $false (T 'no queda espacio en el disco') }  # 0x8A150105
        -1978334969 { return & $outcome $false $false (T 'no hay conexión a internet') }    # 0x8A150107
        -1978334961 { return & $outcome $false $false (T 'una directiva de la organización lo impide') }  # 0x8A15010F
        -1978335128 { return & $outcome $false $false (T 'la app está fijada en su versión') }  # 0x8A150068
        { $_ -in -1978335216, -1978335212 } { return & $outcome $false $false (T 'winget no tiene un instalador para esta PC') }  # 0x8A150010, 0x8A150014
        # 0x8A150056 (el instalador no acepta administrador) y 0x8A15007D (instalada solo para el usuario).
        { $_ -in -1978335146, -1978335107 } { return & $outcome $false $false (T 'no se puede actualizar como administrador; se actualiza desde la propia app') }
    }
    & $outcome $false $false ((T 'winget devolvió el código 0x{0:X8}') -f $ExitCode)
}

# Sin deshacer: queda un registro Action. Si una app falla, sigue con las demás.
function Update-AfWingetApps {
    param([Parameter(Mandatory)]$Tx, [object[]]$Apps = @(), [int]$TimeoutMinutes = 15)
    if (-not $Apps.Count) { return $false }
    # App Installer es el propio winget: si se actualiza antes, las siguientes llamadas pueden fallar.
    $self = 'Microsoft.AppInstaller', '9NBLGGH4NNS1'
    $Apps = @($Apps | Where-Object { $_.Id -notin $self }) + @($Apps | Where-Object { $_.Id -in $self })
    $winget = Get-AfWingetPath
    if (-not $winget) { throw (New-AfApplyError -Reason (T 'winget no está instalado')) }
    $updated = @(); $failed = @(); $reboot = $false
    for ($i = 0; $i -lt $Apps.Count; $i++) {
        $app = $Apps[$i]
        Set-AfTxProgress -Tx $Tx -Text ((T 'Actualizando {0} de {1}: {2}') -f ($i + 1), $Apps.Count, $app.Name)
        $source = if ($app.Source) { ' --source {0}' -f $app.Source } else { '' }
        $arguments = 'upgrade --id "{0}" --exact{1} --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' -f $app.Id, $source
        $result = Invoke-AfProcess -FilePath $winget -Arguments $arguments -TimeoutMs ($TimeoutMinutes * 60000) -Encoding ([System.Text.Encoding]::UTF8)
        $outcome = if ($result.TimedOut) { [pscustomobject]@{ Ok = $false; Reboot = $false; Reason = ((T 'winget no terminó en {0} min') -f $TimeoutMinutes) } } else { Get-AfWingetOutcome -ExitCode $result.ExitCode }
        if ($outcome.Ok) {
            $updated += $app.Name
            if ($outcome.Reboot) { $reboot = $true }
        } else {
            Write-AfLog -Level Warn -Message ('winget {0}: {1} (código {2})' -f $app.Id, $outcome.Reason, $result.ExitCode)
            $failed += [pscustomobject]@{ Name = $app.Name; Reason = $outcome.Reason }
        }
    }
    if (-not $updated.Count) {
        $reasons = @($failed | ForEach-Object { $_.Reason } | Select-Object -Unique)
        $reason = if ($reasons.Count -eq 1) { $reasons[0] } else { (T 'ninguna app se pudo actualizar') }
        throw (New-AfApplyError -Reason $reason)
    }
    $detail = (T 'Se actualizaron {0} de {1}') -f $updated.Count, $Apps.Count
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'Action'; Name = 'Apps'; Detail = $detail; Updated = $updated; Failed = @($failed | ForEach-Object { $_.Name }) }
    [void]$Tx.Notes.Add($detail + '.')
    foreach ($f in $failed) { [void]$Tx.Notes.Add(((T 'No se pudo con {0}: {1}.') -f $f.Name, $f.Reason)) }
    $Tx.NeedsReboot = $reboot
    $true
}