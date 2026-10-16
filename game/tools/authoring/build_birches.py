"""Blender 4.5.3: create three branch/leaf meshes from pinned Sapling white-birch parameters.

Run: blender --background --disable-autoexec --python game/tools/authoring/build_birches.py
Sapling is a separate GPL-2.0-or-later authoring tool; fetched source is checksum checked.
No Sapling program code is packaged in the game. Generated meshes are not scans.
"""
import ast
import hashlib
import json
import os
from pathlib import Path
import sys
import urllib.request

import bpy

ROOT = Path(__file__).resolve().parents[2]
CACHE = Path(os.environ.get('SHASHLIK_AUTHORING_CACHE', '/workspace/.cloud-tools/sapling-authoring'))
SOURCES = json.loads(Path(__file__).with_name('sapling_sources.json').read_text())
for source in SOURCES:
    dest = CACHE / 'add_curve_sapling' / source['file']
    if not dest.exists() or hashlib.sha256(dest.read_bytes()).hexdigest() != source['sha256']:
        request = urllib.request.Request(source['url'], headers={'User-Agent': 'Mozilla/5.0'})
        data = urllib.request.urlopen(request, timeout=60).read()
        if hashlib.sha256(data).hexdigest() != source['sha256']:
            raise RuntimeError('Sapling checksum mismatch: ' + source['file'])
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
sys.path.insert(0, str(CACHE))
import add_curve_sapling
add_curve_sapling.register()
preset = ast.literal_eval((CACHE / 'add_curve_sapling/presets/white_birch.py').read_text())
preset.update(scale=10.0, scaleV=0.0, branches=(0, 45, 25, 0), curveRes=(10, 6, 3, 1),
              baseSplits=0, segSplits=(0.0, 0.15, 0.0, 0.0), ratio=0.012,
              minRadius=0.0008, leafScale=0.105, leafScaleX=0.7, leaves=52,
              bevelRes=1, showLeaves=True)
output = ROOT / 'assets/nature'
output.mkdir(parents=True, exist_ok=True)
manifest = {'generator': 'Blender Sapling Tree Gen 0.3.5, adapted white_birch parameters',
            'blender': bpy.app.version_string, 'sapling_sources': SOURCES,
            'description': 'Generated branch architecture and hexagonal leaf geometry; not photogrammetry.',
            'variants': []}
for index, seed in enumerate([173, 863, 2471], 1):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.curve.tree_add(**dict(preset, seed=seed))
    stats = []
    for ob in list(bpy.context.scene.objects):
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        if ob.type == 'CURVE':
            bpy.ops.object.convert(target='MESH')
            ob = bpy.context.object
            ob.name = 'BirchWood'
        else:
            ob.name = 'BirchLeaves'
        for polygon in ob.data.polygons:
            polygon.use_smooth = ob.name == 'BirchWood'
        ob.data.calc_loop_triangles()
        stats.append({'name': ob.name, 'vertices': len(ob.data.vertices),
                      'triangles': len(ob.data.loop_triangles)})
    bpy.ops.object.select_all(action='SELECT')
    path = output / ('birch_%02d.glb' % index)
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', export_animations=False,
                              export_extras=False)
    manifest['variants'].append({'file': path.name, 'seed': seed, 'meshes': stats,
                                'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                                'bytes': path.stat().st_size})
    print('BIRCH_EXPORTED', path.name, stats, flush=True)
(output / 'BIRCH_MANIFEST.json').write_text(json.dumps(manifest, indent=2) + '\n')
