-- NAMY/MANY MART: run in Supabase > SQL Editor > New query > Run.
-- Only run in the new project created for this store.
begin;
create table if not exists public.namy_admins (
 user_id uuid primary key references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
alter table public.namy_admins enable row level security;
revoke all on public.namy_admins from anon, authenticated;
grant select on public.namy_admins to authenticated;
drop policy if exists "admins_read_own_role" on public.namy_admins;
create policy "admins_read_own_role" on public.namy_admins for select to authenticated using (user_id=(select auth.uid()));
create or replace function public.namy_is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.namy_admins where user_id=(select auth.uid()));
$$;
revoke all on function public.namy_is_admin() from public;
grant execute on function public.namy_is_admin() to anon,authenticated;
create table if not exists public.namy_content (
 id uuid primary key default gen_random_uuid(),
 kind text not null check (kind in ('category','product','gallery')),
 category_id uuid references public.namy_content(id) on delete restrict,
 name_vi text not null check(char_length(trim(name_vi)) between 1 and 160),
 name_en text not null check(char_length(trim(name_en)) between 1 and 160),
 description_vi text not null default '' check(char_length(description_vi)<=3000),
 description_en text not null default '' check(char_length(description_en)<=3000),
 image text not null default '' check(image='' or image like '/assets/%' or image like '/media/%'),
 price bigint check(price is null or price between 0 and 1000000000),
 status text not null default 'draft' check(status in ('draft','published')),
 created timestamptz not null default now(),updated timestamptz not null default now(),
 constraint namy_product_category check ((kind='product' and category_id is not null) or (kind<>'product' and category_id is null)),
 constraint namy_gallery_image check (kind<>'gallery' or status<>'published' or image<>''),
 constraint namy_supported_content check ((name_vi||' '||name_en||' '||description_vi||' '||description_en) !~* '(cigar|tobacco|vape|nicotine|thuốc[[:space:]]*lá|xì[[:space:]]*gà)')
);
create index if not exists namy_content_category_idx on public.namy_content(category_id);
create index if not exists namy_content_public_idx on public.namy_content(status,kind);
alter table public.namy_content enable row level security;
revoke all on public.namy_content from anon,authenticated;
grant select on public.namy_content to anon,authenticated;
grant insert,update,delete on public.namy_content to authenticated;
create or replace function public.namy_visible_category(category uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.namy_content where id=category and kind='category' and status='published');
$$;
revoke all on function public.namy_visible_category(uuid) from public;
grant execute on function public.namy_visible_category(uuid) to anon,authenticated;
drop policy if exists "namy_read_published" on public.namy_content;
create policy "namy_read_published" on public.namy_content for select to anon,authenticated using (status='published' and (kind<>'product' or public.namy_visible_category(category_id)));
drop policy if exists "namy_admin_manage" on public.namy_content;
create policy "namy_admin_manage" on public.namy_content for all to authenticated using (public.namy_is_admin()) with check (public.namy_is_admin());
create or replace function public.namy_validate_content() returns trigger language plpgsql set search_path='' as $$
begin
 if new.kind='product' and not exists(select 1 from public.namy_content where id=new.category_id and kind='category') then raise exception 'Choose a valid category'; end if;
 if TG_OP='UPDATE' and new.kind<>old.kind then raise exception 'Content type cannot be changed'; end if;
 new.updated=now();return new;
end;$$;
drop trigger if exists namy_validate_content on public.namy_content;
create trigger namy_validate_content before insert or update on public.namy_content for each row execute function public.namy_validate_content();
insert into public.namy_content(id,kind,name_vi,name_en,status) values
 ('aaaaaaaa-0000-4000-8000-000000000001','category','Rượu vang','Wines','published'),
 ('aaaaaaaa-0000-4000-8000-000000000002','category','Rượu mạnh','Spirits','published'),
 ('aaaaaaaa-0000-4000-8000-000000000003','category','Bia','Beer','published'),
 ('aaaaaaaa-0000-4000-8000-000000000004','category','Thực phẩm','Food','published') on conflict(id) do nothing;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values ('namy-images','namy-images',true,8388608,array['image/jpeg','image/png','image/webp']) on conflict(id) do update set public=true,file_size_limit=8388608,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists "namy_admin_upload" on storage.objects;
create policy "namy_admin_upload" on storage.objects for insert to authenticated with check(bucket_id='namy-images' and public.namy_is_admin());
drop policy if exists "namy_admin_update_image" on storage.objects;
create policy "namy_admin_update_image" on storage.objects for update to authenticated using(bucket_id='namy-images' and public.namy_is_admin()) with check(bucket_id='namy-images' and public.namy_is_admin());
drop policy if exists "namy_admin_delete_image" on storage.objects;
create policy "namy_admin_delete_image" on storage.objects for delete to authenticated using(bucket_id='namy-images' and public.namy_is_admin());
commit;
