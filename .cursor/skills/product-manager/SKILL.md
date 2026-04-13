---
name: product-manager
description: Defines lightweight product management workflow: clarify problem, users, success metrics, scope, and release plan. Use when the user asks for a plan/roadmap, prioritization, monetization, metrics, or feature requirements (PRD/spec) for this Flutter app.
---

# Product Manager (Lightweight)

## Quick start (default workflow)

When the user asks for a “plan”, “roadmap”, or “requirements”, do this:

1. **Problem**: what user pain or business need are we solving?
2. **Users**: who is this for (primary + secondary)?
3. **Outcome**: what changes if we do this well?
4. **Success metrics** (pick 1–3): how we’ll know it worked.
5. **Scope**:
   - **In-scope** (must have for the first release)
   - **Out-of-scope** (explicitly not doing now)
6. **Requirements**: short, testable bullets.
7. **Release plan**:
   - smallest end-to-end slice (MVP)
   - milestones + acceptance criteria
   - risks + mitigations

If details are missing, infer a reasonable default and proceed. Keep it lightweight and shippable.

## Principles (startup practice)

- **Start with the user**: ship value, then iterate with data.
- **Metrics beat opinions**: define what success looks like upfront.
- **Small releases win**: prefer an MVP that is end-to-end over a big-bang launch.
- **Trade-offs are explicit**: make scope cuts visible and intentional.

## Prioritization (default = RICE-lite)

### RICE-lite (default)
- **Reach**: how many users/sessions it touches
- **Impact**: Low/Med/High
- **Confidence**: Low/Med/High
- **Effort**: person-days

Rank by \((Reach × Impact × Confidence) / Effort\). Keep it rough.

### MoSCoW (stakeholder-friendly)
Must / Should / Could / Won’t (this cycle).

## Templates (copy/paste)

### PRD-lite (1 page)

```markdown
## Problem

## Users
- Primary:
- Secondary:

## Outcome (definition of done)
- …

## Success metrics (pick 1–3)
- …

## Scope
**In-scope (MVP)**
- …

**Out-of-scope (not now)**
- …

## Requirements (testable)
- …

## Non-functional requirements
- Performance:
- Security/privacy:
- Accessibility:
- Analytics/observability:

## Risks + open questions
- Risk:
  - Mitigation:
- Open question:
  - Decision by:
```

### Release plan (MVP → v1)

```markdown
## Release plan

### MVP (smallest end-to-end slice)
- Outcome:
- What’s included:
- Acceptance criteria:
  - [ ] …

### v1 (after MVP)
- Improvements:
  - …

## Rollout
- Internal testing:
- Beta (if any):
- Full release:

## Analytics (events + funnels)
- Event:
- Funnel:
```

### Weekly product update (exec-friendly)

```markdown
## This week
- Shipped:
- Learned (from data / user feedback):
- Decisions:

## Next week
- Top priorities:

## Risks / blockers
- Risk/blocker:
  - What we’re doing:
  - Help needed (if any):
```

## Common triggers (apply this skill)

Apply when the user mentions:
- product plan, roadmap, PRD/spec, requirements
- prioritization, MVP, “what should we build first”
- metrics, funnels, conversion, retention, churn
- pricing, monetization, paywall, subscriptions

