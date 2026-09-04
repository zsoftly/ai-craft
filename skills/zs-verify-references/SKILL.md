---
name: zs-verify-references
description: Checks every external reference a change introduces. URLs, documentation links, package names, version pins, API endpoints, CLI flags, configuration keys, standards, and CVE identifiers are each confirmed to exist and to support what the code claims. Use before pushing anything an AI helped write, and any time a reference appears in a diff.
argument-hint: [optional paths, branch, or a reference to check]
disable-model-invocation: false
---

# Verify References

Confirm that every external thing this change names actually exists and actually says what the change claims. Scope:

$ARGUMENTS

If no scope was given, check the current branch's diff against its upstream.

A language model produces plausible references. Plausible is not the same as real. A package that does not exist, a documentation link that resolves to something unrelated, an API endpoint that was removed two versions ago: each of these reads perfectly well in review and fails in production or, worse, ships and quietly misleads the next person to read the code.

## Step 1: Collect the references

Read the diff and pull out everything that points outside this repository:

- URLs and documentation links, in code, comments, docs, and commit messages.
- Package names and version pins in `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, `pom.xml`, or any lockfile.
- API endpoints, paths, and query parameters for third party services.
- CLI commands, subcommands, and flags for external tools.
- Configuration keys, environment variable names, and settings paths belonging to another product.
- Standards, RFCs, CVE identifiers, licence names, and specification section numbers.
- Named products, versions, and their claimed behaviour.

List them with the file and line where each appears.

## Step 2: Check each one

| Reference type    | How to confirm it                                                                          |
| :---------------- | :----------------------------------------------------------------------------------------- |
| URL or doc link   | Fetch it. Confirm it resolves, and read enough to confirm it covers the claim.             |
| Package name      | Check the registry, or check that it is present in the lockfile and installed tree.        |
| Version pin       | Confirm that version was published, and that the API used exists in it.                    |
| API endpoint      | Find it in the vendor's own reference docs. Call it only when that is safe and authorised. |
| CLI flag          | Run the tool's own `--help`. Do not trust a blog post.                                     |
| Config key        | Find it in the product's documentation or its schema.                                      |
| CVE or RFC        | Look it up by identifier and confirm the subject matches.                                  |
| Behavioural claim | Find the sentence in vendor documentation that supports it, or test it.                    |

Rules for the check:

- Authoritative sources only: the vendor's documentation, the project's own repository, the registry, the tool's own output. A forum answer or a blog post is a lead, not a confirmation.
- A redirect is not a pass. Follow it and confirm where it lands. Documentation sites move, and the old path often lands on a generic index that supports nothing.
- Fetching the page is not enough. The page has to say the thing the code claims.
- If a link is behind auth or is unreachable from here, that is `NOT CONFIRMED`, not `probably fine`.

## Step 3: Report

```
REFERENCES CHECKED: <n>

CONFIRMED (<n>)
- <reference> (path/to/file:line) -> <what confirmed it>

NOT CONFIRMED (<n>)
1. <reference> (path/to/file:line)
   Claimed: <what the code says this is>
   Checked: <what you did>
   Result: <does not exist | resolves elsewhere | version does not have it | source is not authoritative>
   Action: <remove it, replace it with the real one, or confirm it by hand>

UNCHECKABLE (<n>)
- <reference> (path/to/file:line) -> <why: private network, needs credentials, rate limited>
```

Anything in `NOT CONFIRMED` blocks the push. Anything in `UNCHECKABLE` needs a human to confirm it before the change lands, and saying so in the pull request description is part of the job.

Never mark a reference confirmed because it looks right. The only thing that counts is that you checked it.
