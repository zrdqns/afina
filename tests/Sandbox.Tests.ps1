BeforeAll {
    $script:root = Split-Path $PSScriptRoot -Parent
    . "$script:root\src\Load.ps1"
    . "$script:root\sandbox\SandboxLib.ps1"
}

Describe 'Arnés del Sandbox (en la PC, sin Sandbox)' {
    It 'Get-AfBuiltCode carga Get-AfVersion de un build sin correr Main' {
        $out = Join-Path $TestDrive 'dist'
        & powershell -NoProfile -ExecutionPolicy Bypass -File "$script:root\build.ps1" -OutDir $out | Out-Null
        $built = Join-Path $out 'usb\Afina.ps1'
        $command = ". '$script:root\sandbox\SandboxLib.ps1'; . (Get-AfBuiltCode -Path '$built'); Get-AfVersion; [bool](Get-Command Invoke-AfChange -ErrorAction SilentlyContinue)"
        $lines = @(& powershell -NoProfile -ExecutionPolicy Bypass -Command $command)
        $lines[0] | Should -Be (Get-AfVersion)
        $lines[1] | Should -Be 'True'
    }

    It 'Compare-AfSandboxState encuentra un valor cambiado e ignora los de -Ignore' {
        $before = [ordered]@{ 'Registro|A' = 'DWord:1'; 'Firewall|Public' = 'True'; 'Disco|TRIM' = 'True' }
        $after = [ordered]@{ 'Registro|A' = 'DWord:2'; 'Firewall|Public' = 'True'; 'Disco|TRIM' = 'False'; 'Clave|Nueva' = 'String:x' }
        $diff = @(Compare-AfSandboxState -Before $before -After $after -Ignore @('Disco|*'))
        @($diff | ForEach-Object Name) | Should -Be @('Registro|A', 'Clave|Nueva')
        $diff[1].Before | Should -Be '(no existe)'
    }

    It 'Get-AfSandboxShares comparte tres carpetas y solo la salida con escritura' {
        $shares = @(Get-AfSandboxShares -Root 'C:\Proyectos\afina' -OutDir 'C:\Proyectos\afina\.dev\sandbox-out')
        $shares.Count | Should -Be 3
        @($shares | Where-Object Write | ForEach-Object SandboxPath) | Should -Be @('C:\resultados')
        @($shares | ForEach-Object HostPath) | Should -Contain 'C:\Proyectos\afina\dist\usb'
    }

    It 'Get-AfSandboxStartConfig apaga la GPU virtual y es XML válido' {
        $config = Get-AfSandboxStartConfig
        ([xml]$config).Configuration.vGPU | Should -Be 'Disable'
    }

    It 'Get-AfSandboxId saca el id de la salida de wsb, con o sin JSON' {
        Get-AfSandboxId -Text '{ "Id": "11e292e7-4d74-431f-9130-8a7cd51ad5ff" }' | Should -Be '11e292e7-4d74-431f-9130-8a7cd51ad5ff'
        Get-AfSandboxId -Text '{ "WindowsSandboxEnvironments": [] }' | Should -BeNullOrEmpty
    }

    It 'Invoke-AfWsb no espera a otro proceso que herede su salida (como la ventana que abre connect)' {
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-AfWsb -FilePath 'cmd.exe' -Arguments '/c start "" /b ping -n 30 127.0.0.1 & echo listo & rem' -TimeoutSeconds 10
        $watch.Elapsed.TotalSeconds | Should -BeLessThan 15
        $r.TimedOut | Should -BeFalse
        $r.ExitCode | Should -Be 0
    }

    It 'Invoke-AfWsb corta al tiempo límite en vez de quedarse esperando' {
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-AfWsb -FilePath 'powershell.exe' -Arguments '-NoProfile -Command Start-Sleep -Seconds 20; #' -TimeoutSeconds 2
        $watch.Elapsed.TotalSeconds | Should -BeLessThan 10
        $r.TimedOut | Should -BeTrue
        $r.Ok | Should -BeFalse
    }

    It 'el modo de energía sin valor cuenta como Equilibrado, lo mismo que escribe Windows al deshacer' {
        ConvertTo-AfOverlayStateText '(no existe)' | Should -Be 'String:00000000-0000-0000-0000-000000000000'
        ConvertTo-AfOverlayStateText 'String:ded574b5-45a0-4f42-8737-46345c09c238' | Should -Be 'String:ded574b5-45a0-4f42-8737-46345c09c238'
    }

    It 'Set-AfSandboxDetuned se niega a correr fuera del Sandbox' {
        { Set-AfSandboxDetuned } | Should -Throw -ExpectedMessage '*solo se corre dentro de Windows Sandbox*'
    }

    It 'Test-AfSandboxPieces se niega a correr fuera del Sandbox' {
        { Test-AfSandboxPieces -User (Get-AfUserForSid) } | Should -Throw -ExpectedMessage '*solo se corre dentro de Windows Sandbox*'
    }

    It 'ni el desafinado ni las piezas cambian el modo de Optimización de entrega (la fila es a mano)' {
        foreach ($name in 'Set-AfSandboxDetuned', 'Test-AfSandboxPieces') {
            (Get-Command $name).ScriptBlock.ToString() | Should -Not -Match 'DeliveryOptimizationMode' -Because $name
        }
    }

    It 'Get-AfSandboxState incluye anuncios, diagnóstico y las características de prueba' -Tag 'Integration' {
        $state = Get-AfSandboxState
        $state.Contains('Registro|HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager|SilentInstalledAppsEnabled') | Should -BeTrue
        $state.Contains('Registro|HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection|AllowTelemetry') | Should -BeTrue
        $state.Contains('Registro|HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy|TailoredExperiencesWithDiagnosticDataEnabled') | Should -BeTrue
        $state.Contains('Característica|TelnetClient') | Should -BeTrue
    }

    It 'Get-AfSandboxState compara los ajustes nuevos, el modo de entrega y las claves del menú clásico' -Tag 'Integration' {
        $state = Get-AfSandboxState
        $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        foreach ($name in 'HideFileExt', 'IsBatteryPercentageEnabled', 'Start_TrackDocs', 'Start_TrackProgs', 'Start_IrisRecommendations', 'Start_RecoPersonalizedSites', 'Start_AccountNotifications') {
            $state.Contains("Registro|$adv|$name") | Should -BeTrue -Because $name
        }
        $state.Contains('Registro|HKLM:\SOFTWARE\Policies\Microsoft\Dsh|AllowNewsAndInterests') | Should -BeTrue
        $state.Contains('Registro|HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer|HideRecommendedSection') | Should -BeTrue
        $state.Contains('Registro|HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management|PagingFiles') | Should -BeTrue
        $state.Contains('Entrega|Modo') | Should -BeTrue
        $state.Contains('Clave|HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32') | Should -BeTrue
        $state.Contains('Clave|HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy') | Should -BeTrue
    }

    It 'Get-AfSandboxState anota la clave vacía y su valor por defecto, y una clave que queda atrás sale como diferencia' {
        $key = 'HKCU:\Software\AfinaTest\SandboxState'
        $saved = $script:AfSandboxKeys
        try {
            $script:AfSandboxKeys = @($key)
            Mock Get-AfAdsReads { @() }
            Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 0; Output = '' } }
            Mock Get-AfActivePowerScheme { 'x' }
            Mock ConvertFrom-AfPowercfgQuery { $null }
            Mock Get-AfCurrentOverlay { 'x' }
            Mock Get-NetFirewallProfile { @() }
            Mock Get-MpPreference { throw 'sin Defender' }
            Mock Get-AfTrimEnabled { $false }
            Mock Get-AfFeatureInfo { [pscustomobject]@{ Raw = 'x' } }
            Mock Get-AfDisplayModes { @() }
            Mock Get-NetAdapter { @() }
            Mock Get-DOConfig { [pscustomobject]@{ DownloadMode = 'Lan' } }
            Mock Get-AfRegistryState { [pscustomobject]@{ Exists = $false; Type = $null; Value = $null } }
            $none = Get-AfSandboxState
            New-Item -Path $key -Force | Out-Null
            $empty = Get-AfSandboxState
            Set-Item -LiteralPath $key -Value ''
            $withDefault = Get-AfSandboxState
            $none["Clave|$key"] | Should -Be '(no existe)'
            $empty["Clave|$key"] | Should -Be 'existe'
            @(Compare-AfSandboxState -Before $none -After $empty).Count | Should -BeGreaterThan 0
            $withDefault["Clave|$key|"] | Should -Be 'String:'
            $none['Entrega|Modo'] | Should -Be 'Lan'
        } finally {
            $script:AfSandboxKeys = $saved
            Remove-Item -LiteralPath 'HKCU:\Software\AfinaTest\SandboxState' -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Get-AfSandboxState lee el estado de esta PC sin cambiarlo' -Tag 'Integration' {
        $state = Get-AfSandboxState
        $state.Contains('Registro|HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled') | Should -BeTrue
        $state['Energía|Modo con cargador'] | Should -Match '^[0-9a-f-]{36}$'
        $state.Keys | Where-Object { $_ -like 'Pantalla|*' } | Should -Not -BeNullOrEmpty
    }
}
