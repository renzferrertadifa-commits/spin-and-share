-- Run this entire script in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  email text primary key
);
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  room_code text unique not null,
  name text not null,
  created_by uuid not null,
  created_at timestamptz not null default now()
);
create table if not exists public.choices (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  label text not null,
  is_taken boolean not null default false,
  taken_by text,
  taken_at timestamptz
);
create table if not exists public.spins (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  participant_id uuid not null,
  participant_name text not null,
  choice_label text not null,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
alter table public.rooms enable row level security;
alter table public.choices enable row level security;
alter table public.spins enable row level security;

create or replace function public.is_current_user_admin()
returns boolean language sql stable security definer set search_path=public
as $$
 select exists(select 1 from public.admin_users a where lower(a.email)=lower(auth.jwt()->>'email'));
$$;
grant execute on function public.is_current_user_admin() to authenticated;

create policy "admins read own admin status" on public.admin_users
for select to authenticated using (lower(email)=lower(auth.jwt()->>'email'));

create policy "anyone can read rooms by code" on public.rooms
for select to anon, authenticated using (true);
create policy "admins create rooms" on public.rooms
for insert to authenticated with check (public.is_current_user_admin() and created_by=auth.uid());
create policy "admins manage rooms" on public.rooms
for all to authenticated using (public.is_current_user_admin()) with check (public.is_current_user_admin());

create policy "anyone reads available choices" on public.choices
for select to anon, authenticated using (true);
create policy "admins add choices" on public.choices
for insert to authenticated with check (public.is_current_user_admin());
create policy "admins update choices" on public.choices
for update to authenticated using (public.is_current_user_admin()) with check (public.is_current_user_admin());
create policy "admins delete choices" on public.choices
for delete to authenticated using (public.is_current_user_admin());

create policy "admins view spin history" on public.spins
for select to authenticated using (public.is_current_user_admin());

create or replace function public.claim_random_choice(p_room_code text,p_participant_name text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare
  v_room public.rooms%rowtype;
  v_choice public.choices%rowtype;
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Please join again to start a session.'; end if;
  if length(trim(coalesce(p_participant_name,'')))=0 then raise exception 'Enter your name first.'; end if;
  select * into v_room from public.rooms where room_code=upper(trim(p_room_code)) for update;
  if not found then raise exception 'Room code not found.'; end if;
  select * into v_choice from public.choices
   where room_id=v_room.id and is_taken=false
   order by random() limit 1 for update skip locked;
  if not found then raise exception 'No choices remain in this room.'; end if;
  update public.choices set is_taken=true,taken_by=trim(p_participant_name),taken_at=now() where id=v_choice.id;
  insert into public.spins(room_id,participant_id,participant_name,choice_label)
  values(v_room.id,v_user,trim(p_participant_name),v_choice.label);
  return jsonb_build_object('label',v_choice.label);
end;
$$;
grant execute on function public.claim_random_choice(text,text) to anon,authenticated;

-- IMPORTANT: Replace this email with YOUR admin login email after creating
-- your Supabase project and registering an admin account.
-- Example:
-- insert into public.admin_users(email) values ('you@example.com');
-- Enable Anonymous Sign-Ins in Authentication > Providers for participants.
-- Enable Realtime for the public.choices table in Database > Replication.
