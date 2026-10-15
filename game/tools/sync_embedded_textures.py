"""Put authoritative WIP textures into embedded GLB data and import images.

The checkpoint's external PNGs are newer than some embedded image bytes.
Keeping both representations in sync prevents a clean import from reverting
the clothing palette. No pixel content is generated or altered here.
"""
from pathlib import Path
import json,struct,shutil
root=Path(__file__).resolve().parents[1]/'assets/characters'
for name in ['Alina','Kruglik','Krysyuk']:
 path=root/('Refined_'+name+'.glb');raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+length]);binary=raw[28+length:]
 replacement={}
 for image in doc['images']:
  source=root/('Real_'+name+'_'+image['name']+'.png')
  if source.exists():
   replacement[image['bufferView']]=source.read_bytes()
   target=root/('Refined_'+name+'_'+image['name']+'.png');shutil.copyfile(source,target)
 packed=bytearray()
 for i,view in enumerate(doc['bufferViews']):
  start=view.get('byteOffset',0);data=replacement.get(i,binary[start:start+view['byteLength']]);view['byteOffset']=len(packed);view['byteLength']=len(data);packed.extend(data)
  while len(packed)%4:packed.append(0)
 doc['buffers'][0]['byteLength']=len(packed)
 j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
 path.write_bytes(struct.pack('<4sII',b'glTF',2,12+8+len(j)+8+len(packed))+struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(packed),b'BIN\0')+packed)
 print('Synchronized',name,len(replacement),'images')
