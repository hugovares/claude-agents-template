---
name: discovery
description: "Product discovery conversation: turns a vague product idea into a PRODUCT_BRIEF.md through a real back-and-forth — problem, users, options, MVP scope, success metrics — before any PRD, backlog, or code exists. Use when the user has an idea but hasn't pinned down who it's for, what problem it solves, or what the first version includes; when they ask to brainstorm a product or feature area; or when orchestrator-architect recommends running /discovery."
---

# Discovery

You run a product discovery conversation with the user and capture its outcome in `PRODUCT_BRIEF.md` at the project root. This is a skill rather than a sub-agent on purpose: discovery is a dialogue, and only the main session can actually wait for the user's reply and build on it. A sub-agent runs to completion and returns once — see `CLAUDE.md` §1 for the same limitation applied to git.

## Scope
- **Your only output is `PRODUCT_BRIEF.md`** (and the conversation itself). No PRD, no backlog, no architecture, no code. Those belong downstream: `product-analyst` turns the brief into `PRD.md` and then `BACKLOG.md`; `solutions-architect` designs the architecture.
- **What, who, and why — never how.** If the user states a technical constraint ("it must run on our existing Postgres"), record it under Constraints. Don't propose a stack or a structure yourself.
- **No facts from recall.** If a question needs current outside information (competitors, market size, a regulation's details, what a service costs), don't answer it as fact. Record it as an open question and mention the user can ask `orchestrator-architect` for `deep-research-technologist`.

## Before starting
1. Check whether `PRODUCT_BRIEF.md` already exists. If it does, read it and continue from it — ask what changed rather than starting over, and edit only the sections that change. Never overwrite a brief wholesale.
2. If `PRD.md` already exists, point that out and ask whether discovery is really needed or whether the user wants to revise the PRD with `product-analyst` instead.
3. Read `CONTEXT.md` §1 if it's filled in — product facts already recorded there are a starting point, not something to ask again.
4. Suggest (once, briefly) running discovery in a fresh session if this one already carries a lot of unrelated context. Don't insist.

## Conversation
Chat in the user's language. Ask **one to three questions per turn** — this is a conversation, not a form. Follow up on the answers: the most useful question is usually the one prompted by what they just said. Move through these stages in order, but skip or shorten anything the user has already answered.

1. **Problem and people** — What problem is being solved, for whom specifically, how do they cope today, and why solve it now? Push past generic answers ("small businesses") toward a concrete person and situation.
2. **Diverge** — Before settling on the user's first solution, open it up. Use whichever of these fits:
   - "How might we…" reframings of the problem.
   - Two or three genuinely different ways to solve it, including a much smaller one.
   - The riskiest assumption: what has to be true for this to work, and how cheaply could it be checked?
   - What happens if nothing is built?
   Offer your own ideas, clearly labeled as suggestions — the user decides what's in.
3. **Converge** — Pick the direction. Pin down the MVP: what's in the first version, and — just as important — what's explicitly out. Define success as something measurable ("30% of clinics book online within 3 months", not "users like it"). Capture constraints: deadline, budget, team, compliance (LGPD/GDPR), existing systems.
4. **Play it back** — Summarize the brief in a few lines in chat and ask the user to confirm or correct it before writing the file.

Keep it proportional: a small feature area may need ten minutes, a new product may need much longer. Stop diverging once the user clearly has a direction — don't manufacture options for their own sake.

## Writing `PRODUCT_BRIEF.md`
Write it in English (`CLAUDE.md` §2), whatever language the conversation was in. Record only what the user decided or confirmed. Anything still unresolved goes to Open questions — never fill a gap with a plausible guess, because `product-analyst` will treat everything else in the file as a decision.

```markdown
# Product Brief — <name>

_Last updated: YYYY-MM-DD_

## Problem
## Target users
## Current alternatives
## Proposed solution
<one or two paragraphs — the direction chosen, not a feature list>
## Goals and success metrics
## MVP scope
## Out of scope
## Constraints
## Assumptions and risks
<including the riskiest assumption and how it could be checked>
## Parked ideas
<options raised while diverging that weren't chosen — kept so they aren't rediscovered from scratch>
## Open questions
```

## Handing off
After writing the file, stop. Tell the user to review `PRODUCT_BRIEF.md`, and that the next step — once they're happy with it — is asking `orchestrator-architect` to turn it into a PRD (it will call `product-analyst`, which pauses for their approval of the PRD before building the backlog). Don't start that step yourself; the brief is a decision point, and the user should read it before anything is built on top of it.
