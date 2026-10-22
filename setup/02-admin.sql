-- FIRST: Supabase > Authentication > Users > Add user > Create new user.
-- Enter your own admin email and a strong password. Enable Auto Confirm User.
-- THEN replace YOUR_ADMIN_EMAIL below and run this query.
-- Never place your password or a secret/service_role key in website files.
do $$
declare admin_id uuid;
begin
 select id into admin_id from auth.users where lower(email)=lower('YOUR_ADMIN_EMAIL');
 if admin_id is null then raise exception 'Admin user not found: create the user in Authentication > Users and replace YOUR_ADMIN_EMAIL first.'; end if;
 insert into public.namy_admins(user_id) values(admin_id) on conflict(user_id) do nothing;
end;$$;
