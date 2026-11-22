function Get-AfWeight {
    param([string]$Impact)
    switch ($Impact) { 'High' { 3 } 'Medium' { 2 } default { 1 } }
}

function Invoke-AfCheck {
    param([Parameter(Mandatory)][hashtable]$Check, [Parameter(Mandatory)]$Inventory)
    try {
        if ($Check.AppliesTo -and -not (& $Check.AppliesTo $Inventory)) {
            $detection = New-AfDetection -State NotApplicable
        } else {
            $detection = & $Check.Detect $Inventory
            if (-not $detection) { throw (T 'La revisión no devolvió resultado.') }
        }
    } catch {
        $detection = New-AfDetection -State Error -Note $_.Exception.Message
        Write-AfLog -Level Warn -Message "Revisión $($Check.Id): $($_.Exception.Message)"
    }
    $preselect = if ($null -ne $detection.Preselect) { [bool]$detection.Preselect } else { [bool]$Check.Preselect }
    [pscustomobject]@{
        Check = $Check
        Detection = $detection
        Weight = Get-AfWeight -Impact $Check.Impact
        Preselected = $preselect -and $detection.State -eq 'Improvable' -and (Test-AfCanApply -Check $Check)
    }
}

# Las categorías optional y windows no mueven la aguja ni cuentan como listas.
function Test-AfIsScoredCategory {
    param([string]$Category)
    $Category -notin 'optional', 'windows'
}

function Test-AfCountsForScore {
    param($Result)
    $Result.Check.Kind -eq 'Auto' -and (Test-AfIsScoredCategory -Category $Result.Check.Category) -and
        ($Result.Detection.State -eq 'Ok' -or ($Result.Detection.State -eq 'Improvable' -and $Result.Preselected))
}

function Test-AfIsReady {
    param($Result)
    $Result.Check.Kind -eq 'Auto' -and (Test-AfIsScoredCategory -Category $Result.Check.Category) -and
        $Result.Detection.State -eq 'Improvable' -and [bool]$Result.Preselected
}

# Una lectura (Reading) sigue visible en Ok pero no cuenta como "En orden".
function Test-AfOkRow {
    param($Result)
    $Result.Detection.State -eq 'Ok' -and -not $Result.Check.Reading
}

function Test-AfRowPending {
    param($Result)
    $Result.Detection.State -in 'Improvable', 'Manual', 'Error' -or ($Result.Detection.State -eq 'Info' -and -not $Result.Check.Reading)
}

# Posición de la aguja: peso en orden / peso de las revisiones automáticas que cuentan (sección 9 del diseño).
function Get-AfScore {
    param([object[]]$Results = @())
    $counted = @($Results | Where-Object { Test-AfCountsForScore $_ })
    $total = ($counted | Measure-Object -Property Weight -Sum).Sum
    if (-not $total) { return 1.0 }
    $ok = (@($counted | Where-Object { $_.Detection.State -eq 'Ok' }) | Measure-Object -Property Weight -Sum).Sum
    [double]$ok / $total
}

function Get-AfSummary {
    param([object[]]$Results = @())
    [pscustomobject]@{
        Ready = @($Results | Where-Object { Test-AfIsReady $_ }).Count
        Manual = @($Results | Where-Object { $_.Detection.State -eq 'Manual' }).Count
        Ok = @($Results | Where-Object { Test-AfOkRow $_ }).Count
        Optional = @($Results | Where-Object { $_.Check.Category -eq 'optional' -and $_.Detection.State -eq 'Improvable' }).Count
    }
}

# Título del veredicto y si se celebra. Sin fila de disco, el disco cuenta como leído.
function Get-AfVerdict {
    param([object[]]$Results = @())
    $disk = @($Results | Where-Object { $_.Check.Id -eq 'hardware.disk-health' })[0]
    if ($disk -and $disk.Detection.State -eq 'Manual') {
        return [pscustomobject]@{ Title = (T 'Revisa el disco'); Celebrate = $false }
    }
    $reading = $disk -and $disk.Detection.Data -and $disk.Detection.Data.Async
    $tuned = (Get-AfScore -Results $Results) -ge 0.999 -and (Get-AfSummary -Results $Results).Ready -eq 0 -and -not $reading
    [pscustomobject]@{ Title = $(if ($tuned) { T 'Afinada' } else { T 'Afinación' }); Celebrate = [bool]$tuned }
}
