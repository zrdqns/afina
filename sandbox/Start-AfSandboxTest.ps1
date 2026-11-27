# Prueba de aplicar y deshacer de verdad, en Windows Sandbox (nunca en la PC real).
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File sandbox\Start-AfSandboxTest.ps1 [-TimeoutMinutes 25]
param([int]$TimeoutMinutes = 25)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'SandboxLib.ps1')

if (-not (Get-Command -Name 'wsb.exe' -ErrorAction SilentlyContinue)) { throw 'Windows Sandbox no está activado (falta wsb.exe): "Activar o desactivar las características de Windows" > "Espacio aislado de Windows", y reiniciar.' }
# Windows permite un solo Sandbox abierto.
if (Get-AfSandboxId -Text (Invoke-AfWsb -Arguments 'list' -TimeoutSeconds 30).Output) { throw 'Ya hay un Windows Sandbox abierto: ciérralo y vuelve a correr la prueba.' }

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'build.ps1') | Out-Host
$out = Join-Path $root '.dev\sandbox-out'
Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $out | Out-Null
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$watch = [System.Diagnostics.Stopwatch]::StartNew()
function Write-Step([string]$Text) { '{0,6:N0} s  {1}' -f $watch.Elapsed.TotalSeconds, $Text }

# Sin GPU virtual: con ella dwm.exe se cae en el Sandbox y la sesión del usuario nunca inicia; el render por software basta aquí.
$started = Invoke-AfWsb -Arguments ('start --config "{0}"' -f (Get-AfSandboxStartConfig)) -TimeoutSeconds 240
$id = Get-AfSandboxId -Text $started.Output
if (-not $id) { throw "Windows Sandbox no arrancó: $($started.Output)" }
Write-Step "Sandbox $id"
try {
    foreach ($share in Get-AfSandboxShares -Root $root -OutDir $out) {
        $arguments = 'share --id {0} -f "{1}" -s "{2}"{3}' -f $id, $share.HostPath, $share.SandboxPath, $(if ($share.Write) { ' -w' } else { '' })
        $shared = $null
        for ($try = 0; $try -lt 20 -and -not ($shared -and $shared.Ok); $try++) {
            $shared = Invoke-AfWsb -Arguments $arguments -TimeoutSeconds 60
            if (-not $shared.Ok) { Start-Sleep -Seconds 3 }
        }
        if (-not $shared.Ok) { throw "No se pudo compartir $($share.HostPath): $($shared.Output)" }
    }
    Write-Step 'Carpetas compartidas'

    # La prueba corre con el usuario del Sandbox, como Afina en una PC real: hace falta su sesión.
    [void](Invoke-AfWsb -Arguments "connect --id $id" -TimeoutSeconds 60)
    $marker = Join-Path $out 'sesion.txt'
    $sessionDeadline = (Get-Date).AddMinutes(4)
    while (-not (Test-Path -LiteralPath $marker) -and (Get-Date) -lt $sessionDeadline) {
        [void](Invoke-AfWsb -Arguments ('exec --id {0} -r ExistingLogin -c "cmd.exe /c echo ok> C:\resultados\sesion.txt"' -f $id) -TimeoutSeconds 20)
        if (-not (Test-Path -LiteralPath $marker)) { Start-Sleep -Seconds 3 }
    }
    if (-not (Test-Path -LiteralPath $marker)) { throw 'La sesión del Sandbox no respondió en 4 minutos.' }
    Write-Step 'Sesión del usuario lista'

    # wsb puede esperar o no a que termine el comando: se lanza aparte y se espera el informe.
    $command = 'exec --id {0} -r ExistingLogin -c "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\prueba\Test-AfSandbox.ps1 -NoShutdown"' -f $id
    Start-Process -FilePath 'wsb.exe' -ArgumentList $command -WindowStyle Hidden
    while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath (Join-Path $out 'listo.txt'))) { Start-Sleep -Seconds 5 }
    Write-Step 'Fin de la espera'
} finally {
    [void](Invoke-AfWsb -Arguments "stop --id $id" -TimeoutSeconds 90)
    Write-Step 'Sandbox cerrado'
}

$reportPath = Join-Path $out 'informe.json'
if (-not (Test-Path -LiteralPath $reportPath)) {
    $seen = @(Get-ChildItem -LiteralPath $out -Name -ErrorAction SilentlyContinue)
    throw "No llegó el informe en $TimeoutMinutes min. En la salida hay: $($seen -join ', ')"
}
$report = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($reportPath))
'Afina {0} en Windows {1}, administrador: {2}' -f $report.Version, $report.Os, $report.Admin
'Desafinado: ' + (@($report.Detuned) -join '; ')
'Cambios:'
@($report.Changes) | Format-Table Id, Status, StateAfter, Records, Message -AutoSize | Out-String -Width 220
'Deshacer:'
@($report.Undo) | Format-Table Id, Status, Message -AutoSize | Out-String -Width 220
'Revisiones en Error: ' + (@($report.Before | Where-Object { $_.State -eq 'Error' } | ForEach-Object { $_.Id }) -join ', ')
if (@($report.Differences).Count) { 'Diferencias con el estado original:'; @($report.Differences) | Format-Table -AutoSize | Out-String -Width 220 }
if (@($report.RecordsNotRestored).Count) { 'Registros sin restaurar:'; @($report.RecordsNotRestored) | Format-Table -AutoSize | Out-String -Width 220 }
if ($report.Error) { 'Error:'; $report.Error }
'RESULTADO: ' + $(if ($report.Passed) { 'aprobado' } else { 'no aprobado' })
if (-not $report.Passed) { exit 1 }
