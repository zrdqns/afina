$script:AfLogLines = New-Object System.Collections.Generic.List[string]
$script:AfLogPath = $null

function Start-AfLog {
    param([Parameter(Mandatory)][string]$Directory)
    try {
        New-Item -ItemType Directory -Force -Path $Directory | Out-Null
        $path = Join-Path $Directory ((Get-Date -Format 'yyyy-MM-dd_HHmmss') + '.log')
        [System.IO.File]::WriteAllText($path, '', (New-Object System.Text.UTF8Encoding($true)))
        $script:AfLogPath = $path
    } catch {
        $script:AfLogPath = $null
    }
    $script:AfLogPath
}

function Write-AfLog {
    param(
        [ValidateSet('Info', 'Warn', 'Error')][string]$Level = 'Info',
        [Parameter(Mandatory)][string]$Message
    )
    $line = '{0} {1,-5} {2}' -f (Get-Date -Format 'HH:mm:ss.fff'), $Level.ToUpperInvariant(), $Message
    $script:AfLogLines.Add($line)
    if ($script:AfLogPath) {
        try { [System.IO.File]::AppendAllText($script:AfLogPath, $line + "`r`n", [System.Text.Encoding]::UTF8) } catch { }
    }
}

function Get-AfLogLines { , $script:AfLogLines.ToArray() }

function Get-AfLogPath { $script:AfLogPath }

# Para que el runspace de aplicar escriba en el mismo archivo que la ventana.
function Set-AfLogPath {
    param([string]$Path)
    $script:AfLogPath = $Path
}
