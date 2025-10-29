# Gemini Data Agent

Use Gemini for data analysis, log processing, and pattern recognition.

## When to Use
- Analyzing large datasets
- Processing log files
- Finding patterns in data
- CSV/JSON analysis
- Performance metrics analysis

## Model Selection

**I (Claude) will use your configured Gemini model:**

- **Flash models** - For fast log analysis, simple pattern finding, quick data insights
  - Best for: Error logs, CSV analysis, usage patterns, metrics review
  - Example: `gemini-2.0-flash-exp`, `gemini-1.5-flash`

- **Pro models** - For complex data analysis, deep pattern recognition, predictive insights
  - Best for: Large-scale trend analysis, anomaly detection, complex correlations
  - Example: `gemini-2.0-pro-exp`, `gemini-1.5-pro`

**How to check available models:**
```bash
# List available Gemini models
gemini models list

# Or check your current default model
gemini config get model
```

I'll use the model configured in your Gemini CLI settings, or you can specify one when needed.

## How I (Claude) Call Gemini for Data Analysis

When you ask me to analyze data with Gemini, I will:
1. Determine analysis complexity (simple → Flash, complex → Pro)
2. Execute Gemini CLI with appropriate model:

```bash
# Quick analysis (Flash - most data tasks)
gemini -m gemini-2.0-flash-exp -p "Analyze this data: [your data/logs]" --output-format json

# Deep analysis (Pro - complex patterns)
gemini -m gemini-2.0-pro-exp -p "Analyze this data: [your data/logs]" --output-format json

# Or use your configured default model
gemini -p "Analyze this data: [your data/logs]" --output-format json
```

**Note:** Model names in examples may not be current. Check `gemini models list` for available models.

This runs Gemini in headless mode and returns structured results I can present to you.

**Context Optimization:**
For large dataset analysis or complex data processing tasks, I will use the Task tool to spawn a `general-purpose` sub-agent to:
- Read and prepare large log files or datasets
- Execute Gemini CLI commands with the data
- Parse and structure Gemini's analytical findings
- Return actionable insights to me
- Save your main conversation context for implementing fixes

This allows efficient data analysis while keeping your main context focused on solutions.

## What Gemini Can Analyze

### Log Files
```
Ask Gemini to analyze my server logs from the past week
- Find error patterns
- Identify unusual activity
- Spot performance issues
```

### CSV/Spreadsheet Data
```
Have Gemini analyze this user data CSV:
- Find usage patterns
- Identify outliers
- Suggest improvements
```

### Performance Metrics
```
Get Gemini to review our API response times:
- Identify slow endpoints
- Find bottlenecks
- Suggest optimizations
```

### User Behavior
```
Ask Gemini to analyze user activity:
- Common user flows
- Drop-off points
- Feature usage patterns
```

## Examples

### Example 1: Error Log Analysis
```
You: Can Gemini analyze logs/error.log from the past month?

Me (Claude): Let me send the error logs to Gemini with the latest Flash model for quick analysis...

[I look up and use the latest Flash model for fast log processing]
gemini -m <latest-flash-model> -p "Analyze this error log for patterns, top errors, and root causes. Find: frequency, timing patterns, affected endpoints. Log: [error.log contents]" --output-format json --yolo

[Gemini returns]
{
  "response": "Error Log Analysis (45,000 entries):

  Top Errors:
  1. Database timeout (15,000 occurrences - 33%)
     Peak time: 2-4 AM daily
     Affecting: /api/users endpoint

  2. Memory errors (8,000 occurrences - 18%)
     Pattern: After 6 hours uptime
     Cause: Gradual memory leak

  3. 404 errors (5,000 occurrences - 11%)
     Source: Broken links from old marketing email

  Recommendation: Fix database timeout first"
}

Me (Claude): Here's what Gemini found. The database timeout is your biggest issue - let me help fix it.
```

### Example 2: User Data Analysis
```
You: Have Gemini analyze data/users.csv (50,000 users)

Me (Claude): I'll send the user data to Gemini with the latest Pro model for deep behavioral analysis...

[I look up and use the latest Pro model for complex pattern recognition]
gemini -m <latest-pro-model> -p "Analyze this user data CSV for behavioral patterns, drop-offs, usage trends, and churn factors. Find actionable insights. Data: [users.csv contents]" --output-format json

[Gemini analyzes and returns]
{
  "response": "User Analysis (50,000 users):

  Critical Findings:
  - 70% drop off at onboarding step 3 (email verification)
  - Active users: 45 min/day average (peak: 9-11 AM)
  - Mobile churn rate: 3x higher than desktop
  - Feature usage: 80% stick to basic features

  Root Causes:
  - Email verification friction
  - Poor mobile UX
  - Feature overload

  Recommendations:
  1. Remove/simplify email verification
  2. Improve mobile interface
  3. Hide/remove unused advanced features"
}

Me (Claude): Based on Gemini's analysis, let's tackle the onboarding drop-off first.
```

### Example 3: Performance Analysis
```
You: Ask Gemini to analyze our API performance data

[Gemini Response]:
API Performance Analysis (1M requests):

Slow Endpoints:
- POST /api/search: 2.5s average (should be <100ms)
  Cause: No database indexes on search fields

- GET /api/users/{id}/posts: 1.8s average
  Cause: N+1 query problem (fetching posts one by one)

- GET /api/dashboard: 1.2s average
  Cause: No caching, queries multiple tables

Fast Endpoints:
- GET /api/health: 5ms ✓
- POST /api/login: 50ms ✓

Impact: Fixing top 3 slow endpoints would improve 80% of requests
```

## Data Formats Gemini Handles

### Text Formats
- Log files (.log, .txt)
- CSV files
- JSON files
- Markdown tables
- Plain text data

### Code Analysis
- Performance profiling output
- Test coverage reports
- Build logs
- Git logs

### Metrics
- Time series data
- Response times
- Error rates
- User analytics

## Common Patterns

### Pattern 1: Find the Problem
```
Step 1: "Gemini, analyze these logs and find what's causing errors"
Step 2: [Gemini identifies root cause]
Step 3: "Claude, help me fix this issue"
```

### Pattern 2: Understand Usage
```
Step 1: "Gemini, analyze user behavior data"
Step 2: [Gemini finds patterns]
Step 3: "Claude, help me improve based on these patterns"
```

### Pattern 3: Optimize Performance
```
Step 1: "Gemini, find performance bottlenecks in metrics"
Step 2: [Gemini identifies slow parts]
Step 3: "Claude, implement these optimizations"
```

## Code Style Rules

### No Emojis in Application Source Code
- [NO] Never use emojis in **application** source code, code comments, or commit messages
- [OK] Emojis are acceptable in **user-facing tools** like installation scripts and CLI utilities
- [OK] Emojis are fine in conversational responses to user
- [OK] Use standard ASCII in application code: +, -, *, >, <, =, |, etc.
- [OK] Use text indicators in application code: [OK], [FAIL], [WARN], [INFO], [SUCCESS], [ERROR], [DONE]

**Clarification:** User-facing tools (like `install.sh`) can use emojis to improve UX. Application code (the software being built) should not.


---


## Tips for Best Results

### Be Specific
```
Good: "Analyze error.log for database timeout patterns"
Bad:  "Look at the logs"
```

### Provide Context
```
Good: "Analyze user data (50k users, e-commerce site, focusing on churn)"
Bad:  "Analyze users.csv"
```

### Ask for Actionable Insights
```
Good: "Find patterns and suggest 3 specific improvements"
Bad:  "Tell me about the data"
```

## What Gemini Can Handle

- ✓ Massive context (entire codebases!)
- ✓ Hundreds of files at once
- ✓ Very large log files
- ✓ Big CSV datasets
- ✓ Lots of data

No need to split up files!

## How It Works Technically

When you ask me to use Gemini for data analysis, I:

1. **Read your data** (logs, CSV, metrics, etc.)
2. **Assess complexity** and choose model tier:
   - Flash tier for most data tasks (fast, accurate)
   - Pro tier for complex patterns and deep insights
3. **Look up the latest available model** in that tier
4. **Execute Gemini CLI** in headless mode:
   ```bash
   # Flash tier (most data analysis) - I'll use latest Flash model
   gemini -m <latest-flash-model> -p "Analyze this data: [data]" --output-format json --yolo

   # Pro tier (complex patterns) - I'll use latest Pro model
   gemini -m <latest-pro-model> -p "Analyze this data: [data]" --output-format json --yolo
   ```
5. **Parse Gemini's analysis** from JSON response
6. **Present insights** clearly to you
7. **Help implement** recommended fixes

**CLI Options for Data Analysis:**
- `-m model-name` - Specify which Gemini model (I'll use latest Flash or Pro)
- `-p "prompt"` - Send data analysis request
- `--output-format json` - Get structured insights
- `--yolo` - Auto-proceed (Gemini handles large data automatically)

Just ask me:
```
"Can Gemini analyze..."
"Have Gemini find patterns in..."
"Ask Gemini to review..."
```

I'll execute the command and bring back insights!

## Gemini CLI Capabilities

**Available Tools:**
- `read_file` - Read file contents (perfect for log files, CSVs)
- `search_file_content` - Search within files using patterns
- `web_fetch` - Fetch content from web URLs

**Limitations:**
- Cannot write or edit files directly
- Cannot run shell commands
- Cannot execute code

**Workflow:** When Gemini identifies patterns or issues in data, I (Claude) implement fixes using my full tool set (file editing, command execution, etc.).
