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
    function Get-AfServedText([string]$ContentType, [string]$Path = 'dist\Afina.ps1') {
        $bytes = [System.IO.File]::ReadAllBytes((Join-Path $script:root $Path))
        $server = Start-AfTestServer -ContentType $ContentType -Body $bytes
        try { Invoke-RestMethod -Uri $server.Url -UseBasicParsing -TimeoutSec 20 } finally { $server.Listener.Stop(); $server.PowerShell.Dispose() }
    }
}

# Un archivo de un release de GitHub llega como application/octet-stream y Windows PowerShell 5.1 lo decodifica
# como Latin-1 (los acentos se rompen): la línea usa el archivo crudo (raw.githubusercontent.com), que va como UTF-8.
Describe 'Línea de internet (irm | iex)' {
    It 'irm entrega el build intacto como texto UTF-8 (raw de GitHub)' {
        $text = Get-AfServedText -ContentType 'text/plain; charset=utf-8'
        $text.Contains('Afina 0.6.0: análisis y optimización de Windows') | Should -BeTrue
        { [scriptblock]::Create($text) } | Should -Not -Throw
    }

    # La línea corta (irm zrdqns.github.io/afina | iex) baja web\index.html desde GitHub Pages, que lo sirve como HTML en UTF-8.
    # Para el navegador es una página; para PowerShell, un comentario y una sola orden: bajar el build de main y correrlo.
    It 'la página de la línea corta solo carga el build de main' {
        $text = Get-AfServedText -ContentType 'text/html; charset=utf-8' -Path 'web\index.html'
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$errors)
        @($errors) | Should -BeNullOrEmpty
        $statements = @($ast.EndBlock.Statements)
        $statements.Count | Should -Be 1
        $statements[0].Extent.Text | Should -Be 'irm https://raw.githubusercontent.com/zrdqns/afina/main/dist/Afina.ps1 | iex'
        # Sin BOM: irm dejaría U+FEFF antes del "<#" que abre el comentario.
        [System.IO.File]::ReadAllBytes((Join-Path $script:root 'web\index.html'))[0] | Should -Be ([byte][char]'<')
    }

    # Con BOM, irm deja U+FEFF pegado al primer "#": el comentario y el bloque param se leen como comandos.
    It 'el archivo de la línea no lleva BOM y su bloque param se reconoce' {
        $text = Get-AfServedText -ContentType 'text/plain; charset=utf-8'
        [int]$text[0] | Should -Not -Be 0xFEFF
        [scriptblock]::Create($text).Ast.ParamBlock | Should -Not -BeNullOrEmpty
    }

    # Corre en un runspace aparte, como iex en una consola sin administrador: sin ruta de script y sin relanzar.
    It 'sin administrador, la línea dice cómo abrirla, sin errores y sin relanzar' {
        if (Test-AfAdmin) { Set-ItResult -Skipped -Because 'como administrador abriría la ventana'; return }
        $text = Get-AfServedText -ContentType 'text/plain; charset=utf-8'
        $ps = [powershell]::Create()
        try {
            [void]$ps.AddScript('param($t) Invoke-Expression $t; "siguio"').AddArgument($text)
            $output = @($ps.Invoke())
            @($ps.Streams.Error | ForEach-Object { $_.ToString() }) | Should -BeNullOrEmpty
            (@($ps.Streams.Information | ForEach-Object { [string]$_.MessageData }) -join ' ') | Should -Match 'PowerShell (como administrador|as administrator)'
            # return deja la consola abierta: el código de después de iex sigue.
            $output | Should -Contain 'siguio'
        } finally { $ps.Dispose() }
    }
}
