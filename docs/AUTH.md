# Auth

Base historica: 2026-10-15. Actualizacion Auth local: 2026-10-17, IMPLEMENTED / RETEST REQUIRED.
Ubuntu + Docker + Caddy + Supabase LOCAL es el entorno de desarrollo/integracion. Cloud: DEFERRED UNTIL PRE-PRODUCTION; las instrucciones hosted de abajo son referencia futura, no tarea actual.

## P1-LOCAL-AUTH-FIX-C 2026-10-18

- Retest REAL informado por el usuario: `AUTH-LOCAL-01 FAIL`, `AUTH-LOCAL-02 FAIL`, `AUTH-LOCAL-03 PASS`.
- Comprobación local de despliegue: `HEAD=3065949 (prepro)` y `origin/main` no contienen los cambios A/B. Las correcciones están sin commit en el working tree; `git log -S` no encontró un commit con `postAuthPath` ni `readAal2AuthSession`.
- El código de `HEAD` todavía tenía `login -> /onboarding`, `verifyMfa -> /onboarding`, `requirePlatformAdmin` con `/mfa` y onboarding sin el resolver central. Esto explica los síntomas si Ubuntu construyó desde ese commit, pero no demuestra qué imagen está ejecutando el servidor.
- No hubo conexión SSH autorizada para inspeccionar Ubuntu. Antes de modificar Auth, comparar commit, hashes de archivos Auth y la imagen efectiva del contenedor. No crear otro parche hasta demostrar que Ubuntu ejecuta el working tree A/B.

### Comprobación De Paridad Sin Secretos

En Windows, desde `D:\Anubis`, guardar únicamente la salida de estos comandos. En Ubuntu, desde `/opt/anubis/Anubis`, ejecutar los mismos comandos y las comprobaciones de imagen indicadas abajo. No incluir `.env`, logs de Auth, cookies, tokens ni credenciales.

```powershell
git rev-parse HEAD
git hash-object src/lib/auth/actions.ts src/lib/auth/context.ts src/lib/auth/destination.ts src/app/mfa/page.tsx src/app/onboarding/page.tsx src/lib/supabase/server.ts
```

```bash
git rev-parse HEAD
git status --short
git hash-object src/lib/auth/actions.ts src/lib/auth/context.ts src/lib/auth/destination.ts src/app/mfa/page.tsx src/app/onboarding/page.tsx src/lib/supabase/server.ts
docker inspect anubis-anubis-web-1 --format 'CONTAINER_IMAGE={{.Image}}'
docker image inspect anubis-web:local --format 'IMAGE_ID={{.Id}} CREATED={{.Created}}'
docker compose -f compose.yaml -f compose.lab.yaml config --quiet && echo COMPOSE_CONFIG=VALID
```

Si hashes/imagen no corresponden al artefacto A/B, publicar/construir el commit correcto será una operación separada y explícita; esta tarea no despliega.

## P1-LOCAL-AUTH-FIX-A 2026-10-18

- Causa confirmada en el flujo: login y verificación MFA no compartían un destino post-autenticación basado en identidad/permisos; rutas anteriores podían caer en onboarding. La resolución ahora prioriza `platform_admins`, invitaciones válidas y memberships/entitlements autorizados. Platform Admin va a `/mfa?next=/admin` en AAL1 y a `/admin` en AAL2, sin requerir organización.
- La selección de organización conserva el destino interno autorizado; OWNER/ADMIN llegan a dashboard después de AAL2 y TECHNICIAN/SUPERVISOR mantienen el alcance de su organización. El parámetro `next` usa allowlist exacta y no concede permisos ni acepta destinos externos.
- Después de `challengeAndVerify`, la redirección exige simultáneamente `getAuthenticatorAssuranceLevel().currentLevel === aal2` y `claims.aal === aal2` leídos del cliente SSR actualizado. Si no coinciden, se conserva el error y no se redirige con una sesión antigua. La propagación SSR de cookies sigue usando el adaptador writable y el proxy.
- AUTH-LOCAL-01 y AUTH-LOCAL-02: corrección implementada, retest manual real en Ubuntu/browser pendiente. AUTH-LOCAL-03 recovery permanece pendiente para `P1-LOCAL-AUTH-FIX-B`. No se cambiaron migraciones, RLS, Docker, Caddy ni Guardian.

## P1-LOCAL-AUTH-FIX-B 2026-10-18

- El flujo conserva el intercambio real de Supabase (`verifyOtp` o PKCE con AMR `recovery`) y solo después crea el contexto firmado `anubis-recovery`. Una sesión ordinaria no puede llamar a `updateUser` desde esta acción.
- La comprobación de contexto sigue ligada a `sub`, `session_id`, expiración de 15 minutos y firma HMAC. Si el challenge TOTP rota `session_id`, el contexto se vuelve a firmar únicamente después de confirmar AAL2 real; no se relaja la vinculación ni se simula AAL.
- `updateUser` continúa siendo la única operación de cambio. Sus rechazos ahora dejan en log únicamente `code`, `status` y `name` sanitizados, para distinguir `insufficient_aal`, `reauthentication_needed` o sesión inválida sin revelar tokens, cookies, correo ni mensajes privados. El usuario conserva el mensaje seguro.
- Diagnóstico de configuración en este checkout: `.env` y `.env.lab` no están presentes. Compose carga `AUTH_RECOVERY_SECRET` desde `/opt/anubis/Anubis/.env` mediante `env_file`; `--env-file .env.lab` solo resuelve variables de Compose y no sustituye ese `env_file`. La comprobación remota Ubuntu quedó pendiente por SSH no disponible.
- `AUTH-LOCAL-03`: código corregido y 73 pruebas dirigidas simuladas PASS; permanece `RETEST PENDING` hasta validar Mailpit/Supabase local en Ubuntu. No se modificaron SQL, RLS, migraciones, Docker, Caddy ni Guardian.

### Procedimiento Seguro De Retest Ubuntu

1. En `/opt/anubis/Anubis/.env`, configurar `AUTH_RECOVERY_SECRET` como 64+ caracteres hexadecimales, estable entre reinicios; no imprimirlo ni subirlo a Git. Mantener `SUPABASE_URL`, publishable/anon key y `APP_URL` existentes.
2. Verificar sin mostrar el valor: `grep '^AUTH_RECOVERY_SECRET=' .env | awk '{print "AUTH_RECOVERY_SECRET_PRESENT=" ($0 !~ /=$/) }'`. Confirmar que `docker compose -f compose.yaml -f compose.lab.yaml config --quiet` pasa.
3. Reconstruir solo `anubis-web` con la orden documentada previamente, sin `db reset` ni borrar volúmenes. Revisar únicamente estado healthy y logs sanitizados de `[auth] password update rejected`.
4. Probar enlace válido sin MFA, enlace vencido/reusado, contexto ausente/tamper, TOTP incorrecto/correcto si aplica, contraseña nueva, contraseña antigua y login nuevo. Confirmar Platform Admin `/admin`, OWNER en su organización y MFA una sola vez.
5. Registrar solo PASS/FAIL y, si falla, el código sanitizado (`insufficient_aal`, `reauthentication_needed`, etc.); nunca pegar tokens, cookies, códigos, enlaces o secretos.

## Correccion Local 2026-10-17

- Un resolver server-side gobierna login, confirmacion, seleccion, MFA y continuacion: allowlist platform_admins primero (/admin con AAL2, MFA antes si falta); despues invitacion vigente por email confirmado; despues membership activa y organizacion/entitlement utilizable. Conserva seleccion autorizada o elige el unico tenant utilizable; varios sin seleccion -> chooser. Solo un usuario sin rol/invitacion/membresia ve crear organizacion. No asigna tenants a operadores S&N.
- next es una allowlist exacta: /admin, /app/dashboard, /onboarding, /reset-password. Otros valores vuelven al resolver con fallback /onboarding; next no concede permisos. Recovery validado tiene prioridad sobre routing de plataforma/tenant.
- MFA guarda seleccion antes del challenge, conserva next y comprueba claims nuevos mas getAuthenticatorAssuranceLevel antes de redirigir. No reutiliza el contexto cacheado anterior a la mutacion ni fuerza refreshSession sin necesidad. SDK instalado ya persiste MFA_CHALLENGE_VERIFIED; las mutaciones ahora propagan errores de Set-Cookie, mientras RSC conserva refresco mediante proxy. Esto no prueba aun propagacion real en Ubuntu/browser.
- Recovery requiere verifyOtp(type=recovery) exitoso o intercambio PKCE con AMR recovery verificado por getClaims. Ni next ni redirectType del verifier cookie son prueba. Se firma un contexto HttpOnly/Secure/SameSite=Lax de 15 minutos ligado a sub/session_id; no contiene token de correo, JWT ni refresh token. Una sesion normal no permite update. Un factor verificado exige AAL2 antes de update; despues se elimina contexto/tenant y se solicita signOut global y login nuevo. Si revocacion global falla, se intenta cierre local y se muestra aviso sin afirmar cierre global.
- No se almacena ningun token recovery adicional. La clave de firma solo autentica el contexto; nunca establece AAL ni reemplaza validacion Supabase. Rotarla invalida contextos recovery pendientes. Un factor perdido no obtiene bypass.

Causas comprobadas en codigo: login/verifyMfa redirigian siempre a onboarding; no habia next ni comprobacion AAL post-challenge; reset aceptaba requireUser sin comprobar origen recovery ni step-up. La causa exacta remota de cookies y el error Auth de update no se observaron: verificar los tres defectos antes de PASS. Referencia de protocolo: [verifyOtp emite sesion OTP](https://github.com/supabase/auth/blob/master/internal/api/verify.go), [PKCE usa metodo del flujo server-side](https://github.com/supabase/auth/blob/master/internal/api/token.go).

### Configuracion Para El Retest Ubuntu

Agregar AUTH_RECOVERY_SECRET a /opt/anubis/Anubis/.env, nunca NEXT_PUBLIC_ ni Git. Compose ya carga ese archivo mediante env_file; no cambiar puertos, Caddy o Supabase. Generar una sola vez 32 bytes aleatorios hex (64 caracteres) con `openssl rand -hex 32` y guardar el valor unicamente en .env mediante editor privado; no pegarlo en chat/logs. Mantenerlo estable al reconstruir/reiniciar y proteger .env con permisos restrictivos. .env.example solo contiene el nombre vacio.

Tras publicar/descargar el codigo y configurar la clave, reconstruir solo ANUBIS con la combinacion de Compose existente:

```bash
cd /opt/anubis/Anubis
docker compose --env-file .env.lab -f compose.yaml -f compose.lab.yaml up -d --build --no-deps anubis-web
```

No se ejecuto este despliegue desde el agente. Clave ausente/invalida bloquea recovery con mensaje de configuracion, no consume token_hash y no afecta login normal. Confirmar healthy y revalidar los casos de [LOCAL_LAB_VALIDATION](LOCAL_LAB_VALIDATION.md), incluyendo password anterior denegado/nuevo aceptado, cookie AAL2 tras un solo TOTP y refresh autorizado. Los mocks no prueban estas propiedades remotas. No full gate.

## Base De Integracion

## Flujo

Registro envia email/password a Supabase y solo display_name como metadata. Trigger crea profiles; metadata no determina roles. La confirmacion usa token_hash y tipos permitidos; callbacks redirigen solo al origen APP_URL y rutas locales permitidas.

Login usa signInWithPassword. El proxy refresca cookies; la DAL vuelve a comprobar getUser y getClaims, email confirmado y coincidencia de sub. Nunca autoriza con getSession, decodificacion manual de JWT ni user_metadata.role.

Onboarding crea organization, subscription y OWNER en una transaccion; un profile puede pertenecer a muchos tenants, pero no crear trials propios ilimitados. Seleccion de tenant usa cookie anubis-org no confiable; cada request verifica membership activa y entitlement vigente. Suspension/retirada revoca operaciones DB en la siguiente consulta.

Invitacion es membership invited con email y expiracion 7 dias. No reserva seat. El destinatario se registra/confirma/login y acepta; el RPC compara correo confirmado de auth.users, estado, vencimiento, tenant y cupo bajo lock. No usa token propio ni confia en UUID como secreto. No se envia correo de invitacion todavia.

Reset envia respuesta generica y correo Supabase; token hash recovery o intercambio PKCE llevan a /reset-password. Actualiza password y signOut global. Logout normal usa scope local y elimina seleccion de organizacion.

## MFA

TOTP real via enroll + challengeAndVerify. OWNER, ADMIN y S&N platform admin requieren aal2 tanto en SQL como en la DAL. El bootstrap de organizacion admite aal1 para poder configurar TOTP despues; no da acceso operativo privilegiado hasta verificarlo. SUPERVISOR/TECHNICIAN no lo requieren en esta fase.

El QR es exclusivamente de enrolamiento de autenticador, no un modulo comercial QR. El secreto solo se devuelve al usuario autenticado durante enrolamiento; no se registra ni persiste en tablas propias. Recuperacion de factor perdido pendiente, sin bypass de MFA.

## Sesion Y CSRF

Cookies Auth son HttpOnly, SameSite=Lax, Secure en HTTPS, path /. Todo auth/data de Phase 1 se ejecuta en servidor. El browser client queda separado y sin consumidores; no tiene acceso a las cookies HttpOnly. No mezclar ese cliente con auth hasta redisenar explicitamente esa frontera.

Proxy impide cache compartida (private/no-store), y connection() pospone lectura de configuracion al request. React cache solo deduplica la DAL durante el render, no entre usuarios. No use cache para datos autenticados.

Server Actions verifican Origin igual a APP_URL ademas del control Origin/Host de Next. No se agrego wildcard a allowedOrigins. Las rutas de confirmacion son GET con tokens de un uso; no son una autorizacion para otras mutaciones.

Supabase controla JWT, firma, exp y refresh. Las pruebas locales simulan sus respuestas: no equivalen a verificacion criptografica real. Signout revoca refresh; access tokens emitidos pueden funcionar hasta su expiracion. No se promete revocacion instantanea de todos los dispositivos.

## Preparar Proyecto De Pruebas

1. Crear un proyecto ANUBIS en [Supabase Dashboard](https://supabase.com/dashboard). Elegir region y plan conscientemente; guardar password DB en un gestor, nunca en chat/git.
2. Desde la raiz del repo y con Node compatible, usar CLI: comandos siguientes. Autenticarse interactivamente; no incluir tokens/password en historial.
3. Configurar Site URL: https://anubis.snti.local. Permitir solo los redirects exactos /auth/confirm y /auth/callback?next=/reset-password del mismo origen. No comodines de produccion.
4. Activar Email/password, confirmacion de correo, minimo 12 caracteres, TOTP y SMTP propio. Revisar limites Auth y CAPTCHA antes de publicar. No usar datos reales con el mailer de pruebas.
5. Ajustar templates usando SiteURL y TokenHash, no dejar flujos de tokens en fragmentos que el servidor no puede leer.

```powershell
cd D:\Anubis
npx supabase login
npx supabase link --project-ref TU_PROJECT_REF
npx supabase migration list
npx supabase db push --dry-run
npx supabase db push
```

Hacer dry-run y confirmar proyecto de PRUEBAS antes de db push. Nunca ejecutar db reset contra remoto. supabase/config.toml documenta defaults locales; NO configura automaticamente Auth del proyecto cloud.

Template Confirm signup (en el template de Supabase, no JSX):

```html
<a href="{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=signup"
  >Confirmar cuenta</a
>
```

Template Reset password:

```html
<a href="{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=recovery"
  >Actualizar contrasena</a
>
```

El enlace .local se abre en el navegador del usuario dentro de la LAN, con hosts/DNS y CA confiable. Supabase cloud no necesita resolver ese nombre para emitir el correo. Acceso desde fuera de la LAN no esta habilitado.

## Variables En Ubuntu

En /opt/anubis/Anubis/.env, sin subir a Git:

```dotenv
APP_URL=https://anubis.snti.local
SUPABASE_URL=https://TU_PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE
```

Se obtienen Project URL y publishable key del proyecto. No usar secret key ni service_role (incluido JWT legacy). No se necesita esa clave privilegiada para este producto. El servidor acepta variables NEXT_PUBLIC_* como compatibilidad; preferir nombres runtime de arriba para no recompilar por configuracion. NEXT_PUBLIC_SUPABASE_ANON_KEY es solo legacy anon, nunca service_role.

## Primer Acceso Y Operador De Plataforma

Usuario ordinario nuevo: registrar correo propio, confirmar, crear organizacion, enrolar/verificar autenticador y entrar. Operador de plataforma allowlisted: confirmar/login -> MFA -> /admin, sin crear organizacion. No hay usuario/password demo.

Para crear un operador S&N, un DBA autorizado debe usar una migracion de datos controlada despues de que exista ese profile. Insertar UUID confirmado en platform_admins; no email, token ni password. No hay endpoint de auto-promocion. La membresia OWNER no implica operador de plataforma. /admin exige MFA y solo administra entitlements.

## Pruebas Hosted Pendientes

Registro/duplicado, email valido/invalido/vencido/reusado, login incorrecto, refresh, sesion expirada/manipulada, logout, cambio password, MFA correcto/incorrecto, invitacion de otro correo, dos tenants por usuario, suspension, salto de tenant y ataques directos Data API. Usar fixtures ficticios en proyecto dedicado.

Fuentes: [SSR oficial](https://supabase.com/docs/guides/auth/server-side/creating-a-client?queryGroups=framework&framework=nextjs), [TOTP](https://supabase.com/docs/guides/auth/auth-mfa/totp), [email templates](https://supabase.com/docs/guides/auth/auth-email-templates), [migraciones](https://supabase.com/docs/guides/local-development/database-migrations). Patrones Next contrastados con documentacion incluida en next/dist/docs.
