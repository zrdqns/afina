BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    . "$PSScriptRoot\Helpers\Profiles.ps1"
    . "$PSScriptRoot\Helpers\Language.ps1"
    Initialize-AfVocabulary
    $script:user = [pscustomobject]@{ Name = 'PC\Cliente'; Sid = 'S-1-5-21-1' }
    $script:detuned = New-AfDetunedInventory

    # Todo texto que la ventana puede mostrar: TextBlock (con sus Run), contenido de texto y tooltips, también ocultos.
    function Get-AfWindowTexts($Root) {
        $texts = New-Object System.Collections.ArrayList
        $pending = New-Object System.Collections.Stack
        $pending.Push($Root)
        while ($pending.Count) {
            $node = $pending.Pop()
            if ($node -is [System.Windows.Controls.TextBlock]) {
                [void]$texts.Add($node.Text)
                foreach ($inline in @($node.Inlines)) { if ($inline -is [System.Windows.Documents.Run]) { [void]$texts.Add($inline.Text) } }
            }
            if ($node -is [System.Windows.Controls.ContentControl] -and $node.Content -is [string]) { [void]$texts.Add($node.Content) }
            if ($node -is [System.Windows.FrameworkElement] -and $node.ToolTip -is [string]) { [void]$texts.Add($node.ToolTip) }
            foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($node)) { if ($child -is [System.Windows.DependencyObject]) { $pending.Push($child) } }
        }
        $texts.ToArray()
    }

    # Lo que la ventana muestra en inglés y delata español, sin contar lo que viene de afuera (nombres de equipo, apps, gráficas).
    function Get-AfWindowLeftovers($Window, $Inventory) {
        $external = @(@($Inventory.Gpus | ForEach-Object { $_.Name }) + @($Inventory.Startup | ForEach-Object { $_.Name }) + @($Inventory.Security.Antivirus | ForEach-Object { $_.Name }) +
            @($Inventory.Apps.Promo | ForEach-Object { $_.Name }) + @($Inventory.VendorTools) + @($Inventory.Network | ForEach-Object { $_.Description }) +
            @($Inventory.Security.Defender.Threats | ForEach-Object { $_.Name; $_.Path }) + @($Inventory.Device.Model, $Inventory.Cpu.Name, $Inventory.Os.Caption) | Where-Object { $_ })
        # Los nombres de los idiomas se escriben siempre en su propio idioma.
        $external += 'Español', 'English'
        foreach ($text in Get-AfWindowTexts $Window) {
            $clean = [string]$text
            foreach ($name in $external) { $clean = $clean.Replace([string]$name, '') }
            Get-AfSpanishLeftovers $clean
        }
    }

    function New-EnglishWindow {
        $results = @(Get-AfCatalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $script:detuned })
        $window = New-AfWindow -Theme Black
        Set-AfPcCard -Window $window -Inventory $script:detuned
        Show-AfResults -Window $window -Results $results -Animate $false
        $window.Tag.BackupDirectory = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $window
    }
}

Describe 'La ventana en inglés' {
    AfterEach { Set-AfLanguage -Language es }

    It 'los textos fijos del XAML tienen traducción' {
        $xaml = Get-AfWindowXaml
        $values = [regex]::Matches($xaml, '(?:\bText|\bContent|\bToolTip|AutomationProperties\.Name)="([^"{][^"]*)"') | ForEach-Object { [System.Net.WebUtility]::HtmlDecode($_.Groups[1].Value) }
        $missing = @($values | Where-Object { $_ -match '\p{L}{2,}' -and $_ -notin 'Español', 'English', 'Afina' -and -not $script:AfStringsEn.ContainsKey($_) } | Select-Object -Unique)
        $missing | Should -BeNullOrEmpty
    }

    It 'en Preferencias, cada opción entra entera en los dos idiomas' {
        $cut = foreach ($language in 'es', 'en') {
            Set-AfLanguage -Language $language
            $window = New-AfWindow -Theme Black
            try {
                $panel = $window.FindName('Prefs').Child
                $panel.Measure((New-Object System.Windows.Size([double]::PositiveInfinity, [double]::PositiveInfinity)))
                $panel.Arrange((New-Object System.Windows.Rect($panel.DesiredSize)))
                foreach ($name in 'ThemeSystem', 'ThemeBlack', 'ThemeWhite', 'MotionAuto', 'MotionAlways', 'MotionNever', 'LangAuto', 'LangEs', 'LangEn') {
                    $radio = $window.FindName($name)
                    $room = $radio.ActualWidth
                    $radio.Measure((New-Object System.Windows.Size([double]::PositiveInfinity, [double]::PositiveInfinity)))
                    if ($radio.DesiredSize.Width -gt $room) { '{0}: {1} ({2:N1} > {3:N1})' -f $language, $radio.Content, $radio.DesiredSize.Width, $room }
                }
            } finally { $window.Close() }
        }
        @($cut) | Should -BeNullOrEmpty
    }

    It 'en inglés, la ventana con resultados no muestra español' {
        Set-AfLanguage -Language en
        $window = New-EnglishWindow
        try { @(Get-AfWindowLeftovers $window $script:detuned | Select-Object -Unique) | Should -BeNullOrEmpty } finally { $window.Close() }
    }

    It 'en inglés, la confirmación, Listo y el Historial no muestran español' {
        Set-AfLanguage -Language en
        Mock Test-AfAdmin { $true }
        Mock Get-AfRestoreStatus { [pscustomobject]@{ Enabled = $false; Blocked = $false } }
        $window = New-EnglishWindow
        try {
            Enter-AfConfirm -Window $window
            $confirm = @(Get-AfWindowLeftovers $window $script:detuned)
            $s = $window.Tag
            $s.Phase = 'applying'; $s.Applied = @{}; $s.ApplyTotal = 2; $s.ApplyCount = 0; $s.ApplyIndex = 1; $s.ApplyNote = ''; $s.RebootPending = $false
            $ok = [pscustomobject]@{ CheckId = 'gpu.hags'; Title = 'x'; NeedsReboot = $true; Status = 'Applied'; Message = $null; Note = $null; AppliedAt = $null; UndoneAt = $null; Records = @([pscustomobject]@{ Kind = 'RegistryValue' }) }
            $bad = [pscustomobject]@{ CheckId = 'gaming.game-mode'; Title = 'x'; NeedsReboot = $false; Status = 'Failed'; Message = (T 'No se pudo aplicar: {0}. No se cambió nada.') -f (T 'Windows no aceptó el cambio'); Note = $null; AppliedAt = $null; UndoneAt = $null; Records = @() }
            Receive-AfApplyEvent -Window $window -Item ([pscustomobject]@{ Type = 'ChangeDone'; Id = 'gpu.hags'; Change = $ok })
            Receive-AfApplyEvent -Window $window -Item ([pscustomobject]@{ Type = 'ChangeDone'; Id = 'gaming.game-mode'; Change = $bad })
            Receive-AfApplyEvent -Window $window -Item ([pscustomobject]@{ Type = 'ApplyDone'; SessionPath = $null })
            $done = @(Get-AfWindowLeftovers $window $script:detuned)
            $session = New-AfSession -Directory $s.BackupDirectory -User $script:user
            [void]$session.Changes.Add($ok); Save-AfSession -Session $session
            Show-AfHistory -Window $window
            $history = @(Get-AfWindowLeftovers $window $script:detuned)
            @($confirm + $done + $history | Select-Object -Unique) | Should -BeNullOrEmpty
        } finally { $window.Close() }
    }

    It 'Format-AfSessionDate según el idioma' {
        $when = ([datetime]'2026-11-21 16:42:33').ToString('o')
        Set-AfLanguage -Language es
        Format-AfSessionDate -Text $when | Should -Be '21 nov 2026, 16:42'
        Set-AfLanguage -Language en
        Format-AfSessionDate -Text $when | Should -Be 'Nov 21, 2026, 4:42 PM'
    }
}

Describe 'Cambiar de idioma' {
    BeforeEach { Set-AfLanguage -Language es }
    AfterEach { Set-AfLanguage -Language es }

    It 'elegir English guarda Language = en, traduce Preferencias y vuelve a analizar' {
        Mock Start-AfScan { }
        $window = New-EnglishWindow
        try {
            $s = $window.Tag
            $s.Config = Get-AfConfigDefaults
            $s.ConfigPath = Join-Path $TestDrive 'afina.config.json'
            Initialize-AfPrefs -Window $window
            $window.FindName('LangEn').IsChecked = $true
            $s.Config.Language | Should -Be 'en'
            Get-AfLanguage | Should -Be 'en'
            (Get-Content $s.ConfigPath -Raw | ConvertFrom-Json).Language | Should -Be 'en'
            $window.FindName('LangAuto').Content | Should -Be 'Automatic'
            Should -Invoke Start-AfScan -Times 1 -Exactly
        } finally { $window.Close() }
    }

    It 'cambiar a English deja la ventana sin textos en español' {
        Mock Start-AfScan { Show-AfResults -Window $Window -Results @(Get-AfCatalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $script:detuned }) -Animate $false }
        $window = New-EnglishWindow
        try {
            $window.Tag.Config = Get-AfConfigDefaults
            Initialize-AfPrefs -Window $window
            $window.FindName('LangEn').IsChecked = $true
            Set-AfPcCard -Window $window -Inventory $script:detuned
            @(Get-AfWindowLeftovers $window $script:detuned | Select-Object -Unique) | Should -BeNullOrEmpty
        } finally { $window.Close() }
    }

    It 'el selector se apaga mientras aplica' {
        $window = New-EnglishWindow
        try {
            $window.Tag.Phase = 'applying'
            Update-AfLanguageAvailability -Window $window
            $window.FindName('LangEn').IsEnabled | Should -BeFalse
            $window.FindName('LangEn').ToolTip | Should -Be 'Disponible al terminar'
            $window.Tag.Phase = 'ready'
            Update-AfLanguageAvailability -Window $window
            $window.FindName('LangEn').IsEnabled | Should -BeTrue
        } finally { $window.Close() }
    }

    It 'Automático elige según Windows al abrir' {
        Mock Get-UICulture { [System.Globalization.CultureInfo]::GetCultureInfo('en-US') }
        Set-AfStartLanguage -Config @{ Language = 'Auto' }
        Get-AfLanguage | Should -Be 'en'
        Set-AfStartLanguage -Config @{ Language = 'es' }
        Get-AfLanguage | Should -Be 'es'
    }

    It 'el trabajo de aplicar escribe sus motivos en el idioma del plan' {
        $check = @{
            Id = 'test.change'; Category = 'gaming'; Title = 'Cambio de prueba'; Why = 'x'; Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'
            Preselect = $true; NeedsReboot = $false; Source = 'x'; Undo = 'x'
            Detect = { param($inv) New-AfDetection -State Improvable }; Apply = { param($inv, $detected, $tx) throw (New-AfApplyError -Reason (T 'Windows no aceptó el cambio')) }
        }
        $queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
        $inv = New-AfFakeInventory -Override @{ User = (Get-AfUserForSid) }
        $plan = [pscustomobject]@{ Inventory = $inv; RestoreAction = 'off'; BackupDirectory = (Join-Path $TestDrive 'plan-en'); Version = 'prueba'; Language = 'en'
            Items = @([pscustomobject]@{ Id = 'test.change'; Detection = (New-AfDetection -State Improvable) }) }
        Invoke-AfApplyPlan -Plan $plan -Queue $queue -Shared ([hashtable]::Synchronized(@{})) -Catalog @($check)
        $done = @($queue.ToArray() | Where-Object { $_.Type -eq 'ChangeDone' })[0]
        $done.Change.Message | Should -Be "Couldn't apply: Windows didn't accept the change. Nothing was changed."
    }

    It 'una sesión en español se ve con títulos en inglés' {
        $window = New-EnglishWindow
        try {
            $session = New-AfSession -Directory $window.Tag.BackupDirectory -User $script:user
            $session.Language | Should -Be 'es'
            $change = [pscustomobject]@{ CheckId = 'gpu.hags'; Title = 'Programación de GPU por hardware'; NeedsReboot = $true; Status = 'Applied'; Message = $null; Note = $null; AppliedAt = $null; UndoneAt = $null; Records = @([pscustomobject]@{ Kind = 'RegistryValue' }) }
            [void]$session.Changes.Add($change); Save-AfSession -Session $session
            Set-AfLanguage -Language en
            Show-AfHistory -Window $window
            # Solo el Historial: la lista de resultados oculta detrás se armó en español antes del cambio.
            $texts = @(Get-AfWindowTexts $window.FindName('HistoryList'))
            $texts | Should -Contain 'Hardware-accelerated GPU scheduling'
            $texts | Should -Not -Contain 'Programación de GPU por hardware'
        } finally { $window.Close() }
    }

    It 'una sesión de antes de los idiomas (sin Language) cuenta como española' {
        $window = New-EnglishWindow
        try {
            $session = New-AfSession -Directory $window.Tag.BackupDirectory -User $script:user
            $session.PSObject.Properties.Remove('Language')
            $change = [pscustomobject]@{ CheckId = 'gpu.hags'; Title = 'Programación de GPU por hardware'; NeedsReboot = $true; Status = 'Applied'; Message = $null; Note = $null; AppliedAt = $null; UndoneAt = $null; Records = @([pscustomobject]@{ Kind = 'RegistryValue' }) }
            [void]$session.Changes.Add($change); Save-AfSession -Session $session
            Set-AfLanguage -Language en
            Show-AfHistory -Window $window
            @(Get-AfWindowTexts $window.FindName('HistoryList')) | Should -Contain 'Hardware-accelerated GPU scheduling'
        } finally { $window.Close() }
    }
}