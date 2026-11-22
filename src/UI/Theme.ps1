Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function Get-AfIconNames {
    'lightning', 'game-controller', 'wifi-high', 'rocket-launch', 'hard-drives', 'shield-check', 'wrench', 'sliders-horizontal',
    'check-circle', 'squares-four', 'cpu', 'graphics-card', 'memory', 'windows-logo', 'plug-charging', 'clock-counter-clockwise',
    'arrow-right', 'arrow-clockwise', 'arrow-counter-clockwise', 'caret-down', 'check', 'shield-warning', 'warning-circle', 'gear-six', 'info'
}

# Variante rellena: categoría activa en la navegación y círculo de "hecho".
function Get-AfFillIconNames {
    'squares-four', 'lightning', 'game-controller', 'wifi-high', 'rocket-launch', 'hard-drives', 'shield-check', 'wrench', 'sliders-horizontal', 'check-circle'
}

function Get-AfIconData {
    param([Parameter(Mandatory)][string]$Name, [ValidateSet('Bold', 'Fill')][string]$Variant = 'Bold')
    $key = '{0}|{1}' -f $Name, $Variant
    if (-not $script:AfIcons -or -not $script:AfIcons.ContainsKey($key)) { throw "Icono no incluido: $key" }
    $script:AfIcons[$key]
}

function Get-AfThemeColors {
    param([ValidateSet('Black', 'White')][string]$Name = 'Black')
    if ($Name -eq 'Black') {
        [ordered]@{
            Bg = '#FF0A0A0B'; Rail = '#FF0E0E10'; Panel = '#FF131315'; Raised = '#FF19191C'
            Line = '#12FFFFFF'; Line2 = '#21FFFFFF'
            Text = '#FFF5F5F4'; Text2 = '#FFA1A1A6'; Text3 = '#FF7A7A80'
            Red = '#FFFF3B47'; RedText = '#FFEF3340'; RedFill = '#FFD11F2C'
            CheckBg = '#FFF5F5F4'; CheckFg = '#FF0A0A0B'
            Tick = '#2BFFFFFF'; TickMajor = '#73FFFFFF'
        }
    } else {
        [ordered]@{
            Bg = '#FFF5F5F3'; Rail = '#FFEDEDEA'; Panel = '#FFFFFFFF'; Raised = '#FFF8F8F6'
            Line = '#12000000'; Line2 = '#24000000'
            Text = '#FF111113'; Text2 = '#FF5C5C63'; Text3 = '#FF6B6B72'
            Red = '#FFE0202E'; RedText = '#FFC8102E'; RedFill = '#FFD11F2C'
            CheckBg = '#FF111113'; CheckFg = '#FFFFFFFF'
            Tick = '#2B000000'; TickMajor = '#80000000'
        }
    }
}

function Get-AfThemeXaml {
    param([ValidateSet('Black', 'White')][string]$Name = 'Black')
    $colors = Get-AfThemeColors -Name $Name
    $brushes = ($colors.Keys | ForEach-Object { '    <SolidColorBrush x:Key="{0}" Color="{1}"/>' -f $_, $colors[$_] }) -join "`r`n"
    @"
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
$brushes
    <FontFamily x:Key="DisplayFont">Bahnschrift</FontFamily>
    <FontFamily x:Key="TextFont">Segoe UI Variable Text, Segoe UI</FontFamily>
</ResourceDictionary>
"@
}

function Resolve-AfTheme {
    param([ValidateSet('System', 'Black', 'White')][string]$Setting = 'System', $User)
    if ($Setting -ne 'System') { return $Setting }
    $light = Get-AfRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -User $User
    if ($light -eq 1) { 'White' } else { 'Black' }
}
