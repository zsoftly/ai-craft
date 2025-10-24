# Code Review Workflow

A structured prompt for reviewing code changes using git commands.

## Instructions

Please use local git commands to review the changes from the branch `issue-133/jenkins-sso-integration` against `origin/main`. Analyze the differences to understand what the PR is about.

Identify any mistakes such as:

* Syntax errors
* Spelling errors
* Invalid links
* Common documentation mistakes that are unlikely to be correct

For each issue you find, respond briefly with:

* **File name**
* **Line number** (if line numbers are not accurate, include search words to locate the issue)
* **Issue description (short)**
* **Why it's likely incorrect**
* **Recommended fix (only if it is simple)**

Keep responses concise and direct. Only list items that are clearly wrong or need correction.
