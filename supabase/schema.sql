-- Schéma Supabase pour le Carnet de Reprise
-- À exécuter dans : Supabase Dashboard > SQL Editor > New query

create extension if not exists "pgcrypto";

-- Un étudiant = un compte anonyme Supabase Auth, avec un prénom choisi une fois
create table if not exists public.students (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

-- Une ligne par jour du planning coché par un étudiant
create table if not exists public.progress (
  student_id uuid not null references public.students(id) on delete cascade,
  day_key text not null,
  checked boolean not null default false,
  checked_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (student_id, day_key)
);

alter table public.students enable row level security;
alter table public.progress enable row level security;

-- Un étudiant ne voit et ne modifie que sa propre fiche
create policy "student reads own profile" on public.students
  for select using (auth.uid() = id);
create policy "student creates own profile" on public.students
  for insert with check (auth.uid() = id);
create policy "student updates own profile" on public.students
  for update using (auth.uid() = id);

-- L'admin voit toutes les fiches étudiants
create policy "admin reads all profiles" on public.students
  for select using (auth.jwt() ->> 'email' = 'fopa.lesley@gmail.com');

-- Un étudiant ne voit et ne modifie que sa propre progression
create policy "student reads own progress" on public.progress
  for select using (auth.uid() = student_id);
create policy "student inserts own progress" on public.progress
  for insert with check (auth.uid() = student_id);
create policy "student updates own progress" on public.progress
  for update using (auth.uid() = student_id);

-- L'admin voit la progression de tous les étudiants
create policy "admin reads all progress" on public.progress
  for select using (auth.jwt() ->> 'email' = 'fopa.lesley@gmail.com');
