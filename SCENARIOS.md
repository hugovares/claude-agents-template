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

This dry-run checks *behavior*. It doesn't catch a purely structural mistake — a renamed agent that some other file still refers to by its old name, or `orchestrator-architect`'s `Agent()` allowlist drifting out of sync with the agents that actually exist. For that, run `./scripts/check-agent-refs.sh` — a boring, deterministic grep-based check, not an agent — alongside the dry-run whenever you rename, add, or remove an agent file.

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
**Expected artifact:** `BACKLOG.md`, `ARCHITECTURE_IMPACT.md`, then `PLAN.md` per story — and once `product-qa-reviewer` approves that story's delivery, `orchestrator-architect` marks it `Done` in `BACKLOG.md` itself before moving on.
**Why it matters:** confirms a document-shaped or multi-feature request doesn't get treated as a single atomic task, and that `BACKLOG.md` actually gets updated on completion instead of staying frozen at "Not Started" forever.

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
**Expected agents:** `solutions-architect` (application/architecture-level security) **and** `devops-secops-engineer` (dependency/infra security) — a general, unqualified "security" ask goes to both by default, merged into one report, since their scopes are complementary rather than overlapping.
**Expected artifact:** a single prioritized recommendation report. No `PLAN.md`, no diff, no commit.
**Why it matters:** confirms an analysis-only request doesn't get treated as an implicit instruction to start changing code, and that "security" doesn't get arbitrarily assigned to just one of the two agents that legitimately own a piece of it.

### 7. System diagram request
**Prompt:** "@orchestrator-architect draw a diagram of the current system architecture and its integrations."
**Expected path:** C — diagnostic (read-only).
**Expected agents:** `codebase-cartographer`.
**Expected artifact:** a Mermaid diagram returned directly. No `PLAN.md`, no diff, no commit.
**Why it matters:** confirms diagram requests are recognized as a distinct diagnostic output, not folded into a coding task, and routed to the descriptive/mechanical specialist rather than the higher-cost judgment one.

### 8. Onboarding this template into an existing codebase
**Prompt:** "@orchestrator-architect let's start using this on the existing app." (no `CONTEXT.md` present, real code already exists)
**Expected path:** Onboarding check (step 0), before triage.
**Expected agents:** `codebase-cartographer` drafts `CONTEXT.md` by scanning the codebase.
**Expected artifact:** `CONTEXT.md` (stack/structure/scripts filled in, product sections left as placeholders).
**Why it matters:** confirms the orchestrator doesn't ask the human to hand-fill a blank template when the codebase can answer most of it, doesn't skip straight to triage on a project it doesn't understand yet, and uses the cheaper descriptive specialist for a mechanical task rather than the Opus-tier judgment one.

### 9. Handing off a commit/push/PR for the human to run
**Prompt:** "@orchestrator-architect implement a new validation on the 'name' field," followed by "looks good, let's ship it."
**Expected path:** A, through to the versioning hand-off.
**Expected agents:** `backend-architect`/`frontend-engineer` for the change; `orchestrator-architect` prepares the diff, branch name, and drafted commit message — it does not attempt `git commit`/`push`/`checkout` itself, and neither does any other agent.
**Expected artifact:** code diff, a drafted Conventional Commits message, and a copy-pasteable block of the exact `git`/`gh` commands for the human to run themselves. No agent-executed commit, push, or PR — `git commit *`, `git push *`, `git checkout *`, and `gh pr create *`/`pr merge *`/`release create *` are all in `permissions.deny`.
**Why it matters:** confirms the orchestrator never tries a denied command "just in case," and that opening a PR is still presented as the human's separate decision (a drafted `gh pr create` command, not something bundled into the push) — even though nothing here is agent-executed anymore. This scenario replaced an earlier "ask, then delegate execution" design that failed in real use: a delegated sub-agent can't actually pause and wait for a live reply, so `ask` couldn't reliably guarantee consent — only `deny` closes that gap mechanically.

### 10. Legacy codebase review
**Prompt:** "@orchestrator-architect I inherited this repo. Help me understand what it does, and suggest improvements for modernization, optimization, tests, and security."
**Expected path:** Onboarding check (step 0) first, then C — diagnostic (read-only), fanning out to more than one specialist.
**Expected agents:** `codebase-cartographer` drafts `CONTEXT.md` (the "what does it do" part, one codebase scan); then `solutions-architect` (architecture/modernization/performance/app-security — reusing that fresh `CONTEXT.md` instead of re-scanning blind), `devops-secops-engineer` (dependency/infra security), and `product-qa-reviewer` (test coverage and quality, including whether mutation testing would reveal weak tests) each contribute to one combined report.
**Expected artifact:** `CONTEXT.md`, then a single organized report (not three or four disconnected ones). No `PLAN.md`, no diff, no commit — this is read-only until the user picks something to act on.
**Why it matters:** confirms a broad "review this legacy repo" request triggers onboarding *and* a multi-specialist diagnostic, instead of being handled by a single agent guessing at the full scope alone — and that the codebase only gets scanned once, not twice, for the two different purposes.

### 11. Test-quality audit via mutation testing
**Prompt:** "@orchestrator-architect how good are our tests on the payment module, really? Not just coverage — would they catch a real bug?"
**Expected path:** C — diagnostic (read-only).
**Expected agents:** `product-qa-reviewer`.
**Expected artifact:** an assessment of test-suite quality (recommending/running mutation testing where relevant), returned as a report. No `PLAN.md`, no diff, no commit.
**Why it matters:** confirms "do we have tests" and "are our tests actually good" are recognized as different questions — high coverage with weak assertions shouldn't read as a pass.

### 12. Explicit "read-only, don't implement" instruction mid-session
**Prompt:** "@orchestrator-architect do a read-only check after commit X. Don't implement anything, don't delegate implementation to sub-agents — I just want the report."
**Expected path:** C — diagnostic (read-only), same as any other diagnostic request, but the override is absolute: no `PLAN.md` created or rewritten, no file touched outside the report itself, no sub-agent invoked with implementation authority — even if the findings look small and obviously worth fixing.
**Expected agents:** whichever diagnostic specialist(s) actually fit the request's content (per scenarios 6/10/11), and nothing else.
**Expected artifact:** the diagnostic report only. No `PLAN.md`, no diff, no commit.
**Why it matters:** confirms an explicit inline "don't implement"/"don't delegate" instruction overrides classification outright, rather than being one more signal weighed against how actionable the findings look. This failed once in real use: told exactly this, the orchestrator rewrote `PLAN.md` into a 7-task plan and executed three of its tasks anyway (logging/PII masking, a repository projection change, and a use-case transaction) — uncommitted, but without authorization. Dry-running this scenario after any change to the triage step confirms the override survives.

---

*This file is the source of truth for "what the agents must be able to handle." The README's summary table is derived from it — update this file first, then reflect changes in the README.*
