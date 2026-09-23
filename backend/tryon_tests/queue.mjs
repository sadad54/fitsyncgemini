// npm install --prefix /tmp/vton-db-test @electric-sql/pglite
// PGLITE_MODULE=/tmp/vton-db-test/node_modules/@electric-sql/pglite/dist/index.js node backend/tryon_tests/queue.mjs
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const { PGlite } = await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
await db.exec(`create role anon; create role authenticated; create role service_role;
create schema storage; create table storage.buckets(id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]);`);
const migration = await readFile(new URL('../migrations/20260923_tryon_jobs.sql',import.meta.url),'utf8');
await db.exec(migration);
await db.exec(migration); // Rerunnable.
let assertions = 0;
function check(value) { assert.ok(value); assertions++; }
const uid='00000000-0000-0000-0000-000000000001';
function job(n, user=uid, key=`cache-${n}`) {
 return {id:`00000000-0000-0000-0000-${String(n).padStart(12,'0')}`,user_id:user,item_ids:[],provider:'kaggle',model_version:'v1',cache_key:key,options:{},garments:[],person_path:`${user}/${n}/person.jpg`};
}
async function enqueue(j,monthly=100,daily=5) {
 return (await db.query('select * from enqueue_tryon($1::jsonb,$2,$3)',[JSON.stringify(j),monthly,daily])).rows;
}
const first=(await enqueue(job(1)))[0]; check(first.status==='queued');
check((await enqueue(job(2,uid,'cache-1')))[0].id===first.id);
await assert.rejects(enqueue(job(3)),/TRYON_ALREADY_ACTIVE/); assertions++;
check((await db.query("select * from claim_tryon('modal','v1')")).rows.length===0);
check((await db.query("select * from claim_tryon('kaggle','v1')")).rows[0].status==='processing');
check((await db.query("select * from claim_tryon('kaggle','v1')")).rows.length===0);
await db.query("update tryon_jobs set status='completed' where id=$1",[first.id]);
check((await enqueue(job(4,uid,'cache-1')))[0].id===first.id);
// User-scoped cache: same digest from another user must be a different job.
const other='00000000-0000-0000-0000-000000000099';
check((await enqueue(job(5,other,'cache-1')))[0].id!==first.id);
await db.query('update tryon_jobs set deleted_at=now() where id=$1',[first.id]);
await assert.rejects(enqueue(job(6),100,1),/TRYON_QUOTA_EXCEEDED/); assertions++;
await assert.rejects(enqueue(job(7),2,5),/TRYON_QUOTA_EXCEEDED/); assertions++;
// Crash claims fail rather than invoke GPU a second time.
await db.query("update tryon_jobs set status='processing', started_at=now()-interval '16 minutes' where user_id=$1",[other]);
await db.query("select * from claim_tryon('kaggle','v1')");
check((await db.query('select status from tryon_jobs where user_id=$1',[other])).rows[0].status==='failed');
const expired=(await enqueue(job(8)))[0];
await db.query("update tryon_jobs set created_at=now()-interval '31 minutes' where id=$1",[expired.id]);
check((await db.query("select * from claim_tryon('kaggle','v1')")).rows.length===0);
check((await db.query('select status from tryon_jobs where id=$1',[expired.id])).rows[0].status==='failed');
await db.exec('set role authenticated');
await assert.rejects(db.query('select * from tryon_jobs'),/permission denied/); assertions++;
await assert.rejects(db.query("select * from claim_tryon('kaggle','v1')"),/permission denied/); assertions++;
await db.exec('reset role');
check((await db.query("select public from storage.buckets where id='try-on-private'")).rows[0].public===false);
await db.close();
console.log(`${assertions} queue assertions passed (Postgres via PGlite)`);
