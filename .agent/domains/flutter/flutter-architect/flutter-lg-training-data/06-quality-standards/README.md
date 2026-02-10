---
title: Quality Standards & Checklists
folder: 06-quality-standards
tags: [overview, quality, checklists, standards]
---

# Quality Standards 🏆

Before shipping your app.

## What's Inside

Checklists and standards for production-ready code.

### Planned Files

1. **[Code Review Checklist](code-review-checklist.md)** (coming soon)
   - Architecture check
   - Code patterns
   - Performance review
   - Security audit

2. **[Security Checklist](security-checklist.md)** (coming soon)
   - Credential storage
   - Input validation
   - Network security
   - Data privacy

3. **[Testing Guidelines](testing-guidelines.md)** (coming soon)
   - Unit tests
   - Widget tests
   - Integration tests
   - Test coverage

4. **[Performance Checklist](performance-checklist.md)** (coming soon)
   - Memory optimization
   - Build time
   - Frame rate
   - Startup time

## How to Use

### Before Code Review
1. Open Code Review Checklist
2. Check your code against each item
3. Fix any issues
4. Request review

### Before Shipping
1. Go through all checklists
2. Fix any failures
3. Get team approval
4. Deploy

### During Code Review
1. Use checklist as guide
2. Reference standards
3. Ask for improvements
4. Approve when ready

## Quality Levels

### MVP (Minimum Viable Product)
- [ ] Runs without crashes
- [ ] Basic functionality works
- [ ] No obvious memory leaks
- [ ] Error handling present

### Production Ready
- [ ] All quality checklists pass
- [ ] 80%+ code coverage
- [ ] No critical issues
- [ ] Performance acceptable
- [ ] Security reviewed

### Enterprise Ready
- [ ] All production standards
- [ ] 95%+ code coverage
- [ ] Load tested
- [ ] Security hardened
- [ ] Documented

## Quick Standards

### Code Quality
✅ No linting errors  
✅ Consistent naming  
✅ Small functions (< 50 lines)  
✅ Proper error handling  
✅ Separated concerns  

### Performance
✅ < 60 frame drops per minute  
✅ App starts in < 2 seconds  
✅ Memory stable over time  
✅ SSH operations timeout properly  
✅ No janky animations  

### Security
✅ No hard-coded credentials  
✅ Passwords encrypted in storage  
✅ Input validation on all user data  
✅ SSH certificates validated  
✅ No sensitive data in logs  

### Testing
✅ Critical paths tested  
✅ Error cases tested  
✅ Happy path tested  
✅ Edge cases considered  
✅ Tests maintainable  

## Anti-Patterns to Avoid

### Code Quality
❌ God classes (> 200 lines)  
❌ Deeply nested code  
❌ Duplicate code  
❌ Magic numbers  
❌ Commented-out code  

### Performance
❌ Janky animations  
❌ Memory leaks  
❌ Blocking UI thread  
❌ Unnecessary rebuilds  
❌ Large images uncompressed  

### Security
❌ Hard-coded credentials  
❌ Unencrypted passwords  
❌ No input validation  
❌ Unvalidated SSH certs  
❌ Sensitive data in logs  

## Standards Progression

### Week 1: Basic Standards
- [ ] Code doesn't crash
- [ ] No linting errors
- [ ] Basic error handling
- [ ] Comments on complex code

### Week 2: Quality Standards
- [ ] All checklists reviewed
- [ ] Tests for critical paths
- [ ] No hard-coded values
- [ ] Proper resource cleanup

### Week 3: Shipping Standards
- [ ] 80%+ test coverage
- [ ] Security reviewed
- [ ] Performance tested
- [ ] Documentation complete

## Next Steps

1. Pick a quality checklist
2. Review your code against it
3. Fix any issues found
4. Request code review
5. Iterate until passing

---

**Rule of Thumb**: Shipping bad code is faster than shipping good code for 2 days. Then it costs 100 days to fix.
