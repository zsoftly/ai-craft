# Autonomous coordination

This page sets up `/zs-agent-comms` so Claude and Codex sessions can message each other in every direction without asking you, and so they still stop for the actions you choose.

The skill never changes these settings. You copy them in yourself. The installer does not write them either, because they decide your security posture.

## How approval works

Each CLI decides on its own whether a command needs you. The skill only shapes the commands so a rule can match them.

| Direction       | Sender runs                     | What must be pre-approved                          |
| :-------------- | :------------------------------ | :------------------------------------------------- |
| Claude to Claude | native `SendMessage`           | `ListAgents` and `SendMessage` in Claude           |
| Codex to Codex   | the skill's `queue.sh`         | a `queue.sh` prefix rule in Codex                  |
| Claude to Codex  | the skill's `queue.sh`         | a `queue.sh` Bash rule in Claude                   |
| Codex to Claude  | the skill's `relay.sh`         | a `relay.sh` prefix rule in Codex                  |

A rule that names one exact command, with the message text inside it, approves that one message only. The next message is a different command, so the CLI asks again. Approve the stable prefix instead.

## Claude

Add this to `~/.claude/settings.json`, merging with what is already there:

```json
{
  "permissions": {
    "allow": [
      "ListAgents",
      "SendMessage",
      "Bash(bash ~/.claude/skills/zs-agent-comms/queue.sh *)"
    ],
    "ask": ["Bash(git push *)", "Bash(gh pr merge *)", "Bash(kubectl apply *)", "Bash(terraform apply *)"]
  },
  "crossSessionInbound": "accept",
  "isolatePeerMachines": true
}
```

- `allow` lets peer messaging run without a prompt. The skill's own `allowed-tools` covers only the turn that loads the skill, so durable approval has to come from settings.
- `ask` lists the actions that must always reach you. Ask rules are checked before allow rules and prompt in every mode, including `bypassPermissions`. Add the commands that matter in your own work.
- `crossSessionInbound: accept` delivers messages from your other sessions without holding them.
- `isolatePeerMachines: true` still asks before a message leaves this machine. Remove it if you message cloud or remote sessions on purpose.

Then pick a permission mode per session:

| Mode                   | Peer messaging | Your `ask` rules | Everything else                      |
| :--------------------- | :------------- | :--------------- | :----------------------------------- |
| `auto` (recommended)   | runs           | prompts you      | reviewed by the auto mode classifier |
| `dontAsk`              | runs           | denied           | denied unless allowed                |
| `default`              | runs           | prompts you      | prompts you                          |

Use `auto` for "never ask me except for these". Use `dontAsk` for unattended runs, where an `ask` rule becomes a hard stop and the agent reports the blocker instead. Avoid `bypassPermissions` for coordinating sessions. When neither side sets `crossSessionInbound`, Claude Code holds messages arriving between a bypassing and a prompting session for your approval.

Bash rules match command prefixes. They are guardrails, not a sandbox. `Bash(git push *)` does not catch `git -C . push`. Use a deny rule or a PreToolUse hook for anything that must never run.

## Codex

Add a rule file such as `~/.codex/rules/zs-agent-comms.rules`. Replace `/Users/you` with your home directory:

```python
prefix_rule(
    pattern = ["bash", ["~/.claude/skills/zs-agent-comms/queue.sh", "/Users/you/.claude/skills/zs-agent-comms/queue.sh"]],
    decision = "allow",
)
prefix_rule(
    pattern = ["bash", ["~/.claude/skills/zs-agent-comms/relay.sh", "/Users/you/.claude/skills/zs-agent-comms/relay.sh"]],
    decision = "allow",
)
```

Check a rule before relying on it:

```bash
codex execpolicy check --rules ~/.codex/rules/zs-agent-comms.rules \
  bash ~/.claude/skills/zs-agent-comms/relay.sh my-session 'test'
```

A match prints `"decision":"allow"`. A command wrapped in `zsh -lc`, or one that uses `$(...)`, does not match. That is why the skill tells agents to send one plain command.

Allow the two scripts, never a bare `codex queue` or `claude` prefix. `codex queue` also accepts `--dangerously-bypass-approvals-and-sandbox`, `-s danger-full-access`, and `-c` overrides, so a rule on `codex queue --thread` would let a sender append them. A rule on `claude -p` would also allow `claude -p --tools Bash`. `queue.sh` passes only the thread and the message. `relay.sh` fixes every Claude flag and limits the relay to `ListAgents` and `SendMessage`.


For approvals outside these rules, `~/.codex/config.toml` decides:

- `approval_policy = "on-request"` with `approvals_reviewer = "auto_review"` sends approval requests to an automatic reviewer instead of to you.
- `approval_policy = "never"` rejects anything that needs approval, which is the Codex equivalent of `dontAsk`.

## Claude orchestrating Codex

1. Start the orchestrator with a name: `claude --name orchestrator`, or run `/rename orchestrator` in a running session.
2. Note each Codex worker's thread UUID or exact name.
3. Ask the orchestrator to run `/zs-agent-comms` with the task for each worker. It sends with `queue.sh` and puts `orchestrator` in `Return destination`.
4. Each worker replies with `relay.sh orchestrator '<result>'`. Its Codex rule lets that run without asking you.
5. The reply arrives in the orchestrator as a cross-session message. With `crossSessionInbound: accept`, it is delivered without a prompt.

Keep the orchestrator out of `bypassPermissions`. In that mode, replies from the relay can be held for your approval.

## When agents stop for you

The skill's "Escalate to the human" section lists what a session must hand back: out of scope work, irreversible or outward facing actions, configuration changes, ownership disputes, loops, and unverified recipients. That list is an instruction the model follows. The `ask` and `deny` rules above are what the CLI enforces. Rely on the rules for anything that would cause harm if the model got it wrong.

## References

Checked 2026-10-06.

- Claude Code skills, `allowed-tools` and `disable-model-invocation`: https://code.claude.com/docs/en/skills
- Claude Code permission rules and precedence: https://code.claude.com/docs/en/permissions
- Claude Code permission modes: https://code.claude.com/docs/en/permission-modes
- Claude Code cross-session messaging, `crossSessionInbound` and `isolatePeerMachines`: https://code.claude.com/docs/en/cross-session-messaging
- Codex configuration reference, `approval_policy` and `approvals_reviewer`: https://learn.chatgpt.com/docs/config-file/config-reference
- Codex rule syntax was confirmed with `codex execpolicy check` on codex-cli 0.160.1.
