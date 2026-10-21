-- =====================================================
-- KODIGO URBAN · Esquema de Supabase
-- Pégalo completo en: Supabase > SQL Editor > New query > Run
-- Se puede ejecutar varias veces sin romper nada.
-- =====================================================

create extension if not exists pgcrypto;

-- ---------- Productos ----------
create table if not exists public.products (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(btrim(name)) between 1 and 120),
  category    text not null check (category in ('gorras','tenis','sudaderas','pantalones')),
  price       numeric(10,2) not null check (price >= 0),
  description text not null default '',
  images      text[] not null default '{}',   -- URLs públicas (sin límite en BD; el panel permite 6 y ampliar de 6 en 6)
  sizes       text[] not null default '{}',   -- tallas opcionales
  active      boolean not null default true,
  featured    boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists products_category_idx on public.products (category);
create index if not exists products_created_idx  on public.products (created_at desc);

-- ---------- Ajustes del sitio (banner, logo, barra superior) ----------
create table if not exists public.settings (
  key        text primary key,
  value      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- ---------- updated_at automático ----------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists products_updated on public.products;
create trigger products_updated before update on public.products
  for each row execute function public.set_updated_at();

drop trigger if exists settings_updated on public.settings;
create trigger settings_updated before update on public.settings
  for each row execute function public.set_updated_at();

-- ---------- Seguridad (RLS) ----------
-- Público: solo LEE productos activos y ajustes.
-- Administrador (usuario autenticado en Supabase Auth): lee y escribe todo.
alter table public.products enable row level security;
alter table public.settings enable row level security;

drop policy if exists products_public_read on public.products;
create policy products_public_read on public.products
  for select using (active = true or auth.role() = 'authenticated');

drop policy if exists products_admin_write on public.products;
create policy products_admin_write on public.products
  for all to authenticated using (true) with check (true);

drop policy if exists settings_public_read on public.settings;
create policy settings_public_read on public.settings
  for select using (true);

drop policy if exists settings_admin_write on public.settings;
create policy settings_admin_write on public.settings
  for all to authenticated using (true) with check (true);

-- ---------- Permisos de la API (por si el proyecto no los da por defecto) ----------
grant usage on schema public to anon, authenticated;
grant select on public.products, public.settings to anon, authenticated;
grant insert, update, delete on public.products, public.settings to authenticated;

-- ---------- Ajustes iniciales ----------
insert into public.settings (key, value) values (
  'site',
  '{
    "logo": "",
    "announce": "Haz tu pedido directo por WhatsApp",
    "banner": {
      "active": true,
      "title": "Drop de temporada",
      "subtitle": "Promociones del mes en gorras, tenis, sudaderas y pantalones",
      "cta": "Ver tienda",
      "link": "#/tienda",
      "image": ""
    }
  }'::jsonb
) on conflict (key) do nothing;

-- ---------- Productos iniciales (solo si la tabla está vacía) ----------
-- Las fotos viven en la carpeta img/ del sitio (van en el ZIP). Edítalas o bórralas desde el panel.
insert into public.products (name, category, price, description, images, featured, created_at)
select * from (values
  ('GORRA NEW ERA 59FIFTY · Yankees blanca', 'gorras', 30, 'Calidad top Quality', array['img/gorra-1.jpg']::text[], true, now() - interval '1 minutes'),
  ('GORRA NEW ERA 59FIFTY · Braves negra', 'gorras', 30, 'Calidad top Quality', array['img/gorra-2.jpg']::text[], true, now() - interval '2 minutes'),
  ('GORRA NEW ERA 59FIFTY · Dodgers blanca y negra', 'gorras', 30, 'Calidad top Quality', array['img/gorra-3.jpg']::text[], true, now() - interval '3 minutes'),
  ('GORRA NEW ERA 59FIFTY · Yankees blanca y negra', 'gorras', 30, 'Calidad top Quality', array['img/gorra-4.jpg']::text[], true, now() - interval '4 minutes'),
  ('GORRA NEW ERA 59FIFTY · Rockets Just Don negra', 'gorras', 30, 'Calidad top Quality', array['img/gorra-5.jpg']::text[], false, now() - interval '5 minutes'),
  ('GORRA NEW ERA 59FIFTY · Dodgers roja', 'gorras', 30, 'Calidad top Quality', array['img/gorra-6.jpg']::text[], false, now() - interval '6 minutes'),
  ('GORRA NEW ERA 59FIFTY · Bulls Just Don negra', 'gorras', 30, 'Calidad top Quality', array['img/gorra-7.jpg']::text[], false, now() - interval '7 minutes'),
  ('GORRA NEW ERA 59FIFTY · Pirates negra', 'gorras', 30, 'Calidad top Quality', array['img/gorra-8.jpg']::text[], false, now() - interval '8 minutes'),
  ('GORRA NEW ERA 59FIFTY · Raiders blanca', 'gorras', 30, 'Calidad top Quality', array['img/gorra-9.jpg']::text[], false, now() - interval '9 minutes'),
  ('GORRA NEW ERA 59FIFTY · Yankees roja', 'gorras', 30, 'Calidad top Quality', array['img/gorra-10.jpg']::text[], false, now() - interval '10 minutes')
) as v(name, category, price, description, images, featured, created_at)
where not exists (select 1 from public.products);

-- ---------- Almacenamiento de fotos (bucket público "media") ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('media', 'media', true, 10485760,
        array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update
  set public = true,
      file_size_limit = 10485760,
      allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif'];

do $$
begin
  drop policy if exists media_public_read on storage.objects;
  create policy media_public_read on storage.objects
    for select using (bucket_id = 'media');

  drop policy if exists media_admin_insert on storage.objects;
  create policy media_admin_insert on storage.objects
    for insert to authenticated with check (bucket_id = 'media');

  drop policy if exists media_admin_update on storage.objects;
  create policy media_admin_update on storage.objects
    for update to authenticated using (bucket_id = 'media') with check (bucket_id = 'media');

  drop policy if exists media_admin_delete on storage.objects;
  create policy media_admin_delete on storage.objects
    for delete to authenticated using (bucket_id = 'media');
exception when others then
  raise notice 'Aviso: no se pudieron crear las politicas de storage (%). Crealas en Storage > Policies del bucket media.', sqlerrm;
end $$;
