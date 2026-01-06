# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

AI Craft provides structured workflow prompts and simple markdown agents for software development. Work with Claude for code implementation, Gemini for performance analysis and large data processing, and OpenAI Codex for guided code generation.

## Repository Structure

This repository contains simple markdown agents for multiple AI platforms:

- `agents/` - **Simple markdown agents** for multiple AI platforms
  - `dev-agent.md` - Application Development agent
  - `tdd-agent.md` - Test-Driven Development agent
  - `gemini-dev.md` - Gemini development agent
  - `gemini-data.md` - Gemini data analysis agent
  - `code-review-agent.md` - Code Review agent
  - `content-review-agent.md` - Content humanization agent
  - `git-workflow-agent.md` - Git workflow agent
  - `inter-ai-communication.md` - Inter-AI communication patterns
  - `README.md` - Agent usage guide
- `install.sh` / `install.ps1` - Multi-platform installation scripts (Linux/macOS/Windows)
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

6. **Content Review Agent** (`@content-review-agent`)
   - Review and humanize AI-generated content
   - Remove AI writing patterns and banned phrases
   - File: `agents/content-review-agent.md`

### Platform Differences

**Important:** Each platform handles agents differently.

| Platform     | Agent Syntax  | How It Works                                 |
| ------------ | ------------- | -------------------------------------------- |
| Claude Code  | `@agent-name` | Reference agents directly in prompts         |
| Gemini CLI   | No `@` syntax | Agents auto-loaded as context from GEMINI.md |
| OpenAI Codex | No `@` syntax | Agents auto-loaded as context from AGENTS.md |

**Gemini CLI Usage:**

Gemini doesn't support `@agent` references. Instead, agents are automatically loaded as context. Just describe what you want:

```
# Instead of "@dev-agent Phase 1: Analyze my code"
# Just say:
"Analyze my authentication code using the 5-phase development workflow"

# Instead of "@content-review-agent Review this post"
# Just say:
"Review this LinkedIn post for AI patterns and humanize it"
```

Gemini reads the context from `~/.gemini/GEMINI.md` and applies the relevant agent guidance automatically.

### Multi-Platform Installation

One command installs for all AI platforms:

```bash
# Auto-detects Claude Code, Gemini CLI, OpenAI Codex
./install.sh
```

**Installation Paths (Auto-detected):**

- **Claude Code**: `~/.claude/agents/*.md` (for @ references)
- **Gemini CLI**: `~/.gemini/GEMINI.md` (automatically loaded context file)
- **OpenAI Codex**: `~/.codex/AGENTS.md` (automatically loaded context file)

**How It Works:**

- Script detects which AI CLIs are installed
- Copies agents to appropriate location for each platform
- Formats correctly for each platform's requirements
- Falls back to `~/.aicraft/agents/` if no CLIs detected

**Installation Behavior:**

- Running `install.sh` overwrites existing agent files
- Automatic backups created before overwriting (timestamped)
- Safe to run multiple times
- Previous installations backed up to `.backup.<timestamp>` directories

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
gemini
# Agents automatically loaded from ~/.gemini/GEMINI.md - no configuration needed
```

#### In OpenAI Codex

```bash
codex
# Agents automatically loaded from ~/.codex/AGENTS.md - no configuration needed
# Note: @ syntax not supported - just describe what you want
# Example: "Analyze my code using the 5-phase development workflow"
```

### Working with Agents

#### Creating Custom Agents

Just create a markdown file:

```bash
# For Claude Code
nano ~/.claude/agents/my-agent.md

# For Gemini CLI
# Add to ~/.gemini/GEMINI.md

# For OpenAI Codex
# Add to ~/.codex/AGENTS.md
```

Structure it like the existing agents:

- Purpose section
- When to use
- How to use
- Examples

Then reference it in Claude Code: `@my-agent Do something`
(Note: Gemini CLI and Codex don't support @ syntax - just describe what you want)

### Key Files

- `agents/dev-agent.md` - Development workflow agent (5-phase)
- `agents/tdd-agent.md` - TDD workflow agent (Red-Green-Refactor)
- `agents/gemini-dev.md` - Gemini development agent (performance & large codebases)
- `agents/gemini-data.md` - Gemini data analysis agent (logs & patterns)
- `agents/code-review-agent.md` - Code review agent (security & quality)
- `agents/content-review-agent.md` - Content review agent (humanize AI writing)
- `agents/git-workflow-agent.md` - Git workflow agent (review, commit, push)
- `agents/inter-ai-communication.md` - Inter-AI communication patterns
- `agents/README.md` - Overview and examples
- `install.sh` / `install.ps1` - Multi-platform installation scripts
- `lib/colors.sh` - Shared color library

## Integration with AI Platforms

### Claude Code (Primary)

**Agent-Based (Recommended):**

- Reference with `@` in Claude Code
- No setup required - just run `./install.sh` or `./install.ps1`
- Works with Claude, Gemini, and OpenAI Codex
- Simple, non-technical approach
- Easy to customize and extend (fork the repo for custom changes)

### Gemini CLI

**Context Files (GEMINI.md):**

- Agents consolidated into `~/.gemini/GEMINI.md`
- Automatically loaded - no environment variables needed
- Available in all Gemini CLI conversations
- Automatically applied as context

### OpenAI Codex

**Context Files (AGENTS.md):**

- Agents consolidated into `~/.codex/AGENTS.md`
- Automatically loaded - no environment variables needed
- Available in all Codex CLI conversations
- Automatically applied as context
- Note: @ syntax not supported - describe what you want naturally

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
cat ~/.gemini/GEMINI.md

# Verify OpenAI Codex installation
cat ~/.codex/AGENTS.md
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
