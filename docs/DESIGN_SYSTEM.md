# ANUBIS Design System

## Direction

Premium B2B Operational SaaS. The visual identity uses obsidian structure, light work surfaces, slate neutrals, and restrained bronze accents. Egyptian inspiration remains abstract and sophisticated.

The official visual reference is the ANUBIS identity board and the high-quality raster exports supplied by S&N TI. The application uses those files directly through stable asset names and keeps the component API ready to swap to final SVG/vector assets later if approved.

## Tokens

Tokens are defined in `src/app/globals.css` using semantic CSS variables and OKLCH color values:

- `background`, `foreground`
- `surface`, `surface-elevated`, `surface-muted`
- `card`, `card-foreground`
- `muted`, `muted-foreground`
- `primary`, `primary-foreground`
- `accent`, `accent-foreground`, `accent-hover`, `accent-soft`, `accent-strong`
- `success`, `warning`, `destructive`, `info`
- `border`, `border-strong`, `input`, `focus-ring`
- `sidebar`, `sidebar-foreground`, `sidebar-muted`, `sidebar-active`

Official palette mapping:

- Obsidian `#0B0D0D`: sidebar, dark hero surfaces, app icon, brand backgrounds.
- Bronze `#B88955`: primary commercial CTA, selections, premium indicators, minimal divider lines.
- Slate `#334155`: secondary dark text and structural metadata.
- Sand `#F5F1EA`: warm secondary surfaces and commercial sections.
- Neutral `#9CA3AF`: metadata only where contrast remains accessible.

## Typography

The application uses system-like Geist fonts from Next.js for performance and legibility. Body text starts at accessible sizes, headings are restrained, and numeric operational values use tabular figures where useful.

## Components

Initial components:

- AnubisLogo
- AnubisMark
- BrandLockup
- PoweredBySN
- BrandDivider
- PrivacyNotice
- CookieConsentBanner
- AppShell
- AdminSidebar
- MobileBottomNav
- TopBar
- PageHeader
- StatCard
- DataTable
- EmptyState
- ErrorState
- LoadingState
- ServiceCard
- ServiceStatusBadge
- UserAvatar
- ConfirmDialog
- FormField
- SearchInput
- FilterBar
- ResponsiveDrawer
- TechnicianMobileShell

## Brand Assets

Stable application assets:

- `public/brand/anubis-app-icon.png`: 512 x 512 app icon used by the shell and manifest.
- `public/brand/anubis-app-icon-source.png`: high-quality square source.
- `public/brand/anubis-light-lockup.png`: high-quality full lockup for light contexts.
- `public/brand/anubis-dark-lockup.png`: high-quality full lockup for dark contexts.
- `public/brand/anubis-transparent-lockup.png`: transparent-background source retained for future usage.
- `src/app/icon.png`, `src/app/apple-icon.png`, `src/app/favicon.ico`: generated from the high-quality app icon source.

Do not distort, recolor, trace, or regenerate the logo. If final vector files arrive later, replace the stable asset files and preserve component contracts.

## Accessibility

Baseline target: WCAG 2.2 AA.

- Visible focus states use `focus-ring`.
- Inputs have associated labels.
- Icon-only buttons include accessible names.
- Touch targets use at least 44px height.
- Reduced motion is respected globally.
- Layouts reflow for mobile and desktop.
- Data tables are paired with mobile card alternatives.
- Cookie and privacy controls are keyboard reachable and do not imply optional tracking is active.

## Responsive

Technician workflows are mobile-first with bottom navigation and prominent actions. Owner/Admin/Supervisor workflows use desktop sidebar, sticky topbar, metrics, filters, tables, and responsive cards.

## Anti-Patterns

- Do not redraw, distort, recolor, glow, or add 3D effects to the ANUBIS logo.
- Do not use bronze as small low-contrast body text or broad background fill.
- Do not use Egyptian literal decoration; the symbol carries the reference.
- Do not convert protected behavior into frontend-only state.
- Do not add heavy animation, parallax, particles, or decorative charts.
