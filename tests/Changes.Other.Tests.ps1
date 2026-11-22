BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    . "$PSScriptRoot\Helpers\FakeInventory.ps1"
    $script:me = Get-AfUserForSid
}

AfterAll {
    $root = 'HKCU:\Software\AfinaTest'
    if ((Test-Path $root) -and -not @(Get-ChildItem $root).Count) { Remove-Item $root -Force }
}

Describe 'Defender' {
    It 'Set-AfMpPreference guarda PUAProtection 0 y pone 1' {
        Mock Get-MpPreference { [pscustomobject]@{ PUAProtection = [byte]0 } }
        Mock Set-MpPreference { }
        $tx = New-AfTransaction
        Set-AfMpPreference -Tx $tx -Name 'PUAProtection' -Value 1 | Should -BeTrue
        $tx.Records[0].Kind | Should -Be 'MpPreference'
        $tx.Records[0].Previous | Should -Be 0
        Should -Invoke Set-MpPreference -Times 1 -Exactly -ParameterFilter { $PUAProtection -eq 1 }
        Restore-AfMpPreference -Record $tx.Records[0]
        Should -Invoke Set-MpPreference -Times 1 -Exactly -ParameterFilter { $PUAProtection -eq 0 }
    }

    It 'Set-AfMpPreference no hace nada si ya vale el objetivo' {
        Mock Get-MpPreference { [pscustomobject]@{ PUAProtection = [byte]1 } }
        Mock Set-MpPreference { }
        Set-AfMpPreference -Tx (New-AfTransaction) -Name 'PUAProtection' -Value 1 | Should -BeFalse
        Should -Invoke Set-MpPreference -Times 0 -Exactly
    }

    It 'Enable-AfDefenderRealtime da el motivo de la protección contra alteraciones si sigue apagada' {
        Mock Get-MpPreference { [pscustomobject]@{ DisableRealtimeMonitoring = $true } }
        Mock Set-MpPreference { }
        Mock Get-MpComputerStatus { [pscustomobject]@{ RealTimeProtectionEnabled = $false } }
        Mock Start-Sleep { }
        $tx = New-AfTransaction
        { Enable-AfDefenderRealtime -Tx $tx -WaitSeconds 0 } | Should -Throw -ExpectedMessage 'la protección contra alteraciones no dejó encenderla*'
        $tx.Records.Count | Should -Be 1
    }

    It 'Enable-AfDefenderRealtime termina si la protección quedó encendida' {
        Mock Get-MpPreference { [pscustomobject]@{ DisableRealtimeMonitoring = $true } }
        Mock Set-MpPreference { }
        Mock Get-MpComputerStatus { [pscustomobject]@{ RealTimeProtectionEnabled = $true } }
        { Enable-AfDefenderRealtime -Tx (New-AfTransaction) } | Should -Not -Throw
    }

    It 'Update-AfDefenderSignatures deja un registro Action y una nota' {
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*MpCmdRun.exe' }
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 0; Output = ''; Error = ''; TimedOut = $false } }
        $tx = New-AfTransaction
        Update-AfDefenderSignatures -Tx $tx
        $tx.Records[0].Kind | Should -Be 'Action'
        $tx.Notes[0] | Should -Be 'Firmas al día.'
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq '-SignatureUpdate' }
    }

    It 'Update-AfDefenderSignatures sin conexión da el motivo amable' {
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*MpCmdRun.exe' }
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 2; Output = ''; Error = ''; TimedOut = $false } }
        { Update-AfDefenderSignatures -Tx (New-AfTransaction) } | Should -Throw -ExpectedMessage 'no se pudieron descargar las firmas*'
    }
}

Describe 'Firewall' {
    It 'Set-AfFirewallProfile guarda False y Restore lo deja en False' {
        Mock Get-NetFirewallProfile { [pscustomobject]@{ Name = 'Public'; Enabled = 'False' } }
        Mock Set-NetFirewallProfile { }
        $tx = New-AfTransaction
        Set-AfFirewallProfile -Tx $tx -Profile 'Public' -Enabled $true | Should -BeTrue
        $tx.Records[0].Previous | Should -Be 'False'
        Should -Invoke Set-NetFirewallProfile -Times 1 -Exactly -ParameterFilter { $Name -eq 'Public' -and $Enabled -eq 'True' }
        Restore-AfFirewallProfile -Record $tx.Records[0]
        Should -Invoke Set-NetFirewallProfile -Times 1 -Exactly -ParameterFilter { $Name -eq 'Public' -and $Enabled -eq 'False' }
    }
}

Describe 'TRIM' {
    It 'Set-AfTrim guarda que estaba apagado y lo enciende' {
        $sample = 'NTFS DisableDeleteNotify = 1  (Deshabilitado)'
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 0; Output = $sample; Error = ''; TimedOut = $false } } -ParameterFilter { $Arguments -like 'behavior query*' }
        Mock Invoke-AfProcess { [pscustomobject]@{ ExitCode = 0; Output = ''; Error = ''; TimedOut = $false } } -ParameterFilter { $Arguments -like 'behavior set*' }
        $tx = New-AfTransaction
        Set-AfTrim -Tx $tx -Enabled $true | Should -BeTrue
        $tx.Records[0].Previous | Should -BeFalse
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq 'behavior set DisableDeleteNotify NTFS 0' }
        Restore-AfTrim -Record $tx.Records[0]
        Should -Invoke Invoke-AfProcess -Times 1 -Exactly -ParameterFilter { $Arguments -eq 'behavior set DisableDeleteNotify NTFS 1' }
    }
}

Describe 'Clear-AfTempFiles' {
    It 'borra lo viejo, deja lo reciente, salta lo abierto y no entra en una unión' {
        $root = Join-Path $TestDrive 'temp'
        $sub = Join-Path $root 'sub'
        $outside = Join-Path $TestDrive 'fuera'
        New-Item -ItemType Directory -Path $sub, $outside -Force | Out-Null
        $files = @{}
        foreach ($name in 'viejo', 'nuevo', 'abierto') { $files[$name] = Join-Path $root "$name.tmp" }
        $files.sub = Join-Path $sub 'otro.tmp'
        $files.keep = Join-Path $outside 'importante.txt'
        foreach ($path in $files.Values) { [System.IO.File]::WriteAllText($path, ('x' * 1000)) }
        foreach ($name in 'viejo', 'abierto', 'sub', 'keep') { (Get-Item $files[$name]).LastWriteTime = (Get-Date).AddDays(-2) }
        (Get-Item $files.nuevo).LastWriteTime = (Get-Date).AddHours(-1)
        $junction = Join-Path $root 'union'
        New-Item -ItemType Junction -Path $junction -Target $outside | Out-Null
        Mock Get-AfTempFolders { [pscustomobject]@{ Path = $root; MinAgeHours = 24 } }
        Mock Clear-AfDeliveryOptimizationCache { [long]0 }
        $tx = New-AfTransaction
        $stream = [System.IO.File]::Open($files.abierto, 'Open', 'Read', 'None')
        try { Clear-AfTempFiles -Tx $tx -Inventory (New-AfFakeInventory) } finally { $stream.Dispose() }
        try {
            Test-Path $files.viejo | Should -BeFalse
            Test-Path $files.nuevo | Should -BeTrue
            Test-Path $files.abierto | Should -BeTrue
            Test-Path $files.sub | Should -BeFalse
            Test-Path $sub | Should -BeFalse
            Test-Path $files.keep | Should -BeTrue
            $tx.Records[0].Kind | Should -Be 'Action'
            $tx.Records[0].FreedBytes | Should -BeGreaterOrEqual 2000
            $tx.Notes[0] | Should -Match '^Se liberaron '
        } finally {
            [System.IO.Directory]::Delete($junction)
        }
    }
}

Describe 'Inicio' {
    BeforeEach {
        $script:key = 'HKCU:\Software\AfinaTest\' + [guid]::NewGuid().ToString('N')
        New-Item -Path $script:key -Force | Out-Null
    }
    AfterEach { Remove-Item -LiteralPath $script:key -Recurse -Force -ErrorAction SilentlyContinue }

    It 'Get-AfStartupDisabledBytes da 12 bytes que empiezan en 3' {
        $bytes = Get-AfStartupDisabledBytes
        $bytes.Length | Should -Be 12
        $bytes[0] | Should -Be 3
    }

    It 'Disable-AfStartupEntry deja el primer byte impar y deshacer lo quita' {
        $tx = New-AfTransaction -User $script:me
        $entry = [pscustomobject]@{ Name = 'Spotify'; ApprovedKey = $script:key; ApprovedName = 'Spotify' }
        Disable-AfStartupEntry -Tx $tx -Entry $entry | Should -BeTrue
        $value = Get-AfRegistryValue -Path $script:key -Name 'Spotify'
        ([int]@($value)[0] -band 1) | Should -Be 1
        Undo-AfRecords -Records @($tx.Records) -User $script:me | Out-Null
        (Get-AfRegistryState -Path $script:key -Name 'Spotify').Exists | Should -BeFalse
    }

    It 'Disable-AfStartupEntry no reescribe una entrada ya desactivada' {
        New-ItemProperty -LiteralPath $script:key -Name 'Spotify' -PropertyType Binary -Value (Get-AfStartupDisabledBytes -Time (Get-Date).AddDays(-30)) | Out-Null
        $tx = New-AfTransaction -User $script:me
        Disable-AfStartupEntry -Tx $tx -Entry ([pscustomobject]@{ Name = 'Spotify'; ApprovedKey = $script:key; ApprovedName = 'Spotify' }) | Should -BeFalse
        $tx.Records.Count | Should -Be 0
    }
}
