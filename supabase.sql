-- Ellie Pet Care — NEW Supabase project
-- Run this entire file in Supabase Dashboard → SQL Editor.
-- The app uses Supabase Auth + Postgres + Row Level Security.

create table if not exists public.dogs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null default 'Ellie',
  breed text not null default 'Цвергшнауцер',
  photo_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.medications (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid not null references public.dogs(id) on delete cascade,
  name text not null,
  cycle_days integer,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.medication_logs (
  id uuid primary key default gen_random_uuid(),
  medication_id uuid not null references public.medications(id) on delete cascade,
  given_date date not null,
  status text not null default 'given' check (status in ('given','missed')),
  comment text,
  created_at timestamptz not null default now()
);

create table if not exists public.vaccinations (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid not null references public.dogs(id) on delete cascade,
  name text not null default 'Вакцинация',
  given_date date not null,
  next_date date,
  comment text,
  created_at timestamptz not null default now()
);

create table if not exists public.vet_visits (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid not null references public.dogs(id) on delete cascade,
  visit_date date not null,
  title text not null default 'Визит к ветеринару',
  comment text,
  created_at timestamptz not null default now()
);

create table if not exists public.heat_cycles (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid not null references public.dogs(id) on delete cascade,
  start_date date not null,
  end_date date,
  comment text,
  created_at timestamptz not null default now()
);

create table if not exists public.weights (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid not null references public.dogs(id) on delete cascade,
  measured_date date not null,
  weight_kg numeric(5,2) not null check (weight_kg > 0 and weight_kg < 100),
  comment text,
  created_at timestamptz not null default now()
);

-- Helpful indexes
create index if not exists medications_dog_id_idx on public.medications(dog_id);
create index if not exists medication_logs_medication_id_idx on public.medication_logs(medication_id);
create index if not exists vaccinations_dog_id_idx on public.vaccinations(dog_id);
create index if not exists vet_visits_dog_id_idx on public.vet_visits(dog_id);
create index if not exists heat_cycles_dog_id_idx on public.heat_cycles(dog_id);
create index if not exists weights_dog_id_idx on public.weights(dog_id);

-- RLS
alter table public.dogs enable row level security;
alter table public.medications enable row level security;
alter table public.medication_logs enable row level security;
alter table public.vaccinations enable row level security;
alter table public.vet_visits enable row level security;
alter table public.heat_cycles enable row level security;
alter table public.weights enable row level security;

-- Dogs: owner is auth.uid()
drop policy if exists "dogs_select_own" on public.dogs;
drop policy if exists "dogs_insert_own" on public.dogs;
drop policy if exists "dogs_update_own" on public.dogs;
drop policy if exists "dogs_delete_own" on public.dogs;

create policy "dogs_select_own" on public.dogs for select to authenticated using (user_id = auth.uid());
create policy "dogs_insert_own" on public.dogs for insert to authenticated with check (user_id = auth.uid());
create policy "dogs_update_own" on public.dogs for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "dogs_delete_own" on public.dogs for delete to authenticated using (user_id = auth.uid());

-- Child rows are accessible only when their dog belongs to the current user.
drop policy if exists "medications_select_own" on public.medications;
drop policy if exists "medications_insert_own" on public.medications;
drop policy if exists "medications_update_own" on public.medications;
drop policy if exists "medications_delete_own" on public.medications;

create policy "medications_select_own" on public.medications for select to authenticated
using (exists (select 1 from public.dogs d where d.id = medications.dog_id and d.user_id = auth.uid()));
create policy "medications_insert_own" on public.medications for insert to authenticated
with check (exists (select 1 from public.dogs d where d.id = medications.dog_id and d.user_id = auth.uid()));
create policy "medications_update_own" on public.medications for update to authenticated
using (exists (select 1 from public.dogs d where d.id = medications.dog_id and d.user_id = auth.uid()))
with check (exists (select 1 from public.dogs d where d.id = medications.dog_id and d.user_id = auth.uid()));
create policy "medications_delete_own" on public.medications for delete to authenticated
using (exists (select 1 from public.dogs d where d.id = medications.dog_id and d.user_id = auth.uid()));

drop policy if exists "medication_logs_select_own" on public.medication_logs;
drop policy if exists "medication_logs_insert_own" on public.medication_logs;
drop policy if exists "medication_logs_update_own" on public.medication_logs;
drop policy if exists "medication_logs_delete_own" on public.medication_logs;

create policy "medication_logs_select_own" on public.medication_logs for select to authenticated
using (exists (
  select 1 from public.medications m join public.dogs d on d.id=m.dog_id
  where m.id=medication_logs.medication_id and d.user_id=auth.uid()
));
create policy "medication_logs_insert_own" on public.medication_logs for insert to authenticated
with check (exists (
  select 1 from public.medications m join public.dogs d on d.id=m.dog_id
  where m.id=medication_logs.medication_id and d.user_id=auth.uid()
));
create policy "medication_logs_update_own" on public.medication_logs for update to authenticated
using (exists (
  select 1 from public.medications m join public.dogs d on d.id=m.dog_id
  where m.id=medication_logs.medication_id and d.user_id=auth.uid()
))
with check (exists (
  select 1 from public.medications m join public.dogs d on d.id=m.dog_id
  where m.id=medication_logs.medication_id and d.user_id=auth.uid()
));
create policy "medication_logs_delete_own" on public.medication_logs for delete to authenticated
using (exists (
  select 1 from public.medications m join public.dogs d on d.id=m.dog_id
  where m.id=medication_logs.medication_id and d.user_id=auth.uid()
));

-- Generic child table policy helper, written explicitly for clarity.
drop policy if exists "vaccinations_select_own" on public.vaccinations;
drop policy if exists "vaccinations_insert_own" on public.vaccinations;
drop policy if exists "vaccinations_update_own" on public.vaccinations;
drop policy if exists "vaccinations_delete_own" on public.vaccinations;
create policy "vaccinations_select_own" on public.vaccinations for select to authenticated using (exists(select 1 from public.dogs d where d.id=vaccinations.dog_id and d.user_id=auth.uid()));
create policy "vaccinations_insert_own" on public.vaccinations for insert to authenticated with check (exists(select 1 from public.dogs d where d.id=vaccinations.dog_id and d.user_id=auth.uid()));
create policy "vaccinations_update_own" on public.vaccinations for update to authenticated using (exists(select 1 from public.dogs d where d.id=vaccinations.dog_id and d.user_id=auth.uid())) with check (exists(select 1 from public.dogs d where d.id=vaccinations.dog_id and d.user_id=auth.uid()));
create policy "vaccinations_delete_own" on public.vaccinations for delete to authenticated using (exists(select 1 from public.dogs d where d.id=vaccinations.dog_id and d.user_id=auth.uid()));

drop policy if exists "vet_visits_select_own" on public.vet_visits;
drop policy if exists "vet_visits_insert_own" on public.vet_visits;
drop policy if exists "vet_visits_update_own" on public.vet_visits;
drop policy if exists "vet_visits_delete_own" on public.vet_visits;
create policy "vet_visits_select_own" on public.vet_visits for select to authenticated using (exists(select 1 from public.dogs d where d.id=vet_visits.dog_id and d.user_id=auth.uid()));
create policy "vet_visits_insert_own" on public.vet_visits for insert to authenticated with check (exists(select 1 from public.dogs d where d.id=vet_visits.dog_id and d.user_id=auth.uid()));
create policy "vet_visits_update_own" on public.vet_visits for update to authenticated using (exists(select 1 from public.dogs d where d.id=vet_visits.dog_id and d.user_id=auth.uid())) with check (exists(select 1 from public.dogs d where d.id=vet_visits.dog_id and d.user_id=auth.uid()));
create policy "vet_visits_delete_own" on public.vet_visits for delete to authenticated using (exists(select 1 from public.dogs d where d.id=vet_visits.dog_id and d.user_id=auth.uid()));

drop policy if exists "heat_cycles_select_own" on public.heat_cycles;
drop policy if exists "heat_cycles_insert_own" on public.heat_cycles;
drop policy if exists "heat_cycles_update_own" on public.heat_cycles;
drop policy if exists "heat_cycles_delete_own" on public.heat_cycles;
create policy "heat_cycles_select_own" on public.heat_cycles for select to authenticated using (exists(select 1 from public.dogs d where d.id=heat_cycles.dog_id and d.user_id=auth.uid()));
create policy "heat_cycles_insert_own" on public.heat_cycles for insert to authenticated with check (exists(select 1 from public.dogs d where d.id=heat_cycles.dog_id and d.user_id=auth.uid()));
create policy "heat_cycles_update_own" on public.heat_cycles for update to authenticated using (exists(select 1 from public.dogs d where d.id=heat_cycles.dog_id and d.user_id=auth.uid())) with check (exists(select 1 from public.dogs d where d.id=heat_cycles.dog_id and d.user_id=auth.uid()));
create policy "heat_cycles_delete_own" on public.heat_cycles for delete to authenticated using (exists(select 1 from public.dogs d where d.id=heat_cycles.dog_id and d.user_id=auth.uid()));

drop policy if exists "weights_select_own" on public.weights;
drop policy if exists "weights_insert_own" on public.weights;
drop policy if exists "weights_update_own" on public.weights;
drop policy if exists "weights_delete_own" on public.weights;
create policy "weights_select_own" on public.weights for select to authenticated using (exists(select 1 from public.dogs d where d.id=weights.dog_id and d.user_id=auth.uid()));
create policy "weights_insert_own" on public.weights for insert to authenticated with check (exists(select 1 from public.dogs d where d.id=weights.dog_id and d.user_id=auth.uid()));
create policy "weights_update_own" on public.weights for update to authenticated using (exists(select 1 from public.dogs d where d.id=weights.dog_id and d.user_id=auth.uid())) with check (exists(select 1 from public.dogs d where d.id=weights.dog_id and d.user_id=auth.uid()));
create policy "weights_delete_own" on public.weights for delete to authenticated using (exists(select 1 from public.dogs d where d.id=weights.dog_id and d.user_id=auth.uid()));

-- Data API grants. RLS remains the security boundary.
grant select, insert, update, delete on public.dogs to authenticated;
grant select, insert, update, delete on public.medications to authenticated;
grant select, insert, update, delete on public.medication_logs to authenticated;
grant select, insert, update, delete on public.vaccinations to authenticated;
grant select, insert, update, delete on public.vet_visits to authenticated;
grant select, insert, update, delete on public.heat_cycles to authenticated;
grant select, insert, update, delete on public.weights to authenticated;
