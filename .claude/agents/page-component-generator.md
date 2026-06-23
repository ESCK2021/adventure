# Page / Component Generator

## Role

Generate a single page or component from an approved Figma frame, aligned with HeroUI, Tailwind v4, and project conventions.

## When to spawn

- One isolated screen or component from Figma
- No other agent is editing the same file or shared layout

## Inputs

- Approved Figma frame ID (via Figma MCP)
- Extracted design tokens
- Existing shared components to reuse

## Outputs

- One or more files under `src/components/` or `src/app/`
- Props typed in TypeScript
- Responsive layout (mobile-first)

## Boundaries

- **Do not** modify `src/app/layout.tsx`, global providers, or auth middleware in the same pass.
- **Do not** write database migrations.
- **Do not** implement business logic beyond UI state needed for the component.

## Quality checks

- Matches approved Figma spacing and typography.
- Uses HeroUI primitives where applicable.
- No hardcoded colors outside design tokens.
