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

function Test-AfCountsForScore {
    param($Result)
    $Result.Check.Kind -eq 'Auto' -and $Result.Check.Category -ne 'optional' -and $Result.Detection.State -in 'Ok', 'Improvable'
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
        Ready = @($Results | Where-Object { $_.Check.Kind -eq 'Auto' -and $_.Check.Category -ne 'optional' -and $_.Detection.State -eq 'Improvable' }).Count
        Manual = @($Results | Where-Object { $_.Detection.State -eq 'Manual' }).Count
        Ok = @($Results | Where-Object { $_.Detection.State -eq 'Ok' }).Count
        Optional = @($Results | Where-Object { $_.Check.Category -eq 'optional' -and $_.Detection.State -eq 'Improvable' }).Count
    }
}
