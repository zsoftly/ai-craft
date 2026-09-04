---
name: zs-self-review
description: Reviews your own uncommitted or unpushed changes before you ask a colleague to look at them. Runs zs-code-review-agent and zs-context-review-agent in parallel over the diff, adds zs-content-review-agent when prose changed, verifies every external reference the change introduced, and reports what you need to fix before you push.
argument-hint: [optional branch, PR number, or paths]
disable-model-invocation: true
---

# Self Review

Review the engineer's own work before it reaches a peer. Scope:

$ARGUMENTS

If no scope was given, review everything on this branch that has not been pushed.

This runs before a push and before a review request. Anything the reviewers here would catch is something a colleague should never have to spend their time on.

## Step 1: Establish the diff

```bash
git status --porcelain          # includes untracked files, marked ??
git log --oneline origin/HEAD..HEAD
git diff HEAD                   # working tree and staged, against the last commit
git diff --stat origin/HEAD...HEAD
git diff origin/HEAD...HEAD     # commits on this branch
```

Your work is all of it: committed, staged, unstaged, and untracked. `git diff` shows none of the untracked files, so read every path `git status --porcelain` marks `??` in full and include them in what you send the reviewers. A file you just created is the one a colleague has never seen.

Fall back to `git diff HEAD` alone when the branch has no upstream. Use `gh pr diff <number>` when a pull request number was given.

If there is nothing to review, say so and stop. Do not review the whole repository by default.

## Step 2: Work out what is being asked for

The reviewers need the intent, not just the diff. Reconstruct it from the branch name, the commit messages, the linked issue, and the conversation so far. State it in one or two sentences, and say so plainly if you are inferring rather than reading it from somewhere.

## Step 3: Run the reviewers in parallel

Launch these in a single message so they run at the same time:

1. `zs-code-review-agent`: the diff, plus the intent. Bugs, security, correctness.
2. `zs-context-review-agent`: the diff, plus the intent verbatim. Requirements coverage, completeness, docs, and reference verification.
3. `zs-content-review-agent`: only when the change touches README, docs, changelogs, release notes, marketing copy, or user facing text.

Give each one the diff scope explicitly. A reviewer that reviews the wrong range produces confident findings about code you did not write.

## Step 4: Run the repository's own gates

While the reviewers run, run the checks this repository defines: lint, build, tests, formatter. Use the commands in `package.json`, `Makefile`, `pyproject.toml`, or the CI workflow. Report the real result. A failing test is a finding, and it outranks anything the reviewers found.

## Step 5: Verify external references yourself

Independent of what the reviewers report, pull every external reference the diff introduces or changes: URLs, documentation links, package names, version pins, API endpoints, CLI flags, configuration keys, standards, CVE identifiers.

For each one, confirm it exists and that it says what the code claims. Fetch the URL. Check the package against the registry or the lockfile. Check the flag against the tool's own help output.

An unverified reference blocks the push. It does not matter how good the rest of the change is.

## Step 6: Report

```
SELF REVIEW: <branch>, <n> files, <n> insertions, <n> deletions

GATES
- lint: pass | fail | not defined
- build: pass | fail | not defined
- tests: pass | fail | not defined

MUST FIX BEFORE PUSH (<n>)
1. path/to/file:line
   <what is wrong, and what breaks because of it>
   Fix: <the specific change>

SHOULD FIX (<n>)
- path/to/file:line - <one line>

REFERENCES CHECKED (<n>)
- <reference> -> confirmed | NOT CONFIRMED, <what you tried>

REVIEWER NOTES
- <anything a peer reviewer will ask about that you should answer in the PR description>

VERDICT: ready for peer review | fix first
```

Then stop. Do not fix the findings unless the engineer asks. Do not stage, commit, or push anything. The point of this step is that a person reads the findings and decides.

## What this is not

This does not replace peer review. It removes from peer review the class of problem a machine can find, so the colleague reading your change spends their attention on design, on the decisions you made, and on the things only a person who knows the system can see.
