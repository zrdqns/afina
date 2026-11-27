# Respaldos: una sesión por cada vez que se aplica, en %ProgramData%\Afina\respaldos\<fecha>.json (diseño, sección 11).
function Get-AfBackupDirectory {
    Join-Path $env:ProgramData 'Afina\respaldos'
}

function Save-AfSession {
    param([Parameter(Mandatory)]$Session)
    $data = $Session | Select-Object -Property * -ExcludeProperty Path
    $json = ConvertTo-Json -InputObject $data -Depth 10
    # Se escribe aparte y se reemplaza: un corte a mitad de escritura no deja el respaldo dañado.
    $temporary = $Session.Path + '.tmp'
    [System.IO.File]::WriteAllText($temporary, $json, (New-Object System.Text.UTF8Encoding($false)))
    # Un antivirus o el indexador pueden tener el respaldo abierto un instante: hasta 3 intentos, solo ante IOException.
    for ($attempt = 1; ; $attempt++) {
        try {
            # [NullString]::Value: un $null de PowerShell llegaría a .NET como "" y Replace lo rechaza como ruta.
            if ([System.IO.File]::Exists($Session.Path)) { [System.IO.File]::Replace($temporary, $Session.Path, [NullString]::Value) } else { [System.IO.File]::Move($temporary, $Session.Path) }
            return
        } catch [System.IO.IOException] {
            if ($attempt -ge 3) { throw }
            Start-Sleep -Milliseconds 200
        }
    }
}

# Se escribe enseguida: si no se puede guardar el respaldo, no se aplica nada.
function New-AfSession {
    param([Parameter(Mandatory)][string]$Directory, $User, [string]$Version = (Get-AfVersion), [datetime]$Now = (Get-Date))
    $id = $Now.ToString('yyyy-MM-dd_HHmmss')
    $sid = if ($User -and $User.Sid) { $User.Sid } else { (Get-AfUserForSid).Sid }
    $session = [pscustomobject]@{
        Format = 1
        Id = $id
        Version = $Version
        Language = Get-AfLanguage
        Machine = $env:COMPUTERNAME
        User = [pscustomobject]@{ Name = if ($User) { $User.Name } else { $null }; Sid = $sid }
        StartedAt = $Now.ToString('o')
        RestorePoint = $null
        Changes = New-Object System.Collections.ArrayList
        Path = $null
    }
    try {
        New-Item -ItemType Directory -Force -Path $Directory -ErrorAction Stop | Out-Null
        $path = Join-Path $Directory "$id.json"
        $n = 2
        while ([System.IO.File]::Exists($path)) {
            $session.Id = '{0}-{1}' -f $id, $n
            $path = Join-Path $Directory ($session.Id + '.json')
            $n++
        }
        $session.Path = $path
        Save-AfSession -Session $session
    } catch {
        Write-AfLog -Level Error -Message "No se pudo crear el respaldo en ${Directory}: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'no se pudo guardar el respaldo en ProgramData\Afina\respaldos'))
    }
    $session
}

function Import-AfSession {
    param([Parameter(Mandatory)][string]$Path)
    $data = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Path))
    if (-not $data.Id -or $null -eq $data.PSObject.Properties['Changes']) { throw ((T 'No es un respaldo de Afina: {0}') -f $Path) }
    $changes = New-Object System.Collections.ArrayList
    foreach ($change in @($data.Changes)) { if ($null -ne $change) { [void]$changes.Add($change) } }
    $data.Changes = $changes
    $data | Add-Member -NotePropertyName Path -NotePropertyValue $Path -Force
    $data
}

function Get-AfSessions {
    param([string]$Directory = (Get-AfBackupDirectory), [int]$Max = 30)
    if (-not [System.IO.Directory]::Exists($Directory)) { return @() }
    $sessions = foreach ($file in @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File -ErrorAction SilentlyContinue)) {
        try { Import-AfSession -Path $file.FullName } catch { Write-AfLog -Level Warn -Message "Respaldo dañado o ajeno: $($file.Name)" }
    }
    $order = { try { [datetimeoffset]::Parse([string]$_.StartedAt, [System.Globalization.CultureInfo]::InvariantCulture) } catch { [datetimeoffset]::MinValue } }
    @($sessions | Sort-Object -Property $order -Descending | Select-Object -First $Max)
}

function Get-AfSessionSummary {
    param([Parameter(Mandatory)]$Session)
    $changes = @($Session.Changes)
    [pscustomobject]@{
        Applied = @($changes | Where-Object { $_.Status -in 'Applied', 'UndoFailed' }).Count
        Undone = @($changes | Where-Object { $_.Status -eq 'Undone' }).Count
        Failed = @($changes | Where-Object { $_.Status -eq 'Failed' }).Count
        Undoable = @($changes | Where-Object { Test-AfChangeUndoable -Change $_ }).Count
    }
}
