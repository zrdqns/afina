BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:me = Get-AfUserForSid -Sid ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
}

AfterAll {
    $root = 'HKCU:\Software\AfinaTest'
    if ((Test-Path $root) -and -not @(Get-ChildItem $root).Count) { Remove-Item $root -Force }
}

Describe 'Set-AfRegistryValue y Restore-AfRegistryValue' {
    BeforeEach {
        $script:key = 'HKCU:\Software\AfinaTest\' + [guid]::NewGuid().ToString('N')
        New-Item -Path $script:key -Force | Out-Null
        $script:tx = New-AfTransaction -User $script:me
    }
    AfterEach { Remove-Item -LiteralPath $script:key -Recurse -Force -ErrorAction SilentlyContinue }

    It 'crea un DWORD que no existía y deshacer lo borra' {
        Set-AfRegistryValue -Tx $script:tx -Path $script:key -Name 'Valor' -Type DWord -Value 2 | Should -BeTrue
        (Get-AfRegistryState -Path $script:key -Name 'Valor').Value | Should -Be 2
        Undo-AfRecord -Record $script:tx.Records[0] -User $script:me
        (Get-AfRegistryState -Path $script:key -Name 'Valor').Exists | Should -BeFalse
    }

    It 'cambia un DWORD existente y deshacer deja el valor y el tipo originales' {
        New-ItemProperty -LiteralPath $script:key -Name 'Valor' -PropertyType DWord -Value 1 | Out-Null
        Set-AfRegistryValue -Tx $script:tx -Path $script:key -Name 'Valor' -Type DWord -Value 2 | Out-Null
        $r = $script:tx.Records[0]
        $r.Kind | Should -Be 'RegistryValue'
        $r.Previous.Value | Should -Be 1
        $r.New.Value | Should -Be 2
        Undo-AfRecord -Record $r -User $script:me
        $s = Get-AfRegistryState -Path $script:key -Name 'Valor'
        $s.Type | Should -Be 'DWord'
        $s.Value | Should -Be 1
    }

    It 'no deja registro si el valor ya es el objetivo' {
        New-ItemProperty -LiteralPath $script:key -Name 'Valor' -PropertyType DWord -Value 2 | Out-Null
        Set-AfRegistryValue -Tx $script:tx -Path $script:key -Name 'Valor' -Type DWord -Value 2 | Should -BeFalse
        $script:tx.Records.Count | Should -Be 0
    }

    It 'conserva REG_EXPAND_SZ sin expandir' {
        New-ItemProperty -LiteralPath $script:key -Name 'Ruta' -PropertyType ExpandString -Value '%SystemRoot%\x' | Out-Null
        Set-AfRegistryValue -Tx $script:tx -Path $script:key -Name 'Ruta' -Type String -Value 'otra' | Out-Null
        Undo-AfRecord -Record $script:tx.Records[0] -User $script:me
        $s = Get-AfRegistryState -Path $script:key -Name 'Ruta'
        $s.Type | Should -Be 'ExpandString'
        $s.Value | Should -Be '%SystemRoot%\x'
    }

    It 'Binary y MultiString vuelven iguales tras pasar por JSON' {
        New-ItemProperty -LiteralPath $script:key -Name 'Bytes' -PropertyType Binary -Value ([byte[]](2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)) | Out-Null
        New-ItemProperty -LiteralPath $script:key -Name 'Lista' -PropertyType MultiString -Value ([string[]]('a', 'b')) | Out-Null
        Set-AfRegistryValue -Tx $script:tx -Path $script:key -Name 'Bytes' -Type Binary -Value ([byte[]](3, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8)) | Out-Null
        Set-AfRegistryValue -Tx $script:tx -Path $script:key -Name 'Lista' -Type MultiString -Value ([string[]]('c')) | Out-Null
        $json = ConvertTo-Json -InputObject @($script:tx.Records) -Depth 6
        # En 5.1, ConvertFrom-Json devuelve el arreglo entero como un solo objeto: se desarma con la canalización.
        $records = @(ConvertFrom-Json -InputObject $json | ForEach-Object { $_ })
        Undo-AfRecord -Record $records[1] -User $script:me
        Undo-AfRecord -Record $records[0] -User $script:me
        $bytes = Get-AfRegistryState -Path $script:key -Name 'Bytes'
        $bytes.Type | Should -Be 'Binary'
        @($bytes.Value) | Should -Be @(2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        $list = Get-AfRegistryState -Path $script:key -Name 'Lista'
        $list.Type | Should -Be 'MultiString'
        @($list.Value) | Should -Be @('a', 'b')
    }

    It 'si creó la clave, deshacer borra la clave vacía' {
        $sub = "$script:key\Nueva"
        Set-AfRegistryValue -Tx $script:tx -Path $sub -Name 'V' -Type DWord -Value 1 | Out-Null
        $script:tx.Records[0].KeyExisted | Should -BeFalse
        Undo-AfRecord -Record $script:tx.Records[0] -User $script:me
        Test-Path -LiteralPath $sub | Should -BeFalse
    }

    It 'escribe y deshace el valor por defecto, y borra las claves padres que creó' {
        $leaf = "$script:key\Nueva\InprocServer32"
        Set-AfRegistryValue -Tx $script:tx -Path $leaf -Name '' -Type String -Value '' | Should -BeTrue
        (Get-AfRegistryState -Path $leaf -Name '').Exists | Should -BeTrue
        Undo-AfRecord -Record $script:tx.Records[0] -User $script:me
        Test-Path "$script:key\Nueva" | Should -BeFalse
        Test-Path $script:key | Should -BeTrue
    }

    It 'no borra una clave padre que ganó contenido' {
        $leaf = "$script:key\Nueva\InprocServer32"
        Set-AfRegistryValue -Tx $script:tx -Path $leaf -Name '' -Type String -Value '' | Out-Null
        New-ItemProperty -LiteralPath "$script:key\Nueva" -Name 'Otro' -PropertyType DWord -Value 1 | Out-Null
        Undo-AfRecord -Record $script:tx.Records[0] -User $script:me
        Test-Path $leaf | Should -BeFalse
        Test-Path "$script:key\Nueva" | Should -BeTrue
    }

    It 'un registro guardado sin CreatedKeys se sigue deshaciendo' {
        $leaf = "$script:key\Vieja"
        Set-AfRegistryValue -Tx $script:tx -Path $leaf -Name 'V' -Type DWord -Value 1 | Out-Null
        $old = $script:tx.Records[0] | Select-Object * -ExcludeProperty CreatedKeys
        Undo-AfRecord -Record $old -User $script:me
        Test-Path $leaf | Should -BeFalse
    }

    It 'CreatedKeys sobrevive a JSON aunque sea una sola clave' {
        $leaf = "$script:key\Sola"
        Set-AfRegistryValue -Tx $script:tx -Path $leaf -Name 'V' -Type DWord -Value 1 | Out-Null
        $json = ConvertTo-Json -InputObject @($script:tx.Records) -Depth 6
        $records = @(ConvertFrom-Json -InputObject $json | ForEach-Object { $_ })
        Undo-AfRecord -Record $records[0] -User $script:me
        Test-Path $leaf | Should -BeFalse
    }

    It 'Test-AfRecordRestored da $true tras deshacer y $false antes' {
        New-ItemProperty -LiteralPath $script:key -Name 'Valor' -PropertyType DWord -Value 1 | Out-Null
        Set-AfRegistryValue -Tx $script:tx -Path $script:key -Name 'Valor' -Type DWord -Value 2 | Out-Null
        $r = $script:tx.Records[0]
        Test-AfRecordRestored -Record $r -User $script:me | Should -BeFalse
        Undo-AfRecord -Record $r -User $script:me
        Test-AfRecordRestored -Record $r -User $script:me | Should -BeTrue
    }

    It 'Undo-AfRecords sigue si uno falla, deshace al revés y devuelve el fallido' {
        Set-AfRegistryValue -Tx $script:tx -Path $script:key -Name 'Buena' -Type DWord -Value 1 | Out-Null
        Set-AfRegistryValue -Tx $script:tx -Path $script:key -Name 'Mala' -Type DWord -Value 1 | Out-Null
        Mock Restore-AfRegistryValue { throw (New-AfApplyError -Reason 'la clave está bloqueada') } -ParameterFilter { $Record.Name -eq 'Mala' }
        $result = Undo-AfRecords -Records @($script:tx.Records) -User $script:me
        @($result.Failed).Count | Should -Be 1
        $result.Failed[0].Name | Should -Be 'Mala'
        $result.Reason | Should -Be 'la clave está bloqueada'
        (Get-AfRegistryState -Path $script:key -Name 'Buena').Exists | Should -BeFalse
    }

    It 'Undo-AfRecords salta los registros Action' {
        Add-AfTxRecord -Tx $script:tx -Record @{ Kind = 'Action'; Name = 'Temporales'; Detail = 'Se liberaron 1,0 GB' }
        $result = Undo-AfRecords -Records @($script:tx.Records) -User $script:me
        @($result.Failed).Count | Should -Be 0
    }
}

Describe 'Restore-AfRegistryValue con otro usuario' {
    It 'Restore-AfRegistryValue usa HKEY_USERS si la sesión es de otro usuario' {
        $other = Get-AfUserForSid -Sid 'S-1-5-21-9'
        $other.IsSameAsProcess | Should -BeFalse
        Mock Test-Path { $true }
        Mock New-Item { }
        Mock New-ItemProperty { }
        $record = [pscustomobject]@{
            Kind = 'RegistryValue'; Path = 'HKCU:\Software\Microsoft\GameBar'; Name = 'AutoGameModeEnabled'; KeyExisted = $true
            Previous = [pscustomobject]@{ Exists = $true; Type = 'DWord'; Value = 0 }
            New = [pscustomobject]@{ Exists = $true; Type = 'DWord'; Value = 1 }
        }
        Restore-AfRegistryValue -Record $record -User $other
        Should -Invoke New-ItemProperty -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq 'Registry::HKEY_USERS\S-1-5-21-9\Software\Microsoft\GameBar' }
    }
}

Describe 'Errores amables y comparación' {
    It 'Get-AfApplyReason da el motivo de Afina o el genérico' {
        try { throw (New-AfApplyError -Reason 'el adaptador no respondió') } catch { Get-AfApplyReason -ErrorRecord $_ | Should -Be 'el adaptador no respondió' }
        try { throw 'texto crudo de Windows' } catch { Get-AfApplyReason -ErrorRecord $_ | Should -Be 'Windows no aceptó el cambio' }
    }

    It 'Test-AfRevertError reconoce el error de vuelta atrás' {
        try { throw (New-AfApplyError -Reason 'Se volvió a 60 Hz' -Reverted) } catch { Test-AfRevertError -ErrorRecord $_ | Should -BeTrue }
        try { throw (New-AfApplyError -Reason 'otro') } catch { Test-AfRevertError -ErrorRecord $_ | Should -BeFalse }
    }

    It 'ConvertTo-AfComparable iguala byte[] con el arreglo de JSON y hashtable con objeto' {
        $a = [pscustomobject]@{ Exists = $true; Type = 'Binary'; Value = [byte[]](3, 0) }
        $b = ConvertFrom-Json -InputObject '{"Value":[3,0],"Type":"Binary","Exists":true}'
        ConvertTo-AfComparable $a | Should -Be (ConvertTo-AfComparable $b)
        ConvertTo-AfComparable @{ Width = 1920; Hz = 60 } | Should -Be (ConvertTo-AfComparable ([pscustomobject]@{ Hz = [long]60; Width = 1920 }))
        ConvertTo-AfComparable 1 | Should -Not -Be (ConvertTo-AfComparable 2)
    }
}
