-- Mercado: esquema inicial del marketplace
-- Ejecutar en el SQL Editor de Supabase o con `supabase db push`.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Perfiles (1:1 con auth.users)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Perfiles visibles para todos"
  on public.profiles for select
  using (true);

create policy "Cada usuario actualiza su perfil"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      split_part(coalesce(new.email, ''), '@', 1)
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Tiendas / vendedores (una tienda por usuario)
-- ---------------------------------------------------------------------------
create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references public.profiles (id) on delete cascade,
  name text not null,
  slug text not null unique,
  description text not null default '',
  logo_url text,
  phone text,
  city text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.stores enable row level security;

create policy "Tiendas visibles para todos"
  on public.stores for select
  using (true);

create policy "El dueño crea su tienda"
  on public.stores for insert
  to authenticated
  with check (auth.uid() = owner_id);

create policy "El dueño actualiza su tienda"
  on public.stores for update
  to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "El dueño elimina su tienda"
  on public.stores for delete
  to authenticated
  using (auth.uid() = owner_id);

-- ---------------------------------------------------------------------------
-- Categorías
-- ---------------------------------------------------------------------------
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  created_at timestamptz not null default now()
);

alter table public.categories enable row level security;

create policy "Categorías visibles para todos"
  on public.categories for select
  using (true);

-- ---------------------------------------------------------------------------
-- Productos
-- ---------------------------------------------------------------------------
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  category_id uuid references public.categories (id) on delete set null,
  title text not null,
  description text not null default '',
  price numeric(12, 2) not null check (price >= 0),
  currency text not null default 'USD',
  stock integer not null default 0 check (stock >= 0),
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_store_id_idx on public.products (store_id);
create index if not exists products_category_id_idx on public.products (category_id);
create index if not exists products_created_at_idx on public.products (created_at desc);

alter table public.products enable row level security;

create policy "Productos activos visibles para todos"
  on public.products for select
  using (is_active or exists (
    select 1 from public.stores s
    where s.id = products.store_id and s.owner_id = auth.uid()
  ));

create policy "El dueño publica productos en su tienda"
  on public.products for insert
  to authenticated
  with check (exists (
    select 1 from public.stores s
    where s.id = store_id and s.owner_id = auth.uid()
  ));

create policy "El dueño actualiza sus productos"
  on public.products for update
  to authenticated
  using (exists (
    select 1 from public.stores s
    where s.id = products.store_id and s.owner_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.stores s
    where s.id = store_id and s.owner_id = auth.uid()
  ));

create policy "El dueño elimina sus productos"
  on public.products for delete
  to authenticated
  using (exists (
    select 1 from public.stores s
    where s.id = products.store_id and s.owner_id = auth.uid()
  ));

-- ---------------------------------------------------------------------------
-- updated_at automático
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists stores_touch_updated_at on public.stores;
create trigger stores_touch_updated_at
  before update on public.stores
  for each row execute function public.touch_updated_at();

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at
  before update on public.products
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Storage para imágenes de productos
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create policy "Imágenes de productos públicas"
  on storage.objects for select
  using (bucket_id = 'product-images');

create policy "Usuarios suben imágenes a su carpeta"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Usuarios actualizan sus imágenes"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Usuarios eliminan sus imágenes"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- Permisos (RLS sigue aplicando)
-- ---------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;
grant select on public.profiles, public.stores, public.categories,
  public.products to anon, authenticated;
grant update on public.profiles to authenticated;
grant insert, update, delete on public.stores, public.products to authenticated;

-- ---------------------------------------------------------------------------
-- Datos iniciales
-- ---------------------------------------------------------------------------
insert into public.categories (name, slug) values
  ('Tecnología', 'tecnologia'),
  ('Moda', 'moda'),
  ('Hogar', 'hogar'),
  ('Belleza', 'belleza'),
  ('Deportes', 'deportes'),
  ('Juguetes', 'juguetes'),
  ('Libros', 'libros'),
  ('Comida', 'comida')
on conflict (slug) do nothing;
