# Adventure — Figma File Structure

Proposed layout for the design source of truth.

## File

**Name:** `Adventure — Design System`

## Pages

### Foundations

- Colors / tokens (adventure-green, adventure-sky, adventure-earth, adventure-sand)
- Typography scale
- Spacing & grid (mobile-first: 375, tablet 768, desktop 1280+)
- Elevation, radius, motion

### Components

- Atoms: buttons, inputs, badges, avatars
- Molecules: trip cards, checklist rows, journal entry previews
- Organisms: app shell, bottom nav (mobile), header (desktop)

### Templates

- Mobile frame (375×812)
- Tablet frame (768×1024)
- Desktop frame (1280×800)

### Screens — MVP

1. Sign up / Sign in
2. Trip list (home)
3. Trip detail + timeline
4. New trip form
5. Journal entry create/edit
6. Empty states & loading states

### Dev handoff

- Token → Tailwind mapping notes
- Per-screen implementation annotations
- Review checklist (visual / developability / responsive)

## Review gate

1. AI generates review comments on each MVP screen
2. Human resolves blocking items
3. Frame status → **Ready for dev**
4. Only then: Figma MCP → code generation
