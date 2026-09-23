-- Run once in Supabase SQL editor before starting the new API/consumer.
-- This does not alter the legacy try_on_sessions table or its history.
begin;
create table if not exists public.tryon_jobs (
    id uuid primary key,
    user_id uuid not null,
    item_ids jsonb not null,
    status text not null default 'queued' check (status in ('queued','processing','completed','failed')),
    provider text not null,
    model_version text not null,
    cache_key text not null,
    options jsonb not null,
    garments jsonb not null,
    person_path text not null,
    result_path text,
    error_message text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    started_at timestamptz,
    completed_at timestamptz,
    expires_at timestamptz not null default now() + interval '7 days',
    deleted_at timestamptz,
    purged_at timestamptz,
    inference_seconds double precision
);
create index if not exists tryon_jobs_owner on public.tryon_jobs(user_id, created_at desc);
create index if not exists tryon_jobs_queue on public.tryon_jobs(status, created_at);
create index if not exists tryon_jobs_cache on public.tryon_jobs(user_id, cache_key);
alter table public.tryon_jobs enable row level security;
-- Jobs are managed solely through authenticated FastAPI routes using service_role.
revoke all on public.tryon_jobs from anon, authenticated;
grant all on public.tryon_jobs to service_role;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('try-on-private', 'try-on-private', false, 10485760, array['image/jpeg'])
on conflict (id) do update set public = false;

create or replace function public.enqueue_tryon(p_job jsonb, p_monthly_limit int, p_daily_limit int)
returns setof public.tryon_jobs language plpgsql security definer set search_path = public as $$
declare cached public.tryon_jobs; uid uuid := (p_job->>'user_id')::uuid;
begin
    -- Serialize admission, so concurrent uploads cannot bypass cache/quotas.
    perform pg_advisory_xact_lock(71923001);
    select * into cached from tryon_jobs
      where user_id = uid and cache_key = p_job->>'cache_key'
        and deleted_at is null and expires_at > now()
        and status in ('queued','processing','completed')
      order by created_at desc limit 1;
    if found then return next cached; return; end if;
    -- Count admitted jobs, including failures and deletions, conservatively.
    -- A job can contain up to two model calls. This is NOT a dollar budget.
    if (select count(*) from tryon_jobs where created_at >= date_trunc('month', now() at time zone 'UTC') at time zone 'UTC') >= p_monthly_limit
       or (select count(*) from tryon_jobs where user_id = uid and created_at >= now() - interval '24 hours') >= p_daily_limit then
        raise exception 'TRYON_QUOTA_EXCEEDED';
    end if;
    if exists (select 1 from tryon_jobs where user_id = uid and deleted_at is null and status in ('queued','processing')) then
        raise exception 'TRYON_ALREADY_ACTIVE';
    end if;
    return query insert into tryon_jobs(id,user_id,item_ids,provider,model_version,cache_key,options,garments,person_path)
    values ((p_job->>'id')::uuid,uid,p_job->'item_ids',p_job->>'provider',p_job->>'model_version',
            p_job->>'cache_key',p_job->'options',p_job->'garments',p_job->>'person_path') returning *;
end;
$$;

create or replace function public.claim_tryon(p_provider text, p_model_version text)
returns setof public.tryon_jobs language plpgsql security definer set search_path = public as $$
begin
    -- Never replay uncertain inference after a crash: fail it after 15 minutes.
    update tryon_jobs set status='failed', error_message='Generation was interrupted. Please try again.', updated_at=now()
      where status='processing' and started_at < now() - interval '15 minutes';
    update tryon_jobs set status='failed', error_message='The prototype worker was unavailable. Please try again.', updated_at=now()
      where status='queued' and created_at < now() - interval '30 minutes';
    return query update tryon_jobs set status='processing', started_at=now(), updated_at=now()
      where id = (select id from tryon_jobs where status='queued' and deleted_at is null
        and provider=p_provider and model_version=p_model_version and expires_at > now()
        order by created_at for update skip locked limit 1)
      returning *;
end;
$$;
revoke all on function public.enqueue_tryon(jsonb,int,int) from public, anon, authenticated;
revoke all on function public.claim_tryon(text,text) from public, anon, authenticated;
grant execute on function public.enqueue_tryon(jsonb,int,int) to service_role;
grant execute on function public.claim_tryon(text,text) to service_role;
commit;
