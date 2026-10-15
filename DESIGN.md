# ANUBIS Design Direction

## Mood

Night-shift operations room with precise bronze instrumentation: quiet light, hard-working surfaces, and no decorative noise.

## Color Strategy

Restrained product UI with an obsidian structural shell, pure light work surfaces, and bronze used below 10% as an accent. Tokens are semantic and mapped through Tailwind CSS v4 theme variables.

## Palette

- `background`: `oklch(0.985 0 0)` for light product surfaces.
- `foreground`: `oklch(0.155 0.012 250)` for high-contrast ink.
- `primary`: `oklch(0.18 0.018 250)` obsidian.
- `primary-foreground`: `oklch(0.985 0 0)`.
- `accent`: `oklch(0.58 0.105 78)` muted bronze.
- `accent-foreground`: `oklch(0.985 0 0)`.
- `muted`: `oklch(0.94 0.006 250)`.
- `muted-foreground`: `oklch(0.39 0.018 250)`.
- `success`: `oklch(0.49 0.118 155)`.
- `warning`: `oklch(0.68 0.13 78)`.
- `destructive`: `oklch(0.55 0.19 27)`.
- `info`: `oklch(0.5 0.13 245)`.

## Typography

Use system UI fonts for reliability, fast rendering, and platform familiarity. Headings use semibold weight with balanced wrapping. Body text starts at 16px with comfortable line height. Data values use tabular figures.

## Components

Base UI components are small, token-driven, accessible primitives. ANUBIS domain components live separately from generic UI components. Cards use modest 8px radius, visible borders, and restrained shadows only when elevation adds hierarchy.

## Motion

Motion is short, interruptible-feeling, and cause-driven: press feedback, dialog entrance, nav hover, loading shimmer. Reduced motion replaces movement with color/opacity changes. No looping ornamental animation in the application shell.

## Responsive Behavior

Technician flows are mobile-first with bottom navigation and large primary actions. Admin/Owner/Supervisor flows use a desktop sidebar and table-first information density, collapsing cleanly on mobile.
