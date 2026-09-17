---
name: zs-ticket-updates
description: Creates or updates GitHub issues and NorthStar project items using ZSoftly's required metadata, relationships, PR links, and evidence-based status updates. Use only when an engineer explicitly asks to create or change ticket metadata, ticket comments, project fields, or ticket to PR links.
argument-hint: "issue or PR, requested ticket change, and evidence"
disable-model-invocation: true
---

# Ticket Updates

Apply the engineer's requested GitHub issue and NorthStar project change. Scope:

$ARGUMENTS

This is a mutating workflow. Run it only when the engineer explicitly asks to create or update a ticket, project item, comment, or pull request link. Do not infer permission from a request to inspect or report ticket status.

## Required input

Collect or inspect the following before changing anything:

- Repository, issue number, and project item.
- Requested owner, status, parent epic, sprint, and pull request.
- The reason for the change and evidence for any completion claim.
- Current issue metadata, project fields, relationships, linked pull requests, and ticket comments.

For an existing ticket, preserve every value not explicitly requested.
Do not replace an assignee with `No one` or remove labels to produce `No labels`.
Do not clear a milestone, change priority, or alter a project field unless the engineer explicitly asks.

## Fast command playbook

Use these commands directly. Do not rediscover basic `gh issue` syntax unless a
command fails because the installed `gh` version lacks a flag.

Set placeholders mentally or in a short script:

- `<repo>` is `OWNER/REPO`, for example `zsoftly/platform`.
- `<issue>` is the issue number.
- `<issue-url>` is the full issue URL.
- `<project-owner>` is `zsoftly`.
- `<project-number>` is `44` for `NorthStar ⭐`.

For bodies and long comments, write plain markdown to a temporary file and pass
it with `--body-file`. Clean the file up after final verification. Do not inline
multi-line markdown through shell variables, command substitution, heredocs,
`echo`, or `printf`.

### Inspect

```bash
gh issue view <issue> -R <repo> --comments --json number,title,body,state,stateReason,issueType,assignees,labels,milestone,parent,subIssues,projectItems,closedByPullRequestsReferences,url
```

```bash
gh issue list -R <repo> --state all --limit 100 --json number,title,state,issueType,assignees,labels,milestone,parent,projectItems,url --search '<search query>'
```

### Create

Use this for a normal new engineering ticket:

```bash
gh issue create -R <repo> --title '<title>' --body-file <body.md> --type Story --project 'NorthStar ⭐'
```

Use this when a parent issue was explicitly requested and verified:

```bash
gh issue create -R <repo> --title '<title>' --body-file <body.md> --type Story --parent <parent-issue> --project 'NorthStar ⭐'
```

Add only requested labels, assignees, milestones, dependencies, or a different
type:

```bash
gh issue create -R <repo> --title '<title>' --body-file <body.md> --type '<type>' --assignee <login> --label '<label>' --milestone '<milestone>' --blocked-by <issue-or-url> --blocking <issue-or-url>
```

### Edit native issue fields

Use one or more supported flags on the same command:

```bash
gh issue edit <issue> -R <repo> --title '<title>' --body-file <body.md>
```

```bash
gh issue edit <issue> -R <repo> --type Story
gh issue edit <issue> -R <repo> --remove-type
gh issue edit <issue> -R <repo> --parent <parent-issue>
gh issue edit <issue> -R <repo> --remove-parent
gh issue edit <issue> -R <repo> --add-sub-issue <child-issue>
gh issue edit <issue> -R <repo> --remove-sub-issue <child-issue>
gh issue edit <issue> -R <repo> --add-assignee <login>
gh issue edit <issue> -R <repo> --remove-assignee <login>
gh issue edit <issue> -R <repo> --add-label '<label>'
gh issue edit <issue> -R <repo> --remove-label '<label>'
gh issue edit <issue> -R <repo> --milestone '<milestone>'
gh issue edit <issue> -R <repo> --remove-milestone
gh issue edit <issue> -R <repo> --add-blocked-by <issue-or-url>
gh issue edit <issue> -R <repo> --remove-blocked-by <issue-or-url>
gh issue edit <issue> -R <repo> --add-blocking <issue-or-url>
gh issue edit <issue> -R <repo> --remove-blocking <issue-or-url>
```

### Comment and state

```bash
gh issue comment <issue> -R <repo> --body-file <comment.md>
gh issue comment <issue> -R <repo> --edit-last --body-file <comment.md>
gh issue close <issue> -R <repo> --reason completed --comment '<short closing comment>'
gh issue close <issue> -R <repo> --reason 'not planned' --comment '<short closing comment>'
gh issue close <issue> -R <repo> --duplicate-of <issue-or-url>
gh issue reopen <issue> -R <repo> --comment '<short reopening comment>'
```

### NorthStar project fields

First confirm fields and options:

```bash
gh project field-list 44 --owner zsoftly --format json
```

Add an issue to NorthStar if required:

```bash
gh project item-add 44 --owner zsoftly --url <issue-url> --format json
```

Set one field per invocation:

```bash
gh project item-edit 44 --owner zsoftly --url <issue-url> --field 'Status' --value 'Todo'
gh project item-edit 44 --owner zsoftly --url <issue-url> --field 'Status' --value 'In progress'
gh project item-edit 44 --owner zsoftly --url <issue-url> --field 'Status' --value 'Done'
gh project item-edit 44 --owner zsoftly --url <issue-url> --field 'Tags' --value 'engineering'
gh project item-edit 44 --owner zsoftly --url <issue-url> --field 'Extra Tags' --value 'Blocked'
gh project item-edit 44 --owner zsoftly --url <issue-url> --field 'Start date' --date YYYY-MM-DD
gh project item-edit 44 --owner zsoftly --url <issue-url> --field 'Due date' --date YYYY-MM-DD
gh project item-edit 44 --owner zsoftly --url <issue-url> --field 'Effort' --number <number>
```

For iteration fields, use the iteration ID from `field-list`:

```bash
gh project item-edit 44 --owner zsoftly --url <issue-url> --field 'Sprints' --iteration-id <iteration-id>
gh project item-edit 44 --owner zsoftly --url <issue-url> --field 'Month' --iteration-id <iteration-id>
```

Clear a supplied field only when explicitly requested:

```bash
gh project item-edit 44 --owner zsoftly --url <issue-url> --field '<field name>' --clear
```

### GraphQL fallback

Use GraphQL only for fields or verification that `gh issue` and `gh project`
cannot express. Put the request in a JSON file and call:

```bash
gh api graphql --input <request.json>
```

Use this inspection shape as the starting point:

```json
{
  "query": "query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){id number title url issueType{name} parent{number url} projectItems(first:20){nodes{id project{number title}}}}}}",
  "variables": {
    "owner": "<owner>",
    "repo": "<repo>",
    "number": 123
  }
}
```

For batches or many subtasks, prepare a JSON plan plus a short Node script that
calls `gh` with an argument array. Do not build shell commands by interpolating
issue bodies, GraphQL, titles, or user supplied text.

## New engineering ticket baseline

For a new engineering ticket, set this baseline after verifying that each
option exists:

| Field                                                           | Value                                                                    |
| :-------------------------------------------------------------- | :----------------------------------------------------------------------- |
| Type                                                            | `Story`                                                                  |
| Project                                                         | `NorthStar ⭐` (project 44)                                              |
| Status                                                          | `Todo`                                                                   |
| Sprints                                                         | The iteration whose dates include today                                  |
| Tags                                                            | `engineering`, unless the engineer explicitly supplies another valid tag |
| Assignee                                                        | `No one`                                                                 |
| Labels                                                          | `No labels`                                                              |
| Priority                                                        | Leave empty                                                              |
| Milestone                                                       | Leave empty                                                              |
| Start date, due date, month, estimation, effort, and Extra Tags | Leave empty unless supplied                                              |

Use `In progress` instead of `Todo` only when work is already active and the
engineer provides evidence. If no sprint includes today, leave Sprints empty and
report the gap.

If a relevant parent Epic is not named, ask the engineer or leave the ticket
unparented. Verify that the named issue is an Epic before linking it. Do not
infer an Epic from its title, label, repository, or project.

## Inspect before update

Read the issue and current state before editing. Confirm the target repository
and issue number. Check the active NorthStar sprint by its start and end dates.
Do not choose a sprint from its name alone.

Every new engineering ticket must be added to NorthStar project 44 as part of
the baseline above. Use the issue's existing project item when it has one. For
an existing ticket without a NorthStar item, add it only when the engineer
explicitly requests it.

## Existing ticket metadata

Set only requested native GitHub fields:

| Field     | Rule                                                                                              |
| :-------- | :------------------------------------------------------------------------------------------------ |
| Assignee  | Assign the requested accountable engineer. `No one` is a deliberate cleared state, not a default. |
| Labels    | Add or remove only requested labels. `No labels` is a deliberate cleared state, not a default.    |
| Type      | Set the requested type, such as Story or Epic. Do not infer a type from the ticket title.         |
| Milestone | Set or clear only when requested. Preserve `No milestone` otherwise.                              |

### Organization issue field

| Field    | Rule                                                                                |
| :------- | :---------------------------------------------------------------------------------- |
| Priority | Set only when requested. Preserve `Choose an option` when no priority was supplied. |

## Existing NorthStar project 44 metadata

For work tracked in NorthStar, set the requested fields on project 44. Preserve every other field.

| Field      | Rule                                                                                                                                                                   |
| :--------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Status     | Use exactly `Todo`, `In progress`, or `Done`. Use `Done` only with verified completion evidence.                                                                       |
| Sprints    | Select the current active sprint by date when requested. Do not use `Choose an iteration` as a substitute for checking the active sprint.                              |
| Tags       | This is single select. Set one requested value only. Do not add multiple values.                                                                                       |
| Start date | Set only when supplied. Preserve `No date` otherwise.                                                                                                                  |
| Due date   | Set only when supplied. Preserve `No date` otherwise.                                                                                                                  |
| Month      | Select an iteration only when supplied. Preserve `Choose an iteration` otherwise.                                                                                      |
| Estimation | Set only when supplied. Preserve `Choose an option` otherwise.                                                                                                         |
| Effort     | Set only when supplied. Preserve an empty value otherwise.                                                                                                             |
| Extra Tags | Use `Review`, `Blocked`, or `Planning` only when requested. When `Blocked` is set, keep Status as `In progress` unless the engineer explicitly directs another status. |

## Relationships and pull request links

For existing tickets, set a parent issue or pull request link only when the
engineer explicitly requests it. Verify that the parent is an Epic. Verify that
the pull request is on the requested branch and repository. Preserve existing
links unless the engineer explicitly asks to remove them.

For a pull request in the same repository, use `Fixes #<issue>` only when
merging it into the repository's default branch must close the issue. For a
cross-repository pull request, use `Fixes <owner>/<repository>#<issue>` only in
the same circumstance. Verify a closing link appears under Development.

For a non-closing relationship, add ordinary cross-references on both the issue
and pull request. Do not claim that this creates a Development relationship.

## Ticket body

Keep issue bodies short. Use the fewest words needed to state the problem,
desired outcome, and acceptance criteria.

- Epic bodies are at most 5 lines unless the engineer explicitly approves a
  longer manually written body.
- Story bodies are at most 10 lines unless the engineer explicitly approves a
  longer manually written body.
- Task bodies may be longer only when the requested work needs concrete
  reproduction steps, dated history, or review text that would be unsafe to
  omit.

For a new engineering ticket, use this structure. Keep it factual and focused on
the acceptance criteria.

```markdown
## Summary

<Problem and intended outcome in one or two sentences.>

## Acceptance criteria

- [ ] <Observable result.>
```

Do not duplicate technical values, configuration, test logs, deployment output,
pull request content, or source details that GitHub or source control already
maintains. Link to the authoritative pull request, check, deployment, or file
instead of copying it into the ticket.

For a research, discovery, or documentation ticket whose work is to collect
facts, record those facts in a source-controlled file. Add only one line to the
ticket: `Source of truth: https://github.com/zsoftly/<repo-name>/blob/main/<path> ($HOME/zsoftly/<repo-name>/<path>)`.
When the file is on a feature branch, use its expected post-merge `main` URL.
Do not repeat the file's contents, facts, or values in the ticket.

Do not check acceptance criteria, claim a deployment, or change Status to
`Done` without evidence. For `Done`, link to the authoritative GitHub pull
request, check, deployment, or source-controlled file. Do not copy its values,
logs, or output into the ticket.

## Ticket comment

Use this concise format for a status update. Omit `Blocker` when there is none.
Do not repeat information already maintained in a pull request, check,
deployment, or source-controlled file.

```markdown
## Update

- Status: <Todo | In progress | Done>
- Completed: <Verified work only.>
- Evidence: <Link to the authoritative PR, check, deployment, or file.>
- Next step: <One concrete action.>
- Blocker: <What prevents the next step.>
```

## Final check

Before reporting completion, re-read the issue and NorthStar item. Confirm that
the requested values were set and unspecified values were preserved. Confirm
the parent Epic and pull request link have the intended behavior. Report the
issue, project, sprint, parent Epic, status, and pull request link changed.
