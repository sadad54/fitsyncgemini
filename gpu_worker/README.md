# GPU try-on worker

A small FastAPI service that runs [CatVTON](https://github.com/Zheng-Chong/CatVTON)
(the lightest mainstream open-source virtual try-on diffusion model — 899M
params, ~35s per image on a regular GPU at 1024×768) for FitSync's virtual
try-on feature. This is separate, deployable code — it does **not** run on
the same machine as `backend/`, and `backend/` calls it over the network
(see "Wiring it to the main backend" below).

**Read this before you start:** everything about the CatVTON install steps
and model IDs below was verified against the upstream project's README/
INSTALL.md. What is **not** verified — because it depends on your
university's specific cluster — is whether you're allowed to run a
persistent background service on it, whether Tailscale (or any tunnel tool)
is installable there, and whether the network path actually works. Confirm
those with your cluster's policies before relying on this for anything.

## 1. On the GPU cluster (via AnyDesk)

```bash
# Environment
conda create -n fitsync-tryon python=3.10
conda activate fitsync-tryon

# Check your CUDA version first
nvidia-smi

# Install torch matching that CUDA version — pick the right command from
# https://pytorch.org/get-started/locally/, e.g. for CUDA 12.1:
pip install torch --index-url https://download.pytorch.org/whl/cu121

# This service's own dependencies
cd gpu_worker
pip install -r requirements.txt

# CatVTON itself — not pip-installable, clone it alongside this file
git clone https://github.com/Zheng-Chong/CatVTON.git
pip install -r CatVTON/requirements.txt
```

Model weights (`runwayml/stable-diffusion-inpainting`, ~4GB, and
`zhengchong/CatVTON`) download automatically from Hugging Face the first
time the service starts, then cache locally — that first startup will be
slow, subsequent ones fast.

Set the shared secret (pick any long random string — this is what stops
anyone else on your Tailscale network from calling your GPU for free):

```bash
export GPU_TRYON_SHARED_SECRET="<pick something long and random>"
```

Start the service:

```bash
uvicorn app:app --host 0.0.0.0 --port 8100
```

Verify locally on the cluster machine first, before involving the tunnel at all:

```bash
curl http://127.0.0.1:8100/health
# expect: {"status":"ok"}
```

## 2. Tunnel setup (Tailscale)

Install Tailscale on **both** the cluster machine and the machine running
`backend/`, and sign both into the same Tailscale account/network
(tailscale.com — free tier is fine for this). Once connected, Tailscale
gives the cluster machine a stable private address like `100.x.y.z` that
`backend/` can reach directly, without any port-forwarding or opening
inbound ports on the university's firewall — Tailscale handles NAT
traversal from the client side.

```bash
# On the cluster (via AnyDesk)
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
tailscale ip -4   # note this address, e.g. 100.101.102.103
```

```powershell
# On the backend machine (Windows) — install from tailscale.com/download,
# then sign in via the tray app, same account.
```

From the backend machine, confirm you can actually reach the cluster:

```bash
curl http://100.101.102.103:8100/health
```

If that doesn't work, this is a cluster-network-policy problem to resolve
with your university's IT/HPC support, not something to debug in this code.

## 3. Wiring it to the main backend

In `backend/.env`:

```
GPU_TRYON_URL=http://100.101.102.103:8100
GPU_TRYON_SHARED_SECRET=<the same string you set on the cluster>
```

Leave `GPU_TRYON_URL` empty (the default) to disable this entirely —
`backend/app/services/tryon_service.py` falls back to the local PIL
compositor automatically whenever the GPU worker is unset, unreachable, or
times out, so try-on keeps working even when you're not connected to the
cluster.

## Known limitations, honestly

- This only works while your AnyDesk/cluster session is active and the
  `uvicorn` process is still running there. Disconnecting or the cluster
  reclaiming your session kills it.
- The mask fed to CatVTON is generated from MediaPipe pose landmarks
  (`masking.py`), not full human parsing (SCHP) like CatVTON's own demo —
  simpler to deploy (no Detectron2), but a coarser garment-region estimate.
  If quality isn't good enough, swapping in real human parsing is the next
  lever to pull.
- CatVTON's own docs cite ~35s per generation on GPU; the main backend's
  timeout for this call is configured longer than that (see
  `GPU_TRYON_TIMEOUT_SECONDS` in `backend/app/core/config.py`) to absorb
  tunnel latency and any queueing on a shared cluster, but a busy shared
  GPU could still exceed it.
