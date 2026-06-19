-- ============================================================
--  GESTIONE ISTRIA — Schema per Supabase (versione cloud condivisa)
--  Da incollare ed eseguire UNA volta nel "SQL Editor" di Supabase.
--  Crea una tabella che contiene tutti i dati dell'app in un unico
--  documento JSON condiviso, con accesso riservato agli utenti loggati
--  e sincronizzazione in tempo reale.
-- ============================================================

-- Tabella dati (un'unica riga, id = 1)
create table if not exists public.club_data (
    id          int primary key,
    data        jsonb       not null default '{}'::jsonb,
    updated_at  timestamptz not null default now()
);

-- Riga iniziale vuota
insert into public.club_data (id, data)
values (1, '{"moves":[],"players":[],"events":[],"fields":["Campo Comunale","Palestra","Campo allenamento"]}'::jsonb)
on conflict (id) do nothing;

-- Sicurezza: solo gli utenti autenticati possono leggere e scrivere
alter table public.club_data enable row level security;

drop policy if exists "Lettura utenti autenticati"     on public.club_data;
drop policy if exists "Modifica utenti autenticati"     on public.club_data;
drop policy if exists "Inserimento utenti autenticati"  on public.club_data;

create policy "Lettura utenti autenticati" on public.club_data
    for select to authenticated using (true);

create policy "Modifica utenti autenticati" on public.club_data
    for update to authenticated using (true) with check (true);

create policy "Inserimento utenti autenticati" on public.club_data
    for insert to authenticated with check (true);

-- Sincronizzazione in tempo reale (se dà errore "already member" è normale: ignoralo)
alter publication supabase_realtime add table public.club_data;
