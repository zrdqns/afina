BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    $script:adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $script:clsidA = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
    $script:clsidB = 'HKCU:\Software\Classes\CLSID\{51668040-5e31-4023-bbe3-149163bd80f1}\InprocServer32'
    function Get-Check([string]$Id) { @(Get-AfCatalog) | Where-Object { $_.Id -eq $Id } }
    function New-Os([int]$Build = 26300, [string]$Edition = 'Professional', [int]$Ubr = 1000) {
        [pscustomobject]@{ Caption = 'Microsoft Windows'; Build = $Build; Edition = $Edition; IsWin11 = ($Build -ge 22000); IsInsider = $false; Ubr = $Ubr }
    }
    function Invoke-Detect([string]$Id, [hashtable]$Override) {
        (Invoke-AfCheck -Check (Get-Check $Id) -Inventory (New-AfFakeInventory -Override $Override)).Detection
    }
    # Quien llama sustituye antes Set-AfRegistryValue y Send-AfShellNotify: nunca se toca el registro ni el shell reales.
    function Invoke-ApplyMocked([string]$Id, $Inventory) {
        $check = Get-Check $Id
        $result = Invoke-AfCheck -Check $check -Inventory $Inventory
        $tx = New-AfTransaction -User $Inventory.User
        & $check.Apply $Inventory $result.Detection $tx
        $tx
    }
    function New-State([bool]$Exists) { [pscustomobject]@{ KeyExists = $Exists; Exists = $Exists; Type = $(if ($Exists) { 'String' }); Value = $(if ($Exists) { '' }) } }
}

Describe 'Ajustes de Windows: contrato' {
    It 'las seis vienen sin marcar, seguras y en la categoría windows' {
        foreach ($id in 'windows.file-extensions', 'windows.end-task', 'windows.battery-percent', 'windows.classic-menu', 'windows.search-web', 'windows.start-recommendations') {
            $c = Get-Check $id
            $c.Category | Should -Be 'windows'
            $c.Preselect | Should -BeFalse
            $c.Risk | Should -Be 'Safe'
            $c.NeedsReboot | Should -Be ($id -ne 'windows.file-extensions')
        }
    }
}

Describe 'windows.file-extensions' {
    It 'ocultas es mejorable sin marcar y visibles es Ok' {
        $r = Invoke-AfCheck -Check (Get-Check 'windows.file-extensions') -Inventory (New-AfFakeInventory -Override @{ Registry = @{ "$script:adv|HideFileExt" = 1 } })
        $r.Detection.State | Should -Be 'Improvable'
        $r.Preselected | Should -BeFalse
        (Invoke-Detect 'windows.file-extensions' @{ Registry = @{ "$script:adv|HideFileExt" = 0 } }).State | Should -Be 'Ok'
    }
    It 'Apply escribe HideFileExt 0 y avisa al shell' {
        Mock Set-AfRegistryValue { $true }
        Mock Send-AfShellNotify { }
        Invoke-ApplyMocked 'windows.file-extensions' (New-AfFakeInventory -Override @{ Registry = @{ "$script:adv|HideFileExt" = 1 } }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:adv -and $Name -eq 'HideFileExt' -and $Type -eq 'DWord' -and $Value -eq 0 }
        Should -Invoke Send-AfShellNotify -Times 1 -Exactly -ParameterFilter { $Area -eq 'ShellState' }
    }
}

Describe 'windows.end-task' {
    It 'no aplica en Windows 10 ni en 22621' {
        (Invoke-Detect 'windows.end-task' @{ Os = (New-Os -Build 19045) }).State | Should -Be 'NotApplicable'
        (Invoke-Detect 'windows.end-task' @{ Os = (New-Os -Build 22621) }).State | Should -Be 'NotApplicable'
    }
    It 'en 22631 es mejorable y con el valor en 1 está Ok' {
        (Invoke-Detect 'windows.end-task' @{ Os = (New-Os -Build 22631) }).State | Should -Be 'Improvable'
        (Invoke-Detect 'windows.end-task' @{ Os = (New-Os -Build 22631); Registry = @{ "$script:adv\TaskbarDeveloperSettings|TaskbarEndTask" = 1 } }).State | Should -Be 'Ok'
    }
    It 'Apply escribe TaskbarEndTask 1' {
        Mock Set-AfRegistryValue { $true }
        Invoke-ApplyMocked 'windows.end-task' (New-AfFakeInventory -Override @{ Os = (New-Os -Build 26300) }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq "$script:adv\TaskbarDeveloperSettings" -and $Name -eq 'TaskbarEndTask' -and $Value -eq 1 }
    }
}

Describe 'windows.battery-percent' {
    It 'no aplica en escritorio' {
        (Invoke-Detect 'windows.battery-percent' @{ Os = (New-Os -Build 26300); Device = [pscustomobject]@{ IsLaptop = $false; IsDesktop = $true } }).State | Should -Be 'NotApplicable'
    }
    It '26100.7018 no aplica y 26100.7019 es mejorable' {
        (Invoke-Detect 'windows.battery-percent' @{ Os = (New-Os -Build 26100 -Ubr 7018) }).State | Should -Be 'NotApplicable'
        (Invoke-Detect 'windows.battery-percent' @{ Os = (New-Os -Build 26100 -Ubr 7019) }).State | Should -Be 'Improvable'
    }
    It 'Apply escribe IsBatteryPercentageEnabled 1' {
        Mock Set-AfRegistryValue { $true }
        Invoke-ApplyMocked 'windows.battery-percent' (New-AfFakeInventory -Override @{ Os = (New-Os -Build 26300) }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:adv -and $Name -eq 'IsBatteryPercentageEnabled' -and $Value -eq 1 }
    }
}

Describe 'windows.classic-menu' {
    It 'no aplica en Windows 10' {
        (Invoke-Detect 'windows.classic-menu' @{ Os = (New-Os -Build 19045) }).State | Should -Be 'NotApplicable'
    }
    It 'sin las claves es mejorable y avisa que una actualización puede romperlo' {
        Mock Get-AfRegistryState { New-State $false }
        $d = Invoke-Detect 'windows.classic-menu' @{ Os = (New-Os -Build 26300) }
        $d.State | Should -Be 'Improvable'
        $d.Note | Should -Be 'Una actualización de Windows puede volver a romperlo'
    }
    It 'con una sola clave sigue mejorable' {
        Mock Get-AfRegistryState { New-State ($Path -eq $script:clsidA) }
        (Invoke-Detect 'windows.classic-menu' @{ Os = (New-Os -Build 26300) }).State | Should -Be 'Improvable'
    }
    It 'con las dos claves está Ok' {
        Mock Get-AfRegistryState { New-State $true }
        (Invoke-Detect 'windows.classic-menu' @{ Os = (New-Os -Build 26300) }).State | Should -Be 'Ok'
    }
    It 'Apply escribe el valor por defecto vacío en las dos claves' {
        Mock Set-AfRegistryValue { $true }
        Mock Get-AfRegistryState { New-State $false }
        Invoke-ApplyMocked 'windows.classic-menu' (New-AfFakeInventory -Override @{ Os = (New-Os -Build 26300) }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:clsidA -and $Name -eq '' -and $Type -eq 'String' -and $Value -eq '' }
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:clsidB -and $Name -eq '' -and $Type -eq 'String' -and $Value -eq '' }
    }
}

Describe 'windows.search-web' {
    BeforeAll {
        $script:pol = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
        $script:polLm = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
    }
    It 'en Home es Info con pasos que aclaran que no lo quita del todo' {
        $d = Invoke-Detect 'windows.search-web' @{ Os = (New-Os -Build 26300 -Edition 'Core') }
        $d.State | Should -Be 'Info'
        (@($d.Steps) -join ' ') | Should -Match 'no quita'
    }
    It 'en Home los pasos van a la ruta de su versión de Windows' {
        (Invoke-Detect 'windows.search-web' @{ Os = (New-Os -Build 26300 -Edition 'Core') }).Steps[0] | Should -Be 'Abre Configuración > Privacidad y seguridad > Permisos de búsqueda.'
        (Invoke-Detect 'windows.search-web' @{ Os = (New-Os -Build 19045 -Edition 'Core') }).Steps[0] | Should -Be 'Abre Configuración > Búsqueda > Permisos e historial.'
    }
    It 'en Home una directiva olvidada no cuenta como hecha' {
        $d = Invoke-Detect 'windows.search-web' @{ Os = (New-Os -Build 26300 -Edition 'Core'); Registry = @{ "$script:pol|DisableSearchBoxSuggestions" = 1 } }
        $d.State | Should -Be 'Info'
    }
    It 'en Pro lee la directiva de HKCU y Apply solo la escribe a ella' {
        (Invoke-Detect 'windows.search-web' @{ Os = (New-Os -Build 26300 -Edition 'Professional') }).State | Should -Be 'Improvable'
        (Invoke-Detect 'windows.search-web' @{ Os = (New-Os -Build 26300 -Edition 'Professional'); Registry = @{ "$script:pol|DisableSearchBoxSuggestions" = 1 } }).State | Should -Be 'Ok'
        Mock Set-AfRegistryValue { $true }
        Invoke-ApplyMocked 'windows.search-web' (New-AfFakeInventory -Override @{ Os = (New-Os -Build 26300 -Edition 'Professional') }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:pol -and $Name -eq 'DisableSearchBoxSuggestions' -and $Type -eq 'DWord' -and $Value -eq 1 }
    }
    It 'en Pro la nota visible dice que el efecto en Inicio viene de la comunidad, antes y después de aplicar' {
        $os = New-Os -Build 26300 -Edition 'Professional'
        (Invoke-Detect 'windows.search-web' @{ Os = $os }).Note | Should -Match 'comunidad'
        (Invoke-Detect 'windows.search-web' @{ Os = $os; Registry = @{ "$script:pol|DisableSearchBoxSuggestions" = 1 } }).Note | Should -Match 'comunidad'
    }
    It 'en Enterprise lee ConnectedSearchUseWeb y Apply solo la escribe a ella' {
        $os = New-Os -Build 26300 -Edition 'Enterprise'
        (Invoke-Detect 'windows.search-web' @{ Os = $os; Registry = @{ "$script:polLm|ConnectedSearchUseWeb" = 0 } }).State | Should -Be 'Ok'
        (Invoke-Detect 'windows.search-web' @{ Os = $os; Registry = @{ "$script:pol|DisableSearchBoxSuggestions" = 1 } }).State | Should -Be 'Improvable'
        Mock Set-AfRegistryValue { $true }
        Invoke-ApplyMocked 'windows.search-web' (New-AfFakeInventory -Override @{ Os = $os }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:polLm -and $Name -eq 'ConnectedSearchUseWeb' -and $Type -eq 'DWord' -and $Value -eq 0 }
    }
}

Describe 'windows.start-recommendations' {
    BeforeAll {
        $script:startNames = 'Start_TrackProgs', 'Start_IrisRecommendations', 'Start_RecoPersonalizedSites', 'Start_AccountNotifications'
        $script:polEx = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    }
    It 'no aplica en Windows 10' {
        (Invoke-Detect 'windows.start-recommendations' @{ Os = (New-Os -Build 19045) }).State | Should -Be 'NotApplicable'
    }
    It 'no lee ni escribe Start_TrackDocs, que también vacía los archivos recientes del Explorador' {
        @((Get-Check 'windows.start-recommendations').Reads) -join ' ' | Should -Not -Match 'Start_TrackDocs'
        Mock Set-AfRegistryValue { $true }
        Invoke-ApplyMocked 'windows.start-recommendations' (New-AfFakeInventory -Override @{ Os = (New-Os -Build 26300 -Edition 'Professional') }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 0 -Exactly -ParameterFilter { $Name -eq 'Start_TrackDocs' }
    }
    It 'en Home la fila avisa que Inicio puede seguir mostrando archivos recientes' {
        $d = Invoke-Detect 'windows.start-recommendations' @{ Os = (New-Os -Build 26300 -Edition 'Core') }
        $d.State | Should -Be 'Improvable'
        $d.Note | Should -Match 'archivos recientes'
        $reg = @{}
        foreach ($n in $script:startNames) { $reg["$script:adv|$n"] = 0 }
        $ok = Invoke-Detect 'windows.start-recommendations' @{ Os = (New-Os -Build 26300 -Edition 'Core'); Registry = $reg }
        $ok.State | Should -Be 'Ok'
        $ok.Note | Should -Match 'archivos recientes'
    }
    It 'en Home Apply escribe los cuatro en 0 y no la directiva' {
        Mock Set-AfRegistryValue { $true }
        Invoke-ApplyMocked 'windows.start-recommendations' (New-AfFakeInventory -Override @{ Os = (New-Os -Build 26300 -Edition 'Core') }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 4 -Exactly
        foreach ($n in $script:startNames) {
            Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:adv -and $Name -eq $n -and $Type -eq 'DWord' -and $Value -eq 0 }
        }
        Should -Invoke Set-AfRegistryValue -Times 0 -Exactly -ParameterFilter { $Name -eq 'HideRecommendedSection' }
    }
    It 'en Pro Apply suma HideRecommendedSection en HKCU' {
        Mock Set-AfRegistryValue { $true }
        Invoke-ApplyMocked 'windows.start-recommendations' (New-AfFakeInventory -Override @{ Os = (New-Os -Build 26300 -Edition 'Professional') }) | Out-Null
        Should -Invoke Set-AfRegistryValue -Times 5 -Exactly
        Should -Invoke Set-AfRegistryValue -Times 1 -Exactly -ParameterFilter { $Path -eq $script:polEx -and $Name -eq 'HideRecommendedSection' -and $Value -eq 1 }
    }
    It 'en Home la directiva olvidada no basta, y en Pro hace falta' {
        $reg = @{}
        foreach ($n in $script:startNames) { $reg["$script:adv|$n"] = 0 }
        $homeReg = $reg.Clone()
        $homeReg.Remove("$script:adv|Start_TrackProgs")
        $homeReg["$script:polEx|HideRecommendedSection"] = 1
        (Invoke-Detect 'windows.start-recommendations' @{ Os = (New-Os -Build 26300 -Edition 'Core'); Registry = $homeReg }).State | Should -Be 'Improvable'
        (Invoke-Detect 'windows.start-recommendations' @{ Os = (New-Os -Build 26300 -Edition 'Core'); Registry = $reg }).State | Should -Be 'Ok'
        (Invoke-Detect 'windows.start-recommendations' @{ Os = (New-Os -Build 26300 -Edition 'Professional'); Registry = $reg }).State | Should -Be 'Improvable'
        $reg["$script:polEx|HideRecommendedSection"] = 1
        (Invoke-Detect 'windows.start-recommendations' @{ Os = (New-Os -Build 26300 -Edition 'Professional'); Registry = $reg }).State | Should -Be 'Ok'
    }
    It 'el texto dice que también se apagan "Más usadas" y el historial de Ejecutar' {
        $what = (Invoke-Detect 'windows.start-recommendations' @{ Os = (New-Os -Build 26300 -Edition 'Core') }).What
        $what | Should -Match '"Más usadas"'
        $what | Should -Match 'Ejecutar \(Win\+R\)'
    }
}

Describe 'Ajustes de Windows: textos de la revisión final' {
    BeforeAll { $script:managed = 'Configuración puede mostrar que una organización administra este ajuste hasta que lo deshagas.' }
    It 'las ramas que escriben una directiva avisan que Configuración puede mostrarla como administrada' {
        foreach ($case in @(
                @('windows.search-web', 'Professional'), @('windows.search-web', 'Enterprise'), @('windows.start-recommendations', 'Professional'))) {
            $d = Invoke-Detect $case[0] @{ Os = (New-Os -Build 26300 -Edition $case[1]) }
            $d.State | Should -Be 'Improvable' -Because ($case -join ' ')
            $d.What | Should -BeLike "*$script:managed" -Because ($case -join ' ')
        }
    }
    It 'las ramas sin directiva no lo dicen' {
        $core = Invoke-Detect 'windows.start-recommendations' @{ Os = (New-Os -Build 26300 -Edition 'Core') }
        $core.State | Should -Be 'Improvable'
        $core.What | Should -Not -BeLike '*organización administra*'
        Mock Get-AfRegistryState { New-State $false }
        foreach ($id in 'windows.file-extensions', 'windows.end-task', 'windows.battery-percent', 'windows.classic-menu') {
            $d = Invoke-Detect $id @{ Os = (New-Os -Build 26300) }
            $d.State | Should -Be 'Improvable' -Because $id
            $d.What | Should -Not -BeLike '*organización administra*' -Because $id
        }
    }
    It 'las filas que piden reiniciar no lo repiten en la nota: ya lo dice la etiqueta' {
        foreach ($case in @(
                @('windows.end-task', 'Professional'), @('windows.battery-percent', 'Professional'), @('windows.search-web', 'Enterprise'), @('windows.start-recommendations', 'Professional'))) {
            (Get-Check $case[0]).NeedsReboot | Should -BeTrue -Because $case[0]
            $d = Invoke-Detect $case[0] @{ Os = (New-Os -Build 26300 -Edition $case[1]) }
            $d.State | Should -Be 'Improvable' -Because $case[0]
            $d.Note | Should -Not -Be 'Pide reiniciar' -Because $case[0]
        }
    }
}

Describe 'Aviso de build sin probar' {
    It 'end-task, battery-percent y classic-menu lo agregan en 26100 y no en 26300' {
        Mock Set-AfRegistryValue { $true }
        Mock Get-AfRegistryState { New-State $false }
        foreach ($id in 'windows.end-task', 'windows.battery-percent', 'windows.classic-menu') {
            $tx = Invoke-ApplyMocked $id (New-AfFakeInventory -Override @{ Os = (New-Os -Build 26100 -Ubr 7019) })
            @($tx.Notes) | Should -Contain 'Escrito, comprueba que se vea el cambio' -Because $id
            $tx = Invoke-ApplyMocked $id (New-AfFakeInventory -Override @{ Os = (New-Os -Build 26300) })
            @($tx.Notes).Count | Should -Be 0 -Because $id
        }
    }
}
