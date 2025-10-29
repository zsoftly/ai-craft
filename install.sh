#!/bin/bash

# AI Craft Agents Installation Script
# Installs agents to appropriate locations for Claude, Gemini, and OpenAI CLIs

set -e

echo "🤖 Installing AI Craft Agents..."
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
    echo "📁 Installing for Claude Code..."
    mkdir -p "$CLAUDE_DIR"
    cp agents/*.md "$CLAUDE_DIR/"
    echo "   ✓ Installed to: $CLAUDE_DIR"
fi

# Install for Gemini CLI
if [ "$GEMINI_INSTALLED" = true ]; then
    echo "📁 Installing for Gemini CLI..."
    mkdir -p "$GEMINI_DIR"

    # Create system.md with agent instructions
    cat > "$GEMINI_DIR/system.md" << 'EOF'
# AI Craft Agents for Gemini

You have access to structured workflow agents. When the user references an agent with @, provide guidance based on these workflows:

## Available Agents

EOF

    # Append agent summaries
    for agent in agents/*.md; do
        agent_name=$(basename "$agent" .md)
        echo "### @$agent_name" >> "$GEMINI_DIR/system.md"
        head -20 "$agent" | grep -A 5 "^##" | head -10 >> "$GEMINI_DIR/system.md"
        echo "" >> "$GEMINI_DIR/system.md"
    done

    # Also copy full agents for reference
    cp agents/*.md "$GEMINI_DIR/"
    echo "   ✓ Installed to: $GEMINI_DIR/system.md"
fi

# Install for OpenAI Codex CLI
if [ "$CODEX_INSTALLED" = true ]; then
    echo "📁 Installing for OpenAI Codex CLI..."
    mkdir -p "$CODEX_DIR"

    # Create instructions.md with agent guidance
    cat > "$CODEX_DIR/instructions.md" << 'EOF'
# AI Craft Development Agents

Follow these structured workflows when developing:

EOF

    # Append agent content
    for agent in agents/dev-agent.md agents/tdd-agent.md agents/code-review-agent.md; do
        if [ -f "$agent" ]; then
            cat "$agent" >> "$CODEX_DIR/instructions.md"
            echo -e "\n---\n" >> "$CODEX_DIR/instructions.md"
        fi
    done

    echo "   ✓ Installed to: $CODEX_DIR/instructions.md"
fi

echo ""
echo "✅ Installation complete!"
echo ""

# Summary
echo "📍 Installed agents for:"
[ "$CLAUDE_INSTALLED" = true ] && echo "   • Claude Code: $CLAUDE_DIR"
[ "$GEMINI_INSTALLED" = true ] && echo "   • Gemini CLI: $GEMINI_DIR/system.md"
[ "$CODEX_INSTALLED" = true ] && echo "   • OpenAI Codex: $CODEX_DIR/instructions.md"

if [ "$CLAUDE_INSTALLED" = false ] && [ "$GEMINI_INSTALLED" = false ] && [ "$CODEX_INSTALLED" = false ]; then
    echo "   ⚠️  No AI CLIs detected"
    echo "   Installing to fallback location: $HOME/.aicraft/agents"
    mkdir -p "$HOME/.aicraft/agents"
    cp agents/*.md "$HOME/.aicraft/agents/"
fi

echo ""
echo "🚀 Usage:"

if [ "$CLAUDE_INSTALLED" = true ]; then
    echo ""
    echo "  Claude Code:"
    echo "    @dev-agent Phase 1: Analyze my code"
    echo "    @gemini-dev Ask Gemini to check performance"
fi

if [ "$GEMINI_INSTALLED" = true ]; then
    echo ""
    echo "  Gemini CLI:"
    echo "    Set GEMINI_SYSTEM_MD=true in your environment"
    echo "    export GEMINI_SYSTEM_MD=true"
    echo "    Then agents will be available automatically"
fi

if [ "$CODEX_INSTALLED" = true ]; then
    echo ""
    echo "  OpenAI Codex:"
    echo "    Instructions loaded automatically"
    echo "    Agents guide all code generation"
fi

echo ""
echo "Happy coding! 🎉"
