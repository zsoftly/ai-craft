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

For a new engineering ticket, use this structure. Keep it factual and short.

```markdown
## Summary

<Customer or platform problem in one or two sentences.>

## Scope

- <Exact component, service, template, or repository area.>

## Acceptance criteria

- [ ] <Observable result.>

## Deployment status

- Staging: Not deployed
- Production: Not deployed

## Verification evidence

- <Test, command result, PR, deployment result, or screenshot.>

## Risks and follow-up

- <Risk or follow-up item, or `None`.>
```

Do not check acceptance criteria, claim a deployment, or change Status to `Done` without evidence.

## Ticket comment

Use this format for a status update. Omit `Blocker` when there is none.

```markdown
## Update

- Status: <Todo | In progress | Done>
- Completed: <Verified work only.>
- Evidence: <PR, test result, deployment result, or screenshot.>
- Environment: <Staging | Production | Not deployed>
- Next step: <One concrete action.>
- Blocker: <What prevents the next step.>
```

## Final check

Before reporting completion, re-read the issue and NorthStar item. Confirm that
the requested values were set and unspecified values were preserved. Confirm
the parent Epic and pull request link have the intended behavior. Report the
issue, project, sprint, parent Epic, status, and pull request link changed.
