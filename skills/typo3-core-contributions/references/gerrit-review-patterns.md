# TYPO3 Gerrit Review Patterns - Real-World Insights

Based on analysis of actual merged patches from review.typo3.org, this document captures common review patterns, expectations, and best practices.

## Understanding Revision Counts

**Key Insight**: High revision counts (7-25 patch sets) are NORMAL and expected, not a sign of failure.

**Real Examples**:
- Change #90226: 24 patch sets (functional tests for Extbase FileUpload)
- Change #88519: 14 patch sets (breaking change - Record API)
- Change #91161: 9 patch sets (DI refactoring)
- Change #91284: 7 patch sets (pagetree performance)

**What causes multiple revisions**:
1. CI failures requiring fixes
2. Rebases due to base branch updates
3. Code quality refinements based on reviewer feedback
4. Architectural improvements suggested by core team
5. Edge case handling
6. Scope adjustments (e.g., backport constraints)

**Mindset**: Each revision makes the patch better. Multiple revisions show:
- Responsiveness to feedback
- Iterative improvement
- Collaboration with core team
- Thorough vetting process

## Common Reviewer Feedback Themes

### 1. Architectural Alignment

**Pattern**: Leverage framework patterns over custom solutions

**Example from #91161**:
```
Reviewer: "Just make this method no-op with only the trigger_error() and
remove $this->instances since the service locator will catch classes that
implements the interface automatically."
```

**Expectation**:
- Use dependency injection (DI) over manual instance management
- Leverage service locators for interface-based registration
- Follow TYPO3 framework patterns
- Avoid reinventing framework capabilities

**Best Practice**: Before implementing, check if TYPO3 framework already provides the pattern.

### 2. Configuration Best Practices

**Pattern**: Services.yaml configuration matters

**Example from #90226**:
```
Reviewer: "Why is Domain/Validator/ excluded here? This would prevent
validators from receiving dependency injection."
```

**Expectation**:
- Understand Services.yaml exclusion patterns
- Don't copy boilerplate without understanding
- Enable DI for all appropriate classes
- Reference official documentation for patterns

**Best Practice**: Review Services.yaml carefully, don't blindly copy from examples.

### 3. Performance Validation

**Pattern**: Performance claims require empirical evidence

**Example from #91284**:
```
Reviewer: "It performs much better. If a large number of pages are open,
there is still a very slight delay (milliseconds), but this should not
cause any problems."

Reviewer: "Nice one here, removing the expensive calls to this.nodes.find()
- reduced from O(n^(m²)) [30ms] to O(n) [2-3ms]"
```

**Expectation**:
- Test performance fixes in production-like environments
- Provide computational complexity analysis
- Measure actual performance improvements
- Document before/after metrics
- Multiple reviewers test independently

**Best Practice**: Include performance measurements in commit message or comments.

### 4. Breaking Changes Documentation

**Pattern**: Breaking changes need explicit communication

**Example from #88519**:
```
Reviewer: "The info that the item.record is now a record object, is
important to know for externals."

Reviewer: "That's breaking IMHO" (regarding API change)
```

**Expectation**:
- Document API changes affecting extension developers
- Use `[!!!]` prefix for breaking changes
- Add deprecations with `trigger_error()` for BC breaks
- Consider backport constraints (may limit to main branch)
- Provide migration examples

**Best Practice**: Always think about extension developers when changing public APIs.

### 5. Code Quality Standards

**Pattern**: Modern PHP practices and clean code

**Recurring feedback themes**:
- Use named arguments in function calls
- Separate concerns (split large functions into classes)
- Improve readability through refactoring
- Handle edge cases explicitly
- Remove unused code

**Best Practice**: Follow PSR-12 and modern PHP 8+ features.

### 6. Test Stability Focus

**Pattern**: Tests serve as API stability monitors

**Example from #90226**:
```
Reviewer: "These tests could serve as an important whistleblower with
extbase to monitor API stability and how frequently changes are needed."
```

**Expectation**:
- Tests should catch unintended API changes
- Test scope should be "as simple as possible and as complex as needed"
- Functional tests preferred over unit tests for integration points
- Tests validate real-world usage patterns

**Best Practice**: Write tests that detect breaking changes, not just code coverage.

### 7. Iterative Refinement Philosophy

**Pattern**: Patches improve through collaboration, not rejection

**Observed patterns**:
- Positive language: "I like! 🙌", "Awesome job!", "Nice one here"
- Constructive suggestions: "You could...", "Consider...", "What about..."
- Collaborative problem-solving: Multiple reviewers contribute ideas
- Incremental improvements: Each revision refines the approach

**Expectation**:
- Be responsive to feedback
- Implement suggested improvements
- Ask clarifying questions when needed
- Iterate toward excellence

**Best Practice**: View reviews as mentoring, not gatekeeping.

## Common Revision Patterns

### Pattern 1: CI Failure Cycle

**Typical flow**:
1. Initial submission
2. CI rejects (CGL, PHPStan, tests)
3. Fix CI issues
4. Resubmit
5. New CI issues found
6. Repeat until green

**Prevention**: Use typo3-conformance-skill and typo3-testing-skill BEFORE first submission.

### Pattern 2: Rebase Cycle

**Typical flow**:
1. Patch submitted
2. Base branch updated with other changes
3. Gerrit shows "needs rebase"
4. Rebase on latest main
5. Resolve conflicts
6. CI runs again (may reveal new issues)
7. Repeat as needed

**Prevention**: Rebase regularly during development, not just at submission.

### Pattern 3: Scope Adjustment

**Typical flow**:
1. Patch targets main + version branches
2. Review reveals backport complexity
3. Dependencies on other changes discovered
4. Scope changed to "main only"
5. Commit message updated

**Prevention**: Check dependencies before claiming backport compatibility.

### Pattern 4: Architecture Refinement

**Typical flow**:
1. Working implementation submitted
2. Reviewer suggests better framework pattern
3. Refactor to use framework capabilities
4. Simplify code by removing custom logic
5. May take 3-5 revisions to align

**Prevention**: Study framework patterns before implementing custom solutions.

## Review Timeline Expectations

Based on analyzed patches:

**Simple changes** (1-3 files, no breaking changes):
- Review starts: Within 1-2 days
- First feedback: 2-3 days
- Typical revisions: 2-5 patch sets
- Merge time: 1-2 weeks

**Complex changes** (multiple files, new features):
- Review starts: Within 3-5 days
- First feedback: 3-7 days
- Typical revisions: 7-15 patch sets
- Merge time: 2-4 weeks

**Breaking changes** (API changes, [!!!]):
- Review starts: Within 1-2 days
- First feedback: 1-3 days (architectural concerns raised early)
- Typical revisions: 10-20 patch sets
- Merge time: 3-6 weeks (due to documentation, deprecation)

**Performance fixes**:
- Review starts: Within 1-2 days
- Testing phase: 1-2 weeks (reviewers test in production)
- Typical revisions: 5-10 patch sets
- Merge time: 2-3 weeks

## Key Reviewers and Their Focus Areas

Based on observed patterns:

**Christian Kuhn (lolli)**:
- Architectural alignment
- Framework pattern usage
- Test quality and coverage
- Long-term maintainability

**Benni Mack**:
- Breaking change implications
- Extension developer impact
- API design
- Documentation completeness

**Stefan Bürk**:
- Configuration best practices
- Services.yaml patterns
- Dependency injection
- Code quality standards

**Pattern**: Different reviewers have different expertise areas. Address each reviewer's specific concerns.

## Best Practices from Real Reviews

### Do's

✅ **Respond to every comment**: Even if just "Done" or "Fixed in PS X"
✅ **Test in production-like environments**: Especially for performance fixes
✅ **Use framework patterns**: DI, service locators, event dispatchers
✅ **Document breaking changes**: Think about extension developers
✅ **Iterate based on feedback**: Don't defend, improve
✅ **Keep scope focused**: Don't expand scope during review
✅ **Update commit messages**: Reflect scope or approach changes
✅ **Add deprecations properly**: Use trigger_error() for BC breaks

### Don'ts

❌ **Don't take high revision counts personally**: They're normal and expected
❌ **Don't copy boilerplate blindly**: Understand configuration patterns
❌ **Don't skip testing**: CI will catch it anyway
❌ **Don't ignore architectural feedback**: Core team guides for good reasons
❌ **Don't rush rebases**: Test after rebasing
❌ **Don't claim performance without metrics**: Provide evidence
❌ **Don't break APIs without [!!!]**: Use proper prefixes
❌ **Don't argue with multiple reviewers**: If 2+ reviewers agree, they're probably right

## Handling Common Situations

### Situation 1: "My patch has 10 revisions already"

**Response**: This is normal! Changes #90226 had 24, #88519 had 14. Keep iterating.

**Action**:
1. Review all outstanding comments
2. Address each systematically
3. Test thoroughly after each change
4. Mark comments as resolved with explanation
5. Keep positive attitude

### Situation 2: "Reviewer suggested complete refactoring"

**Response**: Core team is guiding toward better patterns. This is mentoring.

**Action**:
1. Ask clarifying questions if needed
2. Study the suggested pattern
3. Implement as suggested
4. Don't defend original approach
5. Learn framework patterns for future

### Situation 3: "CI keeps failing after fixes"

**Response**: Each rebase can reveal new issues. This is expected.

**Action**:
1. Use typo3-conformance-skill locally
2. Use typo3-testing-skill for test failures
3. Validate BEFORE pushing
4. Consider environment differences
5. Ask for help if stuck

### Situation 4: "Scope changed from 'main + 13.4' to 'main only'"

**Response**: Backport complexity discovered during review. Common pattern.

**Action**:
1. Update commit message (Releases: main)
2. Update Forge issue target version
3. Don't argue - backporting is complex
4. Focus on getting main merged first
5. Backport can be separate patch later

## Learning from Reviews

### What to Extract from Reviews

When reading other reviews:
1. **Architectural patterns**: How do they structure code?
2. **Framework usage**: What TYPO3 APIs do they leverage?
3. **Testing approaches**: How do they test complex scenarios?
4. **Documentation style**: How do they explain breaking changes?
5. **Reviewer priorities**: What concerns get raised most?

### How to Improve

Based on review patterns:
1. **Study merged patches**: See what passes review
2. **Read reviewer comments**: Learn what matters to core team
3. **Use framework patterns**: Follow existing approaches
4. **Test thoroughly**: Validate locally before submission
5. **Be responsive**: Quick turnaround on feedback
6. **Stay positive**: Reviews are mentoring, not rejection

## Summary: Review Success Pattern

**Before submission**:
- ✅ Use typo3-conformance-skill
- ✅ Use typo3-testing-skill
- ✅ Study framework patterns
- ✅ Check Services.yaml configuration
- ✅ Test in realistic environment

**During review**:
- ✅ Respond to all comments promptly
- ✅ Implement suggestions positively
- ✅ Test after each revision
- ✅ Update commit message as needed
- ✅ Ask questions when unclear

**Mindset**:
- ✅ Multiple revisions are normal and healthy
- ✅ Reviews improve your code
- ✅ Core team is mentoring you
- ✅ Each iteration makes TYPO3 better
- ✅ You're learning framework patterns

## References

**Analyzed patches**:
- #90226: Extbase FileUpload functional tests (24 PS)
- #91161: DI in ExtractorService (9 PS)
- #91284: Pagetree performance (7 PS)
- #88519: Record API breaking change (14 PS)

**Review platform**: https://review.typo3.org

**Remember**: The best contributors don't have the fewest revisions - they have the most responsive and collaborative review interactions.
