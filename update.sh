#!/bin/bash

# AI Craft Agents Update Script
# Smart update that detects custom modifications and offers merge options

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

print_header "AI Craft Agents - Smart Update"
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
FALLBACK_DIR="$HOME/.aicraft/agents"

# Detect which CLIs have agents installed
CLAUDE_INSTALLED=false
GEMINI_INSTALLED=false
CODEX_INSTALLED=false
FALLBACK_INSTALLED=false

if [ -d "$CLAUDE_DIR" ] && ls "$CLAUDE_DIR"/*.md &> /dev/null; then
    CLAUDE_INSTALLED=true
fi

if [ -d "$GEMINI_DIR" ] && ls "$GEMINI_DIR"/*.md &> /dev/null; then
    GEMINI_INSTALLED=true
fi

if [ -d "$CODEX_DIR" ] && [ -f "$CODEX_DIR/instructions.md" ]; then
    CODEX_INSTALLED=true
fi

if [ -d "$FALLBACK_DIR" ] && ls "$FALLBACK_DIR"/*.md &> /dev/null; then
    FALLBACK_INSTALLED=true
fi

# Check if any installation exists
if [ "$CLAUDE_INSTALLED" = false ] && [ "$GEMINI_INSTALLED" = false ] && [ "$CODEX_INSTALLED" = false ] && [ "$FALLBACK_INSTALLED" = false ]; then
    print_warning "[INFO] No existing installation found."
    echo "Please run ./install.sh first to install agents."
    exit 0
fi

print_info "[Detected Installations]"
[ "$CLAUDE_INSTALLED" = true ] && echo "   - Claude Code: $CLAUDE_DIR"
[ "$GEMINI_INSTALLED" = true ] && echo "   - Gemini CLI: $GEMINI_DIR"
[ "$CODEX_INSTALLED" = true ] && echo "   - OpenAI Codex: $CODEX_DIR"
[ "$FALLBACK_INSTALLED" = true ] && echo "   - Fallback: $FALLBACK_DIR"
echo ""

# Function to check if file has been modified by user
file_has_custom_changes() {
    local source_file="$1"
    local installed_file="$2"

    if [ ! -f "$installed_file" ]; then
        return 1  # File doesn't exist, no custom changes
    fi

    # Compare files
    if diff -q "$source_file" "$installed_file" &> /dev/null; then
        return 1  # Files are identical, no custom changes
    else
        return 0  # Files differ, user has custom changes
    fi
}

# Function to create backup
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"

    if cp "$file" "$backup" 2>/dev/null; then
        print_success "   [BACKUP] Created: $backup"
        return 0
    else
        print_error "   [ERROR] Failed to create backup"
        return 1
    fi
}

# Function to show diff between files
show_diff() {
    local source_file="$1"
    local installed_file="$2"

    echo ""
    print_header "--- Differences ---"
    diff -u "$installed_file" "$source_file" | head -50
    echo ""
}

# Function to prompt user for action
prompt_user_action() {
    local agent_name="$1"
    local source_file="$2"
    local installed_file="$3"

    echo ""
    print_warning "[CUSTOM CHANGES DETECTED] $agent_name"
    echo "The installed version has been modified since installation."
    echo ""
    echo "Options:"
    echo -e "  1) ${GREEN}Overwrite${NC} - Replace with new version (backup created)"
    echo -e "  2) ${BLUE}Keep${NC} - Keep your custom version"
    echo -e "  3) ${CYAN}Diff${NC} - Show differences"
    echo -e "  4) ${YELLOW}Merge${NC} - Manual merge (opens in editor)"
    echo -e "  5) ${RED}Abort${NC} - Stop update process"
    echo ""

    while true; do
        read -p "Choose action [1-5]: " choice
        case $choice in
            1)
                backup_file "$installed_file" || return 1
                if cp "$source_file" "$installed_file" 2>/dev/null; then
                    print_success "   [OK] Overwritten with new version"
                    return 0
                else
                    print_error "   [ERROR] Failed to overwrite"
                    return 1
                fi
                ;;
            2)
                print_info "   [SKIP] Keeping your custom version"
                return 0
                ;;
            3)
                show_diff "$source_file" "$installed_file"
                # Ask again after showing diff
                continue
                ;;
            4)
                backup_file "$installed_file" || return 1
                print_header "   [MERGE] Opening editor for manual merge..."

                # Detect available editor
                if command -v code &> /dev/null; then
                    code --diff "$installed_file" "$source_file" --wait
                elif command -v vim &> /dev/null; then
                    vimdiff "$installed_file" "$source_file"
                elif command -v nano &> /dev/null; then
                    echo "Opening files in nano (edit and save as needed)"
                    nano "$installed_file"
                else
                    print_error "   [ERROR] No editor found. Please merge manually."
                    echo "   Installed: $installed_file"
                    echo "   New version: $source_file"
                fi

                print_success "   [OK] Manual merge completed"
                return 0
                ;;
            5)
                print_error "[ABORT] Update cancelled by user"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter 1-5."
                ;;
        esac
    done
}

# Function to update agents in a directory
update_agents() {
    local target_dir="$1"
    local agent_type="$2"

    echo ""
    print_info "[Updating $agent_type]"

    local modified_count=0
    local updated_count=0
    local skipped_count=0

    for source_agent in agents/*.md; do
        if [ -f "$source_agent" ]; then
            agent_name=$(basename "$source_agent")
            installed_agent="$target_dir/$agent_name"

            if file_has_custom_changes "$source_agent" "$installed_agent"; then
                modified_count=$((modified_count + 1))
                prompt_user_action "$agent_name" "$source_agent" "$installed_agent"
                result=$?
                if [ $result -eq 0 ]; then
                    updated_count=$((updated_count + 1))
                else
                    skipped_count=$((skipped_count + 1))
                fi
            else
                # No custom changes, safe to update
                if cp "$source_agent" "$installed_agent" 2>/dev/null; then
                    print_success "   [OK] Updated: $agent_name"
                    updated_count=$((updated_count + 1))
                else
                    print_error "   [ERROR] Failed to update: $agent_name"
                    skipped_count=$((skipped_count + 1))
                fi
            fi
        fi
    done

    echo ""
    print_header "[$agent_type Summary]"
    echo "   Updated: $updated_count"
    [ $modified_count -gt 0 ] && echo "   Custom changes detected: $modified_count"
    [ $skipped_count -gt 0 ] && echo "   Skipped: $skipped_count"
}

# Update Claude Code agents
if [ "$CLAUDE_INSTALLED" = true ]; then
    update_agents "$CLAUDE_DIR" "Claude Code"
fi

# Update Gemini CLI agents
if [ "$GEMINI_INSTALLED" = true ]; then
    update_agents "$GEMINI_DIR" "Gemini CLI"

    # Also update system.md if needed
    if [ -f "$GEMINI_DIR/system.md" ]; then
        echo ""
        print_info "[Checking Gemini system.md]"

        # Regenerate system.md
        temp_system_md=$(mktemp)
        cat > "$temp_system_md" << 'EOF'
# AI Craft Agents for Gemini

You have access to structured workflow agents. When the user references an agent with @, provide guidance based on these workflows:

## Available Agents

EOF

        for agent in agents/*.md; do
            if [ -f "$agent" ]; then
                agent_name=$(basename "$agent" .md)
                echo "### @$agent_name" >> "$temp_system_md"
                # Extract first header section (up to 10 lines) or use fallback
                head -20 "$agent" | grep -A 5 "^##" | head -10 >> "$temp_system_md" 2>/dev/null || \
                    echo "Agent documentation" >> "$temp_system_md"
                echo "" >> "$temp_system_md"
            fi
        done

        # Check if system.md has custom changes
        if file_has_custom_changes "$temp_system_md" "$GEMINI_DIR/system.md"; then
            prompt_user_action "system.md" "$temp_system_md" "$GEMINI_DIR/system.md"
        else
            cp "$temp_system_md" "$GEMINI_DIR/system.md"
            print_success "   [OK] Updated system.md"
        fi

        rm -f "$temp_system_md"
    fi
fi

# Update OpenAI Codex agents
if [ "$CODEX_INSTALLED" = true ]; then
    update_agents "$CODEX_DIR" "OpenAI Codex"

    # Regenerate instructions.md
    if [ -f "$CODEX_DIR/instructions.md" ]; then
        echo ""
        print_info "[Checking Codex instructions.md]"

        temp_instructions=$(mktemp)
        cat > "$temp_instructions" << 'EOF'
# AI Craft Development Agents

Follow these structured workflows when developing:

EOF

        for agent in agents/dev-agent.md agents/tdd-agent.md agents/code-review-agent.md; do
            if [ -f "$agent" ]; then
                cat "$agent" >> "$temp_instructions" 2>/dev/null
                echo -e "\n---\n" >> "$temp_instructions"
            fi
        done

        if file_has_custom_changes "$temp_instructions" "$CODEX_DIR/instructions.md"; then
            prompt_user_action "instructions.md" "$temp_instructions" "$CODEX_DIR/instructions.md"
        else
            cp "$temp_instructions" "$CODEX_DIR/instructions.md"
            print_success "   [OK] Updated instructions.md"
        fi

        rm -f "$temp_instructions"
    fi
fi

# Update fallback installation
if [ "$FALLBACK_INSTALLED" = true ]; then
    update_agents "$FALLBACK_DIR" "Fallback Location"
fi

echo ""
print_success "[OK] Update complete!"
echo ""

# Show backup locations if any were created
if ls ~/.claude/agents/*.backup.* &> /dev/null 2>&1 || \
   ls ~/.gemini/*.backup.* &> /dev/null 2>&1 || \
   ls ~/.codex/*.backup.* &> /dev/null 2>&1 || \
   ls ~/.aicraft/agents/*.backup.* &> /dev/null 2>&1; then
    print_header "[Backups Created]"
    echo "Your custom versions have been backed up with .backup.TIMESTAMP extension"
    echo "You can restore them anytime if needed."
    echo ""
fi

print_header "[USAGE]"
echo "All agents are now updated. Continue using them as before:"
echo "  @dev-agent Phase 1: Analyze my code"
echo "  @gemini-dev Ask Gemini to check performance"
echo ""
print_success "Happy coding!"
