"""Audit the exported GLB, including actual vertex weights, not Blender groups."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import numpy as np

path = Path(__file__).resolve().parents[1] / 'game/assets/characters/studies/AlinaRevision.glb'
raw = path.read_bytes()
json_length = struct.unpack_from('<I', raw, 12)[0]
doc = json.loads(raw[20:20 + json_length])
binary = raw[28 + json_length:]

def array(index):
    accessor = doc['accessors'][index]
    view = doc['bufferViews'][accessor['bufferView']]
    width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[accessor['type']]
    dtype = np.dtype({5126: '<f4', 5125: '<u4', 5123: '<u2', 5121: 'u1'}[accessor['componentType']])
    return np.ndarray((accessor['count'], width), dtype=dtype, buffer=binary,
                      offset=view.get('byteOffset', 0) + accessor.get('byteOffset', 0),
                      strides=(view.get('byteStride', width * dtype.itemsize), dtype.itemsize))

expected = {'dislike', 'eat', 'getup', 'happy', 'idle', 'sit', 'sit_down', 'walk', 'wave'}
clips = {clip['name'] for clip in doc.get('animations', [])}
if clips != expected:
    raise RuntimeError(f'Animation library differs: {clips}')
head_node = next(node for node in doc['nodes'] if node.get('name') == 'AlinaRevisionHead')
mesh = doc['meshes'][head_node['mesh']]
skin = doc['skins'][head_node['skin']]
joint_names = [doc['nodes'][index]['name'] for index in skin['joints']]
head_index = joint_names.index('Head')
if len(joint_names) != 63:
    raise RuntimeError('Expected the complete 63-bone character rig')
shapes = mesh['extras']['targetNames']
for name in ['eyeBlinkLeft', 'eyeBlinkRight', 'mouthSmileLeft', 'mouthSmileRight', 'jawOpen']:
    if name not in shapes:
        raise RuntimeError(f'Missing game expression: {name}')
if len(shapes) != 63:
    raise RuntimeError('Facial shapes were dropped')
rigid = []
for primitive in mesh['primitives']:
    name = doc['materials'][primitive['material']]['name']
    weights = array(primitive['attributes']['WEIGHTS_0'])
    joints = array(primitive['attributes']['JOINTS_0'])
    if not np.isfinite(weights).all() or np.max(np.abs(weights.sum(axis=1) - 1.0)) > 0.001:
        raise RuntimeError(f'Unbound or unnormalised vertices in {name}')
    if name != 'Head':
        minimum = float(np.sum(np.where(joints == head_index, weights, 0), axis=1).min())
        if minimum < 0.999:
            raise RuntimeError(f'{name} incorrectly follows the neck: Head weight {minimum}')
        rigid.append({'material': name, 'vertices': len(weights), 'minimum_head_weight': minimum})
result = {'file': str(path), 'sha256': hashlib.sha256(raw).hexdigest(),
          'bones': len(joint_names), 'facial_shapes': len(shapes), 'clips': sorted(clips),
          'rigid_surfaces': rigid, 'status': 'PASS',
          'limitation': 'Export integrity only, not an artistic acceptance of anatomy or animation'}
print(json.dumps(result, ensure_ascii=False, indent=2))
