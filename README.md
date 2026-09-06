# Claude Agents Template Base 🚀

> **A reusable multi-agent setup for Claude Code: specialist sub-agents, engineering guardrails, and a human-in-the-loop workflow.**

`claude-agents-template` bootstraps a new project with a coordinated set of Claude Code sub-agents, a shared engineering rulebook (`CLAUDE.md`), and a project-context template (`CONTEXT.md`) — so every new repo starts with the same guardrails and specialist coverage instead of a blank `.claude/` folder.

---

## 🏛 Architecture

The suite follows a **Coordinator/Orchestrator pattern**. A feature request is handed to `orchestrator-architect`, which writes a `PLAN.md` and delegates to the specialist sub-agents in the order the work actually requires:

```text
                [ Developer ]
                      │
                      ▼
           [ orchestrator-architect ]  <-- writes PLAN.md, delegates via the Agent tool
                      │
   ┌──────────────────┼──────────────────┬──────────────────┐
   ▼                  ▼                  ▼                  ▼
[backend-architect] [frontend-engineer] [ui-ux-design-system] [data-telemetry-architect]
   │                  │                  │                  │
   └──────────────────┴──────────────────┴──────────────────┘
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
| `orchestrator-architect` | 🔴 red | Breaks a request into a `PLAN.md` and delegates to the right specialists in sequence. |
| `backend-architect` | 🟢 green | RESTful/GraphQL APIs, Clean Architecture, ACID transactions, OWASP security. |
| `frontend-engineer` | 🔵 blue | React/Angular in strict TypeScript, Core Web Vitals, resilient UI states. |
| `ui-ux-design-system` | 🩵 cyan | Design tokens, WCAG AA accessibility, stable `data-testid` selectors. |
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
│   │   ├── orchestrator-architect.md    # Delegates to the other 6 via the Agent tool
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
