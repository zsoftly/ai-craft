# AI Craft Agent Terminology Glossary

This glossary explains the different phase models and terminology used across AI Craft agents.

## Phase Models

Different agents use different phase models appropriate for their workflows:

### Development Agent (dev-agent.md)

**5-Phase Workflow:**

1. **Phase 1: Initial Analysis & Preparation** - Code analysis and architecture understanding
2. **Phase 2: Plan Review & Architecture Feedback** - Review technical plans
3. **Phase 3: Implementation & Development** - Code implementation with quality gates
4. **Phase 4: Code Review** - Comprehensive review and security checks
5. **Phase 5: Pull Request & Handoff** - PR creation and over-engineering checks

**When to use:** Complete feature development from analysis to pull request

### TDD Agent (tdd-agent.md)

**Red-Green-Refactor Cycle:**

- **RED** - Write a failing test first
- **GREEN** - Implement minimum code to make test pass
- **REFACTOR** - Improve code while keeping tests green

**When to use:** Test-driven development workflows

### Code Review Agent (code-review-agent.md)

**Single-Phase Review:**

- Focused on reviewing existing code
- Security and quality checks
- Git-based workflow

**When to use:** Code review and quality assurance

### Gemini Agents (gemini-dev.md, gemini-data.md)

**Delegation Model:**

- Claude orchestrates workflow
- Gemini handles analysis/data tasks
- Results returned to Claude for implementation

**When to use:** Performance analysis, large data processing

## Cross-Reference

| If you're familiar with... | Try this agent...              |
| -------------------------- | ------------------------------ |
| Waterfall methodology      | dev-agent (5 phases)           |
| Agile/TDD                  | tdd-agent (Red-Green-Refactor) |
| Code review process        | code-review-agent              |
| Data analysis              | gemini-data                    |
| Performance optimization   | gemini-dev                     |

## Terminology Alignment

### Quality Gates

All agents enforce quality gates during implementation:

- Lint and compile after code blocks
- Tests must pass before proceeding
- Security checks included

### Anti-Over-Engineering

Final phases include checks for:

- Unnecessary complexity
- Premature optimization
- Backwards compatibility (only when requested)

### Context Optimization

Agents use Task tool to spawn sub-agents for:

- Large codebase analysis
- Security reviews
- Data processing
- Saves main conversation context

## Choosing the Right Phase Model

**Use 5-Phase (dev-agent) when:**

- Building complete features
- Need structured progression
- Want separation of analysis and implementation
- Working on larger changes

**Use Red-Green-Refactor (tdd-agent) when:**

- Writing new code with tests
- Practicing TDD methodology
- Iterative development
- Testing is the primary concern

**Use Review Model (code-review-agent) when:**

- Code already exists
- Need quality assurance
- Security audit required
- Pre-deployment checks

**Use Delegation Model (gemini-\*) when:**

- Large datasets to analyze
- Performance-critical analysis
- Need alternative perspective
- Processing logs or metrics

## Common Questions

**Q: Can I mix phase models?**
A: Yes! Start with dev-agent Phase 1 (Analysis), then switch to tdd-agent for implementation, then back to dev-agent Phase 4 for review.

**Q: Why different models?**
A: Each model fits different workflows. Structured phases work well for complete features, while TDD's cycle is perfect for test-first development.

**Q: What if I only need part of a phase model?**
A: Jump to specific phases! For example, use dev-agent Phase 4 for just the review, or gemini-data for just analysis.

## Consistent Principles Across All Agents

Regardless of phase model, all agents share:

- **Code Style**: No emojis in application source code (only in user-facing tools)
- **Quality**: Tests, linting, compilation checks
- **Security**: Built-in security considerations
- **Simplicity**: Anti-over-engineering for pre-customer stage
- **Context Optimization**: Sub-agent delegation for heavy tasks
