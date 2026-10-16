"""Prepare a static CC0 alternative head for renderer comparison, not an NPC replacement.

Run in Blender 4.5.3 with -- --source=/path/Selunae.blend.
The original download is never overwritten. Author: Muhammed Ismayil (BlenderKit).
The sculpt, UVs and hair cards remain original; Blender node groups are replaced by
portable PBR materials. Source facial controls/constraints are NOT exported here.
"""
import bmesh
import bpy
import hashlib
from pathlib import Path
import sys

source = next((arg.split('=', 1)[1] for arg in sys.argv if arg.startswith('--source=')), '')
if not source:
    raise RuntimeError('Provide --source=/path/to/Selunae.blend')
if hashlib.sha256(Path(source).read_bytes()).hexdigest() != '7174f9b6f38b5c98a5456881cab888384a40d1d37a173f018d12f34f912e442e':
    raise RuntimeError('Unexpected source hash')
bpy.ops.wm.open_mainfile(filepath=source)
ob = bpy.data.objects['Selunae Body']
keep = {'Head', 'Hair', 'Eye Lashes', 'Eye Bros', 'Mouth', 'Waterline',
        'Tiny Sclera 1.3 (Real Light Blue)'}
bm = bmesh.new()
bm.from_mesh(ob.data)
bmesh.ops.delete(bm, geom=[f for f in bm.faces if ob.data.materials[f.material_index].name not in keep], context='FACES')
bm.to_mesh(ob.data)
bm.free()
# The bust is a shape/material candidate. No claim that its Blender facial rig
# already works in the game; export neutral bind geometry without those controls.
for modifier in list(ob.modifiers):
    ob.modifiers.remove(modifier)
ob.parent = None
ob.location.z += 0.17
ob.name = 'AlternativeHeadStudy'
for name in [layer.name for layer in ob.data.uv_layers]:
    if name not in {'UVMap', 'UVMap_Tangent'} and name in ob.data.uv_layers:
        ob.data.uv_layers.remove(ob.data.uv_layers[name])
for mat in ob.data.materials:
    if mat.name not in keep:
        continue
    nodes = mat.node_tree.nodes
    nodes.clear()
    output = nodes.new('ShaderNodeOutputMaterial')
    shader = nodes.new('ShaderNodeBsdfPrincipled')
    mat.node_tree.links.new(shader.outputs['BSDF'], output.inputs['Surface'])
    shader.inputs['Metallic'].default_value = 0
    shader.inputs['Roughness'].default_value = 0.5
    def texture(name, socket, uv='UVMap', normal=False):
        node = nodes.new('ShaderNodeTexImage')
        node.image = bpy.data.images[name]
        coord = nodes.new('ShaderNodeUVMap')
        coord.uv_map = uv
        mat.node_tree.links.new(coord.outputs['UV'], node.inputs['Vector'])
        value = node.outputs['Color']
        if normal:
            node.image.colorspace_settings.name = 'Non-Color'
            decoder = nodes.new('ShaderNodeNormalMap')
            decoder.uv_map = uv
            decoder.inputs['Strength'].default_value = 0.55
            mat.node_tree.links.new(value, decoder.inputs['Color'])
            value = decoder.outputs['Normal']
        mat.node_tree.links.new(value, shader.inputs[socket])
    if mat.name == 'Head':
        texture('Girl Colour.jpg', 'Base Color')
        texture('Girl Normal', 'Normal', normal=True)
        texture('Girl Roughness.jpg', 'Roughness')
    elif mat.name in {'Hair', 'Eye Lashes', 'Eye Bros'}:
        shader.inputs['Base Color'].default_value = (0.025, 0.014, 0.010, 1)
        texture('Eye Bros_Depth.png', 'Alpha')
        texture('Eye Bros_Normal.png', 'Normal', uv='UVMap_Tangent', normal=True)
        mat.surface_render_method = 'DITHERED'
        mat.use_backface_culling = False
        shader.inputs['Roughness'].default_value = 0.48
    elif mat.name == 'Mouth':
        texture('Mouth Colour.jpg', 'Base Color')
        texture('Mouth Normal', 'Normal', normal=True)
    elif mat.name == 'Waterline':
        shader.inputs['Base Color'].default_value = (0.27, 0.12, 0.10, 1)
        shader.inputs['Roughness'].default_value = 0.28
    else:
        shader.inputs['Base Color'].default_value = (0.62, 0.63, 0.58, 1)
        shader.inputs['Roughness'].default_value = 0.15
bpy.ops.object.select_all(action='DESELECT')
ob.select_set(True)
bpy.context.view_layer.objects.active = ob
output = Path(__file__).resolve().parents[2] / 'assets/characters/studies'
output.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(output / 'AlternativeHeadStudy.glb'), export_format='GLB',
                          use_selection=True, export_animations=False, export_skins=False,
                          export_extras=False, export_all_vertex_colors=False,
                          export_active_vertex_color_when_no_material=False,
                          export_try_sparse_sk=True, export_try_omit_sparse_sk=True)
print('ALTERNATIVE_HEAD_STUDY_EXPORTED', flush=True)
