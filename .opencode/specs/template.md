# [Feature/Task Name]

**Date**: YYYY-MM-DD
**Author**: [Agent or Human]
**Status**: Draft | Approved | Implemented | Deployed

---

## Problem

**Clear description of what needs to be solved and why.**

What is the current situation?
What problem does this solve?
Who is affected by this problem?
What is the business/user value?

---

## Constraints

**Technical, business, and regulatory constraints that limit the solution space.**

- Technical constraints (e.g., must be backwards compatible)
- Business requirements (e.g., must launch by X date)
- Security requirements (e.g., GDPR compliance)
- Performance requirements (e.g., response time < 500ms)
- Resource constraints (e.g., budget, team size)
- Integration constraints (e.g., must work with existing system X)

---

## Proposed Approach

**Detailed description of how to implement the solution.**

### High-Level Design
[Overview of the solution architecture]

### Component Changes
- **Component A**: [What changes and why]
- **Component B**: [What changes and why]

### Data Model Changes
```
[Database schema changes, API contracts, etc.]
```

### API Changes
```
[New endpoints, modified endpoints, request/response formats]
```

### User Interface Changes (if applicable)
- [Wireframes, mockups, or descriptions]

### Technology Stack
- [Languages, frameworks, libraries to use]

---

## Architecture Changes

**Files and components that will be created or modified.**

### New Files
- `path/to/new/file.ts` - [Purpose]

### Modified Files
- `path/to/existing/file.ts` - [What changes]

### Database Changes
- `migrations/YYYY-MM-DD-migration-name.sql` - [Schema changes]

### Configuration Changes
- `config/app.yml` - [Config updates]

---

## Acceptance Criteria

**Specific, testable criteria that define when this work is complete.**

### Functional Requirements
- [ ] Criterion 1: Specific, measurable requirement
- [ ] Criterion 2: Another specific requirement
- [ ] Criterion 3: ...

### Non-Functional Requirements
- [ ] Performance: [Specific metric]
- [ ] Security: [Security requirement]
- [ ] Reliability: [Uptime/error rate requirement]
- [ ] Scalability: [Load requirement]

### User Experience
- [ ] UX criterion 1
- [ ] UX criterion 2

### Technical Quality
- [ ] Code coverage > 80%
- [ ] No linting errors
- [ ] Type-safe implementation
- [ ] Documentation updated

---

## Risks

**Potential risks and mitigation strategies.**

### Technical Risks
- **Risk**: [Description of risk]
  - **Likelihood**: High | Medium | Low
  - **Impact**: High | Medium | Low
  - **Mitigation**: [How to mitigate]

### Security Risks
- **Risk**: [Security concern]
  - **Mitigation**: [Security measures]

### Performance Risks
- **Risk**: [Performance concern]
  - **Mitigation**: [Performance optimization]

### Operational Risks
- **Risk**: [Deployment/ops concern]
  - **Mitigation**: [Operational safeguards]

---

## Task Breakdown

**Step-by-step implementation tasks, ordered by dependencies.**

### Phase 1: Foundation
1. [Task 1] - Estimated: X hours
2. [Task 2] - Estimated: X hours

### Phase 2: Core Implementation
3. [Task 3] - Estimated: X hours
4. [Task 4] - Estimated: X hours

### Phase 3: Integration
5. [Task 5] - Estimated: X hours

### Phase 4: Testing & Documentation
6. [Task 6] - Estimated: X hours

**Total Estimated Time**: X hours

---

## Testing Strategy

### Unit Tests
- [ ] Test case category 1
- [ ] Test case category 2

### Integration Tests
- [ ] Integration scenario 1
- [ ] Integration scenario 2

### End-to-End Tests
- [ ] E2E flow 1
- [ ] E2E flow 2

### Manual Testing
- [ ] Manual test case 1
- [ ] Manual test case 2

### Performance Testing
- [ ] Load test: [Scenario]
- [ ] Stress test: [Scenario]

### Security Testing
- [ ] Security scan
- [ ] Penetration testing (if applicable)

---

## Dependencies

**External dependencies that must be in place before implementation.**

### Technical Dependencies
- [ ] Dependency 1 (e.g., database upgrade)
- [ ] Dependency 2 (e.g., third-party API access)

### Team Dependencies
- [ ] Dependency 1 (e.g., design mockups)
- [ ] Dependency 2 (e.g., product requirements)

### External Dependencies
- [ ] Dependency 1 (e.g., vendor API)

---

## Rollout Plan

**How this change will be deployed and monitored.**

### Deployment Strategy
- [ ] Feature flag configuration
- [ ] Gradual rollout (canary/blue-green)
- [ ] Rollback procedure documented

### Monitoring
- [ ] Metrics to track
- [ ] Alerts to configure
- [ ] Dashboard updates

### Communication Plan
- [ ] Team notification
- [ ] User communication (if applicable)
- [ ] Documentation updates

---

## Success Metrics

**How we'll measure if this implementation is successful.**

### Technical Metrics
- Metric 1: [e.g., Response time < 500ms]
- Metric 2: [e.g., Error rate < 0.1%]

### Business Metrics
- Metric 1: [e.g., User engagement increased by X%]
- Metric 2: [e.g., Feature adoption rate]

### User Satisfaction
- Metric: [e.g., NPS score, user feedback]

---

## Open Questions

**Unresolved questions that need answers before implementation.**

1. Question 1?
   - **Answer**: [To be determined / Answered]

2. Question 2?
   - **Answer**: [To be determined / Answered]

---

## References

**Related documents, specs, tickets, or resources.**

- [Related Spec](link)
- [Design Document](link)
- [Issue #123](link)
- [API Documentation](link)
- [Research Document](link)

---

## Approvals

- [ ] Tech Lead: [Name]
- [ ] Product Manager: [Name]
- [ ] Security Team: [Name] (if security-sensitive)
- [ ] DBA: [Name] (if database changes)

---

## Revision History

| Date | Author | Change |
|------|--------|--------|
| YYYY-MM-DD | [Name] | Initial draft |
| YYYY-MM-DD | [Name] | Updated based on review |

---

## Notes

**Additional notes, context, or decisions made during planning.**

- Note 1
- Note 2
