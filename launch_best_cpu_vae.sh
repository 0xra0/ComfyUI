#!/usr/bin/env bash
set -euo pipefail
cd /mnt/ssd/ComfyUI
export OMP_NUM_THREADS=8
export MKL_NUM_THREADS=8
export OPENBLAS_NUM_THREADS=8
export PYTHONPATH=/mnt/ssd/ComfyUI/.runtime-deps${PYTHONPATH:+:$PYTHONPATH}
export LD_LIBRARY_PATH=/mnt/ssd/ComfyUI/.runtime-deps/llama_cpp/lib:/opt/rocm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
# expandable_segments:True corrupts the first Trellis2 HR flow forward on ROCm/gfx1030 (NaN or wrong output
# from identical inputs; passes 1+ are fine). With False all repeat passes are bit-identical. 2026-11-05.
export PYTORCH_ALLOC_CONF=expandable_segments:False
# COMFY_PORT is shared with pa.py's URL (pa.py reads the same variable, default 8188).
exec /mnt/ssd/conda-envs/ComfyUI/bin/python3.12 main.py --listen 127.0.0.1 --port "${COMFY_PORT:-8188}" --preview-method none --reserve-vram 2 --disable-dynamic-vram --disable-async-offload --disable-pinned-memory --cpu-vae --fp32-vae --enable-manager "$@"
