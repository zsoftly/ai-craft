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

        # Create .clignore to prevent Claude from scanning unwanted files
        $clignorePath = Join-Path $CLAUDE_DIR ".clignore"
        $clignoreContent = @"
# Ignore backup files
*.backup.*

# Ignore non-agent files (keep only .md agents)
*.json
*.yaml
*.yml
*.txt
*.log
.DS_Store
"@
        Set-Content -Path $clignorePath -Value $clignoreContent

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

    # Create aicraft-agents directory
    $aicraftAgentsDir = Join-Path $GEMINI_DIR "aicraft-agents"
    New-Item -ItemType Directory -Force -Path $aicraftAgentsDir | Out-Null

    # Always copy/overwrite individual agent files (we control these)
    Write-Color "   [Copying agent files to $aicraftAgentsDir...]" "Blue"
    Get-ChildItem "agents\*.md" | Where-Object {
        $_.Name -ne "GLOSSARY.md" -and $_.Name -ne "README.md"
    } | Copy-Item -Destination $aicraftAgentsDir -Force
    Write-Color "   [OK] Agent files copied to: $aicraftAgentsDir" "Green"

    # Smart GEMINI.md update: preserve user content, only manage our section
    Write-Color "   [Updating GEMINI.md...]" "Blue"
    $geminiMdPath = Join-Path $GEMINI_DIR "GEMINI.md"

    # Build our managed content section
    $managedContent = @"
<!-- AI-CRAFT-AGENTS-START - Do not edit between these markers, content will be updated automatically -->

# AI Craft Agents for Gemini

You have access to structured workflow agents that provide guidance for different development tasks. These agents define best practices, workflows, and patterns for software development.

When the user asks for help with development tasks, apply the relevant agent's guidance to structure your response.

Individual agent files are stored in: ~/.gemini/aicraft-agents/

## Available Agents

"@

    # Append agent summaries (exclude GLOSSARY and README)
    foreach ($agent in (Get-ChildItem "agents\*.md" | Where-Object {
        $_.Name -ne "GLOSSARY.md" -and $_.Name -ne "README.md"
    })) {
        $agentName = $agent.BaseName
        $managedContent += "`n### Agent: $agentName`n`n"

        # Extract key sections: Brief description, Purpose, and When to Use
        try {
            $agentContent = Get-Content $agent.FullName

            # Get lines 3-4 (brief description after title and blank line)
            $briefDesc = ($agentContent[2..3] | Out-String).Trim()

            # Extract Purpose section
            $purposeLines = @()
            $inPurpose = $false
            foreach ($line in $agentContent) {
                if ($line -match "^## Purpose$") {
                    $inPurpose = $true
                    continue
                }
                if ($inPurpose -and $line -match "^## (?!Purpose)") {
                    break
                }
                if ($inPurpose) {
                    $purposeLines += $line
                }
            }
            $purpose = ($purposeLines | Out-String).Trim()

            # Extract When to Use section
            $whenLines = @()
            $inWhen = $false
            foreach ($line in $agentContent) {
                if ($line -match "^## When to Use$") {
                    $inWhen = $true
                    continue
                }
                if ($inWhen -and $line -match "^## (?!When to Use)") {
                    break
                }
                if ($inWhen) {
                    $whenLines += $line
                }
            }
            $whenToUse = ($whenLines | Out-String).Trim()

            # Combine sections
            $agentSummary = "$briefDesc`n`n## Purpose`n$purpose`n`n## When to Use`n$whenToUse"

            # Fallback if extraction fails
            if ($agentSummary.Length -lt 20) {
                $agentSummary = "Agent documentation - see $agentName.md for details"
            }

            # Strip inline @ references to prevent Gemini CLI import errors
            $agentSummary = $agentSummary -replace '@[a-z-]+', ''

            $managedContent += "$agentSummary`n`n"
        }
        catch {
            $managedContent += "Agent documentation`n`n"
        }
    }

    $managedContent += "<!-- AI-CRAFT-AGENTS-END -->"

    # Check if GEMINI.md exists and has our markers
    if (Test-Path $geminiMdPath) {
        $existingContent = Get-Content $geminiMdPath -Raw -ErrorAction SilentlyContinue

        if ($existingContent -match "<!-- AI-CRAFT-AGENTS-START") {
            # Markers exist - replace content between markers, preserve user content
            Write-Color "   [Updating AI Craft section in existing GEMINI.md...]" "Blue"

            # Create backup
            $backupPath = "$geminiMdPath.backup.$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
            Copy-Item $geminiMdPath $backupPath
            Write-Color "   [BACKUP] Created: $backupPath" "Blue"

            # Extract content before markers
            $beforeContent = ($existingContent -split '<!-- AI-CRAFT-AGENTS-START')[0]

            # Extract content after markers (if exists)
            $afterMatch = $existingContent -match '<!-- AI-CRAFT-AGENTS-END -->([\s\S]*?)$'
            $afterContent = if ($afterMatch) { $Matches[1] } else { "" }

            # Combine: user content before + our managed content + user content after
            $newContent = $beforeContent + $managedContent + $afterContent
            Set-Content -Path $geminiMdPath -Value $newContent

            Write-Color "   [OK] Updated AI Craft section, preserved user content" "Green"
        }
        else {
            # No markers - append our section to preserve existing user content
            Write-Color "   [Appending AI Craft section to existing GEMINI.md...]" "Blue"

            # Create backup
            $backupPath = "$geminiMdPath.backup.$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
            Copy-Item $geminiMdPath $backupPath
            Write-Color "   [BACKUP] Created: $backupPath" "Blue"

            # Append our managed section
            $newContent = $existingContent + "`n`n" + $managedContent
            Set-Content -Path $geminiMdPath -Value $newContent

            Write-Color "   [OK] Appended AI Craft section, preserved existing content" "Green"
        }
    }
    else {
        # No GEMINI.md - create new file with just our content
        Write-Color "   [Creating new GEMINI.md...]" "Blue"
        Set-Content -Path $geminiMdPath -Value $managedContent
        Write-Color "   [OK] Created new GEMINI.md" "Green"
    }

    Write-Color "   [OK] Gemini CLI installation complete" "Green"
}

# Install for OpenAI Codex CLI
if ($CODEX_INSTALLED) {
    Write-Color "[Installing for OpenAI Codex CLI...]" "Blue"

    $CODEX_AGENTS_DIR = Join-Path $CODEX_DIR "agents"

    # Create backup if directory already exists
    if ((Test-Path $CODEX_AGENTS_DIR) -and ((Get-ChildItem $CODEX_AGENTS_DIR -ErrorAction SilentlyContinue).Count -gt 0)) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $BACKUP_DIR = "$CODEX_AGENTS_DIR.backup.$timestamp"
        New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null
        try {
            Copy-Item -Path "$CODEX_AGENTS_DIR\*" -Destination $BACKUP_DIR -Force
            Write-Color "   [BACKUP] Previous installation backed up to: $BACKUP_DIR" "Blue"
        }
        catch {
            Write-Color "   [WARN] Backup failed, but continuing installation" "Yellow"
        }
    }

    New-Item -ItemType Directory -Force -Path $CODEX_AGENTS_DIR | Out-Null

    try {
        # Copy only actual agents (exclude GLOSSARY and README - they're just docs)
        Get-ChildItem "agents\*.md" | Where-Object {
            $_.Name -ne "GLOSSARY.md" -and $_.Name -ne "README.md"
        } | Copy-Item -Destination $CODEX_AGENTS_DIR -Force

        # Create .codexignore to prevent Codex from scanning unwanted files (saves API credits)
        $codexignorePath = Join-Path $CODEX_AGENTS_DIR ".codexignore"
        $codexignoreContent = @"
# Ignore backup files
*.backup.*

# Ignore non-agent files (keep only .md agents)
*.json
*.yaml
*.yml
*.txt
*.log
.DS_Store

# Common directories to exclude
node_modules/
dist/
build/
.git/
"@
        Set-Content -Path $codexignorePath -Value $codexignoreContent

        Write-Color "   [OK] Installed to: $CODEX_AGENTS_DIR" "Green"
    }
    catch {
        Write-Color "   [ERROR] Failed to copy files to $CODEX_AGENTS_DIR" "Red"
        Write-Host $_.Exception.Message
        exit 1
    }
}

Write-Host ""
Write-Color "[OK] Installation complete!" "Green"
Write-Host ""

# Summary
Write-Color "[Installed agents for:]" "Cyan"
if ($CLAUDE_INSTALLED) { Write-Host "   - Claude Code: $CLAUDE_DIR" }
if ($GEMINI_INSTALLED) { Write-Host "   - Gemini CLI: $GEMINI_DIR\GEMINI.md" }
if ($CODEX_INSTALLED) { Write-Host "   - OpenAI Codex: $CODEX_DIR\agents" }

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
    Write-Host "    @dev-agent Phase 1: Analyze my code"
    Write-Host "    @tdd-agent Implement with test-driven approach"
}

Write-Host ""
Write-Color "Happy coding!" "Green"
