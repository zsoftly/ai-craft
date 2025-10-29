# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

AI Craft provides structured workflow prompts and simple markdown agents for software development. Work with Claude for code implementation and Gemini for performance analysis and large data processing.

## Repository Structure

This repository contains simple markdown agents for multiple AI platforms:

- `agents/` - **Simple markdown agents** for multiple AI platforms
  - `dev-agent.md` - Application Development agent
  - `tdd-agent.md` - Test-Driven Development agent
  - `gemini-dev.md` - Gemini development agent
  - `gemini-data.md` - Gemini data analysis agent
  - `code-review-agent.md` - Code Review agent
  - `git-workflow-agent.md` - Git workflow agent
  - `inter-ai-communication.md` - Inter-AI communication patterns
  - `README.md` - Agent usage guide
- `install.sh` / `install.ps1` - Multi-platform installation scripts (Linux/macOS/Windows)
- `update.sh` / `update.ps1` - Smart update scripts with custom change detection
- `lib/colors.sh` - Shared color library for bash scripts

## Core Architecture: Agent-Based Workflows

All agents follow structured workflows designed to enforce separation between analysis, planning, implementation, validation, and deployment:

### Agent Philosophy

Each agent provides:
- **Purpose** - Clear use case definition
- **When to use** - Context for when this agent applies
- **Instructions** - Specific directives formatted as structured workflows
- **Key principles**:
  - Analysis phases explicitly separate thinking from coding
  - Implementation phases enforce quality gates (lint, compile, test after each block)
  - Review phases prevent over-engineering for pre-customer stage
  - Final phases handle deployment and team handoff
  - Sub-agent delegation for heavy analysis work (context optimization)

## Common Patterns Across Agents

### Quality Gates
Implementation phases consistently enforce:
- Lint and compile after every code block
- Write tests for each code block
- Run tests before proceeding to next block

### Anti-Over-Engineering
Final phases include checks for:
- Unnecessary complexity for pre-customer stage
- Excessive abstraction or interfaces
- Unnecessary fallbacks, versioning, or testing overkill
- Backwards compatibility (only add when explicitly requested)

### Code Review Format
When reviewing code, use this specific format:
- File name
- Line number (or search words if line numbers unavailable)
- Issue description (short)
- Why it's likely incorrect
- Recommended fix (only if simple)

### Context Optimization
For large codebases or complex analysis, agents use Claude's Task tool to spawn `general-purpose` sub-agents to:
- Search through entire codebase efficiently
- Analyze multiple files and dependencies
- Return comprehensive findings
- Save main conversation context for implementation

## Working with This Repository

### Making Changes to Agents

When modifying agent documents:
1. Maintain the structured workflow formatting
2. Keep instructions as concise bullet points
3. Preserve the "When to use" and "Purpose" sections
4. Ensure consistency with other agents
5. Include anti-over-engineering guidance in final phases
6. Add context optimization for analysis-heavy phases

### Creating New Agents

New agents should:
1. Follow structured workflow patterns
2. Include separation between analysis and implementation phases
3. Add quality gates in implementation phases
4. Include anti-over-engineering checks in final phases
5. Use consistent formatting with existing agents
6. Include sub-agent delegation where beneficial

### Documentation Standards

- Use markdown format with clear headers
- Include code blocks with triple backticks for multi-line instructions
- Keep bullet points concise and actionable
- Use bold for phase names and key terms
- Maintain consistent terminology across agents
- Never use emojis in generated code (only in conversational responses)

## Simple Markdown Agents

AI Craft includes simple markdown-based agents that can be referenced with `@` in Claude Code. No complex setup - just markdown files.

### Available Agents

Simple markdown files you reference with `@`:

1. **Development Agent** (`@dev-agent`)
   - 5-phase workflow: Analysis → Plan Review → Implementation → Code Review → PR
   - Built-in quality gates and over-engineering checks
   - File: `agents/dev-agent.md`

2. **TDD Agent** (`@tdd-agent`)
   - Red-Green-Refactor cycle
   - Test-first development guidance
   - File: `agents/tdd-agent.md`

3. **Gemini Dev Agent** (`@gemini-dev`)
   - Use latest Gemini model for performance analysis
   - Handle large codebases (massive context window)
   - File: `agents/gemini-dev.md`

4. **Gemini Data Agent** (`@gemini-data`)
   - Use latest Gemini for log analysis, data patterns
   - Process large datasets and CSV files
   - File: `agents/gemini-data.md`

5. **Code Review Agent** (`@code-review-agent`)
   - Git-based code review
   - Security and quality checks
   - File: `agents/code-review-agent.md`

### Multi-Platform Installation

One command installs for all AI platforms:

```bash
# Auto-detects Claude Code, Gemini CLI, OpenAI Codex
./install.sh
```

**Installation Paths (Auto-detected):**
- **Claude Code**: `~/.claude/agents/*.md` (for @ references)
- **Gemini CLI**: `~/.gemini/system.md` (custom system instructions)
- **OpenAI Codex**: `~/.codex/instructions.md` (global instructions)

**How It Works:**
- Script detects which AI CLIs are installed
- Copies agents to appropriate location for each platform
- Formats correctly for each platform's requirements
- Falls back to `~/.aicraft/agents/` if no CLIs detected

No dependencies, no Docker, no npm. Just markdown files.

### Usage Examples

#### In Claude Code (You!)

```
@dev-agent Phase 1: Analyze my authentication system

[Claude analyzes the code]

@dev-agent Phase 3: Implement OAuth with Google
```

#### Using Gemini for Performance

```
@gemini-dev Ask Gemini to analyze performance of src/api/

[Gemini analyzes with massive context]

@dev-agent Implement Gemini's optimization suggestions
```

#### Combined Workflow

```
@dev-agent Phase 1: Analyze payment system

Can you ask Gemini to check for performance issues?

@dev-agent Phase 3: Implement with performance fixes
```

#### In Gemini CLI

```bash
export GEMINI_SYSTEM_MD=true
gemini
# Agents automatically available via system instructions
```

#### In OpenAI Codex

```bash
codex
# Global instructions automatically applied to all generations
```

### Working with Agents

#### Creating Custom Agents

Just create a markdown file:

```bash
# For Claude Code
nano ~/.claude/agents/my-agent.md

# For Gemini CLI
# Add to ~/.gemini/system.md

# For OpenAI Codex
# Add to ~/.codex/instructions.md
```

Structure it like the existing agents:
- Purpose section
- When to use
- How to use
- Examples

Then reference it: `@my-agent Do something`

### Key Files

- `agents/dev-agent.md` - Development workflow agent (5-phase)
- `agents/tdd-agent.md` - TDD workflow agent (Red-Green-Refactor)
- `agents/gemini-dev.md` - Gemini development agent (performance & large codebases)
- `agents/gemini-data.md` - Gemini data analysis agent (logs & patterns)
- `agents/code-review-agent.md` - Code review agent (security & quality)
- `agents/git-workflow-agent.md` - Git workflow agent (review, commit, push)
- `agents/inter-ai-communication.md` - Inter-AI communication patterns
- `agents/README.md` - Overview and examples
- `install.sh` / `install.ps1` - Multi-platform installation scripts
- `update.sh` / `update.ps1` - Smart update scripts
- `lib/colors.sh` - Shared color library

## Integration with AI Platforms

### Claude Code (Primary)

**Agent-Based (Recommended):**
- Reference with `@` in Claude Code
- No setup required - just run `./install.sh` or `./install.ps1`
- Claude + Gemini working together
- Simple, non-technical approach
- Easy to customize and extend
- Smart update system preserves customizations

### Gemini CLI

**System Instructions:**
- Agents consolidated into `~/.gemini/system.md`
- Set `GEMINI_SYSTEM_MD=true` to enable
- Available in all Gemini CLI conversations
- Automatically applied as context

### OpenAI Codex

**Global Instructions:**
- Development agents combined into `~/.codex/instructions.md`
- Automatically loaded for all code generations
- Guides Codex to follow structured workflows
- No per-session setup needed

### Cross-Platform Benefits

✅ One installation works for all platforms
✅ Consistent workflows across different AIs
✅ Each platform gets appropriately formatted content
✅ Simple markdown files - easy to version control
✅ No complex dependencies or setup

## Development Commands

No build commands needed - just markdown files!

### Testing Installation

```bash
# Run installer
./install.sh

# Verify Claude Code installation
ls ~/.claude/agents/

# Verify Gemini CLI installation
cat ~/.gemini/system.md

# Verify OpenAI Codex installation
cat ~/.codex/instructions.md
```

### Making Changes

```bash
# Edit an agent
nano agents/dev-agent.md

# Reinstall to update
./install.sh

# Changes take effect immediately
```
- update the memory