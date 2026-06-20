# AGENTS.md — Barbería Triada (plantilla)

> Estándar **Vibe Engineering** de Tríada. Este archivo es canónico y vive en la
> **raíz** del repo. Léelo antes de tocar el código. Objetivo: que cualquier
> agente (o persona) trabaje con **criterio de ingeniería**, no a tientas
> (anti vibe-coding).

## Qué es

Plantilla de **plataforma para barbería** (producto try-before-buy de Tríada).
Showcase navegable con 5 superficies: Hub, Sitio web, Reservas, Cursos y CRM,
envuelto en un riel para cambiar dispositivo / paleta / tema / íconos.

Origen del diseño: prototipo de **Claude Design** ("Barberia Triada.dc.html"),
reimplementado a **vanilla** (sin el runtime de Design Code).

## Stack y principios

- **Vanilla JS + CSS, sin build ni dependencias.** Scripts **clásicos** (no ES
  modules) a propósito: el `index.html` abre por doble clic y también sirve en
  Vercel. No introducir un bundler ni `type="module"` sin una razón fuerte.
- **Reactividad mínima propia:** `estado → render (string HTML) → bind
  (delegación de eventos)`. Un solo `setState` re-renderiza `#app`; el foco y el
  scroll se preservan a mano (ver `App.render`).
- **Foundation Kit como base.** La marca vive en `assets/css/brand.css`
  (pilar Marca) y la seguridad en `supabase/` + el patrón anti-XSS (pilar
  Seguridad). No dupliques tokens: el default de marca sale del kit.

## Reglas al editar

1. **Texto de usuario SIEMPRE escapado.** Todo dato dinámico pasa por `esc()`
   (`app.js`). Nunca interpolar datos crudos en `innerHTML`. Para handlers usar
   `data-act` / `data-arg` + delegación — **nunca** `onclick="..."` inline con
   datos.
2. **Estilos:** el diseño usa estilos inline (vienen del prototipo). Si agregas
   componentes nuevos, prefiere las clases del kit (`.btn`, `.card`, `.input`…)
   en `components.css`.
3. **Colores/temas:** usar las variables del showcase (`--accent`, `--app-bg`,
   `--surface`, `--ink`, `--txt*`, `--border*`…). No hardcodear hex salvo en
   `data.js` (paletas/temas) o `brand.css`.
4. **Datos de demo:** viven en `data.js`. En producción se reemplazan por
   Supabase (`supabase/02_barberia.sql`). No mezclar lógica de negocio real en
   el render.
5. **Verifica lo que tocas.** Sirve la página (`npx serve .`) y revisa consola
   (0 errores) + las 5 superficies antes de dar algo por "funciona".

## Cómo correr

```bash
npx serve .        # luego abrir http://localhost:3000
# o simplemente abrir index.html
```

## Archivos clave

- `assets/js/app.js` — estado, helpers (`esc`, `clp`, `compute`), CSS vars.
- `assets/js/app.render.js` — riel + Hub + Sitio web + Reservas.
- `assets/js/app.render2.js` — Cursos + CRM + overlays + `mount`/`bind`/acciones.
- `assets/js/data.js` — catálogo, cartera, finanzas, `SHOP`.
- `assets/js/image-slot.js` — `<image-slot>` (drag&drop, localStorage).
- `assets/css/brand.css` — **único** archivo de re-skin por cliente.
