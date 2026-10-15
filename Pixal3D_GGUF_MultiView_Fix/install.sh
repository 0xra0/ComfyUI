#!/usr/bin/env bash
set -euo pipefail

COMFY="${COMFYUI_ROOT:-/mnt/sata/ComfyUI}"
NODE="$COMFY/custom_nodes/ComfyUI-Trellis2-GGUF"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

PIPE_DST="$NODE/trellis2_gguf/pipelines/trellis2_image_to_3d.py"
MM_DST="$NODE/model_manager.py"
MV_CFG_DST="$COMFY/models/Pixal3D-GGUF/pipeline_mv.json"

for f in "$PIPE_DST" "$MM_DST"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing $f" >&2
    exit 1
  fi
  cp -a "$f" "$f.before-pixal3d-mv-$STAMP"
done

mkdir -p "$(dirname "$MV_CFG_DST")"
if [[ -f "$MV_CFG_DST" ]]; then
  cp -a "$MV_CFG_DST" "$MV_CFG_DST.before-pixal3d-mv-$STAMP"
fi

cp -a "$HERE/trellis2_image_to_3d.py" "$PIPE_DST"
cp -a "$HERE/model_manager.py" "$MM_DST"
cp -a "$HERE/pipeline_mv.json" "$MV_CFG_DST"

"${PYTHON:-/mnt/sata/anaconda3/envs/ComfyUI/bin/python3}" -m py_compile "$PIPE_DST" "$MM_DST"

echo
echo "Installed Pixal3D-GGUF MultiView projected-conditioning fix."
echo "Backups use suffix: .before-pixal3d-mv-$STAMP"
echo
echo "Immediate mode: keep LoadModel = Pixal3D-GGUF + Q8_0 + sdpa."
echo "The existing MultiView node will now route Pixal3D through camera-projected conditioning."
echo "No PYTORCH_NO_HIP_MEMORY_CACHING=1 is added by this installer."
