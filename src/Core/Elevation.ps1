function Test-AfAdmin {
    $principal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
    [bool]$principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AfRelaunchArguments {
    param([string]$ScriptPath, [Parameter(Mandatory)][string]$OneLinerUrl, [string[]]$Extra = @())
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass')
    if ($ScriptPath) {
        $arguments += @('-File', ('"{0}"' -f $ScriptPath))
    } else {
        $arguments += @('-Command', ('"irm {0} | iex"' -f $OneLinerUrl))
    }
    $arguments + $Extra
}

function Restart-AfElevated {
    param([Parameter(Mandatory)][string[]]$Arguments)
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $Arguments
}
