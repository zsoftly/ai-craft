# AI Craft Agents Installation Script for Windows
# Installs agents to appropriate locations for Claude, Gemini, and OpenAI CLIs

# Exit on error
$ErrorActionPreference = "Stop"

# Color helper function
function Write-Color {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-Color "`nInstalling AI Craft Agents...`n" "Cyan"

# Check if agents directory exists
if (-not (Test-Path "agents")) {
    Write-Color "ERROR: agents/ directory not found!" "Red"
    Write-Host "Please run this script from the ai-craft root directory."
    exit 1
}

# Check if agent files exist
$agentFiles = Get-ChildItem "agents\*.md" -ErrorAction SilentlyContinue
if (-not $agentFiles) {
    Write-Color "ERROR: No .md files found in agents/ directory!" "Red"
    exit 1
}

# Installation paths for different AI CLIs
$HOME_DIR = $env:USERPROFILE
$CLAUDE_DIR = Join-Path $HOME_DIR ".claude\agents"
$GEMINI_DIR = Join-Path $HOME_DIR ".gemini"
$CODEX_DIR = Join-Path $HOME_DIR ".codex"

# Detect which CLIs are available
$CLAUDE_INSTALLED = $false
$GEMINI_INSTALLED = $false
$CODEX_INSTALLED = $false

# Check for Claude Code
if ((Get-Command claude -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME_DIR ".claude"))) {
    $CLAUDE_INSTALLED = $true
}

# Check for Gemini CLI
if ((Get-Command gemini -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME_DIR ".gemini"))) {
    $GEMINI_INSTALLED = $true
}

# Check for OpenAI Codex CLI
if ((Get-Command codex -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME_DIR ".codex"))) {
    $CODEX_INSTALLED = $true
}

# Install for Claude Code
if ($CLAUDE_INSTALLED) {
    Write-Color "[Installing for Claude Code...]" "Blue"
    New-Item -ItemType Directory -Force -Path $CLAUDE_DIR | Out-Null

    try {
        # Copy only actual agents (exclude GLOSSARY and README - they're in docs/ now)
        Get-ChildItem "agents\*.md" | Where-Object {
            $_.Name -ne "GLOSSARY.md" -and $_.Name -ne "README.md"
        } | Copy-Item -Destination $CLAUDE_DIR -Force

        Write-Color "   [OK] Installed to: $CLAUDE_DIR" "Green"
    }
    catch {
        Write-Color "   [ERROR] Failed to copy files to $CLAUDE_DIR" "Red"
        Write-Host $_.Exception.Message
        exit 1
    }
}

# Install for Gemini CLI
if ($GEMINI_INSTALLED) {
    Write-Color "[Installing for Gemini CLI...]" "Blue"
    New-Item -ItemType Directory -Force -Path $GEMINI_DIR | Out-Null

    # Create GEMINI.md with agent instructions (automatically loaded, no env var needed)
    $geminiMdPath = Join-Path $GEMINI_DIR "GEMINI.md"
    $geminiMdContent = @"
# AI Craft Agents for Gemini

You have access to structured workflow agents. When the user references an agent with @, provide guidance based on these workflows:

## Available Agents

"@

    Set-Content -Path $geminiMdPath -Value $geminiMdContent

    # Append agent summaries (exclude GLOSSARY and README - they're in docs/ now)
    foreach ($agent in (Get-ChildItem "agents\*.md" | Where-Object {
        $_.Name -ne "GLOSSARY.md" -and $_.Name -ne "README.md"
    })) {
        $agentName = $agent.BaseName
        # Use "Agent:" prefix instead of "@" to avoid Gemini CLI import errors
        Add-Content -Path $geminiMdPath -Value "`n### Agent: $agentName"

        # Extract agent summary (match bash: grep -A 5 = matching line + 5 after, max 10 total)
        try {
            $agentContent = Get-Content $agent.FullName -Head 20
            $totalLines = 0
            $maxTotalLines = 10
            $foundAnyHeader = $false

            for ($i = 0; $i -lt $agentContent.Count -and $totalLines -lt $maxTotalLines; $i++) {
                if ($agentContent[$i] -match "^##") {
                    $foundAnyHeader = $true
                    # Output matching line + next 5 lines (6 lines per match, like grep -A 5)
                    $linesToOutput = [Math]::Min(6, $maxTotalLines - $totalLines)
                    $endIndex = [Math]::Min($i + $linesToOutput, $agentContent.Count)

                    for ($j = $i; $j -lt $endIndex -and $totalLines -lt $maxTotalLines; $j++) {
                        Add-Content -Path $geminiMdPath -Value $agentContent[$j]
                        $totalLines++
                    }

                    # Skip past the lines we just output
                    $i = $endIndex - 1
                }
            }

            if (-not $foundAnyHeader) {
                Add-Content -Path $geminiMdPath -Value "Agent documentation"
            }

            # Strip inline @ references to prevent Gemini CLI import errors
            # Gemini CLI treats any @word as an import directive
            $content = Get-Content -Path $geminiMdPath -Raw
            $content = $content -replace '@[a-z-]+', ''
            Set-Content -Path $geminiMdPath -Value $content
        }
        catch {
            Add-Content -Path $geminiMdPath -Value "Agent documentation"
        }
        Add-Content -Path $geminiMdPath -Value ""
    }

    # Note: We don't copy individual agent files because they contain inline @ references
    # that Gemini CLI interprets as import directives, causing errors.
    # GEMINI.md already contains cleaned summaries of all agents.
    Write-Color "   [OK] Installed to: $GEMINI_DIR\GEMINI.md" "Green"
}

# Install for OpenAI Codex CLI
if ($CODEX_INSTALLED) {
    Write-Color "[Installing for OpenAI Codex CLI...]" "Blue"
    New-Item -ItemType Directory -Force -Path $CODEX_DIR | Out-Null

    # Create instructions.md with agent guidance
    $instructionsMdPath = Join-Path $CODEX_DIR "instructions.md"
    $instructionsMdContent = @"
# AI Craft Development Agents

Follow these structured workflows when developing:

"@

    Set-Content -Path $instructionsMdPath -Value $instructionsMdContent

    # Append agent content
    $agentCount = 0
    $agentPaths = @("agents\dev-agent.md", "agents\tdd-agent.md", "agents\code-review-agent.md")

    foreach ($agentPath in $agentPaths) {
        if (Test-Path $agentPath) {
            try {
                $agentContent = Get-Content $agentPath -Raw
                Add-Content -Path $instructionsMdPath -Value $agentContent
                Add-Content -Path $instructionsMdPath -Value "`n---`n"
                $agentCount++
            }
            catch {
                # Continue to next agent
            }
        }
    }

    if ($agentCount -gt 0) {
        Write-Color "   [OK] Installed to: $CODEX_DIR\instructions.md" "Green"
    }
    else {
        Write-Color "   [WARN] No agent files found for Codex" "Yellow"
    }
}

Write-Host ""
Write-Color "[OK] Installation complete!" "Green"
Write-Host ""

# Summary
Write-Color "[Installed agents for:]" "Cyan"
if ($CLAUDE_INSTALLED) { Write-Host "   - Claude Code: $CLAUDE_DIR" }
if ($GEMINI_INSTALLED) { Write-Host "   - Gemini CLI: $GEMINI_DIR\GEMINI.md" }
if ($CODEX_INSTALLED) { Write-Host "   - OpenAI Codex: $CODEX_DIR\instructions.md" }

if (-not $CLAUDE_INSTALLED -and -not $GEMINI_INSTALLED -and -not $CODEX_INSTALLED) {
    Write-Color "   [WARN] No AI CLIs detected" "Yellow"
    $fallbackPath = Join-Path $HOME_DIR ".aicraft\agents"
    Write-Host "   Installing to fallback location: $fallbackPath"
    New-Item -ItemType Directory -Force -Path $fallbackPath | Out-Null

    try {
        # Copy only actual agents (exclude GLOSSARY and README - they're in docs/ now)
        Get-ChildItem "agents\*.md" | Where-Object {
            $_.Name -ne "GLOSSARY.md" -and $_.Name -ne "README.md"
        } | Copy-Item -Destination $fallbackPath -Force

        Write-Color "   [OK] Installed to fallback location" "Green"
    }
    catch {
        Write-Color "   [ERROR] Failed to copy files to fallback location" "Red"
        Write-Host $_.Exception.Message
        exit 1
    }
}

Write-Host ""
Write-Color "[USAGE]" "Cyan"

if ($CLAUDE_INSTALLED) {
    Write-Host ""
    Write-Color "  Claude Code:" "Blue"
    Write-Host "    @dev-agent Phase 1: Analyze my code"
    Write-Host "    @gemini-dev Ask Gemini to check performance"
}

if ($GEMINI_INSTALLED) {
    Write-Host ""
    Write-Color "  Gemini CLI:" "Blue"
    Write-Host "    Agents automatically loaded from $env:USERPROFILE\.gemini\GEMINI.md"
    Write-Host "    No configuration needed - just use Gemini CLI as normal"
}

if ($CODEX_INSTALLED) {
    Write-Host ""
    Write-Color "  OpenAI Codex:" "Blue"
    Write-Host "    Instructions loaded automatically"
    Write-Host "    Agents guide all code generation"
}

Write-Host ""
Write-Color "Happy coding!" "Green"
