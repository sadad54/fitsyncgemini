-- Community, challenges and follows: the tables behind /api/v1/community.
-- Safe to run more than once, and safe on a project that already has some of
-- these tables: it only adds what is missing.
--
-- Every read and write goes through the FastAPI service (service_role), which
-- applies ownership checks, so the anon/authenticated roles get no direct access.
begin;

create table if not exists public.style_challenges (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    description text,
    image_url text,
    color text,
    reward text,
    difficulty_level text default 'medium',
    category text,
    participants_count integer not null default 0,
    start_date timestamptz,
    end_date timestamptz,
    active boolean not null default true,
    created_at timestamptz not null default now()
);

create table if not exists public.community_posts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null,
    created_at timestamptz not null default now()
);
alter table public.community_posts add column if not exists caption text not null default '';
alter table public.community_posts add column if not exists image_url text;
alter table public.community_posts add column if not exists tags text[] not null default '{}';
alter table public.community_posts add column if not exists challenge_id uuid references public.style_challenges(id) on delete set null;
alter table public.community_posts add column if not exists likes_count integer not null default 0;
alter table public.community_posts add column if not exists comments_count integer not null default 0;

create table if not exists public.post_likes (
    id uuid primary key default gen_random_uuid(),
    post_id uuid not null references public.community_posts(id) on delete cascade,
    user_id uuid not null,
    created_at timestamptz not null default now()
);

create table if not exists public.comments (
    id uuid primary key default gen_random_uuid(),
    post_id uuid not null references public.community_posts(id) on delete cascade,
    user_id uuid not null,
    content text not null check (char_length(content) between 1 and 1000),
    created_at timestamptz not null default now()
);

create table if not exists public.user_follows (
    id uuid primary key default gen_random_uuid(),
    follower_id uuid not null,
    followed_id uuid not null,
    created_at timestamptz not null default now(),
    check (follower_id <> followed_id)
);

create table if not exists public.challenge_participants (
    id uuid primary key default gen_random_uuid(),
    challenge_id uuid not null references public.style_challenges(id) on delete cascade,
    user_id uuid not null,
    created_at timestamptz not null default now()
);

-- Tables created by older setups may lack these foreign keys; add them (after
-- dropping orphaned rows) so deleting a post or challenge cleans up after itself.
do $$
declare spec text[];
begin
  foreach spec slice 1 in array array[
    ['post_likes', 'post_id', 'community_posts', 'cascade'],
    ['comments', 'post_id', 'community_posts', 'cascade'],
    ['challenge_participants', 'challenge_id', 'style_challenges', 'cascade'],
    ['community_posts', 'challenge_id', 'style_challenges', 'set null']
  ] loop
    if not exists (
      select 1 from pg_constraint c
      join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any(c.conkey)
      where c.contype = 'f' and c.conrelid = format('public.%I', spec[1])::regclass and a.attname = spec[2]
    ) then
      if spec[4] = 'cascade' then
        execute format('delete from public.%I x where not exists (select 1 from public.%I p where p.id = x.%I)', spec[1], spec[3], spec[2]);
      else
        execute format('update public.%I x set %I = null where %I is not null and not exists (select 1 from public.%I p where p.id = x.%I)',
                       spec[1], spec[2], spec[2], spec[3], spec[2]);
      end if;
      execute format('alter table public.%I add constraint %I foreign key (%I) references public.%I(id) on delete %s',
                     spec[1], spec[1] || '_' || spec[2] || '_fkey', spec[2], spec[3], spec[4]);
    end if;
  end loop;
end $$;

-- Remove duplicates left by older code, then make likes, follows and joins
-- one-per-user at the database level.
delete from public.post_likes a using public.post_likes b
  where a.post_id = b.post_id and a.user_id = b.user_id and a.ctid > b.ctid;
delete from public.user_follows a using public.user_follows b
  where a.follower_id = b.follower_id and a.followed_id = b.followed_id and a.ctid > b.ctid;
delete from public.challenge_participants a using public.challenge_participants b
  where a.challenge_id = b.challenge_id and a.user_id = b.user_id and a.ctid > b.ctid;

create unique index if not exists post_likes_one_per_user on public.post_likes(post_id, user_id);
create unique index if not exists user_follows_once on public.user_follows(follower_id, followed_id);
create unique index if not exists challenge_participants_once on public.challenge_participants(challenge_id, user_id);

-- Indexes for the feed, profile and challenge queries.
create index if not exists community_posts_feed on public.community_posts(created_at desc);
create index if not exists community_posts_author on public.community_posts(user_id, created_at desc);
create index if not exists community_posts_challenge on public.community_posts(challenge_id, created_at desc);
create index if not exists comments_by_post on public.comments(post_id, created_at);
create index if not exists user_follows_followed on public.user_follows(followed_id);

-- Bring stored counters in line with the rows (the API keeps them in sync after this).
update public.community_posts p set
  likes_count = (select count(*) from public.post_likes l where l.post_id = p.id),
  comments_count = (select count(*) from public.comments c where c.post_id = p.id);
update public.style_challenges s set
  participants_count = (select count(*) from public.challenge_participants cp where cp.challenge_id = s.id);

do $$
declare t text;
begin
  foreach t in array array['style_challenges','community_posts','post_likes','comments','user_follows','challenge_participants'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant all on public.%I to service_role', t);
  end loop;
end $$;

commit;
