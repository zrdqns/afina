BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:guid = '{11111111-2222-3333-4444-555555555555}'
}

Describe 'Set-AfNetAdapterProperty' {
    BeforeEach {
        Mock Get-NetAdapter { [pscustomobject]@{ Name = 'Ethernet'; InterfaceGuid = $script:guid; InterfaceDescription = 'Realtek PCIe GbE Family Controller' } }
        Mock Get-NetAdapterAdvancedProperty { [pscustomobject]@{ RegistryKeyword = $RegistryKeyword; RegistryValue = @('1') } }
        Mock Set-NetAdapterAdvancedProperty { }
        Mock Restart-NetAdapter { }
    }

    It 'tres propiedades del mismo adaptador lo reinician una sola vez' {
        $tx = New-AfTransaction
        foreach ($keyword in '*EEE', 'AdvancedEEE', 'EnableGreenEthernet') { Set-AfNetAdapterProperty -Tx $tx -Adapter 'Ethernet' -Keyword $keyword -Value '0' | Out-Null }
        $tx.Records.Count | Should -Be 3
        $tx.Records[0].Previous | Should -Be '1'
        $tx.RestartAdapters.Count | Should -Be 1
        Complete-AfTransaction -Tx $tx
        Should -Invoke Restart-NetAdapter -Times 1 -Exactly
    }

    It 'usa -NoRestart al cambiar cada propiedad' {
        Set-AfNetAdapterProperty -Tx (New-AfTransaction) -Adapter 'Ethernet' -Keyword '*EEE' -Value '0' | Out-Null
        Should -Invoke Set-NetAdapterAdvancedProperty -Times 1 -Exactly -ParameterFilter { $NoRestart -and $RegistryKeyword -eq '*EEE' -and $RegistryValue -eq '0' }
    }

    It 'no hace nada si la propiedad ya vale el objetivo' {
        Mock Get-NetAdapterAdvancedProperty { [pscustomobject]@{ RegistryKeyword = $RegistryKeyword; RegistryValue = @('0') } }
        $tx = New-AfTransaction
        Set-AfNetAdapterProperty -Tx $tx -Adapter 'Ethernet' -Keyword '*EEE' -Value '0' | Should -BeFalse
        $tx.RestartAdapters.Count | Should -Be 0
    }

    It 'si el adaptador no responde da el motivo amable sin registro' {
        Mock Set-NetAdapterAdvancedProperty { throw 'Error crudo de CIM' }
        $tx = New-AfTransaction
        { Set-AfNetAdapterProperty -Tx $tx -Adapter 'Ethernet' -Keyword '*EEE' -Value '0' } | Should -Throw -ExpectedMessage 'el adaptador Ethernet no respondió'
        $tx.Records.Count | Should -Be 0
    }

    It 'Restore busca el adaptador por InterfaceGuid aunque cambie el nombre' {
        Mock Get-NetAdapter { [pscustomobject]@{ Name = 'Ethernet 2'; InterfaceGuid = $script:guid } }
        $record = [pscustomobject]@{ Kind = 'NetAdapterProperty'; InterfaceGuid = $script:guid; Adapter = 'Ethernet'; Keyword = '*EEE'; Previous = '1'; New = '0' }
        Restore-AfNetAdapterProperty -Record $record
        Should -Invoke Set-NetAdapterAdvancedProperty -Times 1 -Exactly -ParameterFilter { $Name -eq 'Ethernet 2' -and $RegistryValue -eq '1' -and $NoRestart }
    }

    It 'Undo-AfRecords reinicia una vez el adaptador al deshacer' {
        $records = @('*EEE', 'AdvancedEEE') | ForEach-Object { [pscustomobject]@{ Kind = 'NetAdapterProperty'; InterfaceGuid = $script:guid; Adapter = 'Ethernet'; Keyword = $_; Previous = '1'; New = '0' } }
        $result = Undo-AfRecords -Records $records
        @($result.Failed).Count | Should -Be 0
        Should -Invoke Set-NetAdapterAdvancedProperty -Times 2 -Exactly
        Should -Invoke Restart-NetAdapter -Times 1 -Exactly
    }
}
