# AI Craft Agents

Reference for every agent and skill in this repository.

For the workflow these fit into, read [workflow.md](workflow.md). For what an agent is versus a skill, read [agents-and-skills.md](agents-and-skills.md).

## Skills

Invoked with `/name`, or `/ai-craft:name` when installed as a plugin.

### `/zs-orchestrate`

The four agent loop. Plans and scopes the work, delegates implementation to `zs-code-agent`, runs `zs-code-review-agent` and `zs-context-review-agent` in parallel, triages what comes back, and iterates until the change stands up.

- **File:** `skills/zs-orchestrate/SKILL.md`
- **Use it for:** any change with more than one moving part

### `/zs-self-review`

Reviews your own uncommitted or unpushed work before a colleague sees it. Runs both reviewers over the diff, runs the repository gates, verifies references, and reports what to fix before you push.

- **File:** `skills/zs-self-review/SKILL.md`
- **Use it for:** every push, on every change, including work you wrote by hand

### `/zs-verify-references`

Pulls every URL, package, endpoint, version, flag, and identifier the change introduced, and confirms each one exists and says what the code claims.

- **File:** `skills/zs-verify-references/SKILL.md`
- **Use it for:** anything an AI helped write

### `/zs-ticket-updates`

When installed through the Claude Code plugin, invoke it as
`/ai-craft:zs-ticket-updates`.

Creates or updates ZSoftly engineering tickets and NorthStar metadata. It
preserves unspecified values and requires explicit engineer authorization before
changing project state.

- **File:** `skills/zs-ticket-updates/SKILL.md`
- **Use it for:** an explicitly requested issue, project field, comment, or pull request update

## The workflow agents

### Code Agent (`@agent-zs-code-agent`)

Implements one scoped change in its own context. Reads the repository first, matches existing conventions, runs lint, build, and tests, then reports what it did, what it assumed, and what it could not verify.

- Runs on a fast model
- **File:** `agents/zs-code-agent.md`

### Code Review Agent (`@agent-zs-code-review-agent`)

Bugs, security holes, and correctness of the code itself. Reports findings by file and line with severity. Has no write tools, so it cannot change what it reviews.

- Runs on a strong review model
- **File:** `agents/zs-code-review-agent.md`

### Context Review Agent (`@agent-zs-context-review-agent`)

The second reviewer, running in parallel with the first. Checks requirements coverage, completeness across callers and docs and config, and whether every external reference the change introduced actually exists.

- Runs on a strong review model
- **File:** `agents/zs-context-review-agent.md`

### Content Review Agent (`@agent-zs-content-review-agent`)

Reports AI writing patterns in prose, with a suggested rewrite for each sentence it flags. Read only, like the other two reviewers. Em dashes, hyperbolic words, filler adjectives, passive voice, and marketing language. Joins the review round whenever a change touches text a human reads.

- **File:** `agents/zs-content-review-agent.md`

## Available Agents

### 1. Development Agent (`@agent-zs-dev-agent`)

5-phase development workflow for building features

- Analysis → Planning → Implementation → Review → Pull Request
- **File:** `agents/zs-dev-agent.md`

### 2. TDD Agent (`@agent-zs-tdd-agent`)

Test-Driven Development with Red-Green-Refactor

- Write test first → Implement → Refactor
- **File:** `agents/zs-tdd-agent.md`

### 3. Gemini Development (`@agent-zs-gemini-dev`)

Use latest Gemini for development (performance, large codebases)

- **File:** `agents/zs-gemini-dev.md`

### 4. Gemini Data Analysis (`@agent-zs-gemini-data`)

Use latest Gemini for data analysis (logs, CSV, patterns)

- **File:** `agents/zs-gemini-data.md`

### 5. Code Review Agent (`@agent-zs-code-review-agent`)

Review code for bugs, security, and quality

- **File:** `agents/zs-code-review-agent.md`

### 6. Inter-AI Communication (`@agent-zs-inter-ai-communication`)

Guide for bidirectional Claude ↔ Gemini communication

- Real CLI commands for AI-to-AI calls
- Working examples and patterns
- **File:** `agents/zs-inter-ai-communication.md`

### 7. Git Workflow Agent (`@agent-zs-git-workflow-agent`)

Review changes, commit, and push using YOUR git credentials

- Shows uncommitted changes and unpushed commits
- Never uses AI attribution in commits
- Always uses your configured git identity
- **File:** `agents/zs-git-workflow-agent.md`

### 8. Sniff (`@agent-zs-sniff`)

Fast opportunity screening against ZSoftly's current ICP

- Flags BID, NO BID, PARTNER, or MORE INFO
- Checks ICP fit, deadline risk, buyer quality, and feasibility
- **File:** `agents/zs-sniff.md`

### 9. Dig (`@agent-zs-dig`)

Deep bid/no-bid and partner-fit analysis

- Reviews RFPs, supplier lists, public tenders, Upwork jobs, and partner opportunities
- Separates eligibility gates from capability fit
- **File:** `agents/zs-dig.md`

### 10. Wag (`@agent-zs-wag`)

ZSoftly-aligned proposal and message drafting

- Writes proposal drafts after `zs-sniff` or `zs-dig`
- Supports RFP sections, Upwork proposals, intent emails, and partner outreach
- **File:** `agents/zs-wag.md`

### 11. CMP Deploy Agent (`@agent-zs-cmp-deploy-agent`)

Deploy ZCP CMP to an instance through Argo CD and verify the result

- Pins image digests, runs the sync, verifies the rollout against running pods
- Checks whether the chart is behind the backend before rolling forward
- Prepares Git changes for a human to publish and never commits or pushes
- **File:** `agents/zs-cmp-deploy-agent.md`

## Installation

```bash
# Clone and install
git clone https://github.com/zsoftly/ai-craft.git
cd ai-craft
chmod +x install.sh
./install.sh
```

The installer detects your AI CLIs and installs to the correct location:

- **Claude Code** → `~/.claude/agents/`
- **Gemini CLI** → `~/.gemini/GEMINI.md`
- **OpenAI Codex** → `~/.codex/AGENTS.md`

Open a new Claude, Gemini, or Codex session after reinstalling. Current windows
usually keep the context they loaded at startup.

## Usage

### Claude Code

Reference agents with `@`:

```
@agent-zs-dev-agent Phase 1: Analyze my authentication system

@agent-zs-tdd-agent RED: Write a failing test for login

@agent-zs-gemini-dev Ask Gemini to check performance of src/api/

@agent-zs-code-review-agent Review PR #123
```

## Working with Gemini

Gemini (Google's model) is great for:

- **Large files** - Massive context window (entire codebases!)
- **Performance analysis** - Optimization specialist
- **Data processing** - Logs, CSVs, metrics
- **Fast responses** - Quick analysis

**Gemini CLI Tools:**

- `read_file` - Read files
- `search_file_content` - Search patterns
- `web_fetch` - Fetch web content

**Note:** Gemini cannot write files or run commands. Claude implements Gemini's suggestions.

### Simple Pattern

```
You: "Ask Gemini to analyze my server logs"

Claude: [Sends to Gemini with latest model]

Gemini: [Analyzes and finds patterns]

Claude: [Helps you fix them]
```

## Common Workflows

### Workflow 1: Development with Both AIs

```
@agent-zs-dev-agent Phase 1: Analyze the codebase
[Claude analyzes architecture]

Ask Gemini to check for performance issues
[Gemini finds bottlenecks]

@agent-zs-dev-agent Phase 3: Implement Gemini's optimizations
[Claude implements fixes]
```

### Workflow 2: Data-Driven Development

```
@agent-zs-gemini-data Analyze user behavior logs
[Gemini finds patterns]

@agent-zs-dev-agent Phase 2: Review this plan based on Gemini's findings
[Claude reviews approach]

@agent-zs-dev-agent Phase 3: Implement improvements
[Claude builds solution]
```

### Workflow 3: TDD with Performance Check

```
@agent-zs-tdd-agent Let's build a search feature with TDD
[Write tests, implement, refactor]

@agent-zs-gemini-dev Ask Gemini to review search performance
[Gemini analyzes, suggests optimizations]

@agent-zs-tdd-agent Refactor with Gemini's suggestions
[Refactor while keeping tests green]
```

## Examples

### Example 1: Bug Investigation

```
You: My app is slow, can you help?

@agent-zs-gemini-data Analyze the performance logs in logs/perf.log

Gemini finds: Database queries taking 2+ seconds

You: How do I fix it?

@agent-zs-dev-agent Phase 3: Optimize database queries based on these findings
```

### Example 2: Feature Development

```
@agent-zs-dev-agent Phase 1: Analyze payment system for adding Stripe

Claude: [Analyzes current code]

You: Check with Gemini if there are performance concerns

@agent-zs-gemini-dev Ask Gemini about payment processing performance

Gemini: [Suggests async processing, webhooks]

@agent-zs-dev-agent Phase 3: Implement Stripe with Gemini's performance tips
```

### Example 3: Code Review

```
@agent-zs-code-review-agent Review my authentication code

Claude: [Reviews security, logic]

@agent-zs-gemini-dev Ask Gemini to check auth performance

Gemini: [Finds password hashing is blocking]

Together: Fix security issues (Claude) + performance (Gemini)
```

## When to Use Which

### Use Claude (@agent-zs-dev-agent, @agent-zs-tdd-agent, @agent-zs-code-review-agent) for:

- Writing code
- Architecture decisions
- Step-by-step workflows
- Code reviews
- Implementation details

### Use Gemini (@agent-zs-gemini-dev, @agent-zs-gemini-data) for:

- Large codebases (100+ files)
- Performance analysis
- Log analysis
- Data patterns
- Quick optimization checks

### Use Both for:

- Complete features (Claude builds, Gemini optimizes)
- Data-driven decisions (Gemini analyzes, Claude implements)
- Performance-critical code (Both review different aspects)

## No Complex Setup!

- ✓ Just markdown files
- ✓ No Docker
- ✓ No npm install
- ✓ No MCP servers
- ✓ Just copy files and use with @

Simple!

## Tips

1. **Start with Claude** for planning and coding
2. **Ask Gemini** when you need performance or data analysis
3. **Combine them** for best results
4. **Be specific** about what you want each AI to do

## Example Session

```
User: I need to build a search feature

@agent-zs-dev-agent Phase 1: Analyze current search setup
[Claude analyzes]

@agent-zs-dev-agent Phase 2: Review this plan:
- Full-text search with PostgreSQL
- Index on search columns
- Cache popular searches
[Claude reviews plan]

@agent-zs-gemini-dev Ask Gemini about search performance at scale
[Gemini suggests: Elasticsearch for >100k records]

@agent-zs-dev-agent Phase 3: Implement search with Elasticsearch
[Claude implements]

@agent-zs-gemini-data Have Gemini analyze search query logs
[Gemini finds: Most searches are 1-2 words]

@agent-zs-dev-agent Optimize for short queries based on Gemini's findings
[Claude optimizes]

@agent-zs-code-review-agent Review the search implementation
[Claude does final review]

Done! ✓
```

## Learn More

Read the individual agent files:

- `agents/zs-code-agent.md` - Scoped implementation, reports back
- `agents/zs-code-review-agent.md` - Code review process
- `agents/zs-context-review-agent.md` - Requirements, completeness, reference checking
- `agents/zs-content-review-agent.md` - Removing AI writing patterns
- `agents/zs-dev-agent.md` - Full development workflow
- `agents/zs-tdd-agent.md` - Test-driven development
- `agents/zs-gemini-dev.md` - Using Gemini for development
- `agents/zs-gemini-data.md` - Using Gemini for data analysis
- `agents/zs-inter-ai-communication.md` - Claude and Gemini bidirectional communication
- `agents/zs-git-workflow-agent.md` - Git commit and push with your credentials
- `agents/zs-cmp-deploy-agent.md` - ZCP CMP deploy and rollout verification

And the skills in `skills/`:

- `skills/zs-orchestrate/SKILL.md` - The four agent loop
- `skills/zs-self-review/SKILL.md` - Pre push review of your own work
- `skills/zs-verify-references/SKILL.md` - Confirming external references
- `skills/zs-ticket-updates/SKILL.md` - Engineering ticket and NorthStar updates

## Inter-AI Communication

The inter-ai-communication agent includes working examples of:

1. **Claude → Gemini**: Performance analysis with real CLI commands
2. **Claude implements**: Based on Gemini's suggestions
3. **Claude → Gemini**: Validation loop
4. **Complete patterns**: Full bidirectional communication examples

All examples use actual `gemini -p` and `claude -p` commands you can run directly.
