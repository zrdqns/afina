BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    function New-StartupEntry([string]$Name) {
        [pscustomobject]@{
            Name = $Name; Command = "C:\Apps\$Name.exe"; Path = "C:\Apps\$Name.exe"; Source = 'Run'; Scope = 'User'; Enabled = $true
            ApprovedKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'; ApprovedName = $Name
            IsSigned = $true; Signer = $Name; InUserWritablePath = $false
        }
    }
    function Get-FakeResults([hashtable]$Override = @{}) {
        $values = @{
            Registry = @{ 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode' = 1; 'HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled' = 0 }
            Startup = @((New-StartupEntry 'EpicGamesLauncher'), (New-StartupEntry 'Steam'))
        }
        foreach ($key in $Override.Keys) { $values[$key] = $Override[$key] }
        $inv = New-AfFakeInventory -Override $values
        @(Get-AfCatalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $inv })
    }
    function New-TestWindow($Results = (Get-FakeResults)) {
        $window = New-AfWindow -Theme Black
        Show-AfResults -Window $window -Results $Results -Animate $false
        $window
    }
    function New-Change([string]$Id, [string]$Status = 'Applied', [bool]$Reboot = $false) {
        [pscustomobject]@{ CheckId = $Id; Title = $Id; NeedsReboot = $Reboot; Status = $Status; Message = $null; Note = $null; AppliedAt = $null; UndoneAt = $null; Records = @([pscustomobject]@{ Kind = 'RegistryValue' }) }
    }
    function Start-FakeApply($Window, [int]$Total = 1) {
        $s = $Window.Tag
        $s.Phase = 'applying'; $s.Applied = @{}; $s.ApplyTotal = $Total; $s.ApplyCount = 0; $s.ApplyIndex = 1; $s.ApplyNote = 'Punto de restauración creado a las 16:42.'; $s.RebootPending = $false
    }
}

Describe 'Textos de aplicar' {
    It 'Get-AfConfirmText arma las frases exactas' {
        Get-AfConfirmText -Count 7 -Network $true -Restore create | Should -Be 'Se aplicarán 7 cambios. La red se cortará unos segundos. Se crea un punto de restauración antes.'
        Get-AfConfirmText -Count 1 -Display $true -Reboot 1 -Restore enable | Should -Be 'Se aplicará 1 cambio. La pantalla cambia y pide confirmar. Al final pide reiniciar. Se activa Restaurar sistema y se crea un punto antes.'
        Get-AfConfirmText -Count 2 -Restore off | Should -Be 'Se aplicarán 2 cambios. Sin punto de restauración: Restaurar sistema está apagado. Los valores originales igual se guardan.'
        Get-AfConfirmText -Count 2 -Restore blocked | Should -Be 'Se aplicarán 2 cambios. Restaurar sistema está bloqueado en esta PC; los valores originales igual se guardan.'
    }

    It 'la confirmación avisa que las actualizaciones tardan y cuántos cambios bajan la seguridad' {
        Get-AfConfirmText -Count 2 -Updates $true -Advanced 1 -Restore create | Should -Be 'Se aplicarán 2 cambios. Las actualizaciones pueden tardar varios minutos. 1 cambio baja la seguridad de Windows. Se crea un punto de restauración antes.'
        Get-AfConfirmText -Count 3 -Advanced 2 -Network $true -Restore create | Should -Be 'Se aplicarán 3 cambios. 2 cambios bajan la seguridad de Windows. La red se cortará unos segundos. Se crea un punto de restauración antes.'
    }

    It 'Get-AfDoneText da los resúmenes exactos' {
        (Get-AfDoneText -Applied 7 -Reboot 1 -Manual 2).Text | Should -Be '7 cambios aplicados. Reinicia para terminar 1. Quedan 2 para hacer a mano.'
        (Get-AfDoneText -Applied 6 -Failed 1).Text | Should -Be '6 cambios aplicados y 1 no se pudo.'
        (Get-AfDoneText -Applied 1 -Manual 1).Text | Should -Be '1 cambio aplicado. Queda 1 para hacer a mano.'
        (Get-AfDoneText -Applied 0 -Failed 2).Text | Should -Be 'Ningún cambio aplicado y 2 no se pudieron.'
        (Get-AfDoneText -Applied 7 -Reboot 1).Lead | Should -Be '7 cambios aplicados'
    }

    It 'Get-AfDisplayPrompt cuenta los segundos' {
        Get-AfDisplayPrompt -Seconds 12 | Should -Be '¿Se ve bien la pantalla? Vuelve sola al modo anterior en 12 s.'
    }
}

Describe 'Pie y confirmación' {
    It 'Set-AfFooter oculta los botones sin texto' {
        $w = New-TestWindow
        Set-AfFooter -Window $w -Note 'Nota de prueba' -Primary 'Aplicar'
        $w.FindName('GhostButton').Visibility | Should -Be 'Collapsed'
        $w.FindName('ExtraButton').Visibility | Should -Be 'Collapsed'
        $w.FindName('PrimaryLead').Text | Should -Be 'Aplicar'
        $w.FindName('NoteText').Text | Should -Be 'Nota de prueba'
        $w.Close()
    }

    It 'Enter-AfConfirm pone Aplicar y Cancelar y bloquea la lista' {
        Mock Test-AfAdmin { $true }
        Mock Get-AfRestoreStatus { [pscustomobject]@{ Enabled = $true; Blocked = $false } }
        $w = New-TestWindow
        Enter-AfConfirm -Window $w
        $w.Tag.Phase | Should -Be 'confirm'
        $w.FindName('PrimaryLead').Text | Should -Be 'Aplicar'
        $w.FindName('GhostText').Text | Should -Be 'Cancelar'
        $w.FindName('Groups').IsHitTestVisible | Should -BeFalse
        $w.FindName('NoteText').Text | Should -Match '^Se aplicarán \d+ cambios\. .*Se crea un punto de restauración antes\.$'
        $w.FindName('RestoreRow').Visibility | Should -Be 'Collapsed'
        Exit-AfConfirm -Window $w
        $w.Tag.Phase | Should -Be 'ready'
        $w.FindName('Groups').IsHitTestVisible | Should -BeTrue
        $w.FindName('PrimaryLead').Text | Should -Be 'Optimizar '
        $w.Close()
    }

    It 'con Restaurar sistema apagado ofrece activarlo marcado y el texto cambia al desmarcar' {
        Mock Test-AfAdmin { $true }
        Mock Get-AfRestoreStatus { [pscustomobject]@{ Enabled = $false; Blocked = $false } }
        $w = New-TestWindow
        Enter-AfConfirm -Window $w
        $w.FindName('RestoreRow').Visibility | Should -Be 'Visible'
        $w.FindName('RestoreOption').IsChecked | Should -BeTrue
        $w.FindName('NoteText').Text | Should -Match 'Se activa Restaurar sistema'
        $w.FindName('RestoreOption').IsChecked = $false
        Get-AfConfirmNote -Window $w | Should -Match 'Sin punto de restauración'
        $w.Close()
    }

    It 'sin administrador no entra en confirmación' {
        Mock Test-AfAdmin { $false }
        $w = New-TestWindow
        Enter-AfConfirm -Window $w
        $w.Tag.Phase | Should -Be 'ready'
        $w.FindName('NoteText').Text | Should -Be 'Para aplicar cambios, abre Afina como administrador.'
        $w.Close()
    }
}

Describe 'Filas al aplicar' {
    It 'Set-AfRowStatus Failed muestra el mensaje y quita la casilla' {
        $w = New-TestWindow
        $row = Get-AfRowById -Window $w -Id 'gpu.hags'
        Set-AfRowStatus -Row $row -Status Failed -Message 'No se pudo aplicar: Windows no aceptó el cambio. No se cambió nada.'
        Get-AfRowCheckBox -Row $row | Should -BeNullOrEmpty
        $row.FindName('RowNote').Text | Should -Be 'No se pudo aplicar: Windows no aceptó el cambio. No se cambió nada.'
        $row.FindName('RowNote').Visibility | Should -Be 'Visible'
        $w.Close()
    }

    It 'Reset-AfRow vuelve a poner la casilla marcada' {
        $w = New-TestWindow
        $row = Get-AfRowById -Window $w -Id 'gpu.hags'
        Set-AfRowStatus -Row $row -Status Applied
        $new = Reset-AfRow -Row $row
        (Get-AfRowCheckBox -Row $new).IsChecked | Should -BeTrue
        (Get-AfRowById -Window $w -Id 'gpu.hags') | Should -Be $new
        $w.Close()
    }

    It 'desmarcar todas las opciones de inicio desmarca la fila y baja el contador; marcarla devuelve las preseleccionadas' {
        $w = New-TestWindow
        $row = Get-AfRowById -Window $w -Id 'startup.apps'
        $before = Get-AfSelectedCount -Window $w
        $boxes = @($row.Resources['ChoiceBoxes'])
        $boxes.Count | Should -Be 2
        foreach ($box in $boxes) { $box.IsChecked = $false; Sync-AfChoice -Box $box }
        (Get-AfRowCheckBox -Row $row).IsChecked | Should -BeFalse
        Get-AfSelectedCount -Window $w | Should -Be ($before - 1)
        Reset-AfChoices -Row $row
        @($row.Tag.Detection.Data.Choices | Where-Object Selected | ForEach-Object Name) | Should -Be @('EpicGamesLauncher')
        $w.Close()
    }

    It 'una fila que no se deshace y pide reiniciar avisa primero que no se deshace' {
        $w = New-TestWindow
        Update-AfAsyncResult -Window $w -Id 'updates.windows' -Detection (New-AfDetection -State Improvable -Current '1 disponible' -Target 'Instaladas')
        $tag = (Get-AfRowById -Window $w -Id 'updates.windows').FindName('RowTag')
        @($tag.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] })[0].Text | Should -Be 'No se puede deshacer'
        $w.Close()
    }

    It 'la etiqueta No se puede deshacer sale también en inglés' {
        Set-AfLanguage -Language en
        try {
            $w = New-TestWindow
            Update-AfAsyncResult -Window $w -Id 'updates.windows' -Detection (New-AfDetection -State Improvable -Current '1' -Target 'x')
            $tag = (Get-AfRowById -Window $w -Id 'updates.windows').FindName('RowTag')
            @($tag.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] })[0].Text | Should -Be "Can't be undone"
            $w.Close()
        } finally { Set-AfLanguage -Language es }
    }

    It 'marcar una fila sin opciones no falla' {
        $w = New-TestWindow
        $row = Get-AfRowById -Window $w -Id 'gpu.hags'
        { Reset-AfChoices -Row $row } | Should -Not -Throw
        $w.Close()
    }

    It 'el detalle usa el nombre de la lista de opciones' {
        $check = @(Get-AfCatalog) | Where-Object { $_.Id -eq 'startup.apps' }
        $choice = [pscustomobject]@{ Name = 'Firefox'; Label = 'Firefox (1 → 2)'; Selected = $false; Preselected = $true }
        $detection = New-AfDetection -State Improvable -Data @{ Choices = @($choice); ChoicesLabel = 'Apps' }
        $panel = New-AfDetailContent -Result ([pscustomobject]@{ Check = $check; Detection = $detection })
        $texts = @($panel.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] } | ForEach-Object { $_.Text })
        $texts | Should -Contain 'Apps'
        $texts | Should -Not -Contain 'Programas'
    }

    It 'una revisión Auto sin Apply no tiene casilla y dice En la próxima versión' {
        $apps = [pscustomobject]@{ Promo = @([pscustomobject]@{ Name = 'Candy Crush'; PackageName = 'king.com.CandyCrushSaga'; PackageFullName = 'king.com.CandyCrushSaga_1'; StoreId = '9NBLGGH18846'; Provisioned = $false }) }
        $results = Get-FakeResults -Override @{ Apps = $apps }
        $promo = $results | Where-Object { $_.Check.Id -eq 'cleanup.promo-apps' }
        $withoutApply = $promo.Check.Clone()
        $withoutApply.Remove('Apply')
        $promo.Check = $withoutApply
        $w = New-TestWindow -Results $results
        $row = Get-AfRowById -Window $w -Id 'cleanup.promo-apps'
        Get-AfRowCheckBox -Row $row | Should -BeNullOrEmpty
        $tag = $row.FindName('RowTag')
        $tag.Visibility | Should -Be 'Visible'
        @($tag.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] })[0].Text | Should -Be 'En la próxima versión'
        $w.Close()
    }
}

Describe 'Aplicar en la ventana' {
    It 'ChangeProgress muestra el texto en la fila sin cambiar su estado' {
        $w = New-TestWindow
        Start-FakeApply -Window $w
        Receive-AfApplyEvent -Window $w -Item ([pscustomobject]@{ Type = 'ChangeStart'; Id = 'gpu.hags' })
        $row = Get-AfRowById -Window $w -Id 'gpu.hags'
        $spinner = @($row.FindName('Lead').Children)[0]
        Receive-AfApplyEvent -Window $w -Item ([pscustomobject]@{ Type = 'ChangeProgress'; Id = 'gpu.hags'; Text = 'Descargando 1 de 2' })
        $note = $row.FindName('RowNote')
        $note.Text | Should -Be 'Descargando 1 de 2'
        $note.Visibility | Should -Be 'Visible'
        @($row.FindName('Lead').Children)[0] | Should -Be $spinner
        $w.Close()
    }

    It 'Enter-AfConfirm cuenta las actualizaciones y los cambios que bajan la seguridad' {
        Mock Test-AfAdmin { $true }
        Mock Get-AfRestoreStatus { [pscustomobject]@{ Enabled = $true; Blocked = $false } }
        $security = (New-AfFakeInventory).Security
        $security.HvciRunning = $true
        $registry = @{
            'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode' = 1; 'HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled' = 0
            'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity|Enabled' = 1
        }
        $w = New-TestWindow -Results (Get-FakeResults -Override @{ Security = $security; Registry = $registry })
        Update-AfAsyncResult -Window $w -Id 'updates.windows' -Detection (New-AfDetection -State Improvable -Current '1 disponible' -Target 'Instaladas')
        foreach ($id in 'advanced.memory-integrity', 'updates.windows') { (Get-AfRowCheckBox -Row (Get-AfRowById -Window $w -Id $id)).IsChecked = $true }
        Enter-AfConfirm -Window $w
        $w.Tag.Confirm.Updates | Should -BeTrue
        $w.Tag.Confirm.Advanced | Should -Be 1
        Get-AfConfirmNote -Window $w | Should -BeLike '*Las actualizaciones pueden tardar varios minutos. 1 cambio baja la seguridad de Windows.*'
        $w.Close()
    }

    It 'ChangeDone Applied pone la fila en Applied, mueve la aguja y anota el reinicio' {
        $w = New-TestWindow
        Start-FakeApply -Window $w
        $before = Get-AfScore -Results @(Get-AfEffectiveResults -Window $w)
        Receive-AfApplyEvent -Window $w -Item ([pscustomobject]@{ Type = 'ChangeDone'; Id = 'gpu.hags'; Change = (New-Change -Id 'gpu.hags' -Reboot $true) })
        Get-AfRowCheckBox -Row (Get-AfRowById -Window $w -Id 'gpu.hags') | Should -BeNullOrEmpty
        $w.Tag.NeedleF | Should -BeGreaterThan $before
        $w.Tag.RebootPending | Should -BeTrue
        $w.Close()
    }

    It 'ApplyDone con un cambio que pide reinicio muestra Reiniciar ahora, Más tarde y Deshacer' {
        $w = New-TestWindow
        Start-FakeApply -Window $w
        Receive-AfApplyEvent -Window $w -Item ([pscustomobject]@{ Type = 'ChangeDone'; Id = 'gpu.hags'; Change = (New-Change -Id 'gpu.hags' -Reboot $true) })
        Receive-AfApplyEvent -Window $w -Item ([pscustomobject]@{ Type = 'ApplyDone'; SessionPath = 'C:\x.json' })
        $w.Tag.Phase | Should -Be 'done'
        $w.FindName('PrimaryLead').Text | Should -Be 'Reiniciar ahora'
        $w.FindName('GhostText').Text | Should -Be 'Más tarde'
        $w.FindName('ExtraText').Text | Should -Be 'Deshacer'
        (($w.FindName('Summary').Inlines | ForEach-Object { $_.Text }) -join '') | Should -Match '^1 cambio aplicado\. Reinicia para terminar 1\.'
        Invoke-AfGhostAction -Window $w
        $w.FindName('PrimaryLead').Text | Should -Be 'Volver a analizar'
        $w.FindName('GhostButton').Visibility | Should -Be 'Collapsed'
        $w.Close()
    }

    It 'ConfirmDisplay pregunta y Mantener contesta keep' {
        $w = New-TestWindow
        Start-FakeApply -Window $w
        $w.Tag.Shared = [hashtable]::Synchronized(@{ DisplayAnswer = $null })
        Receive-AfApplyEvent -Window $w -Item ([pscustomobject]@{ Type = 'ConfirmDisplay'; Id = 'display.refresh'; Records = @() })
        $w.Tag.Phase | Should -Be 'display'
        $w.FindName('PrimaryLead').Text | Should -Be 'Mantener'
        $w.FindName('GhostText').Text | Should -Be 'Volver al anterior'
        Invoke-AfPrimaryAction -Window $w
        $w.Tag.Shared.DisplayAnswer | Should -Be 'keep'
        $w.Tag.Phase | Should -Be 'applying'
        $w.Close()
    }

    It 'Closing se cancela en las fases de aplicar y deshacer' {
        foreach ($phase in 'applying', 'display', 'restore', 'undoing') { Test-AfBusyPhase -Phase $phase | Should -BeTrue -Because $phase }
        foreach ($phase in 'ready', 'confirm', 'done', 'history', 'scanning') { Test-AfBusyPhase -Phase $phase | Should -BeFalse -Because $phase }
    }

    It 'un error del trabajo antes de aplicar vuelve a listo y lo dice en la nota' {
        $w = New-TestWindow
        Start-FakeApply -Window $w
        Receive-AfApplyEvent -Window $w -Item ([pscustomobject]@{ Type = 'Error'; Message = 'no se pudo guardar el respaldo en ProgramData\Afina\respaldos' })
        $w.Tag.Phase | Should -Be 'ready'
        $w.FindName('NoteText').Text | Should -Be 'No se pudo aplicar: no se pudo guardar el respaldo en ProgramData\Afina\respaldos. Lo que no aparece como hecho no se cambió.'
        $w.Close()
    }
}

Describe 'Trabajo de aplicar' {
    BeforeEach {
        $script:key = 'HKCU:\Software\AfinaTest\' + [guid]::NewGuid().ToString('N')
        New-Item -Path $script:key -Force | Out-Null
    }
    AfterEach { Remove-Item -LiteralPath $script:key -Recurse -Force -ErrorAction SilentlyContinue }
    AfterAll {
        $root = 'HKCU:\Software\AfinaTest'
        if ((Test-Path $root) -and -not @(Get-ChildItem $root).Count) { Remove-Item $root -Force }
    }

    It 'Invoke-AfApplyPlan aplica con la red al final y guarda la sesión' {
        $make = {
            param([string]$Id, [string]$Category, [string]$Name)
            @{ Id = $Id; Category = $Category; Title = $Id; Why = 'x'; Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false; Source = 's'; Undo = 'u'
                Detect = { param($inv) New-AfDetection -State Improvable }
                Apply = [scriptblock]::Create("param(`$inv, `$detected, `$tx) Set-AfRegistryValue -Tx `$tx -Path '$script:key' -Name '$Name' -Type DWord -Value 1 | Out-Null") }
        }
        $catalog = @((& $make 'test.red' 'network' 'Red'), (& $make 'test.juego' 'gaming' 'Juego'))
        $queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
        $plan = [pscustomobject]@{
            Mode = 'Apply'; RestoreAction = 'none'; BackupDirectory = (Join-Path $TestDrive 'respaldos'); Version = '0.2.0'
            Inventory = (New-AfFakeInventory -Override @{ User = (Get-AfUserForSid) })
            Items = @([pscustomobject]@{ Id = 'test.red'; Detection = (New-AfDetection -State Improvable) }, [pscustomobject]@{ Id = 'test.juego'; Detection = (New-AfDetection -State Improvable) })
        }
        Invoke-AfApplyPlan -Plan $plan -Queue $queue -Shared ([hashtable]::Synchronized(@{})) -Catalog $catalog
        $events = @($queue.ToArray())
        @($events | Where-Object Type -eq 'ChangeStart' | ForEach-Object Id) | Should -Be @('test.juego', 'test.red')
        $done = @($events | Where-Object Type -eq 'ApplyDone')[0]
        (Import-AfSession -Path $done.SessionPath).Changes.Count | Should -Be 2
        (Get-AfRegistryState -Path $script:key -Name 'Red').Value | Should -Be 1
    }

    It 'el worker no aplica si New-AfSession falla' {
        $code = $Global:AfCode + "`r`nfunction New-AfSession { throw (New-AfApplyError -Reason 'no se pudo guardar el respaldo en ProgramData\Afina\respaldos') }"
        $queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
        $plan = [pscustomobject]@{
            Mode = 'Apply'; RestoreAction = 'none'; BackupDirectory = (Join-Path $TestDrive 'x'); Version = '0.2.0'; LogPath = $null
            Inventory = (New-AfFakeInventory)
            Items = @([pscustomobject]@{ Id = 'gaming.game-mode'; Detection = (New-AfDetection -State Improvable) })
        }
        $worker = Start-AfApplyWorker -Code $code -Queue $queue -Shared ([hashtable]::Synchronized(@{})) -Plan $plan
        $events = New-Object System.Collections.ArrayList
        $deadline = (Get-Date).AddSeconds(90)
        $item = $null
        while ((Get-Date) -lt $deadline -and -not @($events | Where-Object { $_.Type -in 'Error', 'ApplyDone' }).Count) {
            while ($queue.TryDequeue([ref]$item)) { [void]$events.Add($item) }
            Start-Sleep -Milliseconds 200
        }
        $worker.PowerShell.Dispose()
        $worker.Runspace.Dispose()
        @($events | Where-Object Type -eq 'ChangeStart').Count | Should -Be 0
        $failure = @($events | Where-Object Type -eq 'Error')[0]
        $failure | Should -Not -BeNullOrEmpty
        $failure.Message | Should -Be 'no se pudo guardar el respaldo en ProgramData\Afina\respaldos'
    }
}
