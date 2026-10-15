# Performance

## Baseline Goals

- LCP <= 2.5s when measured on target hardware.
- INP <= 200ms.
- CLS <= 0.1.
- Fast enough for mid-range mobile devices in field conditions.

## Current Optimizations

- Prefer Server Components by default.
- Client Components are limited to interactive UI such as cookie consent and dialogs.
- No heavy animation library was added.
- No 3D, particles, parallax, or scroll hijacking.
- Fonts use Next.js font optimization through Geist.
- Images use `next/image` with intrinsic dimensions.
- Hero/brand images use the Next.js 16 `preload` prop instead of deprecated `priority`.
- Static assets are local; no remote image domains are configured.
- Docker uses standalone output to reduce runtime files.

## Image Notes

High-quality raster brand assets are in `public/brand`.

The current logo lockups are around 1 MB each as source assets. They are rendered through `next/image`, so the self-hosted Next server can optimize responsive responses at runtime. On the Ubuntu target, verify that image optimization cache writes correctly inside the container.

Generated app icons:

- `public/brand/anubis-app-icon.png`: 512 x 512.
- `src/app/icon.png`: 512 x 512.
- `src/app/apple-icon.png`: 180 x 180.
- `src/app/favicon.ico`: 16/32/48 family.

## Bundle Concerns

Current dependencies are intentionally small:

- Radix Dialog/Slot.
- Supabase JS prepared for future use.
- Lucide icons.
- Tailwind utility runtime generated at build.
- No charting, animation, map, PDF, AI, or payment SDKs yet.

## Client Component Concerns

Keep future client components scoped. Do not move layout/page shells to client components unless there is a clear interaction need.

## Lighthouse

Lighthouse was not executed in this environment. Run it on the Ubuntu deployment URL after Docker and Caddy are running:

```bash
npx lighthouse https://anubis.snti.local --view
```

If the local CA is not trusted by the runner, execute Lighthouse from a browser profile that trusts `anubis-local-ca.crt`.

## Pending Performance Validation

- Measure Lighthouse on `/`.
- Measure responsive interaction on `/app/services/demo-service-001`.
- Verify Next image optimization cache in the Docker runtime.
- Re-check bundle after Phase 1 introduces auth, database calls, storage, and reporting.
