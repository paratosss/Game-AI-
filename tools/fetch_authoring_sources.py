"""Restore the two pinned CC0 authoring originals outside the game directory.
Uses BlenderKit's public download API; no account, payment or credential is used.
"""
import argparse
import hashlib
import json
from pathlib import Path
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
records = [('Selunae', '7174f9b6f38b5c98a5456881cab888384a40d1d37a173f018d12f34f912e442e'),
           ('European_White_Birch_Bark', '2a7ac694bb8d11c2ce65addd2e093ea00b4ec210d2b2d55f809c061252699e9b')]
args.output.mkdir(parents=True, exist_ok=True)
for name, digest in records:
    dest = args.output / (name + '.blend')
    if dest.exists() and hashlib.sha256(dest.read_bytes()).hexdigest() == digest:
        print('VERIFIED', dest.name)
        continue
    source = json.loads((root / 'game/tools/authoring' / (name+'_source.json')).read_text())
    if source['license'] != 'cc_zero' or not source['isFree']:
        raise RuntimeError('Unexpected source access/license')
    url = source['files'][0]['downloadUrl'] + '?scene_uuid=8cf90e67-92c1-4f60-813b-d1f5d9360d68'
    request = urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0'})
    reply = json.loads(urllib.request.urlopen(request, timeout=60).read())
    request = urllib.request.Request(reply['filePath'], headers={'User-Agent':'Mozilla/5.0'})
    temporary = dest.with_suffix('.blend.tmp')
    checksum = hashlib.sha256()
    with urllib.request.urlopen(request, timeout=120) as response, temporary.open('wb') as target:
        while block := response.read(1024*1024):
            target.write(block)
            checksum.update(block)
    if checksum.hexdigest() != digest:
        temporary.unlink()
        raise RuntimeError('Downloaded source differs: '+name)
    temporary.replace(dest)
    print('RESTORED', dest.name)
