# AI Craft Agents

Simple agents for working with Claude and Gemini together.

## Available Agents

### 1. Development Agent (`@dev-agent`)
5-phase development workflow for building features
- Analysis → Planning → Implementation → Review → Pull Request
- **File:** `dev-agent.md`

### 2. TDD Agent (`@tdd-agent`)
Test-Driven Development with Red-Green-Refactor
- Write test first → Implement → Refactor
- **File:** `tdd-agent.md`

### 3. Gemini Development (`@gemini-dev`)
Use latest Gemini for development (performance, large codebases)
- **File:** `gemini-dev.md`

### 4. Gemini Data Analysis (`@gemini-data`)
Use latest Gemini for data analysis (logs, CSV, patterns)
- **File:** `gemini-data.md`

### 5. Code Review Agent (`@code-review-agent`)
Review code for bugs, security, and quality
- **File:** `code-review-agent.md`

### 6. Inter-AI Communication (`@inter-ai-communication`)
Guide for bidirectional Claude ↔ Gemini communication
- Real CLI commands for AI-to-AI calls
- Working examples and patterns
- **File:** `inter-ai-communication.md`

### 7. Git Workflow Agent (`@git-workflow-agent`)
Review changes, commit, and push using YOUR git credentials
- Shows uncommitted changes and unpushed commits
- Never uses AI attribution in commits
- Always uses your configured git identity
- **File:** `git-workflow-agent.md`

## Installation

```bash
# Clone and install
git clone https://github.com/yourusername/ai-craft.git
cd ai-craft
chmod +x install.sh
./install.sh
```

The installer detects your AI CLIs and installs to the correct location:
- **Claude Code** → `~/.claude/agents/`
- **Gemini CLI** → `~/.gemini/system.md`
- **OpenAI Codex** → `~/.codex/instructions.md`

## Usage

### Claude Code

Reference agents with `@`:

```
@dev-agent Phase 1: Analyze my authentication system

@tdd-agent RED: Write a failing test for login

@gemini-dev Ask Gemini to check performance of src/api/

@code-review-agent Review PR #123
```

## Working with Gemini

Gemini (Google's latest model) is great for:
- **Large files** - Massive context window (entire codebases!)
- **Performance analysis** - Optimization specialist
- **Data processing** - Logs, CSVs, metrics
- **Fast responses** - Quick analysis

I'll automatically use the latest Gemini model for best results.

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
@dev-agent Phase 1: Analyze the codebase
[Claude analyzes architecture]

Ask Gemini to check for performance issues
[Gemini finds bottlenecks]

@dev-agent Phase 3: Implement Gemini's optimizations
[Claude implements fixes]
```

### Workflow 2: Data-Driven Development
```
@gemini-data Analyze user behavior logs
[Gemini finds patterns]

@dev-agent Phase 2: Review this plan based on Gemini's findings
[Claude reviews approach]

@dev-agent Phase 3: Implement improvements
[Claude builds solution]
```

### Workflow 3: TDD with Performance Check
```
@tdd-agent Let's build a search feature with TDD
[Write tests, implement, refactor]

@gemini-dev Ask Gemini to review search performance
[Gemini analyzes, suggests optimizations]

@tdd-agent Refactor with Gemini's suggestions
[Refactor while keeping tests green]
```

## Examples

### Example 1: Bug Investigation
```
You: My app is slow, can you help?

@gemini-data Analyze the performance logs in logs/perf.log

Gemini finds: Database queries taking 2+ seconds

You: How do I fix it?

@dev-agent Phase 3: Optimize database queries based on these findings
```

### Example 2: Feature Development
```
@dev-agent Phase 1: Analyze payment system for adding Stripe

Claude: [Analyzes current code]

You: Check with Gemini if there are performance concerns

@gemini-dev Ask Gemini about payment processing performance

Gemini: [Suggests async processing, webhooks]

@dev-agent Phase 3: Implement Stripe with Gemini's performance tips
```

### Example 3: Code Review
```
@code-review-agent Review my authentication code

Claude: [Reviews security, logic]

@gemini-dev Ask Gemini to check auth performance

Gemini: [Finds password hashing is blocking]

Together: Fix security issues (Claude) + performance (Gemini)
```

## When to Use Which

### Use Claude (@dev-agent, @tdd-agent, @code-review-agent) for:
- Writing code
- Architecture decisions
- Step-by-step workflows
- Code reviews
- Implementation details

### Use Gemini (@gemini-dev, @gemini-data) for:
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

@dev-agent Phase 1: Analyze current search setup
[Claude analyzes]

@dev-agent Phase 2: Review this plan:
- Full-text search with PostgreSQL
- Index on search columns
- Cache popular searches
[Claude reviews plan]

@gemini-dev Ask Gemini about search performance at scale
[Gemini suggests: Elasticsearch for >100k records]

@dev-agent Phase 3: Implement search with Elasticsearch
[Claude implements]

@gemini-data Have Gemini analyze search query logs
[Gemini finds: Most searches are 1-2 words]

@dev-agent Optimize for short queries based on Gemini's findings
[Claude optimizes]

@code-review-agent Review the search implementation
[Claude does final review]

Done! ✓
```

## Learn More

Read the individual agent files:
- `dev-agent.md` - Full development workflow
- `tdd-agent.md` - Test-driven development
- `gemini-dev.md` - Using Gemini for development
- `gemini-data.md` - Using Gemini for data analysis
- `code-review-agent.md` - Code review process
- `inter-ai-communication.md` - Claude ↔ Gemini bidirectional communication
- `git-workflow-agent.md` - Git commit and push with your credentials

## Inter-AI Communication

The inter-ai-communication agent includes working examples of:
1. **Claude → Gemini**: Performance analysis with real CLI commands
2. **Claude implements**: Based on Gemini's suggestions
3. **Claude → Gemini**: Validation loop
4. **Complete patterns**: Full bidirectional communication examples

All examples use actual `gemini -p` and `claude -p` commands you can run directly.
