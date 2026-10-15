#!/usr/bin/env bash
set -euo pipefail

# Is the Pixal3D-GGUF MultiView fix in place on THIS box? Override COMFYUI_ROOT / PYTHON.
COMFY="${COMFYUI_ROOT:-/mnt/ssd/ComfyUI}"
NODE="$COMFY/custom_nodes/ComfyUI-Trellis2-GGUF"
PIPE="$NODE/trellis2_gguf/pipelines/trellis2_image_to_3d.py"
MM="$NODE/model_manager.py"
MV_CFG="$COMFY/models/Pixal3D-GGUF/pipeline_mv.json"
PY="${PYTHON:-/mnt/ssd/conda-envs/ComfyUI/bin/python3.12}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for f in "$PIPE" "$MM"; do
  [[ -f "$f" ]] || { echo "MISSING $f - the fix is not installed"; exit 1; }
done
"$PY" -m py_compile "$PIPE" "$MM"

grep -q 'def run_pixal3d_multiview' "$PIPE"
grep -q 'def get_proj_cond_shape_mv' "$PIPE"
grep -q "if getattr(self, 'isPixal3D', False):" "$PIPE"
grep -q 'Pixal3D-GGUF-MV' "$MM"
[[ -f "$MV_CFG" ]] || echo "NOTE: no $MV_CFG (only needed once official *_mv weights are converted to GGUF)"

# A different installed file is normal here: newer patches sit on top of this folder's fix.
if cmp -s "$PIPE" "$HERE/trellis2_image_to_3d.py"; then
  echo "pipeline content: identical to this folder's copy"
elif [[ "$PIPE" -nt "$HERE/trellis2_image_to_3d.py" ]]; then
  echo "pipeline content: NEWER than this folder - later patches installed on top (expected on this box)"
else
  echo "pipeline content: OLDER than this folder and different - ./install.sh would upgrade it"
fi
echo "OK: Pixal3D GGUF projected MultiView code is installed."
