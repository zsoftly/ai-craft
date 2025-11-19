# Gemini Development Agent

Use Google's latest Gemini model for development tasks.

## When to Use
- Large codebases (Gemini handles massive context!)
- Performance analysis
- Need a different perspective from Claude
- Processing lots of code files at once

## Platform Note

**Using Gemini CLI directly?** The `@agent` syntax doesn't work in Gemini CLI. Agents are automatically loaded as context from `~/.gemini/GEMINI.md`. Just describe what you want and Gemini applies the guidance.

See CLAUDE.md "Platform Differences" section for details.

## Model Selection

**I (Claude) will use your configured Gemini model:**

- **Flash models** - For quick code reviews, simple analysis, fast responses
  - Best for: Performance checks, pattern finding, quick opinions
  - Example: `gemini-2.0-flash-exp`, `gemini-1.5-flash`

- **Pro models** - For complex coding tasks, deep analysis, architecture reviews
  - Best for: Large refactors, security audits, complex optimizations
  - Example: `gemini-2.0-pro-exp`, `gemini-1.5-pro`

**How to check available models:**
```bash
# List available Gemini models
gemini models list

# Or check your current default model
gemini config get model
```

I'll use the model configured in your Gemini CLI settings, or you can specify one when needed.

## How I (Claude) Call Gemini

When you ask me to use Gemini, I will:
1. Determine task complexity (quick → Flash, complex → Pro)
2. Execute Gemini CLI with appropriate model:

```bash
# Quick tasks - Use Flash model (faster)
gemini -m gemini-2.0-flash-exp -p "Your request here" --output-format json

# Complex tasks - Use Pro model (more thorough)
gemini -m gemini-2.0-pro-exp -p "Your request here" --output-format json

# Or use your configured default model
gemini -p "Your request here" --output-format json
```

**Note:** Model names in examples may not be current. Check `gemini models list` for available models.

**Context Optimization:**
For complex inter-AI tasks or large analysis requests, I will use the Task tool to spawn a `general-purpose` sub-agent to:
- Prepare and format data for Gemini
- Execute Gemini CLI commands
- Parse and validate Gemini's responses
- Return structured findings to me
- Save your main conversation context for implementation work

This allows me to delegate the Gemini communication while keeping your main context free.

### Simple Delegation
Just ask me:

```
Can you ask Gemini to analyze the performance of my Python code?
```

I'll execute:
```bash
gemini -p "Analyze performance of [your code] and suggest optimizations" --output-format json
```

Then bring back Gemini's response to you.

### What Gemini is Good At

**Best for:**
- Analyzing large files (Gemini handles massive context!)
- Performance optimization suggestions
- Processing lots of data
- Quick responses (very fast)
- Alternative perspective on problems

**Example tasks:**
```
Ask Gemini to review all files in src/ for performance issues

Have Gemini analyze these 10,000 log entries and find patterns

Get Gemini's opinion on this architecture design

Ask Gemini to optimize this database query
```

## Usage Patterns

### Pattern 1: Claude Plans, Gemini Analyzes
```
You: Analyze my microservices architecture

Me (Claude): [I analyze the architecture]

You: Now have Gemini check for performance bottlenecks

Me (Claude): [I execute]
gemini -p "Analyze this architecture for performance bottlenecks: [architecture details]" --output-format json

[Gemini responds with findings]

Me (Claude): Based on Gemini's findings, let me implement the fixes
```

### Pattern 2: Get Second Opinion
```
Me (Claude): Here's my solution to the problem [I provide solution]

You: "Can you ask Gemini for their opinion on this?"

Gemini: [Alternative perspective]

Together: We synthesize both perspectives
```

### Pattern 3: Large Data Processing
```
You: "I have 50,000 lines of logs in logs/ - can Gemini find anomalies?"

Me: I'll send to Gemini since they handle large data better

Gemini: [Analysis of all 50k lines]

Me (Claude): Based on Gemini's findings, here's what to do next
```

## Examples

### Example 1: Performance Analysis
```
You: Can you have Gemini analyze src/api/ for performance issues?

Context:
- Python FastAPI application
- Handling 1000 req/sec
- Response time getting slower
- Files: src/api/*.py (20 files)

Me (Claude): Let me call Gemini with the latest Flash model for quick performance analysis...

[I look up and use the latest Flash model for speed]
gemini -m <latest-flash-model> -p "Analyze these FastAPI files for performance issues. Focus on database queries, caching, and bottlenecks. Files: [src/api/ contents]" --output-format json

[Gemini returns]
{
  "response": "Performance Issues Found:
  1. N+1 query problem in src/api/users.py line 45
  2. Missing database indexes on frequently queried fields
  3. Inefficient list comprehension in src/api/posts.py line 120
  4. No caching layer for repeated queries
  Recommendation: Add Redis caching + fix N+1 queries = 10x improvement"
}

Me (Claude): Here's what Gemini found. Let me implement these fixes for you.
```

### Example 2: Large Codebase Review
```
You: Ask Gemini to review all TypeScript files for security issues

Me (Claude): I'll send all .ts files to Gemini with the latest Pro model for deep security analysis...

[I look up and use the latest Pro model for thorough security review]
gemini -m <latest-pro-model> -p "Review these TypeScript files for security vulnerabilities: SQL injection, XSS, exposed secrets, input validation. Files: [all .ts files]" --output-format json --yolo

[Gemini analyzes 150 files and returns]
{
  "response": "Security Issues Found (10 files):
  - SQL injection risk in db/queries.ts line 23
  - XSS vulnerability in components/UserInput.tsx line 67
  - Hardcoded API key in config/settings.ts line 12
  - Missing input validation in 5 API endpoints"
}

Me (Claude): Here are the security issues Gemini found. Let me help you fix them.
```

### Example 3: Data Pattern Recognition
```
You: I have user activity logs from the past month. Can Gemini find patterns?

Me: Perfect task for Gemini! Sending logs...

[Gemini Response]:
Patterns Found:
- 80% of errors occur between 2-4 AM (database backup window)
- Spike in 404s on /api/v2 endpoints (deprecated?)
- Users from EU region have 3x slower response times
- Mobile app makes 10x more API calls than web

Me (Claude): Based on these patterns, here's what we should fix first...
```

## When to Use Gemini vs Claude

### Use Gemini for:
- Large files/codebases (100+ files)
- Performance and optimization analysis
- Data pattern recognition
- Quick factual responses
- Processing logs, CSVs, large datasets

### Use Claude (me) for:
- Code generation and implementation
- Detailed reasoning and planning
- Complex problem-solving
- Interactive development workflow
- Writing documentation

### Use Both:
- Important decisions (get both perspectives)
- Architecture reviews (Claude for structure, Gemini for performance)
- Code review (Claude for logic, Gemini for optimization)

## Simple Syntax

Just ask naturally:

```
"Ask Gemini to..."
"Have Gemini check..."
"Can Gemini analyze..."
"Get Gemini's opinion on..."
```

I'll handle the communication and bring back the response!

## How It Works Technically

When you ask me to use Gemini, I:

1. **Take your question** and prepare the prompt
2. **Assess complexity** and choose model tier:
   - Flash tier for quick analysis
   - Pro tier for deep/complex tasks
3. **Look up the latest available model** in that tier
4. **Execute Gemini CLI** in headless mode:
   ```bash
   # Flash tier (fast) - I'll use the latest Flash model available
   gemini -m <latest-flash-model> -p "your prompt" --output-format json

   # Pro tier (thorough) - I'll use the latest Pro model available
   gemini -m <latest-pro-model> -p "your prompt" --output-format json
   ```
5. **Parse Gemini's JSON response**
6. **Present results** to you clearly
7. **Help implement** any suggestions

**CLI Options I Use:**
- `-m model-name` - Specify which Gemini model (I'll use latest Flash or Pro)
- `-p "prompt"` - Send prompt in headless mode
- `--output-format json` - Get structured output
- `--yolo` - Auto-proceed without confirmations (when appropriate)

That's it! No complex setup needed.

## Gemini CLI Capabilities

**Available Tools:**
- `read_file` - Read file contents
- `search_file_content` - Search within files using patterns
- `web_fetch` - Fetch content from web URLs

**Limitations:**
- Cannot write or edit files directly
- Cannot run shell commands
- Cannot execute code

**Workflow:** When Gemini identifies issues or optimizations, I (Claude) implement them using my full tool set (file editing, command execution, etc.).

## Security Note: Command Escaping

**When using CLI commands in scripts or automated workflows:**

- Always properly escape user input
- Use proper quoting for variables
- Avoid directly interpolating untrusted input into commands
- Validate input before passing to CLI tools

**Examples:**
```bash
# [NO] Dangerous - no escaping
user_input="some value"
gemini -p "$user_input"  # Could break with special characters

# [OK] Safe - proper quoting (Bash 4.4+)
user_input="some value"
gemini -p "${user_input@Q}"

# [OK] Safe - proper quoting (Bash 3.x compatible)
user_input="some value"
gemini -p "$(printf '%q' "$user_input")"

# [WARNING] This validation is VERY restrictive - for demonstration only!
# Real code validation should be comprehensive or use file-based input (shown below)
if [[ "$user_input" =~ ^[a-zA-Z0-9\ ]+$ ]]; then
    gemini -p "$user_input"
fi

# [RECOMMENDED] Use file-based input instead of inline validation
# This is safer and avoids escaping complexity entirely
```

**These agent examples show sanitized prompts. Always add appropriate escaping in production scripts.**

## Code Style Rules

### No Emojis in Application Source Code
- [NO] Never use emojis in **application** source code, code comments, or commit messages
- [OK] Emojis are acceptable in **user-facing tools** like installation scripts and CLI utilities
- [OK] Emojis are fine in conversational responses to user
- [OK] Use standard ASCII in application code: +, -, *, >, <, =, |, etc.
- [OK] Use text indicators in application code: [OK], [FAIL], [WARN], [INFO], [SUCCESS], [ERROR], [DONE]

**Clarification:** User-facing tools (like `install.sh`) can use emojis to improve UX. Application code (the software being built) should not.

