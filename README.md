# Adventure

Plan outdoor trips, log explorations, and revisit your adventures in one place.

## Status

**Bootstrap phase** — agent workflow, brief, and toolchain are in place. Implementation follows Figma design approval per `docs/brief.md`.

## Stack

- Next.js 15 + TypeScript + HeroUI + Tailwind CSS v4
- Supabase · Vercel · Vitest · Playwright · GitHub Actions
- MCP: Figma (remote) · GitHub · Supabase

## Getting started

### Prerequisites

- Node.js 22+
- Xcode Command Line Tools (for `git` on macOS) — install with `xcode-select --install` if needed
- Copy `.env.example` → `.env.local` and fill Supabase + GitHub MCP secrets

### Install & run

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

### Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Dev server (Turbopack) |
| `npm run build` | Production build |
| `npm run lint` | ESLint |
| `npm run typecheck` | TypeScript check |
| `npm run test` | Vitest unit tests |
| `npm run test:e2e` | Playwright E2E |

## Project structure

```text
.claude/          Agent rules + sub-agent definitions
.cursor/          MCP configuration
.github/          CI/CD workflows + PR template
docs/             Product brief, changelog, agent logs
src/              Next.js application
supabase/         Database migrations
tests/            Unit + E2E tests
```

## Workflow

1. Read `docs/brief.md`
2. Design in Figma (source of truth) → human approval
3. Implement via agent using Figma MCP
4. PR to `develop` → CI → preview deploy
5. `release/*` → production after design gate

See `.claude/CLAUDE.md` for full agent operating rules.

## Git

GitFlow: `feature/*` → `develop` → `release/*` → `main`

> **Note:** Git was not initialized automatically (Xcode CLI tools missing on this machine). Run `git init` after installing command line tools, then create the GitHub remote.

## Open setup items

- [ ] GitHub org/user + remote repo
- [ ] Fine-grained PAT for GitHub MCP
- [ ] Figma workspace + design file
- [ ] Supabase project ref + env vars
- [ ] Vercel project link + secrets for preview/release workflows
