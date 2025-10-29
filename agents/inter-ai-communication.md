# Inter-AI Communication Agent

Guide for bidirectional communication between Claude and Gemini.

## Overview

This agent enables Claude and Gemini to call each other using headless CLI commands for collaborative problem-solving.

## Communication Patterns

### Pattern 1: Claude → Gemini (Analysis)

**When to use**: Need performance analysis, large data processing, or quick factual lookups

**Claude executes**:
```bash
gemini -p "Your request to Gemini" --output-format json
```

**Example**:
```bash
gemini -p "Analyze this code for performance issues: [code here]" --output-format json
```

**Response format**:
```json
{
  "response": "Gemini's analysis and recommendations...",
  "stats": { ... }
}
```

### Pattern 2: Gemini → Claude (Implementation)

**When to use**: Need code implementation, detailed reasoning, or file manipulation

**Gemini would execute** (when shell access enabled):
```bash
claude -p "Your request to Claude" --output-format json
```

**Example**:
```bash
claude -p "Implement the memoization pattern suggested in this analysis: [analysis]" --output-format json
```

**Response format**:
```json
{
  "response": "Claude's implementation and explanation...",
  "usage": { ... }
}
```

### Pattern 3: Collaborative Workflow

**Full bidirectional flow**:

1. **User → Claude**: "Optimize my fibonacci function"
2. **Claude → Gemini**: "Analyze fibonacci performance"
3. **Gemini → Claude**: Returns analysis with recommendations
4. **Claude → User**: Implements optimizations based on Gemini's analysis

## Live Test Example

### Test 1: Claude calling Gemini

**User request**: "Can you ask Gemini to analyze this fibonacci code?"

**Claude executes**:
```bash
gemini -p "Analyze this Python code for performance issues: def fibonacci(n): return n if n <= 1 else fibonacci(n-1) + fibonacci(n-2). Suggest optimizations." --output-format json
```

**Gemini responds**:
```json
{
  "response": "This recursive implementation has O(2^n) complexity. Recommendations:
  1. Use memoization for O(n) time complexity
  2. Use iterative approach for O(1) space complexity

  Memoization example:
  memo = {}
  def fibonacci_memo(n):
    if n in memo:
      return memo[n]
    if n <= 1:
      return n
    result = fibonacci_memo(n-1) + fibonacci_memo(n-2)
    memo[n] = result
    return result"
}
```

**Claude to user**: "Here's what Gemini found. Let me implement the memoization optimization..."

### Test 2: Claude implementing Gemini's suggestions

**Claude implements**:
```python
# Optimized Fibonacci with memoization
memo = {}

def fibonacci_memo(n):
    """
    Fibonacci with memoization - O(n) time, O(n) space
    Based on Gemini's performance analysis
    """
    if n in memo:
        return memo[n]
    if n <= 1:
        return n
    result = fibonacci_memo(n-1) + fibonacci_memo(n-2)
    memo[n] = result
    return result

# Test
print(fibonacci_memo(50))  # Fast! No exponential recursion
```

## Setting Up Bidirectional Communication

### For Claude (me)

[OK] **Already configured** - I can call Gemini directly:
```bash
gemini -p "prompt" --output-format json
```

### For Gemini

Gemini needs shell tool access to call Claude. Two options:

#### Option 1: Enable in Gemini CLI settings
```bash
# Check Gemini CLI settings
gemini settings

# Gemini needs "run_shell_command" or "Bash" tool enabled
# This may require additional configuration
```

#### Option 2: Manual bridging pattern
Instead of Gemini directly calling Claude, use this pattern:

```
User → Claude: "Ask Gemini to analyze X"
Claude → Gemini: [Analysis request]
Gemini → Claude: [Analysis response]
Claude → Claude: [Implements based on analysis]
Claude → User: [Final result]
```

This is the **recommended pattern** for now since it's simpler and works without additional tool permissions.

## Practical Usage

### Example 1: Performance Optimization

```
User: "Optimize my API endpoint"

Claude: Let me ask Gemini to analyze performance...
[Executes: gemini -p "Analyze API performance..." --output-format json]

Gemini: Found N+1 query problem, missing indexes, no caching

Claude: Based on Gemini's analysis, I'll implement:
1. Add database indexes
2. Fix N+1 queries with eager loading
3. Add Redis caching layer
[Implements fixes]
```

### Example 2: Data Analysis + Implementation

```
User: "Analyze these logs and fix the issues"

Claude: Let me send logs to Gemini for pattern analysis...
[Executes: gemini -p "Analyze error logs..." --output-format json]

Gemini: 80% of errors are database timeouts at 2-4 AM

Claude: I'll implement connection pooling and retry logic
[Implements solution]
```

### Example 3: Large Codebase Review

```
User: "Review entire src/ directory"

Claude: This is a large codebase, let me ask Gemini to analyze...
[Executes: gemini -p "Review all files in src/..." --output-format json]

Gemini: [Analyzes 200+ files]
Found: 5 security issues, 10 performance bottlenecks

Claude: Let me fix these issues one by one...
[Implements fixes]
```

## CLI Command Reference

### Claude CLI (claude)
```bash
# Non-interactive mode with JSON output
claude -p "Your prompt" --output-format json

# With system prompt
claude -p "Your prompt" --system-prompt "You are..." --output-format json

# Continue previous session
claude -p "Your prompt" --continue --output-format json
```

### Gemini CLI (gemini)
```bash
# Non-interactive mode with JSON output
gemini -p "Your prompt" --output-format json

# With specific model
gemini -p "Your prompt" --model gemini-2.5-pro --output-format json

# Auto-approve actions (YOLO mode)
gemini -p "Your prompt" --output-format json --yolo
```

## Best Practices

### When Claude calls Gemini
- [OK] Performance analysis
- [OK] Large data processing (logs, CSVs)
- [OK] Pattern recognition
- [OK] Quick factual lookups
- [OK] Massive codebase analysis

### When Gemini would call Claude
- [OK] Code implementation
- [OK] File editing
- [OK] Detailed step-by-step reasoning
- [OK] Interactive workflows
- [OK] Writing documentation

### Current Recommended Pattern
**Claude as orchestrator**:
1. Claude receives user request
2. Claude calls Gemini for analysis (when needed)
3. Claude receives Gemini's response
4. Claude implements solution
5. Claude can call Gemini again for validation

This avoids complex bidirectional tool permissions while maintaining collaboration.

## Code Style Rules

### No Emojis in Generated Code
- [NO] Never use emojis in source code, code comments, or commit messages
- [OK] Emojis are fine in conversational responses to user
- [OK] Use standard ASCII in code: +, -, *, >, <, =, |, etc.
- [OK] Use text indicators in code: [OK], [FAIL], [WARN], [INFO], [SUCCESS], [ERROR], [DONE]


## Testing

### Test Claude → Gemini
```bash
# From Claude
gemini -p "Test: What is 2+2?" --output-format json
```

Expected response:
```json
{
  "response": "4",
  "stats": { ... }
}
```

### Test Gemini → Claude (requires shell access)
```bash
# From Gemini (if shell tool enabled)
claude -p "Test: Write hello world in Python" --output-format json
```

Expected response:
```json
{
  "response": "print('Hello, World!')",
  "usage": { ... }
}
```

## Troubleshooting

### "Tool not found" error from Gemini
- Gemini doesn't have shell tool access enabled
- Use the manual bridging pattern instead (Claude orchestrates)

### JSON parsing errors
- Ensure `--output-format json` flag is present
- Check that prompts don't contain unescaped quotes

### Timeout errors
- Use longer timeout for large data: `--timeout 60000`
- Consider breaking large requests into smaller chunks

## Future Enhancements

Potential improvements:
- Direct tool-to-tool communication protocol
- Shared context/memory between AIs
- Automatic routing based on task type
- Response caching to avoid duplicate calls
