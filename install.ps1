# GudaCC Skills Installer for Windows
# https://github.com/GuDaStudio/skills

param(
    [Alias("u")][switch]$User,
    [Alias("p")][switch]$Project,
    [Alias("t")][string]$Target,
    [Alias("a")][switch]$All,
    [Alias("s")][string[]]$Skill,
    [Alias("l")][switch]$List,
    [Alias("h")][switch]$Help
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AvailableSkills = @("collaborating-with-codex", "collaborating-with-gemini")

function Write-ColorOutput {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Show-Usage {
    Write-ColorOutput "GudaCC Skills Installer" "Blue"
    Write-Host ""
    Write-Host "Usage: .\install.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -User, -u              Install to user-level (~\.claude\skills\)"
    Write-Host "  -Project, -p           Install to project-level (.\.claude\skills\)"
    Write-Host "  -Target, -t <path>     Install to custom target path"
    Write-Host "  -All, -a               Install all available skills"
    Write-Host "  -Skill, -s <name>      Install specific skill (can be used multiple times)"
    Write-Host "  -List, -l              List available skills"
    Write-Host "  -Help, -h              Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1 -User -All"
    Write-Host "  .\install.ps1 -Project -All"
    Write-Host "  .\install.ps1 -User -Skill collaborating-with-codex"
    Write-Host "  .\install.ps1 -User -Skill collaborating-with-codex -Skill collaborating-with-gemini"
    Write-Host "  .\install.ps1 -Target C:\custom\path -All"
    Write-Host ""
    Write-Host "Available skills:"
    foreach ($s in $AvailableSkills) {
        Write-Host "  - $s"
    }
}

function Show-SkillList {
    Write-ColorOutput "Available Skills:" "Blue"
    Write-Host ""
    foreach ($s in $AvailableSkills) {
        $sourcePath = Join-Path $ScriptDir $s
        if (Test-Path $sourcePath -PathType Container) {
            Write-Host "  " -NoNewline
            Write-ColorOutput "✓" "Green" -NoNewline
            Write-Host " $s"
        } else {
            Write-Host "  " -NoNewline
            Write-ColorOutput "✗" "Red" -NoNewline
            Write-Host " $s (not found in source)"
        }
    }
}

function Write-ColorOutput {
    param(
        [string]$Text,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Install-Skill {
    param([string]$SkillName, [string]$TargetDir)

    $sourceDir = Join-Path $ScriptDir $SkillName
    $destDir = Join-Path $TargetDir $SkillName

    if (-not (Test-Path $sourceDir -PathType Container)) {
        Write-ColorOutput "Error: Skill '$SkillName' not found in source directory" "Red"
        return $false
    }

    Write-Host "Installing " -NoNewline
    Write-ColorOutput "$SkillName" "Cyan" -NoNewline
    Write-Host " -> $destDir"

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    if (Test-Path $destDir) {
        Write-ColorOutput "  Removing existing installation..." "Yellow"
        Remove-Item -Path $destDir -Recurse -Force
    }

    Copy-Item -Path $sourceDir -Destination $destDir -Recurse

    $gitFile = Join-Path $destDir ".git"
    if (Test-Path $gitFile -PathType Leaf) {
        Remove-Item -Path $gitFile -Force
    }

    Write-ColorOutput "  ✓ Installed" "Green"
    return $true
}

if ($Help) {
    Show-Usage
    exit 0
}

if ($List) {
    Show-SkillList
    exit 0
}

$TargetPath = ""
if ($User) {
    $TargetPath = Join-Path $env:USERPROFILE ".claude\skills"
} elseif ($Project) {
    $TargetPath = ".\.claude\skills"
} elseif ($Target) {
    $TargetPath = $Target
}

if (-not $TargetPath) {
    Write-ColorOutput "Error: Please specify installation target (-User, -Project, or -Target)" "Red"
    Write-Host ""
    Show-Usage
    exit 1
}

if (-not $All -and (-not $Skill -or $Skill.Count -eq 0)) {
    Write-ColorOutput "Error: Please specify skills to install (-All or -Skill)" "Red"
    Write-Host ""
    Show-Usage
    exit 1
}

$SkillsToInstall = @()
if ($All) {
    $SkillsToInstall = $AvailableSkills
} else {
    $SkillsToInstall = $Skill
}

foreach ($s in $SkillsToInstall) {
    if ($s -notin $AvailableSkills) {
        Write-ColorOutput "Error: Unknown skill '$s'" "Red"
        Write-Host "Available skills: $($AvailableSkills -join ', ')"
        exit 1
    }
}

Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Blue"
Write-ColorOutput "GudaCC Skills Installer" "Blue"
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Blue"
Write-Host ""
Write-Host "Target: " -NoNewline
Write-ColorOutput $TargetPath "Green"
Write-Host "Skills: " -NoNewline
Write-ColorOutput ($SkillsToInstall -join ", ") "Green"
Write-Host ""

foreach ($s in $SkillsToInstall) {
    Install-Skill -SkillName $s -TargetDir $TargetPath
}

Write-Host ""
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"
Write-ColorOutput "Installation complete!" "Green"
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"
