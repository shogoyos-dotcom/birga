-- ============================================================
--  BIRGA HAMYON — Supabase schema (guruhlar uchun)
--  Supabase Dashboard ▸ SQL Editor ▸ shu faylni to‘liq run qiling.
-- ============================================================

-- ---------- Jadvallar ----------
create table if not exists groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  currency text not null default 'UZS',
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  name text not null,
  user_id uuid references auth.users(id),          -- null = hali qo‘shilmagan (taklif kutyapti)
  role text not null default 'editor',             -- 'owner' | 'editor' | 'viewer'
  claim_token text,                                -- taklif havolasidagi maxfiy kalit
  created_at timestamptz not null default now()
);
create index if not exists members_group_idx on members(group_id);
create index if not exists members_user_idx on members(user_id);

create table if not exists entries (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  type text not null default 'expense',            -- 'expense' | 'income'
  title text not null,
  amount bigint not null,
  category text,
  paid_by uuid references members(id) on delete set null,
  occurred_on date not null default current_date,
  splits jsonb not null default '[]'::jsonb,        -- [{"member_id": "...", "share": 123}]
  receipt text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists entries_group_idx on entries(group_id);

create table if not exists settlements (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references groups(id) on delete cascade,
  from_member uuid references members(id) on delete cascade,
  to_member uuid references members(id) on delete cascade,
  amount bigint not null,
  occurred_on date not null default current_date,
  created_at timestamptz not null default now()
);
create index if not exists settlements_group_idx on settlements(group_id);

-- ---------- Yordamchi funksiyalar (RLS uchun) ----------
create or replace function is_member(gid uuid) returns boolean
  language sql security definer stable set search_path = public as $$
  select exists (select 1 from members where group_id = gid and user_id = auth.uid());
$$;

create or replace function member_role(gid uuid) returns text
  language sql security definer stable set search_path = public as $$
  select role from members where group_id = gid and user_id = auth.uid() limit 1;
$$;

-- ---------- RLS ----------
alter table groups      enable row level security;
alter table members     enable row level security;
alter table entries     enable row level security;
alter table settlements enable row level security;

-- GROUPS
drop policy if exists g_select on groups;
drop policy if exists g_insert on groups;
drop policy if exists g_update on groups;
create policy g_select on groups for select using (is_member(id));
create policy g_insert on groups for insert with check (auth.uid() = created_by);
create policy g_update on groups for update using (member_role(id) = 'owner');

-- MEMBERS
drop policy if exists m_select    on members;
drop policy if exists m_owner     on members;
drop policy if exists m_bootstrap on members;
create policy m_select on members for select using (is_member(group_id));
-- guruh yaratuvchi o‘zining "owner" a'zo qatorini birinchi bo‘lib qo‘sha oladi
create policy m_bootstrap on members for insert with check (
  user_id = auth.uid() and role = 'owner'
  and exists (select 1 from groups where id = group_id and created_by = auth.uid())
);
create policy m_owner on members for all
  using (member_role(group_id) = 'owner')
  with check (member_role(group_id) = 'owner');

-- ENTRIES
drop policy if exists e_select on entries;
drop policy if exists e_write  on entries;
create policy e_select on entries for select using (is_member(group_id));
create policy e_write  on entries for all
  using (member_role(group_id) in ('owner','editor'))
  with check (member_role(group_id) in ('owner','editor'));

-- SETTLEMENTS
drop policy if exists s_select on settlements;
drop policy if exists s_write  on settlements;
create policy s_select on settlements for select using (is_member(group_id));
create policy s_write  on settlements for all
  using (member_role(group_id) in ('owner','editor'))
  with check (member_role(group_id) in ('owner','editor'));

-- ---------- Taklif / qo‘shilish RPC ----------
-- Havola egasi guruhga a'zo bo‘lishдан oldin nima ko‘rishini qaytaradi
create or replace function invite_preview(p_member uuid, p_token text)
  returns table(group_id uuid, group_name text, member_name text, already_claimed boolean)
  language sql security definer stable set search_path = public as $$
  select m.group_id, g.name, m.name, (m.user_id is not null)
  from members m join groups g on g.id = m.group_id
  where m.id = p_member and m.claim_token = p_token;
$$;

-- Havola orqali a'zo o‘rnini egallash
create or replace function claim_member(p_member uuid, p_token text)
  returns members language plpgsql security definer set search_path = public as $$
declare m members;
begin
  update members set user_id = auth.uid()
   where id = p_member and claim_token = p_token and user_id is null
  returning * into m;
  if m.id is null then
    raise exception 'Taklif yaroqsiz yoki allaqachon ishlatilgan';
  end if;
  return m;
end $$;

grant execute on function invite_preview(uuid, text) to anon, authenticated;
grant execute on function claim_member(uuid, text)  to anon, authenticated;

-- ---------- Realtime ----------
alter publication supabase_realtime add table groups;
alter publication supabase_realtime add table members;
alter publication supabase_realtime add table entries;
alter publication supabase_realtime add table settlements;
