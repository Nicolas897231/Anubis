# Local Deployment

Fecha: 2026-10-15. Esta guia actualiza el laboratorio existente; no reinstala Docker ni toca Guardian.

## Topologia

Windows hosts/DNS -> https://anubis.snti.local -> Caddy :443 -> anubis-web :3000, red Docker privada.
Guardian usa :80. Mantener Caddy con solo 443 publicado y el bloque global auto_https disable_redirects al principio del Caddyfile. IP LAN solamente en hosts/DNS, nunca en codigo.

Phase 0 fue validada en Ubuntu. Esta nueva version Phase 1 requiere rebuild y smoke test propios. No se aplico remotamente desde esta sesion.

## Publicar Cambios En GitHub

En PowerShell, revisar antes de incluir archivos. Nunca agregar .env, passwords, certificados privados, tokens ni service_role.

```powershell
cd D:\Anubis
git status --short
git diff --check
git add src supabase tests docs package.json package-lock.json vitest.config.mts compose.yaml deploy/caddy/Caddyfile .gitignore .env.example README.md
git diff --cached --stat
git commit -m "Implement Anubis phase 1 data and authentication"
git push
```

El remote debe ser el repositorio del usuario ya configurado. No se hizo commit/push automatico. Dejar intacto cualquier archivo no relacionado; hay un archivo sin seguimiento anterior a este trabajo que no pertenece a Phase 1.

## Supabase Primero

Seguir AUTH.md para crear un proyecto de PRUEBAS, enlazar CLI, hacer db push --dry-run y aplicar migraciones. La app no crea la base automaticamente. No resetear produccion ni editar schema manualmente desde SQL Editor.

Configurar correo, confirmacion, TOTP y URLs exactas. El navegador debe resolver el FQDN dentro de la LAN y confiar en Caddy. No hacen falta IP publica, puertos DB publicados ni Supabase self-hosted.

## Actualizar Ubuntu

Usar el usuario propietario del checkout (nicolas), no alternar root con archivos de usuario. Si hay permisos incorrectos, un administrador debe corregir solo el checkout concreto tras revisar propietario; no aplicar chmod 777.

```bash
cd /opt/anubis/Anubis
git status --short
git diff -- compose.yaml deploy/caddy/Caddyfile
```

Si quedan las ediciones locales previas de Caddy/Compose, preservarlas antes de pull. Los archivos nuevos ya incluyen el ajuste de 443; no reponer automaticamente la version antigua.

```bash
git stash push -m "Configuracion local Caddy antes de Phase 1" -- compose.yaml deploy/caddy/Caddyfile
git pull --ff-only
```

Omitir stash si no hay cambios. Si hay otros cambios, revisarlos antes de continuar. Conservar el stash como referencia, no ejecutar stash pop a ciegas.

Crear .env solo si no existe. Nunca sobrescribir un .env configurado:

```bash
test -f .env || cp .env.example .env
chmod 600 .env
nano .env
```

Valores necesarios:

```dotenv
APP_URL=https://anubis.snti.local
SUPABASE_URL=https://TU_PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE
```

La publishable key no es service_role. No imprimir el contenido de .env en terminal/chat. APP_URL debe coincidir exactamente con el origen del navegador para Server Actions.

```bash
sudo docker compose -f compose.yaml config --quiet
sudo docker compose -f compose.yaml run --rm --no-deps caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
sudo docker compose -f compose.yaml build anubis-web
sudo docker compose -f compose.yaml up -d
sudo docker compose -f compose.yaml ps
sudo docker compose -f compose.yaml logs --tail=80 anubis-web caddy
```

No continuar si la validacion falla. up -d solo despues de build exitoso. No usar down -v ni borrar volumenes Caddy (contienen la CA). Nunca detener guardian-nginx para liberar :80.

## Windows Y TLS

Editar como administrador C:\Windows\System32\drivers\etc\hosts:

```text
IP_LAN_ACTUAL_DEL_SERVIDOR anubis.snti.local
```

Despues ejecutar ipconfig /flushdns. Si ya funciona el FQDN no cambiarlo.

Si la CA no esta instalada, exportar solo root.crt de Caddy mediante compose cp y transferir por SSH verificando host key. Nunca copiar root.key. Instalar solo la CA del servidor propio, verificando su huella:

```powershell
certutil -hashfile .\anubis-local-ca.crt SHA256
certutil -addstore -f Root .\anubis-local-ca.crt
curl.exe --ssl-revoke-best-effort https://anubis.snti.local/api/health
```

La excepcion de revocacion es por solicitud para CA interna; sigue verificando cadena/nombre. No usar -k ni desactivar controles TLS globales. La instalacion de raiz amplifica confianza: verificar origen antes de confiarla. Esta CA ya fue instalada en la PC de Nicolas.

## Smoke Test

- Health devuelve status ok; solo verifica proceso, NO DB/Auth.
- /app/dashboard sin sesion redirige a login.
- Registro propio -> correo confirmado -> onboarding -> TOTP -> dashboard.
- Crear cliente, servicio, asignarse como OWNER, iniciar, completar, guardar/finalizar informe.
- Crear segundo tenant ficticio y probar aislamiento y roles tambien via Data API.
- Reiniciar contenedores y verificar persistencia en Supabase y refresh de sesion.
- Probar login/confirmacion/recovery desde movil con DNS y CA configurados.

No hay password demo ni datos demo cargados por migraciones.

## Rollback Y Operacion

Conservar imagen/tag previo antes de reemplazarlo y backups DB antes de migrar. Rollback de imagen no revierte schema automaticamente; no borrar datos ni ejecutar migraciones inversas improvisadas. Las seis migraciones iniciales solo agregan el nucleo nuevo.

Restringir firewall a las redes necesarias. ANUBIS no publica 3000 ni PostgreSQL. Revisar aparte MySQL de Guardian, que aparecia publicado en todas las interfaces; no se modifico como parte de este trabajo. Antes de internet: dominio/certificado publico, SMTP, rate limiting, backups probados, monitoreo y privacidad aprobada.
