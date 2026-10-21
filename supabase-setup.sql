create table if not exists public.portfolio_uploads (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    category text not null check (category in ('photoshop', 'illustrator', 'premiere', 'after-effects')),
    file_name text not null,
    mime_type text not null,
    storage_path text not null unique,
    created_at timestamptz not null default now()
);

alter table public.portfolio_uploads enable row level security;

grant select on public.portfolio_uploads to anon, authenticated;
grant insert, delete on public.portfolio_uploads to authenticated;

drop policy if exists "Anyone can view portfolio uploads" on public.portfolio_uploads;
create policy "Anyone can view portfolio uploads"
    on public.portfolio_uploads for select
    using (true);

drop policy if exists "Portfolio owner can upload metadata" on public.portfolio_uploads;
create policy "Portfolio owner can upload metadata"
    on public.portfolio_uploads for insert
    to authenticated
    with check ((auth.jwt() -> 'app_metadata' ->> 'portfolio_owner') = 'true');

drop policy if exists "Portfolio owner can delete metadata" on public.portfolio_uploads;
create policy "Portfolio owner can delete metadata"
    on public.portfolio_uploads for delete
    to authenticated
    using ((auth.jwt() -> 'app_metadata' ->> 'portfolio_owner') = 'true');

insert into storage.buckets (id, name, public)
values ('portfolio-uploads', 'portfolio-uploads', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Anyone can view portfolio files" on storage.objects;
create policy "Anyone can view portfolio files"
    on storage.objects for select
    using (bucket_id = 'portfolio-uploads');

drop policy if exists "Portfolio owner can upload files" on storage.objects;
create policy "Portfolio owner can upload files"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'portfolio-uploads'
        and (auth.jwt() -> 'app_metadata' ->> 'portfolio_owner') = 'true'
    );

drop policy if exists "Portfolio owner can update files" on storage.objects;
create policy "Portfolio owner can update files"
    on storage.objects for update
    to authenticated
    using (
        bucket_id = 'portfolio-uploads'
        and (auth.jwt() -> 'app_metadata' ->> 'portfolio_owner') = 'true'
    )
    with check (
        bucket_id = 'portfolio-uploads'
        and (auth.jwt() -> 'app_metadata' ->> 'portfolio_owner') = 'true'
    );

drop policy if exists "Portfolio owner can delete files" on storage.objects;
create policy "Portfolio owner can delete files"
    on storage.objects for delete
    to authenticated
    using (
        bucket_id = 'portfolio-uploads'
        and (auth.jwt() -> 'app_metadata' ->> 'portfolio_owner') = 'true'
    );
