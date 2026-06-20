# Barbería Triada · Plantilla de plataforma

Plataforma integral para una barbería, hecha por **Tríada**. Es una de las
**plantillas de producto** (try-before-buy): el cliente la prueba en vivo y,
si le gusta, se conecta a su backend real.

Reúne **4 productos conectados** en una sola demo navegable:

| Producto | Qué es |
|---|---|
| **Sitio web** | Landing pública: servicios, precios, trayectoria, ubicación y CTA de reserva. |
| **Reservas** | Flujo de 4 pasos (servicio → día → hora → datos) que termina en una confirmación por WhatsApp. La firma: **trIA** acompaña cada paso. |
| **Cursos** | Landing de la escuela presencial + inscripción con plan de pago. |
| **CRM** | Panel de Matías: resumen con KPIs, agenda, cartera de clientes (con **historial visual** de cortes), finanzas y análisis de **trIA**. |

Todo envuelto en un **showcase**: un riel de control para cambiar **dispositivo**
(móvil / notebook), **color de acento** (8 paletas), **fondo / tema** (5) y
**estilo de íconos** — pensado para que el cliente "se vea" en el producto.

---

## Cómo verla

Es 100% estática (HTML + CSS + JS vanilla, sin build ni dependencias).

- **Local:** abre `index.html` con doble clic, **o** sirve la carpeta:
  ```bash
  npx serve .
  ```
- **Deploy (recomendado para compartir):** Vercel / Netlify / GitHub Pages →
  apuntar a la raíz del repo. No requiere configuración.

> Las fotos que arrastres a los espacios de imagen se guardan en el navegador
> (localStorage), así la demo "queda armada" para quien la abra en ese equipo.

---

## Cómo personalizarla (re-skin)

El sistema está construido sobre el **Foundation Kit de Tríada** (2 pilares: Marca
y Seguridad). Para adaptarla a otro cliente tocas **muy pocos archivos**:

1. **Marca** → `assets/css/brand.css`
   Único archivo de "piel": color primario, navy, los 3 trazos del logo y las
   fuentes. El resto del sistema (`theme.css`, `components.css`) **no se toca**.
2. **Contenido / datos** → `assets/js/data.js`
   Catálogo de servicios (`SERV`), cartera de clientes (`CLI`), finanzas y, en
   `SHOP`, el nombre, WhatsApp, dominio, dirección y precios del curso.
3. **Logo / nombre** → el símbolo de 3 chevrons y el wordmark "Tríada·" viven en
   `app.js` (`logoFull`) y se pueden cambiar por la marca del cliente.

> El riel de paletas/temas es solo para la **demo**. En el producto final se fija
> una sola paleta (la del cliente) y se quita el riel.

---

## Estructura

```
BARBER-TEMPLATE/
├── index.html                 # entrada
├── assets/
│   ├── css/
│   │   ├── theme.css           # Foundation Kit · sistema (no editar)
│   │   ├── brand.css           # Foundation Kit · MARCA  ← re-skin acá
│   │   ├── components.css      # Foundation Kit · componentes base
│   │   └── app.css             # chrome del showcase + puente al kit
│   ├── js/
│   │   ├── data.js             # datos de demo (→ Supabase en producción)
│   │   ├── image-slot.js       # <image-slot> drag&drop (localStorage)
│   │   ├── app.js              # lógica + helpers (esc, compute)
│   │   ├── app.render.js       # render: riel, hub, web, reservas
│   │   └── app.render2.js      # render: cursos, CRM, overlays + mount
│   └── img/                    # fotos del cliente (opcional)
├── supabase/                   # Pilar SEGURIDAD (backend-ready)
│   ├── 01_core.sql             # core del kit (orgs, RLS, auditoría)
│   ├── 02_barberia.sql         # tablas de la barbería + RLS por perfil
│   └── security.reference.js   # cliente Supabase + anti-XSS (referencia)
├── AGENTS.md                   # estándar de ingeniería (anti vibe-coding)
└── SECURITY.md                 # postura de seguridad y qué falta para prod
```

---

## De demo a producción

Hoy el front funciona con datos de ejemplo. Para conectarlo a un backend real:

1. Crear proyecto en **Supabase** y correr `supabase/01_core.sql` y luego
   `supabase/02_barberia.sql` (definen tablas + **RLS** por perfil: catálogo
   público, reservas anónimas, CRM privado).
2. Copiar `supabase/security.reference.js` a `assets/js/`, poner la URL y la
   anon key, y reemplazar las lecturas de `data.js` por consultas a Supabase.
3. Habilitar **Auth** para el panel de Matías y agregar **CAPTCHA / rate-limit**
   en los formularios públicos (reservas, inscripción) antes de publicar.

Ver `SECURITY.md` para el detalle de lo que ya está cubierto y lo que falta.

---

Hecho por **Tríada** · una marca, muchos productos.
