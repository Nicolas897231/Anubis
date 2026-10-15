# S&N TI — Conversación Maestra: Micro Apps y ANUBIS

**Proyecto:** S&N TI Soluciones Digitales  
**Producto principal definido en esta conversación:** **ANUBIS**  
**Fecha de consolidación:** 12 de octubre de 2026  
**Estado:** Diseño funcional, comercial, técnico, legal y de seguridad previo al desarrollo

---

# 1. Objetivo de la conversación

La conversación comenzó con el objetivo de entender:

- Qué son las **micro apps**.
- Cómo pueden aplicarse a **S&N TI Soluciones Digitales**.
- Cómo construirlas siendo principiante con apoyo de **vibe coding**.
- Cómo convertirlas en productos vendibles.
- Cómo generar ingresos mediante:
  - implementación;
  - suscripción;
  - personalizaciones;
  - integraciones;
  - automatización;
  - servicios adicionales de S&N TI.
- Cómo identificar oportunidades de micro apps rentables para Colombia y Latinoamérica.

La conclusión estratégica fue que S&N TI no debería comenzar intentando desarrollar un gran ERP o una plataforma enorme, sino construir **micro apps B2B verticales** que solucionen dolores concretos y repetitivos.

---

# 2. Qué entendemos por Micro App

Una **micro app** es una aplicación pequeña que resuelve un problema muy específico.

Ejemplo:

En lugar de:

> “Administramos toda tu empresa.”

una micro app puede decir:

> “Permito que un técnico documente una visita con fotos, firma y descripción, y genere un informe profesional en PDF antes de salir del cliente.”

Cuando una micro app se ofrece como servicio recurrente mediante suscripción, se convierte en un modelo tipo:

## Micro SaaS

Características buscadas:

- problema específico;
- nicho concreto;
- producto sencillo;
- bajo costo operativo;
- posibilidad de cobrar mensualmente;
- desarrollo y soporte manejables por un equipo pequeño;
- facilidad para probar rápidamente si alguien pagaría.

---

# 3. Estrategia de S&N TI con Micro Apps

La estrategia acordada fue:

```text
PROBLEMA PEQUEÑO
        +
OCURRE FRECUENTEMENTE
        +
ACTUALMENTE SE RESUELVE MANUALMENTE
        +
LE CUESTA TIEMPO O DINERO A UNA EMPRESA
        +
PODEMOS AUTOMATIZAR GRAN PARTE
        =
CANDIDATO A MICRO APP
```

Luego:

```text
MICRO APP
+
NICHO ESPECÍFICO
+
COBRO RECURRENTE
=
MICRO SaaS
```

Se identificó como señal de oportunidad cuando una empresa dice cosas como:

- “Eso lo llevo en Excel.”
- “Lo hacemos por WhatsApp.”
- “Lo hace mi secretaria.”
- “Hay que revisarlo manualmente.”
- “A veces se nos olvida.”
- “Perdemos clientes por eso.”
- “Hay que copiarlo de un sistema a otro.”

---

# 4. Modelo de monetización general

Se propuso no depender únicamente de una mensualidad.

Modelo preferido:

## Implementación + Suscripción

Ejemplo:

- Configuración inicial:
  - COP $150.000 a $400.000 o más según tamaño.
- Suscripción mensual:
  - planes según cantidad de usuarios/licencias y funcionalidades.

Posibles ingresos adicionales:

- personalización;
- importación inicial de datos;
- diseño de plantillas;
- integraciones;
- automatización;
- API;
- desarrollo a medida;
- capacitación;
- soporte premium;
- servicios de infraestructura y ciberseguridad de S&N TI.

La micro app también funcionará como puerta de entrada para proyectos más grandes de S&N TI.

---

# 5. Ideas de Micro Apps priorizadas

Se creó un Excel con **15 ideas de alto potencial** para S&N TI.

Las principales incluyen:

1. **S&N Acta / ReporteExpress**  
   Fotos + texto/voz + firma → informe técnico PDF.

2. **CotizaVoz**  
   Voz → cotización profesional → PDF/WhatsApp.

3. **GarantíaActiva**  
   Seguimiento de garantías, mantenimientos y recompra.

4. **ReciboTaller**  
   Recepción de equipos con fotos, estado, accesorios y firma.

5. **CertificaServicio**  
   Certificados de servicios periódicos + próxima renovación.

6. **MantenimientoQR**  
   QR por activo con historial de mantenimiento.

7. **EntregaOK**  
   Evidencia de entrega, estado, seriales y firma.

8. **VisitaInmueble**  
   Actas de entrega/recibo de inmuebles con fotos.

9. **Checklist Campo**  
   Checklists configurables para inspecciones.

10. **RenuevaCliente**  
    Seguimiento de contratos, servicios y renovaciones.

11. **CobroRuta**  
    Registro de abonos y cobros en ruta.

12. **PedidoRuta**  
    Pedidos desde celular para vendedores externos.

13. **ObraAvance**  
    Reporte visual de avances de obra.

14. **AlquilaControl**  
    Entrega/devolución de equipos alquilados.

15. **SigueCotización**  
    Seguimiento simple de cotizaciones sin convertirse en CRM completo.

Archivo creado:

**SN_TI_MicroApps_y_ReporteExpress.xlsx**

---

# 6. Primera Micro App escogida

La idea seleccionada para profundizar fue inicialmente:

## S&N Acta / ReporteExpress

Problema:

Los técnicos realizan trabajos y luego:

- toman fotos;
- escriben por WhatsApp;
- hacen informes en Word;
- buscan firmas;
- envían PDF;
- pierden evidencia;
- dejan el informe para después;
- no hay trazabilidad centralizada.

La aplicación debía permitir:

```text
SERVICIO
  ↓
EVIDENCIA
  ↓
FIRMA
  ↓
INFORME
  ↓
CLIENTE
```

---

# 7. Casos de uso contemplados

La aplicación debe servir para:

- técnico independiente;
- emprendimiento de una sola persona;
- tienda con uno o varios técnicos;
- microempresa;
- pyme;
- empresa con varios equipos;
- empresa multi-sede en una fase futura.

Sectores contemplados:

- CCTV;
- alarmas;
- soporte TI;
- redes;
- aire acondicionado;
- electricidad;
- paneles solares;
- mantenimiento industrial;
- fumigación;
- electrodomésticos;
- talleres;
- instalaciones;
- servicios locativos;
- otros servicios técnicos.

---

# 8. Decisión fundamental: una sola aplicación Multi-Tenant

No se desarrollarán versiones separadas para:

- independientes;
- tiendas;
- empresas.

Se construirá:

## Una sola aplicación SaaS multi-tenant

Cada cliente será una:

## Organización

Ejemplo:

```text
Organización: Carlos Servicios Técnicos
Usuarios: 1
```

o:

```text
Organización: TecnoPC Cali
Usuarios: 3
```

o:

```text
Organización: Seguridad XYZ SAS
Usuarios: 25
```

La misma arquitectura servirá para todos.

---

# 9. Organización, usuario, licencia y rol

Se decidió separar los siguientes conceptos:

| Concepto | Definición |
|---|---|
| Organización | Cliente de ANUBIS |
| Usuario | Persona con acceso |
| Licencia / Seat | Cupo disponible para un usuario activo |
| Rol | Permisos que tiene el usuario |
| Plan | Límites y funcionalidades contratadas |

---

# 10. Modelo de licencias

Las licencias serán:

## Por usuario activo / asiento

No por celular.

Ejemplo:

Plan de 10 licencias:

- 6 usuarios activos;
- 4 licencias disponibles.

Cuando un usuario se suspende:

- deja de consumir licencia;
- sus informes históricos se conservan.

La licencia pertenece a una persona activa.

---

# 11. Planes conceptuales

Se definieron cuatro niveles iniciales:

## Solo

- 1 usuario;
- pensado para técnico independiente.

## Negocio

- alrededor de 3 usuarios;
- owner/admin/técnicos;
- pensado para tiendas o microempresas.

## Equipo

- alrededor de 10 usuarios;
- admite supervisor;
- asignación de técnicos;
- dashboard más completo.

## Empresa

- cantidad personalizada;
- multi-sede futura;
- APIs;
- integraciones;
- soporte avanzado.

Los precios todavía son hipótesis a validar comercialmente.

---

# 12. Creación y administración de usuarios

Decisión:

## S&N NO creará manualmente cada usuario en la operación normal.

La empresa cliente administrará su propio equipo.

Flujo:

```text
ADMIN
  ↓
Mi equipo
  ↓
Invitar usuario
  ↓
Nombre
Correo
Rol
Supervisor
  ↓
Enviar invitación
```

El usuario recibe una invitación, crea su propia contraseña y acepta el acceso.

S&N puede ofrecer onboarding empresarial como servicio adicional.

---

# 13. No entregar contraseñas

No se usarán esquemas como:

```text
usuario: tecnico1
contraseña: Tecnico123
```

Cada persona tendrá:

- identidad individual;
- correo;
- contraseña propia;
- sesiones propias;
- historial de actividad.

El administrador no conocerá la contraseña de los técnicos.

---

# 14. Roles definidos

## Owner

Puede:

- gestionar la organización;
- usuarios;
- plan;
- facturación;
- configuración;
- clientes;
- servicios;
- informes;
- roles;
- supervisores.

---

## Administrador

Puede manejar:

- usuarios;
- clientes;
- servicios;
- técnicos;
- informes;
- operación.

No necesariamente puede:

- eliminar la organización;
- transferir propiedad.

---

## Supervisor

Puede manejar principalmente:

- técnicos asignados a su equipo;
- visitas;
- servicios;
- informes;
- pendientes;
- asignaciones.

No administra toda la organización.

---

## Técnico

Acceso limitado a:

- sus servicios;
- clientes relacionados;
- evidencias;
- informes;
- perfil.

No ve:

- facturación;
- plan;
- configuración global;
- otros equipos;
- administración empresarial.

---

# 15. S&N Super Admin

S&N tendrá un panel independiente para administración global.

Podrá ver:

```text
Organizaciones
Planes
Suscripciones
Usuarios totales
Licencias
Estado
Uso
Almacenamiento
Errores
Feature flags
Soporte
```

S&N administrará:

- plan;
- número máximo de licencias;
- estado de suscripción;
- bloqueos;
- límites;
- funcionalidades habilitadas;
- soporte;
- estado de plataforma.

---

# 16. Separación de responsabilidades

## S&N controla

- organizaciones;
- planes;
- límites de usuarios;
- estado de suscripción;
- feature flags;
- almacenamiento;
- soporte;
- estado de plataforma;
- infraestructura global.

## Cliente controla

- sus usuarios;
- roles;
- supervisores;
- clientes;
- servicios;
- asignaciones;
- informes;
- logo;
- configuración permitida.

---

# 17. Supervisores

El Admin/Owner podrá asignar técnicos a un supervisor.

Ejemplo:

```text
Pedro — Supervisor
  ├─ Juan
  ├─ Miguel
  ├─ Sebastián
  └─ Andrés
```

El supervisor podrá:

- revisar trabajos;
- asignar visitas;
- consultar informes;
- administrar su equipo.

No puede administrar técnicos ajenos a su ámbito.

---

# 18. Asignación de servicios

## Técnico independiente

El servicio se autoasigna.

```text
Técnico:
Carlos
```

## Empresa

Admin o Supervisor puede crear:

```text
Cliente
Fecha
Hora
Tipo de servicio
Técnico asignado
```

El técnico recibe el servicio.

---

# 19. Estados de usuario

Se definieron:

- Invitado
- Activo
- Suspendido
- Eliminado

Cuando una persona deja la empresa:

- se suspende;
- no puede entrar;
- libera la licencia;
- su historial permanece.

---

# 20. Usuarios y varias organizaciones

Arquitectónicamente se permitirá que una persona pertenezca a varias organizaciones.

Ejemplo:

```text
juan@email.com
    ↓
Membership A → Empresa A → Técnico
Membership B → Empresa B → Supervisor
```

Esto se manejará mediante:

## memberships

y no colocando simplemente `organization_id` directamente en la identidad.

---

# 21. Dispositivos y sesiones

La licencia será por persona, no por dispositivo.

Política inicial propuesta:

## Hasta 2 dispositivos/sesiones confiables por usuario

Ejemplo:

```text
Samsung A55
Chrome Windows
```

Si aparece un tercer dispositivo:

- se puede solicitar verificación;
- se puede cerrar una sesión previa;
- se puede alertar al usuario.

El Admin podrá consultar dispositivos y cerrar sesiones.

---

# 22. Auditoría

La arquitectura debe permitir registrar eventos como:

```text
Inicio de sesión
Inicio de servicio
Carga de fotografía
Cambio de estado
Cierre de servicio
Generación de informe
Cambio de usuario
Acceso de soporte
```

Los logs avanzados podrán convertirse en funcionalidad de planes superiores.

---

# 23. Pagos y suscripciones

Inicialmente no se necesita automatizar completamente el pago.

Puede funcionar mediante:

- transferencia;
- Nequi;
- Bre-B;
- facturación de S&N;
- activación manual del plan.

Luego se podrá integrar:

- Wompi;
- Mercado Pago;
- Stripe;
- otro proveedor.

---

# 24. Cuando se acaban las licencias

Ejemplo:

```text
Plan Equipo
10 / 10 usuarios
```

Al intentar invitar otro:

> Has utilizado todas tus licencias.

Opciones:

- Solicitar licencia.
- Cambiar plan.

Inicialmente esto puede generar una solicitud a S&N.

---

# 25. Importación masiva de usuarios

Para empresas grandes se contempla una fase posterior con:

- CSV;
- Excel;
- importación masiva.

Ejemplo:

```text
nombre,email,rol,supervisor
Juan,juan@email.com,tecnico,Pedro
Luis,luis@email.com,tecnico,Pedro
```

---

# 26. Nombre definitivo del producto

Se exploraron:

- Argos;
- Nodus;
- Eikon;
- Aster;
- Rastro;
- otros.

Se decidió finalmente:

# ANUBIS

Nombre oficial:

## ANUBIS

Concepto:

**Gestión inteligente de servicios en campo**

Marca:

**ANUBIS by S&N TI Soluciones Digitales**

Frase conceptual:

> **La evidencia de tu operación.**

---

# 27. Familia de productos S&N TI

La línea conceptual queda:

```text
S&N TI Soluciones Digitales

ÁMBAR
Gestión documental

GUARDIAN
Gestión de inventarios

ANUBIS
Gestión de servicios técnicos y operación en campo
```

---

# 28. Funcionalidad principal de ANUBIS

ANUBIS será una plataforma para:

- registrar clientes;
- crear servicios;
- asignarlos;
- realizar trabajos;
- documentar evidencia;
- capturar fotografías;
- registrar trabajo realizado;
- registrar hallazgos;
- registrar recomendaciones;
- obtener firma del cliente;
- generar PDF;
- compartir informe;
- mantener historial;
- consultar servicios;
- administrar equipos.

---

# 29. Flujo principal

```text
CLIENTE
  ↓
SERVICIO
  ↓
ASIGNACIÓN
  ↓
TÉCNICO
  ↓
TRABAJO
  ↓
EVIDENCIA
  ↓
FIRMA
  ↓
INFORME PDF
  ↓
COMPARTIR
  ↓
HISTORIAL
```

---

# 30. Importancia de la entidad Servicio

No se diseñará simplemente:

```text
Cliente → Informe
```

Se decidió:

```text
Cliente
  ↓
Servicio
  ↓
Informe
```

Esto permitirá después agregar:

- asignaciones;
- fechas;
- estados;
- rutas;
- garantías;
- mantenimientos;
- activos;
- SLA;
- historial.

---

# 31. Estados del servicio

Conceptualmente:

```text
Asignado
  ↓
En proceso
  ↓
Finalizado
  ↓
Informe generado
```

La definición exacta podrá ampliarse en el diseño de estados.

---

# 32. Arquitectura de ANUBIS

Arquitectura inicial recomendada:

## Frontend

- Next.js
- React
- Tailwind CSS
- PWA

## Backend

- Next.js server actions/API inicialmente;
- posible backend separado después.

## Base de datos

- PostgreSQL
- Supabase gestionado inicialmente.

## Autenticación

- Supabase Auth inicialmente.

## Storage

- Supabase Storage.

## Automatización

- n8n.

## PDFs

- React PDF / Puppeteer u otra solución compatible.

## IA futura

- Whisper / STT;
- LLM;
- opciones self-hosted según costos.

---

# 33. PWA

ANUBIS comenzará como:

## Progressive Web App

Ventajas:

- una sola base de código;
- Android;
- iPhone;
- tablet;
- Windows;
- macOS;
- acceso desde navegador;
- posibilidad de instalación en pantalla de inicio.

No se crearán inicialmente tres aplicaciones separadas.

---

# 34. Offline

Se contempla una evolución:

## Offline parcial / Offline-first donde tenga sentido

El técnico podrá en una fase posterior:

- abrir servicio;
- escribir;
- tomar fotos;
- firmar;
- guardar temporalmente.

Luego sincronizar cuando vuelva Internet.

No es requisito obligatorio del primer MVP.

---

# 35. Base de datos

Se decidió usar:

## Una sola base PostgreSQL multi-tenant

No una base separada por empresa inicialmente.

Las tablas deben llevar:

```text
organization_id
```

para separar datos.

---

# 36. Modelo de datos base

Entidades principales:

## organizations

Representa:

- empresa;
- técnico independiente;
- tienda;
- emprendimiento.

## profiles

Datos de la persona.

## memberships

Relaciona:

- usuario;
- organización;
- rol;
- estado;
- supervisor.

## clients

Clientes finales de cada organización.

## jobs / services

Servicios u órdenes.

## reports

Informes técnicos.

## evidence

Fotos y otros archivos.

## signatures

Firma y datos asociados.

## report_templates

Plantillas de informe.

## subscriptions

Plan, límites y estado.

---

# 37. Archivos

No se guardarán fotografías directamente como blobs pesados dentro de PostgreSQL.

Se manejará:

## PostgreSQL

- metadata;
- relaciones;
- información estructurada.

## Object Storage

- fotos;
- firmas;
- PDFs;
- archivos.

---

# 38. Seguridad Multi-Tenant

Se implementará aislamiento entre organizaciones mediante:

## Row Level Security (RLS)

La base de datos deberá impedir que una organización consulte datos de otra incluso si alguien intenta manipular manualmente una llamada.

Ejemplo:

```text
Usuario pertenece a organization_id = 32
↓
solo puede consultar datos de organization_id = 32
```

---

# 39. Feature Flags

Se contemplará una arquitectura con banderas de funcionalidad.

Ejemplo:

```text
voice_ai = false
offline_mode = false
advanced_dashboard = false
multi_branch = false
```

Un plan superior puede habilitar:

```text
voice_ai = true
advanced_dashboard = true
```

Misma aplicación, diferentes capacidades.

---

# 40. Funciones V1 / MVP

La primera versión comercial debe incluir:

1. Registro/login.
2. Organización.
3. Usuarios.
4. Roles.
5. Clientes.
6. Nuevo servicio.
7. Asignación de técnico.
8. Trabajo realizado.
9. Fotografías.
10. Hallazgos.
11. Recomendaciones.
12. Firma.
13. Generación de PDF.
14. Compartir informe.
15. Historial.
16. Administración básica.
17. Control de licencias.
18. Seguridad multi-tenant.

---

# 41. IA y voz

No bloquearán el lanzamiento inicial.

Fase posterior:

```text
Técnico habla
  ↓
Transcripción
  ↓
IA organiza
  ↓
Trabajo realizado
Hallazgos
Recomendaciones
```

El usuario podrá:

- aceptar;
- editar;
- corregir.

Nunca se asumirá que una salida de IA es necesariamente correcta.

---

# 42. Verticalización

ANUBIS podrá adaptar formularios según sector.

Ejemplo:

## CCTV

- cámaras;
- DVR/NVR;
- cableado;
- conectividad;
- grabación.

## Aire acondicionado

- marca;
- BTU;
- temperatura;
- filtros;
- condensador;
- presión.

Será la misma aplicación con plantillas/configuraciones distintas.

---

# 43. Expansión futura

ANUBIS puede evolucionar hacia:

```text
Cotización
   ↓
Servicio
   ↓
Informe
   ↓
Garantía
   ↓
Mantenimiento
   ↓
Nueva venta
```

Posibles módulos futuros:

- voz/IA;
- activos;
- QR;
- garantías;
- mantenimientos;
- multi-sede;
- APIs;
- integraciones;
- analítica avanzada.

---

# 44. Panel cliente

Dependiendo del rol podrá mostrar:

```text
Dashboard
Servicios
Clientes
Equipo
Informes
Plantillas
Administración
Plan
Configuración
```

El técnico tendrá interfaz reducida.

---

# 45. Panel S&N Super Admin

Debe ser independiente del panel normal.

Funciones:

- organizaciones;
- planes;
- licencias;
- suscripciones;
- consumo;
- almacenamiento;
- errores;
- soporte;
- feature flags;
- salud de plataforma.

---

# 46. Acceso de soporte S&N

S&N no deberá revisar información interna de los clientes libremente.

El Super Admin debe mostrar normalmente solo información administrativa.

Si se necesita soporte con datos:

- acceso temporal;
- motivo;
- ticket;
- usuario S&N;
- fecha/hora;
- auditoría.

---

# 47. Privacidad y protección de datos

ANUBIS debe diseñarse bajo el principio de:

## Minimización de datos

No recolectar información “por si acaso”.

Cada formulario debe indicar:

- qué dato solicita;
- por qué;
- si es obligatorio;
- cómo se usará.

No se recopilarán por defecto:

- contactos del teléfono;
- historial de llamadas;
- ubicación permanente;
- biometría;
- reconocimiento facial;
- cédula del cliente si no es necesaria;
- grabación permanente de micrófono;
- datos no vinculados al servicio.

---

# 48. Formularios

Los formularios deben incluir avisos claros.

Ejemplo para fotografías:

> Carga únicamente evidencia necesaria para documentar el servicio. Evita fotografiar personas, documentos o información privada que no sea necesaria.

Los campos deben pedir únicamente información necesaria.

---

# 49. Firma del cliente

La firma no debe significar automáticamente:

> “Estoy totalmente satisfecho.”

Debe diferenciarse entre:

- constancia de recepción;
- aceptación del servicio;
- satisfacción, si corresponde.

La aplicación debe evitar declaraciones engañosas.

---

# 50. Documentos legales requeridos

Se decidió preparar:

- Política de Tratamiento de Datos Personales y Privacidad.
- Términos y Condiciones.
- Política de reembolsos.
- Política de cancelación/retracto según aplique.
- Política de Cookies.
- Banner de consentimiento de cookies.
- Avisos cortos de privacidad para formularios.
- Consentimientos específicos cuando correspondan.

Estos documentos deberán revisarse jurídicamente antes de publicarse.

---

# 51. Cookies

Debe existir:

## Banner de consentimiento

No usar casillas premarcadas.

El usuario debe poder:

- aceptar;
- rechazar cuando corresponda;
- configurar preferencias.

Las cookies no esenciales no deberían activarse antes del consentimiento cuando legalmente se requiera.

---

# 52. Reseñas y testimonios

Política definida:

## Cero reseñas falsas

No se crearán testimonios inventados.

Si se muestra un caso ficticio:

debe marcarse claramente como:

- Demo;
- Ejemplo;
- Caso ficticio.

---

# 53. Afirmaciones comerciales

No se utilizarán afirmaciones absolutas como:

- “100% seguro”.
- “Imposible de hackear”.
- “Nunca se cae”.
- “La IA nunca falla”.
- “Ahorra 90% garantizado”.

Las afirmaciones deberán ser:

- verificables;
- sustentadas;
- medibles.

---

# 54. Accesibilidad

Objetivo:

## WCAG 2.2 AA

Requisitos:

- navegación completa por teclado;
- foco visible;
- sin keyboard traps;
- contraste adecuado;
- labels reales;
- instrucciones claras;
- errores accesibles;
- texto alternativo;
- iconos con nombres accesibles;
- zoom;
- reflow;
- compatibilidad con lector de pantalla;
- alternativa accesible a firma dibujada.

---

# 55. Seguridad

Se decidió que ANUBIS tendrá una postura de seguridad estricta.

Baseline:

## OWASP ASVS 5.0 Nivel 2

Controles contemplados:

- MFA;
- passkeys cuando sea viable;
- sesiones seguras;
- recuperación de cuenta segura;
- reautenticación;
- RLS;
- RBAC;
- aislamiento de tenants;
- protección IDOR;
- XSS;
- SQL Injection;
- CSRF;
- CORS;
- rate limiting;
- credential stuffing;
- storage privado;
- signed URLs;
- validación de archivos;
- escaneo de archivos;
- CSP;
- HSTS;
- secretos fuera del código;
- repositorio privado;
- CI/CD;
- SAST;
- SCA;
- secret scanning;
- DAST;
- SBOM;
- dependencias controladas;
- logs;
- alertas;
- auditoría;
- backups;
- restauración;
- respuesta a incidentes;
- pentesting.

---

# 56. MFA

MFA deberá ser obligatorio, al menos, para perfiles privilegiados:

- S&N Super Admin;
- Owner;
- Admin.

Para otros usuarios podrá evaluarse según riesgo y experiencia de uso.

---

# 57. Seguridad de archivos

Archivos privados:

- no públicos por defecto;
- URLs firmadas;
- control de organización;
- validación de tipo;
- validación de tamaño;
- nombre seguro;
- escaneo cuando corresponda.

---

# 58. Protección contra clonación

Se reconoció que ninguna aplicación web puede hacerse “imposible de clonar”.

La estrategia será:

- frontend sin secretos;
- lógica crítica en backend;
- APIs protegidas;
- autenticación;
- autorización;
- reglas de negocio privadas;
- repositorio privado;
- secretos fuera del cliente;
- marca;
- propiedad intelectual;
- registro de software;
- contratos.

---

# 59. Repositorios

Se recomienda:

- repositorio privado;
- protección de ramas;
- revisiones;
- escaneo de secretos;
- dependabot/actualizaciones;
- CI/CD controlado;
- ambientes separados.

---

# 60. Entornos

Idealmente:

```text
development
staging
production
```

Nunca probar directamente cambios riesgosos en producción.

---

# 61. Backups

Debe existir:

- backup de base de datos;
- backup/estrategia de storage;
- restauración probada;
- retención;
- RPO;
- RTO;
- procedimientos documentados.

---

# 62. Monitoreo

ANUBIS deberá contar con:

- monitoreo;
- health checks;
- alertas;
- errores;
- métricas;
- logs;
- disponibilidad;
- eventos críticos.

---

# 63. Protección de disponibilidad

Contemplar:

- rate limiting;
- WAF;
- protección DDoS;
- CDN cuando aplique;
- límites de consumo;
- colas para procesos pesados;
- generación de PDF controlada;
- subida de archivos restringida.

---

# 64. Incidentes

Debe existir procedimiento de:

- detección;
- clasificación;
- contención;
- recuperación;
- notificación;
- análisis posterior.

Los incidentes de seguridad deben quedar registrados.

---

# 65. Manuales

Se decidió preparar manuales de uso para:

- Owner;
- Administrador;
- Supervisor;
- Técnico;
- S&N Super Admin.

Deben documentar:

- ingreso;
- equipo;
- creación de servicios;
- asignación;
- evidencia;
- firma;
- PDF;
- usuarios;
- licencias;
- seguridad;
- soporte.

---

# 66. Documento maestro creado

Se generó:

## ANUBIS_Especificacion_Maestra_v1.0.docx

Contenido:

- requerimientos funcionales;
- arquitectura;
- multi-tenancy;
- licencias;
- roles;
- seguridad;
- privacidad;
- accesibilidad;
- cookies;
- legales;
- manuales;
- operación;
- roadmap.

El documento fue revisado visualmente y estructuralmente.

---

# 67. Decisiones congeladas antes del desarrollo

Hasta este punto se consideran decisiones base:

| Tema | Decisión |
|---|---|
| Nombre | ANUBIS |
| Empresa fabricante | S&N TI Soluciones Digitales |
| Arquitectura | Multi-tenant |
| Cliente | Organization |
| Licenciamiento | Por usuario activo / seat |
| Identidad | Una cuenta por persona |
| Relación usuario-organización | Membership |
| Roles | Owner / Admin / Supervisor / Técnico |
| Gestión de usuarios | Cliente mediante invitaciones |
| Creación masiva | CSV/Excel futura |
| Supervisor | Configurado por Admin/Owner |
| Asignaciones | Admin/Supervisor |
| Independiente | Autoasignación |
| Control de licencias | Automático |
| Dispositivos | Sesiones confiables limitadas |
| S&N | Super Admin separado |
| Pago inicial | Puede ser manual |
| Pago futuro | Pasarela |
| Históricos | Se conservan al retirar técnico |
| Seguridad | RLS + RBAC + ASVS |
| Datos | Minimización |
| Accesibilidad | WCAG 2.2 AA |
| App inicial | PWA |
| BD | PostgreSQL |
| Storage | Separado |
| IA | Fase posterior |
| Offline | Evolución posterior |
| Soporte S&N | Acceso excepcional auditado |

---

# 68. Flujo completo del producto

```text
EMPRESA / TÉCNICO SE REGISTRA
          ↓
CREA ORGANIZACIÓN
          ↓
SE CREA OWNER
          ↓
SE ASIGNA PLAN
          ↓
OWNER/ADMIN INVITA EQUIPO
          ↓
SE DEFINEN ROLES
          ↓
SE DEFINEN SUPERVISORES
          ↓
SE CREAN CLIENTES
          ↓
SE CREA SERVICIO
          ↓
SE ASIGNA TÉCNICO
          ↓
TÉCNICO RECIBE SERVICIO
          ↓
REALIZA TRABAJO
          ↓
FOTOS / EVIDENCIA
          ↓
TRABAJO REALIZADO
          ↓
HALLAZGOS
          ↓
RECOMENDACIONES
          ↓
FIRMA / CONSTANCIA
          ↓
PDF
          ↓
COMPARTIR
          ↓
HISTORIAL
```

---

# 69. Roadmap conceptual

## V0 — Demo

- prototipo;
- ejemplo de PDF;
- validación con clientes.

## V1 — MVP comercial

- autenticación;
- organización;
- usuarios;
- roles;
- clientes;
- servicios;
- asignación;
- evidencia;
- firma;
- PDF;
- compartir;
- licencias;
- administración.

## V1.5 — Operación

- supervisores;
- dashboard;
- auditoría;
- mejoras de equipo.

## V2 — IA

- voz;
- transcripción;
- estructura automática de informes.

## V3 — Automatización

- garantías;
- mantenimiento;
- recordatorios;
- recompra.

## V4 — Plataforma

- multi-sede;
- API;
- integraciones;
- plantillas sectoriales;
- verticales.

---

# 70. Lo que NO se debe hacer

No convertir ANUBIS en un ERP gigante desde V1.

No agregar inicialmente:

- contabilidad;
- nómina;
- facturación electrónica completa;
- inventario completo;
- compras;
- CRM genérico;
- rutas complejas;
- funciones que no han sido validadas.

La prioridad es:

> resolver perfectamente el flujo de servicio técnico y generar evidencia profesional.

---

# 71. Próximo gran paso recomendado

Antes de empezar a programar:

## Modelo técnico definitivo

Definir:

- ERD final;
- tablas;
- campos;
- índices;
- relaciones;
- constraints;
- estados;
- políticas RLS;
- permisos exactos por rol;
- endpoints;
- eventos de auditoría;
- sesiones;
- licencias;
- feature flags.

Después:

## Diseño de pantallas

Para:

- Owner;
- Admin;
- Supervisor;
- Técnico;
- S&N Super Admin.

Y luego:

## Vibe Coding del MVP

---

# 72. Archivos generados durante esta conversación

## Excel de Micro Apps

`SN_TI_MicroApps_y_ReporteExpress.xlsx`

Incluye:

- 15 ideas;
- ranking;
- matriz de evaluación;
- blueprint;
- arquitectura;
- datos;
- roadmap.

## Especificación maestra de ANUBIS

`ANUBIS_Especificacion_Maestra_v1.0.docx`

Incluye:

- requerimientos;
- funcionalidad;
- arquitectura;
- licenciamiento;
- usuarios;
- roles;
- seguridad;
- privacidad;
- accesibilidad;
- legal;
- operación;
- manuales.

---

# 73. Visión de ANUBIS

ANUBIS debe comenzar como una herramienta pequeña y clara:

> **La evidencia de tu operación.**

Pero su arquitectura permitirá evolucionar hacia una plataforma completa para empresas de servicios técnicos.

Visión futura:

```text
ANUBIS

Clientes
Servicios
Equipo
Evidencias
Informes
IA
Activos
QR
Garantías
Mantenimientos
Analítica
Integraciones
```

Sin construir todo desde el primer día.

---

# 74. Principio de desarrollo

El principio central acordado es:

> **El código debe obedecer la especificación; la especificación no debe improvisarse mientras se programa.**

Antes del desarrollo deben quedar definidos:

- negocio;
- usuario;
- organización;
- licencias;
- roles;
- seguridad;
- privacidad;
- arquitectura;
- flujo;
- datos;
- operación.

---

# 75. Estado actual

ANUBIS se encuentra en:

## Fase de definición avanzada previa al desarrollo

Ya están planteados:

- concepto;
- nombre;
- mercado;
- modelo SaaS;
- licencias;
- roles;
- multi-tenancy;
- arquitectura;
- seguridad;
- privacidad;
- accesibilidad;
- operación;
- roadmap.

Pendiente principal:

## Diseño técnico detallado de base de datos, RLS, permisos y pantallas.

---

# 76. Resumen ejecutivo

S&N TI decidió crear una nueva línea de Micro Apps.

El primer producto será:

# ANUBIS

**ANUBIS** será una plataforma SaaS multi-tenant para técnicos independientes, tiendas, microempresas y empresas con equipos técnicos.

Permitirá:

- administrar clientes;
- registrar servicios;
- asignar técnicos;
- capturar evidencias;
- tomar fotografías;
- registrar trabajo;
- hallazgos;
- recomendaciones;
- capturar firma;
- generar PDF;
- compartir informes;
- conservar trazabilidad.

Funcionará inicialmente como PWA.

Tendrá licenciamiento por usuario activo.

Los clientes administrarán sus propios usuarios.

S&N administrará planes, límites y plataforma.

La seguridad deberá estar integrada desde el inicio.

El producto deberá respetar principios de:

- privacidad;
- minimización de datos;
- consentimiento;
- accesibilidad;
- transparencia;
- seguridad;
- auditoría;
- disponibilidad.

ANUBIS se concibe como producto independiente:

> **ANUBIS by S&N TI Soluciones Digitales**

junto a:

- Ámbar;
- Guardian.

El desarrollo todavía no debe comenzar hasta cerrar:

- ERD;
- modelo de datos;
- RLS;
- permisos;
- estados;
- arquitectura final;
- pantallas.

---

**Fin del resumen maestro de la conversación.**
