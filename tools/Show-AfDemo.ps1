# Abre Afina con el análisis real (solo lectura) y un aplicar y deshacer de mentira: no cambia nada en la PC.
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -STA -File tools\Show-AfDemo.ps1
#      -AutoPlay <carpeta>: recorre confirmar, aplicar, listo e historial solo, guarda capturas y cierra.
#      -Optional (con -AutoPlay): espera las búsquedas de actualizaciones, elige solo lo de Opcional y abre un detalle con opciones.
#      -Language es|en: el idioma de la ventana (por defecto, Automático); con -AutoPlay también captura Preferencias abiertas.
param([string]$AutoPlay, [switch]$Optional, [ValidateSet('Auto', 'es', 'en')][string]$Language = 'Auto')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'src\Load.ps1')

# Se agrega al código del trabajo de aplicar y reemplaza lo que toca el sistema.
$demo = @'
function Enable-AfSystemRestore { Start-Sleep -Milliseconds 400; $true }
function New-AfRestorePoint { Start-Sleep -Milliseconds 900; [pscustomobject]@{ Ok = $true; At = (Get-Date).ToString('o'); Message = $null } }
function Restore-AfDemo { param($Record, $User) Start-Sleep -Milliseconds 250 }
function Invoke-AfChange {
    param($Session, $Check, $Detection, $Inventory, $ConfirmDisplay, $Progress, $Step)
    # Los mismos pasos que el motor de verdad (save, apply, backup), con pausas de mentira.
    if ($Step -and -not $Check.NoUndo) { & $Step 'save'; Start-Sleep -Milliseconds 300 }
    if ($Step) { & $Step 'apply' }
    Start-Sleep -Milliseconds 650
    if ($Check.Id -like 'updates.*' -and $Progress) {
        foreach ($n in 1, 2) { foreach ($step in 'Descargando {0} de {1}', 'Instalando {0} de {1}') { & $Progress ((T $step) -f $n, 2); Start-Sleep -Milliseconds 700 } }
    }
    $answer = if ($Check.Id -eq 'display.refresh' -and $ConfirmDisplay) { & $ConfirmDisplay @() } else { 'keep' }
    $status = if ($answer -eq 'keep') { 'Applied' } else { 'Reverted' }
    $records = if ($Check.Id -in 'storage.temp', 'security.signatures', 'updates.windows', 'updates.apps') { @([pscustomobject]@{ Kind = 'Action' }) } else { @([pscustomobject]@{ Kind = 'Demo' }) }
    $change = [pscustomobject]@{
        CheckId = $Check.Id; Title = $(if ($Detection.Title) { $Detection.Title } else { $Check.Title }); NeedsReboot = [bool]$Check.NeedsReboot
        Status = $status; Message = $(if ($status -eq 'Reverted') { ((T 'Se volvió a {0} Hz') -f 60) + '.' }); Note = $(if ($Check.Id -eq 'storage.temp') { ((T 'Se liberaron {0}') -f (Format-AfSize -Bytes 2040109466)) + '.' })
        AppliedAt = (Get-Date).ToString('o'); UndoneAt = $null; Records = $records
    }
    if ($Step -and $status -eq 'Applied') { & $Step 'backup'; Start-Sleep -Milliseconds 250 }
    [void]$Session.Changes.Add($change)
    Save-AfSession -Session $Session
    $change
}
'@

$config = Get-AfConfigDefaults
$config.Motion = 'Always'
$config.Language = $Language
$backups = Join-Path $root '.dev\demo-respaldos'
$onShown = $null
if ($AutoPlay) {
    New-Item -ItemType Directory -Force -Path $AutoPlay | Out-Null
    $Global:AfDemoOut = $AutoPlay
    $Global:AfDemoOptional = [bool]$Optional
    $onShown = {
        param($window)
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(300)
        $timer.Tag = @{ Window = $window; Shots = @{}; DoneTicks = 0; Start = Get-Date }
        $timer.Add_Tick({
                param($sender, $e)
                $st = $sender.Tag
                $w = $st.Window
                # Una captura espera la ventana (Wait-AfUi) y el temporizador vuelve a entrar: un solo tick a la vez.
                if ($st.Busy) { return }
                $st.Busy = $true
                $shoot = { param($name) if (-not $st.Shots[$name]) { $st.Shots[$name] = $true; Save-AfWindowSnapshot -Window $w -Path (Join-Path $Global:AfDemoOut "demo-$name.png") } }
                try {
                # La pantalla de entrada: queda fija mientras se captura a mitad del giro y ya armada.
                if ($w.FindName('Splash').Visibility -eq 'Visible' -and -not $w.Tag.SplashGone) {
                    $w.Tag.SplashPinned = $true
                    if (-not $st.Shots['entrada-giro'] -and ((Get-Date) - $st.Start).TotalMilliseconds -ge 700) { & $shoot 'entrada-giro' }
                    if ($st.Shots['entrada-giro'] -and $w.FindName('SplashTag').Opacity -ge 0.99) {
                        & $shoot 'entrada'
                        $w.Tag.SplashPinned = $false
                        Hide-AfSplash -Window $w
                    }
                    return
                }
                if ($w.FindName('Splash').Visibility -eq 'Visible') { return }
                switch ($w.Tag.Phase) {
                    'scanning' {
                        # El análisis a medio armar: ya están los datos de la PC y quedan grupos fantasma.
                        if ($w.Tag.Revealed -ge 3 -and -not $st.Shots['resumen-analizando']) { & $shoot 'resumen-analizando' }
                        if ($w.FindName('PcName').Text -and @($w.FindName('Groups').Children | Where-Object { "$($_.Tag)" -like 'skeleton:*' }).Count) { & $shoot 'analizando' }
                    }
                    'ready' {
                        if ($st.Shots['analisis']) { return }
                        # El Resumen con unos segundos de estadísticas en vivo; después la barra desplegada y la lista.
                        if (-not $st.Shots['resumen']) {
                            if (@($w.Tag.LiveHistory.Cpu).Count -lt 4 -and ((Get-Date) - $st.Start).TotalSeconds -lt 40) { return }
                            Wait-AfUi -Milliseconds 900
                            & $shoot 'resumen'
                            Set-AfRailOpen -Window $w -Open $true
                            Wait-AfUi -Milliseconds 400
                            & $shoot 'barra'
                            Set-AfRailOpen -Window $w -Open $false
                            Set-AfFilter -Window $w -Filter 'all'
                            return
                        }
                        if ($Global:AfDemoOptional -and -not $st.Shots['opcional']) {
                            # Primero terminan las búsquedas en segundo plano; después se elige solo Opcional (un tick prepara y el siguiente captura).
                            if (@(Get-AfRows -Window $w | Where-Object { $_.Tag.Detection.Data.Async }).Count) { return }
                            if (-not $st.Prepared) {
                                foreach ($row in Get-AfRows -Window $w) {
                                    $box = Get-AfRowCheckBox -Row $row
                                    if (-not $box) { continue }
                                    $box.IsChecked = $row.Tag.Check.Category -eq 'optional'
                                    if ($box.IsChecked) { Reset-AfChoices -Row $row }
                                }
                                Update-AfPrimary -Window $w
                                Set-AfFilter -Window $w -Filter 'optional'
                                $withChoices = @(Get-AfRows -Window $w | Where-Object { $_.Tag.Check.Category -eq 'optional' -and $_.Resources['ChoiceBoxes'] })[0]
                                if ($withChoices) { Switch-AfRowDetail -Row $withChoices -Motion $false }
                                $st.Prepared = $true
                                return
                            }
                            & $shoot 'opcional'
                        }
                        & $shoot 'analisis'
                        # Preferencias es un Popup (otra ventana): se captura su panel aparte.
                        if (-not $st.Shots['preferencias']) {
                            $st.Shots['preferencias'] = $true
                            $prefs = $w.FindName('Prefs')
                            Update-AfLanguageAvailability -Window $w
                            $prefs.IsOpen = $true
                            Wait-AfUi -Milliseconds 450
                            $panel = $prefs.Child
                            $bitmap = New-Object System.Windows.Media.Imaging.RenderTargetBitmap([int][math]::Ceiling($panel.ActualWidth), [int][math]::Ceiling($panel.ActualHeight), 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
                            $bitmap.Render($panel)
                            $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
                            $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
                            $stream = [System.IO.File]::Create((Join-Path $Global:AfDemoOut 'demo-preferencias.png'))
                            try { $encoder.Save($stream) } finally { $stream.Dispose() }
                            $prefs.IsOpen = $false
                        }
                        # Sin nada marcado (una PC ya afinada), el demo marca lo primero que haya: aplicar es de mentira.
                        if (-not (Get-AfSelectedCount -Window $w)) {
                            $box = @(Get-AfRows -Window $w | ForEach-Object { Get-AfRowCheckBox -Row $_ } | Where-Object { $_ })[0]
                            if ($box) { $box.IsChecked = $true; Update-AfPrimary -Window $w }
                        }
                        # Sin nada para aplicar no hay confirmación: termina aquí.
                        if (-not (Get-AfSelectedCount -Window $w)) { $sender.Stop(); $w.Close(); return }
                        Invoke-AfPrimaryAction -Window $w
                    }
                    'confirm' { & $shoot 'confirmar'; Invoke-AfPrimaryAction -Window $w }
                    'applying' {
                        # Una fila con sus pasos a la vista (uno en curso).
                        if (@(Get-AfRows -Window $w | Where-Object { @($_.FindName('Steps').Children | Where-Object { $_.Resources['State'] -eq 'Running' }).Count }).Count) { & $shoot 'paso' }
                        if ($Global:AfDemoOptional) {
                            $busy = @(Get-AfRows -Window $w | Where-Object { @($_.FindName('Steps').Children | Where-Object { $_.Tag -eq 'apply' -and $_.Children[1].Text -match ' · ' }).Count })
                            if ($busy.Count) { & $shoot 'aplicando' }
                        } elseif ($w.Tag.ApplyCount -ge 2) { & $shoot 'aplicando' }
                    }
                    'display' { & $shoot 'pantalla'; Invoke-AfPrimaryAction -Window $w }
                    'done' {
                        $st.DoneTicks++
                        if ($st.DoneTicks -ge 5) {
                            & $shoot 'listo'
                            # Una categoría sin nada para cambiar muestra su tarjeta.
                            $groups = @($w.FindName('Groups').Children)
                            $quiet = @(Get-AfCategories | Where-Object { $id = $_.Id; -not @($groups | Where-Object { $_.Tag -eq $id }).Count })[0]
                            if ($quiet) { Set-AfFilter -Window $w -Filter $quiet.Id; & $shoot 'en-orden'; Set-AfFilter -Window $w -Filter 'all' }
                            Show-AfHistory -Window $w
                        }
                    }
                    'history' { & $shoot 'historial'; $sender.Stop(); $w.Close() }
                }
                } finally { $st.Busy = $false }
            })
        $timer.Start()
    }
}
Show-AfApp -Config $config -BackupDirectory $backups -DemoCode $demo -OnShown $onShown
# Igual que Main.ps1: la búsqueda de Windows Update en segundo plano no se puede cortar.
[Environment]::Exit(0)
