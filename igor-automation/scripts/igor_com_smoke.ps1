param(
    [string]$OutputDir = (Join-Path (Get-Location) "outputs"),
    [string]$ShortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Igor Pro\Igor Pro.lnk",
    [switch]$Hidden,
    [switch]$NewExperiment,
    [switch]$QuitIfStartedByScript
)

$ErrorActionPreference = "Stop"

function Resolve-IgorShortcut {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    [pscustomobject]@{
        ShortcutPath     = $Path
        TargetPath       = $shortcut.TargetPath
        Arguments        = $shortcut.Arguments
        WorkingDirectory = $shortcut.WorkingDirectory
    }
}

function Get-IgorApplication {
    try {
        $app = [Runtime.InteropServices.Marshal]::GetActiveObject("IgorPro.Application")
        return [pscustomobject]@{
            Application     = $app
            StartedByScript = $false
            AttachMode      = "attached"
        }
    }
    catch {
        $app = New-Object -ComObject IgorPro.Application
        return [pscustomobject]@{
            Application     = $app
            StartedByScript = $true
            AttachMode      = "started"
        }
    }
}

function Invoke-IgorCommand {
    param(
        [Parameter(Mandatory = $true)]$Application,
        [Parameter(Mandatory = $true)][string]$Command
    )

    try {
        $Application.Execute($Command)
    }
    catch {
        throw "Igor command failed: $Command`n$($_.Exception.Message)"
    }
}

function Convert-PathForIgor {
    param([string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not $full.EndsWith("\")) {
        $full += "\"
    }
    return $full.Replace("\", "\\")
}

function Get-PngInfo {
    param([string]$Path)

    Add-Type -AssemblyName System.Drawing
    $image = [System.Drawing.Image]::FromFile($Path)
    try {
        [pscustomobject]@{
            Path   = $Path
            Width  = $image.Width
            Height = $image.Height
            Bytes  = (Get-Item -LiteralPath $Path).Length
        }
    }
    finally {
        $image.Dispose()
    }
}

$shortcutInfo = Resolve-IgorShortcut -Path $ShortcutPath
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$graphPng = Join-Path $OutputDir "codex_igor_graph.png"
$layoutPng = Join-Path $OutputDir "codex_igor_layout.png"
$experimentPath = Join-Path $OutputDir "codex_igor_smoke_test.pxp"
Remove-Item -LiteralPath $graphPng, $layoutPng, $experimentPath -ErrorAction SilentlyContinue

$connection = Get-IgorApplication
$app = $connection.Application
$app.Visible = -not $Hidden

if ($connection.StartedByScript -or $NewExperiment) {
    $app.NewExperiment(0)
}

$igorOutputDir = Convert-PathForIgor -Path $OutputDir

$commands = @(
    'DoWindow/K CodexSmokeGraph',
    'DoWindow/K CodexSmokeLayout',
    'Make/O/N=401 codexX, codexSin, codexCos',
    'codexX = p*0.02*pi',
    'codexSin = sin(codexX)',
    'codexCos = 0.65*cos(codexX)',
    'Display/N=CodexSmokeGraph/W=(80,80,760,520) codexSin vs codexX',
    'AppendToGraph codexCos vs codexX',
    'ModifyGraph lSize(codexSin)=2,lSize(codexCos)=2',
    'ModifyGraph rgb(codexSin)=(0,21760,52224),rgb(codexCos)=(52224,10752,0)',
    'ModifyGraph mirror=2,nticks=6,standoff=0,grid(left)=1,grid(bottom)=1,gridRGB(left)=(56576,56576,56576),gridRGB(bottom)=(56576,56576,56576)',
    'Legend/C/N=codex_legend/J/F=0/A=RT "\\s(codexSin) sin(x)\r\\s(codexCos) 0.65 cos(x)"',
    'Label left "Signal (a.u.)"',
    'Label bottom "Phase x (rad)"',
    'TextBox/C/N=codex_note/F=0/A=LT/X=2/Y=3 "Codex -> Igor Pro COM"',
    "NewPath/O/Q/C codexOut, `"$igorOutputDir`"",
    'SavePICT/O/E=-5/RES=300/WIN=CodexSmokeGraph/P=codexOut as "codex_igor_graph.png"',
    'NewLayout/N=CodexSmokeLayout/W=(100,100,760,900)',
    'AppendLayoutObject/R=(72,130,540,440) graph CodexSmokeGraph',
    'SetDrawLayer/W=CodexSmokeLayout UserFront',
    'SetDrawEnv/W=CodexSmokeLayout fname="Arial", fsize=16, textrgb=(0,0,0)',
    'DrawText/W=CodexSmokeLayout 72,78,"Codex Igor layout test"',
    'SetDrawEnv/W=CodexSmokeLayout fname="Arial", fsize=10, textrgb=(26000,26000,26000)',
    'DrawText/W=CodexSmokeLayout 72,103,"Graph object placed on a page layout and exported by SavePICT"',
    'DrawText/W=CodexSmokeLayout 72,690,"Generated from PowerShell via IgorPro.Application COM"',
    'SavePICT/O/E=-5/RES=300/WIN=CodexSmokeLayout/P=codexOut as "codex_igor_layout.png"',
    'SaveExperiment /P=codexOut as "codex_igor_smoke_test.pxp"'
)

foreach ($command in $commands) {
    Invoke-IgorCommand -Application $app -Command $command
}

$graphInfo = Get-PngInfo -Path $graphPng
$layoutInfo = Get-PngInfo -Path $layoutPng
$experimentInfo = Get-Item -LiteralPath $experimentPath

if ($QuitIfStartedByScript -and $connection.StartedByScript) {
    $app.Quit()
}

[pscustomobject]@{
    Status          = "ok"
    AttachMode      = $connection.AttachMode
    ShortcutTarget  = if ($shortcutInfo) { $shortcutInfo.TargetPath } else { $null }
    GraphPng        = $graphInfo
    LayoutPng       = $layoutInfo
    ExperimentPath  = $experimentInfo.FullName
    ExperimentBytes = $experimentInfo.Length
}
