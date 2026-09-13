# Claude Agents Template Base 🚀

> **A reusable multi-agent setup for Claude Code: specialist sub-agents, engineering guardrails, and a human-in-the-loop workflow.**

`claude-agents-template` bootstraps a new project with a coordinated set of Claude Code sub-agents, a shared engineering rulebook (`CLAUDE.md`), and a project-context template (`CONTEXT.md`) — so every new repo starts with the same guardrails and specialist coverage instead of a blank `.claude/` folder.

---

## 🏛 Architecture

The suite follows a **Coordinator/Orchestrator pattern**. Every request first goes through a triage step in `orchestrator-architect`, which sorts it into one of three paths: straight to implementation, through requirements/architecture analysis first, or — if it's not asking for a code change at all — a read-only diagnostic that never touches the codebase.

**Step 1 — Triage** (`orchestrator-architect` reads the request and picks one path):

```text
[ Developer's request ] --> [ orchestrator-architect: triage ] --> one of:

  A) Simple, scoped, clear acceptance criterion
     --> go straight to Step 2 below.

  B) Ambiguous, multi-feature, or a PRD/spec document
     --> [ product-analyst ]        writes/updates BACKLOG.md
     --> [ solutions-architect ]    writes ARCHITECTURE_IMPACT.md
         (significant impact found? --> stop, ask for human approval)
     --> pick a story, go to Step 2 below.

  C) Diagnostic — audit, architectural/security/performance/test-quality
     recommendations, a system diagram, or a legacy-codebase review
     (no code change asked for)
     --> [ codebase-cartographer ]    a diagram, or CONTEXT.md for onboarding
     --> [ solutions-architect ]      architecture/performance/app-security
     --> [ devops-secops-engineer ]   infra/dependency security
     --> [ product-qa-reviewer ]      test coverage/quality
         (only the specialists the request actually needs get called —
         an unqualified "security audit" always calls both
         solutions-architect and devops-secops-engineer, not just one)
     --> one combined report or diagram returned to the user. Flow ends
         here: no PLAN.md, no delegation, no git diff.
```

**Step 2 — Implementation** (only reached from paths A or B above):

```text
                   [ orchestrator-architect ]  <-- writes PLAN.md, delegates via the Agent tool
                                 │
      ┌──────────────────────────┼──────────────────────────┬──────────────────────────┐
      ▼                          ▼                          ▼                          ▼
[backend-architect]      [frontend-engineer]      [ui-ux-design-system]      [data-telemetry-architect]
      │                          │                          │                          │
      └──────────────────────────┴──────────────────────────┴──────────────────────────┘
                                 │
                                 ▼  (code + tests)
                      [devops-secops-engineer]   <-- validates Docker / CI
                                 │
                                 ▼
                       [product-qa-reviewer]     <-- runs the test suite
                                 │
                                 ▼
                        [ git diff on screen ]   <-- with a drafted commit message
                                 │
                                 ▼
                      [ you run it yourself ]    <-- git commit/push/checkout are hard-denied for every agent
```

`orchestrator-architect` never runs `git commit`/`push`/`checkout`/`merge`/`rebase` or `gh pr create`/`pr merge`/`release create` — no agent does, in any invocation form, including a direct `@mention`. These are blocked by a `deny` rule in `.claude/settings.json` that applies regardless of who's asking. What the orchestrator does instead: prepare the diff, a drafted commit message (and branch name, and PR title/description when relevant), and hand you a copy-pasteable block of the exact commands to run in your own terminal.

Only `orchestrator-architect` can invoke other sub-agents (it's the only one with the `Agent` tool, scoped to this exact list). Every other agent works within its own lane and reports back to it.

## 👥 Agent Roster (`.claude/agents/`)

| Agent | Color | Focus |
|---|---|---|
| `orchestrator-architect` | 🔴 red | Triages requests, breaks them into a `PLAN.md`, and delegates to the right specialists in sequence. |
| `product-analyst` | 🩷 pink | Turns a PRD or ambiguous request into `BACKLOG.md` — epics, user stories, acceptance criteria. |
| `solutions-architect` | 🟣 purple | Assesses structural/architectural impact before implementation; audits the codebase for architecture/performance/**application-level** security. Runs on `claude-opus-5` — the judgment-heavy half of what used to be one agent (see [Model per agent](#model-per-agent-cost-vs-quality)). |
| `codebase-cartographer` | 🟣 purple | Descriptive, mechanical codebase mapping: drafts `CONTEXT.md` when onboarding an existing codebase, and produces system diagrams. No judgment calls — that's `solutions-architect`, its architecture-adjacent sibling (same color, on purpose). Runs on `claude-sonnet-5`. |
| `backend-architect` | 🟢 green | RESTful/GraphQL APIs, Clean Architecture, ACID transactions, OWASP security. |
| `frontend-engineer` | 🔵 blue | React/Angular in strict TypeScript, Core Web Vitals, resilient UI states. |
| `ui-ux-design-system` | 🩵 cyan | Design tokens, WCAG AA accessibility, stable `data-testid` selectors; translates a visual reference or a qualitative style brief into an implementable spec. |
| `data-telemetry-architect` | 🟠 orange | SQL/NoSQL schema design, JSON structured logging, alerting thresholds, LGPD/GDPR compliance — infrastructure-adjacent, same color as `devops-secops-engineer`. |
| `devops-secops-engineer` | 🟠 orange | Multi-stage Docker, compatibility with the project's existing CI/CD (doesn't create one), local quality-gate hook, release/rollback/feature-flag strategy, **dependency/infra** security, and hands-on help resolving git merge/rebase conflicts. |
| `product-qa-reviewer` | 🟡 yellow | Test suite execution, test-quality audits (incl. mutation testing), anti-over-engineering, Definition of Done. |

There are 10 agents and only 8 supported colors, so two pairs share a color deliberately, grouped by functional proximity rather than arbitrarily: `solutions-architect`/`codebase-cartographer` (both architecture-adjacent — literally split from one original agent) share purple, and `devops-secops-engineer`/`data-telemetry-architect` (both infrastructure/operations, both hold a "CLAUDE.md §7 ask-once" standing decision) share orange. Every other agent keeps a unique color.

Each file's `description` field is written so Claude Code can also route work to the right specialist automatically, even without going through the orchestrator — see each agent's `.md` file for its full responsibilities and rules.

## ✅ What the Agents Can Handle

| Type of request | Path | Example |
|---|---|---|
| Simple, scoped change | Direct | "Implement a validation on the 'name' field." |
| Multi-step feature, still clearly scoped | Direct | "Implement a password reset flow." |
| PRD / multi-feature spec | Analysis | "Here's the PRD for the referral program." |
| Screen from an image, Figma, or Lovable | Direct (design-first) | "Implement this screen (image attached)." |
| Qualitative style change, no reference | Direct (design-first) | "Make screen 'A' feel more executive." |
| Architecture/performance/security audit | Diagnostic (read-only) | "What architectural improvements would you recommend?" |
| System diagram | Diagnostic (read-only) | "Draw the current system architecture." |
| Onboarding into an existing codebase | Onboarding check (before triage) | "Let's start using this on the existing app." |
| Opening a PR after a push | Direct/Analysis, versioning step | (asked separately, after you approve the push) |
| Legacy codebase review (understand + modernize/optimize/test/security) | Onboarding, then Diagnostic (multi-specialist) | "I inherited this repo — what should we improve?" |
| Test-quality audit (is test coverage actually meaningful?) | Diagnostic (read-only) | "How good are our tests on the payment module, really?" |
| Explicit "read-only, don't implement" instruction | Diagnostic (read-only), override is absolute | "Verify the last fix, read-only — don't implement, don't delegate to sub-agents." |

This table is a summary of [`SCENARIOS.md`](SCENARIOS.md), the canonical checklist of behaviors the agent suite must keep covering. It's a **manual regression checklist**, not automated tests — this repo has no application code of its own, so a scenario here only verifies *routing* (which agents get called, in what order), not implementation quality.

**Whenever you edit an agent's `description`/rules or the orchestrator's triage logic**, dry-run `SCENARIOS.md` before committing:

```
@orchestrator-architect Without actually doing the work, walk through
SCENARIOS.md and tell me, for each scenario, which agents you'd invoke
and in what order. Flag any that don't match the "Expected path" column.
```

If a change adds a new capability worth remembering, add it as a new scenario there first, then reflect it in the table above.

## 🛡 Guardrails

Versioning commands are **hard-denied for every agent**, in every invocation form, with no exception:

- **`.claude/settings.json`** sets `permissions.deny` on `git commit`, `git push`, `git checkout`, `git merge`, `git rebase`, `gh pr create`, `gh pr merge`, and `gh release create`. A deny rule blocks the command outright, in every permission mode — there's no prompt to click through, because there's nothing to ask: the tool call simply cannot execute.
- **[`CLAUDE.md`](CLAUDE.md)** reinforces this behaviorally: agents run `git diff` (read-only, always fine), present a summary and a drafted commit message, and hand you the exact commands to run yourself. They don't attempt the denied commands even once.

**Why `deny` instead of `ask`:** earlier versions of this template used `permissions.ask` — the orchestrator would ask for approval in chat, then delegate execution to `devops-secops-engineer`. In real use, this failed more than once: a delegated sub-agent (even one invoked by an explicit `@mention` mid-conversation) runs to completion and returns a single result — it has no way to actually pause and wait for your next chat message, so "ask, then wait, then execute" isn't something a sub-agent can reliably honor no matter how the instruction is worded. Only a hard `deny` closes that gap, because it doesn't depend on any agent choosing correctly — the command is mechanically unreachable. The tradeoff: you now always run `git commit`/`push`/`checkout`/`merge`/`rebase` and `gh pr create`/`pr merge`/`release create` yourself, in your own terminal. If your team is comfortable with the weaker guarantee, `ask` is still a valid choice — just know its limits going in.

### Branching, pull requests, and merge conflicts

Branch strategy is a standing decision, not a per-request one: the first time any request reaches implementation, `orchestrator-architect` asks once — feature/fix branch + PR by default, direct on the current branch, or something conditional — and records the answer in `CONTEXT.md` §6. Every request after that follows it silently, no re-asking. When the recorded strategy calls for a branch, it proposes a `feature/<slug>` or `fix/<slug>` name and, once code is ready, hands you a copy-pasteable block: the branch command, the commit (with a drafted Conventional Commits message), the push, and — only if you separately ask for a PR — a `gh pr create` with a drafted title/description. You run all of it yourself. If you get stuck on a merge/rebase conflict, `devops-secops-engineer` can help: it reads both sides and edits the conflicting files to resolve the markers, but it doesn't run `git add`/`commit`/`merge`/`rebase` itself either — you finish with the commands it gives you.

### Model per agent (cost vs. quality)

All agents default to `claude-sonnet-5` except `solutions-architect`, which uses `claude-opus-5`. The reasoning: `solutions-architect` makes the highest-stakes calls in the suite (a missed architectural risk can slip through silently, since it only escalates to you when *it* judges the impact significant) and is invoked far less often than the tactical agents — so the extra cost applies to a small slice of total usage. `orchestrator-architect` runs on every single request, so bumping its model would multiply cost across all usage for a triage decision Sonnet already handles well; it stays on Sonnet by design, not by oversight.

`solutions-architect` used to also handle onboarding (`CONTEXT.md` drafting) and diagramming — both mechanical, descriptive tasks with no real judgment call, which don't justify Opus pricing. Those moved to a separate agent, `codebase-cartographer`, on `claude-sonnet-5`, precisely so the more expensive model is only paid for the work that actually needs it. A Claude Code subagent has exactly one `model:` per file, so splitting by cost/stakes was the only way to stop paying Opus rates for work that didn't need it — this is also why the two agents' security scopes are split (`solutions-architect` for application/architecture-level security, `devops-secops-engineer` for dependency/infra) rather than one agent owning "security" broadly.

### Runaway loops and unverified claims

Two failure modes worth guarding against explicitly: an agent grinding on a task without converging (burning tokens), and an agent asserting something is done/working without having actually checked.

- **`maxTurns` per agent** (in each `.claude/agents/*.md`): caps how many turns a single sub-agent invocation can take. When it's hit, Claude Code returns the output marked as partial instead of erroring, and `orchestrator-architect` is instructed to resume it once with a focused ask — if it's still not done after that, it stops and tells you what's unfinished instead of presenting partial work as complete. Values are a starting point (30 for the implementation-heavy agents, 20-25 for analysis/review agents, 50 for the orchestrator itself, which coordinates everyone else) — tune them once you see real usage. Requires Claude Code v2.1.246+ for the partial-output marking.
- **Capped rejection loop:** if `product-qa-reviewer` rejects a delivery twice on the same story without resolving it, `orchestrator-architect` stops retrying and escalates to you with a summary of what was tried — instead of cycling indefinitely.
- **Evidence over assertion** (`CLAUDE.md` §6): no agent may report a test as passing, a build as working, or a migration as applied without having actually run the command and relaying its real output. `product-qa-reviewer` specifically re-runs the test suite itself rather than trusting another agent's summary.

None of this is a hallucination *detector* — Claude Code doesn't have one. It's a combination of hard caps (`maxTurns`) and behavioral rules that make ungrounded claims and endless loops easier to catch before they reach your `git diff`.

### Mechanical quality gate — local only (opt-in, asked once)

Everything above is either a hard cap on turns or a behavioral rule — an agent is *instructed* to show evidence, but nothing stops it from being wrong in good faith. [Claude Code hooks](https://code.claude.com/docs/en/hooks) close that gap: a hook runs in Claude Code's own runtime, not the model's judgment, and can genuinely block a tool call.

**This template deliberately does not create a CI/CD pipeline.** That's assumed to already exist (or be someone else's job to set up) — scaffolding one wasn't something we wanted this template responsible for. What it does ship is a local convenience: **`.claude/hooks/test-gate.sh`** — a `PreToolUse` hook that, if wired up, runs before `git commit`/`git push`, executes `.claude/hooks/run-tests.sh` (auto-detects `npm test`/`pytest`/`go test`, or hardcode your own command in it), and blocks the command (exit code 2) if tests fail.

With `permissions.deny` on those same commands by default (see the Guardrails section above), **this hook never actually fires for any agent** — the command is already unreachable before a hook would even be consulted. It only matters if you deliberately relax `git commit`/`git push` from `deny` back to `ask` for your project; `devops-secops-engineer` still offers to wire it up once, the first time it's relevant, and records the answer in `CONTEXT.md` §6 — it's a real choice a project might make, so it's still worth asking about.

### Release, rollback, and alerting

`devops-secops-engineer` also owns release/rollback/feature-flag strategy (`CONTEXT.md` §7), and `data-telemetry-architect` defines alert thresholds on top of the structured logs it already emits, not just the logs themselves (`CONTEXT.md` §8) — a log nobody is paged on doesn't catch an incident. Both follow the same "ask once, record the answer, never re-litigate" principle — stated once in [`CLAUDE.md`](CLAUDE.md) §7 so it isn't re-explained in every agent that uses it. The same split applies to `CONTEXT.md` §4: `backend-architect` owns Database Rules (ID strategy, soft-delete), `devops-secops-engineer` owns Storage Rules — except when `codebase-cartographer` is onboarding an existing codebase, where it fills §4 in by describing what the code already does, since that's an observable fact rather than a decision to ask about.

### Onboarding an existing codebase

If you point this template at a project that already has code and no `CONTEXT.md`, `orchestrator-architect` notices before triaging anything and has `codebase-cartographer` scan the codebase to draft `CONTEXT.md` itself (stack, folder structure, scripts) — you fill in the product/business sections (§1), which can't be inferred from code. This is a descriptive task, not a judgment call, so it's handled by the cheaper of the two architecture-adjacent agents rather than `solutions-architect`.

## 📁 Repository Structure

```text
claude-agents-template/
├── .claude/
│   ├── agents/
│   │   ├── orchestrator-architect.md    # Triages requests and delegates via the Agent tool
│   │   ├── product-analyst.md           # PRD/requirements → BACKLOG.md
│   │   ├── solutions-architect.md       # Architecture impact assessment → ARCHITECTURE_IMPACT.md
│   │   ├── codebase-cartographer.md     # Descriptive mapping: CONTEXT.md onboarding, diagrams
│   │   ├── backend-architect.md
│   │   ├── frontend-engineer.md
│   │   ├── ui-ux-design-system.md
│   │   ├── data-telemetry-architect.md
│   │   ├── devops-secops-engineer.md    # Also helps resolve git merge/rebase conflicts
│   │   └── product-qa-reviewer.md
│   ├── hooks/
│   │   ├── test-gate.sh                  # PreToolUse hook: blocks git commit/push if tests fail (opt-in, local only)
│   │   └── run-tests.sh                  # Test-runner the hook calls; auto-detects npm/pytest/go
│   └── settings.json                    # Permission rules (git/gh commands require confirmation)
├── scripts/
│   └── install.sh                       # One-time copy of this template into another project
├── CLAUDE.md                            # Global engineering rules and guardrails
├── CONTEXT.md.template                  # Per-project context template (stack, architecture, scripts)
├── SCENARIOS.md                         # Manual regression checklist for agent routing
└── README.md
```

## 🛠 Using This Template in a New Project

### Option A — Git Submodule (keeps updates in sync)

Best when you want a project to automatically be able to pull future changes to the shared agents/guardrails.

```bash
cd my-new-project
git submodule add https://github.com/your-org/claude-agents-template.git .claude
git submodule update --init --recursive
cp .claude/CLAUDE.md CLAUDE.md
cp .claude/CONTEXT.md.template CONTEXT.md
```

`.claude/agents/` and `.claude/settings.json` are already in the right place, since the submodule *is* `.claude/`. Only `CLAUDE.md` and `CONTEXT.md` need copying, because Claude Code reads those from the project root, not from `.claude/`.

To pull future updates into an existing project:

```bash
cd my-new-project
git submodule update --remote .claude
cp .claude/CLAUDE.md CLAUDE.md
```

### Option B — One-time copy via `install.sh` (simplest)

Best for solo projects where you don't need automatic updates — just run the script again whenever you want to re-sync.

```bash
git clone https://github.com/your-org/claude-agents-template.git
./claude-agents-template/scripts/install.sh /path/to/my-new-project
```

This copies `.claude/agents/`, `.claude/hooks/`, `.claude/settings.json`, and `CLAUDE.md` into the target project, and creates `CONTEXT.md` from the template only if one doesn't already exist there. The local hook is inert until `devops-secops-engineer` wires it up — see [Mechanical quality gate](#mechanical-quality-gate--local-only-opt-in-asked-once). This template doesn't scaffold a CI/CD pipeline — that's assumed to already exist in the project.

Either way, the last step is always the same: **fill in `CONTEXT.md`** with the new project's actual stack, folder layout, and scripts — this is what `orchestrator-architect` reads before planning any work.

## 🔄 Daily Workflow

1. Start Claude Code in your project root:
   ```bash
   claude
   ```
2. Describe the feature to the orchestrator:
   ```
   @orchestrator-architect Implement a password reset flow: generate a
   time-limited token, email it to the user, add a reset-password screen,
   and log the attempt with trace_id for observability.
   ```
3. `orchestrator-architect` reads `CONTEXT.md`, writes `PLAN.md`, and delegates to `data-telemetry-architect`, `ui-ux-design-system`, `backend-architect`/`frontend-engineer`, `devops-secops-engineer`, and finally `product-qa-reviewer` — in whatever order the request actually needs.
4. It presents the `git diff` and asks whether to commit (and push). Review it, and reply with something like:
   ```
   Looks good, commit and push it.
   ```
   Claude Code will still show its own confirmation prompt for the `git commit`/`git push` command before running it — that's `.claude/settings.json` doing its job as the final check.

## 📋 Handling a PRD or a Large/Ambiguous Request

Not every request should go straight to implementation. When you hand the orchestrator a PRD, a spec document, or a request that plausibly spans multiple features, it routes through analysis first instead of guessing:

```
@orchestrator-architect Here's the PRD for the referral program
(prd-referral-program.pdf attached). Let's start on this.
```

1. `orchestrator-architect` triages the request. A PRD like this — multiple features, cross-cutting — triggers the analysis path instead of direct implementation.
2. `product-analyst` reads the PRD and writes `BACKLOG.md`: epics broken into user stories, each with acceptance criteria, a rough size (S/M/L), a suggested priority, and any open questions the PRD left unanswered. It asks you to resolve those questions rather than guessing.
3. For the story you pick to work on next, `solutions-architect` checks whether it forces a structural change (new service, breaking API, schema migration, cross-module ripple) and writes its finding to `ARCHITECTURE_IMPACT.md`. If the impact is significant, it stops and asks for your explicit approval before any code gets written; if it's negligible, it says so and the orchestrator proceeds directly.
4. From there, it's the same flow as any other request: `PLAN.md`, delegation to the relevant specialists, `product-qa-reviewer`, and the diff for your approval.

`BACKLOG.md` persists across sessions — each time you come back to work on the next story, `product-analyst` updates it rather than starting over. A short, clearly-scoped request (like the password reset example above) skips straight past `product-analyst`/`solutions-architect` — they only add value when there's real ambiguity or structural risk to catch.

## 🖼 Implementing a Screen from an Image, Figma, or Lovable

Claude reads images natively, so a screenshot or an exported Figma frame works out of the box — no extra tooling required. Attach the image and mention the orchestrator:

```
@orchestrator-architect Here's the checkout screen layout (image attached).
Implement it.
```

`orchestrator-architect` calls `ui-ux-design-system` **first**: it reads the image and writes a spec (component breakdown, spacing/color mapped to design tokens, and the Loading/Error/Empty/Success states expected for each component) before `frontend-engineer` implements it. This keeps a design handoff from skipping straight to code without going through token discipline and accessibility review.

What to attach depends on the source:
- **Screenshot / exported PNG or SVG:** attach directly, works as-is.
- **Figma:** export the frame as PNG/SVG and attach it. For higher-fidelity handoff (exact spacing and token values instead of a flat image), consider connecting [Figma's Dev Mode MCP server](https://www.figma.com/developers) so `ui-ux-design-system` can query structured design data instead of just reading a picture of it — not set up in this template, but a natural next step if you use Figma regularly.
- **Lovable:** if you're sharing a preview/screenshot, treat it like any other image. If you're sharing exported code (Lovable generates React + Tailwind), there's nothing special to do — `frontend-engineer` and `ui-ux-design-system` read code directly with the `Read` tool.

### No reference, just a style direction

You don't need an attached image to ask for a visual change — a qualitative brief works too:

```
@orchestrator-architect Make screen "A" feel more executive.
```

`ui-ux-design-system` still goes first: it interprets the brief into concrete token changes (palette, type scale, spacing density) and writes a short rationale for why those changes read as "more executive," before `frontend-engineer` implements them.

## 🔍 Diagnostics: Audits, Recommendations, Diagrams, and Legacy Reviews

Some requests aren't asking for a code change at all — they're asking for an assessment. The orchestrator's triage recognizes this and routes to whichever specialist(s) fit, skipping `PLAN.md`, delegation, and the git diff entirely. Nothing gets written or changed in any of the examples below — if you then say "go ahead and implement recommendation #2," *that* becomes a new request, which goes back through triage like any other.

### Architecture, performance, and security recommendations

```
@orchestrator-architect Based on the current codebase, what architectural
improvements would you recommend for performance and security?
```

`solutions-architect` reads the codebase against `CONTEXT.md` and returns a prioritized list of recommendations, each with rationale and a rough effort/risk estimate. If the ask is a general, unqualified "security" review rather than something clearly architectural, `devops-secops-engineer` contributes its own (dependency/infra) findings too, merged into the same report — the two agents' security scopes are complementary, not overlapping, so an unqualified ask goes to both rather than picking one.

### System diagram

```
@orchestrator-architect Draw a diagram of the current system architecture
and its integrations.
```

`codebase-cartographer` returns a Mermaid diagram of modules/services, data stores, and external integrations — renders natively wherever the docs are viewed. This is a descriptive task with no judgment call involved, so it's handled by the cheaper of the two architecture-adjacent agents rather than `solutions-architect`.

### Test-quality audit (mutation testing)

```
@orchestrator-architect How good are our tests on the payment module,
really — not just coverage, would they actually catch a bug?
```

`product-qa-reviewer` handles this one: high line coverage with weak assertions isn't the same as a test suite that catches broken behavior. It recommends or runs mutation testing (Stryker/mutmut/PIT, depending on the stack) and reports back which parts of the suite are actually effective.

### Legacy codebase review

```
@orchestrator-architect I inherited this repo. Help me understand what it
does, and suggest improvements for modernization, optimization, tests,
and security.
```

This is the broadest diagnostic case, and it's the one most worth knowing about if you're adopting this template on an existing project: the [onboarding check](#onboarding-an-existing-codebase) has `codebase-cartographer` scan the codebase **once** and draft `CONTEXT.md` first (the "what does it do" part), then the diagnostic fans out to **three** specialists — `solutions-architect` (architecture/modernization/performance/app-security, reading that fresh `CONTEXT.md` as its starting map instead of re-exploring blind), `devops-secops-engineer` (dependency/infra security), and `product-qa-reviewer` (test coverage and quality) — and `orchestrator-architect` merges their findings into one organized report instead of handing you three disconnected ones. The codebase only gets scanned once, not once per agent that needs to understand it.

## 🗂 Traceability

Three files carry the project's working memory, and they're deliberately not treated the same way:

- **`BACKLOG.md`** (from `product-analyst`) is persistent — `orchestrator-architect` marks a story `Done` directly once it's delivered, never deleted, so it always reflects the full history of what was planned and delivered.
- **`ARCHITECTURE_IMPACT.md`** (from `solutions-architect`) is **append-only** — every assessment or audit adds a new dated section (`## YYYY-MM-DD — <title>`) instead of overwriting the last one. This is your architecture decision log: read it to see why a structural call was made, not just what the current state is.
- **`PLAN.md`** (from `orchestrator-architect`) is ephemeral by design — it's a checklist for the task at hand, and gets overwritten by the next request. Its reasoning isn't lost, though: commit it alongside the code diff it produced, and `git log`/`git blame` on `PLAN.md` gives you that history too, tied to the actual commit that resulted from it.
