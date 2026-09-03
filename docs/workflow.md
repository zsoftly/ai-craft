# The AI Craft Workflow

This is the workflow every engineer is expected to use, and the one to demonstrate when asked to show how you work with AI.

The expectation is not one prompt and accept the answer. It is an engineering loop where AI implements, critiques, verifies, and improves, and where a person owns the result.

## The four roles

| Role           | What runs it                                 | Model                 | Job                                                                                |
| :------------- | :------------------------------------------- | :-------------------- | :--------------------------------------------------------------------------------- |
| Orchestrator   | your main session, running `/zs-orchestrate` | your strongest model  | Break the problem down, delegate, triage findings, iterate, decide when it is done |
| Implementation | `zs-code-agent` subagent                     | a fast model          | Read the repository, write the code, run the gates, report back                    |
| Code review    | `zs-code-review-agent` subagent              | a strong review model | Bugs, security, correctness of the code itself                                     |
| Context review | `zs-context-review-agent` subagent           | a strong review model | Requirements coverage, completeness, docs, and reference verification              |

`zs-content-review-agent` joins as a third reviewer whenever the change touches prose a human will read.

Each subagent runs in its own context window. It cannot see your conversation, and you cannot see its working. That isolation is the point. A reviewer that shares the implementer's context inherits the implementer's blind spots, and you get agreement instead of review.

## The loop

```
                    /zs-orchestrate "the task"
                              |
                      [ Orchestrator ]
                    plan and scope the work
                              |
                              v
                       [ code-agent ]
                  read repo, implement, run gates
                              |
                              v
              +---------------+---------------+
              |                               |
     [ code-review-agent ]        [ context-review-agent ]
      bugs, security, logic        requirements, docs, refs
              |                               |
              +---------------+---------------+
                              |
                      [ Orchestrator ]
                triage: fix now, out of scope, wrong
                              |
                    findings? -> back to code-agent
                     clean? -> run gates yourself
                              |
                              v
                    report, then the engineer
                     reviews, commits, pushes
```

Stop after three rounds, or when the same finding survives two rounds. At that point a person needs to look at it.

## Running it

```
/zs-orchestrate add rate limiting to the login endpoint, 5 attempts per minute per IP
```

Before you push, on every change, including changes you wrote by hand:

```
/zs-self-review
```

And when a change introduces links, packages, endpoints, or versions:

```
/zs-verify-references
```

Individual agents can be called on their own when you do not need the full loop:

```
@agent-zs-code-review-agent review the changes on this branch
@agent-zs-context-review-agent check this against the ticket description
@agent-zs-content-review-agent review the README changes
```

## Running it in Codex

Same loop, different mechanics. Codex ships the four workflow agents as TOML in `~/.codex/agents/`, with their models and sandbox already set.

```bash
codex
# $zs-orchestrate add rate limiting to the login endpoint, 5 attempts per minute per IP
# $zs-self-review
```

Two differences worth knowing:

- Codex does not delegate on its own. Name the agent you want: "spawn the zs-code-agent to implement this", then "spawn zs-code-review-agent and zs-context-review-agent on the diff in parallel". The main thread collects the results.
- `/agent` inspects and switches between running threads while they work.

The reviewers run with `sandbox_mode = "read-only"`, so they cannot edit the code they are reviewing even if asked to.

## Models

| Role           | Claude Code | Codex                                            |
| :------------- | :---------- | :----------------------------------------------- |
| Orchestrator   | `opus`      | `gpt-5.6-sol` or `gpt-5.6-terra` for the session |
| Implementation | `sonnet`    | `gpt-5.6-terra`                                  |
| Code review    | `opus`      | `gpt-5.6-sol`                                    |
| Context review | `opus`      | `gpt-5.6-sol`                                    |
| Content review | `sonnet`    | `gpt-5.6-luna`                                   |

The orchestrator takes the session model in both CLIs, so start the session on your strongest one. Every other row is set in the agent file and can be changed there.

A fan out costs more than a single pass, because each agent runs its own model and its own tool calls. That is the trade: more tokens for a review that did not come from the same context that wrote the code.

## Self review is not optional

Run `/zs-self-review` before you ask a colleague to look at your work. A colleague's attention is the scarcest thing on the team, and it should go to design, to the decisions you made, and to the things only a person who knows the system can see. It should not go to a missing null check that a machine would have found in thirty seconds.

If a reviewer runs these same agents on your change and they surface issues a self review would have caught, the process was not followed. That is a teamwork problem before it is a code problem.

Self review does not replace peer review. It raises the floor of what reaches peer review.

## Verify every external reference

When an AI hands you a link, a source, an API endpoint, a package name, a documentation URL, or any other external fact, verify it independently before it goes anywhere near the source code.

Check that it exists. Check that it is correct. Check that it is authoritative. Check that it actually supports what the AI says it supports.

A model produces text that is shaped like a correct reference. Shape is not truth. A package that was never published, a doc link that lands on an unrelated page, an endpoint removed two versions ago: each of these reads perfectly in review and fails later, usually somewhere expensive.

An unverified AI generated reference in the source code is a defect. `/zs-verify-references` automates the collection and the checking. It does not transfer the responsibility.

## Ownership

You are one hundred percent responsible for the code you submit. The loop does not change that, and neither does a clean report from four agents.

- An agent reporting success is not evidence that the work is correct. Read the diff.
- A reviewer agent can be wrong. When you disagree, say why, and decide.
- Anything you could not verify goes in the pull request description, not in silence.

Use AI to be faster and more thorough. Judgment, verification, and accountability stay with you.

## Demonstrating your workflow

When showing how you work, a live run beats slides. Show:

1. The task, stated as you would state it to a colleague.
2. `/zs-orchestrate`, and the plan it produces before any code is written.
3. The delegation to `zs-code-agent`, and the report that comes back, including its assumptions and anything it could not verify.
4. Both reviewers running in parallel, and their findings.
5. Your triage. Which findings you sent back, which you rejected, and why. This step is the workflow. Everything else is plumbing.
6. A second round on the fixes.
7. `/zs-self-review` on the final diff, and the reference check.
8. You reading the diff and deciding it is ready.

A run where every agent agrees on the first pass is a weak demo. Show a round where a reviewer found something real, or where a reviewer was wrong and you overruled it.

## When not to use the loop

A one line fix does not need four agents. Neither does a typo, a version bump, or a config value. The loop costs tokens and wall clock time, and using it everywhere trains people to skip it.

Use it when the change has more than one moving part, touches something that matters, or when you would want a second pair of eyes before pushing.

Self review, on the other hand, runs on everything.
