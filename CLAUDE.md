# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repository is

AI Craft is ZSoftly's engineering workflow for AI assisted development, packaged for Claude Code, Gemini CLI, and OpenAI Codex. It ships subagents, skills, and the installer and plugin manifests that put them on an engineer's machine.

It contains no application code. Everything here is markdown that other tools load, plus two installer scripts.

## Layout

```
agents/                       subagent definitions, one file per agent
skills/<name>/SKILL.md        skills, invoked with /<name>
.claude-plugin/plugin.json    plugin manifest, the repo root is the plugin root
.claude-plugin/marketplace.json  marketplace manifest, source is "./"
install.sh, install.ps1       installers for Claude, Gemini, and Codex
lib/colors.sh                 shared bash colour helpers
docs/                         workflow and reference documentation
```

## The workflow this repository defines

Four roles. The orchestrator runs in the main session and delegates the rest.

| Role           | Runs as                            | Claude and Gemini                   | Codex                                       |
| :------------- | :--------------------------------- | :---------------------------------- | :------------------------------------------ |
| Orchestrator   | `/zs-orchestrate` skill            | `skills/zs-orchestrate/SKILL.md`    | same file, installed to `~/.agents/skills/` |
| Implementation | `zs-code-agent` subagent           | `agents/zs-code-agent.md`           | `codex/agents/zs-code-agent.toml`           |
| Code review    | `zs-code-review-agent` subagent    | `agents/zs-code-review-agent.md`    | `codex/agents/zs-code-review-agent.toml`    |
| Context review | `zs-context-review-agent` subagent | `agents/zs-context-review-agent.md` | `codex/agents/zs-context-review-agent.toml` |

`/zs-self-review` runs the two reviewers over the engineer's own diff before a push. `/zs-verify-references` checks every external reference a change introduces.

Full description in `docs/workflow.md`. The distinction between agents and skills, and how the three CLIs each spell it, is in `docs/agents-and-skills.md`.

## Rules for changing this repository

### Every agent file needs frontmatter

Claude Code registers a file in an `agents/` directory as a subagent only when it opens with YAML frontmatter carrying `name` and `description`. A file without it is inert. This was the single biggest defect in the previous revision of this repository.

```yaml
---
name: agent-name
description: What it does and when to delegate to it. This text is the only thing the main model sees when deciding whether to use the agent.
tools: Read, Grep, Glob, Bash
model: opus
color: red
---
```

- `description` decides delegation. Write it as "does X, use it when Y", not as a title.
- Omit `Edit` and `Write` from `tools` for any agent that must not change code. Every review agent depends on this.
- Set `model` only when there is a reason: `opus` for review and deep analysis, `sonnet` for fast implementation and pattern work, otherwise leave it out and inherit the session model.
- Avoid `: ` inside an unquoted description. It breaks the YAML parse.

### Everything is prefixed zs-

Agent `name` fields, agent filenames, skill directory names, and the `name` key in the Codex TOML all start with `zs-`. This keeps the repository clear of bundled skills, which take generic names and grow over time, and it makes the bare `/zs-orchestrate` form work identically whether the plugin or the installer put it there.

Agent names accept lowercase letters and hyphens only, so the prefix is `zs-` and not `zs_`.

When you add anything, prefix it. When you rename anything, add the old name to `LEGACY_AGENT_FILES` in both installers, and only add a directory to the retire list if a released installer actually wrote to it. Retiring into a sibling folder matters, because Claude Code scans `~/.claude/agents` recursively.

### Codex agents mirror the markdown agents

`codex/agents/*.toml` carries the same instructions as the matching `agents/zs-*.md`, in a `developer_instructions` key rather than the file body. A change to one needs the same change to the other. This is the only duplication in the repository, and it exists because Codex takes TOML while Claude and Gemini take markdown frontmatter.

Verified Codex keys: `name`, `description`, and `developer_instructions` are required. `model`, `model_reasoning_effort`, and `sandbox_mode` are optional. Use `sandbox_mode = "read-only"` for every review agent, which is the Codex equivalent of leaving `Edit` and `Write` out of a Claude agent's `tools`. Do not add a key you have not confirmed in the Codex documentation.

Model slugs: `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna`.

### Every skill needs a directory

A skill is `skills/<name>/SKILL.md`. The directory name becomes the command. Set `disable-model-invocation: true` on skills that should only run when a person types them, which is the right default for workflows that spend real tokens.

### Keep frontmatter portable

Gemini and Codex do not understand Claude's `tools` and `model` values, and Codex validates frontmatter keys strictly. The installers write a copy carrying only `name` and `description` for those CLIs. Do not add a field that the installer would have to special case unless it earns its place.

### Validate before shipping

```bash
python3 -c "import tomllib,glob;[tomllib.load(open(f,'rb')) for f in glob.glob('codex/agents/*.toml')]"
claude plugin validate .              # plugin and marketplace manifests
claude --plugin-dir . --model haiku -p "list the agent types available to you"
bash -n install.sh                    # installer syntax
HOME=/tmp/aicraft-test ./install.sh   # installer against a throwaway home
npm run fmt:check                     # prettier
```

Never test the installer against your real home directory. It writes into `~/.claude`, `~/.gemini`, `~/.codex`, and `~/.agents`.

### Writing style

- No em dashes. No semicolons in prose. The `zs-content-review-agent` in this repository enforces this and the repository should pass its own check.
- No emojis in generated code or in agent bodies. Emojis in installer console output are already there and are controlled by `--no-emoji`.
- Short sentences. Say what the thing does, then when to use it.
- No hyperbole, no marketing adjectives, no "not just X but Y".

### External references

Every URL in this repository was verified when it was added. The date of the check is recorded next to the reference list in `docs/agents-and-skills.md`. If you add a link, fetch it first and confirm it says what you claim it says. This repository teaches that discipline, so it has to hold itself to it.

### Record the change

Every user visible change goes in `CHANGELOG.md` under the version being prepared, using the Keep a Changelog headings: Added, Changed, Deprecated, Removed, Fixed, Security. A rename or a behaviour change that breaks an existing install also needs a row in the migration table and, if it changes a filename, an entry in `LEGACY_AGENT_FILES` in both installers.

Version numbers follow Semantic Versioning. Keep `package.json` and `.claude-plugin/plugin.json` on the same version, because the plugin manifest version is what decides whether installed copies receive an update.

## Constraints

- Never run `git add`, `git commit`, or `git push` on the user's behalf. Hand over the commands.
- Do not remove an agent or a skill people are using. Add, deprecate in the docs, and remove in a later change.
- The installer overwrites files in the home directory. Keep the backup behaviour that is already there.
