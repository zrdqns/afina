BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    . "$PSScriptRoot\Helpers\Profiles.ps1"
    . "$PSScriptRoot\Helpers\Language.ps1"
    $script:detuned = New-AfDetunedInventory

    # Ventana con los resultados de la PC desafinada, como queda después de analizar.
    function New-LiveWindow([bool]$Motion = $false) {
        $results = @(Get-AfCatalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $script:detuned })
        $window = New-AfWindow -Theme Black
        Show-AfResults -Window $window -Results $results -Animate $false
        $window.Tag.Motion = $Motion
        $window.Tag.BackupDirectory = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $window
    }

    function Get-StepTexts($Row) { @($Row.FindName('Steps').Children | ForEach-Object { $_.Children[1].Text }) }
    function Get-StepStates($Row) { @($Row.FindName('Steps').Children | ForEach-Object { $_.Resources['State'] }) }

    # Lo que deja Start-AfApply, sin arrancar el trabajo.
    function Enter-TestApplying($Window, [int]$Total = 2) {
        $s = $Window.Tag
        $s.Phase = 'applying'; $s.Applied = @{}; $s.ApplyTotal = $Total; $s.ApplyIndex = 0; $s.ApplyCount = 0
        $s.ApplyNote = ''; $s.RebootPending = $false; $s.Follow = $true; $s.ApplyHoldUntil = [datetime]::MinValue
        $s.ApplyQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    }
    function Send-TestEvent($Window, [hashtable]$Event) { Receive-AfApplyEvent -Window $Window -Item ([pscustomobject]$Event) }
    function New-TestChange([string]$Id, [string]$Status = 'Applied') {
        [pscustomobject]@{ CheckId = $Id; Title = 'x'; NeedsReboot = $false; Status = $Status; Message = $(if ($Status -ne 'Applied') { 'No se pudo aplicar: motivo. No se cambió nada.' }); Note = $null; AppliedAt = $null; UndoneAt = $null; Records = @([pscustomobject]@{ Kind = 'RegistryValue' }) }
    }
    # Dos revisiones mejorables de categorías distintas, para seguir de una a otra.
    function Get-TwoRows($Window) {
        $rows = @(Get-AfRows -Window $Window | Where-Object { $_.Tag.Detection.State -eq 'Improvable' -and (Test-AfCanApply -Check $_.Tag.Check) })
        $first = $rows[0]
        $second = @($rows | Where-Object { $_.Tag.Check.Category -ne $first.Tag.Check.Category })[0]
        $first
        $second
    }
    function Get-SummaryText($Window) { (@($Window.FindName('Summary').Inlines) | ForEach-Object { $_.Text }) -join '' }
}

Describe 'Pasos dentro de la fila' {
    AfterEach { Set-AfLanguage -Language es }

    It 'Open-AfRowSteps arma una línea por clave' {
        $window = New-LiveWindow
        try {
            $row = Get-AfRowById -Window $window -Id 'gpu.hags'
            Open-AfRowSteps -Row $row -Keys @('save', 'apply', 'backup') -Motion $false
            @($row.FindName('Steps').Children | ForEach-Object Tag) | Should -Be @('save', 'apply', 'backup')
            Get-StepTexts $row | Should -Be @('Guardando el valor original', 'Aplicando', 'Guardando el respaldo')
            # El alto abierto deja ver las tres líneas (unos 20 px cada una).
            $row.FindName('Steps').MaxHeight | Should -BeGreaterThan 50
        } finally { $window.Close() }
    }

    It 'Set-AfRowStepState marca en curso con su detalle' {
        $window = New-LiveWindow
        try {
            $row = Get-AfRowById -Window $window -Id 'gpu.hags'
            Open-AfRowSteps -Row $row -Keys @('apply', 'backup') -Motion $false
            Set-AfRowStepState -Row $row -Key 'apply' -State Running -Detail 'Descargando 1 de 2'
            (Get-StepTexts $row)[0] | Should -Match 'Descargando 1 de 2'
            Set-AfRowStepState -Row $row -Key 'apply' -State Done
            (Get-StepTexts $row)[0] | Should -Be 'Aplicando'
            { Set-AfRowStepState -Row $row -Key 'save' -State Running } | Should -Not -Throw
        } finally { $window.Close() }
    }

    It 'Close-AfRowSteps deja la fila sin pasos' {
        $window = New-LiveWindow
        try {
            $row = Get-AfRowById -Window $window -Id 'gpu.hags'
            Open-AfRowSteps -Row $row -Keys @('save', 'apply', 'backup') -Motion $false
            Close-AfRowSteps -Row $row -Motion $false
            $row.FindName('Steps').Children.Count | Should -Be 0
            $row.FindName('Steps').MaxHeight | Should -Be 0
        } finally { $window.Close() }
    }

    It 'en inglés los pasos salen traducidos' {
        Set-AfLanguage -Language en
        $window = New-LiveWindow
        try {
            $row = Get-AfRowById -Window $window -Id 'gpu.hags'
            Open-AfRowSteps -Row $row -Keys @('save', 'apply', 'backup', 'restore') -Motion $false
            Get-StepTexts $row | Should -Be @('Saving the original value', 'Applying', 'Saving the backup', 'Restoring the original value')
        } finally { $window.Close() }
    }
}

Describe 'Seguir al cambio en curso' {
    AfterEach { Set-AfLanguage -Language es }

    It 'ChangeStart sigue a la categoría de la fila' {
        $window = New-LiveWindow
        try {
            Enter-TestApplying $window
            $a, $b = Get-TwoRows $window
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = $b.Tag.Check.Id }
            $window.Tag.Filter | Should -Be $b.Tag.Check.Category
        } finally { $window.Close() }
    }

    It 'ChangeStart abre los pasos y pone Optimizando' {
        $window = New-LiveWindow
        try {
            Enter-TestApplying $window 2
            $a, $b = Get-TwoRows $window
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = $a.Tag.Check.Id }
            $window.FindName('Title').Text | Should -Be 'Optimizando'
            $window.FindName('TitleCount').Text | Should -Be '1 de 2'
            $window.FindName('TitleCount').Visibility | Should -Be 'Visible'
            $expected = if ($a.Tag.Check.NoUndo) { @('apply', 'backup') } else { @('save', 'apply', 'backup') }
            @($a.FindName('Steps').Children | ForEach-Object Tag) | Should -Be $expected
        } finally { $window.Close() }
    }

    It 'ChangeStep marca el anterior hecho y el nuevo en curso' {
        $window = New-LiveWindow
        try {
            Enter-TestApplying $window
            $row = Get-AfRowById -Window $window -Id 'gpu.hags'
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = 'gpu.hags' }
            Send-TestEvent $window @{ Type = 'ChangeStep'; Id = 'gpu.hags'; Step = 'save' }
            Send-TestEvent $window @{ Type = 'ChangeStep'; Id = 'gpu.hags'; Step = 'apply' }
            Get-StepStates $row | Should -Be @('Done', 'Running', $null)
            Get-SummaryText $window | Should -Match 'Aplicando…'
        } finally { $window.Close() }
    }

    It 'un cambio que falla marca su paso en curso como fallido' {
        $window = New-LiveWindow
        try {
            Enter-TestApplying $window
            $row = Get-AfRowById -Window $window -Id 'gpu.hags'
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = 'gpu.hags' }
            Send-TestEvent $window @{ Type = 'ChangeStep'; Id = 'gpu.hags'; Step = 'save' }
            Send-TestEvent $window @{ Type = 'ChangeDone'; Id = 'gpu.hags'; Change = (New-TestChange 'gpu.hags' 'Failed') }
            Get-StepStates $row | Should -Be @('Failed', $null, $null)
            $row.FindName('Steps').Visibility | Should -Be 'Visible'
            $row.FindName('RowNote').Text | Should -Match 'motivo'
        } finally { $window.Close() }
    }

    It 'un cambio aplicado cierra sus pasos' {
        $window = New-LiveWindow
        try {
            Enter-TestApplying $window
            $row = Get-AfRowById -Window $window -Id 'gpu.hags'
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = 'gpu.hags' }
            Send-TestEvent $window @{ Type = 'ChangeDone'; Id = 'gpu.hags'; Change = (New-TestChange 'gpu.hags') }
            $row.FindName('Steps').Children.Count | Should -Be 0
        } finally { $window.Close() }
    }

    It 'elegir otra categoría mientras aplica pausa el seguimiento' {
        $window = New-LiveWindow
        try {
            Enter-TestApplying $window
            $a, $b = Get-TwoRows $window
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = $a.Tag.Check.Id }
            $other = @($window.Tag.Nav.Keys | Where-Object { $_ -notin 'all', 'ok', $a.Tag.Check.Category, $b.Tag.Check.Category })[0]
            $window.Tag.Nav[$other].Button.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = $b.Tag.Check.Id }
            $window.Tag.Filter | Should -Be $other
            $window.FindName('FollowChip').Visibility | Should -Be 'Visible'
        } finally { $window.Close() }
    }

    It 'Seguir el avance vuelve a la fila en curso' {
        $window = New-LiveWindow
        try {
            Enter-TestApplying $window
            $a, $b = Get-TwoRows $window
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = $a.Tag.Check.Id }
            Suspend-AfFollow -Window $window
            Set-AfFilter -Window $window -Filter 'ok'
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = $b.Tag.Check.Id }
            Resume-AfFollow -Window $window
            $window.Tag.Filter | Should -Be $b.Tag.Check.Category
            $window.FindName('FollowChip').Visibility | Should -Be 'Collapsed'
        } finally { $window.Close() }
    }

    It 'al terminar con el seguimiento pausado la vista se queda' {
        $window = New-LiveWindow
        try {
            Enter-TestApplying $window 1
            $a, $b = Get-TwoRows $window
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = $a.Tag.Check.Id }
            Suspend-AfFollow -Window $window
            Set-AfFilter -Window $window -Filter 'ok'
            Send-TestEvent $window @{ Type = 'ChangeDone'; Id = $a.Tag.Check.Id; Change = (New-TestChange $a.Tag.Check.Id) }
            Send-TestEvent $window @{ Type = 'ApplyDone'; SessionPath = $null }
            $window.Tag.Filter | Should -Be 'ok'
            $window.FindName('FollowChip').Visibility | Should -Be 'Collapsed'
            $window.FindName('TitleCount').Visibility | Should -Be 'Collapsed'
        } finally { $window.Close() }
    }

    It 'al terminar siguiendo la vista vuelve a Todo' {
        $window = New-LiveWindow
        try {
            Enter-TestApplying $window 1
            $a, $b = Get-TwoRows $window
            Send-TestEvent $window @{ Type = 'ChangeStart'; Id = $a.Tag.Check.Id }
            Send-TestEvent $window @{ Type = 'ChangeDone'; Id = $a.Tag.Check.Id; Change = (New-TestChange $a.Tag.Check.Id) }
            Send-TestEvent $window @{ Type = 'ApplyDone'; SessionPath = $null }
            $window.Tag.Filter | Should -Be 'all'
        } finally { $window.Close() }
    }

    It 'con animaciones, un evento de inicio hace esperar al siguiente' {
        $window = New-LiveWindow -Motion $true
        try {
            Enter-TestApplying $window
            foreach ($e in @(@{ Type = 'ChangeStart'; Id = 'gpu.hags' }, @{ Type = 'ChangeStep'; Id = 'gpu.hags'; Step = 'save' }, @{ Type = 'ChangeStep'; Id = 'gpu.hags'; Step = 'apply' })) { $window.Tag.ApplyQueue.Enqueue([pscustomobject]$e) }
            Receive-AfEvents -Window $window
            $window.Tag.ApplyQueue.Count | Should -Be 2
        } finally { $window.Close() }
    }

    It 'con seis o más eventos en cola se procesan sin esperar' {
        $window = New-LiveWindow -Motion $true
        try {
            Enter-TestApplying $window
            foreach ($id in 'gpu.hags', 'gaming.game-mode') {
                $window.Tag.ApplyQueue.Enqueue([pscustomobject]@{ Type = 'ChangeStart'; Id = $id })
                foreach ($step in 'save', 'apply', 'backup') { $window.Tag.ApplyQueue.Enqueue([pscustomobject]@{ Type = 'ChangeStep'; Id = $id; Step = $step }) }
            }
            Receive-AfEvents -Window $window
            $window.Tag.ApplyQueue.Count | Should -Be 0
        } finally { $window.Close() }
    }

    It 'en inglés el pie dice Preparing…' {
        Set-AfLanguage -Language en
        $window = New-LiveWindow
        try {
            Enter-TestApplying $window
            $window.Tag.ApplyNote = (T 'Preparando…')
            Set-AfApplyingFooter -Window $window
            $window.FindName('PrimaryLead').Text | Should -Be 'Preparing…'
            $window.FindName('NoteText').Text | Should -Be 'Preparing…'
        } finally { $window.Close() }
    }
}
Describe 'Deshacer en vivo' {
    It 'deshacer desde Listo sigue y muestra los pasos' {
        $window = New-LiveWindow
        try {
            $s = $window.Tag
            $s.Phase = 'undoing'; $s.UndoFromHistory = $false; $s.UndoIndex = 0; $s.UndoTotal = 1; $s.Follow = $true; $s.Applied = @{}
            $a, $b = Get-TwoRows $window
            Set-AfFilter -Window $window -Filter 'ok'
            Send-TestEvent $window @{ Type = 'UndoStart'; Id = $b.Tag.Check.Id }
            $s.Filter | Should -Be $b.Tag.Check.Category
            @($b.FindName('Steps').Children | ForEach-Object Tag) | Should -Be @('restore', 'backup')
            Send-TestEvent $window @{ Type = 'ChangeStep'; Id = $b.Tag.Check.Id; Step = 'restore' }
            Get-StepStates $b | Should -Be @('Running', $null)
        } finally { $window.Close() }
    }

    It 'deshacer desde el Historial muestra el paso en la línea' {
        $window = New-LiveWindow
        try {
            $s = $window.Tag
            $session = New-AfSession -Directory $s.BackupDirectory -User ([pscustomobject]@{ Name = 'PC\Cliente'; Sid = 'S-1-5-21-1' })
            [void]$session.Changes.Add((New-TestChange 'gpu.hags')); Save-AfSession -Session $session
            Show-AfHistory -Window $window
            $s.Phase = 'undoing'; $s.UndoFromHistory = $true; $s.UndoIndex = 0; $s.UndoTotal = 1; $s.UndoSessionPath = $session.Path
            Send-TestEvent $window @{ Type = 'UndoStart'; Id = 'gpu.hags' }
            Send-TestEvent $window @{ Type = 'ChangeStep'; Id = 'gpu.hags'; Step = 'restore' }
            $card = @($window.FindName('HistoryList').Children | Where-Object { $_.Tag -eq $session.Path })[0]
            $line = @($card.Child.Children | Where-Object { $_.Tag -eq 'gpu.hags' })[0]
            @($line.Children | Where-Object { $_ -is [System.Windows.Controls.Button] }).Count | Should -Be 0
            $texts = @($line.Children | ForEach-Object { if ($_ -is [System.Windows.Controls.Panel]) { $_.Children } else { $_ } } | Where-Object { $_ -is [System.Windows.Controls.TextBlock] } | ForEach-Object Text)
            $texts | Should -Contain 'Restaurando el valor original'
        } finally { $window.Close() }
    }
}
Describe 'Tarjetas de estado' {
    BeforeAll {
        $script:profiles = Get-AfProfileInventories
        # Ventana con un perfil donde Red no tiene nada para cambiar.
        function New-ProfileWindow([string]$Profile, [switch]$OnlyOk) {
            $results = @(Get-AfCatalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $script:profiles[$Profile] })
            if ($OnlyOk) { $results = @($results | Where-Object { $_.Detection.State -in 'Ok', 'NotApplicable' }) }
            $window = New-AfWindow -Theme Black
            Show-AfResults -Window $window -Results $results -Animate $false
            $window.Tag.BackupDirectory = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            $window
        }
        function Get-Texts($Root) {
            $texts = New-Object System.Collections.ArrayList
            $pending = New-Object System.Collections.Stack
            $pending.Push($Root)
            while ($pending.Count) {
                $node = $pending.Pop()
                if ($node -is [System.Windows.Controls.TextBlock]) { [void]$texts.Add($node.Text) }
                foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($node)) { if ($child -is [System.Windows.DependencyObject]) { $pending.Push($child) } }
            }
            $texts.ToArray()
        }
    }
    AfterEach { Set-AfLanguage -Language es }

    It 'una categoría sin cambios muestra su tarjeta con lo revisado' {
        $window = New-ProfileWindow 'noDriver'
        try {
            Set-AfFilter -Window $window -Filter 'network'
            $window.FindName('EmptyState').Visibility | Should -Be 'Visible'
            $window.FindName('PanelBorder').Visibility | Should -Be 'Collapsed'
            $texts = @(Get-Texts $window.FindName('EmptyState'))
            $texts | Should -Contain 'Red en orden'
            $ok = @($window.Tag.Results | Where-Object { $_.Check.Category -eq 'network' -and $_.Detection.State -eq 'Ok' -and $_.Detection.Current })[0]
            if ($ok) { $texts | Should -Contain ([string]$ok.Detection.Current) }
            $n = @($window.Tag.Results | Where-Object { $_.Check.Category -eq 'network' }).Count
            ($texts -join ' ') | Should -Match ([regex]::Escape($(if ($n -eq 1) { 'Se revisó 1 punto' } else { "Se revisaron $n puntos" })))
        } finally { $window.Close() }
    }

    It 'Todo sin cambios muestra Esta PC está afinada' {
        $window = New-ProfileWindow 'noDriver' -OnlyOk
        try {
            Set-AfFilter -Window $window -Filter 'all'
            $window.FindName('EmptyState').Visibility | Should -Be 'Visible'
            @(Get-Texts $window.FindName('EmptyState')) | Should -Contain 'Esta PC está afinada'
        } finally { $window.Close() }
    }

    It 'una categoría con cambios no muestra tarjeta' {
        $window = New-ProfileWindow 'noDriver'
        try {
            Set-AfFilter -Window $window -Filter 'gaming'
            $window.FindName('EmptyState').Visibility | Should -Be 'Collapsed'
            $window.FindName('PanelBorder').Visibility | Should -Be 'Visible'
        } finally { $window.Close() }
    }

    It 'un resultado en segundo plano que deja la categoría en orden muestra su tarjeta' {
        $window = New-ProfileWindow 'broken'
        try {
            $rows = @(Get-AfRows -Window $window | Where-Object { $_.Tag.Check.Category -eq 'energy' })
            Set-AfFilter -Window $window -Filter 'energy'
            foreach ($row in $rows) { Update-AfAsyncResult -Window $window -Id $row.Tag.Check.Id -Detection (New-AfDetection -State Ok -Current 'Bien') }
            $window.FindName('EmptyState').Visibility | Should -Be 'Visible'
            @(Get-Texts $window.FindName('EmptyState')) | Should -Contain 'Energía en orden'
        } finally { $window.Close() }
    }

    It 'el Historial vacío explica para qué sirve' {
        $window = New-ProfileWindow 'noDriver'
        try {
            Show-AfHistory -Window $window
            $texts = @(Get-Texts $window.FindName('HistoryList'))
            $texts | Should -Contain 'Todavía no hay cambios en esta PC'
            $texts | Should -Contain 'Cada vez que optimizas, Afina guarda aquí los valores originales para deshacerlos cuando quieras.'
        } finally { $window.Close() }
    }

    It 'en inglés las tarjetas no muestran español' {
        Set-AfLanguage -Language en
        Initialize-AfVocabulary
        $window = New-ProfileWindow 'noDriver'
        try {
            Set-AfFilter -Window $window -Filter 'network'
            $card = @(Get-Texts $window.FindName('EmptyState'))
            Set-AfFilter -Window $window -Filter 'all'
            Show-AfHistory -Window $window
            $history = @(Get-Texts $window.FindName('HistoryList'))
            $left = @($card + $history | ForEach-Object { Get-AfSpanishLeftovers ([string]$_) } | Select-Object -Unique)
            $left | Should -BeNullOrEmpty
            $card | Should -Contain 'Network all good'
        } finally { $window.Close() }
    }
}
Describe 'Análisis que se arma' {
    BeforeEach { Mock Start-AfScanWorker { [pscustomobject]@{ PowerShell = $null; Runspace = $null; Handle = $null } } }

    It 'al empezar el análisis hay un grupo fantasma por categoría' {
        $window = New-AfWindow -Theme Black
        try {
            Start-AfScan -Window $window
            $groups = $window.FindName('Groups')
            @($groups.Children | Where-Object { "$($_.Tag)" -like 'skeleton:*' }).Count | Should -Be (@(Get-AfCategories).Count - 1)
            $window.FindName('PanelBorder').Visibility | Should -Be 'Visible'
        } finally { $window.Close() }
    }

    It 'una categoría con cambios reemplaza a su fantasma en el mismo lugar' {
        $window = New-AfWindow -Theme Black
        try {
            Start-AfScan -Window $window
            $groups = $window.FindName('Groups')
            $index = $groups.Children.IndexOf(@($groups.Children | Where-Object { $_.Tag -eq 'skeleton:gaming' })[0])
            $category = @(Get-AfCategories | Where-Object Id -eq 'gaming')[0]
            $results = @(Get-AfCatalog | Where-Object Category -eq 'gaming' | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $script:detuned })
            Add-AfCategoryGroup -Window $window -Category $category -Results $results -Motion $false
            $groups.Children[$index].Tag | Should -Be 'gaming'
            @($groups.Children | Where-Object { $_.Tag -eq 'skeleton:gaming' }).Count | Should -Be 0
        } finally { $window.Close() }
    }

    It 'una categoría en orden cierra su fantasma' {
        $window = New-AfWindow -Theme Black
        try {
            Start-AfScan -Window $window
            $category = @(Get-AfCategories | Where-Object Id -eq 'network')[0]
            Add-AfCategoryGroup -Window $window -Category $category -Results @() -Motion $false
            @($window.FindName('Groups').Children | Where-Object { $_.Tag -eq 'skeleton:network' }).Count | Should -Be 0
        } finally { $window.Close() }
    }

    It 'al terminar no queda ningún fantasma' {
        $window = New-AfWindow -Theme Black
        try {
            Start-AfScan -Window $window
            Complete-AfScan -Window $window
            @($window.FindName('Groups').Children | Where-Object { "$($_.Tag)" -like 'skeleton*' }).Count | Should -Be 0
        } finally { $window.Close() }
    }

    It 'la tarjeta de la PC cambia el esqueleto por los datos' {
        $window = New-AfWindow -Theme Black
        try {
            Start-AfScan -Window $window
            $window.FindName('PcSkeleton').Visibility | Should -Be 'Visible'
            $window.FindName('PcSkeleton').Children.Count | Should -BeGreaterThan 5
            Set-AfPcCard -Window $window -Inventory $script:detuned
            $window.FindName('PcSkeleton').Visibility | Should -Be 'Collapsed'
            $window.FindName('PcCard').Opacity | Should -Be 1
        } finally { $window.Close() }
    }
}
Describe 'Pulido final' {
    AfterEach { Set-AfLanguage -Language es }

    It 'en inglés la tarjeta de una PC gamer con doble canal no muestra español' {
        Set-AfLanguage -Language en
        $inv = New-AfDetunedInventory
        $inv.Device.IsLaptop = $true
        $inv.Gpus = @([pscustomobject]@{ Name = 'NVIDIA GeForce RTX 3060 Laptop GPU'; Vendor = 'NVIDIA'; IsDiscrete = $true; HasDriver = $true })
        $inv.Memory = [pscustomobject]@{ TotalGB = 16; Socketed = $true; Modules = @([pscustomobject]@{ SizeGB = 8 }, [pscustomobject]@{ SizeGB = 8 }) }
        $window = New-AfWindow -Theme Black
        try {
            Set-AfPcCard -Window $window -Inventory $inv
            $window.FindName('PcKind').Text | Should -Be 'Gaming laptop'
            @($window.FindName('Specs').Children | ForEach-Object { $_.Children[1].Text }) | Should -Contain '16 GB, dual channel'
        } finally { $window.Close() }
    }

    It 'la cuenta de la barra lateral cambia sin perder el valor' {
        $window = New-LiveWindow -Motion $true
        try {
            $before = $window.Tag.Nav['gaming'].Count
            Set-AfNavCount -Window $window -Category 'gaming' -Count ($before + 1) -Motion $true
            $element = @($window.Tag.Nav['gaming'].CountHost.Children)[0]
            $element.Text | Should -Be ([string]($before + 1))
            $element.RenderTransform | Should -BeOfType ([System.Windows.Media.ScaleTransform])
            Set-AfNavCount -Window $window -Category 'gaming' -Count ($before + 1) -Motion $true
            @($window.Tag.Nav['gaming'].CountHost.Children)[0].RenderTransform | Should -Not -BeOfType ([System.Windows.Media.ScaleTransform])
        } finally { $window.Close() }
    }
}
Describe 'Ajustes de Windows y lecturas' {
    BeforeAll {
        # Resultado inventado a partir de una revisión real: cambia categoría, id, estado y si es lectura.
        function New-FakeResult([string]$Category, [string]$Id, [string]$State, [bool]$Reading = $false, [string]$Current = 'valor', [bool]$Preselected = $false) {
            $kind = if ($State -eq 'Improvable') { 'Auto' } else { 'Manual' }
            $base = @(Get-AfCatalog | Where-Object { $_.Kind -eq $kind })[0]
            $check = $base.Clone()
            $check.Id = $Id; $check.Category = $Category; $check.Title = "Titulo $Id"
            if ($Reading) { $check.Reading = $true }
            [pscustomobject]@{ Check = $check; Detection = (New-AfDetection -State $State -Current $Current -Target 'meta'); Weight = 2; Preselected = $Preselected }
        }
        function New-FakeWindow([object[]]$Results) {
            $window = New-AfWindow -Theme Black
            Show-AfResults -Window $window -Results $Results -Animate $false
            $window.Tag.Motion = $false
            $window
        }
        function Get-GroupByTag($Window, [string]$Tag) { @($Window.FindName('Groups').Children | Where-Object { $_.Tag -eq $Tag })[0] }
    }

    It 'windows no aparece en Todo' {
        $window = New-FakeWindow @(New-FakeResult 'windows' 'w.one' 'Improvable')
        try {
            Set-AfFilter -Window $window -Filter 'all'
            (Get-GroupByTag $window 'windows').Visibility | Should -Be 'Collapsed'
            Set-AfFilter -Window $window -Filter 'windows'
            (Get-GroupByTag $window 'windows').Visibility | Should -Be 'Visible'
        } finally { $window.Close() }
    }

    It 'lo marcado en windows se aplica aunque no se vea' {
        $window = New-FakeWindow @(New-FakeResult 'windows' 'w.one' 'Improvable' -Preselected $true)
        try {
            Set-AfFilter -Window $window -Filter 'all'
            (Get-AfRowCheckBox -Row (Get-AfRowById -Window $window -Id 'w.one')).IsChecked = $true
            Get-AfSelectedCount -Window $window | Should -Be 1
        } finally { $window.Close() }
    }

    It 'windows no muestra número' {
        $window = New-FakeWindow @()
        try {
            Set-AfNavCount -Window $window -Category windows -Count 3
            $window.Tag.Nav['windows'].CountHost.Children.Count | Should -Be 0
        } finally { $window.Close() }
    }

    It 'una lectura Ok se queda en su grupo y no en En orden' {
        $window = New-FakeWindow @(New-FakeResult 'hardware' 'h.read' 'Ok' -Reading $true)
        try {
            Get-AfRowById -Window $window -Id 'h.read' | Should -Not -BeNullOrEmpty
            (Get-GroupByTag $window 'hardware') | Should -Not -BeNullOrEmpty
            Get-GroupByTag $window 'ok' | Should -BeNullOrEmpty
        } finally { $window.Close() }
    }

    It 'una lectura Ok muestra su valor' {
        $window = New-FakeWindow @(New-FakeResult 'hardware' 'h.read' 'Ok' -Reading $true -Current 'Estado sano')
        try {
            $sub = (Get-AfRowById -Window $window -Id 'h.read').FindName('RowSub')
            $sub.Visibility | Should -Be 'Visible'
            @($sub.Children | Where-Object { $_.Text -eq 'Estado sano' }).Count | Should -Be 1
        } finally { $window.Close() }
    }

    It 'con solo lecturas sanas sale Esta PC está afinada' {
        $window = New-FakeWindow @(New-FakeResult 'hardware' 'h.read' 'Ok' -Reading $true)
        try {
            Set-AfFilter -Window $window -Filter 'all'
            $window.FindName('EmptyState').Visibility | Should -Be 'Visible'
        } finally { $window.Close() }
    }

    It 'Diagnóstico con solo lecturas no repite la tarjeta' {
        $window = New-FakeWindow @(New-FakeResult 'hardware' 'h.read' 'Ok' -Reading $true)
        try {
            Set-AfFilter -Window $window -Filter 'hardware'
            $window.FindName('EmptyState').Visibility | Should -Be 'Collapsed'
        } finally { $window.Close() }
    }

    It 'una lectura async que llega en Ok no se borra' {
        $window = New-FakeWindow @(New-FakeResult 'hardware' 'h.read' 'Info' -Reading $true)
        try {
            Update-AfAsyncResult -Window $window -Id 'h.read' -Detection (New-AfDetection -State Ok -Current 'Sano')
            Get-AfRowById -Window $window -Id 'h.read' | Should -Not -BeNullOrEmpty
        } finally { $window.Close() }
    }

    It 'una lectura async No aplica se borra' {
        $window = New-FakeWindow @(New-FakeResult 'hardware' 'h.read' 'Info' -Reading $true)
        try {
            Update-AfAsyncResult -Window $window -Id 'h.read' -Detection (New-AfDetection -State NotApplicable)
            Get-AfRowById -Window $window -Id 'h.read' | Should -BeNullOrEmpty
        } finally { $window.Close() }
    }

    It 'lectura tardía mientras aplica no cambia el título' {
        $window = New-FakeWindow @(New-FakeResult 'hardware' 'hardware.disk-health' 'Info' -Reading $true)
        try {
            $window.Tag.Phase = 'applying'
            $window.FindName('Title').Text = 'Aplicando'
            Update-AfAsyncResult -Window $window -Id 'hardware.disk-health' -Detection (New-AfDetection -State Manual -Current 'Mal')
            $window.FindName('Title').Text | Should -Be 'Aplicando'
        } finally { $window.Close() }
    }

    It 'lectura tardía celebra una sola vez' {
        Mock Start-AfCelebration {}
        $window = New-FakeWindow @(New-FakeResult 'hardware' 'hardware.disk-health' 'Info' -Reading $true)
        try {
            $window.Tag.Phase = 'ready'
            $window.Tag.Celebrated = $false
            Update-AfAsyncResult -Window $window -Id 'hardware.disk-health' -Detection (New-AfDetection -State Ok -Current 'Sano')
            Update-AfAsyncResult -Window $window -Id 'hardware.disk-health' -Detection (New-AfDetection -State Ok -Current 'Sano')
            Should -Invoke Start-AfCelebration -Times 1 -Exactly
        } finally { $window.Close() }
    }

    It 'la barra llega a todas las entradas en la ventana mínima' {
        $window = New-FakeWindow @()
        try {
            Set-AfPcCard -Window $window -Inventory $script:detuned
            $window.Height = 600
            $window.Show()
            $window.UpdateLayout()
            $scroll = $window.FindName('NavScroll')
            $scroll.ScrollableHeight | Should -BeGreaterThan 0
            $scroll.ScrollToBottom()
            $window.UpdateLayout()
            $button = $window.Tag.Nav['ok'].Button
            $point = $button.TranslatePoint((New-Object System.Windows.Point(0, $button.ActualHeight)), $scroll)
            $point.Y | Should -BeLessOrEqual ($scroll.ViewportHeight + 1)
        } finally { $window.Close() }
    }
}
