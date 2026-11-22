BeforeAll {
    . "$PSScriptRoot\..\src\Load.ps1"
    $script:root = Split-Path $PSScriptRoot -Parent
    # Sirve un solo pedido en localhost con el tipo de contenido dado, como GitHub sirve un archivo de un release.
    function Start-AfTestServer([string]$ContentType, [byte[]]$Body) {
        $listener = New-Object System.Net.HttpListener
        $port = Get-Random -Minimum 20000 -Maximum 40000
        $listener.Prefixes.Add("http://localhost:$port/")
        $listener.Start()
        $ps = [powershell]::Create()
        [void]$ps.AddScript({
                param($Listener, $ContentType, $Body)
                $context = $Listener.GetContext()
                $context.Response.ContentType = $ContentType
                $context.Response.ContentLength64 = $Body.Length
                $context.Response.OutputStream.Write($Body, 0, $Body.Length)
                $context.Response.Close()
            }).AddArgument($listener).AddArgument($ContentType).AddArgument($Body)
        [pscustomobject]@{ Listener = $listener; Url = "http://localhost:$port/Afina.ps1"; PowerShell = $ps; Handle = $ps.BeginInvoke() }
    }
    function Get-AfServedText([string]$ContentType) {
        $bytes = [System.IO.File]::ReadAllBytes((Join-Path $script:root 'dist\Afina.ps1'))
        $server = Start-AfTestServer -ContentType $ContentType -Body $bytes
        try { Invoke-RestMethod -Uri $server.Url -UseBasicParsing -TimeoutSec 20 } finally { $server.Listener.Stop(); $server.PowerShell.Dispose() }
    }
}

# Un archivo de un release de GitHub llega como application/octet-stream y Windows PowerShell 5.1 lo decodifica
# como Latin-1 (los acentos se rompen): la línea usa el archivo crudo (raw.githubusercontent.com), que va como UTF-8.
Describe 'Línea de internet (irm | iex)' {
    It 'irm entrega el build intacto como texto UTF-8 (raw de GitHub)' {
        $text = Get-AfServedText -ContentType 'text/plain; charset=utf-8'
        $text.Contains('Afina 0.3.0: análisis y optimización de Windows') | Should -BeTrue
        { [scriptblock]::Create($text) } | Should -Not -Throw
    }

    It 'la URL de la línea es la del archivo crudo de GitHub' {
        $main = [System.IO.File]::ReadAllText((Join-Path $script:root 'src\Main.ps1'))
        $main | Should -Match ([regex]::Escape("`$AfOneLinerUrl = 'https://raw.githubusercontent.com/zrdqns/afina/main/dist/Afina.ps1'"))
    }
}
