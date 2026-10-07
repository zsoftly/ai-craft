#!/bin/bash

# AI Craft Agents Installation Script
# Installs agents to appropriate locations for Claude, Gemini, and OpenAI CLIs

# Exit on error or undefined variables
set -eu

# Parse command line arguments
USE_EMOJI=true
SKIP_CLAUDE=false
for arg in "$@"; do
    case $arg in
        --no-emoji)
            USE_EMOJI=false
            ;;
        --skip-claude)
            SKIP_CLAUDE=true
            ;;
        --help|-h)
            echo "AI Craft Agents Installation Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-emoji     Disable emoji output (use ASCII indicators instead)"
            echo "  --skip-claude  Do not install into ~/.claude (use when you installed the"
            echo "                 ai-craft plugin instead, to avoid two copies of each agent)"
            echo "  --help, -h     Show this help message"
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

# Strip YAML frontmatter from a markdown file
strip_frontmatter() {
    awk '{ sub(/\r$/, "") }
         NR==1 && $0=="---" { infm=1; next }
         infm && $0=="---" { infm=0; next }
         !infm { print }' "$1"
}

# Read one top level field out of YAML frontmatter, empty if absent
fm_field() {
    awk -v key="$2" '
        { sub(/\r$/, "") }
        NR==1 && $0=="---" { infm=1; next }
        infm && $0=="---" { exit }
        infm {
            idx = index($0, ":")
            if (idx > 0 && substr($0, 1, idx - 1) == key) {
                v = substr($0, idx + 1)
                sub(/^[ \t]+/, "", v)
                print v
                exit
            }
        }' "$1"
}

# Filenames this repository shipped in 1.0.0, before the zs- prefix.
# Only these eleven, and only in the two directories the 1.0.0 installer wrote to.
# Anything else under those paths belongs to the user and is left alone.
LEGACY_AGENT_FILES="code-review-agent.md content-review-agent.md dev-agent.md dig.md gemini-data.md gemini-dev.md git-workflow-agent.md inter-ai-communication.md sniff.md tdd-agent.md wag.md"

# Move pre zs- files out of an install directory into a sibling folder.
# A sibling, not a subdirectory, because Claude Code scans ~/.claude/agents
# recursively and would otherwise keep registering what we just retired.
retire_legacy() {
    target_dir="$1"
    extra_files="${2:-}"
    [ -d "$target_dir" ] || return 0

    # A 1.0.0 file carries no frontmatter. If one of these names does have
    # frontmatter it belongs to the user, so leave it where it is.
    is_legacy_file() {
        [ -f "$1" ] || return 1
        [ "$(head -1 "$1" | tr -d '\r')" = "---" ] && return 1
        return 0
    }

    found=""
    for legacy in $LEGACY_AGENT_FILES $extra_files; do
        if is_legacy_file "$target_dir/$legacy"; then
            found="yes"
        fi
    done
    [ -n "$found" ] || return 0

    legacy_dir="$target_dir.aicraft-legacy.$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$legacy_dir"
    for legacy in $LEGACY_AGENT_FILES $extra_files; do
        if is_legacy_file "$target_dir/$legacy"; then
            if ! mv "$target_dir/$legacy" "$legacy_dir/"; then
                print_warning "   [WARN] Could not retire $target_dir/$legacy"
            fi
        fi
    done
    print_info "   [MIGRATION] 1.0.0 files moved to: $legacy_dir"
    return 0
}

# Write a portable SKILL.md or agent file carrying only name and description,
# for CLIs that reject frontmatter keys they do not know
write_portable() {
    src="$1"
    dest="$2"
    fallback_name="$3"
    p_name=$(fm_field "$src" name)
    p_desc=$(fm_field "$src" description)
    [ -n "$p_name" ] || p_name="$fallback_name"
    [ -n "$p_desc" ] || p_desc="AI Craft workflow"
    {
        echo "---"
        echo "name: $p_name"
        echo "description: $p_desc"
        echo "---"
        echo ""
        strip_frontmatter "$src"
    } > "$dest"
}

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

        # Agents must carry YAML frontmatter with name and description,
        # otherwise Claude Code and Gemini CLI will not register them
        if [ "$(head -1 "$agent" | tr -d '\r')" = "---" ]; then
            if [ -z "$(fm_field "$agent" name)" ] || [ -z "$(fm_field "$agent" description)" ]; then
                print_warning "   [WARN] Frontmatter missing name or description: $agent"
                invalid_files=$((invalid_files + 1))
            fi
        elif head -1 "$agent" | grep -q "^#"; then
            print_warning "   [WARN] No YAML frontmatter, will not register as a subagent: $agent"
            invalid_files=$((invalid_files + 1))
        else
            print_warning "   [WARN] File starts with neither frontmatter nor a heading: $agent"
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
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
GEMINI_DIR="$HOME/.gemini"
GEMINI_AGENTS_DIR="$HOME/.gemini/agents"
CODEX_DIR="$HOME/.codex"
CODEX_AGENTS_DIR="$HOME/.codex/agents"
SHARED_SKILLS_DIR="$HOME/.agents/skills"

# Detect which CLIs are available
CLAUDE_INSTALLED=false
GEMINI_INSTALLED=false
CODEX_INSTALLED=false

# Check for Claude Code
if command -v claude &> /dev/null || [ -d "$HOME/.claude" ]; then
    CLAUDE_INSTALLED=true
fi

# Keep the real detection result. The fallback install at the end must not fire
# just because the user asked us to skip the Claude half.
CLAUDE_DETECTED=$CLAUDE_INSTALLED
if [ "$SKIP_CLAUDE" = true ]; then
    CLAUDE_INSTALLED=false
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
    retire_legacy "$CLAUDE_DIR"

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

    # Install invocable skills, including /zs-orchestrate and /zs-ticket-updates.
    if [ -d "skills" ]; then
        mkdir -p "$CLAUDE_SKILLS_DIR"
        for skill_dir in skills/*/; do
            [ -d "$skill_dir" ] || continue
            skill_name=$(basename "$skill_dir")
            if [ ! -f "$skill_dir/SKILL.md" ]; then
                print_warning "   [WARN] Skipping $skill_name, no SKILL.md"
                continue
            fi
            mkdir -p "$CLAUDE_SKILLS_DIR/$skill_name"
            if ! cp -R "$skill_dir." "$CLAUDE_SKILLS_DIR/$skill_name/" 2>/dev/null; then
                print_error "   [ERROR] Failed to copy skill $skill_name"
                exit 1
            fi
        done
        print_success "   [OK] Skills installed to: $CLAUDE_SKILLS_DIR"
    fi
fi

# --skip-claude means do not install into ~/.claude. It does not mean leave a
# directory of 1.0.0 agents registered, which is the state the flag's own user
# is trying to get out of.
if [ "$SKIP_CLAUDE" = true ] && [ "$CLAUDE_DETECTED" = true ]; then
    print_info "[Retiring 1.0.0 files in $CLAUDE_DIR, skipping the install itself...]"
    retire_legacy "$CLAUDE_DIR"
fi

# Install for Gemini CLI
if [ "$GEMINI_INSTALLED" = true ]; then
    CURRENT_STEP="Installing for Gemini CLI"
    INSTALL_STARTED=true

    print_info "[Installing for Gemini CLI...]"

    # Create directories
    mkdir -p "$GEMINI_DIR"
    mkdir -p "$GEMINI_DIR/aicraft-agents"
    retire_legacy "$GEMINI_DIR/aicraft-agents"
    mkdir -p "$GEMINI_AGENTS_DIR"

    # Gemini CLI reads subagents from ~/.gemini/agents/*.md with YAML frontmatter.
    # Claude tool and model names mean nothing to Gemini, so install a portable
    # copy carrying only name and description and let Gemini pick its defaults.
    print_info "   [Installing native Gemini subagents...]"
    for agent in agents/*.md; do
        [ -f "$agent" ] || continue
        agent_basename=$(basename "$agent")
        if [ "$agent_basename" = "README.md" ] || [ "$agent_basename" = "GLOSSARY.md" ]; then
            continue
        fi
        write_portable "$agent" "$GEMINI_AGENTS_DIR/$agent_basename" "$(basename "$agent" .md)"
    done
    print_success "   [OK] Subagents installed to: $GEMINI_AGENTS_DIR"

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
            brief_desc=$(fm_field "$agent" description)
            if [ -z "$brief_desc" ]; then
                brief_desc=$(strip_frontmatter "$agent" | sed -n '3,4p' 2>/dev/null)
            fi
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

    # Codex reads custom subagents from ~/.codex/agents/*.toml. These carry their
    # own model and sandbox settings, which is how the review agents are kept
    # read-only. See https://learn.chatgpt.com/docs/agent-configuration/subagents
    if [ -d "codex/agents" ]; then
        print_info "   [Installing Codex subagents...]"
        mkdir -p "$CODEX_AGENTS_DIR"
        # Installers up to 1bf896a copied the agent markdown plus .codexignore
        # here. Codex parses this directory now, so those files have to go.
        retire_legacy "$CODEX_AGENTS_DIR" ".codexignore"
        for codex_agent in codex/agents/*.toml; do
            [ -f "$codex_agent" ] || continue
            if ! cp "$codex_agent" "$CODEX_AGENTS_DIR/" 2>/dev/null; then
                print_error "   [ERROR] Failed to copy $codex_agent to $CODEX_AGENTS_DIR"
                exit 1
            fi
        done
        print_success "   [OK] Subagents installed to: $CODEX_AGENTS_DIR"
    fi

    # Smart AGENTS.md update: preserve user content, only manage our section
    print_info "   [Updating AGENTS.md...]"

    # Build our managed content section
    CODEX_MANAGED_CONTENT="<!-- AI-CRAFT-AGENTS-START - Do not edit between these markers, content will be updated automatically -->

# AI Craft Workflow Guidance

The sections below are reference documents, not agents you can spawn. Apply the relevant guidance when working on a matching task.

The subagents you can actually spawn are defined in ~/.codex/agents/*.toml:
zs-code-agent, zs-code-review-agent, zs-context-review-agent, zs-content-review-agent.
The skills you can invoke live in ~/.agents/skills/:
zs-orchestrate, zs-self-review, zs-verify-references, zs-ticket-updates, zs-agent-comms.

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
            CODEX_MANAGED_CONTENT+="---"$'\n\n'"### Guidance: $agent_name"$'\n\n'

            # Read full agent content without frontmatter, and drop @ references
            # because Codex has no @agent syntax
            agent_content=$(strip_frontmatter "$agent" | sed 's/@agent-[a-z-]\{1,\}//g' 2>/dev/null)

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

# Install Agent Skills to the shared location
# Both Codex and Gemini CLI read skills from ~/.agents/skills. The Agent Skills
# spec at https://agentskills.io does not mandate a location, this path is the
# convention both CLIs adopted. Install the portable form, carrying only the two
# frontmatter fields the spec requires.
if { [ "$GEMINI_INSTALLED" = true ] || [ "$CODEX_INSTALLED" = true ]; } && [ -d "skills" ]; then
    CURRENT_STEP="Installing shared Agent Skills"
    INSTALL_STARTED=true

    print_info "[Installing Agent Skills to $SHARED_SKILLS_DIR...]"
    mkdir -p "$SHARED_SKILLS_DIR"
    for skill_dir in skills/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name=$(basename "$skill_dir")
        [ -f "$skill_dir/SKILL.md" ] || continue
        mkdir -p "$SHARED_SKILLS_DIR/$skill_name"
        write_portable "$skill_dir/SKILL.md" "$SHARED_SKILLS_DIR/$skill_name/SKILL.md" "$skill_name"
    done
    print_success "   [OK] Skills installed to: $SHARED_SKILLS_DIR"
fi

echo ""
print_success "[OK] Installation complete!"
echo ""

# Summary
print_header "[Installed agents for:]"
[ "$CLAUDE_INSTALLED" = true ] && echo "   - Claude Code: $CLAUDE_DIR and $CLAUDE_SKILLS_DIR"
[ "$GEMINI_INSTALLED" = true ] && echo "   - Gemini CLI: $GEMINI_AGENTS_DIR and $GEMINI_DIR/GEMINI.md"
[ "$CODEX_INSTALLED" = true ] && echo "   - OpenAI Codex: $CODEX_AGENTS_DIR and $CODEX_DIR/AGENTS.md"
if [ "$GEMINI_INSTALLED" = true ] || [ "$CODEX_INSTALLED" = true ]; then
    echo "   - Agent Skills: $SHARED_SKILLS_DIR"
fi

if [ "$CLAUDE_DETECTED" = false ] && [ "$GEMINI_INSTALLED" = false ] && [ "$CODEX_INSTALLED" = false ]; then
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
    echo "    /zs-orchestrate add rate limiting to the login endpoint"
    echo "    /zs-self-review                   (run this before every push)"
    echo "    /zs-verify-references"
    echo "    /zs-ticket-updates create an engineering Story in NorthStar"
    echo "    /zs-agent-comms coordinate work with an existing Codex peer"
    echo "    @agent-zs-code-review-agent review the changes on this branch"
    echo "    @agent-zs-sniff [paste opportunity]"
    echo ""
    echo "    Start a new Claude Code session before expecting these to appear."
fi

if [ "$GEMINI_INSTALLED" = true ]; then
    echo ""
    print_info "  Gemini CLI:"
    echo "    Subagents installed to ~/.gemini/agents/, direct one with @<name>"
    echo "    Example: '@zs-code-review-agent review the changes on this branch'"
    echo "    Skills in ~/.agents/skills/, list them with /skills list"
    echo "    Context also loaded from ~/.gemini/GEMINI.md at session start"
fi

if [ "$CODEX_INSTALLED" = true ]; then
    echo ""
    print_info "  OpenAI Codex:"
    echo "    Skills in ~/.agents/skills/, invoke one with \$<name>"
    echo "    Example: '\$zs-self-review', '\$zs-orchestrate add rate limiting', '\$zs-ticket-updates update issue #123', or '\$zs-agent-comms'"
    echo "    Subagents in ~/.codex/agents/, spawn one by name in your prompt"
    echo "    Example: 'Spawn the zs-code-review-agent to review this branch'"
    echo "    Inspect running threads with /agent"
fi

echo ""
print_info "  After updating agents, start a new AI CLI session/window to load the latest instructions."
echo ""
print_success "Happy coding!"
