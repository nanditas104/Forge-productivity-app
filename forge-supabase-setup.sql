-- ═══════════════════════════════════════════════════════════════════
-- FORGE APP — SUPABASE DATABASE SETUP
-- Run this entire file in Supabase → SQL Editor → New Query → Run
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. USER PROFILES TABLE ──────────────────────────────────────────
-- Stores username & contact alongside Supabase auth user
create table if not exists public.forge_users (
  id          uuid primary key references auth.users(id) on delete cascade,
  username    text not null,
  contact     text,
  created_at  timestamptz default now()
);

-- ── 2. APP STATE TABLE ───────────────────────────────────────────────
-- One row per user — all app data stored as JSONB columns
create table if not exists public.forge_state (
  id              bigserial primary key,
  user_id         uuid not null unique references auth.users(id) on delete cascade,
  tasks           jsonb default '[]'::jsonb,
  habits          jsonb default '[]'::jsonb,
  goals           jsonb default '[]'::jsonb,
  books           jsonb default '[]'::jsonb,
  reflections     jsonb default '[]'::jsonb,
  focus_sessions  jsonb default '[]'::jsonb,
  waste_log       jsonb default '[]'::jsonb,
  cal_events      jsonb default '{}'::jsonb,
  settings        jsonb default '{}'::jsonb,
  updated_at      timestamptz default now()
);

-- ── 3. ROW LEVEL SECURITY (RLS) ──────────────────────────────────────
-- Users can only read/write their own data
alter table public.forge_users  enable row level security;
alter table public.forge_state  enable row level security;

-- forge_users policies
create policy "Users can read own profile"
  on public.forge_users for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.forge_users for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.forge_users for update
  using (auth.uid() = id);

-- forge_state policies
create policy "Users can read own state"
  on public.forge_state for select
  using (auth.uid() = user_id);

create policy "Users can insert own state"
  on public.forge_state for insert
  with check (auth.uid() = user_id);

create policy "Users can update own state"
  on public.forge_state for update
  using (auth.uid() = user_id);

create policy "Users can upsert own state"
  on public.forge_state for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── 4. AUTO-UPDATE TIMESTAMP TRIGGER ────────────────────────────────
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger forge_state_updated_at
  before update on public.forge_state
  for each row execute function update_updated_at();

-- ── 5. DONE! ─────────────────────────────────────────────────────────
-- Your schema is ready. Now:
-- 1. Go to Supabase → Project Settings → API
-- 2. Copy "Project URL" and "anon public" key
-- 3. Paste them into both forge-login.html and forge-icons.html
--    where you see: SUPABASE_URL and SUPABASE_ANON_KEY
