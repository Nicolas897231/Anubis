# Supabase Local En Ubuntu

Fecha: 2026-10-17. Ruta elegida explicitamente por Nicolas: laboratorio local primero.
Estado: archivos preparados; ejecucion Ubuntu y Auth real pendientes. No es Supabase cloud ni un despliegue self-hosted de produccion.

## Topologia Y Limites

PC -> ANUBIS/Caddy :443 -> Next.js privado -> Caddy interno :8443 -> API Supabase en red Docker anubis-supabase-lab.

- Guardian conserva :80. compose.yaml y deploy/caddy/Caddyfile base no se modifican.
- compose.lab.yaml es opt-in. API/DB/Studio/correo solo publican en loopback Ubuntu; nunca abrir sus puertos a LAN/internet.
- El hostname supabase.anubis.internal existe solo como alias Docker. No agregarlo al hosts de Windows; no publicar 8443.
- El servidor Next.js mantiene HTTPS hacia Supabase y verifica la CA con NODE_EXTRA_CA_CERTS. No usar -k, NODE_TLS_REJECT_UNAUTHORIZED=0 ni service_role.
- Supabase CLI es un laboratorio con credenciales de desarrollo y permisos administrativos locales. Solo datos ficticios; backups antes de actualizar. No sustituye validacion hosted ni SMTP externo.
- Los correos de confirmacion/recovery se capturan localmente. Invitaciones de membresia siguen sin envio implementado.

## 1. Publicar Y Descargar

Desde D:\Anubis en PowerShell, revisar la seleccion antes del commit. Estos son los archivos de esta preparacion; otros cambios Phase 1 pendientes requieren revision separada.

```powershell
git status --short
git add .gitattributes .gitignore .dockerignore compose.lab.yaml deploy/local supabase/config.toml supabase/templates docs
git diff --cached --stat
git diff --cached --check
git commit -m "Prepare isolated Ubuntu Supabase lab"
git push
```

No incluir .env, .env.lab, certificados o claves. En Ubuntu, como propietario del checkout:

```bash
cd /opt/anubis/Anubis
git status --short
git pull --ff-only
bash deploy/local/preflight.sh
```

Si hay cambios locales, preservarlos/revisarlos antes de pull siguiendo [LOCAL_DEPLOYMENT](LOCAL_DEPLOYMENT.md). No usar reset/clean, no sobreescribir .env. Detenerse si cualquier paso falla. El preflight es solo lectura y para primera instalacion: muestra recursos/puertos y exige Caddy existente, Docker accesible y checkout sin enlace cloud. Node/npm NO se requieren en Ubuntu: Node ya esta en la imagen ANUBIS. La CLI nativa Supabase se instala despues del preflight; no se cambian permisos Docker automaticamente.

Correccion 2026-10-17: el usuario reporto `BLOCKED: Missing command: node` en Ubuntu. Era una dependencia innecesaria del procedimiento npx, no un fallo del contenedor. Retirada del preflight y reemplazado npx por CLI nativa en esta guia. No instalar Node para resolverlo; publicar/descargar la correccion y repetir preflight.

Verificacion dirigida de la correccion: Bash -n y cuatro casos simulados PASS. Se acepta host sin Node/npm/npx/CLI todavia; se conservan bloqueos por Docker inaccesible, Caddy ausente y puertos ocupados. No equivale a un preflight real PASS en Ubuntu; ese resultado sigue pendiente.

Revisar RAM/disco disponibles considerando Guardian y las otras aplicaciones. Si falta capacidad, no iniciar el stack. Un PASS de preflight no demuestra capacidad bajo carga. No hay evidencia de recursos del servidor en esta sesion.

## 2. Iniciar Supabase Local

CLI nativa fijada en 2.121.0, release oficial verificada el 2026-10-17. No requiere Node/npm, supabase login/link ni cuenta cloud. El checkout ya contiene config.toml: NO ejecutar init --force.

Solo despues de revisar el preflight: si `supabase --version` ya devuelve 2.121.0, omitir instalacion. Si hay otra version, revisar antes de reemplazarla. Para primera instalacion Ubuntu amd64/arm64, descargar el paquete oficial y comprobar SHA256 antes de instalar. Requiere curl, dpkg, awk y sha256sum; ejecutar cada bloque solo si el anterior termino bien. Como root, se puede omitir sudo.

```bash
(
  set -euo pipefail
  arch=$(dpkg --print-architecture)
  case "$arch" in amd64|arm64) ;; *) echo "Arquitectura no contemplada: $arch"; exit 1 ;; esac
  download_dir=$(mktemp -d)
  cd "$download_dir"
  file="supabase_2.121.0_linux_${arch}.deb"
  release="https://github.com/supabase/cli/releases/download/v2.121.0"
  curl -fL "$release/$file" -o "$file"
  curl -fL "$release/checksums.txt" -o checksums.txt
  awk -v file="$file" '$2 == file { print; found=1 } END { if (!found) exit 1 }' checksums.txt | sha256sum -c -
  sudo dpkg -i "./$file"
  supabase --version
)
```

La CLI orquesta los contenedores; no instala PostgreSQL ni Node como servicios del host. No ejecutar instalacion/arranque mientras el preflight tenga bloqueos sin revisar.

Crear esta red solamente si no existe; si existe, preflight debe haber comprobado la opcion de loopback:

```bash
docker network inspect anubis-supabase-lab >/dev/null 2>&1 || docker network create --driver bridge -o com.docker.network.bridge.host_binding_ipv4=127.0.0.1 anubis-supabase-lab
supabase start --network-id anubis-supabase-lab
bash deploy/local/verify-bindings.sh
```

start puede mostrar claves: NO pegar su salida completa en chat, no usar --debug ni grabarla en Git/docs. Si la comprobacion de bindings falla, detener SOLO este laboratorio con `supabase stop`, sin --all ni --no-backup, y revisar antes de seguir. UFW por si solo no sustituye comprobar puertos publicados por Docker.

Aplicar/comprobar migraciones contra LOCAL, nunca resetear ni enlazar remoto:

```bash
supabase migration up --local
supabase migration list --local
docker ps --filter network=anubis-supabase-lab --format 'table {{.Names}}\t{{.Ports}}'
```

Debe constar el conjunto de seis migraciones del repo. Si falla una migracion, detenerse y compartir solo el error sanitizado; no editar tablas manualmente ni ejecutar db reset. El primer start puede aplicar las migraciones al inicializar; migration up solo aplica pendientes.

## 3. Clave Local Y CA Existente

Consultar `supabase status` solo en la terminal privada. Tomar Publishable key (o legacy anon si corresponde), NUNCA Secret ni service_role.
Identificar en docker ps el gateway de API y su puerto INTERNO. Un ejemplo historico es supabase_kong_anubis:8000; usar el nombre/puerto realmente observados, no el puerto publicado 54321 ni localhost.

```bash
umask 077
test -f .env.lab || cp deploy/local/lab.env.example .env.lab
chmod 600 .env.lab
nano .env.lab
```

Completar ANUBIS_LAB_PUBLISHABLE_KEY y ANUBIS_LAB_API_UPSTREAM. .env original permanece intacto; las variables runtime del override prevalecen sobre las cloud. No copiar todas las variables de supabase status a .env.

Exportar SOLO el certificado publico de la CA de Caddy existente. Si root.crt ya existe, comparar huella con la CA vigente antes de reutilizarlo; no reemplazar una CA inesperada a ciegas.

```bash
mkdir -p deploy/local/certs
chmod 755 deploy/local/certs
test -f deploy/local/certs/root.crt || docker compose -f compose.yaml cp caddy:/data/caddy/pki/authorities/local/root.crt deploy/local/certs/root.crt
chmod 644 deploy/local/certs/root.crt
openssl x509 -in deploy/local/certs/root.crt -noout -fingerprint -sha256
```

Nunca copiar root.key. El certificado se monta solo lectura, no entra en Git ni en la imagen. Los volumenes Caddy originales se conservan; no cambiar project name de Compose. La misma CA que ya confia Windows debe seguir emitiendo los certificados.

## 4. Validar Y Actualizar ANUBIS

Usar ambos Compose en todas las operaciones del laboratorio. Definir helper en esta terminal:

```bash
lab() { docker compose --env-file .env.lab -f compose.yaml -f compose.lab.yaml "$@"; }
lab config --quiet
lab run --rm --no-deps caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
```

No ejecutar config sin --quiet ni imprimir env: contienen la clave. Verificar que 443 sigue perteneciendo a ANUBIS; preflight lista propietarios. Conservar imagen anterior antes del build:

```bash
previous_image=$(docker compose -f compose.yaml images -q anubis-web)
docker image tag "$previous_image" "anubis-web:pre-lab-$(date +%Y%m%d%H%M%S)"
lab build anubis-web
lab up -d --no-deps caddy
lab up -d --no-deps anubis-web
lab ps
bash deploy/local/verify-bindings.sh
```

Ejecutar cada comando solo si el anterior tuvo exito. Caddy requiere recarga/recreacion para incorporar el listener interno; no apagar Guardian. Validar backend desde Next.js con TLS y clave local, sin imprimir respuestas sensibles:

```bash
lab exec -T anubis-web node -e 'fetch(process.env.SUPABASE_URL+"/auth/v1/health",{headers:{apikey:process.env.SUPABASE_PUBLISHABLE_KEY},signal:AbortSignal.timeout(10000)}).then(r=>{if(!r.ok)throw Error();console.log("PASS: Supabase Auth reachable over verified HTTPS")}).catch(()=>{console.error("FAIL: review internal DNS, CA, gateway and Auth");process.exit(1)})'
```

Un error TLS requiere corregir CA/nombre/ruta, no desactivar verificacion. Health es conectividad, no prueba login/RLS. Si falla el arranque, no resetear DB ni borrar volumenes. Para volver al montaje anterior, conservar .env original, retaggear la imagen anterior elegida a anubis-web:local y ejecutar `docker compose -f compose.yaml up -d --no-deps anubis-web caddy`; verificar salud/HTTPS. Esto no revierte migraciones ni borra datos del laboratorio.

## 5. Correo Y Navegador Desde Windows

Abrir un tunel SSH, usando el FQDN que ya resuelve al Ubuntu existente. Comprobar la huella SSH si se solicita; no desactivar host-key checking.

```powershell
ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:54323:127.0.0.1:54323 -L 127.0.0.1:54324:127.0.0.1:54324 nicolas@anubis.snti.local
```

Mantener esa terminal abierta. Si status indica puertos diferentes, ajustar solo el tunel. Studio: http://127.0.0.1:54323; correo de pruebas: http://127.0.0.1:54324. Estas herramientas dan acceso administrativo/correos de pruebas; nunca publicarlas. Revisar tokens en el navegador propio, sin capturas ni logs compartidos.

Entrar en https://anubis.snti.local/register, crear un usuario ficticio, abrir confirmacion desde correo local, crear organizacion y enrolar TOTP. Las plantillas versionadas llevan SiteURL/TokenHash directamente a /auth/confirm; no apuntan a localhost del PC. Probar recovery igualmente. No enviar ni documentar QR/secretos MFA.

Desde otra terminal PowerShell:

```powershell
curl.exe --ssl-revoke-best-effort https://anubis.snti.local/api/health
```

Esperado: {"status":"ok"}; no confirma DB/Auth. Probar tambien login/logout/refresh, OWNER SOLO, cliente/servicio/reporte, roles y aislamiento A/B mediante Data API. Movil requiere resolver FQDN y confiar en CA; no probarlo sobre una red ajena.

## Operacion Y Evidencia

- Registrar resultados reales en [LOCAL_LAB_VALIDATION](LOCAL_LAB_VALIDATION.md), nunca como hosted PASS.
- No ejecutar full gate todavia: primero preflight y primer arranque local. Pruebas dirigidas para cualquier defecto observado.
- No usar down -v, db reset, stop --no-backup, prune ni borrar volumenes. Parada temporal: supabase stop, sin flags destructivos; mantener el checkout/project_id estable.
- Tras reiniciar Ubuntu, comprobar servicios. No se instala systemd/autostart del laboratorio ni se promete recuperacion automatica; iniciar con la misma CLI/red si hace falta.
- Para cambios de config/templates, parar/iniciar solo el stack local conservando datos, misma version CLI/red, y volver a verificar bindings. Guardar backup antes de upgrades.
- Supabase cloud no alojara automaticamente la aplicacion Next.js. Migraciones/configuracion y datos requieren un plan separado; este laboratorio no mueve datos a cloud.

## Fuentes

[CLI nativa Linux](https://github.com/supabase/cli#install-the-cli), [release fijada 2.121.0](https://github.com/supabase/cli/releases/tag/v2.121.0).

[Supabase local y binding loopback](https://supabase.com/docs/guides/local-development), [CLI y migraciones](https://supabase.com/docs/reference/cli/supabase-migration-up), [plantillas locales](https://supabase.com/docs/guides/local-development/customizing-email-templates), [Caddy import](https://caddyserver.com/docs/caddyfile/directives/import), [Node CA adicional](https://nodejs.org/api/cli.html#node_extra_ca_certsfile).
