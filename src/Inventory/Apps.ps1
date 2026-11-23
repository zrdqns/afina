# Apps promocionales preinstaladas (lista cerrada y conservadora; ver sección 10 del diseño).
# StoreId y FamilyName verificados en el catálogo de la Microsoft Store (displaycatalog, 2026-11-21):
# el ID solo se usa si el paquete instalado es exactamente ese, para reinstalarlo al deshacer.
# Es una función, no datos sueltos: los nombres se traducen al usarla, con el idioma ya fijado.
function Get-AfPromoAppPatterns {
    @(
    @{ Pattern = 'king.com.CandyCrush*'; Name = 'Candy Crush'; StoreId = '9NBLGGH18846'; FamilyName = 'king.com.CandyCrushSaga_kgqvnymyfvs32' }
    @{ Pattern = 'BytedancePte.Ltd.TikTok'; Name = 'TikTok'; StoreId = '9NH2GPH4JZS4'; FamilyName = 'BytedancePte.Ltd.TikTok_6yccndn6064se' }
    @{ Pattern = 'Disney.37853FC22B2CE'; Name = 'Disney+'; StoreId = '9NXQXXLFST89'; FamilyName = 'Disney.37853FC22B2CE_6rarf9sa4v8jt' }
    @{ Pattern = 'Facebook.Facebook'; Name = 'Facebook'; StoreId = '9WZDNCRFJ2WL'; FamilyName = 'Facebook.Facebook_8xx8rvfyw5nnt' }
    @{ Pattern = 'Facebook.InstagramBeta'; Name = 'Instagram'; StoreId = '9NBLGGH5L9XT'; FamilyName = 'Facebook.InstagramBeta_8xx8rvfyw5nnt' }
    @{ Pattern = '7EE7776C.LinkedInforWindows'; Name = 'LinkedIn'; StoreId = '9WZDNCRFJ4Q7'; FamilyName = '7EE7776C.LinkedInforWindows_w1wdnht996qgy' }
    @{ Pattern = 'Microsoft.MicrosoftSolitaireCollection'; Name = (T 'Solitario'); StoreId = '9WZDNCRFHWD2'; FamilyName = 'Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe' }
    @{ Pattern = 'Microsoft.BingNews'; Name = (T 'Noticias'); StoreId = '9WZDNCRFHVFW'; FamilyName = 'Microsoft.BingNews_8wekyb3d8bbwe' }
    @{ Pattern = 'Microsoft.Getstarted'; Name = (T 'Sugerencias'); StoreId = '9WZDNCRDTBJJ'; FamilyName = 'Microsoft.Getstarted_8wekyb3d8bbwe' }
    @{ Pattern = 'Microsoft.GetHelp'; Name = (T 'Obtener ayuda'); StoreId = '9PKDZBMV1H3T'; FamilyName = 'Microsoft.GetHelp_8wekyb3d8bbwe' }
    @{ Pattern = 'Microsoft.WindowsFeedbackHub'; Name = (T 'Centro de opiniones'); StoreId = '9NBLGGH4R32N'; FamilyName = 'Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe' }
    @{ Pattern = 'Microsoft.MixedReality.Portal'; Name = (T 'Portal de realidad mixta'); StoreId = '9NG1H8B3ZC7M'; FamilyName = 'Microsoft.MixedReality.Portal_8wekyb3d8bbwe' }
    )
}

function Get-AfPromoApps {
    param($User)
    $packages = @()
    try {
        $packages = if ($User -and -not $User.IsSameAsProcess) { @(Get-AppxPackage -User $User.Sid -ErrorAction Stop) } else { @(Get-AppxPackage -ErrorAction Stop) }
    } catch {
        Write-AfLog -Level Warn -Message "No se pudieron listar las apps: $($_.Exception.Message)"
    }
    $promo = @(foreach ($entry in Get-AfPromoAppPatterns) {
            $match = $packages | Where-Object { $_.Name -like $entry.Pattern } | Select-Object -First 1
            if ($match) {
                [pscustomobject]@{
                    Name = $entry.Name; PackageName = $match.Name; PackageFullName = $match.PackageFullName; PackageFamilyName = $match.PackageFamilyName
                    StoreId = if ($match.PackageFamilyName -eq $entry.FamilyName) { $entry.StoreId } else { $null }
                    Provisioned = $false
                }
            }
        })
    # Aprovisionada = sigue en la PC después de quitarla, y se puede registrar de nuevo sin internet.
    # La consulta tarda unos segundos: solo hace falta para las que no se pueden reinstalar desde la Store.
    if (@($promo | Where-Object { -not $_.StoreId }).Count) {
        try {
            $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop | ForEach-Object { [string]$_.DisplayName })
            foreach ($app in $promo) { $app.Provisioned = $provisioned -contains $app.PackageName }
        } catch {
            Write-AfLog -Level Warn -Message "No se pudieron listar las apps aprovisionadas: $($_.Exception.Message)"
        }
    }
    # Copilot no está en la lista cerrada: se ofrece aparte, con su propia revisión.
    $copilot = $null
    $found = $packages | Where-Object { $_.Name -eq 'Microsoft.Copilot' } | Select-Object -First 1
    if ($found) {
        $copilot = [pscustomobject]@{
            Name = 'Copilot'; PackageName = $found.Name; PackageFullName = $found.PackageFullName; PackageFamilyName = $found.PackageFamilyName
            StoreId = if ($found.PackageFamilyName -eq 'Microsoft.Copilot_8wekyb3d8bbwe') { '9NHT9RB2F4HD' } else { $null }
            Provisioned = $false
        }
    }
    $hasWidgets = [bool]($packages | Where-Object { $_.Name -eq 'MicrosoftWindows.Client.WebExperience' } | Select-Object -First 1)
    [pscustomobject]@{ Promo = $promo; Copilot = $copilot; HasWidgets = $hasWidgets }
}
