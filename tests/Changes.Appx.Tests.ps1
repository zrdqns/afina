BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:me = Get-AfUserForSid
    function New-Package([string]$Name, [string]$Family) {
        [pscustomobject]@{ Name = $Name; PackageFullName = "$($Name)_1.0.0.0_x64__x"; PackageFamilyName = $Family }
    }
}

Describe 'Get-AfPromoApps' {
    It 'no confunde Instagram con Facebook y pone el ID de la Store solo al paquete verificado' {
        Mock Get-AppxPackage { @(
                (New-Package 'Facebook.InstagramBeta' 'Facebook.InstagramBeta_8xx8rvfyw5nnt')
                (New-Package 'king.com.CandyCrushSodaSaga' 'king.com.CandyCrushSodaSaga_kgqvnymyfvs32')
            ) }
        Mock Get-AppxProvisionedPackage { @() }
        $promo = @((Get-AfPromoApps -User $script:me).Promo)
        @($promo | ForEach-Object Name) | Should -Be @('Candy Crush', 'Instagram')
        ($promo | Where-Object Name -eq 'Instagram').StoreId | Should -Be '9NBLGGH5L9XT'
        ($promo | Where-Object Name -eq 'Candy Crush').StoreId | Should -BeNullOrEmpty
        ($promo | Where-Object Name -eq 'Instagram').PackageFamilyName | Should -Be 'Facebook.InstagramBeta_8xx8rvfyw5nnt'
    }

    It 'marca las aprovisionadas cuando alguna no tiene ID de la Store' {
        Mock Get-AppxPackage { New-Package 'king.com.CandyCrushSodaSaga' 'king.com.CandyCrushSodaSaga_kgqvnymyfvs32' }
        Mock Get-AppxProvisionedPackage { [pscustomobject]@{ DisplayName = 'king.com.CandyCrushSodaSaga' } }
        (Get-AfPromoApps -User $script:me).Promo[0].Provisioned | Should -BeTrue
    }

    It 'si todas tienen ID de la Store no pregunta por las aprovisionadas (tarda)' {
        Mock Get-AppxPackage { New-Package 'Microsoft.BingNews' 'Microsoft.BingNews_8wekyb3d8bbwe' }
        Mock Get-AppxProvisionedPackage { @() }
        (Get-AfPromoApps -User $script:me).Promo[0].StoreId | Should -Be '9WZDNCRFHVFW'
        Should -Invoke Get-AppxProvisionedPackage -Times 0 -Exactly
    }

    It 'sin apps promocionales no pregunta por las aprovisionadas (tarda)' {
        Mock Get-AppxPackage { New-Package 'Microsoft.WindowsCalculator' 'Microsoft.WindowsCalculator_8wekyb3d8bbwe' }
        Mock Get-AppxProvisionedPackage { @() }
        @((Get-AfPromoApps -User $script:me).Promo).Count | Should -Be 0
        Should -Invoke Get-AppxProvisionedPackage -Times 0 -Exactly
    }
}

Describe 'Pieza AppxPackage' {
    It 'quita la app y deshacer la registra de nuevo si sigue en la PC' {
        Mock Get-AppxPackage { New-Package 'Microsoft.BingNews' 'Microsoft.BingNews_8wekyb3d8bbwe' } -ParameterFilter { -not $AllUsers }
        Mock Remove-AppxPackage { }
        $tx = New-AfTransaction -User $script:me
        Remove-AfAppxPackage -Tx $tx -App ([pscustomobject]@{ Name = 'Noticias'; PackageName = 'Microsoft.BingNews'; StoreId = '9WZDNCRFHVFW' }) | Should -BeTrue
        Should -Invoke Remove-AppxPackage -Times 1 -Exactly -ParameterFilter { $Package -eq 'Microsoft.BingNews_1.0.0.0_x64__x' }
        $record = $tx.Records[0]
        $record.Kind | Should -Be 'AppxPackage'
        $record.PackageFamilyName | Should -Be 'Microsoft.BingNews_8wekyb3d8bbwe'
        $record.Previous | Should -Be 'Installed'

        Mock Get-AppxPackage { @() } -ParameterFilter { -not $AllUsers }
        Mock Get-AppxPackage { New-Package 'Microsoft.BingNews' 'Microsoft.BingNews_8wekyb3d8bbwe' } -ParameterFilter { $AllUsers }
        Mock Add-AppxPackage { }
        Get-AfRecordState -Record $record -User $script:me | Should -Be 'Removed'
        Undo-AfRecord -Record $record -User $script:me
        Should -Invoke Add-AppxPackage -Times 1 -Exactly -ParameterFilter { $RegisterByFamilyName -and $MainPackage -eq 'Microsoft.BingNews_8wekyb3d8bbwe' }
    }

    It 'no deja registro si la app ya no está' {
        Mock Get-AppxPackage { @() }
        Mock Remove-AppxPackage { }
        $tx = New-AfTransaction -User $script:me
        Remove-AfAppxPackage -Tx $tx -App ([pscustomobject]@{ Name = 'Noticias'; PackageName = 'Microsoft.BingNews' }) | Should -BeFalse
        @($tx.Records).Count | Should -Be 0
        Should -Invoke Remove-AppxPackage -Times 0 -Exactly
    }

    It 'si Windows no deja quitarla lo dice' {
        Mock Get-AppxPackage { New-Package 'Microsoft.BingNews' 'Microsoft.BingNews_8wekyb3d8bbwe' }
        Mock Remove-AppxPackage { throw 'Deployment failed with HRESULT: 0x80073CFA' }
        { Remove-AfAppxPackage -Tx (New-AfTransaction -User $script:me) -App ([pscustomobject]@{ Name = 'Noticias'; PackageName = 'Microsoft.BingNews' }) } | Should -Throw -ExpectedMessage 'Windows no dejó quitar Noticias'
    }

    It 'deshacer la reinstala desde la Store si ya no está en la PC' {
        Mock Get-AppxPackage { @() }
        Mock Get-AppxProvisionedPackage { @() }
        Mock Get-AfWingetPath { 'C:\winget\winget.exe' }
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 0; Output = ''; Error = ''; TimedOut = $false } }
        $record = [pscustomobject]@{ Kind = 'AppxPackage'; Name = 'TikTok'; PackageName = 'BytedancePte.Ltd.TikTok'; PackageFamilyName = 'BytedancePte.Ltd.TikTok_6yccndn6064se'; StoreId = '9NH2GPH4JZS4'; Previous = 'Installed'; New = 'Removed' }
        Undo-AfRecord -Record $record -User $script:me
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq 'install --id 9NH2GPH4JZS4 --source msstore --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' }
    }

    It 'sin ID ni copia en la PC, deshacer da un motivo amable' {
        Mock Get-AppxPackage { @() }
        Mock Get-AppxProvisionedPackage { @() }
        $record = [pscustomobject]@{ Kind = 'AppxPackage'; Name = 'Candy Crush'; PackageName = 'king.com.CandyCrushSodaSaga'; PackageFamilyName = 'king.com.CandyCrushSodaSaga_kgqvnymyfvs32'; StoreId = $null; Previous = 'Installed'; New = 'Removed' }
        { Undo-AfRecord -Record $record -User $script:me } | Should -Throw -ExpectedMessage 'ya no está en la PC; se reinstala desde la Microsoft Store'
    }
}
