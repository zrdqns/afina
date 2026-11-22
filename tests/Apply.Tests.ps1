BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    $script:me = Get-AfUserForSid
    function New-TestCheck([scriptblock]$Apply, [string]$Id = 'test.change', [string]$Category = 'gaming') {
        @{
            Id = $Id; Category = $Category; Title = 'Cambio de prueba'; Why = 'Porque sí.'; Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'
            Preselect = $true; NeedsReboot = $false; Source = 'Prueba'; Undo = 'Se puede deshacer'
            Detect = { param($inv) New-AfDetection -State Improvable }; Apply = $Apply
        }
    }
    # Corre el plan de aplicar con una revisión y devuelve sus eventos ChangeStep.
    function Get-TestSteps($Check) {
        $queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
        $plan = [pscustomobject]@{
            Inventory = $script:inv; RestoreAction = 'off'; BackupDirectory = (Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))); Version = 'prueba'
            Items = @([pscustomobject]@{ Id = $Check.Id; Detection = $script:detected })
        }
        Invoke-AfApplyPlan -Plan $plan -Queue $queue -Shared ([hashtable]::Synchronized(@{})) -Catalog @($Check)
        @($queue.ToArray() | Where-Object { $_.Type -eq 'ChangeStep' })
    }
}

AfterAll {
    $root = 'HKCU:\Software\AfinaTest'
    if ((Test-Path $root) -and -not @(Get-ChildItem $root).Count) { Remove-Item $root -Force }
}

Describe 'Invoke-AfChange y Undo-AfChange' {
    BeforeEach {
        $script:key = 'HKCU:\Software\AfinaTest\' + [guid]::NewGuid().ToString('N')
        New-Item -Path $script:key -Force | Out-Null
        New-ItemProperty -LiteralPath $script:key -Name 'Uno' -PropertyType DWord -Value 1 | Out-Null
        $script:session = New-AfSession -Directory (Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))) -User $script:me
        $script:inv = New-AfFakeInventory -Override @{ User = $script:me }
        $script:detected = New-AfDetection -State Improvable
    }
    AfterEach { Remove-Item -LiteralPath $script:key -Recurse -Force -ErrorAction SilentlyContinue }

    It 'aplica, guarda Applied y los registros' {
        $check = New-TestCheck { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path $script:key -Name 'Uno' -Type DWord -Value 2 | Out-Null }
        $change = Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv
        $change.Status | Should -Be 'Applied'
        @($change.Records).Count | Should -Be 1
        $change.AppliedAt | Should -Not -BeNullOrEmpty
        (Get-AfRegistryState -Path $script:key -Name 'Uno').Value | Should -Be 2
    }

    It 'revierte lo aplicado de esa revisión si una pieza falla' {
        $check = New-TestCheck {
            param($inv, $detected, $tx)
            Set-AfRegistryValue -Tx $tx -Path $script:key -Name 'Uno' -Type DWord -Value 2 | Out-Null
            throw (New-AfApplyError -Reason 'el adaptador no respondió')
        }
        $change = Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv
        $change.Status | Should -Be 'Failed'
        $change.Message | Should -Be 'No se pudo aplicar: el adaptador no respondió. No se cambió nada.'
        @($change.Records).Count | Should -Be 0
        (Get-AfRegistryState -Path $script:key -Name 'Uno').Value | Should -Be 1
    }

    It 'si no se puede revertir todo, lo dice y deja lo que quedó para deshacer' {
        Mock Restore-AfRegistryValue { throw (New-AfApplyError -Reason 'la clave está bloqueada') }
        $check = New-TestCheck {
            param($inv, $detected, $tx)
            Set-AfRegistryValue -Tx $tx -Path $script:key -Name 'Uno' -Type DWord -Value 2 | Out-Null
            throw (New-AfApplyError -Reason 'el adaptador no respondió')
        }
        $change = Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv
        $change.Status | Should -Be 'Failed'
        $change.Message | Should -Be 'No se pudo aplicar: el adaptador no respondió. Una parte quedó aplicada y se puede deshacer desde Historial.'
        Test-AfChangeUndoable -Change $change | Should -BeTrue
    }

    It 'un error crudo da el motivo genérico y queda en el registro de actividad' {
        $check = New-TestCheck { param($inv, $detected, $tx) throw 'acceso denegado a HKLM\SYSTEM' }
        $change = Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv
        $change.Message | Should -Be 'No se pudo aplicar: Windows no aceptó el cambio. No se cambió nada.'
        (Get-AfLogLines) -join "`n" | Should -Match 'acceso denegado a HKLM'
    }

    It 'una vuelta atrás queda Reverted con su texto' {
        $check = New-TestCheck { param($inv, $detected, $tx) throw (New-AfApplyError -Reason 'Se volvió a 60 Hz' -Reverted) }
        $change = Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv
        $change.Status | Should -Be 'Reverted'
        $change.Message | Should -Be 'Se volvió a 60 Hz.'
    }

    It 'la sesión en disco tiene un cambio por cada Invoke-AfChange' {
        $one = New-TestCheck { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path $script:key -Name 'Uno' -Type DWord -Value 2 | Out-Null }
        $two = New-TestCheck -Id 'test.two' -Apply { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path $script:key -Name 'Dos' -Type DWord -Value 1 | Out-Null }
        Invoke-AfChange -Session $script:session -Check $one -Detection $script:detected -Inventory $script:inv | Out-Null
        (Import-AfSession -Path $script:session.Path).Changes.Count | Should -Be 1
        Invoke-AfChange -Session $script:session -Check $two -Detection $script:detected -Inventory $script:inv | Out-Null
        (Import-AfSession -Path $script:session.Path).Changes.Count | Should -Be 2
    }

    It 'Undo-AfChange deja el valor original y Status Undone' {
        $check = New-TestCheck { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path $script:key -Name 'Uno' -Type DWord -Value 2 | Out-Null }
        $change = Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv
        Undo-AfChange -Session $script:session -Change $change | Out-Null
        $change.Status | Should -Be 'Undone'
        (Get-AfRegistryState -Path $script:key -Name 'Uno').Value | Should -Be 1
        (Import-AfSession -Path $script:session.Path).Changes[0].Status | Should -Be 'Undone'
        Test-AfChangeUndoable -Change $change | Should -BeFalse
    }

    It 'deshace desde una sesión leída del disco (otro día)' {
        $check = New-TestCheck { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path $script:key -Name 'Uno' -Type DWord -Value 2 | Out-Null }
        Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv | Out-Null
        $back = Import-AfSession -Path $script:session.Path
        Undo-AfChange -Session $back -Change $back.Changes[0] | Out-Null
        (Get-AfRegistryState -Path $script:key -Name 'Uno').Value | Should -Be 1
        (Import-AfSession -Path $script:session.Path).Changes[0].Status | Should -Be 'Undone'
    }

    It 'un registro Action no se deshace y el cambio no es deshacible' {
        $check = New-TestCheck {
            param($inv, $detected, $tx)
            Add-AfTxRecord -Tx $tx -Record @{ Kind = 'Action'; Name = 'Temporales'; Detail = 'Se liberaron 1,0 GB' }
            [void]$tx.Notes.Add('Se liberaron 1,0 GB.')
        }
        $change = Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv
        $change.Note | Should -Be 'Se liberaron 1,0 GB.'
        Test-AfChangeUndoable -Change $change | Should -BeFalse
    }

    It 'una revisión sin Apply no se aplica' {
        $change = Invoke-AfChange -Session $script:session -Check (New-TestCheck $null) -Detection $script:detected -Inventory $script:inv
        $change.Status | Should -Be 'Failed'
    }

    It 'en inglés, un cambio que falla lo dice en inglés' {
        Set-AfLanguage -Language en
        try {
            $check = New-TestCheck { param($inv, $detected, $tx) throw (New-AfApplyError -Reason ((T 'el adaptador {0} no respondió') -f 'Ethernet')) }
            $change = Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv
            $change.Message | Should -Be "Couldn't apply: the Ethernet adapter didn't respond. Nothing was changed."
            ConvertTo-AfUpdateReason -HResult 0x80070422 | Should -Be 'the Windows Update service is turned off'
            (Get-AfWingetOutcome -ExitCode -1978334975).Reason | Should -Be 'the app is open'
        } finally { Set-AfLanguage -Language es }
    }

    It 'Set-AfTxProgress llama al avance y no falla sin él' {
        $seen = New-Object System.Collections.ArrayList
        $tx = New-AfTransaction -User $script:me -Progress { param($text) [void]$seen.Add($text) }.GetNewClosure()
        Set-AfTxProgress -Tx $tx -Text 'Descargando 1 de 2'
        @($seen) | Should -Be @('Descargando 1 de 2')
        { Set-AfTxProgress -Tx (New-AfTransaction -User $script:me) -Text 'x' } | Should -Not -Throw
        { Set-AfTxProgress -Tx (New-AfTransaction -User $script:me -Progress { throw 'roto' }) -Text 'x' } | Should -Not -Throw
    }

    It 'el cambio usa NeedsReboot de la transacción si la pieza lo fija' {
        $check = New-TestCheck { param($inv, $detected, $tx) $tx.NeedsReboot = $false }
        $check.NeedsReboot = $true
        (Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv).NeedsReboot | Should -BeFalse
        $plain = New-TestCheck { param($inv, $detected, $tx) }
        $plain.NeedsReboot = $true
        (Invoke-AfChange -Session $script:session -Check $plain -Detection $script:detected -Inventory $script:inv).NeedsReboot | Should -BeTrue
    }

    It 'Invoke-AfApplyPlan encola ChangeProgress con el Id del cambio en curso' {
        $check = New-TestCheck { param($inv, $detected, $tx) Set-AfTxProgress -Tx $tx -Text 'Paso 1' }
        $queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
        $plan = [pscustomobject]@{
            Inventory = $script:inv; RestoreAction = 'off'; BackupDirectory = (Join-Path $TestDrive 'plan'); Version = 'prueba'
            Items = @([pscustomobject]@{ Id = 'test.change'; Detection = $script:detected })
        }
        Invoke-AfApplyPlan -Plan $plan -Queue $queue -Shared ([hashtable]::Synchronized(@{})) -Catalog @($check)
        $progress = @($queue.ToArray() | Where-Object { $_.Type -eq 'ChangeProgress' })
        $progress.Count | Should -Be 1
        $progress[0].Id | Should -Be 'test.change'
        $progress[0].Text | Should -Be 'Paso 1'
    }

    # Pasos reales para la ventana (diseño "Afina en vivo"): salen de la transacción, no de un reloj.
    It 'ChangeStep sale en orden: save, apply, backup' {
        $check = New-TestCheck { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path $script:key -Name 'Uno' -Type DWord -Value 2 | Out-Null }
        $steps = @(Get-TestSteps -Check $check)
        @($steps.Step) | Should -Be @('save', 'apply', 'backup')
        @($steps.Id | Select-Object -Unique) | Should -Be @('test.change')
    }

    It 'una revisión NoUndo empieza en apply' {
        $check = New-TestCheck { param($inv, $detected, $tx) }
        $check.NoUndo = $true
        @((Get-TestSteps -Check $check).Step) | Should -Be @('apply', 'backup')
    }

    It 'si el cambio falla no hay más pasos' {
        $check = New-TestCheck { param($inv, $detected, $tx) throw (New-AfApplyError -Reason 'no') }
        @((Get-TestSteps -Check $check).Step) | Should -Be @('save')
    }

    It 'deshacer envía restore y backup' {
        $check = New-TestCheck { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path $script:key -Name 'Uno' -Type DWord -Value 2 | Out-Null }
        [void](Invoke-AfChange -Session $script:session -Check $check -Detection $script:detected -Inventory $script:inv)
        $queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
        Invoke-AfUndoPlan -Plan ([pscustomobject]@{ Mode = 'Undo'; SessionPath = $script:session.Path; ChangeIds = @() }) -Queue $queue
        $steps = @($queue.ToArray() | Where-Object { $_.Type -eq 'ChangeStep' })
        @($steps.Step) | Should -Be @('restore', 'backup')
        $steps[0].Id | Should -Be 'test.change'
    }
}

Describe 'Orden y preselección' {
    It 'Get-AfApplyOrder deja display.refresh primero y red al final' {
        $items = @(
            [pscustomobject]@{ Check = @{ Id = 'network.ethernet-power'; Category = 'network' } }
            [pscustomobject]@{ Check = @{ Id = 'gpu.hags'; Category = 'gaming' } }
            [pscustomobject]@{ Check = @{ Id = 'display.refresh'; Category = 'gaming' } }
            [pscustomobject]@{ Check = @{ Id = 'network.wifi-power'; Category = 'network' } }
            [pscustomobject]@{ Check = @{ Id = 'storage.trim'; Category = 'storage' } }
        )
        @(Get-AfApplyOrder -Items $items | ForEach-Object { $_.Check.Id }) | Should -Be @('display.refresh', 'gpu.hags', 'storage.trim', 'network.ethernet-power', 'network.wifi-power')
    }

    It 'las actualizaciones van después del resto y antes de la red' {
        $items = @(
            [pscustomobject]@{ Check = @{ Id = 'network.ethernet-power'; Category = 'network' } }
            [pscustomobject]@{ Check = @{ Id = 'updates.windows'; Category = 'optional' } }
            [pscustomobject]@{ Check = @{ Id = 'cleanup.ads'; Category = 'optional' } }
            [pscustomobject]@{ Check = @{ Id = 'updates.apps'; Category = 'optional' } }
            [pscustomobject]@{ Check = @{ Id = 'gpu.hags'; Category = 'gaming' } }
        )
        @(Get-AfApplyOrder -Items $items | ForEach-Object { $_.Check.Id }) | Should -Be @('cleanup.ads', 'gpu.hags', 'updates.windows', 'updates.apps', 'network.ethernet-power')
    }

    It 'Invoke-AfCheck no preselecciona una revisión Auto sin Apply' {
        (Invoke-AfCheck -Check (New-TestCheck $null) -Inventory (New-AfFakeInventory)).Preselected | Should -BeFalse
        (Invoke-AfCheck -Check (New-TestCheck { param($inv, $detected, $tx) }) -Inventory (New-AfFakeInventory)).Preselected | Should -BeTrue
    }

    It 'Test-AfCheckDefinition rechaza un Apply que no es scriptblock' {
        $check = New-TestCheck { }
        $check.Apply = 'texto'
        @(Test-AfCheckDefinition -Check $check) | Should -Contain 'Apply debe ser un scriptblock'
    }
}
