-- Run in Supabase Dashboard → SQL Editor.
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,display_name text,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table if not exists public.lesson_progress(user_id uuid not null references auth.users(id) on delete cascade,lesson_id text not null,completed_at timestamptz not null default now(),primary key(user_id,lesson_id));
create table if not exists public.quiz_attempts(id bigint generated always as identity primary key,user_id uuid not null references auth.users(id) on delete cascade,lesson_id text not null,skill text not null,correct boolean not null,created_at timestamptz not null default now());
create index if not exists quiz_attempts_user_skill_idx on public.quiz_attempts(user_id,skill,created_at desc);
create table if not exists public.chapter_test_attempts(id bigint generated always as identity primary key,user_id uuid not null references auth.users(id) on delete cascade,chapter_id text not null,score integer not null check(score>=0),total integer not null check(total>0 and score<=total),created_at timestamptz not null default now());
create index if not exists chapter_tests_user_idx on public.chapter_test_attempts(user_id,created_at desc);
alter table public.profiles enable row level security;alter table public.lesson_progress enable row level security;alter table public.quiz_attempts enable row level security;alter table public.chapter_test_attempts enable row level security;
drop policy if exists "Users manage own profile" on public.profiles;create policy "Users manage own profile" on public.profiles for all using(auth.uid()=id) with check(auth.uid()=id);
drop policy if exists "Users manage own lesson progress" on public.lesson_progress;create policy "Users manage own lesson progress" on public.lesson_progress for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists "Users read own quiz attempts" on public.quiz_attempts;create policy "Users read own quiz attempts" on public.quiz_attempts for select using(auth.uid()=user_id);
drop policy if exists "Users insert own quiz attempts" on public.quiz_attempts;create policy "Users insert own quiz attempts" on public.quiz_attempts for insert with check(auth.uid()=user_id);
drop policy if exists "Users read own chapter tests" on public.chapter_test_attempts;create policy "Users read own chapter tests" on public.chapter_test_attempts for select using(auth.uid()=user_id);
drop policy if exists "Users insert own chapter tests" on public.chapter_test_attempts;create policy "Users insert own chapter tests" on public.chapter_test_attempts for insert with check(auth.uid()=user_id);
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path='' as $$ begin insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'display_name',split_part(new.email,'@',1))) on conflict(id) do nothing;return new;end;$$;
drop trigger if exists on_auth_user_created on auth.users;create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

grant select,insert,update,delete on public.profiles to authenticated;
grant select,insert,update,delete on public.lesson_progress to authenticated;
grant select,insert on public.quiz_attempts to authenticated;
grant select,insert on public.chapter_test_attempts to authenticated;
grant usage,select on all sequences in schema public to authenticated;
