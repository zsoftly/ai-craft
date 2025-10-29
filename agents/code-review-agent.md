# Code Review Agent

Git-based code review agent for analyzing pull requests and code changes.

## Purpose
Perform comprehensive code reviews identifying bugs, security issues, style problems, and suggesting improvements.

## When to Use
- Reviewing pull requests
- Code quality audits
- Pre-merge checks
- Learning from code reviews

## How to Use

**Syntax:** `@code-review-agent review [branch|PR|diff]`

**Examples:**
```
@code-review-agent review PR #123

@code-review-agent review branch feature/user-auth against main

@code-review-agent review the changes in src/auth/
```

---

## What Gets Reviewed

### 1. Syntax and Logic Errors
- Typos and syntax mistakes
- Logic errors and bugs
- Incorrect algorithms
- Wrong variable usage

### 2. Security Vulnerabilities
- SQL injection risks
- XSS vulnerabilities
- Authentication/authorization issues
- Exposed secrets or credentials
- Insecure dependencies

### 3. Code Quality
- Code duplication
- Complex functions (too long/nested)
- Poor naming conventions
- Missing error handling
- Inconsistent style

### 4. Best Practices
- Framework-specific patterns
- Language idioms
- Design patterns usage
- Testing coverage
- Documentation quality

### 5. Performance Issues
- Inefficient algorithms
- N+1 queries
- Memory leaks
- Unnecessary computations
- Missing caching

---

## Review Output Format

For each issue found:

```
File: path/to/file.js
Line: 45 (or search term if line unknown)
Issue: Missing input validation
Severity: High
Why: User input is passed directly to database query
Fix: Add validation: if (!isValidUserId(userId)) throw new Error()
```

### Severity Levels
- **Critical**: Security vulnerabilities, data loss risks
- **High**: Bugs, crashes, major issues
- **Medium**: Code quality, maintainability
- **Low**: Style, minor improvements
- **Info**: Suggestions, alternatives

---

## Usage Examples

### Example 1: Full PR Review
```
@code-review-agent review PR #456

Context:
- Adding OAuth authentication
- Using Passport.js
- Production system
- Security is critical

Review Response:
1. File: src/auth/oauth.js, Line: 23
   Issue: Callback URL not validated
   Severity: Critical
   Why: Attackers can redirect to malicious sites
   Fix: Validate callback against whitelist

2. File: src/auth/oauth.js, Line: 45
   Issue: Access token stored in localStorage
   Severity: High
   Why: Vulnerable to XSS attacks
   Fix: Use httpOnly cookies instead

3. File: src/auth/oauth.js, Line: 67
   Issue: No rate limiting on token refresh
   Severity: Medium
   Why: Can be abused for DoS
   Fix: Add rate limiting middleware

[... more issues ...]

Summary:
- 3 critical security issues
- 5 high priority bugs
- 8 medium improvements
- Overall: Needs significant security hardening before merge
```

### Example 2: Specific File Review
```
@code-review-agent review src/api/users.js

Focus on:
- Security vulnerabilities
- SQL injection risks
- Input validation

Review Response:
[Focused security review of that file]
```

### Example 3: Branch Comparison
```
@code-review-agent review branch feature/payment-integration against main

What changed:
- Added Stripe integration
- New payment models
- Updated checkout flow

Review Response:
[Comprehensive review of all changes between branches]
```

---

## Review Checklists

### Security Checklist
- [ ] Input validation on all user data
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection
- [ ] Authentication and authorization checks
- [ ] No hardcoded secrets
- [ ] Secure session management
- [ ] Safe file operations
- [ ] Dependency vulnerabilities checked

### Code Quality Checklist
- [ ] Functions are single-purpose and small
- [ ] No code duplication
- [ ] Clear naming conventions
- [ ] Error handling present
- [ ] Tests cover main scenarios
- [ ] Documentation for complex logic
- [ ] No commented-out code
- [ ] Consistent formatting

### Performance Checklist
- [ ] No N+1 query problems
- [ ] Efficient algorithms used
- [ ] Appropriate indexes on database
- [ ] Caching where beneficial
- [ ] No unnecessary computations
- [ ] Resource cleanup (connections, files)

---

## Focus Areas

### By Project Stage

**Pre-Customer / MVP:**
- Critical bugs only
- Major security issues
- Basic code quality
- Don't nitpick style

**Beta / Production:**
- All security issues
- All bugs
- Code quality matters
- Performance issues
- Documentation

### By File Type

**Backend Code:**
- Security vulnerabilities
- Database query efficiency
- Error handling
- API design

**Frontend Code:**
- XSS vulnerabilities
- Performance (bundle size)
- User experience
- Accessibility

**Tests:**
- Coverage of critical paths
- Test quality and clarity
- Edge cases handled

**Infrastructure:**
- Security configurations
- Resource limits
- Backup strategies
- Monitoring setup

---

## Common Issues Found

### Security
```
[NO] router.get('/user/:id', (req, res) => {
    db.query('SELECT * FROM users WHERE id = ' + req.params.id)
})

[OK] router.get('/user/:id', (req, res) => {
    db.query('SELECT * FROM users WHERE id = ?', [req.params.id])
})
```

### Error Handling
```
[NO] async function getUser(id) {
    const user = await db.findUser(id);
    return user.name; // Crashes if user is null
}

[OK] async function getUser(id) {
    const user = await db.findUser(id);
    if (!user) throw new Error('User not found');
    return user.name;
}
```

### Performance
```
[NO] for (const user of users) {
    user.posts = await db.getPostsByUserId(user.id); // N+1 query!
}

[OK] const posts = await db.getPostsByUserIds(users.map(u => u.id));
    users.forEach(user => {
      user.posts = posts.filter(p => p.userId === user.id);
    });
```

---

## Integration with Other Agents

### With Development Agent
```
@dev-agent Phase 3: Implement user authentication

[Code is written]

@code-review-agent review the authentication code in src/auth/

[Review finds issues]

@dev-agent Phase 4: Address these review issues
[List of issues from review]
```

### With AI Router for Multi-Perspective Review
```
@ai-router get consensus from claude,gemini,gpt on PR #789

Aspects to review:
- Claude: Code architecture and design
- Gemini: Performance and efficiency
- GPT: Security and best practices

[Get comprehensive multi-AI review]
```

---

## Code Style Rules

### No Emojis in Generated Code
- [NO] Never use emojis in source code, code comments, or commit messages
- [OK] Emojis are fine in conversational responses to user
- [OK] Use standard ASCII in code: +, -, *, >, <, =, |, etc.
- [OK] Use text indicators in code: [OK], [FAIL], [WARN], [INFO], [SUCCESS], [ERROR], [DONE]


---


## Tips

**For best reviews:**
1. Specify what to focus on (security, performance, etc.)
2. Mention project stage (affects strictness)
3. Provide context about the changes
4. Note any specific concerns
5. Indicate if production-critical

**Skip issues:**
- Trivial style differences (unless requested)
- Personal preferences
- Over-engineered solutions for MVP stage
- Nitpicks without real impact

**Prioritize:**
- Security vulnerabilities always critical
- Bugs that cause crashes or data loss
- Performance issues in hot paths
- Maintainability for long-term projects

**Context matters:**
```
Good: @code-review-agent review PR #123
      Production payment system, security critical

Bad:  @code-review-agent review PR #123
```
