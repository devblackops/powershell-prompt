$mods = @(
    'NameIT'
    'posh-git'
    'Terminal-Icons'
)
Import-Module $mods

Set-PSReadLineOption -EditMode Emacs -ShowToolTips
Set-PSReadLineOption -PredictionSource History -Colors @{ Selection = "`e[92;7m"; InLinePrediction = "`e[36;7;238m" }
Set-PSReadLineKeyHandler -Chord Shift+Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord Ctrl+b -Function BackwardWord
Set-PSReadLineKeyHandler -Chord Ctrl+f -Function ForwardWord

if ($IsMacOS) {
    try {
        Import-UnixCompleters
    } catch {
        Install-Module Microsoft.PowerShell.UnixCompletes -Repository PSGallery -AcceptLicense -Force
        Import-UnixCompleters
    }
}

$script:commonDirs = @{
    home     = $HOME
    docs     = [IO.Path]::Combine($HOME, 'OneDrive', 'Documents')
    github   = [IO.Path]::Combine($HOME, 'OneDrive', 'Documents', 'GitHub')
    onedrive = [IO.Path]::Combine($HOME, 'OneDrive')
}
$script:color = @{
    reset  = "`e[0m"
    red    = "`e[31;1m"
    green  = "`e[32;1m"
    yellow = "`e[33;1m"
    blue   = "`e[34;1m"
    grey   = "`e[37m"
    lightblue = "`e[38;2;102;178;255m"
    orange = "`e[38;2;255;144;30m"
}
$script:glyphs = @{
    home          = "$($color.blue)`u{f7db}$($color.reset)"
    docs          = "$($color.Blue)`u{f491}$($color.reset)"
    heart         = "$($color.Red)`u{2764}$($color.reset)"
    stackoverflow = "$($color.orange)`u{e710}$($color.reset)"
    git           = "$($color.blue)`u{e0a0}$($color.reset)"
    github        = "$($color.lightblue)`u{f408}$($color.reset)"
    onedrive      = "$($color.blue)`u{f8c9}$($color.reset)"
    rightArrow    = "$($color.blue)`u{25ba}$($color.reset)"
    ellipsis      = "$($color.reset)`u{2026}$($color.reset)"
    normal        = "$($color.green)`u{2714}$($color.reset)"
    error         = "$($color.red)`u{f00d}$($color.reset)"
    warning       = "$($color.yellow)`u{f071}$($color.reset)"
    fowardSlash   = " $($color.orange)`u{e216}$($color.reset) "
}

$global:GitPromptSettings.BeforeStatus = $color.blue + $glyphs.git + "`e[93m[`e[39m"

function prompt {
    # Modifed from @SteveL-MSFT
    # https://gist.github.com/SteveL-MSFT/a208d2bd924691bae7ec7904cab0bd8e

    # Determine last command status
    $lastExit = $? ? "[$($glyphs.normal)]" : "[$($glyphs.error)]"
    $lastCmd = Get-History -Count 1
    if ($null -ne $lastCmd) {
        $cmdTime = $lastCmd.Duration.TotalMilliseconds
        $units = "ms"
        $timeColor = $color.green
        if ($cmdTime -gt 250 -and $cmdTime -lt 1000) {
            $timeColor = $color.yellow
        } elseif ($cmdTime -ge 1000) {
            $timeColor = $color.red
            $units = "s"
            $cmdTime = $lastCmd.Duration.TotalSeconds
            if ($cmdTime -ge 60) {
                $units = "m"
                $cmdTIme = $lastCmd.Duration.TotalMinutes
            }
        }
        $lastCmdTime = "$($color.grey)[$timeColor$($cmdTime.ToString('#.##'))$units$($color.grey)]$($color.reset)"
    }

    # Display the common folder glyph instead of the path
    $dispDir = $executionContext.SessionState.Path.CurrentLocation.Path
    $commonDirGlyph = ''
    switch ($dispDir) {
        {$_.Contains($commonDirs.github)} {
            $commonDirGlyph = $glyphs.github
            $dispDir = $dispDir.Replace($commonDirs.github, '')
            break
        }
        {$_.Contains($commonDirs.docs)} {
            $commonDirGlyph = $glyphs.docs
            $dispDir = $dispDir.Replace($commonDirs.docs, '')
            break
        }
        {$_.Contains($commonDirs.onedrive)} {
            $commonDirGlyph = $glyphs.onedrive
            $dispDir = $dispDir.Replace($commonDirs.onedrive, '')
            break
        }
        {$_.Contains($commonDirs.home)} {
            $commonDirGlyph = $glyphs.home
            $dispDir = $dispDir.Replace($commonDirs.home, '')
            break
        }
    }

    # Truncate path if too long and just show the last part of it
    $maxPathLength = 48
    if ($dispDir.Length -gt $maxPathLength) {
        $pathParts = ($dispDir -split '/') | Where-Object {-not [string]::IsNullOrEmpty($_)} | ForEach-Object {
            @{
                name   = $_
                length = $_.Length
            }
        }
        $pathLength    = 0
        $dirsShown     = 0
        $truncatedPath = ''
        for($i = -1; $i -ge ($pathParts.Count * -1); $i--) {
            if ($pathLength -le $maxPathLength -and $dirsShown -le 2) {
                $truncatedPath = $pathParts[$i].name + '/' + $truncatedPath
                $pathLength   += $pathParts[$i].length
                $dirsShown++
            } else {
                break
            }
        }
        $dispDir = $commonDirGlyph + '/' + $glyphs.ellipsis + '/' + $truncatedPath
    } else {
        $dispDir = $commonDirGlyph + $dispDir
    }

    # Pretty slashes
    $dispDir = $dispDir.Replace('/', $glyphs.fowardSlash)
    $dispDir = $dispDir.Replace('\', $glyphs.fowardSlash)

    $glyphs.stackoverflow + ' ' + $dispDir + $(Write-VcsStatus) + " $lastExit $lastCmdTime" + [Environment]::NewLine + "I $($glyphs.heart) PS $($glyphs.rightArrow) "
}

# Windows title
$HOST.UI.RawUI.WindowTitle = Invoke-Generate -Template '[adjective] [noun]'