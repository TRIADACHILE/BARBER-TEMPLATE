# SECURITY.md — Barbería Triada (plantilla)

> Estándar **Vibe Engineering** de Tríada · Pilar **Seguridad** del Foundation
> Kit. Canónico y en la **raíz** del repo. Describe qué está cubierto, qué NO, y
> qué falta antes de poner esto en producción con datos reales.

## Estado actual

Hoy es una **demo front-only**: sin backend, sin login, sin datos reales. Los
datos viven en `assets/js/data.js` y las fotos en `localStorage` del navegador.
En este estado **no hay superficie de ataque de servidor** — el riesgo es solo
de presentación (XSS al renderizar texto).

## Lo que YA está cubierto

- **Anti-XSS en el front.** Todo texto dinámico se renderiza con `esc()`
  (escapa `& < > " '`, incl. la comilla simple). Patrón tomado del kit
  (`supabase/security.reference.js`). Los handlers usan `data-act` + delegación,
  nunca `onclick="..."` con datos del usuario.
- **Backend listo y seguro por diseño** (cuando se conecte): `supabase/01_core.sql`
  + `supabase/02_barberia.sql` traen **RLS obligatoria** en cada tabla, con un
  perfil de acceso por caso de uso:
  - `servicios` → **lectura pública**, escritura solo del dueño (Perfil B).
  - `citas`, `inscripciones` → **insert anónimo** desde el sitio, lectura/gestión
    solo del dueño autenticado (Perfil C).
  - `clientes`, `gastos` → **privadas** del CRM, multi-tenant por `org_id`
    (Perfil A) + auditoría inmutable en `clientes`.
  - `org_id` lo estampa el servidor (`set_org_id()`), el front nunca lo manda.

## Lo que NO está cubierto (pendiente para producción)

1. **Autenticación.** El panel de Matías (CRM) hoy es abierto en la demo. En
   producción va detrás de **Supabase Auth**; las políticas RLS ya exigen
   `authenticated` para leer la cartera/agenda/finanzas.
2. **Rate-limit / CAPTCHA en formularios públicos.** El insert anónimo de
   `citas` e `inscripciones` **no tiene throttle nativo** → es spameable. Antes
   de publicar: hCaptcha/Turnstile en los formularios o una Edge Function con
   límite por IP. (Anotado también en `02_barberia.sql`.)
3. **Versión pineada de Supabase JS.** Usar la versión EXACTA (no el major
   flotante `@2`) como muestra `security.reference.js`.
4. **CSP.** Agregar Content-Security-Policy al servir en producción.

## Checklist antes de conectar datos reales

- [ ] Correr `01_core.sql` y `02_barberia.sql` en el proyecto Supabase.
- [ ] Confirmar que **todas** las tablas tienen `enable row level security`.
- [ ] Activar Supabase Auth para el CRM.
- [ ] CAPTCHA/rate-limit en reservas e inscripción.
- [ ] anon key pública pero RLS verificada (la seguridad la da la RLS, no ocultar la key).
- [ ] CSP + HTTPS en el hosting.

## Reportar un problema

Escribir a Tríada. No abras un issue público con detalles de una vulnerabilidad.
