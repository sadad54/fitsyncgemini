// npm install --prefix /tmp/vton-db-test @electric-sql/pglite
// PGLITE_MODULE=/tmp/vton-db-test/node_modules/@electric-sql/pglite/dist/index.js node backend/tryon_tests/community.mjs
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const { PGlite } = await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
await db.exec(`create role anon; create role authenticated; create role service_role;`);
let assertions = 0;
const check = (value, message) => { assert.ok(value, message); assertions++; };
const rejects = async (sql, pattern) => { await assert.rejects(db.exec(sql), pattern); assertions++; };

// An older project: community_posts exists without the columns the API needs, and has duplicate likes.
const P = '00000000-0000-0000-0000-0000000000a1', U1 = '00000000-0000-0000-0000-000000000001', U2 = '00000000-0000-0000-0000-000000000002';
await db.exec(`
create table public.community_posts (id uuid primary key default gen_random_uuid(), user_id uuid not null, content text, created_at timestamptz not null default now());
create table public.post_likes (id uuid primary key default gen_random_uuid(), post_id uuid not null, user_id uuid not null);
insert into public.community_posts (id, user_id) values ('${P}', '${U1}');
insert into public.post_likes (post_id, user_id) values ('${P}', '${U2}'), ('${P}', '${U2}');`);

const migration = await readFile(new URL('../migrations/20261103_community.sql', import.meta.url), 'utf8');
await db.exec(migration);
await db.exec(migration); // rerunnable

const cols = (await db.query(`select column_name from information_schema.columns where table_name = 'community_posts'`)).rows.map(r => r.column_name);
for (const c of ['caption', 'tags', 'challenge_id', 'likes_count', 'comments_count']) check(cols.includes(c), `missing column ${c}`);

check((await db.query(`select count(*)::int n from post_likes`)).rows[0].n === 1, 'duplicate likes removed');
check((await db.query(`select likes_count from community_posts where id = $1`, [P])).rows[0].likes_count === 1, 'counter backfilled');

await rejects(`insert into post_likes (post_id, user_id) values ('${P}', '${U2}')`, /duplicate key|unique/i);
await rejects(`insert into user_follows (follower_id, followed_id) values ('${U1}', '${U1}')`, /check/i);
await db.exec(`insert into user_follows (follower_id, followed_id) values ('${U1}', '${U2}')`);
await rejects(`insert into user_follows (follower_id, followed_id) values ('${U1}', '${U2}')`, /duplicate key|unique/i);
await rejects(`insert into comments (post_id, user_id, content) values ('${P}', '${U1}', '')`, /check/i);

const ch = (await db.query(`insert into style_challenges (title) values ('Monochrome week') returning id`)).rows[0].id;
await db.exec(`insert into challenge_participants (challenge_id, user_id) values ('${ch}', '${U1}')`);
await rejects(`insert into challenge_participants (challenge_id, user_id) values ('${ch}', '${U1}')`, /duplicate key|unique/i);

// Deleting a post removes its likes and comments; deleting a challenge un-tags posts.
await db.exec(`insert into comments (post_id, user_id, content) values ('${P}', '${U2}', 'nice')`);
await db.exec(`update community_posts set challenge_id = '${ch}' where id = '${P}'`);
await db.exec(`delete from style_challenges where id = '${ch}'`);
check((await db.query(`select challenge_id from community_posts where id = $1`, [P])).rows[0].challenge_id === null, 'challenge delete sets null');
await db.exec(`delete from community_posts where id = '${P}'`);
check((await db.query(`select (select count(*) from post_likes)::int + (select count(*) from comments)::int n`)).rows[0].n === 0, 'cascade');

// Client roles cannot touch the tables directly.
for (const role of ['anon', 'authenticated']) {
  await db.exec(`set role ${role}`);
  await rejects(`select * from community_posts`, /permission denied/i);
  await db.exec(`reset role`);
}

// A brand-new project gets the same schema, with exactly one foreign key per column.
const fresh = new PGlite();
await fresh.exec(`create role anon; create role authenticated; create role service_role;`);
await fresh.exec(migration);
await fresh.exec(migration);
const fks = (await fresh.query(`select conrelid::regclass::text t, count(*)::int n from pg_constraint where contype = 'f' group by 1 order by 1`)).rows;
check(JSON.stringify(fks) === JSON.stringify([
  { t: 'challenge_participants', n: 1 }, { t: 'comments', n: 1 }, { t: 'community_posts', n: 1 }, { t: 'post_likes', n: 1 }
]), `unexpected foreign keys ${JSON.stringify(fks)}`);

console.log(`community migration: ${assertions} assertions passed`);
