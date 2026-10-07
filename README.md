# AI Craft

The ZSoftly engineering workflow for AI assisted development. Agents and skills for Claude Code, Gemini CLI, and OpenAI Codex.

## What this gives you

An engineering loop, not a prompt box. One orchestrator plans and delegates, an implementation agent writes the code, and two review agents check it in parallel from different angles. Findings go back through implementation until the change stands up.

```
/zs-orchestrate add rate limiting to the login endpoint
/zs-self-review                 # before every push, on every change
/zs-verify-references           # every link, package, and endpoint the change introduced
/zs-ticket-updates              # create or update a ZSoftly engineering ticket
/zs-agent-comms                 # coordinate an already-running Claude or Codex peer
```

Read [docs/workflow.md](docs/workflow.md) for how the loop runs and what is expected of you inside it. Read [docs/agents-and-skills.md](docs/agents-and-skills.md) if you are unclear on what an agent is versus a skill.

## Contributor setup

Install the repository's formatting dependency with pnpm, then run the check:

```bash
pnpm install --frozen-lockfile
pnpm run fmt:check
```

## Install

### Claude Code, using the plugin

Versioned, namespaced, and updated with one command. This is the recommended path.

```
/plugin marketplace add zsoftly/ai-craft
/plugin install ai-craft@zsoftly
```

Skills arrive as `/ai-craft:zs-orchestrate`, `/ai-craft:zs-self-review`,
`/ai-craft:zs-verify-references`, `/ai-craft:zs-ticket-updates`, and
`/ai-craft:zs-agent-comms`. Agents
arrive as `ai-craft:zs-code-review-agent` and so on. Update with
`/plugin update ai-craft@zsoftly`.

To put it on every engineer's machine automatically, commit this to a repository's `.claude/settings.json`. Claude Code applies it once the engineer trusts the folder.

```json
{
  "extraKnownMarketplaces": {
    "zsoftly": {
      "source": {
        "source": "github",
        "repo": "zsoftly/ai-craft"
      }
    }
  },
  "enabledPlugins": {
    "ai-craft@zsoftly": true
  }
}
```

### Gemini CLI and OpenAI Codex, using the installer

The installer also covers Claude Code for anyone who prefers files in `~/.claude` over the plugin. Do not use both for Claude Code on the same machine, or you get two copies of every agent. Pass `--skip-claude` when the plugin is already installed.

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

- **Claude Code** → `~/.claude/agents/` and `~/.claude/skills/`
- **Gemini CLI** → `~/.gemini/agents/` and `~/.gemini/GEMINI.md`
- **OpenAI Codex** → `~/.codex/agents/` and `~/.codex/AGENTS.md`
- **Gemini CLI and Codex, shared** → `~/.agents/skills/`, the Agent Skills standard location

**No AI CLIs detected?** The installer will create `~/.aicraft/agents/` as a fallback.

**Installation Behavior:**

- Running `install.sh` **overwrites** existing agent files
- **Automatic backups** are created before overwriting (timestamped)
- Safe to run multiple times - your previous installation is always backed up
- Backups are stored in the same directory with `.backup.<timestamp>` suffix
- Already-open Claude, Gemini, or Codex windows may keep their old context.
  Start a new AI CLI session after reinstalling to load updated agents.

#### Step 3: Verify Installation

**For Claude Code:**

```bash
# List installed agents
ls ~/.claude/agents/

# You should see:
# zs-cmp-deploy-agent.md
# zs-code-agent.md
# zs-code-review-agent.md
# zs-content-review-agent.md
# zs-context-review-agent.md
# zs-dev-agent.md
# zs-dig.md
# zs-gemini-data.md
# zs-gemini-dev.md
# zs-git-workflow-agent.md
# zs-inter-ai-communication.md
# zs-sniff.md
# zs-tdd-agent.md
# zs-wag.md

# And the skills:
ls ~/.claude/skills/
# zs-orchestrate
# zs-self-review
# zs-verify-references
# zs-ticket-updates
# zs-agent-comms
```

**For Gemini CLI:**

```bash
# Check GEMINI.md was created
cat ~/.gemini/GEMINI.md | head -10
```

**For OpenAI Codex:**

```bash
# List installed subagents
ls ~/.codex/agents/
# zs-code-agent.toml
# zs-code-review-agent.toml
# zs-content-review-agent.toml
# zs-context-review-agent.toml

# List installed skills
ls ~/.agents/skills/

# View the always on guidance
cat ~/.codex/AGENTS.md | head -20
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

- **Claude Code** → `%USERPROFILE%\.claude\agents\` and `%USERPROFILE%\.claude\skills\`
- **Gemini CLI** → `%USERPROFILE%\.gemini\agents\` and `%USERPROFILE%\.gemini\GEMINI.md`
- **OpenAI Codex** → `%USERPROFILE%\.codex\agents\` and `%USERPROFILE%\.codex\AGENTS.md`
- **Gemini CLI and Codex, shared** → `%USERPROFILE%\.agents\skills\`

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
# zs-code-agent.md
# zs-code-review-agent.md
# zs-content-review-agent.md
# zs-context-review-agent.md
# zs-dev-agent.md
# zs-dig.md
# zs-gemini-data.md
# zs-gemini-dev.md
# zs-git-workflow-agent.md
# zs-inter-ai-communication.md
# zs-sniff.md
# zs-tdd-agent.md
# zs-wag.md

# And the skills:
Get-ChildItem "$env:USERPROFILE\.claude\skills\"
```

**For Gemini CLI:**

```powershell
# Check GEMINI.md was created
Get-Content "$env:USERPROFILE\.gemini\GEMINI.md" | Select-Object -First 10
```

**For OpenAI Codex:**

```powershell
# List installed subagents and skills
Get-ChildItem "$env:USERPROFILE\.codex\agents\"
Get-ChildItem "$env:USERPROFILE\.agents\skills\"

# View the always on guidance
Get-Content "$env:USERPROFILE\.codex\AGENTS.md" | Select-Object -First 20
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

- Overwrites existing agent files for Claude; updates only the managed section for Gemini and Codex
- Creates automatic backups before overwriting (timestamped in `.backup.*` directories)
- Safe to run multiple times
- Start a new Claude, Gemini, or Codex session after reinstalling. Current
  windows usually do not reload global agent files mid-session.

### Customizing Agents

**Don't modify installed agents directly.** Instead:

1. **Fork the repository** and modify agents in your fork
2. Install from your fork:
   `git clone https://github.com/YOUR_USERNAME/ai-craft.git`
3. **Contribute improvements**: Open a pull request to share your enhancements with the community

This approach keeps your customizations version-controlled and makes it easy to pull upstream updates.

## Usage

### Claude Code

Skills are invoked with `/`, agents with `@agent-`. With the plugin installed both carry the `ai-craft:` prefix.

```
/zs-orchestrate add rate limiting to the login endpoint
/zs-self-review
/zs-verify-references
/zs-ticket-updates create an engineering Story in NorthStar

@agent-zs-code-review-agent review the changes on this branch
@agent-zs-context-review-agent check this change against the ticket description
@agent-zs-content-review-agent review the README changes
@agent-zs-tdd-agent write a failing test for login
@agent-zs-sniff [paste job posting]
```

Claude Code loads agents and skills when the session starts. If you install while Claude is already open, start a new session before relying on the updated files.

### Gemini CLI

Subagents install to `~/.gemini/agents/` and are directed with `@<name>`. Skills install to `~/.agents/skills/`, and `~/.gemini/GEMINI.md` carries the always on context.

```bash
gemini
# @zs-code-review-agent review the changes on this branch
# /skills list
```

### OpenAI Codex

Codex has all three pieces. Subagents are TOML files in `~/.codex/agents/`, skills live in `~/.agents/skills/` and are invoked with `$<name>`, and `~/.codex/AGENTS.md` carries the always on guidance.

Codex does not spawn subagents on its own, so delegation is explicit. Name the agent in the prompt.

```bash
codex
# $zs-orchestrate add rate limiting to the login endpoint
# $zs-self-review
# $zs-ticket-updates update issue #123 with verified deployment evidence
# Spawn zs-code-review-agent and zs-context-review-agent on this branch in parallel
# /agent          inspect and switch between running threads
```

The four workflow agents ship with their models already set: `gpt-5.6-terra` for implementation, `gpt-5.6-sol` for both reviewers, `gpt-5.6-luna` for content review. The reviewers also set `sandbox_mode = "read-only"`, which is how they are prevented from editing what they review. Change any of it in `~/.codex/agents/*.toml`.

## Using Multiple AIs Together

Each CLI is stronger at different work.

- **Claude**: code writing, architecture, multi step reasoning, orchestration
- **Gemini**: very large codebases, performance analysis, log and data patterns
- **Codex**: parallel subagent fan out with per agent model and sandbox settings

The `zs-gemini-dev` and `zs-gemini-data` agents support Gemini analysis. Use `zs-agent-comms` when an already-running Claude or Codex peer needs a verified native handoff. `zs-inter-ai-communication` remains the agent entry point for that skill.

Running the same change past two model families is a real second opinion, and worth it when the change is risky.

## Multi-Platform Support

Agents and skills work across all three CLIs:

- Claude Code: subagents in `~/.claude/agents/`, skills in `~/.claude/skills/`, or the plugin
- Gemini CLI: subagents in `~/.gemini/agents/`, skills in `~/.agents/skills/`
- OpenAI Codex: subagents in `~/.codex/agents/`, skills in `~/.agents/skills/`, guidance in `~/.codex/AGENTS.md`

One install command covers all three. See [docs/agents-and-skills.md](docs/agents-and-skills.md) for what each location means.

## Skill Reference

Invoked with `/name`, or `/ai-craft:name` when installed as a plugin.

| Skill                  | Purpose                                                                  |
| ---------------------- | ------------------------------------------------------------------------ |
| `zs-orchestrate`       | The four agent loop: plan, implement, review in parallel, iterate        |
| `zs-self-review`       | Review your own diff before asking a colleague. Run before every push    |
| `zs-verify-references` | Confirm every link, package, endpoint, and version the change introduced |
| `zs-ticket-updates`    | Create or update ZSoftly engineering tickets and NorthStar metadata      |
| `zs-agent-comms`       | Coordinate an already-running Claude or Codex peer session               |

## Agent Reference

Invoked with `@agent-name`, or delegated to automatically.

| Agent                       | Model   | Purpose                                                       |
| --------------------------- | ------- | ------------------------------------------------------------- |
| `zs-code-agent`             | sonnet  | Implements a scoped change and reports what it did            |
| `zs-code-review-agent`      | opus    | Bugs, security, and correctness of the code itself            |
| `zs-context-review-agent`   | opus    | Requirements coverage, completeness, docs, reference checking |
| `zs-content-review-agent`   | sonnet  | Reports AI writing patterns in prose, with rewrites           |
| `zs-dev-agent`              | inherit | Five phase development workflow                               |
| `zs-tdd-agent`              | inherit | Test driven development, red green refactor                   |
| `zs-git-workflow-agent`     | inherit | Inspect changes, commit and push with your own git identity   |
| `zs-gemini-dev`             | inherit | Delegate development and performance work to Gemini           |
| `zs-gemini-data`            | inherit | Delegate log and dataset analysis to Gemini                   |
| `zs-inter-ai-communication` | inherit | Routes Claude and Codex peer messaging to `zs-agent-comms`    |
| `zs-sniff`                  | sonnet  | Fast opportunity screen against the ZSoftly ICP               |
| `zs-dig`                    | opus    | Deep bid or no bid and partner fit analysis                   |
| `zs-wag`                    | inherit | Proposal and outreach drafting aligned to the ICP             |

## Naming

Everything this repository ships is prefixed `zs-`. That keeps it clear of the skills Claude Code, Gemini CLI, and Codex bundle themselves, which take generic names such as `/verify`, `/loop`, `/batch`, and `/code-review`. A skill that shares a name with a bundled one silently replaces it, and that is a bad surprise to hand an engineer.

The prefix also means one name works everywhere. `/zs-orchestrate` is what you type whether the plugin installed it or the installer did, because a plugin skill is reachable by its bare name as long as nothing else has claimed it. `/ai-craft:zs-orchestrate` stays available as the collision proof form.

Installing over a 1.0.0 install moves the eleven old filenames into a timestamped sibling folder rather than deleting them, and touches nothing else. The full name mapping is in [CHANGELOG.md](CHANGELOG.md#migrating-to-200).

If you fork this for another org, change the prefix in the `agents/` filenames and `name:` fields, the `skills/` directory names, and the `name` field in `codex/agents/*.toml`.

## Documentation

- [docs/workflow.md](docs/workflow.md): the four agent loop, self review, and what ownership means
- [docs/agents-and-skills.md](docs/agents-and-skills.md): agents, skills, commands, and plugins across the three CLIs
- [docs/agents-overview.md](docs/agents-overview.md): what each agent does, with examples
- [docs/GLOSSARY.md](docs/GLOSSARY.md): terms used across the agents
- [CHANGELOG.md](CHANGELOG.md): what changed in each release, and how to migrate
