BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:samples = Join-Path $PSScriptRoot 'Samples'
    function Read-Sample([string]$Name) { [System.IO.File]::ReadAllText((Join-Path $script:samples $Name), [System.Text.Encoding]::UTF8) }
}

Describe 'ConvertFrom-AfPowercfgQuery' {
    It 'lee CA y CC por posición en español' {
        $r = ConvertFrom-AfPowercfgQuery -Text (Read-Sample 'powercfg-wifi-es.txt')
        $r.Ac | Should -Be 0
        $r.Dc | Should -Be 2
    }

    It 'lee CA y CC por posición en inglés' {
        $r = ConvertFrom-AfPowercfgQuery -Text (Read-Sample 'powercfg-wifi-en.txt')
        $r.Ac | Should -Be 0
        $r.Dc | Should -Be 2
    }
}

Describe 'ConvertFrom-AfNetshWlan' {
    It 'lee la banda en español' {
        $r = ConvertFrom-AfNetshWlan -Text (Read-Sample 'netsh-wlan-es.txt')
        $r.Connected | Should -BeTrue
        $r.BandGHz | Should -Be 5
        $r.Channel | Should -Be 44
        $r.Ssid | Should -Be 'CasaNet'
    }

    It 'lee la banda en inglés' {
        $r = ConvertFrom-AfNetshWlan -Text (Read-Sample 'netsh-wlan-en.txt')
        $r.BandGHz | Should -Be 2.4
    }

    It 'saca 2,4 GHz del canal 6 sin la palabra GHz' {
        $r = ConvertFrom-AfNetshWlan -Text (Read-Sample 'netsh-wlan-win10-en.txt')
        $r.Connected | Should -BeTrue
        $r.BandGHz | Should -Be 2.4
    }

    It 'da desconectado si no hay SSID' {
        $r = ConvertFrom-AfNetshWlan -Text "Hay 1 interfaz en el sistema:`r`n    Nombre : Wi-Fi`r`n    Estado : desconectado"
        $r.Connected | Should -BeFalse
        $r.BandGHz | Should -BeNullOrEmpty
    }
}

Describe 'ConvertFrom-AfFsutilTrim' {
    It 'lee DisableDeleteNotify = 0 como TRIM activado' {
        (ConvertFrom-AfFsutilTrim -Text (Read-Sample 'fsutil-trim-es.txt')).NtfsDisabled | Should -BeFalse
    }

    It 'lee DisableDeleteNotify = 1 como TRIM apagado' {
        (ConvertFrom-AfFsutilTrim -Text 'NTFS DisableDeleteNotify = 1  (Disabled)').NtfsDisabled | Should -BeTrue
    }
}

Describe 'ConvertFrom-AfProductState' {
    It '397568 está activado y al día' {
        $r = ConvertFrom-AfProductState -State 397568
        $r.Enabled | Should -BeTrue
        $r.UpToDate | Should -BeTrue
    }

    It '393472 está apagado' {
        (ConvertFrom-AfProductState -State 393472).Enabled | Should -BeFalse
    }
}

Describe 'ConvertFrom-AfWingetUpgrade' {
    It 'lee dos apps de una tabla en español' {
        $apps = @(ConvertFrom-AfWingetUpgrade -Text (Read-Sample 'winget-upgrade-es.txt'))
        $apps.Count | Should -Be 2
        $apps[0].Name | Should -Be 'Google Chrome'
        $apps[0].Id | Should -Be 'Google.Chrome'
        $apps[0].Version | Should -Be '131.0.6778.86'
        $apps[0].Available | Should -Be '131.0.6778.109'
        $apps[1].Id | Should -Be 'Discord.Discord'
    }

    It 'devuelve vacío si no hay tabla' {
        @(ConvertFrom-AfWingetUpgrade -Text 'No se encontró ningún paquete instalado que coincida.').Count | Should -Be 0
    }

    It 'lee la columna Origen' {
        $apps = @(ConvertFrom-AfWingetUpgrade -Text (Read-Sample 'winget-upgrade-es.txt'))
        $apps[0].Source | Should -Be 'winget'
        $apps[1].Source | Should -Be 'winget'
    }
}

Describe 'Get-AfWddmVersion' {
    It "'32.0.15.6094' es 3.2" { Get-AfWddmVersion -DriverVersion '32.0.15.6094' | Should -Be 3.2 }
    It "'27.21.14.5671' es 2.7" { Get-AfWddmVersion -DriverVersion '27.21.14.5671' | Should -Be 2.7 }
    It 'una versión vacía da 0' { Get-AfWddmVersion -DriverVersion '' | Should -Be 0 }
}
