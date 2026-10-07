# AI Craft Agents Installation Script for Windows
# Installs agents to appropriate locations for Claude, Gemini, and OpenAI CLIs

<#
.SYNOPSIS
    Installs AI Craft agents and skills for Claude Code, Gemini CLI, and OpenAI Codex.
.PARAMETER SkipClaude
    Do not install into ~/.claude. Use when you installed the ai-craft plugin
    instead, to avoid two copies of each agent. Files from 1.0.0 are still
    retired so they stop registering.
.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -SkipClaude
#>
param(
    [switch]$SkipClaude
)

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

# Return one top level field from a markdown file's YAML frontmatter, or ""
function Get-FrontmatterField {
    param(
        [string]$Path,
        [string]$Key
    )
    $lines = @(Get-Content $Path)
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne "---") { return "" }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "---") { break }
        $idx = $lines[$i].IndexOf(":")
        if ($idx -gt 0 -and $lines[$i].Substring(0, $idx) -eq $Key) {
            return $lines[$i].Substring($idx + 1).Trim()
        }
    }
    return ""
}

# Return a markdown file's body with any YAML frontmatter removed
function Get-BodyWithoutFrontmatter {
    param([string]$Path)
    $lines = @(Get-Content $Path)
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne "---") {
        return (Get-Content $Path -Raw)
    }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "---") {
            if (($i + 1) -ge $lines.Count) { return "" }
            return (($lines[($i + 1)..($lines.Count - 1)]) -join "`n")
        }
    }
    return (Get-Content $Path -Raw)
}

# Filenames this repository shipped in 1.0.0, before the zs- prefix.
# Only these eleven, and only in the two directories the 1.0.0 installer wrote to.
# Anything else under those paths belongs to the user and is left alone.
$LEGACY_AGENT_FILES = @(
    "code-review-agent.md", "content-review-agent.md", "dev-agent.md", "dig.md",
    "gemini-data.md", "gemini-dev.md", "git-workflow-agent.md",
    "inter-ai-communication.md", "sniff.md", "tdd-agent.md", "wag.md"
)

# Move pre zs- files out of an install directory into a sibling folder.
# A sibling, not a subdirectory, because Claude Code scans ~/.claude/agents
# recursively and would otherwise keep registering what we just retired.
function Move-Legacy {
    param(
        [string]$TargetDir,
        [string[]]$ExtraFiles = @()
    )
    if (-not (Test-Path $TargetDir)) { return }

    # A 1.0.0 file carries no frontmatter. If one of these names does have
    # frontmatter it belongs to the user, so leave it where it is.
    $isLegacy = {
        param([string]$Path)
        if (-not (Test-Path $Path)) { return $false }
        $first = @(Get-Content $Path -TotalCount 1)
        if ($first.Count -eq 0) { return $false }
        return ($first[0].Trim() -ne "---")
    }

    $found = $false
    foreach ($legacy in ($LEGACY_AGENT_FILES + $ExtraFiles)) {
        if (& $isLegacy (Join-Path $TargetDir $legacy)) { $found = $true }
    }
    if (-not $found) { return }

    $legacyDir = "$TargetDir.aicraft-legacy.$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
    New-Item -ItemType Directory -Force -Path $legacyDir | Out-Null
    foreach ($legacy in ($LEGACY_AGENT_FILES + $ExtraFiles)) {
        $path = Join-Path $TargetDir $legacy
        if (& $isLegacy $path) {
            try {
                Move-Item -Path $path -Destination $legacyDir -Force
            }
            catch {
                Write-Color "   [WARN] Could not retire $path" "Yellow"
            }
        }
    }
    Write-Color "   [MIGRATION] 1.0.0 files moved to: $legacyDir" "Blue"
}

# Write a copy carrying only name and description, for CLIs that reject
# frontmatter keys they do not know
function Write-Portable {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$FallbackName
    )
    $pName = Get-FrontmatterField -Path $Source -Key "name"
    $pDesc = Get-FrontmatterField -Path $Source -Key "description"
    if ([string]::IsNullOrWhiteSpace($pName)) { $pName = $FallbackName }
    if ([string]::IsNullOrWhiteSpace($pDesc)) { $pDesc = "AI Craft workflow" }
    $body = Get-BodyWithoutFrontmatter -Path $Source
    $out = "---`nname: $pName`ndescription: $pDesc`n---`n`n$body"
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Destination, $out, $utf8NoBom)
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

# Verify agent files carry frontmatter, otherwise no CLI registers them
Write-Color "[Verifying agent files...]" "Blue"
$invalidFiles = 0
foreach ($agent in (Get-ChildItem "agents\*.md" | Where-Object {
    $_.Name -ne "GLOSSARY.md" -and $_.Name -ne "README.md"
})) {
    if ((Get-FrontmatterField -Path $agent.FullName -Key "name") -eq "" -or
        (Get-FrontmatterField -Path $agent.FullName -Key "description") -eq "") {
        Write-Color "   [WARN] Frontmatter missing name or description: $($agent.Name)" "Yellow"
        $invalidFiles++
    }
}
if ($invalidFiles -gt 0) {
    Write-Color "   [WARN] Found $invalidFiles suspicious file(s) - continuing anyway" "Yellow"
}
else {
    Write-Color "   [OK] All agent files verified" "Green"
}
Write-Host ""

# Installation paths for different AI CLIs
$HOME_DIR = $env:USERPROFILE
$CLAUDE_DIR = Join-Path $HOME_DIR ".claude\agents"
$CLAUDE_SKILLS_DIR = Join-Path $HOME_DIR ".claude\skills"
$GEMINI_DIR = Join-Path $HOME_DIR ".gemini"
$GEMINI_AGENTS_DIR = Join-Path $HOME_DIR ".gemini\agents"
$CODEX_DIR = Join-Path $HOME_DIR ".codex"
$CODEX_AGENTS_DIR = Join-Path $HOME_DIR ".codex\agents"
$SHARED_SKILLS_DIR = Join-Path $HOME_DIR ".agents\skills"

# Detect which CLIs are available
$CLAUDE_INSTALLED = $false
$GEMINI_INSTALLED = $false
$CODEX_INSTALLED = $false

# Check for Claude Code
if ((Get-Command claude -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME_DIR ".claude"))) {
    $CLAUDE_INSTALLED = $true
}

# Keep the real detection result. The fallback install at the end must not fire
# just because the user asked us to skip the Claude half.
$CLAUDE_DETECTED = $CLAUDE_INSTALLED
if ($SkipClaude) {
    $CLAUDE_INSTALLED = $false
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
    Move-Legacy -TargetDir $CLAUDE_DIR

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

        # Install invocable skills, including /zs-orchestrate and /zs-ticket-updates.
        if (Test-Path "skills") {
            New-Item -ItemType Directory -Force -Path $CLAUDE_SKILLS_DIR | Out-Null
            foreach ($skill in (Get-ChildItem "skills" -Directory)) {
                if (-not (Test-Path (Join-Path $skill.FullName "SKILL.md"))) {
                    Write-Color "   [WARN] Skipping $($skill.Name), no SKILL.md" "Yellow"
                    continue
                }
                $target = Join-Path $CLAUDE_SKILLS_DIR $skill.Name
                if (Test-Path $target) { Remove-Item -Path $target -Recurse -Force }
                Copy-Item -Path $skill.FullName -Destination $target -Recurse -Force
            }
            Write-Color "   [OK] Skills installed to: $CLAUDE_SKILLS_DIR" "Green"
        }
    }
    catch {
        Write-Color "   [ERROR] Failed to copy files to $CLAUDE_DIR" "Red"
        Write-Host $_.Exception.Message
        exit 1
    }
}

# -SkipClaude means do not install into ~/.claude. It does not mean leave a
# directory of 1.0.0 agents registered, which is the state the flag's own user
# is trying to get out of.
if ($SkipClaude -and $CLAUDE_DETECTED) {
    Write-Color "[Retiring 1.0.0 files in $CLAUDE_DIR, skipping the install itself...]" "Blue"
    Move-Legacy -TargetDir $CLAUDE_DIR
}

# Install for Gemini CLI
if ($GEMINI_INSTALLED) {
    Write-Color "[Installing for Gemini CLI...]" "Blue"
    New-Item -ItemType Directory -Force -Path $GEMINI_DIR | Out-Null

    # Create aicraft-agents directory
    $aicraftAgentsDir = Join-Path $GEMINI_DIR "aicraft-agents"
    New-Item -ItemType Directory -Force -Path $aicraftAgentsDir | Out-Null
    Move-Legacy -TargetDir $aicraftAgentsDir

    # Always copy/overwrite individual agent files (we control these)
    Write-Color "   [Copying agent files to $aicraftAgentsDir...]" "Blue"
    Get-ChildItem "agents\*.md" | Where-Object {
        $_.Name -ne "GLOSSARY.md" -and $_.Name -ne "README.md"
    } | Copy-Item -Destination $aicraftAgentsDir -Force
    Write-Color "   [OK] Agent files copied to: $aicraftAgentsDir" "Green"

    # Gemini CLI reads subagents from ~/.gemini/agents/*.md with YAML frontmatter.
    # Claude tool and model names mean nothing to Gemini, so install a portable
    # copy carrying only name and description and let Gemini pick its defaults.
    New-Item -ItemType Directory -Force -Path $GEMINI_AGENTS_DIR | Out-Null
    foreach ($agent in (Get-ChildItem "agents\*.md" | Where-Object {
        $_.Name -ne "GLOSSARY.md" -and $_.Name -ne "README.md"
    })) {
        Write-Portable -Source $agent.FullName -Destination (Join-Path $GEMINI_AGENTS_DIR $agent.Name) -FallbackName $agent.BaseName
    }
    Write-Color "   [OK] Subagents installed to: $GEMINI_AGENTS_DIR" "Green"

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
            $agentContent = (Get-BodyWithoutFrontmatter -Path $agent.FullName) -split "`n"

            # Prefer the frontmatter description, fall back to the opening lines
            $briefDesc = Get-FrontmatterField -Path $agent.FullName -Key "description"
            if ([string]::IsNullOrWhiteSpace($briefDesc) -and $agentContent.Count -ge 4) {
                $briefDesc = ($agentContent[2..3] | Out-String).Trim()
            }

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
            $afterContent = ""
            if ($existingContent -match '<!-- AI-CRAFT-AGENTS-END -->([\s\S]*)$') {
                $afterContent = $Matches[1]
            }

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

    # Create directory if it doesn't exist
    New-Item -ItemType Directory -Force -Path $CODEX_DIR | Out-Null

    # Codex reads custom subagents from ~/.codex/agents/*.toml. These carry their
    # own model and sandbox settings, which is how the review agents are kept
    # read-only. See https://learn.chatgpt.com/docs/agent-configuration/subagents
    if (Test-Path "codex\agents") {
        Write-Color "   [Installing Codex subagents...]" "Blue"
        New-Item -ItemType Directory -Force -Path $CODEX_AGENTS_DIR | Out-Null
        # Installers up to 1bf896a copied the agent markdown plus .codexignore
        # here. Codex parses this directory now, so those files have to go.
        Move-Legacy -TargetDir $CODEX_AGENTS_DIR -ExtraFiles @(".codexignore")
        Get-ChildItem "codex\agents\*.toml" | Copy-Item -Destination $CODEX_AGENTS_DIR -Force
        Write-Color "   [OK] Subagents installed to: $CODEX_AGENTS_DIR" "Green"
    }

    # Smart AGENTS.md update: preserve user content, only manage our section
    Write-Color "   [Updating AGENTS.md...]" "Blue"
    $agentsMdPath = Join-Path $CODEX_DIR "AGENTS.md"

    # Build our managed content section
    $codexManagedContent = @"
<!-- AI-CRAFT-AGENTS-START - Do not edit between these markers, content will be updated automatically -->

# AI Craft Workflow Guidance

The sections below are reference documents, not agents you can spawn. Apply the relevant guidance when working on a matching task.

The subagents you can actually spawn are defined in ~/.codex/agents/*.toml:
zs-code-agent, zs-code-review-agent, zs-context-review-agent, zs-content-review-agent.
The skills you can invoke live in ~/.agents/skills/:
zs-orchestrate, zs-self-review, zs-verify-references, zs-ticket-updates, zs-agent-comms.

"@

    # Append full agent content (exclude GLOSSARY and README)
    foreach ($agent in (Get-ChildItem "agents\*.md" | Where-Object {
        $_.Name -ne "GLOSSARY.md" -and $_.Name -ne "README.md"
    })) {
        $agentName = $agent.BaseName
        $codexManagedContent += "---`n`n### Guidance: $agentName`n`n"

        try {
            # Read the agent body without frontmatter
            $agentContent = Get-BodyWithoutFrontmatter -Path $agent.FullName

            # Remove @agent references, Codex has no @ syntax
            $agentContent = $agentContent -replace '@agent-[a-z-]+', ''

            if ([string]::IsNullOrWhiteSpace($agentContent)) {
                $agentContent = "# $agentName`n`nAgent documentation - see source repository for details"
            }

            $codexManagedContent += "$agentContent`n`n"
        }
        catch {
            $codexManagedContent += "# $agentName`n`nAgent documentation - see source repository for details`n`n"
        }
    }

    $codexManagedContent += "<!-- AI-CRAFT-AGENTS-END -->"

    # Check if AGENTS.md exists and has our markers
    if (Test-Path $agentsMdPath) {
        $existingContent = Get-Content $agentsMdPath -Raw -ErrorAction SilentlyContinue

        if ($existingContent -match "<!-- AI-CRAFT-AGENTS-START") {
            # Markers exist - replace content between markers, preserve user content
            Write-Color "   [Updating AI Craft section in existing AGENTS.md...]" "Blue"

            # Create backup
            $backupPath = "$agentsMdPath.backup.$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
            Copy-Item $agentsMdPath $backupPath
            Write-Color "   [BACKUP] Created: $backupPath" "Blue"

            # Extract content before markers
            $beforeContent = ($existingContent -split '<!-- AI-CRAFT-AGENTS-START')[0]

            # Extract content after markers (if exists)
            $afterContent = ""
            if ($existingContent -match '<!-- AI-CRAFT-AGENTS-END -->([\s\S]*)$') {
                $afterContent = $Matches[1]
            }

            # Combine: user content before + our managed content + user content after
            $newContent = $beforeContent + $codexManagedContent + $afterContent
            Set-Content -Path $agentsMdPath -Value $newContent

            Write-Color "   [OK] Updated AI Craft section, preserved user content" "Green"
        }
        else {
            # No markers - append our section to preserve existing user content
            Write-Color "   [Appending AI Craft section to existing AGENTS.md...]" "Blue"

            # Create backup
            $backupPath = "$agentsMdPath.backup.$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
            Copy-Item $agentsMdPath $backupPath
            Write-Color "   [BACKUP] Created: $backupPath" "Blue"

            # Append our managed section
            $newContent = $existingContent + "`n`n" + $codexManagedContent
            Set-Content -Path $agentsMdPath -Value $newContent

            Write-Color "   [OK] Appended AI Craft section, preserved existing content" "Green"
        }
    }
    else {
        # No AGENTS.md - create new file with just our content
        Write-Color "   [Creating new AGENTS.md...]" "Blue"
        Set-Content -Path $agentsMdPath -Value $codexManagedContent
        Write-Color "   [OK] Created new AGENTS.md" "Green"
    }

    Write-Color "   [OK] Codex CLI installation complete" "Green"
}

# Install Agent Skills to the shared location
# Both Codex and Gemini CLI read skills from ~/.agents/skills. The Agent Skills
# spec at https://agentskills.io does not mandate a location, this path is the
# convention both CLIs adopted. Install the portable form, carrying only the two
# frontmatter fields the spec requires.
if (($GEMINI_INSTALLED -or $CODEX_INSTALLED) -and (Test-Path "skills")) {
    Write-Color "[Installing Agent Skills to $SHARED_SKILLS_DIR...]" "Blue"
    New-Item -ItemType Directory -Force -Path $SHARED_SKILLS_DIR | Out-Null
    foreach ($skill in (Get-ChildItem "skills" -Directory)) {
        $skillFile = Join-Path $skill.FullName "SKILL.md"
        if (-not (Test-Path $skillFile)) { continue }
        $target = Join-Path $SHARED_SKILLS_DIR $skill.Name
        New-Item -ItemType Directory -Force -Path $target | Out-Null
        Write-Portable -Source $skillFile -Destination (Join-Path $target "SKILL.md") -FallbackName $skill.Name
    }
    Write-Color "   [OK] Skills installed to: $SHARED_SKILLS_DIR" "Green"
}

Write-Host ""
Write-Color "[OK] Installation complete!" "Green"
Write-Host ""

# Summary
Write-Color "[Installed agents for:]" "Cyan"
if ($CLAUDE_INSTALLED) { Write-Host "   - Claude Code: $CLAUDE_DIR and $CLAUDE_SKILLS_DIR" }
if ($GEMINI_INSTALLED) { Write-Host "   - Gemini CLI: $GEMINI_AGENTS_DIR and $GEMINI_DIR\GEMINI.md" }
if ($CODEX_INSTALLED) { Write-Host "   - OpenAI Codex: $CODEX_AGENTS_DIR and $CODEX_DIR\AGENTS.md" }
if ($GEMINI_INSTALLED -or $CODEX_INSTALLED) { Write-Host "   - Agent Skills: $SHARED_SKILLS_DIR" }

if (-not $CLAUDE_DETECTED -and -not $GEMINI_INSTALLED -and -not $CODEX_INSTALLED) {
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
    Write-Host "    /zs-orchestrate add rate limiting to the login endpoint"
    Write-Host "    /zs-self-review                   (run this before every push)"
    Write-Host "    /zs-verify-references"
    Write-Host "    /zs-ticket-updates create an engineering Story in NorthStar"
    Write-Host "    /zs-agent-comms coordinate work with an existing Codex peer"
    Write-Host "    @agent-zs-code-review-agent review the changes on this branch"
    Write-Host "    @agent-zs-sniff [paste opportunity]"
    Write-Host ""
    Write-Host "    Start a new Claude Code session before expecting these to appear."
}

if ($GEMINI_INSTALLED) {
    Write-Host ""
    Write-Color "  Gemini CLI:" "Blue"
    Write-Host "    Subagents installed to $env:USERPROFILE\.gemini\agents\, direct one with @<name>"
    Write-Host "    Example: '@zs-code-review-agent review the changes on this branch'"
    Write-Host "    Skills in $env:USERPROFILE\.agents\skills\, list them with /skills list"
    Write-Host "    Context also loaded from $env:USERPROFILE\.gemini\GEMINI.md at session start"
}

if ($CODEX_INSTALLED) {
    Write-Host ""
    Write-Color "  OpenAI Codex:" "Blue"
    Write-Host "    Skills in $env:USERPROFILE\.agents\skills\, invoke one with `$<name>"
    Write-Host "    Example: '`$zs-self-review', '`$zs-orchestrate add rate limiting', '`$zs-ticket-updates update issue #123', or '`$zs-agent-comms'"
    Write-Host "    Subagents in $env:USERPROFILE\.codex\agents\, spawn one by name in your prompt"
    Write-Host "    Example: 'Spawn the zs-code-review-agent to review this branch'"
    Write-Host "    Inspect running threads with /agent"
}

Write-Host ""
Write-Color "  After updating agents, start a new AI CLI session/window to load the latest instructions." "Blue"
Write-Host ""
Write-Color "Happy coding!" "Green"
