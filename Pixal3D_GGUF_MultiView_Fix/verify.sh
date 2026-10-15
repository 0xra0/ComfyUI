#!/usr/bin/env bash
set -euo pipefail
COMFY="${COMFYUI_ROOT:-/mnt/sata/ComfyUI}"
P="$COMFY/custom_nodes/ComfyUI-Trellis2-GGUF/trellis2_gguf/pipelines/trellis2_image_to_3d.py"
PY="${PYTHON:-/mnt/sata/anaconda3/envs/ComfyUI/bin/python3}"
"$PY" -m py_compile "$P"
grep -q 'def run_pixal3d_multiview' "$P"
grep -q 'def get_proj_cond_shape_mv' "$P"
grep -q "if getattr(self, 'isPixal3D', False):" "$P"
echo "OK: Pixal3D GGUF projected MultiView code is installed."
