BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
}

Describe 'Código nativo' -Tag 'Integration' {
    It 'Initialize-AfNative compila sin errores' {
        Initialize-AfNative | Should -BeTrue
    }

    It 'Get-AfDisplayModes devuelve una pantalla con Hz y su modo actual dentro de Modes' {
        $displays = @(Get-AfDisplayModes)
        $displays.Count | Should -BeGreaterThan 0
        $d = $displays[0]
        $d.Hz | Should -BeGreaterThan 0
        @($d.Modes | Where-Object { $_.Width -eq $d.Width -and $_.Height -eq $d.Height -and $_.Hz -eq $d.Hz }).Count | Should -BeGreaterThan 0
    }

    It 'Get-AfPowerOverlay devuelve un GUID o null sin lanzar error' {
        { $script:ov = Get-AfPowerOverlay } | Should -Not -Throw
        if ($script:ov) { $script:ov | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' }
    }
}
