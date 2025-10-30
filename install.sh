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
    print_success "   [OK] Installed to: $CLAUDE_DIR"
fi

# Install for Gemini CLI
if [ "$GEMINI_INSTALLED" = true ]; then
    CURRENT_STEP="Installing for Gemini CLI"
    INSTALL_STARTED=true

    print_info "[Installing for Gemini CLI...]"

    # Create backup if GEMINI.md already exists
    if [ -f "$GEMINI_DIR/GEMINI.md" ]; then
        BACKUP_DIR="$GEMINI_DIR/backup.$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        if cp "$GEMINI_DIR/GEMINI.md" "$BACKUP_DIR/" 2>/dev/null; then
            print_info "   [BACKUP] Previous GEMINI.md backed up to: $BACKUP_DIR"
        else
            print_warning "   [WARN] Backup failed, but continuing installation"
        fi
    fi

    mkdir -p "$GEMINI_DIR"

    # Create GEMINI.md with agent instructions (automatically loaded, no env var needed)
    # Build content in memory first, then write once for better performance
    GEMINI_CONTENT="# AI Craft Agents for Gemini

You have access to structured workflow agents. When the user references an agent with @, provide guidance based on these workflows:

## Available Agents

"

    # Append agent summaries with error handling (exclude README and GLOSSARY - they're just docs)
    for agent in agents/*.md; do
        if [ -f "$agent" ]; then
            agent_basename=$(basename "$agent")
            # Skip documentation files
            if [ "$agent_basename" = "README.md" ] || [ "$agent_basename" = "GLOSSARY.md" ]; then
                continue
            fi
            agent_name=$(basename "$agent" .md)
            GEMINI_CONTENT+="### Agent: $agent_name"$'\n'
            # Extract overview and usage sections more robustly
            # Get content from first ## header, up to 15 lines total
            agent_summary=$(awk 'BEGIN { count=0 } /^## / { found=1 } found { if (count >= 15) exit; print; count++ }' "$agent" 2>/dev/null) || \
                agent_summary="Agent documentation - see $agent_name.md for details"
            # Remove inline @ references to prevent Gemini CLI import errors
            # Gemini CLI treats any @word as an import directive, not just headers
            agent_summary=$(echo "$agent_summary" | sed 's/@[a-z-][a-z-]*//g')
            GEMINI_CONTENT+="$agent_summary"$'\n\n'
        fi
    done

    # Write content to file in one operation
    if echo "$GEMINI_CONTENT" > "$GEMINI_DIR/GEMINI.md" 2>/dev/null; then
        print_success "   [OK] Installed to: $GEMINI_DIR/GEMINI.md"
    else
        print_error "   [ERROR] Failed to write to $GEMINI_DIR/GEMINI.md"
        print_error "   Reason: Permission denied or directory not writable"
        exit 1
    fi

    # Note: We don't copy individual agent files because they contain inline @ references
    # that Gemini CLI interprets as import directives, causing errors.
    # GEMINI.md already contains cleaned summaries of all agents.
fi

# Install for OpenAI Codex CLI
if [ "$CODEX_INSTALLED" = true ]; then
    CURRENT_STEP="Installing for OpenAI Codex CLI"
    INSTALL_STARTED=true

    print_info "[Installing for OpenAI Codex CLI...]"

    # Create backup if instructions.md already exists
    if [ -f "$CODEX_DIR/instructions.md" ]; then
        BACKUP_DIR="$CODEX_DIR/backup.$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        if cp "$CODEX_DIR/instructions.md" "$BACKUP_DIR/" 2>/dev/null; then
            print_info "   [BACKUP] Previous instructions.md backed up to: $BACKUP_DIR"
        else
            print_warning "   [WARN] Backup failed, but continuing installation"
        fi
    fi

    mkdir -p "$CODEX_DIR"

    # Create instructions.md with agent guidance
    cat > "$CODEX_DIR/instructions.md" << 'EOF'
# AI Craft Development Agents

Follow these structured workflows when developing:

EOF

    # Append agent content with error handling
    agent_count=0
    for agent in agents/dev-agent.md agents/tdd-agent.md agents/code-review-agent.md; do
        if [ -f "$agent" ]; then
            if cat "$agent" >> "$CODEX_DIR/instructions.md" 2>/dev/null; then
                echo -e "\n---\n" >> "$CODEX_DIR/instructions.md"
                agent_count=$((agent_count + 1))
            fi
        fi
    done

    if [ $agent_count -gt 0 ]; then
        print_success "   [OK] Installed to: $CODEX_DIR/instructions.md"
    else
        print_warning "   [WARN] No agent files found for Codex"
    fi
fi

echo ""
print_success "[OK] Installation complete!"
echo ""

# Summary
print_header "[Installed agents for:]"
[ "$CLAUDE_INSTALLED" = true ] && echo "   - Claude Code: $CLAUDE_DIR"
[ "$GEMINI_INSTALLED" = true ] && echo "   - Gemini CLI: $GEMINI_DIR/GEMINI.md"
[ "$CODEX_INSTALLED" = true ] && echo "   - OpenAI Codex: $CODEX_DIR/instructions.md"

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
    echo "    No configuration needed - just use Gemini CLI as normal"
fi

if [ "$CODEX_INSTALLED" = true ]; then
    echo ""
    print_info "  OpenAI Codex:"
    echo "    Instructions loaded automatically"
    echo "    Agents guide all code generation"
fi

echo ""
print_success "Happy coding!"
