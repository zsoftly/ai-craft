#!/bin/bash

# AI Craft Agents Installation Script
# Installs agents to appropriate locations for Claude, Gemini, and OpenAI CLIs

# Exit on error or undefined variables
set -eu

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    print_info "[Installing for Claude Code...]"
    mkdir -p "$CLAUDE_DIR"

    # Copy agent files with error handling
    if cp agents/*.md "$CLAUDE_DIR/" 2>/dev/null; then
        print_success "   [OK] Installed to: $CLAUDE_DIR"
    else
        print_error "   [ERROR] Failed to copy files to $CLAUDE_DIR"
        exit 1
    fi
fi

# Install for Gemini CLI
if [ "$GEMINI_INSTALLED" = true ]; then
    print_info "[Installing for Gemini CLI...]"
    mkdir -p "$GEMINI_DIR"

    # Create system.md with agent instructions
    cat > "$GEMINI_DIR/system.md" << 'EOF'
# AI Craft Agents for Gemini

You have access to structured workflow agents. When the user references an agent with @, provide guidance based on these workflows:

## Available Agents

EOF

    # Append agent summaries with error handling
    for agent in agents/*.md; do
        if [ -f "$agent" ]; then
            agent_name=$(basename "$agent" .md)
            echo "### @$agent_name" >> "$GEMINI_DIR/system.md"

            # Extract agent summary with fallback
            if head -20 "$agent" | grep -A 5 "^##" | head -10 >> "$GEMINI_DIR/system.md" 2>/dev/null; then
                :  # Success, do nothing
            else
                echo "Agent documentation" >> "$GEMINI_DIR/system.md"
            fi
            echo "" >> "$GEMINI_DIR/system.md"
        fi
    done

    # Also copy full agents for reference
    if cp agents/*.md "$GEMINI_DIR/" 2>/dev/null; then
        print_success "   [OK] Installed to: $GEMINI_DIR/system.md"
    else
        print_error "   [ERROR] Failed to copy files to $GEMINI_DIR"
        exit 1
    fi
fi

# Install for OpenAI Codex CLI
if [ "$CODEX_INSTALLED" = true ]; then
    print_info "[Installing for OpenAI Codex CLI...]"
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
[ "$GEMINI_INSTALLED" = true ] && echo "   - Gemini CLI: $GEMINI_DIR/system.md"
[ "$CODEX_INSTALLED" = true ] && echo "   - OpenAI Codex: $CODEX_DIR/instructions.md"

if [ "$CLAUDE_INSTALLED" = false ] && [ "$GEMINI_INSTALLED" = false ] && [ "$CODEX_INSTALLED" = false ]; then
    print_warning "   [WARN] No AI CLIs detected"
    echo "   Installing to fallback location: $HOME/.aicraft/agents"
    mkdir -p "$HOME/.aicraft/agents"

    # Copy with error handling
    if cp agents/*.md "$HOME/.aicraft/agents/" 2>/dev/null; then
        print_success "   [OK] Installed to fallback location"
    else
        print_error "   [ERROR] Failed to copy files to fallback location"
        exit 1
    fi
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
    echo "    Set GEMINI_SYSTEM_MD=true in your environment"
    echo "    export GEMINI_SYSTEM_MD=true"
    echo "    Then agents will be available automatically"
fi

if [ "$CODEX_INSTALLED" = true ]; then
    echo ""
    print_info "  OpenAI Codex:"
    echo "    Instructions loaded automatically"
    echo "    Agents guide all code generation"
fi

echo ""
print_success "Happy coding!"
