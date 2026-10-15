#!/usr/bin/env bash
set -euo pipefail

# Pixal3D-GGUF MultiView projected-conditioning fix - installer.
#
# THIS BOX (RX 6800 / gfx1030, October 2026): ComfyUI lives in /mnt/ssd/ComfyUI and its
# python is /mnt/ssd/conda-envs/ComfyUI/bin/python3.12. Override with COMFYUI_ROOT=... / PYTHON=...
#
# WARNING: the Trellis2-GGUF node installed here already carries this fix PLUS later patches
# (rocm_safe_bake, v4.12 camera calibration) that are NOT in this folder. A plain reinstall
# would DOWNGRADE them, so this installer refuses when the installed file is newer than the
# folder's copy. Use FORCE=1 to install anyway; every replaced file is kept as a
# .before-pixal3d-mv-<stamp> backup next to itself.

COMFY="${COMFYUI_ROOT:-/mnt/ssd/ComfyUI}"
NODE="$COMFY/custom_nodes/ComfyUI-Trellis2-GGUF"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
PY="${PYTHON:-/mnt/ssd/conda-envs/ComfyUI/bin/python3.12}"
FORCE="${FORCE:-0}"

PIPE_SRC="$HERE/trellis2_image_to_3d.py"
PIPE_DST="$NODE/trellis2_gguf/pipelines/trellis2_image_to_3d.py"
MM_DST="$NODE/model_manager.py"
MV_CFG_DST="$COMFY/models/Pixal3D-GGUF/pipeline_mv.json"

MARKER='def run_pixal3d_multiview'

for f in "$PIPE_DST" "$MM_DST"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing $f - is the ComfyUI-Trellis2-GGUF node installed under $COMFY?" >&2
    exit 1
  fi
done

# Refuse to downgrade: installed pipeline already has the fix and is newer than this folder.
if [[ -f "$PIPE_SRC" ]] && grep -q "$MARKER" "$PIPE_DST" && [[ "$PIPE_DST" -nt "$PIPE_SRC" ]]; then
  echo "REFUSE: the installed pipeline already has the fix and is NEWER than this folder:" >&2
  stat -c '%y %s %n' "$PIPE_DST" "$PIPE_SRC" >&2
  echo "        The installed copy has later patches (rocm_safe_bake, camera calibration) that" >&2
  echo "        this folder predates, so installing now would delete them. Use FORCE=1 to" >&2
  echo "        install anyway; the newer file is kept as .before-pixal3d-mv-$STAMP." >&2
  [[ "$FORCE" == "1" ]] || exit 1
fi

for f in "$PIPE_DST" "$MM_DST"; do
  cp -a "$f" "$f.before-pixal3d-mv-$STAMP"
done

mkdir -p "$(dirname "$MV_CFG_DST")"
if [[ -f "$MV_CFG_DST" ]]; then
  cp -a "$MV_CFG_DST" "$MV_CFG_DST.before-pixal3d-mv-$STAMP"
fi

cp -a "$PIPE_SRC" "$PIPE_DST"
cp -a "$HERE/model_manager.py" "$MM_DST"
cp -a "$HERE/pipeline_mv.json" "$MV_CFG_DST"

"$PY" -m py_compile "$PIPE_DST" "$MM_DST"

echo
echo "Installed Pixal3D-GGUF MultiView projected-conditioning fix."
echo "Backups use suffix: .before-pixal3d-mv-$STAMP"
echo
echo "Immediate mode: keep LoadModel = Pixal3D-GGUF + Q8_0 + sdpa."
echo "The existing MultiView node will now route Pixal3D through camera-projected conditioning."
echo "No PYTORCH_NO_HIP_MEMORY_CACHING=1 is added by this installer."
