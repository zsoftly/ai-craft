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

### Linux / macOS

#### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/ai-craft.git
cd ai-craft
```

#### Step 2: Run the Installer

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

#### Step 3: Verify Installation

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

### Windows (PowerShell)

#### Step 1: Clone the Repository

```powershell
git clone https://github.com/yourusername/ai-craft.git
cd ai-craft
```

#### Step 2: Run the PowerShell Installer

```powershell
# Run the PowerShell installer
.\install.ps1
```

The installer automatically detects which AI CLIs you have installed and configures them:

**Detects and installs for:**
- **Claude Code** → `%USERPROFILE%\.claude\agents\` (if Claude Code is installed)
- **Gemini CLI** → `%USERPROFILE%\.gemini\system.md` (if Gemini CLI is installed)
- **OpenAI Codex** → `%USERPROFILE%\.codex\instructions.md` (if Codex is installed)

**No AI CLIs detected?** The installer will create `%USERPROFILE%\.aicraft\agents\` as a fallback.

**Note:** If you encounter an execution policy error, you may need to allow script execution:

```powershell
# Allow scripts for current session only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Then run the installer
.\install.ps1
```

#### Step 3: Verify Installation

**For Claude Code:**
```powershell
# List installed agents
Get-ChildItem "$env:USERPROFILE\.claude\agents\"

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
```powershell
# Check system.md was created
Get-Content "$env:USERPROFILE\.gemini\system.md" | Select-Object -First 10
```

**For OpenAI Codex:**
```powershell
# Check instructions.md was created
Get-Content "$env:USERPROFILE\.codex\instructions.md" | Select-Object -First 10
```

## Updating Agents

### Linux / macOS

When agents are updated in the repository, use the smart update script:

```bash
chmod +x update.sh
./update.sh
```

**Smart Features:**
- ✓ Detects custom modifications you made to agents
- ✓ Offers options: Overwrite, Keep, Diff, or Merge
- ✓ Creates automatic backups before overwriting
- ✓ Shows differences between versions
- ✓ Opens diff viewer for manual merging

**Update Options:**
1. **Overwrite** - Replace with new version (backup created automatically)
2. **Keep** - Keep your custom version
3. **Diff** - View differences between versions
4. **Merge** - Manual merge using your editor (VS Code, vim, nano)
5. **Abort** - Cancel update

### Windows (PowerShell)

```powershell
.\update.ps1
```

Same smart features as Linux/macOS version!

**Update Options:**
- Automatic backup creation
- Diff viewing with VS Code or Notepad
- Manual merge support
- Safe rollback with backups

### When to Update

Run the update script when:
- You pull latest changes from the repository
- New agent features are released
- Bug fixes or improvements are available

The update script will safely handle your custom modifications.

**Note for WSL Users:** Use the Linux/macOS update script (`./update.sh`) instead of the PowerShell version.

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
