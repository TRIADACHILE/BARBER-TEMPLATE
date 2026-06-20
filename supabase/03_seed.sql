-- ============================================================
-- BARBERÍA TRIADA · 03_SEED  (datos iniciales de ejemplo)
-- Corre DESPUÉS de 01_core.sql y 02_barberia.sql.
--
-- Carga el catálogo de servicios + una cartera y gastos de ejemplo,
-- para que el CRM no arranque vacío. El trigger set_org_id() estampa
-- la organización por defecto automáticamente.
--
-- Idempotente: cada tabla se siembra solo si está vacía (se puede
-- re-correr sin duplicar). Para re-sembrar, vacía la tabla antes.
-- ============================================================

-- ── Servicios (catálogo público) ────────────────────────────
insert into servicios (nombre, descripcion, duracion, precio, orden)
select v.* from (values
  ('Corte',              'Tijera y máquina, lavado incluido',                '30 min', 12000, 1),
  ('Corte + barba',      'Corte completo + perfilado y toalla caliente',     '45 min', 18000, 2),
  ('Perfilado de barba', 'Diseño, navaja y aceite',                          '25 min',  9000, 3),
  ('Afeitado clásico',   'Navaja, toalla caliente y bálsamo',                '30 min', 11000, 4),
  ('Corte niño',         'Hasta 12 años',                                    '25 min',  9000, 5),
  ('Diseño / líneas',    'Freestyle, fades y detalles',                      '40 min', 14000, 6)
) as v(nombre, descripcion, duracion, precio, orden)
where not exists (select 1 from servicios);

-- ── Clientes (cartera del CRM) ───────────────────────────────
insert into clientes (nombre, telefono, servicio_fav, notas)
select v.* from (values
  ('Diego Soto',      '+56 9 8123 4567', 'Corte + barba',   'Máquina 1.5 a los lados. Siempre puntual.'),
  ('Felipe Rojas',    '+56 9 7644 1290', 'Corte',           'Conversador, hincha de Colo-Colo.'),
  ('Camilo Vera',     '+56 9 9012 8833', 'Corte + barba',   'Cliente fiel desde 2023. Trátalo VIP.'),
  ('Tomás Díaz',      '+56 9 6233 7781', 'Afeitado clásico', 'Nuevo, llegó por Instagram.'),
  ('Sebastián Lagos', '+56 9 8890 2245', 'Diseño / líneas',  'Pide diseños, trae referencias. Reactivar.'),
  ('Andrés Pinto',    '+56 9 5567 9034', 'Corte',           'Reagenda seguido, recordarle el día antes.')
) as v(nombre, telefono, servicio_fav, notas)
where not exists (select 1 from clientes);

-- ── Gastos del mes (finanzas del CRM) ────────────────────────
insert into gastos (concepto, monto)
select v.* from (values
  ('Arriendo local',      450000),
  ('Insumos y productos', 220000),
  ('Servicios básicos',    90000),
  ('Marketing / RRSS',     60000)
) as v(concepto, monto)
where not exists (select 1 from gastos);
