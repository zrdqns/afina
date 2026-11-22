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

    It 'Get-AfSandboxState incluye anuncios, diagnóstico y las características de prueba' -Tag 'Integration' {
        $state = Get-AfSandboxState
        $state.Contains('Registro|HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager|SilentInstalledAppsEnabled') | Should -BeTrue
        $state.Contains('Registro|HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection|AllowTelemetry') | Should -BeTrue
        $state.Contains('Registro|HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy|TailoredExperiencesWithDiagnosticDataEnabled') | Should -BeTrue
        $state.Contains('Característica|TelnetClient') | Should -BeTrue
    }

    It 'Get-AfSandboxState lee el estado de esta PC sin cambiarlo' -Tag 'Integration' {
        $state = Get-AfSandboxState
        $state.Contains('Registro|HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled') | Should -BeTrue
        $state['Energía|Modo con cargador'] | Should -Match '^[0-9a-f-]{36}$'
        $state.Keys | Where-Object { $_ -like 'Pantalla|*' } | Should -Not -BeNullOrEmpty
    }
}
