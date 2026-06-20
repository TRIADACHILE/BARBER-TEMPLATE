-- ============================================================
-- BARBERÍA TRIADA · Esquema de negocio (backend-ready)
-- Pilar SEGURIDAD del Foundation Kit aplicado a la barbería.
--
-- Requiere correr ANTES: 01_core.sql  (orgs, auth_org_id(), set_org_id(),
-- audit_row(), is_admin(), etc.)
--
-- Cada tabla elige UNA receta del kit según cómo se accede:
--   servicios       → PERFIL B (lectura pública: el sitio web los muestra sin login)
--   citas           → PERFIL C (el visitante reserva anónimo; Matías gestiona con login)
--   inscripciones   → PERFIL C (el alumno se inscribe anónimo; Matías gestiona)
--   clientes        → PERFIL A (cartera privada del CRM)
--   gastos          → PERFIL A (finanzas privadas del CRM)
--
-- ⚠️ TODA tabla en `public` DEBE tener RLS. Sin RLS queda abierta vía PostgREST.
-- ============================================================


-- ╔══════════════════════════════════════════════════════════╗
-- ║  servicios — PERFIL B (lectura pública, escritura privada) ║
-- ╚══════════════════════════════════════════════════════════╝
create table if not exists servicios (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  descripcion text,
  duracion    text,                 -- '30 min', '45 min'
  precio      integer not null,     -- CLP, entero
  orden       integer not null default 0,
  publicado   boolean not null default true,
  org_id      uuid references orgs(id),
  created_at  timestamptz not null default now()
);
alter table servicios enable row level security;

drop trigger if exists trg_servicios_org on servicios;
create trigger trg_servicios_org before insert on servicios
  for each row execute function set_org_id();

drop policy if exists servicios_public_read on servicios;
create policy servicios_public_read on servicios for select to anon, authenticated
  using (publicado = true);

drop policy if exists servicios_owner_write on servicios;
create policy servicios_owner_write on servicios for all to authenticated
  using (org_id = auth_org_id()) with check (org_id = auth_org_id());


-- ╔══════════════════════════════════════════════════════════╗
-- ║  clientes — PERFIL A (cartera privada del CRM)            ║
-- ╚══════════════════════════════════════════════════════════╝
create table if not exists clientes (
  id            uuid primary key default gen_random_uuid(),
  nombre        text not null,
  telefono      text,
  servicio_fav  text,
  notas         text,
  org_id        uuid references orgs(id),
  created_at    timestamptz not null default now()
);
alter table clientes enable row level security;

drop trigger if exists trg_clientes_org on clientes;
create trigger trg_clientes_org before insert on clientes
  for each row execute function set_org_id();

drop policy if exists clientes_org on clientes;
create policy clientes_org on clientes for all to authenticated
  using (org_id = auth_org_id()) with check (org_id = auth_org_id());

drop trigger if exists trg_clientes_audit on clientes;
create trigger trg_clientes_audit after insert or update or delete on clientes
  for each row execute function audit_row();


-- ╔══════════════════════════════════════════════════════════╗
-- ║  citas — PERFIL C (reserva anónima + gestión del dueño)   ║
-- ║  El sitio inserta la reserva sin login; Matías la ve/edita.║
-- ╚══════════════════════════════════════════════════════════╝
create table if not exists citas (
  id            uuid primary key default gen_random_uuid(),
  cliente_id    uuid references clientes(id),     -- null si reserva web anónima
  cliente_nombre text not null,                    -- nombre tal cual lo dejó el visitante
  telefono      text,
  servicio_id   uuid references servicios(id),
  servicio_nombre text,
  fecha         date not null,
  hora          text not null,                     -- '18:00'
  estado        text not null default 'pendiente', -- pendiente|confirmada|cancelada|atendida
  foto_url      text,                              -- historial visual del corte (CRM)
  org_id        uuid references orgs(id),
  created_at    timestamptz not null default now()
);
alter table citas enable row level security;

drop trigger if exists trg_citas_org on citas;
create trigger trg_citas_org before insert on citas
  for each row execute function set_org_id();

-- INSERT ANÓNIMO: el sitio público puede crear la reserva…
drop policy if exists citas_anon_insert on citas;
create policy citas_anon_insert on citas for insert to anon, authenticated
  with check (true);

-- …pero el público NO puede leer la agenda. Solo Matías (login) la gestiona:
drop policy if exists citas_owner_read on citas;
create policy citas_owner_read on citas for select to authenticated
  using (org_id = auth_org_id());
drop policy if exists citas_owner_manage on citas;
create policy citas_owner_manage on citas for update to authenticated
  using (org_id = auth_org_id()) with check (org_id = auth_org_id());
drop policy if exists citas_owner_delete on citas;
create policy citas_owner_delete on citas for delete to authenticated
  using (org_id = auth_org_id() and is_admin());


-- ╔══════════════════════════════════════════════════════════╗
-- ║  inscripciones — PERFIL C (inscripción anónima al curso)  ║
-- ╚══════════════════════════════════════════════════════════╝
create table if not exists inscripciones (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  email       text not null,
  plan        text not null default 'contado',  -- contado|cuotas
  estado      text not null default 'pendiente',
  org_id      uuid references orgs(id),
  created_at  timestamptz not null default now()
);
alter table inscripciones enable row level security;

drop trigger if exists trg_inscripciones_org on inscripciones;
create trigger trg_inscripciones_org before insert on inscripciones
  for each row execute function set_org_id();

drop policy if exists inscripciones_anon_insert on inscripciones;
create policy inscripciones_anon_insert on inscripciones for insert to anon, authenticated
  with check (true);
drop policy if exists inscripciones_owner_read on inscripciones;
create policy inscripciones_owner_read on inscripciones for select to authenticated
  using (org_id = auth_org_id());
drop policy if exists inscripciones_owner_manage on inscripciones;
create policy inscripciones_owner_manage on inscripciones for update to authenticated
  using (org_id = auth_org_id()) with check (org_id = auth_org_id());


-- ╔══════════════════════════════════════════════════════════╗
-- ║  gastos — PERFIL A (finanzas privadas del CRM)            ║
-- ╚══════════════════════════════════════════════════════════╝
create table if not exists gastos (
  id          uuid primary key default gen_random_uuid(),
  concepto    text not null,
  monto       integer not null,    -- CLP
  periodo     date not null default date_trunc('month', now()),
  org_id      uuid references orgs(id),
  created_at  timestamptz not null default now()
);
alter table gastos enable row level security;

drop trigger if exists trg_gastos_org on gastos;
create trigger trg_gastos_org before insert on gastos
  for each row execute function set_org_id();

drop policy if exists gastos_org on gastos;
create policy gastos_org on gastos for all to authenticated
  using (org_id = auth_org_id()) with check (org_id = auth_org_id());


-- ⚠️ PRODUCCIÓN: el insert anónimo (citas, inscripciones) NO tiene rate-limit
-- nativo. Antes de publicar, agregá CAPTCHA (hCaptcha/Turnstile) en los
-- formularios o un throttle por IP en una Edge Function. Sin eso, son spameables.
