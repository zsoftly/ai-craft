# AI Craft Agents Update Script (PowerShell)
# Smart update that detects custom modifications and offers merge options

Write-Host "AI Craft Agents - Smart Update" -ForegroundColor Cyan
Write-Host ""

# Check if agents directory exists
if (-not (Test-Path "agents")) {
    Write-Host "ERROR: agents/ directory not found!" -ForegroundColor Red
    Write-Host "Please run this script from the ai-craft root directory."
    exit 1
}

# Check if agent files exist
$agentFiles = Get-ChildItem -Path "agents\*.md" -ErrorAction SilentlyContinue
if ($agentFiles.Count -eq 0) {
    Write-Host "ERROR: No .md files found in agents/ directory!" -ForegroundColor Red
    exit 1
}

# Installation paths for different AI CLIs
$claudeDir = "$env:USERPROFILE\.claude\agents"
$geminiDir = "$env:USERPROFILE\.gemini"
$codexDir = "$env:USERPROFILE\.codex"
$fallbackDir = "$env:USERPROFILE\.aicraft\agents"

# Detect which CLIs have agents installed
$claudeInstalled = $false
$geminiInstalled = $false
$codexInstalled = $false
$fallbackInstalled = $false

if ((Test-Path $claudeDir) -and ((Get-ChildItem -Path "$claudeDir\*.md" -ErrorAction SilentlyContinue).Count -gt 0)) {
    $claudeInstalled = $true
}

if ((Test-Path $geminiDir) -and ((Get-ChildItem -Path "$geminiDir\*.md" -ErrorAction SilentlyContinue).Count -gt 0)) {
    $geminiInstalled = $true
}

if ((Test-Path $codexDir) -and (Test-Path "$codexDir\instructions.md")) {
    $codexInstalled = $true
}

if ((Test-Path $fallbackDir) -and ((Get-ChildItem -Path "$fallbackDir\*.md" -ErrorAction SilentlyContinue).Count -gt 0)) {
    $fallbackInstalled = $true
}

# Check if any installation exists
if (-not ($claudeInstalled -or $geminiInstalled -or $codexInstalled -or $fallbackInstalled)) {
    Write-Host "[INFO] No existing installation found." -ForegroundColor Yellow
    Write-Host "Please run .\install.ps1 first to install agents."
    exit 0
}

Write-Host "[Detected Installations]" -ForegroundColor Blue
if ($claudeInstalled) { Write-Host "   - Claude Code: $claudeDir" }
if ($geminiInstalled) { Write-Host "   - Gemini CLI: $geminiDir" }
if ($codexInstalled) { Write-Host "   - OpenAI Codex: $codexDir" }
if ($fallbackInstalled) { Write-Host "   - Fallback: $fallbackDir" }
Write-Host ""

# Function to check if file has been modified by user
function Test-CustomChanges {
    param(
        [string]$sourceFile,
        [string]$installedFile
    )

    if (-not (Test-Path $installedFile)) {
        return $false  # File doesn't exist, no custom changes
    }

    # Compare files
    $sourceContent = Get-Content $sourceFile -Raw -ErrorAction SilentlyContinue
    $installedContent = Get-Content $installedFile -Raw -ErrorAction SilentlyContinue

    if ($sourceContent -eq $installedContent) {
        return $false  # Files are identical, no custom changes
    } else {
        return $true   # Files differ, user has custom changes
    }
}

# Function to create backup
function Backup-File {
    param([string]$file)

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backup = "$file.backup.$timestamp"

    try {
        Copy-Item -Path $file -Destination $backup -ErrorAction Stop
        Write-Host "   [BACKUP] Created: $backup" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "   [ERROR] Failed to create backup: $_" -ForegroundColor Red
        return $false
    }
}

# Function to show diff between files
function Show-Diff {
    param(
        [string]$sourceFile,
        [string]$installedFile
    )

    Write-Host ""
    Write-Host "--- Differences ---" -ForegroundColor Cyan

    if (Get-Command code -ErrorAction SilentlyContinue) {
        Write-Host "Opening VS Code diff viewer..."
        & code --diff $installedFile $sourceFile
    } else {
        Write-Host "Installed version (first 20 lines):" -ForegroundColor Yellow
        Get-Content $installedFile | Select-Object -First 20
        Write-Host ""
        Write-Host "New version (first 20 lines):" -ForegroundColor Yellow
        Get-Content $sourceFile | Select-Object -First 20
    }
    Write-Host ""
}

# Function to prompt user for action
function Invoke-UserAction {
    param(
        [string]$agentName,
        [string]$sourceFile,
        [string]$installedFile
    )

    Write-Host ""
    Write-Host "[CUSTOM CHANGES DETECTED] $agentName" -ForegroundColor Yellow
    Write-Host "The installed version has been modified since installation."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  1) Overwrite - Replace with new version (backup created)" -ForegroundColor Green
    Write-Host "  2) Keep - Keep your custom version" -ForegroundColor Blue
    Write-Host "  3) Diff - Show differences" -ForegroundColor Cyan
    Write-Host "  4) Merge - Manual merge (opens in editor)" -ForegroundColor Yellow
    Write-Host "  5) Abort - Stop update process" -ForegroundColor Red
    Write-Host ""

    while ($true) {
        $choice = Read-Host "Choose action [1-5]"

        switch ($choice) {
            "1" {
                if (-not (Backup-File $installedFile)) { return $false }
                try {
                    Copy-Item -Path $sourceFile -Destination $installedFile -Force -ErrorAction Stop
                    Write-Host "   [OK] Overwritten with new version" -ForegroundColor Green
                    return $true
                } catch {
                    Write-Host "   [ERROR] Failed to overwrite: $_" -ForegroundColor Red
                    return $false
                }
            }
            "2" {
                Write-Host "   [SKIP] Keeping your custom version" -ForegroundColor Blue
                return $true
            }
            "3" {
                Show-Diff $sourceFile $installedFile
                continue
            }
            "4" {
                if (-not (Backup-File $installedFile)) { return $false }
                Write-Host "   [MERGE] Opening editor for manual merge..." -ForegroundColor Cyan

                if (Get-Command code -ErrorAction SilentlyContinue) {
                    & code --diff $installedFile $sourceFile --wait
                } elseif (Get-Command notepad -ErrorAction SilentlyContinue) {
                    Write-Host "Opening files in Notepad..."
                    Start-Process notepad $installedFile
                    Start-Process notepad $sourceFile
                    Write-Host "Please merge manually, then press Enter to continue..."
                    Read-Host
                } else {
                    Write-Host "   [ERROR] No editor found. Please merge manually." -ForegroundColor Red
                    Write-Host "   Installed: $installedFile"
                    Write-Host "   New version: $sourceFile"
                }

                Write-Host "   [OK] Manual merge completed" -ForegroundColor Green
                return $true
            }
            "5" {
                Write-Host "[ABORT] Update cancelled by user" -ForegroundColor Red
                exit 0
            }
            default {
                Write-Host "Invalid choice. Please enter 1-5." -ForegroundColor Yellow
            }
        }
    }
}

# Function to update agents in a directory
function Update-Agents {
    param(
        [string]$targetDir,
        [string]$agentType
    )

    Write-Host ""
    Write-Host "[Updating $agentType]" -ForegroundColor Blue

    $modifiedCount = 0
    $updatedCount = 0
    $skippedCount = 0

    foreach ($sourceAgent in Get-ChildItem -Path "agents\*.md") {
        $agentName = $sourceAgent.Name
        $installedAgent = Join-Path $targetDir $agentName

        if (Test-CustomChanges $sourceAgent.FullName $installedAgent) {
            $modifiedCount++
            $result = Invoke-UserAction $agentName $sourceAgent.FullName $installedAgent
            if ($result) {
                $updatedCount++
            } else {
                $skippedCount++
            }
        } else {
            # No custom changes, safe to update
            try {
                Copy-Item -Path $sourceAgent.FullName -Destination $installedAgent -Force -ErrorAction Stop
                Write-Host "   [OK] Updated: $agentName" -ForegroundColor Green
                $updatedCount++
            } catch {
                Write-Host "   [ERROR] Failed to update: $agentName - $_" -ForegroundColor Red
                $skippedCount++
            }
        }
    }

    Write-Host ""
    Write-Host "[$agentType Summary]" -ForegroundColor Cyan
    Write-Host "   Updated: $updatedCount"
    if ($modifiedCount -gt 0) { Write-Host "   Custom changes detected: $modifiedCount" }
    if ($skippedCount -gt 0) { Write-Host "   Skipped: $skippedCount" }
}

# Update Claude Code agents
if ($claudeInstalled) {
    Update-Agents $claudeDir "Claude Code"
}

# Update Gemini CLI agents
if ($geminiInstalled) {
    Update-Agents $geminiDir "Gemini CLI"

    # Also update system.md if needed
    if (Test-Path "$geminiDir\system.md") {
        Write-Host ""
        Write-Host "[Checking Gemini system.md]" -ForegroundColor Blue

        # Regenerate system.md
        $tempSystemMd = New-TemporaryFile
        $systemContent = @"
# AI Craft Agents for Gemini

You have access to structured workflow agents. When the user references an agent with @, provide guidance based on these workflows:

## Available Agents

"@
        Set-Content -Path $tempSystemMd -Value $systemContent

        foreach ($agent in Get-ChildItem -Path "agents\*.md") {
            $agentName = $agent.BaseName
            Add-Content -Path $tempSystemMd -Value "### @$agentName"

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
                            Add-Content -Path $tempSystemMd -Value $agentContent[$j]
                            $totalLines++
                        }

                        # Skip past the lines we just output
                        $i = $endIndex - 1
                    }
                }

                if (-not $foundAnyHeader) {
                    Add-Content -Path $tempSystemMd -Value "Agent documentation"
                }
            }
            catch {
                Add-Content -Path $tempSystemMd -Value "Agent documentation"
            }
            Add-Content -Path $tempSystemMd -Value ""
        }

        if (Test-CustomChanges $tempSystemMd "$geminiDir\system.md") {
            Invoke-UserAction "system.md" $tempSystemMd "$geminiDir\system.md"
        } else {
            Copy-Item -Path $tempSystemMd -Destination "$geminiDir\system.md" -Force
            Write-Host "   [OK] Updated system.md" -ForegroundColor Green
        }

        Remove-Item $tempSystemMd -Force
    }
}

# Update OpenAI Codex agents
if ($codexInstalled) {
    Update-Agents $codexDir "OpenAI Codex"

    # Regenerate instructions.md
    if (Test-Path "$codexDir\instructions.md") {
        Write-Host ""
        Write-Host "[Checking Codex instructions.md]" -ForegroundColor Blue

        $tempInstructions = New-TemporaryFile
        $instructionsHeader = @"
# AI Craft Development Agents

Follow these structured workflows when developing:

"@
        Set-Content -Path $tempInstructions -Value $instructionsHeader

        foreach ($agent in @("agents\dev-agent.md", "agents\tdd-agent.md", "agents\code-review-agent.md")) {
            if (Test-Path $agent) {
                Get-Content $agent | Add-Content -Path $tempInstructions
                Add-Content -Path $tempInstructions -Value "`n---`n"
            }
        }

        if (Test-CustomChanges $tempInstructions "$codexDir\instructions.md") {
            Invoke-UserAction "instructions.md" $tempInstructions "$codexDir\instructions.md"
        } else {
            Copy-Item -Path $tempInstructions -Destination "$codexDir\instructions.md" -Force
            Write-Host "   [OK] Updated instructions.md" -ForegroundColor Green
        }

        Remove-Item $tempInstructions -Force
    }
}

# Update fallback installation
if ($fallbackInstalled) {
    Update-Agents $fallbackDir "Fallback Location"
}

Write-Host ""
Write-Host "[OK] Update complete!" -ForegroundColor Green
Write-Host ""

# Show backup locations if any were created
$backupLocations = @(
    "$env:USERPROFILE\.claude\agents\*.backup.*",
    "$env:USERPROFILE\.gemini\*.backup.*",
    "$env:USERPROFILE\.codex\*.backup.*",
    "$env:USERPROFILE\.aicraft\agents\*.backup.*"
)

$backupsFound = $false
foreach ($location in $backupLocations) {
    if (Test-Path $location) {
        $backupsFound = $true
        break
    }
}

if ($backupsFound) {
    Write-Host "[Backups Created]" -ForegroundColor Cyan
    Write-Host "Your custom versions have been backed up with .backup.TIMESTAMP extension"
    Write-Host "You can restore them anytime if needed."
    Write-Host ""
}

Write-Host "[USAGE]" -ForegroundColor Cyan
Write-Host "All agents are now updated. Continue using them as before:"
Write-Host "  @dev-agent Phase 1: Analyze my code"
Write-Host "  @gemini-dev Ask Gemini to check performance"
Write-Host ""
Write-Host "Happy coding!" -ForegroundColor Green
