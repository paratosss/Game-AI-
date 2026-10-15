#!/bin/bash
set -euo pipefail
mkdir -p /workspace/.cloud-tools/bin
python3 - <<'PY'
from pathlib import Path
import hashlib
import tarfile
import urllib.request

root = Path('/workspace/.cloud-tools/blender-4.5.3')
root.mkdir(parents=True, exist_ok=True)
archive = root / 'blender-4.5.3-linux-x64.tar.xz'
expected = '975c58fcb244273838534bba771e64ad87739216b0f9b39a888531a49a72d845'
if not archive.exists():
    request = urllib.request.Request(
        'https://download.blender.org/release/Blender4.5/' + archive.name,
        headers={'User-Agent': 'Mozilla/5.0'},
    )
    temporary = archive.with_suffix('.download')
    with urllib.request.urlopen(request, timeout=60) as response, temporary.open('wb') as output:
        while chunk := response.read(1024 * 1024):
            output.write(chunk)
    with temporary.open('rb') as stream:
        if hashlib.file_digest(stream, 'sha256').hexdigest() != expected:
            raise RuntimeError('Official Blender archive SHA-256 mismatch')
    temporary.replace(archive)
with archive.open('rb') as stream:
    if hashlib.file_digest(stream, 'sha256').hexdigest() != expected:
        raise RuntimeError('Cached Blender archive SHA-256 mismatch')
binary = root / 'blender-4.5.3-linux-x64/blender'
if not binary.exists():
    with tarfile.open(archive) as package:
        package.extractall(root, filter='data')
print('Official Blender 4.5.3 archive verified')
PY
cat > /workspace/.cloud-tools/bin/blender-4.5.3 <<'BLENDER'
#!/bin/bash
set -euo pipefail
source /workspace/.cloud-tools/godot-env.sh
exec /workspace/.cloud-tools/blender-4.5.3/blender-4.5.3-linux-x64/blender "$@"
BLENDER
chmod +x /workspace/.cloud-tools/bin/blender-4.5.3
/workspace/.cloud-tools/bin/blender-4.5.3 --background --factory-startup --version
