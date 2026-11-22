function Get-AfWingetPath {
    $winget = Get-Command -Name 'winget' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($winget) { $winget.Source } else { $null }
}

function Get-AfWingetUpgrades {
    $winget = Get-AfWingetPath
    if (-not $winget) { return [pscustomobject]@{ Available = $false; TimedOut = $false; Apps = @() } }
    $result = Invoke-AfProcess -FilePath $winget -Arguments 'upgrade --accept-source-agreements --disable-interactivity' -TimeoutMs 60000 -Encoding ([System.Text.Encoding]::UTF8)
    if ($result.TimedOut) { return [pscustomobject]@{ Available = $true; TimedOut = $true; Apps = @() } }
    [pscustomobject]@{ Available = $true; TimedOut = $false; Apps = @(ConvertFrom-AfWingetUpgrade -Text $result.Output) }
}
