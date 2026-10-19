# Slice de dominio: AUTH (solo abrir para P1-LOCAL-AUTH-FIX)

## Defectos observados en Ubuntu
- AUTH-LOCAL-01: un operador registrado en `platform_admins` y con MFA puede volver a `/onboarding` y recibir invitación a crear una organización; debería acceder a `/admin` sin membresía tenant.
- AUTH-LOCAL-02: usuario con organización hace Entrar→MFA→Entrar→MFA→Entrar; verificación real de AAL y cookies/selección de organización.
- AUTH-LOCAL-03: recovery por Mailpit llega a “Nueva contraseña” pero `updateUser`/acción falla; mostrar diagnóstico seguro sin perder/ver exposición de token.

## Contrato mínimo de arreglo
- Conservar autorización servidor + RLS y `AAL2` real; nunca forzarlo en una cookie propia.
- Usar identidad/roles de BD y sesión Supabase como verdad; no confiar en `user_metadata`/parámetros del navegador para privilegios.
- Resolver destino seguro tras auth/MFA: platform→`/admin`; invitado→aceptación; usuario tenant→organización/app; nuevo sin roles→onboarding. Validar parámetro `next` como ruta local segura.
- MFA correct: reto una vez y redirigir tras sesión AAL2; incorrecto se rechaza. Recovery correcto verifica sesión, aplica política de segundo factor y permite nueva contraseña.
- Pruebas dirigidas de rutas/redirect, AAL1/2, plataforma sin org, password antigua rechazada, invalid/expired recovery y sin regresiones de seguridad.

**No ejecutar otras funcionalidades ni cierre de fase en este slice.** Leer `docs/AUTH.md` solo si es requerido por el cambio concreto.
