# Scenario Checklist

This is a **manual regression checklist**, not an automated test suite. Its job is to make sure a change to an agent's `description`/rules or to `orchestrator-architect`'s triage logic doesn't silently break a routing behavior we already relied on.

**Scope — read this before trusting a "pass":** this repository has no application code of its own. Running a scenario here can only verify *routing* — which agent(s) get called, in what order, and which artifact (`PLAN.md`, `BACKLOG.md`, `ARCHITECTURE_IMPACT.md`, a diagram, a report) is expected. It cannot verify that the resulting code is actually good — that only shows up in a real consuming project with real code.

## How to use this file

Whenever you change any file under `.claude/agents/`, ask Claude Code (or `orchestrator-architect` directly) to **dry-run** the scenarios below — reason through which agent(s) it would invoke and in what order, without actually executing the work — and confirm each one still matches its expected path. Something like:

```
@orchestrator-architect Without actually doing the work, walk through
SCENARIOS.md and tell me, for each scenario, which agents you'd invoke
and in what order. Flag any that don't match the "Expected path" column.
```

Fix any mismatch before committing the prompt change.

## Scenarios

### 1. Simple, scoped change
**Prompt:** "@orchestrator-architect implement a new validation on the 'name' field."
**Expected path:** A — direct to implementation.
**Expected agents:** `backend-architect` and/or `frontend-engineer`, depending on where the field lives.
**Expected artifact:** `PLAN.md`, code diff.
**Why it matters:** confirms trivial requests don't get routed through unnecessary analysis overhead.

### 2. Multi-agent feature, still clearly scoped
**Prompt:** "@orchestrator-architect implement a password reset flow: generate a token, email it, add a reset screen, log the attempt with trace_id."
**Expected path:** A — direct to implementation (touching several agents is not, by itself, a reason to route through analysis).
**Expected agents:** `data-telemetry-architect`, `ui-ux-design-system`, `backend-architect`/`frontend-engineer`, `devops-secops-engineer`, `product-qa-reviewer`.
**Expected artifact:** `PLAN.md`, code diff.
**Why it matters:** confirms "touches multiple layers" doesn't get confused with "needs product-analyst" — the trigger for path B is ambiguity/scope, not agent count.

### 3. PRD / large or ambiguous request
**Prompt:** "@orchestrator-architect here's the PRD for the referral program (file attached), let's start on this."
**Expected path:** B — requirements analysis first.
**Expected agents:** `product-analyst` → `solutions-architect` → (per selected story) the usual implementation agents.
**Expected artifact:** `BACKLOG.md`, `ARCHITECTURE_IMPACT.md`, then `PLAN.md` per story.
**Why it matters:** confirms a document-shaped or multi-feature request doesn't get treated as a single atomic task.

### 4. Screen from an image/Figma/Lovable, with backend implications
**Prompt:** "@orchestrator-architect here's the checkout screen layout (image attached), implement it including whatever's needed on the backend."
**Expected path:** A (or B if the PRD/ambiguity criteria also apply).
**Expected agents:** `ui-ux-design-system` **first**, then `backend-architect` (scoped explicitly to any data/API need the spec calls out) and `frontend-engineer`.
**Expected artifact:** a design spec from `ui-ux-design-system`, `PLAN.md` naming the backend work explicitly, code diff.
**Why it matters:** confirms a visual reference doesn't skip design-token review, and that implied backend work doesn't get silently dropped.

### 5. Qualitative style change, no reference attached
**Prompt:** "@orchestrator-architect make screen 'A' feel more executive."
**Expected path:** A.
**Expected agents:** `ui-ux-design-system` first (interprets the brief into token changes), then `frontend-engineer`.
**Expected artifact:** a token-change rationale from `ui-ux-design-system`, code diff.
**Why it matters:** confirms a subjective brief without an attached image still goes through design review instead of being improvised by `frontend-engineer` alone.

### 6. Proactive architecture/performance/security audit
**Prompt:** "@orchestrator-architect based on the current codebase, what architectural improvements would you recommend for performance and security?"
**Expected path:** C — diagnostic (read-only).
**Expected agents:** `solutions-architect` (+ `devops-secops-engineer` if it's infra/dependency-specific).
**Expected artifact:** a prioritized recommendation report. No `PLAN.md`, no diff, no commit.
**Why it matters:** confirms an analysis-only request doesn't get treated as an implicit instruction to start changing code.

### 7. System diagram request
**Prompt:** "@orchestrator-architect draw a diagram of the current system architecture and its integrations."
**Expected path:** C — diagnostic (read-only).
**Expected agents:** `solutions-architect`.
**Expected artifact:** a Mermaid diagram returned directly. No `PLAN.md`, no diff, no commit.
**Why it matters:** confirms diagram requests are recognized as a distinct diagnostic output, not folded into a coding task.

### 8. Onboarding this template into an existing codebase
**Prompt:** "@orchestrator-architect let's start using this on the existing app." (no `CONTEXT.md` present, real code already exists)
**Expected path:** Onboarding check (step 0), before triage.
**Expected agents:** `solutions-architect` drafts `CONTEXT.md` by scanning the codebase.
**Expected artifact:** `CONTEXT.md` (stack/structure/scripts filled in, product sections left as placeholders).
**Why it matters:** confirms the orchestrator doesn't ask the human to hand-fill a blank template when the codebase can answer most of it, and doesn't skip straight to triage on a project it doesn't understand yet.

### 9. Opening a PR after a push
**Prompt:** "@orchestrator-architect implement a new validation on the 'name' field," followed by approving the commit and push.
**Expected path:** A, through to the versioning step.
**Expected agents:** `backend-architect`/`frontend-engineer`, then the orchestrator itself for git operations.
**Expected artifact:** code diff, a branch, a commit, a push — and a **separate** question ("want me to open a PR?") before any `gh pr create` runs.
**Why it matters:** confirms approving a push is never silently treated as approving a PR too — they're gated independently, same as commit vs. push.

---

*This file is the source of truth for "what the agents must be able to handle." The README's summary table is derived from it — update this file first, then reflect changes in the README.*
