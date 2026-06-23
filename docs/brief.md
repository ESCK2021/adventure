# Adventure — Project Brief

## Overview

- **Product:** Adventure
- **One-liner:** Plan outdoor trips, log explorations, and revisit your adventures in one place.
- **Target user:** Weekend hikers, campers, and casual outdoor explorers who want a lightweight trip journal without heavy gear-tracking complexity.
- **Problem:** Trip plans live in notes apps, photos in the camera roll, and routes in scattered screenshots — nothing ties the story together.

## MVP (top 3 features)

1. **Trip planner** — Create a trip with title, dates, location, and a simple checklist (gear, reservations, waypoints).
2. **Adventure journal** — Add dated entries per trip with text, photos, and optional location pins.
3. **Trip timeline** — View a trip as a chronological feed of entries and checklist progress.

## Auth

- [x] Required in v1 (users need accounts to save trips and journals)
- Deferred: social sharing, public trip pages, team trips

## Brand & tone

- **Visual direction:** Warm, outdoorsy, approachable — earthy greens and sky blues, generous whitespace, mobile-first.
- **HeroUI:** Strict base for interactive components (buttons, forms, modals, nav); custom layout for trip cards and timeline.

## Design

- **Figma as source of truth:** Yes — design system and MVP screens before implementation.
- **Review gate:** AI review suggestions during exploration; **human acceptance required** before code generation and release.
- **First screens to design:**
  1. Design system foundations (tokens, typography, spacing)
  2. Auth (sign up / sign in)
  3. Trip list (home)
  4. Trip detail + timeline
  5. New trip form
  6. Journal entry create/edit
  7. Mobile navigation shell

## Technical (defaults)

| Layer | Choice |
|-------|--------|
| Framework | Next.js 15 + App Router + TypeScript |
| UI | HeroUI + Tailwind CSS v4 |
| Backend | Supabase (auth, Postgres, storage for photos) |
| Hosting | Vercel |
| Unit tests | Vitest |
| E2E | Playwright |
| Monitoring | Sentry + Vercel Analytics |
| CI/CD | GitHub Actions |
| Git model | GitFlow |
| MCP | Official remote Figma + GitHub + Supabase |

## GitHub

- **Owner:** _TBD — confirm personal account or org_
- **Repo name:** `adventure`
- **Auth:** Fine-grained PAT (default)

## Figma

- **Workspace/team:** _TBD_
- **File name:** `Adventure — Design System`
- **Approval signal:** Frame status set to "Ready for dev" + resolving all blocking review comments

## Supabase

- **Project ref:** _TBD — create new or link existing_
- **In scope for v1:**
  - [x] Schema (trips, entries, checklist items)
  - [x] Auth (email/password or magic link)
  - [x] Storage (journal photos)
  - [ ] Edge functions (defer unless needed for image processing)

## Success criteria for v1

- User can sign up, create a trip, add journal entries with photos, and view the trip timeline on mobile and desktop.
- CI passes (lint, typecheck, unit, E2E smoke) on every PR to `develop`.
- Preview deploy available on each PR; production deploy only from approved `release/*` branch.

## Open questions (resolve before implementation)

1. GitHub org/user and whether the remote repo already exists.
2. Figma workspace and who approves design review.
3. Supabase project ref and auth provider preference (email vs OAuth).
4. Photo size limits and storage quota expectations for v1.
