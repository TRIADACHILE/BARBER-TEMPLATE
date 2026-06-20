-- ============================================================
-- FOUNDATION KIT · Pilar SEGURIDAD · 01_CORE
-- Fundación de seguridad para CUALQUIER proyecto nuevo (Supabase).
--
-- Corre UNA sola vez, en un proyecto Supabase FRESCO:
--   Supabase → SQL Editor → New query → pegar todo → Run.
--
-- Deja lista la maquinaria común a todos los templates:
--   · multitenancy (orgs + org_id)   · RBAC (roles + is_admin)
--   · anti-escalada de privilegios   · auditoría inmutable
--   · helpers cacheables             · profiles auto al crear usuario
--
-- Después, por CADA tabla de negocio que agregues, aplicá una receta de
-- 02_recetas_tablas.sql según su perfil de acceso (A / B / C).
--
-- Idempotente: se puede re-correr sin romper nada.
-- ============================================================

-- ===== 0. Organizaciones (tenants) ==========================
create table if not exists orgs (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  activo     boolean not null default true,
  created_at timestamptz not null default now()
);

-- ===== 1. Perfiles de usuario (1 fila por usuario de auth) ===
create table if not exists profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text,
  nombre     text,
  role       text not null default 'usuario',   -- 'admin' | 'usuario' (ajustá a tu app)
  org_id     uuid references orgs(id),
  activo     boolean not null default true,
  created_at timestamptz not null default now()
);

-- ===== 2. Auditoría: log inmutable =========================
create table if not exists actividad (
  id         bigint generated always as identity primary key,
  entidad    text not null,        -- tabla afectada
  entidad_id uuid,                 -- id de la fila
  accion     text not null,        -- insert | update | delete
  usuario    uuid,                 -- auth.uid() que la hizo
  org_id     uuid references orgs(id),
  payload    jsonb,                -- snapshot de la fila
  created_at timestamptz not null default now()
);

-- ===== 3. Helpers (security definer = corren como owner) =====
-- Espina dorsal: leen profiles aunque la RLS del invocante lo niegue.
create or replace function auth_org_id() returns uuid
language sql stable security definer set search_path = public as $$
  select org_id from public.profiles where id = auth.uid()
$$;

create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin')
$$;

-- ===== 4. Stamping de org_id en cada INSERT (el front no manda org_id) =====
-- Autenticado sin org_id → su org. Anónimo → org por defecto (forzada,
-- ignora cualquier org_id del cliente: anti-inyección cross-tenant).
create or replace function set_org_id() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_org uuid;
begin
  if v_uid is null then
    select id into v_org from public.orgs order by created_at limit 1;
    new.org_id := v_org;
  elsif new.org_id is null then
    new.org_id := auth_org_id();
  end if;
  return new;
end $$;

-- ===== 5. Auditoría automática por trigger ==================
-- Escribe en actividad aunque la RLS niegue al user → log infalsificable.
create or replace function audit_row() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_row jsonb; v_id uuid; v_org uuid;
begin
  if (tg_op = 'DELETE') then v_row := to_jsonb(old); v_id := old.id;
  else v_row := to_jsonb(new); v_id := new.id; end if;
  begin v_org := (v_row->>'org_id')::uuid; exception when others then v_org := null; end;
  insert into actividad (entidad, entidad_id, accion, usuario, org_id, payload)
  values (tg_table_name, v_id, lower(tg_op), auth.uid(),
          coalesce(v_org, auth_org_id()), v_row);
  return coalesce(new, old);
end $$;

-- ===== 6. Usuario nuevo → fila en profiles con org por defecto =====
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_org uuid;
begin
  select id into v_org from public.orgs order by created_at limit 1;
  if v_org is null then
    insert into public.orgs(nombre) values ('Mi Organización') returning id into v_org;
  end if;
  insert into public.profiles (id, email, nombre, org_id)
  values (new.id, new.email,
          coalesce(new.raw_user_meta_data->>'nombre', new.email), v_org);
  return new;
end $$;
drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created
  after insert on auth.users for each row execute function handle_new_user();

-- ===== 7. Anti-escalada de privilegios ======================
-- Bloquea "update profiles set role='admin' where id=auth.uid()".
create or replace function guard_profile_privesc() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (new.role   is distinct from old.role
   or new.org_id is distinct from old.org_id
   or new.activo is distinct from old.activo) and not is_admin() then
     raise exception 'no autorizado: solo un admin puede cambiar role/org/activo';
  end if;
  return new;
end $$;
drop trigger if exists trg_profiles_guard on profiles;
create trigger trg_profiles_guard before update on profiles
  for each row execute function guard_profile_privesc();

-- ===== 8. RLS de las tablas de plataforma ===================
alter table orgs       enable row level security;
alter table profiles   enable row level security;
alter table actividad  enable row level security;

-- orgs: cada quien ve solo la suya
drop policy if exists orgs_read on orgs;
create policy orgs_read on orgs for select to authenticated using (id = auth_org_id());

-- profiles: lectura por org; uno edita lo suyo, admin edita los de su org
drop policy if exists profiles_read_org on profiles;
create policy profiles_read_org on profiles for select to authenticated
  using (org_id = auth_org_id());
drop policy if exists profiles_self_update on profiles;
create policy profiles_self_update on profiles for update to authenticated
  using (id = auth.uid() or is_admin())
  with check ((id = auth.uid() or is_admin()) and org_id = auth_org_id());

-- actividad: SOLO lectura por org. Sin políticas de write ⇒ inmutable.
drop policy if exists actividad_read_org on actividad;
create policy actividad_read_org on actividad for select to authenticated
  using (org_id = auth_org_id());

-- ===== 9. Org inicial (para que el primer usuario tenga dónde caer) =====
insert into orgs (nombre)
select 'Mi Organización' where not exists (select 1 from orgs);

-- ============================================================
-- LISTO. Próximo paso: por cada tabla de negocio, aplicá una receta de
-- 02_recetas_tablas.sql (perfil A privado / B público-lectura / C landing).
-- Y en el dashboard: Authentication → cerrá "Allow new users to sign up"
-- si el acceso es de equipo cerrado (ver README §5).
-- ============================================================
