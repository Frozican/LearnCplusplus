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

-- Friends: authenticated users can discover usernames; relationships stay private to participants.
alter table public.profiles add column if not exists username text;
update public.profiles set username = left(coalesce(nullif(lower(regexp_replace(coalesce(display_name,'learner'),'[^a-zA-Z0-9_]','','g')),''),'learner'),15) || '_' || substr(id::text,1,4) where username is null;
alter table public.profiles alter column username set not null;
alter table public.profiles drop constraint if exists profiles_username_format;
alter table public.profiles add constraint profiles_username_format check(username ~ '^[a-z0-9_]{3,24}$');
create unique index if not exists profiles_username_lower_unique on public.profiles(lower(username));
drop policy if exists "Authenticated users can discover profiles" on public.profiles;
create policy "Authenticated users can discover profiles" on public.profiles for select to authenticated using(true);
create table if not exists public.friend_requests(id uuid primary key default gen_random_uuid(),requester_id uuid not null references auth.users(id) on delete cascade,recipient_id uuid not null references auth.users(id) on delete cascade,status text not null default 'pending' check(status in ('pending','accepted','declined')),created_at timestamptz not null default now(),updated_at timestamptz not null default now(),constraint friend_requests_not_self check(requester_id<>recipient_id));
create unique index if not exists friend_requests_pair_unique on public.friend_requests(least(requester_id,recipient_id),greatest(requester_id,recipient_id));
create index if not exists friend_requests_recipient_status_idx on public.friend_requests(recipient_id,status,created_at desc);
create index if not exists friend_requests_requester_status_idx on public.friend_requests(requester_id,status,created_at desc);
alter table public.friend_requests enable row level security;
drop policy if exists "Users can view their own friend requests" on public.friend_requests;
create policy "Users can view their own friend requests" on public.friend_requests for select to authenticated using((select auth.uid())=requester_id or (select auth.uid())=recipient_id);
drop policy if exists "Users can send friend requests" on public.friend_requests;
create policy "Users can send friend requests" on public.friend_requests for insert to authenticated with check((select auth.uid())=requester_id and status='pending');
drop policy if exists "Recipients can respond to friend requests" on public.friend_requests;
create policy "Recipients can respond to friend requests" on public.friend_requests for update to authenticated using((select auth.uid())=recipient_id and status='pending') with check((select auth.uid())=recipient_id and status in ('accepted','declined'));
drop policy if exists "Participants can remove friendships" on public.friend_requests;
create policy "Participants can remove friendships" on public.friend_requests for delete to authenticated using((select auth.uid())=requester_id or (select auth.uid())=recipient_id);
create or replace function public.guard_friend_request_update() returns trigger language plpgsql set search_path='' as $$
begin
if new.requester_id<>old.requester_id or new.recipient_id<>old.recipient_id then raise exception 'Friend request participants cannot be changed'; end if;
if old.status<>'pending' or new.status not in ('accepted','declined') then raise exception 'Only pending requests can be accepted or declined'; end if;
new.updated_at:=pg_catalog.now();return new;end;$$;
drop trigger if exists friend_request_update_guard on public.friend_requests;
create trigger friend_request_update_guard before update on public.friend_requests for each row execute function public.guard_friend_request_update();
grant select,update on public.profiles to authenticated;
grant select,insert,update,delete on public.friend_requests to authenticated;

-- Friends may see only the learning activity needed for XP and streak comparisons.
drop policy if exists "Friends can view shared lesson progress" on public.lesson_progress;
create policy "Friends can view shared lesson progress" on public.lesson_progress for select to authenticated
using (user_id=(select auth.uid()) or exists(select 1 from public.friend_requests fr where fr.status='accepted' and ((fr.requester_id=(select auth.uid()) and fr.recipient_id=lesson_progress.user_id) or (fr.recipient_id=(select auth.uid()) and fr.requester_id=lesson_progress.user_id))));
drop policy if exists "Friends can view shared chapter tests" on public.chapter_test_attempts;
create policy "Friends can view shared chapter tests" on public.chapter_test_attempts for select to authenticated
using (user_id=(select auth.uid()) or exists(select 1 from public.friend_requests fr where fr.status='accepted' and ((fr.requester_id=(select auth.uid()) and fr.recipient_id=chapter_test_attempts.user_id) or (fr.recipient_id=(select auth.uid()) and fr.requester_id=chapter_test_attempts.user_id))));

-- Public profile pictures; only each owner can upload, replace, or delete their own files.
alter table public.profiles add column if not exists avatar_url text;
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('avatars','avatars',true,2097152,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=true,file_size_limit=2097152,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists "Users upload own profile avatars" on storage.objects;
create policy "Users upload own profile avatars" on storage.objects for insert to authenticated with check(bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "Users update own profile avatars" on storage.objects;
create policy "Users update own profile avatars" on storage.objects for update to authenticated using(bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text) with check(bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists "Users delete own profile avatars" on storage.objects for delete to authenticated using(bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
