# ComfyUI — Local ROCm Fork (0xra0)

> **Base:** [comfyanonymous/ComfyUI](https://github.com/comfyanonymous/ComfyUI) **v0.38.0**  
> **Branch:** `local-rocm` — AMD ROCm / gfx1030 (RX 6800) patches on top of upstream.

This fork contains a focused set of changes on top of ComfyUI v0.38.0 that make
ComfyUI work reliably on **AMD ROCm with 16 GB VRAM (gfx1030 / RX 6800)**, including
a Pixal3D-GGUF MultiView projected-conditioning fix and an optimised launch script.

---

## What's Different from Upstream

### 1. `main.py` — ROCm backend detection for `comfy-aimdo`

Upstream `comfy-aimdo` initialisation does not pass the backend implementation
identifier, so the library may default to CUDA paths that fail silently on ROCm.

The patch reads `torch/version.py` at startup and passes `"rocm"` as the first
positional argument to `comfy_aimdo.control.init()` when a ROCm PyTorch build is
detected.  Fallback chain for older `comfy-aimdo` protocols (0.4.9 / 0.4.10 / 0.5.x)
is preserved.

```python
# Before (upstream)
comfy_aimdo.control.init(simple_vram_headroom=..., nvml_pressure=...)

# After (this fork)
comfy_aimdo.control.init("rocm", simple_vram_headroom=..., nvml_pressure=...)
```

### 2. `launch_best_cpu_vae.sh` — Optimised ROCm launch script

A single-file launcher that sets up the environment and starts ComfyUI with
settings tuned for ROCm 16 GB VRAM:

| Flag | Reason |
|---|---|
| `--cpu-vae --fp32-vae` | Keeps the VAE on CPU to free VRAM for diffusion |
| `--reserve-vram 2` | Reserves 2 GB for OS / display driver headroom |
| `--disable-dynamic-vram` | Avoids ROCm allocator pressure spikes |
| `--disable-async-offload` | Prevents async offload race conditions on ROCm |
| `--disable-pinned-memory` | Reduces ROCm pinned-memory fragmentation |
| `--preview-method none` | Removes preview decode overhead during generation |
| `--enable-manager` | Enables the ComfyUI-Manager endpoint |
| `PYTORCH_ALLOC_CONF=expandable_segments:False` | Fixes NaN / wrong output on first Trellis2 HR flow forward on ROCm/gfx1030 |
| `OMP_NUM_THREADS=8` | Caps CPU thread count for VAE and CPU-side ops |

### 3. `Pixal3D_GGUF_MultiView_Fix/` — MultiView projected-conditioning fix

A patch directory for the `ComfyUI-Trellis2-GGUF` custom node that fixes
Pixal3D-GGUF MultiView generation on ROCm 16 GB cards.

**What it fixes:**
- Pixal3D-GGUF no longer falls through to TRELLIS generic spatial-blending MultiView sampling.
- Front / left / back / right views are converted to Pixal3D camera poses and fused via `DinoV3ProjMultiViewFeatureExtractor`.
- Fixes the `proj_context=None` / `ProjectAttention` crash.
- Uses sparse-only projected shape/texture conditioning — `R=64/96` no longer allocates a full dense `R³` projected feature tensor on a 16 GB ROCm card.
- NAF stays enabled; in low-VRAM mode its projected path uses tiled NAF.
- Removes deeply interior sparse voxels and aborts pathological dense samples before they consume an hour in Shape SLat.
- Corrects cascade coordinate scaling when `sparse_structure_resolution != 32`.

### 4. `styles/default.csv` — Default style presets

Two style presets shipped with this fork:
- **❌ Low Token** — negative prompt blocking common quality issues.
- **✅ Line Art / Manga** — Anime/manga positive prompt targeting Satoshi Kon, Ken Sugimori, Hiromu Arakawa aesthetics.

---

## Hardware Target

| Component | Spec |
|---|---|
| GPU | AMD Radeon RX 6800 (gfx1030) |
| VRAM | 16 GB |
| ROCm | 6.x / 7.x |
| Python | 3.12 |
| PyTorch | ROCm build |
| OS | Linux |

---

## Installation

### Prerequisites

- Linux with ROCm 6+ drivers installed ([ROCm install guide](https://rocm.docs.amd.com/en/latest/deploy/linux/index.html))
- Conda or a Python 3.12 venv
- At least 16 GB GPU VRAM (or adjust `--reserve-vram` / `--disable-dynamic-vram`)

### 1. Clone this repo

```bash
git clone https://github.com/0xra0/ComfyUI.git
cd ComfyUI
git checkout local-rocm
```

### 2. Create the Python environment

```bash
conda create -n ComfyUI python=3.12
conda activate ComfyUI
```

### 3. Install PyTorch for ROCm

Pick the ROCm wheel matching your ROCm version from [PyTorch's install page](https://pytorch.org/get-started/locally/).  
Example for ROCm 6.2:

```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.2
```

### 4. Install ComfyUI dependencies

```bash
pip install -r requirements.txt
```

### 5. Configure paths

Edit `launch_best_cpu_vae.sh` and update:

```bash
# Line 3: change to your ComfyUI install path
cd /your/path/to/ComfyUI

# Line 7: change to your Python binary
exec /your/path/to/python3.12 main.py ...
```

Or set environment variables at runtime:

```bash
COMFYUI_ROOT=/your/path PYTHON=/your/python launch_best_cpu_vae.sh
```

### 6. Launch

```bash
chmod +x launch_best_cpu_vae.sh
./launch_best_cpu_vae.sh
```

ComfyUI will be available at `http://127.0.0.1:8188` by default.  
Override the port with `COMFY_PORT=9000 ./launch_best_cpu_vae.sh`.

---

## Pixal3D-GGUF MultiView Fix (Optional)

If you use the `ComfyUI-Trellis2-GGUF` custom node with Pixal3D-GGUF weights,
apply the MultiView fix:

### Prerequisites

- `ComfyUI-Trellis2-GGUF` custom node installed under `custom_nodes/`
- Pixal3D-GGUF model weights

### Install

```bash
cd Pixal3D_GGUF_MultiView_Fix
./install.sh
```

The installer:
1. Verifies the custom node is present.
2. Refuses to downgrade a newer installed pipeline (use `FORCE=1` to override).
3. Backs up replaced files as `.before-pixal3d-mv-<timestamp>`.
4. Copies `trellis2_image_to_3d.py`, `model_manager.py`, and `pipeline_mv.json`.
5. Syntax-checks the installed files via `python -m py_compile`.

### Verify

```bash
cd Pixal3D_GGUF_MultiView_Fix
./verify.sh
```

### Expected workflow settings

| Setting | Value |
|---|---|
| Model | Pixal3D-GGUF |
| Format | GGUF Q8\_0 |
| Backend | sdpa |
| Device | cuda (ROCm) |
| `low_vram` | true |
| Views | front, back, left, right |
| `pipeline_type` | 512 |
| `sparse_structure_resolution` | 32 |

Expected log markers after applying the fix:
```
[Pixal3D-GGUF MV] Using camera-projected conditioning
[Pixal3D MV] views=['front', 'left', 'back', 'right']
[Sparse] occupied tokens after shell=...
```

---

## Custom Nodes

**Custom nodes are not included in this repository.**  
Install them separately via [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)
or by cloning them into the `custom_nodes/` directory.

The `.gitignore` already excludes `custom_nodes/` (upstream behaviour).

---

## Relationship to Upstream

This branch tracks **comfyanonymous/ComfyUI v0.38.0** and applies local patches on
top. It is not intended as a general-purpose fork — it is a personal hardware-specific
setup committed for reproducibility and sharing.

Pull requests and issues are welcome for the ROCm-specific patches but feature
requests that belong in upstream ComfyUI should be directed there.

---

## License

[GNU General Public License v3.0](LICENSE) — same as upstream ComfyUI.
