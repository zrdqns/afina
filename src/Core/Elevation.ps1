function Test-AfAdmin {
    $principal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
    [bool]$principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Solo desde un archivo (USB): con "irm … | iex" no se relanza (ver Main.ps1).
function Get-AfRelaunchArguments {
    param([Parameter(Mandatory)][string]$ScriptPath, [string[]]$Extra = @())
    @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $ScriptPath)) + $Extra
}

function Restart-AfElevated {
    param([Parameter(Mandatory)][string[]]$Arguments)
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $Arguments
}
