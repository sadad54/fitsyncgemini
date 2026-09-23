# FitSync virtual try-on prototype

## What changed

The active app is **Expo / React Native / TypeScript** in `mobile/`, targeting Android and iOS. The backend is **FastAPI + Supabase Auth/Postgres/Storage**. Root Flutter-era documentation is historical.

The old try-on synchronously called a remote worker, silently substituted a PIL cutout on failure, then inserted a completed session. Its GPU worker used BF16/TF32, coarse MediaPipe polygons and an outdated base model identifier. The mobile screen invented fit scores and changed cosmetic layer/size controls without regenerating the image.

The new flow is:

1. Authenticated mobile upload; backend verifies **every** selected closet item belongs to that user.
2. Decode and normalize photos, strip EXIF, snapshot inputs in private Supabase storage.
3. An atomic Postgres function deduplicates and admits a queued job under tester quotas; HTTP **202** returns its `id` (the job ID).
4. A separate CPU consumer claims a job and calls the configured GPU provider. Jobs survive API/consumer restarts.
5. Mobile polls `GET /api/v1/tryon/{id}` every three seconds while queued/processing. History can reopen the job after navigation or app restart. Errors offer reconnection.
6. Results receive one-hour signed URLs; reopening refreshes URLs. New jobs expire after seven days. The running consumer purges expired/deleted image objects. Legacy sessions remain readable.

**No paid API, GPU deployment, Supabase migration, real-image benchmark, or tester upload was performed by Codex.** The checked-in notebooks and deployment configuration still require execution in your accounts.

## Prototype model choice and garment scope

CatVTON `mix` is the initial candidate, **not a claimed benchmark winner**. Its official automatic mask supports `upper`, `lower`, `overall`. We use DensePose + SCHP and `overall` for dresses, FP16 on one T4, 768×1024 with aspect-preserving padding, 50 steps, seed 42. The model stays loaded in the warm GPU process.

Supported: one dress; one top/outerwear item; one bottom; or a bottom followed by a top. Two-piece generation makes **two** inference calls and can introduce accumulated artifacts. A dress must be selected alone. Shoes, accessories and ambiguous activewear are rejected; they are not silently rendered as shirts. This is visual try-on, not a size/fit measurement or a general multilayer outfit simulator.

IDM-VTON has a separate comparison notebook with CPU offload. Both models see the same prepared photos/masks. This is an engineering comparison using shared preprocessing, not a reproduction of published scores. The standard IDM demo hard-codes an upper-body mask; we do not use that mask for dresses.

## First run: zero-budget Kaggle development

1. Check out this PR branch (`codex/async-vton-prototype`), or merge and pull `main`.
2. In **Supabase → SQL Editor**, run `backend/migrations/20260923_tryon_jobs.sql`. It adds `tryon_jobs`, service-role-only queue RPCs, and a **private** `try-on-private` bucket. It does not migrate/delete legacy sessions or change the existing clothing bucket. Existing `try_on_sessions` and `clothing_items` must already exist.
3. In Kaggle, create a **private** notebook, enable Internet and a T4 accelerator, and import `gpu_worker/notebooks/01_catvton_kaggle.ipynb`. If working after merge, change its `BRANCH` to `main`. Execute setup. It creates an isolated Python 3.11 environment; it does not replace Kaggle's global torch.
4. For quality checks, upload a private, consented test-image dataset and a JSON manifest using `gpu_worker/benchmark_manifest.example.json`. Set `MANIFEST` in the notebook. Review the generated masks and run the CatVTON benchmark. Keep notebook outputs private: they contain photos.
5. For a supervised end-to-end test, add two Kaggle Secrets: `GPU_TRYON_SHARED_SECRET` (32+ random characters) and `NGROK_AUTHTOKEN`. Execute the optional worker/tunnel cells **only if permitted by Kaggle's current policies**. The notebook prints a temporary HTTPS URL. Kaggle quotas, GPU availability, Internet availability and tunnel rules are account/platform-dependent; no production service is promised.
6. Set these in **backend/.env**, alongside your existing Supabase configuration:

   ```dotenv
   ENV=development
   TRYON_PROVIDER=kaggle
   TRYON_ENDPOINT=https://your-current-tunnel-host
   TRYON_SHARED_SECRET=the-same-secret-as-the-worker
   TRYON_NONCOMMERCIAL_ACK=true
   TRYON_MODEL_VERSION=catvton-mix-automask-fp16-v1
   TRYON_TIMEOUT_SECONDS=240
   TRYON_MONTHLY_JOB_LIMIT=100
   TRYON_DAILY_USER_LIMIT=5
   ```

   Keep the Supabase service-role key **only on the backend**. Never copy it into Expo, Kaggle, or the GPU worker.
7. With the existing backend environment activated (Python **3.11+**), open two terminals in `backend/`:

   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

   ```bash
   python -m app.tryon.worker
   ```

   Use one consumer for this small prototype. The API can run without it, but queued jobs will not generate until it starts. Stale queued jobs fail after 30 minutes when maintenance runs; interrupted processing jobs fail after 15 minutes. They are **never automatically replayed**, since an uncertain timeout may already have used compute.
8. Start your existing Expo app with `EXPO_PUBLIC_API_BASE_URL` pointing at the backend computer's LAN IP, as before. Choose a supported closet item, open try-on, take/pick a full-body photo and generate. Expect queued → processing → completed, or an explicit failed result. Reopen through history.
9. Stop the tunnel and notebook worker when finished. Restarting the notebook normally changes the endpoint; update backend config and restart the API/consumer.

The Python dependency files are pinned starter environments checked against upstream APIs, but **not GPU-tested here**. If a Kaggle setup step fails, preserve its exact error; do not blindly upgrade torch/diffusers or install into the backend environment.

## Compare CatVTON and IDM-VTON before choosing quality

Run notebook 01's preparation first, then `02_idm_comparison_kaggle.ipynb` in its **separate Python 3.10 environment**. Preserve `/kaggle/working/vton-prepared` or adjust paths when transferring it to another private session. Stop the CatVTON HTTP worker before IDM to release GPU memory.

Use at least 10 dress cases (short/long hems, sleeved/sleeveless, loose/fitted, patterns/logos) plus tops/bottoms and varied people/lighting. Run seeds 42, 7 and 123. Each model writes images and a CSV containing load time, preprocessing time, inference time, peak allocated VRAM, failures and blank human-review columns. Report first inference separately from later runs. CSV `seconds` excludes shared preparation; add `preprocessing_seconds` for an end-to-end estimate. Load/download/cold-start time is separate. GPU OOM is a failed case, not a passing benchmark.

Blindly rate identity, garment fidelity, hem/sleeves and artifacts (5 = best/no artifacts). Do not accept changed faces or anatomically broken results. Mask inspection is essential for dresses. There is deliberately **no fabricated quality/confidence percentage** in the app.

## Optional Modal prototype hosting — account setup still required

Modal's pricing page checked on 23 September 2026 lists **$30/month included compute** on Starter. This is a credit allowance, **not an unlimited free backend or an automatic $0 spending guarantee**. Do not rely on the handoff's 5–10 second estimate or its 13k–27k images/month projection. CPU/RAM, warm idle time, model downloads and cold starts count too; the measured pipeline may be much slower.

Before deployment, inspect your Modal billing controls. If your account cannot enforce the $0 out-of-pocket constraint, **stay on supervised Kaggle**. Do not enable paid top-ups for this prototype. Application job quotas reduce use but cannot measure or guarantee dollar spend.

When you choose to enable Modal:

1. Install/authenticate the Modal CLI in a separate tools environment.
2. In Modal create a secret named `fitsync-tryon` with `GPU_TRYON_SHARED_SECRET` and `TRYON_NONCOMMERCIAL_ACK=true`. Use the same shared secret as the backend.
3. Create a **Modal Proxy Token** in workspace settings. The deployment requires proxy authentication, so unauthorized requests are rejected before reaching the GPU function. Keep its key/secret on the backend.
4. From repo root run `modal deploy gpu_worker/modal_app.py`. Initial model downloads can exceed a first-request timeout: run one authorized warm-up test and inspect logs before inviting testers. Repeat only after you know the first call has ended.
5. Set `TRYON_PROVIDER=modal`, `TRYON_ENDPOINT=<deployment URL>`, `TRYON_MODAL_KEY=<proxy token ID>`, and `TRYON_MODAL_SECRET=<proxy token secret>`. Restart backend and consumer. Keep prototype licensing opt-in enabled only for permitted use.

The configuration uses one T4, `min_containers=0`, `max_containers=1`, a 30-second scaledown window and a model cache volume. No keep-alive scheduler runs. This is **optional prototype serving**, not a commercial-launch approval. When changing checkpoints, masking, resolution, precision or defaults, change `TRYON_MODEL_VERSION` to invalidate cached results and drain old jobs first.

## Provider boundary and future scaling

Mobile only knows FitSync jobs. `TryOnProvider.generate(person_bytes, garment_bytes, options)` is the one backend inference interface; `KaggleTunnelProvider` and `ModalProvider` implement it, selected by config. The handoff's `submit/status` lifecycle is deliberately owned by the **durable backend queue**, rather than duplicating queues in both backend and ephemeral notebook. A future API adapter can submit/poll a vendor job inside its `generate` implementation without mobile changes. For long-running vendors, extend persisted provider IDs and worker leases before enabling retries; do not add an in-memory job dictionary.

Cache keys include normalized person/garment content, categories, item IDs, seed/steps/guidance, provider and model version. Lookup is scoped to the authenticated user. Atomic admission deduplicates simultaneous requests. It returns the existing job for a cache hit; this does not spend another generation slot. Deleted/expired/failed results are not cache hits. Quotas count admitted jobs including failures/deletions; each job can contain up to two model calls.

Usage query (Supabase SQL Editor):

```sql
select provider, date_trunc('month', created_at) as month,
       count(*) as admitted_jobs,
       count(*) filter (where status='completed') as completed_jobs,
       sum(jsonb_array_length(garments)) as admitted_garment_calls,
       sum(inference_seconds) as worker_wall_seconds
from public.tryon_jobs group by 1,2 order by 2 desc;
```

`inference_seconds` is consumer wall time including network/storage and cold starts, **not billed GPU time**. Reconcile against Modal's dashboard. Before wider testing: test migrations against a staging Supabase project, exercise concurrent consumers against hosted Postgres, enforce retention with an always-running maintenance service, add monitored worker health, and set account-level spend controls. Snapshots uploaded immediately before a backend process crash can be orphaned; audit unreferenced storage folders before broad deployment. This is why this change remains a draft prototype.

## Privacy and launch gate

New personal photos/results are private objects with short-lived signed URLs. No arbitrary person/garment URLs are accepted by the worker API. Input images are decoded, pixel/byte bounded, EXIF-stripped and normalized. Photo deletion is retried by the consumer on storage failure. Retention cleanup requires the consumer to be running; expiry hides photos from the API even if cleanup is delayed. Old public-bucket photos are not retrospectively made private; audit them before real testers use the app.

Both CatVTON and IDM-VTON upstream code/checkpoints are CC BY-NC-SA 4.0. Preserve upstream notices. This integration does not grant commercial rights or relicense their materials. **Free-to-use is not synonymous with non-commercial**: a free beta intended for business benefit also needs license review before external distribution. Obtain permission or replace the model/provider with a commercially permitted route before launch. Dataset terms must be reviewed separately; this document makes no blanket claim that all trained weights automatically inherit a dataset's license.

## Validation

- Backend/router/GPU contract tests: `python -m pytest backend/tryon_tests gpu_worker/tests --confcutdir=backend/tryon_tests -q`.
- SQL behavior: install `@electric-sql/pglite`, then run `backend/tryon_tests/queue.mjs` (setup command in that file). Runs the real migration twice and checks deduplication, quotas, owner scoping, claims, stale failures and service-role restrictions. It is not a substitute for hosted multi-process concurrency testing.
- Mobile: `cd mobile && npm run typecheck`. The existing package set needs `npm install --legacy-peer-deps` with npm because its test-renderer peer dependency floats beyond the pinned React version; no production dependencies were changed here.
- Python bytecode compilation and notebook JSON/code-cell parsing.
- Not executed here: CUDA inference/benchmarks, Modal image build/deploy, hosted Supabase migration, device/UI end-to-end test.

## Primary references checked

- https://github.com/Zheng-Chong/CatVTON (automatic masking, model identifiers, licensing)
- https://github.com/yisol/IDM-VTON (DressCode inference and licensing)
- https://modal.com/pricing (current credits; verify again before deployment)
- https://modal.com/docs/guide/webhooks (ASGI deployment)
- https://modal.com/docs/guide/webhook-proxy-auth (proxy authentication)
