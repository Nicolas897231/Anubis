# Performance

Fecha: 2026-10-15.

## Objetivos Sin Medicion Productiva

LCP <= 2.5s, INP <= 200ms, CLS <= 0.1. No se afirma cumplimiento: falta Lighthouse y medicion con Auth/DB hosted en dispositivos de campo.

## Implementacion

- Server Components; cliente limitado a formularios/estados MFA y fecha local.
- Selecciones explicitas sin SELECT * de PostgREST; SQL usa filas completas solo dentro de RPC puntuales con PK.
- Listas clients/services/reports/team/admin: 25 por pagina, hasta pagina 400; ampliar a keyset si el volumen lo requiere.
- Dashboard: 4 conteos y lista acotada, no N+1. Nombres del equipo resueltos en una consulta batch.
- Consulta de clientes/responsables para formularios: 50 resultados y busqueda; supervisores: 100 max.
- Onboarding: 100 membresias/organizaciones y 50 invitaciones; detalle: 25 asignaciones y 20 versiones recientes. Reportes globales si se necesitan versiones anteriores. Estos limites evitan cargas completas, no son una UX ilimitada.
- Indices compuestos por tenant y filtros; unicidad parcial de asignacion actual y borrador.
- DAL React cache por render, sin cache compartida de datos autenticados. Esto reduce riesgo de filtracion, no elimina el coste Auth por request.
- connection() garantiza variables runtime y autenticacion fuera del prerender. Suspense delimita shell.
- Imagenes de marca de alta calidad conservadas con next/image; dimensiones intrinsecas; sin nuevas librerias pesadas de animacion/PDF.

## Compromisos

Locks organization serializan mutaciones y seat checks: correcto para esta fase, medir contencion antes de escala. OFFSET profundo y count exact pueden degradarse con tablas grandes. No se ejecutaron EXPLAIN/benchmark sobre datos productivos. Probar cache de imagenes dentro de Docker non-root y latencia de region Supabase.
