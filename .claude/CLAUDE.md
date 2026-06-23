# Adventure — Agent Operating Rules

## Principles

- **One main agent** coordinates the full workflow. Spawn sub-agents only for isolated, non-overlapping tasks.
- **Figma is the source of truth before code.** Do not implement UI from specs alone when Figma designs exist.
- **Design review is a release gate.** No production-bound implementation without human-approved Figma frames.
- **Serial over parallel** when tasks touch the same file, schema, or tightly coupled logic.
- **Keep the toolchain simple.** Avoid multi-agent orchestration platforms unless the project explicitly requires them.

## Stack

- Next.js 15 (App Router) + TypeScript
- HeroUI + Tailwind CSS v4
- Supabase (auth, database, storage)
- Vercel (hosting + previews)
- Vitest (unit) + Playwright (E2E)
- Sentry + Vercel Analytics

## Git

- **GitFlow:** `feature/*` → `develop` → `release/*` → `main`
- **Conventional Commits** (`feat:`, `fix:`, `chore:`, etc.)
- Prefer **GitHub MCP** for issues, PRs, branches, and CI visibility when available.
- Never commit secrets (`.env`, tokens, service keys).

## Workflow

1. Read `docs/brief.md` for product scope.
2. Generate or update **Figma** (design system → components → MVP screens → dev notes).
3. Run **AI design review**; obtain **human approval** (frame status + resolved blocking comments).
4. Read approved frames via **Figma MCP**; implement aligned with HeroUI + Tailwind tokens.
5. Open PR to `develop` with structured description (what / why / tests / design link).
6. CI must pass (lint, typecheck, unit, E2E smoke).
7. Preview deploy on PR; production only from approved `release/*` after design gate.

## MCP usage

| Server | Use for |
|--------|---------|
| Figma (remote) | Read approved designs; create/update when writable |
| GitHub | Branches, commits, PRs, issues, CI status |
| Supabase | Schema, migrations, types, RLS policies |

## Sub-agents

Delegate only when work is isolated. Definitions live in `.claude/agents/`.

| Agent | When |
|-------|------|
| `design-token-extractor` | After Figma approval, before UI implementation |
| `github-issue-writer` | Spec intake, release notes, PR bodies |
| `test-fixer` | CI failure with isolated, fixable test errors |
| `db-migration-writer` | Schema changes only |
| `page-component-generator` | Single page/component from one Figma frame |

## Logging & visibility

Every PR and significant commit should answer:

- What changed?
- Why?
- What tests ran?
- What failed and what was fixed?
- Link to Figma frame(s) and design approval status.

## Responsive quality

Mobile-first layouts are mandatory. Review standard includes visual consistency, developability, and **mobile spacing / responsive layout quality**.

## Project docs

- Product brief: `docs/brief.md`
- Changelog: `docs/changelog.md`
- Agent action log (optional): `docs/agent-log/`
