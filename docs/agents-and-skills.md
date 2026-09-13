# Agents, Skills, Commands, and Plugins

Every AI CLI now uses the same four concepts under slightly different names. Getting them straight is most of what people are missing when they say the agents "do not work".

Everything below was checked against vendor documentation on 2026-09-03. The links are in [References](#references).

## The four concepts

| Concept       | What it is                                                                                              | Where it lives for Claude Code                | How you use it                                               |
| :------------ | :------------------------------------------------------------------------------------------------------ | :-------------------------------------------- | :----------------------------------------------------------- |
| Subagent      | A worker with its own context window, model, and tool set. You delegate to it and it reports back.      | `agents/<name>.md`                            | `@agent-<name> do the thing`, or Claude delegates on its own |
| Skill         | A procedure loaded on demand. Runs in the current session unless it says otherwise.                     | `skills/<name>/SKILL.md`                      | `/<name> arguments`, or Claude loads it when relevant        |
| Slash command | The old name for a user invoked skill. Merged into skills.                                              | `commands/<name>.md` still works              | `/<name>`                                                    |
| Plugin        | The packaging and distribution unit. Bundles agents, skills, hooks, and MCP servers, and versions them. | `.claude-plugin/plugin.json` at the repo root | `/plugin install ai-craft@zsoftly`                           |

The short version: a **skill** is a procedure you or the model runs here, and an **agent** is a worker you hand a job to and get a report from.

## Shipped skills

| Skill                   | Use it for                                          |
| :---------------------- | :-------------------------------------------------- |
| `/zs-orchestrate`       | Running the implementation and review loop          |
| `/zs-self-review`       | Reviewing your own change before push               |
| `/zs-verify-references` | Verifying references a change introduces            |
| `/zs-ticket-updates`    | Explicit GitHub issue and NorthStar project changes |

## The mistake this repository used to make

Before this revision, every file in `agents/` was plain markdown with no YAML frontmatter. Claude Code only registers a file in `~/.claude/agents/` as a subagent when it opens with frontmatter carrying `name` and `description`. Without it, the file sits on disk and nothing loads it. `@dev-agent` did not invoke an agent, it was a file reference that usually resolved to nothing.

That is why the agents felt unreliable. They were not installed as agents.

Every agent in this repository now opens with real frontmatter:

```yaml
---
name: code-review-agent
description: Reviews a diff, branch, or set of files for bugs, security holes, and quality problems. Use before every push, before asking a colleague for review, and as the code reviewer inside the orchestrate workflow. Reports findings by file and line with severity and never edits code.
tools: Read, Grep, Glob, Bash
model: opus
color: red
---
```

The `description` is not decoration. It is the only thing the main model sees when deciding whether to delegate, so it has to say what the agent does and when to use it.

Omitting `Edit` and `Write` from `tools` is what stops a review agent from silently rewriting your code.

## Choosing between a skill and an agent

Write a **skill** when:

- It is a procedure with steps, and you want to invoke it by name.
- It needs the current conversation, the files you have open, and the state you built up.
- It should be able to ask you something in the middle.

Write an **agent** when:

- It is a bounded job with a clear input and a clear report as output.
- It should not see your conversation, either because the context would bias it or because it would waste it.
- It should run on a different model, or with fewer tools than you have.
- Several of them should run at the same time.

`/zs-orchestrate` drives the session and delegates. `zs-code-review-agent` is
separate so it does not see the reasoning that produced the code. Use
`/zs-ticket-updates` only for an explicit issue or project change.

## The same ideas in the other CLIs

|                   | Claude Code                                               | Gemini CLI                                                 | Codex                                                  |
| :---------------- | :-------------------------------------------------------- | :--------------------------------------------------------- | :----------------------------------------------------- |
| Subagents         | `~/.claude/agents/*.md`, invoke with `@agent-<name>`      | `~/.gemini/agents/*.md`, invoke with `@<name>`             | `~/.codex/agents/*.toml`, name the agent in the prompt |
| Skills            | `~/.claude/skills/<name>/SKILL.md`, invoke with `/<name>` | `~/.agents/skills/` or `~/.gemini/skills/`, `/skills list` | `~/.agents/skills/`, invoke with `$<name>`             |
| Always on context | `CLAUDE.md`                                               | `~/.gemini/GEMINI.md`                                      | `~/.codex/AGENTS.md`                                   |

`~/.agents/skills/` is the path both Gemini CLI and Codex read. The Agent Skills spec does not mandate a location, so this is a convention the clients adopted rather than a requirement of the standard. `install.sh` writes skills there once for both.

Codex subagents are the one place where the format differs sharply. They are TOML, not markdown with frontmatter, and the system prompt goes in a `developer_instructions` key rather than in the file body:

```toml
name = "zs-code-review-agent"
description = "Reviews a diff for bugs, security holes, and quality problems."
model = "gpt-5.6-sol"
model_reasoning_effort = "high"
sandbox_mode = "read-only"
developer_instructions = '''
You are a senior reviewer. You receive a change and you report findings.
'''
```

`sandbox_mode = "read-only"` is how a Codex reviewer is stopped from editing the code it reviews. It is the equivalent of leaving `Edit` and `Write` out of a Claude agent's `tools` list.

Codex does not delegate on its own. Name the agent in the prompt, for example "spawn the zs-code-review-agent on this branch". `/agent` inspects and switches between running threads. Because each subagent runs its own model and tools, a fan out costs more tokens than a single pass.

These live in `codex/agents/*.toml` in this repository, and the installer copies them to `~/.codex/agents/`. They carry the same instructions as the matching markdown agents, so a change to one needs the same change to the other.

## Models

Model choice is per agent, and it is where the cost of the loop is decided. Orchestration and review want a strong model. Implementation wants a fast one.

| Role           | Claude Code | Codex                                            |
| :------------- | :---------- | :----------------------------------------------- |
| Orchestrator   | `opus`      | `gpt-5.6-sol` or `gpt-5.6-terra` for the session |
| Implementation | `sonnet`    | `gpt-5.6-terra`                                  |
| Code review    | `opus`      | `gpt-5.6-sol`                                    |
| Context review | `opus`      | `gpt-5.6-sol`                                    |
| Content review | `sonnet`    | `gpt-5.6-luna`                                   |

Claude aliases are `opus`, `sonnet`, `haiku`, `fable`, or `inherit` to take the session model. Codex slugs are `gpt-5.6-sol`, `gpt-5.6-terra`, and `gpt-5.6-luna`. `gpt-5.5` is still available but is previous generation, and Terra is described as competitive with it at lower cost. `gpt-5.4` and `gpt-5.4-mini` retire from Codex on 31 August 2026, so any saved configuration still naming them needs updating.

The orchestrator has no model field of its own in either CLI. It runs on whatever model the session is on, so start the session on your strongest one.

## Naming

Everything here is prefixed `zs-`. Bundled skills take generic names: Claude Code ships `/verify`, `/loop`, `/batch`, `/debug`, `/code-review`, and more arrive over time. A personal or project skill that shares a name with a bundled one replaces it silently, and a name you picked last year can be claimed by a vendor next year.

The prefix costs three characters and removes the whole class of problem.

It also gives one name across install paths. A plugin skill is always reachable as `/ai-craft:zs-orchestrate`, and also as the bare `/zs-orchestrate` as long as nothing else claims that name, which the prefix guarantees. So `/zs-orchestrate` works whether the plugin installed it or the installer did.

Prefixing inside the plugin namespace as well would give `/ai-craft:zs-orchestrate`, which looks redundant. It is deliberate. The namespace protects against another plugin, and the prefix protects against the bundled set and against the installer path having no namespace at all.

Frontmatter portability matters here. Claude specific keys such as `tools: Read, Grep` and `model: opus` mean nothing to Gemini or Codex, and Codex validates frontmatter keys strictly. The installer writes a portable copy carrying only `name` and `description` for those CLIs, the two of the spec's six frontmatter fields that are required.

## Known limitation: reviewer write access on Gemini

A review agent must not be able to edit the code it reviews. Two of the three CLIs enforce that:

- Claude Code: the agent omits `Edit` and `Write` from `tools`, so the tools are not there to call. This covers all three reviewers, including `zs-content-review-agent`, which reports rewrites rather than applying them.
- Codex: the agent sets `sandbox_mode = "read-only"`, so the sandbox refuses writes.

Gemini CLI has no equivalent in place today. The portable copy the installer writes carries only `name` and `description`, because Claude tool names are meaningless to Gemini, so a Gemini reviewer inherits the default tool set and can write. The only control there is the instruction in the agent body telling it to report rather than edit, which is a soft control.

Treat a Gemini review as advisory and check the diff afterwards, or run reviews on Claude Code or Codex. Setting Gemini's own `tools` list on the reviewer agents would close this, and it is not done yet because the tool names have not been verified against a working install.

## Distribution

Two ways to get this repository's agents and skills onto a machine.

**Plugin, for Claude Code.** Versioned, namespaced, and updated with one
command. Agents arrive as `ai-craft:zs-code-review-agent`. Skills include
`/ai-craft:zs-orchestrate` and `/ai-craft:zs-ticket-updates`.

```
/plugin marketplace add zsoftly/ai-craft
/plugin install ai-craft@zsoftly
```

**Installer, for Gemini CLI and Codex, and for Claude Code without the plugin.** Copies files into the home directory locations each CLI reads.

```bash
./install.sh
```

Do not use both for Claude Code on the same machine. Two copies of an agent under two names is exactly the kind of confusion this document exists to remove. Run `./install.sh --skip-claude` when the plugin is installed.

## References

Checked 2026-09-03.

- Claude Code subagents: https://code.claude.com/docs/en/sub-agents
- Claude Code skills: https://code.claude.com/docs/en/skills
- Claude Code plugins: https://code.claude.com/docs/en/plugins
- Claude Code plugin marketplaces: https://code.claude.com/docs/en/plugin-marketplaces
- Agent Skills standard: https://agentskills.io
- Gemini CLI subagents: https://geminicli.com/docs/core/subagents/
- Gemini CLI skills: https://geminicli.com/docs/cli/skills/
- Codex skills: https://learn.chatgpt.com/docs/build-skills
- Codex AGENTS.md: https://learn.chatgpt.com/docs/agent-configuration/agents-md
