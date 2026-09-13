# Global Engineering, Observability, and AI Guardrail Rules

## 1. Versioning Guardrails (Human-in-the-Loop)
- `git commit`, `git push`, `git checkout`, `git merge`, `git rebase`, and `gh pr create`/`pr merge`/`release create` are blocked by `deny` in `.claude/settings.json` — for **every agent**, no exceptions, in any permission mode. This isn't "ask first": it's "there's no way to run it, period." Don't attempt these commands, and don't ask another agent to run them either.
- **Why `deny` and not `ask`:** we already tried "ask, then execute" (one agent asks, waits for approval, another agent executes) and it failed in practice — a delegated sub-agent can't actually pause and wait for a live reply from the user; it runs to completion and returns a single result. This holds even when the user explicitly mentions the agent (`@orchestrator-architect`) mid-session — it's still a sub-agent invocation, not a main session capable of pausing. Only `deny` guarantees this mechanically, regardless of how the agent was invoked.
- After finishing the code, run `git diff` (read-only, no risk) and present a concise summary of the changes, along with a suggested commit message (Conventional Commits) and the exact commands — ready to copy and paste — that the user should run themselves, in their own terminal.
- Branch strategy (feature/fix + PR vs. straight to main) is a permanent project decision, not a per-request choice — it follows the §7 pattern: ask once, record the answer in `CONTEXT.md` §6, and follow that answer silently from then on.
- If the user asks for help with a merge/rebase conflict, edit the conflicting files — never finalize (`git add`/`commit`/`--continue`) it yourself.
- Any other infrastructure change remains prohibited autonomously — always ask the user to run it manually.

## 2. Rational Token Use & Efficiency (Context Routing)
- Concise, to-the-point responses. Skip greetings or verbose explanations of what was asked.
- **Language:** chat with the user in whatever language they use (e.g. Portuguese) — but every artifact written to disk (code, comments, identifiers, documentation, `CONTEXT.md`, `PLAN.md`, `BACKLOG.md`, `ARCHITECTURE_IMPACT.md`, commit messages, PR descriptions) is always in English, no exceptions. Chat and repository deliberately follow different languages.
- Don't read entire directories unnecessarily. Use focused search tools (`grep`, `find`) to load only relevant files.
- NEVER rewrite entire files to change a few lines. Use surgical, patch-style edits or block substitutions.
- **Lean command output between agents:** when relaying the result of a command (`test`, `build`, `lint`) to another agent — for example `product-qa-reviewer` handing a failure back for `orchestrator-architect` to relay to the responsible specialist — extract only the relevant lines (failure messages, the specific error's stack trace), never the full verbose log. This holds even within the retry cap of "Rejection loop, capped": that cap controls the *number* of retries, this one controls the *size* of each one — without both, an agent stuck in 1-2 retries can still reprocess thousands of log lines repeatedly.

## 3. Fullstack Development Guidelines (Software)
- **Principles:** Apply SOLID, DRY, and Clean/Hexagonal Architecture. Strictly separate Domain, Application, and Infrastructure.
- **Frontend (React/Angular):** Strict TypeScript typing (`any` is forbidden). Mobile-first, accessible (WCAG AA) interfaces focused on Core Web Vitals.
- **Backend (Node/Python):** Business rules isolated from controllers/frameworks. Optimized database queries, avoiding the N+1 problem.
- **Databases (SQL/NoSQL):** Atomic transactions for critical data. Paginated queries by default to preserve memory and response time.

## 4. Observability & Telemetry Standard (Data)
- Every public API route, worker, or event handler MUST emit structured JSON logs.
- Every log must mandatorily include: `timestamp`, `level`, `trace_id` (for correlation), `event_name`, and `duration_ms`.
- NEVER log sensitive data (PII, passwords, tokens, banking data) in application logs.

## 5. Product Vision & Pragmatism
- **80/20 Rule (KISS):** Prefer simple solutions that solve the business pain before suggesting over-engineering or premature microservices.
- No feature is considered done (Definition of Done) without valid automated tests (unit, integration, and, when the journey is critical, E2E) and a guarantee of zero regression.
- For critical business logic (payments, permissions, financial calculations), the test suite must be good enough to survive mutation testing, not just have line coverage — high coverage with weak tests goes unnoticed without it.
- This template does not create or manage a CI/CD pipeline — it assumes one already exists (or should exist) in the project. The agents' role is to ensure new code passes tests locally and is compatible with what the pipeline already validates, not to replace it.

## 6. Evidence Over Assertion (Anti-Hallucination)
- NEVER state that a test passed, a build worked, or a migration was applied without having actually run the real command and reporting its real output. "Should work" is not a verification.
- When citing an existing file, function, or behavior, base it on what was actually read/executed in this session — not on an assumption of how the code "probably" is.
- Every agent has a `maxTurns` cap (`.claude/agents/*.md`). If you hit that cap mid-task, your output comes back marked as partial — that's expected and safe; don't try to force more work past the cap to "finish at any cost."
- A prompt rule is behavioral reinforcement, not a technical guarantee. Where a hook is configured (`.claude/hooks/`, see `CONTEXT.md` §6), it runs in Claude Code's own runtime and can genuinely block the action (e.g., `git commit`/`git push` with failing tests) — treat that as the real check, not as something redundant or bypassable.

## 7. Permanent Project Decisions (Ask Once)
- Every project decision that doesn't change from request to request (where the CI pipeline lives, whether the local hook is enabled, release/rollback/feature-flag strategy, branch strategy, where alerts are viewed, and who gets notified) follows the same pattern: if the corresponding `CONTEXT.md` section doesn't have an answer yet, ask the user **once**, record the answer there, and never ask again.
- Honor the answer even if you, the agent, think another choice would be better practice — it's not your call to insist.
- Every agent that owns one of these questions (`orchestrator-architect` for branch strategy, `devops-secops-engineer` for CI/hook/release/storage, `backend-architect` for database conventions, `data-telemetry-architect` for observability) references this principle instead of re-explaining it.
