"""Blender: extract unchanged packed JPEG maps from the verified CC0 bark source.
Run with -- --source=/path/European_White_Birch_Bark.blend.
"""
import bpy
import hashlib
from pathlib import Path
import sys

source = next((s.split('=',1)[1] for s in sys.argv if s.startswith('--source=')), '')
if not source or hashlib.sha256(Path(source).read_bytes()).hexdigest() != '2a7ac694bb8d11c2ce65addd2e093ea00b4ec210d2b2d55f809c061252699e9b':
    raise RuntimeError('Provide the verified European White Birch Bark source')
bpy.ops.wm.open_mainfile(filepath=source)
output = Path(__file__).resolve().parents[2] / 'assets/textures/birch_scan'
output.mkdir(parents=True, exist_ok=True)
for name, dest in [('Zilver-Berk_diffuse_8K.jpg','color_8k.jpg'),('Zilver-Berk_Normal_8K.jpg','normal_8k.jpg'),('Zilver-Berk_roughness_8K.jpg','roughness_8k.jpg')]:
    image = bpy.data.images[name]
    if not image.packed_file:
        raise RuntimeError('Missing packed source image: ' + name)
    (output / dest).write_bytes(image.packed_file.data)
    print('BARK_EXTRACTED', dest, flush=True)
