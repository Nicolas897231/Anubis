# Auth

Fecha: 2026-10-15. Integracion implementada; ejecucion contra Supabase hosted PENDIENTE porque no existe proyecto.

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

Registrar correo propio, confirmar, crear organizacion, enrolar/verificar autenticador y entrar. No hay usuario/password demo.

Para crear un operador S&N, un DBA autorizado debe usar una migracion de datos controlada despues de que exista ese profile. Insertar UUID confirmado en platform_admins; no email, token ni password. No hay endpoint de auto-promocion. La membresia OWNER no implica operador de plataforma. /admin exige MFA y solo administra entitlements.

## Pruebas Hosted Pendientes

Registro/duplicado, email valido/invalido/vencido/reusado, login incorrecto, refresh, sesion expirada/manipulada, logout, cambio password, MFA correcto/incorrecto, invitacion de otro correo, dos tenants por usuario, suspension, salto de tenant y ataques directos Data API. Usar fixtures ficticios en proyecto dedicado.

Fuentes: [SSR oficial](https://supabase.com/docs/guides/auth/server-side/creating-a-client?queryGroups=framework&framework=nextjs), [TOTP](https://supabase.com/docs/guides/auth/auth-mfa/totp), [email templates](https://supabase.com/docs/guides/auth/auth-email-templates), [migraciones](https://supabase.com/docs/guides/local-development/database-migrations). Patrones Next contrastados con documentacion incluida en next/dist/docs.
