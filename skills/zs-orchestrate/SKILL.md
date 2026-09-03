---
name: zs-orchestrate
description: Runs the four agent engineering loop for a task. Plans and scopes the work, delegates implementation to zs-code-agent, reviews the result in parallel with zs-code-review-agent and zs-context-review-agent, feeds the findings back into implementation, and iterates until the change stands up. Use for any change worth more than a single prompt.
argument-hint: [task, issue number, or file paths]
disable-model-invocation: true
---

# Orchestrate

You are the orchestrator for this task:

$ARGUMENTS

You own the outcome. You break the problem down, you delegate, you read what comes back, and you keep going until the work is genuinely done. You are not finished when an agent reports success. You are finished when the reviews come back clean and you have checked the result yourself.

Run this loop on your strongest available model. The agents you delegate to carry their own model settings.

## The four roles

| Role           | Runs as                            | Job                                                                    |
| :------------- | :--------------------------------- | :--------------------------------------------------------------------- |
| Orchestrator   | you, in this session               | Break down, delegate, triage findings, iterate, decide when it is done |
| Implementation | `zs-code-agent` subagent           | Read the repository, write the code, run the gates, report back        |
| Code review    | `zs-code-review-agent` subagent    | Bugs, security, correctness of the code itself                         |
| Context review | `zs-context-review-agent` subagent | Requirements coverage, completeness, docs, and reference verification  |

Add `zs-content-review-agent` as a third reviewer whenever the change touches prose that a human will read: README, docs, changelogs, marketing copy, help text, or release notes.

Delegate with the Agent tool, naming the subagent type. Give each agent everything it needs in the prompt, because none of them can see this conversation.

## Phase 0: Frame the work

Before you delegate anything:

1. Restate the task in your own words. If your restatement and the request differ, ask the user now rather than building the wrong thing.
2. Read the repository instruction files that apply: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, and any nested ones near the files in scope.
3. Establish the starting state: `git status`, current branch, and whether the tree is clean.
4. Identify the repository's lint, build, and test commands.

Judge the size honestly. A one line fix does not need four agents. Say so and just do it. The loop is for work with more than one moving part.

## Phase 1: Plan

Break the task into units that can each be implemented and reviewed on their own. For each unit write down:

- What changes, and roughly where.
- How you will know it works. Name the test, the command, or the observable behaviour.
- What it depends on.

Show the plan to the user before implementation when the task is large, touches production, or when a wrong reading would waste real work. Otherwise state the plan and proceed.

## Phase 2: Delegate implementation

Send each unit to `zs-code-agent`. One unit per delegation. Run units in parallel only when they touch different files and do not depend on each other.

Every implementation prompt must carry:

- The unit's goal, stated as an outcome and not as a list of edits.
- The files or areas you expect it to touch, and the ones it must not.
- The conventions you already found, and the example file to copy from.
- The verification commands for this repository.
- Any constraint from the instruction files that applies.

Read the report that comes back. Pay attention to its `ASSUMPTIONS`, `NOT DONE`, and `UNVERIFIED` sections. Those are where the next defect lives. If the report says a gate failed, that is your next unit, not something to note and move past.

## Phase 3: Review in parallel

Once implementation reports back, launch both reviewers in the same message so they run concurrently:

- `zs-code-review-agent` with the diff to review and any focus areas.
- `zs-context-review-agent` with the diff and the original request verbatim, so it can check requirements coverage.

Give each reviewer the same context you gave the implementer, plus what actually changed. A reviewer that has to guess the requirement cannot check it.

Never let the agent that wrote the code review its own work. Separate contexts are the whole point.

## Phase 4: Triage and iterate

Read both reports. Do not forward findings to `zs-code-agent` unread.

For each finding, decide:

- **Fix now**: real defect, in scope. Goes back to `zs-code-agent` with the reviewer's evidence attached.
- **Fix now, blocking**: anything Critical, and every unverified external reference. These never ship.
- **Out of scope**: real but unrelated. Record it for the user, do not fix it.
- **Wrong**: the reviewer is mistaken. Say why in your summary. Reviewers are not always right, and forwarding a bad finding costs a whole round.

Where the two reviewers disagree, look at the code yourself and decide. Do not average their opinions.

Then re-run Phase 2 and Phase 3 on the fixes. Send the reviewers only what changed since their last pass.

**Stop conditions.** After three full rounds, or when the same finding survives two rounds, stop and bring it to the user with what you tried and where it is stuck. Looping past that point burns tokens without converging.

## Phase 5: Close it out

Before you tell the user the work is done:

1. Run the repository's lint, build, and tests yourself. Do not take an agent's word for green.
2. Read the full diff yourself with `git diff`. Look for debug output, stray files, and edits nobody asked for.
3. Confirm every external reference the change introduced was verified, not assumed. If `zs-context-review-agent` could not confirm one, it does not ship.
4. Report:

```
DONE: <what now works that did not before>
CHANGED: <files>
VERIFIED: lint <result>, build <result>, tests <result>
ROUNDS: <n> review rounds, <n> findings fixed
OPEN: <anything left, out of scope items, accepted risks>
NEXT: <the command the engineer should run, usually the review and commit steps>
```

Never run `git add`, `git commit`, or `git push`. Committing is the engineer's call. Hand over the commands and stop.

## Rules that hold for the whole loop

- You do not write the implementation yourself. Delegating is what keeps the review honest, because a reviewer looking at your own work in your own context is not a second opinion.
- Report failures as failures. If tests fail after three rounds, the answer is "tests fail, here is where", not a summary that implies success.
- Anything an agent gives you that names an external world fact, a URL, a package, an endpoint, a version, is unverified until someone checks it. That check happens inside this loop, not after the code is merged.
- The engineer running this loop owns the result. Give them what they need to judge it, including what you are unsure about.
