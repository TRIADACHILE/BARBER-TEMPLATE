// ============================================================
// FOUNDATION KIT · Pilar SEGURIDAD · Helpers de FRONTEND
//
// Lo único que el frontend aporta a la seguridad: NUNCA renderizar datos
// crudos del usuario (anti-XSS) y conectar a Supabase con versión pineada.
// La defensa real vive en Postgres (RLS + triggers). Esto es la capa de
// presentación segura.
//
// Uso: copiá este archivo a /js de tu proyecto e importá lo que necesites.
// ============================================================

// ─── 1. Cliente Supabase (versión EXACTA pineada) ───────────
// ❌ '@supabase/supabase-js@2'      → major flotante: un publish roto te llega solo
// ✅ '@supabase/supabase-js@2.108.1' → versión fija; subís a mano tras leer changelog
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.108.1/+esm';

// Reemplazá por los valores de TU proyecto (Settings → API).
// La anon/publishable key es pública por diseño: la seguridad la da la RLS, no ocultarla.
const SUPABASE_URL      = 'https://TU_PROYECTO.supabase.co';
const SUPABASE_ANON_KEY = 'TU_PUBLISHABLE_KEY';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);


// ─── 2. Escape anti-XSS ─────────────────────────────────────
// Escapa TODO carácter peligroso, incluida la comilla simple (sin ella, un dato
// podía romper un string JS dentro de un atributo y ejecutar código).
export function escHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

// Tagged template que escapa TODA interpolación por defecto: imposible olvidarse.
// Para inyectar HTML confiable a propósito (íconos SVG internos) → envolver con raw().
export function html(strings, ...vals) {
  return strings.reduce((out, s, i) =>
    out + s + (i < vals.length
      ? (vals[i] && vals[i].__raw !== undefined ? vals[i].__raw : escHtml(vals[i]))
      : ''), '');
}
export function raw(s) { return { __raw: String(s ?? '') }; }

// ─── Ejemplos de uso ────────────────────────────────────────
//   el.innerHTML = html`<h2 class="plato">${item.nombre}</h2>`;   // escapado siempre
//   el.innerHTML = html`<span>${raw(iconoSVG('check'))}</span>`;   // SVG confiable
//
// ⚠️ escHtml solo es seguro en contexto de TEXTO o ATRIBUTO HTML.
//    NUNCA metas datos del usuario dentro de un onclick="..." inline.
//    Usá data-* + event delegation:
//       html`<button data-id="${item.id}">Editar</button>`
//       container.addEventListener('click', e => {
//         const id = e.target.closest('button')?.dataset.id; ...
//       });
