# Gemini Development Agent

Use Google's latest Gemini model for development tasks.

## When to Use
- Large codebases (Gemini handles massive context!)
- Performance analysis
- Need a different perspective from Claude
- Processing lots of code files at once

## Model
Uses: **Latest Gemini model** (automatically selected for best results)

## How I (Claude) Call Gemini

When you ask me to use Gemini, I'll execute the Gemini CLI in headless mode:

```bash
gemini -p "Your request here" --output-format json
```

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

Me (Claude): Let me call Gemini to analyze the performance...

[I execute headless command]
gemini -p "Analyze these FastAPI files for performance issues. Focus on database queries, caching, and bottlenecks. Files: [src/api/ contents]" --output-format json

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

Me (Claude): I'll send all .ts files to Gemini for security analysis...

[I execute]
gemini -p "Review these TypeScript files for security vulnerabilities: SQL injection, XSS, exposed secrets, input validation. Files: [all .ts files]" --output-format json --yolo

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
2. **Execute Gemini CLI** in headless mode:
   ```bash
   gemini -p "your prompt" --output-format json
   ```
3. **Parse Gemini's JSON response**
4. **Present results** to you clearly
5. **Help implement** any suggestions

**CLI Options I Use:**
- `-p "prompt"` - Send prompt in headless mode
- `--output-format json` - Get structured output
- `--yolo` - Auto-proceed without confirmations (when appropriate)

That's it! No complex setup needed.

## Code Style Rules

### No Emojis in Generated Code
- [NO] Never use emojis in source code, code comments, or commit messages
- [OK] Emojis are fine in conversational responses to user
- [OK] Use standard ASCII in code: +, -, *, >, <, =, |, etc.
- [OK] Use text indicators in code: [OK], [FAIL], [WARN], [INFO], [SUCCESS], [ERROR], [DONE]

