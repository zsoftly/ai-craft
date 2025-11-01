# AI Craft

Structured workflow prompts and simple agents for software development with Claude, Gemini, and OpenAI Codex. 

### Prerequisites

**System Requirements:**
- **Shell**: Bash 3.0+ or Zsh
- **Operating Systems**: Linux, macOS, WSL2, Git Bash (Windows)
- **Note**: This installer uses bashisms and is not POSIX sh compatible

**Optional:**
- Claude Code CLI (for `@` agent references)
- Gemini CLI (for automatic agent context loading)
- OpenAI Codex CLI (for global instructions)

If no AI CLIs are detected, agents will be installed to `~/.aicraft/agents/` as a fallback.

### Linux / macOS

#### Step 1: Clone the Repository

```bash
git clone https://github.com/zsoftly/ai-craft.git
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
- **Gemini CLI** → `~/.gemini/GEMINI.md` (if Gemini CLI is installed)
- **OpenAI Codex** → `~/.codex/agents/` (if Codex is installed)

**No AI CLIs detected?** The installer will create `~/.aicraft/agents/` as a fallback.

**Installation Behavior:**
- Running `install.sh` **overwrites** existing agent files
- **Automatic backups** are created before overwriting (timestamped)
- Safe to run multiple times - your previous installation is always backed up
- Backups are stored in the same directory with `.backup.<timestamp>` suffix

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
# Check GEMINI.md was created
cat ~/.gemini/GEMINI.md | head -10
```

**For OpenAI Codex:**
```bash
# List installed agents
ls ~/.codex/agents/
```

### Windows (PowerShell)

#### Step 1: Clone the Repository

```powershell
git clone https://github.com/zsoftly/ai-craft.git
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
- **Gemini CLI** → `%USERPROFILE%\.gemini\GEMINI.md` (if Gemini CLI is installed)
- **OpenAI Codex** → `%USERPROFILE%\.codex\agents\` (if Codex is installed)

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
# Check GEMINI.md was created
Get-Content "$env:USERPROFILE\.gemini\GEMINI.md" | Select-Object -First 10
```

**For OpenAI Codex:**
```powershell
# List installed agents
Get-ChildItem "$env:USERPROFILE\.codex\agents\"
```

## Updating Agents

When agents are updated in the repository, simply re-run the installation script:

### Linux / macOS / WSL

```bash
git pull
./install.sh
```

### Windows (PowerShell)

```powershell
git pull
.\install.ps1
```

**Installation Behavior:**
- Overwrites all existing agent files with latest versions
- Creates automatic backups before overwriting (timestamped in `.backup.*` directories)
- Safe to run multiple times

### Customizing Agents

**Don't modify installed agents directly.** Instead:

1. **Fork the repository** and modify agents in your fork
2. Install from your fork: `git clone https://github.com/YOUR_USERNAME/ai-craft.git`
3. **Contribute improvements**: Open a pull request to share your enhancements with the community

This approach keeps your customizations version-controlled and makes it easy to pull upstream updates.

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

Agents are automatically loaded from `~/.gemini/GEMINI.md`:

```bash
gemini  # Agents loaded automatically - no configuration needed
```

### OpenAI Codex

Instructions are automatically loaded:

```bash
codex  # Agents guide all code generation
```

## Using Multiple AIs Together

**Claude** is great for: Code writing, architecture, detailed reasoning
**Gemini** is great for: Performance analysis, large files, data patterns
**OpenAI Codex** is great for: Guided code generation, structured workflows

Use them together:
1. Claude analyzes and plans
2. Gemini checks performance and data
3. Codex generates code following agent workflows
4. All three review from different angles

Simple and powerful!

## Multi-Platform Support

AI Craft agents work across all major AI CLIs:
- ✓ Claude Code (via @ references)
- ✓ Gemini CLI (via system instructions)
- ✓ OpenAI Codex (via global instructions)

One install command works for all!
