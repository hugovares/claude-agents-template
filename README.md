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

  C) Diagnostic — audit, architectural/security/performance
     recommendations, or a system diagram (no code change asked for)
     --> [ solutions-architect ] (+ devops-secops-engineer for infra/security)
     --> report or diagram returned to the user. Flow ends here:
         no PLAN.md, no delegation, no git diff.
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
                        [ git diff on screen ]   <-- human approves before anything is committed
```

Only `orchestrator-architect` can invoke other sub-agents (it's the only one with the `Agent` tool, scoped to this exact list). Every other agent works within its own lane and reports back to it.

## 👥 Agent Roster (`.claude/agents/`)

| Agent | Color | Focus |
|---|---|---|
| `orchestrator-architect` | 🔴 red | Triages requests, breaks them into a `PLAN.md`, and delegates to the right specialists in sequence. |
| `product-analyst` | 🩷 pink | Turns a PRD or ambiguous request into `BACKLOG.md` — epics, user stories, acceptance criteria. |
| `solutions-architect` | 🟣 purple | Assesses structural/architectural impact before implementation; also audits the codebase and produces system diagrams on request. |
| `backend-architect` | 🟢 green | RESTful/GraphQL APIs, Clean Architecture, ACID transactions, OWASP security. |
| `frontend-engineer` | 🔵 blue | React/Angular in strict TypeScript, Core Web Vitals, resilient UI states. |
| `ui-ux-design-system` | 🩵 cyan | Design tokens, WCAG AA accessibility, stable `data-testid` selectors; translates a visual reference or a qualitative style brief into an implementable spec. |
| `data-telemetry-architect` | 🟣 purple | SQL/NoSQL schema design, JSON structured logging, LGPD/GDPR compliance. |
| `devops-secops-engineer` | 🟠 orange | Multi-stage Docker, CI/CD pipelines, secrets management, dependency scanning. |
| `product-qa-reviewer` | 🟡 yellow | Test suite execution, anti-over-engineering, Definition of Done. |

Each file's `description` field is written so Claude Code can also route work to the right specialist automatically, even without going through the orchestrator — see each agent's `.md` file for its full responsibilities and rules.

## 🛡 Guardrails

Versioning follows a human-in-the-loop flow, enforced on two layers:

1. **Behavioral:** [`CLAUDE.md`](CLAUDE.md) instructs every agent to run `git diff`, present a summary, and explicitly ask you in the conversation before running `git commit`, `git push`, or `git checkout`. Any other infrastructure change stays off-limits autonomously either way — the agent asks you to run those yourself.
2. **Hard (tool-level):** [`.claude/settings.json`](.claude/settings.json) sets `permissions.ask` on `git commit`, `git push`, and `git checkout` — even after you approve in chat, Claude Code shows its own native confirmation prompt before actually running the command. That prompt is the real safety net: it fires regardless of what an agent decides to do, so approval in conversation is never enough on its own.

In short: the agent shows you the diff, asks if it should commit/push/checkout, and only runs the command — with Claude Code's own prompt as the final check — once you say yes. If you'd rather it never even attempt these commands and you always run them yourself, change `ask` to `deny` for those three entries in `settings.json` and revert the "Versioning" rule in `CLAUDE.md`/`orchestrator-architect.md` back to fully manual.

## 📁 Repository Structure

```text
claude-agents-template/
├── .claude/
│   ├── agents/
│   │   ├── orchestrator-architect.md    # Triages requests and delegates via the Agent tool
│   │   ├── product-analyst.md           # PRD/requirements → BACKLOG.md
│   │   ├── solutions-architect.md       # Architecture impact assessment → ARCHITECTURE_IMPACT.md
│   │   ├── backend-architect.md
│   │   ├── frontend-engineer.md
│   │   ├── ui-ux-design-system.md
│   │   ├── data-telemetry-architect.md
│   │   ├── devops-secops-engineer.md
│   │   └── product-qa-reviewer.md
│   └── settings.json                    # Permission rules (git commit/push/checkout require confirmation)
├── scripts/
│   └── install.sh                       # One-time copy of this template into another project
├── CLAUDE.md                            # Global engineering rules and guardrails
├── CONTEXT.md.template                  # Per-project context template (stack, architecture, scripts)
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

This copies `.claude/agents/`, `.claude/settings.json`, and `CLAUDE.md` into the target project, and creates `CONTEXT.md` from the template only if one doesn't already exist there.

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

## 🔍 Diagnostics: Audits, Recommendations, and Diagrams

Some requests aren't asking for a code change at all — they're asking for an assessment. The orchestrator's triage recognizes this and routes straight to `solutions-architect`, skipping `PLAN.md`, delegation, and the git diff entirely:

```
@orchestrator-architect Based on the current codebase, what architectural
improvements would you recommend for performance and security?
```

```
@orchestrator-architect Draw a diagram of the current system architecture
and its integrations.
```

`solutions-architect` reads the codebase against `CONTEXT.md` and returns a prioritized list of recommendations (with rationale and rough effort/risk) or a Mermaid diagram — whichever was asked for — directly to you. Nothing gets written or changed. If you then say "go ahead and implement recommendation #2," *that* becomes a new request, which goes back through triage like any other.

## 🗂 Traceability

Three files carry the project's working memory, and they're deliberately not treated the same way:

- **`BACKLOG.md`** (from `product-analyst`) is persistent — stories are marked done, never deleted, so it always reflects the full history of what was planned and delivered.
- **`ARCHITECTURE_IMPACT.md`** (from `solutions-architect`) is **append-only** — every assessment or audit adds a new dated section (`## YYYY-MM-DD — <title>`) instead of overwriting the last one. This is your architecture decision log: read it to see why a structural call was made, not just what the current state is.
- **`PLAN.md`** (from `orchestrator-architect`) is ephemeral by design — it's a checklist for the task at hand, and gets overwritten by the next request. Its reasoning isn't lost, though: commit it alongside the code diff it produced, and `git log`/`git blame` on `PLAN.md` gives you that history too, tied to the actual commit that resulted from it.
