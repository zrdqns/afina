BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:me = Get-AfUserForSid
}

Describe 'Windows Update' {
    It 'Find-AfWindowsUpdates devuelve los títulos y busca solo lo que Windows instalaría solo' {
        $r = Find-AfWindowsUpdates -Script 'param($Sync, $Mode, $Criteria) @{ Titles = @(''KB1'', $Criteria) }'
        $r.Count | Should -Be 2
        $r.Titles[0] | Should -Be 'KB1'
        $r.Titles[1] | Should -BeLike '*BrowseOnly=0*'
        $r.Reason | Should -BeNullOrEmpty
    }

    It 'Find-AfWindowsUpdates traduce 0x80070422' {
        $r = Find-AfWindowsUpdates -Script 'param($Sync, $Mode, $Criteria) throw (New-Object System.Runtime.InteropServices.COMException(''x'', -2147023838))'
        $r.Count | Should -Be 0
        $r.Reason | Should -Be 'el servicio de Windows Update está desactivado'
    }

    It 'Install-AfWindowsUpdates registra lo instalado y pide reinicio si alguna lo pide' {
        $seen = New-Object System.Collections.ArrayList
        $tx = New-AfTransaction -User $script:me -Progress { param($text) [void]$seen.Add($text) }.GetNewClosure()
        $job = @'
param($Sync, $Mode, $Criteria)
$Sync.Results = @()
$Sync.Found = 2
foreach ($t in 'KB1', 'KB2') {
    $Sync.Stage = "Instalando $t"; $Sync.Beat = [datetime]::UtcNow; Start-Sleep -Milliseconds 400
    $Sync.Results = @($Sync.Results) + @(@{ Title = $t; Ok = $true; HResult = 0; RebootRequired = ($t -eq 'KB2') })
}
'@
        Install-AfWindowsUpdates -Tx $tx -Script $job | Out-Null
        @($tx.Records).Count | Should -Be 1
        $tx.Records[0].Kind | Should -Be 'Action'
        $tx.Records[0].Detail | Should -Be 'Se instalaron 2 de 2'
        @($tx.Records[0].Installed) | Should -Be @('KB1', 'KB2')
        $tx.NeedsReboot | Should -BeTrue
        @($seen) | Should -Contain 'Instalando KB1'
    }

    It 'el avance de Windows Update sale en el idioma elegido' {
        Set-AfLanguage -Language en
        try {
            $seen = New-Object System.Collections.ArrayList
            $tx = New-AfTransaction -User $script:me -Progress { param($text) [void]$seen.Add($text) }.GetNewClosure()
            $job = @'
param($Sync, $Mode, $Criteria)
$Sync.Found = 1
$Sync.Stage = $Sync.Texts.Install -f 1, 1; $Sync.Beat = [datetime]::UtcNow; Start-Sleep -Milliseconds 400
$Sync.Results = @(@{ Title = 'KB1'; Ok = $true; HResult = 0; RebootRequired = $false })
'@
            Install-AfWindowsUpdates -Tx $tx -Script $job | Out-Null
            @($seen) | Should -Contain 'Installing 1 of 1'
        } finally { Set-AfLanguage -Language es }
    }

    It 'sin ninguna instalada lanza un error amable' {
        $tx = New-AfTransaction -User $script:me
        $job = 'param($Sync, $Mode, $Criteria) $Sync.Found = 1; $Sync.Results = @(@{ Title = ''KB1''; Ok = $false; HResult = -2145124330; RebootRequired = $false })'
        { Install-AfWindowsUpdates -Tx $tx -Script $job } | Should -Throw -ExpectedMessage 'Windows Update está instalando otra cosa o espera un reinicio'
    }

    It 'sin actualizaciones no deja registro' {
        $tx = New-AfTransaction -User $script:me
        Install-AfWindowsUpdates -Tx $tx -Script 'param($Sync, $Mode, $Criteria) $Sync.Found = 0' | Out-Null
        @($tx.Records).Count | Should -Be 0
        @($tx.Notes) | Should -Contain 'Ya estaba al día.'
        $tx.NeedsReboot | Should -BeFalse
    }

    It 'con un paso trabado deja anotado lo instalado' {
        $tx = New-AfTransaction -User $script:me
        $job = @'
param($Sync, $Mode, $Criteria)
$Sync.Found = 2
$Sync.Results = @(@{ Title = 'KB1'; Ok = $true; HResult = 0; RebootRequired = $false })
$Sync.Stage = 'Instalando 2 de 2'; $Sync.Beat = [datetime]::UtcNow
Start-Sleep -Seconds 30
'@
        Install-AfWindowsUpdates -Tx $tx -Script $job -StallSeconds 1 | Out-Null
        $tx.Records[0].Detail | Should -Be 'Se instalaron 1 de 2'
        (@($tx.Notes) -join ' ') | Should -BeLike '*dejó de responder*'
    }

    It 'ConvertTo-AfUpdateReason traduce los códigos conocidos y muestra el resto' {
        ConvertTo-AfUpdateReason -HResult 0x80070422 | Should -Be 'el servicio de Windows Update está desactivado'
        ConvertTo-AfUpdateReason -HResult 2147943458 | Should -Be 'el servicio de Windows Update está desactivado'
        foreach ($code in 0x8024402C, 0x80072EE2, 0x80072EE7, 0x80072EFD) { ConvertTo-AfUpdateReason -HResult $code | Should -Be 'no hay conexión con Windows Update' }
        ConvertTo-AfUpdateReason -HResult 0x80072F8F | Should -Be 'no se pudo abrir una conexión segura con Windows Update'
        ConvertTo-AfUpdateReason -HResult 0x80240016 | Should -Be 'Windows Update está instalando otra cosa o espera un reinicio'
        ConvertTo-AfUpdateReason -HResult 0x8024001E | Should -Be 'Windows Update se detuvo'
        ConvertTo-AfUpdateReason -HResult 0x80240FFF | Should -Be 'Windows Update devolvió el código 0x80240FFF'
    }

    It 'el trabajo real se puede analizar' {
        $script:AfWindowsUpdateJob | Should -Not -BeNullOrEmpty
        { [scriptblock]::Create($script:AfWindowsUpdateJob) } | Should -Not -Throw
    }

    It 'Find-AfWindowsUpdates busca de verdad sin instalar (solo lectura)' -Tag 'Integration' {
        $r = Find-AfWindowsUpdates
        $r.TimedOut | Should -BeFalse
        $r.Reason | Should -BeNullOrEmpty
    }
}

Describe 'winget' {
    BeforeEach {
        Mock Get-AfWingetPath { 'C:\winget\winget.exe' }
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 0; Output = ''; Error = ''; TimedOut = $false } }
        $script:tx = New-AfTransaction -User $script:me
        $script:apps = @(
            [pscustomobject]@{ Name = 'Firefox'; Id = 'Mozilla.Firefox'; Version = '1'; Available = '2'; Source = 'winget' }
            [pscustomobject]@{ Name = 'Discord'; Id = 'Discord.Discord'; Version = '1'; Available = '2'; Source = '' }
        )
    }

    It 'actualiza cada app con su Id exacto y su origen' {
        Update-AfWingetApps -Tx $script:tx -Apps $script:apps | Out-Null
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -like 'upgrade --id "Mozilla.Firefox" --exact --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' }
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -like 'upgrade --id "Discord.Discord" --exact --silent *' }
        $script:tx.Records[0].Kind | Should -Be 'Action'
        $script:tx.Records[0].Detail | Should -Be 'Se actualizaron 2 de 2'
    }

    It 'actualiza App Installer al final (es el propio winget)' {
        $script:order = New-Object System.Collections.ArrayList
        Mock Invoke-AfProcess { [void]$script:order.Add($Arguments); [pscustomobject]@{ ExitCode = 0; Output = ''; Error = ''; TimedOut = $false } }
        $installer = [pscustomobject]@{ Name = 'App Installer'; Id = 'Microsoft.AppInstaller'; Version = '1'; Available = '2'; Source = 'winget' }
        Update-AfWingetApps -Tx $script:tx -Apps @($installer, $script:apps[0]) | Out-Null
        $script:order[0] | Should -BeLike '*Mozilla.Firefox*'
        $script:order[1] | Should -BeLike '*Microsoft.AppInstaller*'
    }

    It 'sigue con las demás si una app está abierta' {
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = -1978334975; Output = ''; Error = ''; TimedOut = $false } } -ParameterFilter { $Arguments -like '*Mozilla.Firefox*' }
        Update-AfWingetApps -Tx $script:tx -Apps $script:apps | Out-Null
        Should -Invoke Invoke-AfProcess -Times 2 -Exactly
        $script:tx.Records[0].Detail | Should -Be 'Se actualizaron 1 de 2'
        (@($script:tx.Notes) -join ' ') | Should -BeLike '*No se pudo con Firefox: la app está abierta.*'
    }

    It 'pide reinicio si winget lo indica' {
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = -1978334967; Output = ''; Error = ''; TimedOut = $false } }
        Update-AfWingetApps -Tx $script:tx -Apps @($script:apps[0]) | Out-Null
        $script:tx.NeedsReboot | Should -BeTrue
    }

    It 'sin ninguna actualizada lanza un error amable' {
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = -1978334969; Output = ''; Error = ''; TimedOut = $false } }
        { Update-AfWingetApps -Tx $script:tx -Apps $script:apps } | Should -Throw -ExpectedMessage 'no hay conexión a internet'
    }

    It 'si winget no termina a tiempo lo dice' {
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = $null; Output = ''; Error = ''; TimedOut = $true } }
        { Update-AfWingetApps -Tx $script:tx -Apps @($script:apps[0]) } | Should -Throw -ExpectedMessage 'winget no terminó en 15 min'
    }

    It 'Get-AfWingetOutcome sigue la tabla oficial' {
        (Get-AfWingetOutcome -ExitCode 0).Ok | Should -BeTrue
        $same = Get-AfWingetOutcome -ExitCode -1978335189
        $same.Ok | Should -BeTrue
        $same.Reason | Should -Be 'ya estaba al día'
        (Get-AfWingetOutcome -ExitCode -1978334965).Reboot | Should -BeTrue
        (Get-AfWingetOutcome -ExitCode -1978334966).Reason | Should -Be 'hay que reiniciar la PC antes'
        (Get-AfWingetOutcome -ExitCode -1978334973).Reason | Should -Be 'la app está abierta'
        (Get-AfWingetOutcome -ExitCode -1978334974).Reason | Should -Be 'hay otra instalación en curso'
        (Get-AfWingetOutcome -ExitCode -1978334971).Reason | Should -Be 'no queda espacio en el disco'
        (Get-AfWingetOutcome -ExitCode -1978334961).Reason | Should -Be 'una directiva de la organización lo impide'
        (Get-AfWingetOutcome -ExitCode -1978335128).Reason | Should -Be 'la app está fijada en su versión'
        (Get-AfWingetOutcome -ExitCode -1978335216).Reason | Should -Be 'winget no tiene un instalador para esta PC'
        (Get-AfWingetOutcome -ExitCode -1978335212).Reason | Should -Be 'winget no tiene un instalador para esta PC'
        (Get-AfWingetOutcome -ExitCode -1978335146).Reason | Should -Be 'no se puede actualizar como administrador; se actualiza desde la propia app'
        (Get-AfWingetOutcome -ExitCode -1978335107).Reason | Should -Be 'no se puede actualizar como administrador; se actualiza desde la propia app'
        (Get-AfWingetOutcome -ExitCode 5).Reason | Should -Be 'winget devolvió el código 0x00000005'
    }
}