# Funciones de la prueba en Windows Sandbox (diseño, sección 12). Set-AfSandboxDetuned solo corre dentro del Sandbox.

# El código de Afina sale del build (bloque $Global:AfCodeBlock) sin correr Main: se carga con  . (Get-AfBuiltCode -Path …)
function Get-AfBuiltCode {
    param([Parameter(Mandatory)][string]$Path)
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    if (@($errors).Count) { throw "El build tiene errores de sintaxis: $Path" }
    $assignment = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$Global:AfCodeBlock' }, $true)
    if (-not $assignment) { throw "No se encontró el código de Afina en $Path" }
    $assignment.Right.Expression.ScriptBlock.GetScriptBlock()
}

function Test-AfInSandbox { $env:USERNAME -eq 'WDAGUtilityAccount' }

# Windows Sandbox se maneja con wsb.exe (Windows 11 24H2 o posterior) y no con el comando de inicio del .wsb:
# el 2026-11-21 ese comando no corrió en dos arranques seguidos. Toda llamada a wsb lleva tiempo límite, porque
# un "exec" lanzado antes de que haya sesión de usuario se queda esperando sin fin.
function Invoke-AfWsb {
    param([Parameter(Mandatory)][string]$Arguments, [int]$TimeoutSeconds = 60, [string]$FilePath = 'wsb.exe')
    $psi = New-Object System.Diagnostics.ProcessStartInfo($FilePath, ($Arguments + ' --raw'))
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($psi)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try { $process.Kill() } catch { }
        return [pscustomobject]@{ Ok = $false; TimedOut = $true; ExitCode = $null; Output = '' }
    }
    # "wsb connect" abre la ventana del Sandbox, que hereda la salida y la deja abierta: no se espera a que se cierre.
    [void]$stdout.Wait(3000)
    [void]$stderr.Wait(1000)
    $outText = if ($stdout.IsCompleted) { $stdout.Result } else { '' }
    $errText = if ($stderr.IsCompleted) { $stderr.Result } else { '' }
    $inner = $null
    try { $inner = (ConvertFrom-Json -InputObject $outText).ExitCode } catch { }
    [pscustomobject]@{ Ok = $process.ExitCode -eq 0 -and ($null -eq $inner -or $inner -eq 0); TimedOut = $false; ExitCode = $process.ExitCode; Output = ($outText + ' ' + $errText).Trim() }
}

# Configuración de arranque: con la GPU virtual dwm.exe se cae en bucle (udwm.dll, 0xc00001ad), no queda winlogon y la sesión nunca inicia.
# Con render por software basta para la prueba.
function Get-AfSandboxStartConfig {
    '<Configuration><vGPU>Disable</vGPU></Configuration>'
}

function Get-AfSandboxId {
    param([string]$Text)
    ([regex]::Match([string]$Text, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')).Value
}

# Carpetas que se comparten con el Sandbox: el build y la prueba de solo lectura, y la salida con escritura.
function Get-AfSandboxShares {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$OutDir)
    @(
        [pscustomobject]@{ HostPath = Join-Path $Root 'dist\usb'; SandboxPath = 'C:\afina'; Write = $false }
        [pscustomobject]@{ HostPath = Join-Path $Root 'sandbox'; SandboxPath = 'C:\prueba'; Write = $false }
        [pscustomobject]@{ HostPath = $OutDir; SandboxPath = 'C:\resultados'; Write = $true }
    )
}

$script:AfSandboxValues = @(
    'HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR|HistoricalCaptureEnabled'
    'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences|DirectXUserGlobalSettings'
    'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System|EnableLUA'
    'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes|ActivePowerScheme'
    'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes|ActiveOverlayAcPowerScheme'
    'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes|ActiveOverlayDcPowerScheme'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection|AllowTelemetry'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy|TailoredExperiencesWithDiagnosticDataEnabled'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|HideFileExt'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|IsBatteryPercentageEnabled'
    # Start_TrackDocs no lo toca ninguna revisión: va aquí para que el informe pruebe que no cambió.
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|Start_TrackDocs'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|Start_TrackProgs'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|Start_IrisRecommendations'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|Start_RecoPersonalizedSites'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|Start_AccountNotifications'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings|TaskbarEndTask'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize|EnableTransparency'
    'HKCU:\Control Panel\Mouse|MouseSpeed'
    'HKCU:\Control Panel\Mouse|MouseThreshold1'
    'HKCU:\Control Panel\Mouse|MouseThreshold2'
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management|PagingFiles'
    'HKLM:\SOFTWARE\Policies\Microsoft\Dsh|AllowNewsAndInterests'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI|DisableAIDataAnalysis'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search|ConnectedSearchUseWeb'
    'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer|DisableSearchBoxSuggestions'
    'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer|HideRecommendedSection'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR|AllowGameDVR'
)

# Servicios que un "optimizador" deshabilita en la prueba (la revisión hardware.services los tiene que devolver).
$script:AfSandboxServices = @('Spooler', 'UsoSvc', 'XblAuthManager', 'XboxGipSvc', 'bthserv', 'fhsvc', 'DPS')

# Características sin importancia para la ida y vuelta de la pieza WindowsFeature (se usa la primera apagada con su contenido).
$script:AfSandboxFeatures = @('TelnetClient', 'TFTP')

# Apps sin importancia para la ida y vuelta de la pieza AppxPackage (solo si están aprovisionadas, para poder registrarlas de nuevo).
$script:AfSandboxApps = @('Microsoft.WindowsCalculator', 'Microsoft.MicrosoftStickyNotes', 'Microsoft.WindowsAlarms', 'Microsoft.BingNews', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.WindowsFeedbackHub', 'Microsoft.MicrosoftSolitaireCollection')

# Sin valor, Windows usa "sin superposición" (Equilibrado). Al deshacer, la API vuelve a ese modo pero deja el GUID nulo
# escrito: es el mismo estado y no cuenta como diferencia (prueba en Sandbox del 2026-11-21).
function ConvertTo-AfOverlayStateText {
    param([string]$Text)
    if ($Text -eq '(no existe)') { 'String:00000000-0000-0000-0000-000000000000' } else { $Text }
}

$script:AfSandboxKeys = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
    'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
    'HKCU:\Software\Classes\CLSID\{51668040-5e31-4023-bbe3-149163bd80f1}\InprocServer32'
)

function ConvertTo-AfStateText {
    param($Value)
    if ($null -eq $Value) { return '(no existe)' }
    if ($Value -is [array]) { return (@($Value) | ForEach-Object { [string]$_ }) -join ' ' }
    [string]$Value
}

# Todo lo que las piezas pueden tocar, como texto: antes de aplicar y después de deshacer tiene que dar igual.
function Get-AfSandboxState {
    $state = [ordered]@{}
    foreach ($read in @($script:AfSandboxValues) + @(Get-AfAdsReads)) {
        $parts = $read -split '\|', 2
        $value = Get-AfRegistryState -Path $parts[0] -Name $parts[1]
        $text = if ($value.Exists) { '{0}:{1}' -f $value.Type, (ConvertTo-AfStateText $value.Value) } else { '(no existe)' }
        if ($parts[1] -like 'ActiveOverlay*PowerScheme') { $text = ConvertTo-AfOverlayStateText $text }
        $state["Registro|$read"] = $text
    }
    foreach ($key in $script:AfSandboxKeys) {
        $item = Get-Item -LiteralPath $key -ErrorAction SilentlyContinue
        if (-not $item) { $state["Clave|$key"] = '(no existe)'; continue }
        # Una clave que queda vacía también es una diferencia, y el valor por defecto sale con nombre vacío (Clave|ruta|).
        $state["Clave|$key"] = 'existe'
        foreach ($name in @($item.GetValueNames() | Sort-Object)) {
            $state["Clave|$key|$name"] = '{0}:{1}' -f $item.GetValueKind($name), (ConvertTo-AfStateText $item.GetValue($name, $null, 'DoNotExpandEnvironmentNames'))
        }
        $item.Close()
    }
    $scheme = Get-AfActivePowerScheme
    $query = Invoke-AfProcess -FilePath 'powercfg.exe' -Arguments "/q $scheme 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a" -TimeoutMs 15000
    $values = ConvertFrom-AfPowercfgQuery -Text $query.Output
    $state['Energía|Wi-Fi CA/CC'] = if ($values) { '{0}/{1}' -f $values.Ac, $values.Dc } else { '(sin datos)' }
    $state['Energía|Modo con cargador'] = Get-AfCurrentOverlay
    $state['Entrega|Modo'] = try { [string](Get-DOConfig -ErrorAction Stop).DownloadMode } catch { '(sin datos)' }
    try { foreach ($firewall in @(Get-NetFirewallProfile -ErrorAction Stop)) { $state["Firewall|$($firewall.Name)"] = [string]$firewall.Enabled } } catch { $state['Firewall'] = '(sin datos)' }
    try {
        $mp = Get-MpPreference -ErrorAction Stop
        $state['Defender|PUAProtection'] = [string]$mp.PUAProtection
        $state['Defender|DisableRealtimeMonitoring'] = [string]$mp.DisableRealtimeMonitoring
    } catch { $state['Defender'] = '(sin datos)' }
    try { $state['Disco|TRIM'] = [string](Get-AfTrimEnabled) } catch { $state['Disco|TRIM'] = '(sin datos)' }
    foreach ($group in Get-AfServiceGroups) {
        foreach ($name in $group.Services.Keys) {
            $start = Get-AfServiceStart -Name $name
            $state["Servicio|$name"] = if ($start) { ConvertTo-AfServiceMode -Start $start.Start -Delayed $start.Delayed } else { '(no existe)' }
        }
    }
    # Sin administrador DISM no responde: queda "(sin datos)" igual antes y después.
    foreach ($feature in $script:AfSandboxFeatures) { $state["Característica|$feature"] = try { (Get-AfFeatureInfo -Name $feature).Raw } catch { '(sin datos)' } }
    foreach ($display in @(Get-AfDisplayModes)) { $state["Pantalla|$($display.DeviceName)"] = '{0}x{1}@{2}' -f $display.Width, $display.Height, $display.Hz }
    foreach ($nic in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue)) {
        foreach ($property in @(Get-NetAdapterAdvancedProperty -Name $nic.Name -ErrorAction SilentlyContinue | Where-Object RegistryKeyword)) {
            $state["Red|$($nic.InterfaceGuid)|$($property.RegistryKeyword)"] = ConvertTo-AfStateText @($property.RegistryValue)
        }
    }
    $state
}

function Compare-AfSandboxState {
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Before, [Parameter(Mandatory)][System.Collections.IDictionary]$After, [string[]]$Ignore = @())
    foreach ($name in @(@($Before.Keys) + @($After.Keys) | Select-Object -Unique)) {
        if (@($Ignore | Where-Object { $name -like $_ }).Count) { continue }
        $old = if ($Before.Contains($name)) { $Before[$name] } else { '(no existe)' }
        $new = if ($After.Contains($name)) { $After[$name] } else { '(no existe)' }
        if ($old -ne $new) { [pscustomobject]@{ Name = $name; Before = $old; After = $new } }
    }
}

# Deja el Sandbox "desafinado" en lo que se pueda, para que Afina tenga qué aplicar. Devuelve lo que hizo.
function Set-AfSandboxDetuned {
    if (-not (Test-AfInSandbox)) { throw 'Set-AfSandboxDetuned solo se corre dentro de Windows Sandbox.' }
    $done = New-Object System.Collections.ArrayList
    $step = {
        param([string]$Name, [scriptblock]$Action)
        try { & $Action; [void]$done.Add($Name) } catch { [void]$done.Add("$Name (no se pudo: $($_.Exception.Message))") }
    }
    & $step 'Plan Ahorro de energía' { $r = Invoke-AfProcess -FilePath 'powercfg.exe' -Arguments '/setactive a1841308-3541-4fab-bc81-f71556f20b4a'; if ($r.ExitCode -ne 0) { throw "powercfg $($r.ExitCode)" } }
    & $step 'Modo de juego apagado' { New-Item -Path 'HKCU:\Software\Microsoft\GameBar' -Force | Out-Null; New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -PropertyType DWord -Value 0 -Force | Out-Null }
    & $step 'Grabación en segundo plano' { New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Force | Out-Null; New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'HistoricalCaptureEnabled' -PropertyType DWord -Value 1 -Force | Out-Null }
    & $step 'DirectX sin optimizaciones en ventana' { New-Item -Path 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Force | Out-Null; New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name 'DirectXUserGlobalSettings' -PropertyType String -Value 'VRROptimizeEnable=0;' -Force | Out-Null }
    & $step 'Spotify al arrancar' { New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'Spotify' -PropertyType String -Value '"C:\afina-prueba\Spotify.exe" /minimized' -Force | Out-Null }
    & $step 'Defender sin bloqueo de PUA' { Set-MpPreference -PUAProtection 0 -ErrorAction Stop }
    & $step 'Defender sin tiempo real' { Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop }
    & $step 'Firewall Público apagado' { Set-NetFirewallProfile -Name 'Public' -Enabled False -ErrorAction Stop }
    & $step 'Anuncios y sugerencias encendidos' {
        foreach ($read in Get-AfAdsReads) {
            $path, $name = $read -split '\|', 2
            if (-not (Test-Path -LiteralPath $path)) { New-Item -Path $path -Force | Out-Null }
            New-ItemProperty -LiteralPath $path -Name $name -PropertyType DWord -Value 1 -Force | Out-Null
        }
    }
    & $step 'Datos de diagnóstico opcionales' {
        $collection = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
        if (-not (Test-Path -LiteralPath $collection)) { New-Item -Path $collection -Force | Out-Null }
        New-ItemProperty -LiteralPath $collection -Name 'AllowTelemetry' -PropertyType DWord -Value 3 -Force | Out-Null
        $privacy = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'
        if (-not (Test-Path -LiteralPath $privacy)) { New-Item -Path $privacy -Force | Out-Null }
        New-ItemProperty -LiteralPath $privacy -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -PropertyType DWord -Value 1 -Force | Out-Null
    }
    & $step 'UAC apagado' { New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -PropertyType DWord -Value 0 -Force | Out-Null }
    & $step 'TRIM apagado' { $r = Invoke-AfProcess -FilePath 'fsutil.exe' -Arguments 'behavior set DisableDeleteNotify NTFS 1'; if ($r.ExitCode -ne 0) { throw "fsutil $($r.ExitCode)" } }
    & $step 'Temporales viejos (120 MB)' {
        $dir = Join-Path $env:TEMP 'afina-prueba'
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $bytes = New-Object byte[] (10MB)
        for ($i = 0; $i -lt 12; $i++) {
            $file = Join-Path $dir "viejo$i.tmp"
            [System.IO.File]::WriteAllBytes($file, $bytes)
            (Get-Item -LiteralPath $file).LastWriteTime = (Get-Date).AddDays(-3)
        }
    }
    & $step 'Extensiones ocultas' { New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -PropertyType DWord -Value 1 -Force | Out-Null }
    & $step 'Aceleración del mouse encendida' {
        foreach ($pair in @(@('MouseSpeed', '1'), @('MouseThreshold1', '6'), @('MouseThreshold2', '10'))) {
            New-ItemProperty -LiteralPath 'HKCU:\Control Panel\Mouse' -Name $pair[0] -PropertyType String -Value $pair[1] -Force | Out-Null
        }
        Invoke-AfSetSystemParameter -Name Mouse -Value ([int[]]@(6, 10, 1))  # umbral 1, umbral 2, aceleración: lo normal de Windows
    }
    & $step 'Transparencia y animación encendidas' {
        $personalize = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        if (-not (Test-Path -LiteralPath $personalize)) { New-Item -Path $personalize -Force | Out-Null }
        New-ItemProperty -LiteralPath $personalize -Name 'EnableTransparency' -PropertyType DWord -Value 1 -Force | Out-Null
        Invoke-AfSetSystemParameter -Name ClientAreaAnimation -Value $true
    }
    & $step 'Sensor de almacenamiento apagado' {
        $policy = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
        if (-not (Test-Path -LiteralPath $policy)) { New-Item -Path $policy -Force | Out-Null }
        New-ItemProperty -LiteralPath $policy -Name '01' -PropertyType DWord -Value 0 -Force | Out-Null
    }
    # $service y no $name: dentro de $step, $name sería su parámetro $Name (PowerShell no distingue mayúsculas).
    foreach ($service in $script:AfSandboxServices) {
        & $step "Servicio $service deshabilitado" { $r = Invoke-AfProcess -FilePath 'sc.exe' -Arguments "config $service start= disabled"; if ($r.ExitCode -ne 0) { throw "sc $($r.ExitCode)" } }
    }
    & $step 'Directiva AllowGameDVR = 0' {
        $dvr = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
        if (-not (Test-Path -LiteralPath $dvr)) { New-Item -Path $dvr -Force | Out-Null }
        New-ItemProperty -LiteralPath $dvr -Name 'AllowGameDVR' -PropertyType DWord -Value 0 -Force | Out-Null
    }
    & $step 'Archivo de paginación fijo' {
        Set-AfPagefileAutomatic -Value $false
        New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -PropertyType MultiString -Value @('C:\pagefile.sys 1024 1024') -Force | Out-Null
    }
    @($done)
}

# Lo que hay en el Sandbox para estas pruebas (va al informe). DISM se cronometra: en la PC real solo se le pregunta por VMP.
function Get-AfSandboxEnvironment {
    $wu = Get-Service -Name 'wuauserv' -ErrorAction SilentlyContinue
    $features = [ordered]@{}
    foreach ($feature in @($script:AfSandboxFeatures) + 'VirtualMachinePlatform') {
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        $raw = try { (Get-AfFeatureInfo -Name $feature).Raw } catch { 'error: ' + $_.Exception.Message }
        $features[$feature] = '{0} ({1:N1} s)' -f $raw, $watch.Elapsed.TotalSeconds
    }
    [pscustomobject]@{
        WindowsUpdate = if ($wu) { '{0}, {1}' -f $wu.Status, $wu.StartType } else { '(no existe)' }
        Features = [pscustomobject]$features
        Provisioned = @(try { Get-AppxProvisionedPackage -Online -ErrorAction Stop | ForEach-Object { [string]$_.DisplayName } } catch { })
        Installed = @(Get-AppxPackage -ErrorAction SilentlyContinue | ForEach-Object { [string]$_.Name })
    }
}

# Aplica una pieza, deshace sus registros y compara: Restored exige que haya cambiado algo y que vuelva igual.
function Invoke-AfPieceRoundTrip {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][scriptblock]$Apply, [Parameter(Mandatory)][scriptblock]$Read, $User)
    try {
        $before = & $Read
        $tx = New-AfTransaction -User $User
        $applied = [bool](& $Apply $tx)
        $middle = & $Read
        $undo = Undo-AfRecords -Records @($tx.Records) -User $User
        Start-Sleep -Seconds 1
        $after = & $Read
        $restored = $applied -and $middle -ne $before -and $after -eq $before -and -not @($undo.Failed).Count
        [pscustomobject]@{ Name = $Name; Applied = $applied; Restored = $restored; Detail = ('{0} → {1} → {2}{3}' -f $before, $middle, $after, $(if ($undo.Reason) { " ($($undo.Reason))" })) }
    } catch {
        [pscustomobject]@{ Name = $Name; Applied = $false; Restored = $false; Detail = 'error: ' + $_.Exception.Message }
    }
}

# Las piezas de la etapa 3 que el catálogo no aplica en el Sandbox (no hay VMP encendida ni apps promocionales).
function Test-AfSandboxPieces {
    param($User)
    if (-not (Test-AfInSandbox)) { throw 'Test-AfSandboxPieces solo se corre dentro de Windows Sandbox.' }
    $feature = $null
    foreach ($candidate in $script:AfSandboxFeatures) {
        try { if ((Get-AfFeatureInfo -Name $candidate).Raw -eq 'Disabled') { $feature = $candidate; break } } catch { }
    }
    if ($feature) {
        Invoke-AfPieceRoundTrip -Name "WindowsFeature $feature" -User $User -Apply { param($tx) Set-AfWindowsFeature -Tx $tx -Name $feature -Enabled $true } -Read { (Get-AfFeatureInfo -Name $feature).Raw }
    } else {
        [pscustomobject]@{ Name = 'WindowsFeature'; Applied = $false; Restored = $true; Detail = 'sin característica de prueba apagada con su contenido' }
    }
    $provisioned = @(try { Get-AppxProvisionedPackage -Online -ErrorAction Stop | ForEach-Object { [string]$_.DisplayName } } catch { })
    $package = @(Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $_.Name -in $script:AfSandboxApps -and $provisioned -contains $_.Name })[0]
    if ($package) {
        $app = [pscustomobject]@{ Name = $package.Name; PackageName = $package.Name; StoreId = $null }
        Invoke-AfPieceRoundTrip -Name "AppxPackage $($package.Name)" -User $User -Apply { param($tx) Remove-AfAppxPackage -Tx $tx -App $app } -Read { if (@(Get-AppxPackage -Name $app.PackageName).Count) { 'Installed' } else { 'Removed' } }
    } else {
        [pscustomobject]@{ Name = 'AppxPackage'; Applied = $false; Restored = $true; Detail = 'sin paquete aprovisionado de la lista' }
    }
    # Parámetros del sistema: la ida y vuelta pasa por la API real (la hibernación queda fuera: el Sandbox no hiberna).
    Invoke-AfPieceRoundTrip -Name 'SystemParameter Mouse' -User $User -Apply { param($tx) Set-AfSystemParameter -Tx $tx -Name Mouse -Value @(0, 0, 0) } -Read { (Get-AfSystemParameterValue -Name Mouse) -join ',' }
    Invoke-AfPieceRoundTrip -Name 'SystemParameter ClientAreaAnimation' -User $User -Apply { param($tx) Set-AfSystemParameter -Tx $tx -Name ClientAreaAnimation -Value $false } -Read { [string](Get-AfSystemParameterValue -Name ClientAreaAnimation) }
}