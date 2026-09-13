# Changelog

All notable changes to this project are recorded here.

The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-09-12

### Added

- `zs-cmp-deploy-agent`. Deploys a platform release through a GitOps controller and verifies the rollout. It carries the end to end flow as ordered gates: establish the published commit and digests, check the contract between the API and its clients, check whether the deployment configuration is behind the application, check migration and rollback compatibility, pin digests, sync with the options passed explicitly, watch the migration hook, verify the rollout against running workload digests, confirm preserved configuration survived the sync, and verify end to end by response body rather than status code.
- This agent definition is public, so it holds no environment specific information at all. No repository names, document paths, hostnames, cluster or namespace names, application identifiers, instance identifiers, Secret names, registry names, service inventory or incident narratives. Its first action is to locate and read the organisation's internal deploy runbook, which owns every concrete value, and it is told to ask rather than guess anything it cannot find there. A published agent definition is the wrong place for deploy topology, and a stale copy of an environment detail is worse than no copy.
- The deploy agent has two modes. It defaults to preparing changes and handing them to the engineer with no Git write of any kind. Given an explicit autonomous grant that names the environments, the repositories and whether merging is included, it publishes through the GitHub API rather than local Git, so the engineer's index and working tree stay untouched either way. Autonomy covers publication only, every gate still has to pass, and self merging into a staging or production environment needs that environment named explicitly plus a passing required check suite.

## [2.1.1] - 2026-09-12

### Changed

- `/zs-ticket-updates` keeps ticket bodies and status comments concise and acceptance-criteria-focused. It links to authoritative GitHub or source-controlled evidence instead of duplicating technical details.

## [2.1.0] - 2026-09-09

### Added

- `/zs-ticket-updates` skill. Updates GitHub and NorthStar items with required metadata and evidence-based completion. It requires explicit engineer authorization before changing project state.

## [2.0.0] - 2026-09-03

This release breaks every existing installation. Read [Migrating to 2.0.0](#migrating-to-200) before upgrading.

Two things happened. The agents in this repository were never registered as agents by any CLI, because they had no YAML frontmatter, so `@dev-agent` and the rest resolved to nothing. That is fixed. On top of that, the repository now ships the four agent workflow: an orchestrator that plans and delegates, an implementation agent, and two review agents that run in parallel and feed findings back.

### Added

- `/zs-orchestrate` skill. The four agent loop. Plans and scopes the work, delegates implementation, runs both reviewers in parallel, triages the findings, and iterates. Stops after three rounds or when a finding survives two rounds.
- `/zs-self-review` skill. Reviews your own diff before you ask a colleague. Runs both reviewers, runs the repository gates, checks references, and reports what to fix before pushing.
- `/zs-verify-references` skill. Collects every URL, package, version pin, endpoint, CLI flag, configuration key, and identifier a change introduces, and confirms each one exists and says what the code claims.
- `zs-code-agent`. Implementation agent. Reads the repository first, matches existing conventions, runs lint, build, and tests, then reports what it changed, what it assumed, and what it could not verify.
- `zs-context-review-agent`. Second reviewer, running alongside the code reviewer. Covers requirements coverage, completeness across callers and docs and config, and external reference verification.
- Codex subagents in `codex/agents/*.toml`, installed to `~/.codex/agents/`. The 1.0.0 installer treated that directory as a mistake and moved the whole thing aside on every run, which would have clobbered the TOMLs on the second install. That blanket migration is replaced by one that retires only the specific files an older installer left there. Four agents with their models and sandbox settings already set. The reviewers run with `sandbox_mode = "read-only"`.
- Claude Code plugin packaging. `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` make the repository installable with `/plugin marketplace add zsoftly/ai-craft`.
- Skills install for all three CLIs. `~/.claude/skills/` for Claude Code, and `~/.agents/skills/` for Gemini CLI and Codex, which is the shared path from the Agent Skills standard.
- Native Gemini CLI subagents. The installer writes `~/.gemini/agents/*.md` in addition to the `GEMINI.md` context block.
- `--skip-claude` on `install.sh` and `-SkipClaude` on `install.ps1`, for engineers who installed the plugin and do not want a second copy in `~/.claude`.
- `docs/workflow.md`. The loop, the self review expectation, reference verification, ownership, and a script for demonstrating the workflow.
- `docs/agents-and-skills.md`. What agents, skills, commands, and plugins are, how each CLI spells them, the model mapping, and the naming rules. Every reference in it was fetched and checked on 2026-09-03.

### Changed

- Every agent and skill is prefixed `zs-`. Bundled skills take generic names, and a same named personal or project skill silently replaces the bundled one. See [Migrating to 2.0.0](#migrating-to-200) for the full name mapping.
- Every agent file now carries YAML frontmatter with `name` and `description`, which is what makes it register as a subagent. All three review agents omit `Edit` and `Write` from `tools`, so they can no longer modify what they review.
- `zs-content-review-agent` reports rewrites instead of applying them. In 1.0.0 it edited prose directly. It now quotes each sentence it flags and gives the replacement, and the caller decides what to take. This matches the other two reviewers and the Codex definition, which was already read only.
- Every reviewer now establishes the full change: committed, staged, unstaged, and untracked. The previous instructions used `git diff origin/HEAD...HEAD`, which shows no untracked files at all, so a newly added file could pass review without anyone reading it.
- A reference the reviewer could not confirm is reported once, under `UNVERIFIED REFERENCES`, which blocks the change the same way `CRITICAL` does. It was previously told to file the same reference under both.
- Models are set per agent. Review and deep analysis on `opus` and `gpt-5.6-sol`, implementation on `sonnet` and `gpt-5.6-terra`, content review on `sonnet` and `gpt-5.6-luna`. The orchestrator takes the session model.
- `zs-code-review-agent` now establishes the diff itself with git before reviewing, reports findings without editing, and treats an unverified external reference as a Critical finding.
- Invocation syntax in all documentation moved from the bare `@name` to `@agent-zs-name`, which is the form Claude Code actually accepts for a subagent.
- `install.sh` and `install.ps1` validate frontmatter rather than checking for a leading markdown heading, which the previous check would have failed on every file in this release. Both tolerate CRLF checkouts, which Git for Windows produces by default.
- The Gemini and Codex context blocks are built from the frontmatter description rather than by slicing lines 3 and 4 of each file.
- The `~/.codex/AGENTS.md` section is now headed "Workflow Guidance" and each entry is "Guidance: <name>", and it names the four spawnable subagents and three skills explicitly. Codex was reading the thirteen guidance sections as thirteen spawnable agents and reporting them as such.
- Agent and skill copies written for Gemini and Codex carry only `name` and `description`. Claude specific `tools` and `model` values mean nothing to those CLIs, and Codex validates frontmatter keys strictly.
- `CLAUDE.md` and `README.md` rewritten for the current structure.
- `package.json` version raised to 2.0.0 to match the plugin manifest.

### Fixed

- Agents were never registered as agents. Files in `~/.claude/agents/` require YAML frontmatter with `name` and `description`, and none of them had it, so every one of them sat inert on disk. This is why `@dev-agent` appeared to do nothing useful and why the agents felt unreliable.
- Documentation instructed the bare `@dev-agent` form. In Claude Code a bare `@` is a file reference, not an agent invocation, so the instruction could not have worked even with valid frontmatter.
- `install.sh` warned on any file not starting with `#`, which frontmatter does not.

### Migrating to 2.0.0

Nothing is deleted. The installer moves the eleven 1.0.0 filenames into a timestamped sibling folder:

- `~/.claude/agents.aicraft-legacy.<ts>/`
- `~/.gemini/aicraft-agents.aicraft-legacy.<ts>/`
- `~/.codex/agents.aicraft-legacy.<ts>/`, which also takes the `.codexignore` an installer up to 1bf896a wrote there

Those are the only directories a released installer wrote to, and only those names are touched. A file with YAML frontmatter is never retired, because 1.0.0 shipped none, so a file of that name carrying frontmatter is yours. Delete the folders once you have confirmed the new install works.

`--skip-claude` still retires the 1.0.0 files in `~/.claude/agents`. It skips the install, not the cleanup, because leaving them would keep them registered alongside the plugin.

Upgrade:

```bash
cd ai-craft
git pull
./install.sh
```

Then start a new Claude, Gemini, or Codex session. Running sessions keep the old context.

If you use the Claude Code plugin instead, install it and skip the Claude half of the installer so you do not end up with two copies:

```
/plugin marketplace add zsoftly/ai-craft
/plugin install ai-craft@zsoftly
```

```bash
./install.sh --skip-claude
```

Name mapping. Every agent and skill gained a `zs-` prefix:

| Before                    | After                              |
| :------------------------ | :--------------------------------- |
| `@code-review-agent`      | `@agent-zs-code-review-agent`      |
| `@content-review-agent`   | `@agent-zs-content-review-agent`   |
| `@dev-agent`              | `@agent-zs-dev-agent`              |
| `@tdd-agent`              | `@agent-zs-tdd-agent`              |
| `@git-workflow-agent`     | `@agent-zs-git-workflow-agent`     |
| `@gemini-dev`             | `@agent-zs-gemini-dev`             |
| `@gemini-data`            | `@agent-zs-gemini-data`            |
| `@inter-ai-communication` | `@agent-zs-inter-ai-communication` |
| `@sniff`                  | `@agent-zs-sniff`                  |
| `@dig`                    | `@agent-zs-dig`                    |
| `@wag`                    | `@agent-zs-wag`                    |

Agent filenames gained the same prefix, so `agents/dev-agent.md` is now `agents/zs-dev-agent.md`.

If you forked this repository, the rename touches four places: the `agents/` filenames, the `name:` field inside each agent, the `skills/` directory names, and the `name` key in `codex/agents/*.toml`. Add any name you retire to `LEGACY_AGENT_FILES` in both installers so existing machines get the old copy moved aside.

### Known limitations

- Reviewer agents cannot write on Claude Code (no `Edit` or `Write` in `tools`) or on Codex (`sandbox_mode = "read-only"`). On Gemini CLI they inherit the default tool set and can write, because the portable copy carries only `name` and `description`. The instruction in the agent body is the only control there. Treat a Gemini review as advisory.
- `install.ps1` has not been executed against a real Windows host in this release. It was reviewed by reading, and PowerShell is not available on the machine the work was done on.

### Notes on models

`gpt-5.4` and `gpt-5.4-mini` retire from Codex on 31 August 2026. Any saved Codex configuration, custom agent, or scheduled task still naming them needs updating. `gpt-5.5` remains available but is previous generation, and OpenAI describes `gpt-5.6-terra` as competitive with it at lower cost.

## [1.0.0]

Initial set of markdown workflow prompts for Claude, Gemini CLI, and OpenAI Codex, with `install.sh` and `install.ps1`. See the git history for detail. No releases were tagged.
