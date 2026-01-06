#!/bin/bash

# AI Craft Agents Installation Script
# Installs agents to appropriate locations for Claude, Gemini, and OpenAI CLIs

# Exit on error or undefined variables
set -eu

# Parse command line arguments
USE_EMOJI=true
for arg in "$@"; do
    case $arg in
        --no-emoji)
            USE_EMOJI=false
            ;;
        --help|-h)
            echo "AI Craft Agents Installation Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-emoji    Disable emoji output (use ASCII indicators instead)"
            echo "  --help, -h    Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Export emoji setting for use in color library
export USE_EMOJI

# Track installation state for cleanup
INSTALL_STARTED=false
BACKUP_DIR=""

# Cleanup function
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ] && [ "$INSTALL_STARTED" = true ]; then
        echo ""
        # Use print_error if available, otherwise use plain echo
        if type print_error &>/dev/null; then
            print_error "[ERROR] Installation failed at step: $CURRENT_STEP"
            if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
                print_info "   Backup available at: $BACKUP_DIR"
                print_info "   You can restore manually if needed"
            fi
            print_info "   Please check the error message above and try again"
        else
            echo "[ERROR] Installation failed at step: $CURRENT_STEP"
            if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
                echo "   Backup available at: $BACKUP_DIR"
                echo "   You can restore manually if needed"
            fi
            echo "   Please check the error message above and try again"
        fi
    fi
}

# Set trap for cleanup on error or exit
trap cleanup EXIT ERR

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_STEP="Initialization"

# Load shared color library
if [ -f "$SCRIPT_DIR/lib/colors.sh" ]; then
    source "$SCRIPT_DIR/lib/colors.sh"
else
    # Fallback if library not found
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; NC=''
    print_error() { echo "$1"; }
    print_success() { echo "$1"; }
    print_warning() { echo "$1"; }
    print_info() { echo "$1"; }
    print_header() { echo "$1"; }
fi

print_header "Installing AI Craft Agents..."
echo ""

CURRENT_STEP="Checking prerequisites"

# Check if agents directory exists
if [ ! -d "agents" ]; then
    print_error "ERROR: agents/ directory not found!"
    echo "Please run this script from the ai-craft root directory."
    exit 1
fi

# Check if agent files exist
if ! ls agents/*.md &> /dev/null; then
    print_error "ERROR: No .md files found in agents/ directory!"
    exit 1
fi

CURRENT_STEP="Verifying agent files"

# Verify file integrity
print_info "[Verifying agent files...]"
invalid_files=0
for agent in agents/*.md; do
    if [ -f "$agent" ]; then
        # Check if file is readable
        if [ ! -r "$agent" ]; then
            print_warning "   [WARN] File not readable: $agent"
            invalid_files=$((invalid_files + 1))
            continue
        fi

        # Check if file is empty
        if [ ! -s "$agent" ]; then
            print_warning "   [WARN] File is empty: $agent"
            invalid_files=$((invalid_files + 1))
            continue
        fi

        # Check if file starts with markdown header
        if ! head -1 "$agent" | grep -q "^#"; then
            print_warning "   [WARN] File doesn't start with markdown header: $agent"
            invalid_files=$((invalid_files + 1))
        fi
    fi
done

if [ $invalid_files -gt 0 ]; then
    print_warning "   [WARN] Found $invalid_files suspicious file(s) - continuing anyway"
else
    print_success "   [OK] All agent files verified"
fi
echo ""

# Installation paths for different AI CLIs
CLAUDE_DIR="$HOME/.claude/agents"
GEMINI_DIR="$HOME/.gemini"
CODEX_DIR="$HOME/.codex"

# Detect which CLIs are available
CLAUDE_INSTALLED=false
GEMINI_INSTALLED=false
CODEX_INSTALLED=false

# Check for Claude Code
if command -v claude &> /dev/null || [ -d "$HOME/.claude" ]; then
    CLAUDE_INSTALLED=true
fi

# Check for Gemini CLI
if command -v gemini &> /dev/null || [ -d "$HOME/.gemini" ]; then
    GEMINI_INSTALLED=true
fi

# Check for OpenAI Codex CLI
if command -v codex &> /dev/null || [ -d "$HOME/.codex" ]; then
    CODEX_INSTALLED=true
fi

# Install for Claude Code
if [ "$CLAUDE_INSTALLED" = true ]; then
    CURRENT_STEP="Installing for Claude Code"
    INSTALL_STARTED=true

    print_info "[Installing for Claude Code...]"

    # Create backup if directory already exists
    if [ -d "$CLAUDE_DIR" ] && [ "$(ls -A "$CLAUDE_DIR" 2>/dev/null)" ]; then
        BACKUP_DIR="$CLAUDE_DIR.backup.$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        if cp -r "$CLAUDE_DIR"/* "$BACKUP_DIR/" 2>/dev/null; then
            print_info "   [BACKUP] Previous installation backed up to: $BACKUP_DIR"
        else
            print_warning "   [WARN] Backup failed, but continuing installation"
        fi
    fi

    mkdir -p "$CLAUDE_DIR"

    # Copy agent files with error handling (exclude README and GLOSSARY - they're just docs)
    for agent in agents/*.md; do
        if [ -f "$agent" ]; then
            agent_name=$(basename "$agent")
            # Skip documentation files
            if [ "$agent_name" = "README.md" ] || [ "$agent_name" = "GLOSSARY.md" ]; then
                continue
            fi
            if ! cp "$agent" "$CLAUDE_DIR/" 2>/dev/null; then
                print_error "   [ERROR] Failed to copy $agent to $CLAUDE_DIR"
                exit 1
            fi
        fi
    done

    # Create .clignore to prevent Claude from scanning unwanted files
    cat > "$CLAUDE_DIR/.clignore" << 'EOF'
# Ignore backup files
*.backup.*

# Ignore non-agent files (keep only .md agents)
*.json
*.yaml
*.yml
*.txt
*.log
.DS_Store
EOF

    print_success "   [OK] Installed to: $CLAUDE_DIR"
fi

# Install for Gemini CLI
if [ "$GEMINI_INSTALLED" = true ]; then
    CURRENT_STEP="Installing for Gemini CLI"
    INSTALL_STARTED=true

    print_info "[Installing for Gemini CLI...]"

    # Create directories
    mkdir -p "$GEMINI_DIR"
    mkdir -p "$GEMINI_DIR/aicraft-agents"

    # Always copy/overwrite individual agent files (we control these)
    print_info "   [Copying agent files to $GEMINI_DIR/aicraft-agents/...]"
    for agent in agents/*.md; do
        if [ -f "$agent" ]; then
            agent_basename=$(basename "$agent")
            # Skip documentation files
            if [ "$agent_basename" = "README.md" ] || [ "$agent_basename" = "GLOSSARY.md" ]; then
                continue
            fi
            if ! cp "$agent" "$GEMINI_DIR/aicraft-agents/" 2>/dev/null; then
                print_error "   [ERROR] Failed to copy $agent to $GEMINI_DIR/aicraft-agents/"
                exit 1
            fi
        fi
    done
    print_success "   [OK] Agent files copied to: $GEMINI_DIR/aicraft-agents/"

    # Smart GEMINI.md update: preserve user content, only manage our section
    print_info "   [Updating GEMINI.md...]"

    # Build our managed content section
    MANAGED_CONTENT="<!-- AI-CRAFT-AGENTS-START - Do not edit between these markers, content will be updated automatically -->

# AI Craft Agents for Gemini

You have access to structured workflow agents that provide guidance for different development tasks. These agents define best practices, workflows, and patterns for software development.

When the user asks for help with development tasks, apply the relevant agent's guidance to structure your response.

Individual agent files are stored in: ~/.gemini/aicraft-agents/

## Available Agents

"

    # Append agent summaries with error handling
    for agent in agents/*.md; do
        if [ -f "$agent" ]; then
            agent_basename=$(basename "$agent")
            # Skip documentation files
            if [ "$agent_basename" = "README.md" ] || [ "$agent_basename" = "GLOSSARY.md" ]; then
                continue
            fi
            agent_name=$(basename "$agent" .md)
            MANAGED_CONTENT+="### Agent: $agent_name"$'\n\n'

            # Extract key sections: Brief description, Purpose, and When to Use
            brief_desc=$(sed -n '3,4p' "$agent" 2>/dev/null)
            purpose=$(awk '/^## Purpose$/,/^## [^P]/ {if (!/^## [^P]/) print}' "$agent" 2>/dev/null)
            when_to_use=$(awk '/^## When to Use$/,/^## [^W]/ {if (!/^## [^W]/) print}' "$agent" 2>/dev/null)

            # Combine sections
            agent_summary="${brief_desc}"$'\n\n'"${purpose}"$'\n\n'"${when_to_use}"

            # Fallback if extraction fails
            if [ -z "$agent_summary" ] || [ ${#agent_summary} -lt 20 ]; then
                agent_summary="Agent documentation - see $agent_name.md for details"
            fi

            # Remove inline @ references to prevent Gemini CLI import errors
            agent_summary=$(echo "$agent_summary" | sed 's/@[a-z-]\+//g')
            MANAGED_CONTENT+="$agent_summary"$'\n\n'
        fi
    done

    MANAGED_CONTENT+="<!-- AI-CRAFT-AGENTS-END -->"

    # Check if GEMINI.md exists and has our markers
    if [ -f "$GEMINI_DIR/GEMINI.md" ]; then
        if grep -q "<!-- AI-CRAFT-AGENTS-START" "$GEMINI_DIR/GEMINI.md" 2>/dev/null; then
            # Markers exist - replace content between markers, preserve user content
            print_info "   [Updating AI Craft section in existing GEMINI.md...]"

            # Create backup before modifying
            BACKUP_FILE="$GEMINI_DIR/GEMINI.md.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$GEMINI_DIR/GEMINI.md" "$BACKUP_FILE"
            print_info "   [BACKUP] Created: $BACKUP_FILE"

            # Extract content before our markers
            before_content=$(awk '/<!-- AI-CRAFT-AGENTS-START/ {exit} {print}' "$GEMINI_DIR/GEMINI.md")
            # Extract content after our markers
            after_content=$(awk '/<!-- AI-CRAFT-AGENTS-END -->/ {found=1; next} found {print}' "$GEMINI_DIR/GEMINI.md")

            # Combine: user content before + our managed content + user content after
            {
                echo "$before_content"
                echo "$MANAGED_CONTENT"
                echo "$after_content"
            } > "$GEMINI_DIR/GEMINI.md"

            print_success "   [OK] Updated AI Craft section, preserved user content"
        else
            # No markers - append our section to preserve existing user content
            print_info "   [Appending AI Craft section to existing GEMINI.md...]"

            # Create backup
            BACKUP_FILE="$GEMINI_DIR/GEMINI.md.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$GEMINI_DIR/GEMINI.md" "$BACKUP_FILE"
            print_info "   [BACKUP] Created: $BACKUP_FILE"

            # Append our managed section
            {
                cat "$GEMINI_DIR/GEMINI.md"
                echo ""
                echo ""
                echo "$MANAGED_CONTENT"
            } > "$GEMINI_DIR/GEMINI.md.tmp" && mv "$GEMINI_DIR/GEMINI.md.tmp" "$GEMINI_DIR/GEMINI.md"

            print_success "   [OK] Appended AI Craft section, preserved existing content"
        fi
    else
        # No GEMINI.md - create new file with just our content
        print_info "   [Creating new GEMINI.md...]"
        echo "$MANAGED_CONTENT" > "$GEMINI_DIR/GEMINI.md"
        print_success "   [OK] Created new GEMINI.md"
    fi

    print_success "   [OK] Gemini CLI installation complete"
fi

# Install for OpenAI Codex CLI
if [ "$CODEX_INSTALLED" = true ]; then
    CURRENT_STEP="Installing for OpenAI Codex CLI"
    INSTALL_STARTED=true

    print_info "[Installing for OpenAI Codex CLI...]"

    # Create directory if it doesn't exist
    mkdir -p "$CODEX_DIR"

    # Migration: Clean up old incorrect agents/ directory structure
    if [ -d "$CODEX_DIR/agents" ]; then
        print_warning "   [MIGRATION] Found old ~/.codex/agents/ directory (incorrect structure)"
        print_info "   [MIGRATION] Codex uses ~/.codex/AGENTS.md, not individual files"

        # Backup old directory
        OLD_BACKUP_DIR="$CODEX_DIR/agents.old.$(date +%Y%m%d_%H%M%S)"
        if mv "$CODEX_DIR/agents" "$OLD_BACKUP_DIR" 2>/dev/null; then
            print_info "   [MIGRATION] Old directory moved to: $OLD_BACKUP_DIR"
            print_info "   [MIGRATION] You can safely delete it after verifying the new setup works"
        else
            print_warning "   [WARN] Could not move old directory, please remove manually: $CODEX_DIR/agents"
        fi
    fi

    # Smart AGENTS.md update: preserve user content, only manage our section
    print_info "   [Updating AGENTS.md...]"

    # Build our managed content section
    CODEX_MANAGED_CONTENT="<!-- AI-CRAFT-AGENTS-START - Do not edit between these markers, content will be updated automatically -->

# AI Craft Agents

Structured workflow agents for software development tasks. Apply the relevant agent's guidance when working on matching tasks.

"

    # Append full agent content
    for agent in agents/*.md; do
        if [ -f "$agent" ]; then
            agent_basename=$(basename "$agent")
            # Skip documentation files
            if [ "$agent_basename" = "README.md" ] || [ "$agent_basename" = "GLOSSARY.md" ]; then
                continue
            fi
            agent_name=$(basename "$agent" .md)
            CODEX_MANAGED_CONTENT+="---"$'\n\n'

            # Read full agent content, remove @ references that don't work in Codex
            agent_content=$(sed 's/@[a-z-]\+//g' "$agent" 2>/dev/null)

            if [ -z "$agent_content" ]; then
                agent_content="# $agent_name"$'\n\n'"Agent documentation - see source repository for details"
            fi

            CODEX_MANAGED_CONTENT+="$agent_content"$'\n\n'
        fi
    done

    CODEX_MANAGED_CONTENT+="<!-- AI-CRAFT-AGENTS-END -->"

    # Check if AGENTS.md exists and has our markers
    if [ -f "$CODEX_DIR/AGENTS.md" ]; then
        if grep -q "<!-- AI-CRAFT-AGENTS-START" "$CODEX_DIR/AGENTS.md" 2>/dev/null; then
            # Markers exist - replace content between markers, preserve user content
            print_info "   [Updating AI Craft section in existing AGENTS.md...]"

            # Create backup before modifying
            BACKUP_FILE="$CODEX_DIR/AGENTS.md.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$CODEX_DIR/AGENTS.md" "$BACKUP_FILE"
            print_info "   [BACKUP] Created: $BACKUP_FILE"

            # Extract content before our markers
            before_content=$(awk '/<!-- AI-CRAFT-AGENTS-START/ {exit} {print}' "$CODEX_DIR/AGENTS.md")
            # Extract content after our markers
            after_content=$(awk '/<!-- AI-CRAFT-AGENTS-END -->/ {found=1; next} found {print}' "$CODEX_DIR/AGENTS.md")

            # Combine: user content before + our managed content + user content after
            {
                echo "$before_content"
                echo "$CODEX_MANAGED_CONTENT"
                echo "$after_content"
            } > "$CODEX_DIR/AGENTS.md"

            print_success "   [OK] Updated AI Craft section, preserved user content"
        else
            # No markers - append our section to preserve existing user content
            print_info "   [Appending AI Craft section to existing AGENTS.md...]"

            # Create backup
            BACKUP_FILE="$CODEX_DIR/AGENTS.md.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$CODEX_DIR/AGENTS.md" "$BACKUP_FILE"
            print_info "   [BACKUP] Created: $BACKUP_FILE"

            # Append our managed section
            {
                cat "$CODEX_DIR/AGENTS.md"
                echo ""
                echo ""
                echo "$CODEX_MANAGED_CONTENT"
            } > "$CODEX_DIR/AGENTS.md.tmp" && mv "$CODEX_DIR/AGENTS.md.tmp" "$CODEX_DIR/AGENTS.md"

            print_success "   [OK] Appended AI Craft section, preserved existing content"
        fi
    else
        # No AGENTS.md - create new file with just our content
        print_info "   [Creating new AGENTS.md...]"
        echo "$CODEX_MANAGED_CONTENT" > "$CODEX_DIR/AGENTS.md"
        print_success "   [OK] Created new AGENTS.md"
    fi

    print_success "   [OK] Codex CLI installation complete"
fi

echo ""
print_success "[OK] Installation complete!"
echo ""

# Summary
print_header "[Installed agents for:]"
[ "$CLAUDE_INSTALLED" = true ] && echo "   - Claude Code: $CLAUDE_DIR"
[ "$GEMINI_INSTALLED" = true ] && echo "   - Gemini CLI: $GEMINI_DIR/GEMINI.md"
[ "$CODEX_INSTALLED" = true ] && echo "   - OpenAI Codex: $CODEX_DIR/AGENTS.md"

if [ "$CLAUDE_INSTALLED" = false ] && [ "$GEMINI_INSTALLED" = false ] && [ "$CODEX_INSTALLED" = false ]; then
    print_warning "   [WARN] No AI CLIs detected"
    echo "   Installing to fallback location: $HOME/.aicraft/agents"
    mkdir -p "$HOME/.aicraft/agents"

    # Copy with error handling (exclude README and GLOSSARY - they're just docs)
    for agent in agents/*.md; do
        if [ -f "$agent" ]; then
            agent_name=$(basename "$agent")
            # Skip documentation files
            if [ "$agent_name" = "README.md" ] || [ "$agent_name" = "GLOSSARY.md" ]; then
                continue
            fi
            if ! cp "$agent" "$HOME/.aicraft/agents/" 2>/dev/null; then
                print_error "   [ERROR] Failed to copy $agent to fallback location"
                exit 1
            fi
        fi
    done
    print_success "   [OK] Installed to fallback location"
fi

echo ""
print_header "[USAGE]"

if [ "$CLAUDE_INSTALLED" = true ]; then
    echo ""
    print_info "  Claude Code:"
    echo "    @dev-agent Phase 1: Analyze my code"
    echo "    @gemini-dev Ask Gemini to check performance"
fi

if [ "$GEMINI_INSTALLED" = true ]; then
    echo ""
    print_info "  Gemini CLI:"
    echo "    Agents automatically loaded from ~/.gemini/GEMINI.md"
    echo "    Note: @ syntax not supported - just describe what you want"
    echo "    Example: 'Analyze my code using the 5-phase development workflow'"
fi

if [ "$CODEX_INSTALLED" = true ]; then
    echo ""
    print_info "  OpenAI Codex:"
    echo "    Agents automatically loaded from ~/.codex/AGENTS.md"
    echo "    Note: @ syntax not supported - just describe what you want"
    echo "    Example: 'Analyze my code using the 5-phase development workflow'"
fi

echo ""
print_success "Happy coding!"
