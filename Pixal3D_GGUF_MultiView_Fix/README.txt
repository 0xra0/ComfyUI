Pixal3D-GGUF MultiView fix
==========================

What this fixes
---------------
- Pixal3D-GGUF no longer enters TRELLIS generic spatial-blending MultiView sampling.
- Front/left/back/right are converted to Pixal3D camera poses and fused through
  DinoV3ProjMultiViewFeatureExtractor.
- Fixes the proj_context=None / ProjectAttention crash.
- Uses sparse-only projected shape/texture conditioning so R=64/96 does not allocate
  a full dense R^3 projected feature tensor on a 16 GB ROCm card.
- NAF stays enabled. In low-VRAM mode its projected path uses tiled NAF.
- Removes deeply interior sparse voxels and aborts pathological dense samples before
  spending an hour in Shape SLat.
- Corrects cascade coordinate scaling when sparse_structure_resolution != 32.
- Does NOT enable PYTORCH_NO_HIP_MEMORY_CACHING=1.

Install
-------
  cd /path/to/Pixal3D_GGUF_MultiView_Fix
  ./install.sh

Then launch ComfyUI normally with your ROCm command (sdpa + --cpu-vae).

First test
----------
LoadModel:
  modelname: Pixal3D-GGUF
  format: GGUF Q8_0
  backend: sdpa
  device: cuda
  low_vram: true

MultiView:
  front = front image
  back  = back image
  left  = left image
  right = right image
  pipeline_type = 512
  sparse steps = 4
  shape steps = 4
  generate_texture_slat = false
  sparse_structure_resolution = 32

Expected log markers:
  [Pixal3D-GGUF MV] Using camera-projected conditioning
  [Pixal3D MV] views=['front', 'left', 'back', 'right']
  [Sparse] occupied tokens after shell=...

Dedicated official *_mv weights
--------------------------------
pipeline_mv.json is included for later use with converted official TencentARC/Pixal3D
*_mv checkpoints. The immediate compatibility path works with the Pixal3D-GGUF weights
you already have; dedicated *_mv weights should improve fidelity once converted to GGUF.
