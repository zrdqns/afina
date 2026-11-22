function Test-AfMotionEnabled {
    param([ValidateSet('Auto', 'Always', 'Never')][string]$Setting = 'Auto')
    switch ($Setting) {
        'Always' { $true }
        'Never' { $false }
        default { [bool][System.Windows.SystemParameters]::ClientAreaAnimation }
    }
}

# Curvas de la sección 9 del diseño (cubic-bezier → KeySpline).
function New-AfKeySpline {
    param([ValidateSet('Out', 'InOut', 'Icon', 'Linear')][string]$Ease = 'Out')
    switch ($Ease) {
        'Out' { New-Object System.Windows.Media.Animation.KeySpline(0.23, 1, 0.32, 1) }
        'InOut' { New-Object System.Windows.Media.Animation.KeySpline(0.77, 0, 0.175, 1) }
        'Icon' { New-Object System.Windows.Media.Animation.KeySpline(0.2, 0, 0, 1) }
        default { New-Object System.Windows.Media.Animation.KeySpline(0, 0, 1, 1) }
    }
}

# Anima una propiedad double. Sin movimiento, pone el valor final al instante.
function Start-AfAnimation {
    param(
        [Parameter(Mandatory)]$Target,
        [Parameter(Mandatory)][System.Windows.DependencyProperty]$Property,
        [double]$From = [double]::NaN,
        [Parameter(Mandatory)][double]$To,
        [int]$DurationMs = 200,
        [int]$DelayMs = 0,
        [ValidateSet('Out', 'InOut', 'Icon', 'Linear')][string]$Ease = 'Out',
        [bool]$Enabled = $true
    )
    if (-not $Enabled) {
        $Target.BeginAnimation($Property, $null)
        $Target.SetValue($Property, $To)
        return
    }
    if (-not [double]::IsNaN($From)) {
        $Target.BeginAnimation($Property, $null)
        $Target.SetValue($Property, $From)
    }
    $animation = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
    $animation.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds($DurationMs))
    $animation.BeginTime = [TimeSpan]::FromMilliseconds($DelayMs)
    $animation.FillBehavior = [System.Windows.Media.Animation.FillBehavior]::HoldEnd
    $frame = New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame($To, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds($DurationMs)), (New-AfKeySpline -Ease $Ease))
    [void]$animation.KeyFrames.Add($frame)
    $Target.BeginAnimation($Property, $animation)
    $animation
}
