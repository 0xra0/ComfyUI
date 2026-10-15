#!/usr/bin/env bash
set -euo pipefail
cd /mnt/ssd/ComfyUI
export OMP_NUM_THREADS=8
export MKL_NUM_THREADS=8
export OPENBLAS_NUM_THREADS=8
export PYTHONPATH=/mnt/ssd/ComfyUI/.runtime-deps${PYTHONPATH:+:$PYTHONPATH}
export LD_LIBRARY_PATH=/mnt/ssd/ComfyUI/.runtime-deps/llama_cpp/lib:/opt/rocm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PYTORCH_ALLOC_CONF=expandable_segments:True
exec /mnt/ssd/conda-envs/ComfyUI/bin/python3.12 main.py --listen 127.0.0.1 --port 8188 --preview-method none --reserve-vram 2 --disable-dynamic-vram --disable-async-offload --disable-pinned-memory --cpu-vae --fp32-vae --enable-manager
