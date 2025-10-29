# AI Craft

Structured workflow prompts and simple agents for software development with Claude and Gemini.

## What's Included

### 📋 Workflow Documentation
Complete 5-phase development workflows for Claude AI.
[View Claude Workflows →](./claude/)

### 🤖 Simple Agents
Markdown-based agents you can use with `@` in Claude Code:
- **@dev-agent** - 5-phase development workflow
- **@tdd-agent** - Test-Driven Development (Red-Green-Refactor)
- **@gemini-dev** - Use Gemini for performance & large codebases
- **@gemini-data** - Use Gemini for data analysis & logs
- **@code-review-agent** - Code review and security checks

[View Agents →](./agents/)

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/ai-craft.git
cd ai-craft
```

### Step 2: Run the Installer

```bash
chmod +x install.sh
./install.sh
```

The installer automatically detects which AI CLIs you have installed and configures them:

**Detects and installs for:**
- **Claude Code** → `~/.claude/agents/` (if Claude Code is installed)
- **Gemini CLI** → `~/.gemini/system.md` (if Gemini CLI is installed)
- **OpenAI Codex** → `~/.codex/instructions.md` (if Codex is installed)

**No AI CLIs detected?** The installer will create `~/.aicraft/agents/` as a fallback.

### Step 3: Verify Installation

**For Claude Code:**
```bash
# List installed agents
ls ~/.claude/agents/

# You should see:
# code-review-agent.md
# dev-agent.md
# gemini-data.md
# gemini-dev.md
# git-workflow-agent.md
# inter-ai-communication.md
# tdd-agent.md
```

**For Gemini CLI:**
```bash
# Check system.md was created
cat ~/.gemini/system.md | head -10
```

**For OpenAI Codex:**
```bash
# Check instructions.md was created
cat ~/.codex/instructions.md | head -10
```

## Usage

### Claude Code

Use agents with the `@` symbol:

```
@dev-agent Phase 1: Analyze my authentication system
@tdd-agent RED: Write a failing test for login
@gemini-dev Ask Gemini to check performance of src/api/
@code-review-agent Review my code
@git-workflow-agent What changes do I have that haven't been pushed?
```

### Gemini CLI

Enable system instructions:

```bash
export GEMINI_SYSTEM_MD=true
gemini  # Agents loaded automatically
```

Or set in your shell profile (`~/.bashrc` or `~/.zshrc`):
```bash
echo 'export GEMINI_SYSTEM_MD=true' >> ~/.bashrc
source ~/.bashrc
```

### OpenAI Codex

Instructions are automatically loaded:

```bash
codex  # Agents guide all code generation
```

## Claude + Gemini Together

**Claude** is great for: Code writing, architecture, detailed reasoning
**Gemini** is great for: Performance analysis, large files, data patterns

Use them together:
1. Claude analyzes and plans
2. Gemini checks performance and data
3. Claude implements the solution
4. Both review from different angles

Simple and powerful!

## Multi-Platform Support

AI Craft agents work across all major AI CLIs:
- ✓ Claude Code (via @ references)
- ✓ Gemini CLI (via system instructions)
- ✓ OpenAI Codex (via global instructions)

One install command works for all!
