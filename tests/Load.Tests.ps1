BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
}

Describe 'Carga del código' {
    It 'Get-AfVersion devuelve 0.4.0' {
        Get-AfVersion | Should -Be '0.4.0'
    }

    It 'AfCode contiene la definición de Get-AfVersion' {
        $Global:AfCode | Should -Match 'function Get-AfVersion'
    }

    It 'AfFiles lista archivos que existen' {
        $Global:AfFiles.Count | Should -BeGreaterThan 0
        foreach ($f in $Global:AfFiles) { Test-Path $f | Should -BeTrue }
    }
}
