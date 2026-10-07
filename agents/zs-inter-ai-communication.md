---
name: zs-inter-ai-communication
description: Coordinates already-running Claude and Codex peer sessions through verified native messages. Use when work, status, or a result must reach a peer without starting duplicate work.
tools: Bash, Read
color: cyan
---

# Inter-AI Communication Agent

Use the current session's verified CLI capabilities. Do not assume a model family, CLI version, or tool availability from this file.

For source and plugin installs, read [zs-agent-comms](../skills/zs-agent-comms/SKILL.md). In an installed agent, prefer the skill path the client catalog provides. Direct Claude installs use `~/.claude/skills/zs-agent-comms/SKILL.md`. Gemini and Codex use `~/.agents/skills/zs-agent-comms/SKILL.md`. The repository-relative link is a source reference only, not a path for embedded Codex or Gemini guidance. The skill defines recipient verification, the transport-only Claude relay, handoff fields, delivery states, and authorisation boundaries.

Do not create, resume, or fork a peer session to deliver a message. This agent coordinates transport only. When native Claude peer tools are unavailable in this wrapper, use the skill's verified capability fallback. Preserve the recipient's standing work and return results to the sender's stated destination.
