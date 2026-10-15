#!/bin/bash
set -euo pipefail

# Reuse this task's existing checkout. Do not create a worktree.
tool_root=/workspace/.cloud-tools
project_root=/workspace/Game-AI-/game
mkdir -p "$tool_root"/{bin,cache,data,config,godot,apt/lists/partial,apt/cache/archives/partial}
export PIP_CACHE_DIR="$tool_root/cache/pip"

python3 - <<'PY'
from pathlib import Path
import hashlib, urllib.request, zipfile
root = Path('/workspace/.cloud-tools/godot')
name = 'Godot_v4.5.1-stable_linux.x86_64.zip'
# Verified against the official 4.5.1-stable SHA512-SUMS.txt during onboarding.
expected = '5bccbed65a94b82c7c319fdb15719ee8113a6e503976cc54e16f1c61fe95f3d74e5e40b8449b5bb89ff7f424574c20af01a4f5ef08b389e4dc338b245185b0b9'
archive = root / name
if not archive.exists():
    url = 'https://github.com/godotengine/godot-builds/releases/download/4.5.1-stable/' + name
    partial = archive.with_suffix('.partial')
    with urllib.request.urlopen(url, timeout=90) as source, partial.open('wb') as target:
        while chunk := source.read(1024 * 1024):
            target.write(chunk)
    partial.rename(archive)
if hashlib.sha512(archive.read_bytes()).hexdigest() != expected:
    raise SystemExit('Godot archive SHA-512 mismatch; refusing installation')
with zipfile.ZipFile(archive) as z:
    binary_name = 'Godot_v4.5.1-stable_linux.x86_64'
    data = z.read(binary_name)
binary = root / binary_name
if not binary.exists() or hashlib.sha256(binary.read_bytes()).digest() != hashlib.sha256(data).digest():
    binary.write_bytes(data)
binary.chmod(0o755)
link = Path('/workspace/.cloud-tools/bin/godot-4.5.1')
if not link.exists():
    link.symlink_to(binary)
PY

if [ ! -x "$tool_root/xvfb/usr/bin/Xvfb" ]; then
    cat > "$tool_root/apt/sources.list" <<'SOURCES'
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian trixie main
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian trixie-updates main
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://security.debian.org/debian-security trixie-security main
SOURCES
    cat > "$tool_root/apt/local.conf" <<'APTCONF'
Dir::Etc::parts "-";
Dir::Etc::main "-";
Dir::Etc::sourcelist "/workspace/.cloud-tools/apt/sources.list";
Dir::Etc::sourceparts "-";
Dir::State::lists "/workspace/.cloud-tools/apt/lists";
Dir::Cache "/workspace/.cloud-tools/apt/cache";
APTCONF
    APT_CONFIG="$tool_root/apt/local.conf" apt-get update
    (
        cd "$tool_root/apt/cache"
        APT_CONFIG="$tool_root/apt/local.conf" apt-get download xvfb
        for package_file in xvfb_*.deb; do
            dpkg-deb -x "$package_file" "$tool_root/xvfb"
        done
    )
fi

cat > "$tool_root/godot-env.sh" <<'ENVIRONMENT'
export PATH="/workspace/.cloud-tools/bin:/workspace/.cloud-tools/xvfb/usr/bin:$PATH"
export XDG_CACHE_HOME=/workspace/.cloud-tools/cache
export XDG_DATA_HOME=/workspace/.cloud-tools/data
export XDG_CONFIG_HOME=/workspace/.cloud-tools/config
export PIP_CACHE_DIR=/workspace/.cloud-tools/cache/pip
export LIBGL_ALWAYS_SOFTWARE=1
export LP_NUM_THREADS=4
ENVIRONMENT
cat > "$tool_root/bin/shashlik-godot" <<'GODOT'
#!/bin/bash
set -euo pipefail
source /workspace/.cloud-tools/godot-env.sh
cd /workspace/Game-AI-/game
exec godot-4.5.1 --path /workspace/Game-AI-/game "$@"
GODOT
cat > "$tool_root/bin/shashlik-render" <<'RENDER'
#!/bin/bash
set -euo pipefail
source /workspace/.cloud-tools/godot-env.sh
cd /workspace/Game-AI-/game
exec xvfb-run -a -s "-screen 0 1280x720x24 -nolisten tcp" godot-4.5.1 --path /workspace/Game-AI-/game --rendering-method gl_compatibility --audio-driver Dummy "$@"
RENDER
chmod +x "$tool_root/bin/shashlik-godot" "$tool_root/bin/shashlik-render"

cat > "$tool_root/authoring-requirements.txt" <<'REQUIREMENTS'
ImageIO==2.38.1
lazy-loader==0.6
networkx==3.7
numpy==2.2.6
packaging==26.3
pillow==11.3.0
scikit-image==0.25.2
scipy==1.15.3
tifffile==2026.9.20
REQUIREMENTS
if [ ! -x "$tool_root/authoring-venv/bin/python" ]; then
    python3 -m venv "$tool_root/authoring-venv"
fi
"$tool_root/authoring-venv/bin/python" -m pip install --disable-pip-version-check -r "$tool_root/authoring-requirements.txt"
"$tool_root/authoring-venv/bin/python" -m pip check

# Original source archives and the restored project are retained in the snapshot.
# Never reset the checkout or regenerate its geometry during environment setup.
test -f "$project_root/project.godot"
"$tool_root/bin/shashlik-godot" --version
"$tool_root/bin/shashlik-godot" --headless --editor --import
"$tool_root/bin/shashlik-godot" --headless --audio-driver Dummy -- --self-test


# Verified visual tooling additions, 2026-10-16.
cat > "$tool_root/setup-vulkan.sh" <<'SHASHLIK_VULKAN_SETUP_V1'
#!/bin/bash
set -euo pipefail
tool_root=/workspace/.cloud-tools
mkdir -p "$tool_root/apt/lists/partial" "$tool_root/apt/cache/archives/partial" "$tool_root/apt/empty" "$tool_root/bin"
if [ ! -f "$tool_root/vulkan/usr/lib/x86_64-linux-gnu/libvulkan_lvp.so" ]; then
    cat > "$tool_root/apt/vulkan-sources.list" <<'SOURCES'
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian trixie main
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian trixie-updates main
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://security.debian.org/debian-security trixie-security main
SOURCES
    cat > "$tool_root/apt/vulkan.conf" <<'APTCONF'
Dir::Etc::parts "/workspace/.cloud-tools/apt/empty";
Dir::Etc::main "/workspace/.cloud-tools/apt/empty.conf";
Dir::Etc::sourcelist "/workspace/.cloud-tools/apt/vulkan-sources.list";
Dir::Etc::sourceparts "/workspace/.cloud-tools/apt/empty";
Dir::State::lists "/workspace/.cloud-tools/apt/lists";
Dir::Cache "/workspace/.cloud-tools/apt/cache";
APTCONF
    touch "$tool_root/apt/empty.conf"
    APT_CONFIG="$tool_root/apt/vulkan.conf" apt-get update
    (
        cd "$tool_root/apt/cache"
        APT_CONFIG="$tool_root/apt/vulkan.conf" apt-get download mesa-vulkan-drivers
        for package_file in mesa-vulkan-drivers_*.deb; do
            dpkg-deb -x "$package_file" "$tool_root/vulkan"
        done
    )
fi
cat > "$tool_root/bin/shashlik-forward-render" <<'RENDER'
#!/bin/bash
set -euo pipefail
source /workspace/.cloud-tools/godot-env.sh
export VK_DRIVER_FILES=/workspace/.cloud-tools/vulkan/usr/share/vulkan/icd.d/lvp_icd.json
export LD_LIBRARY_PATH=/workspace/.cloud-tools/vulkan/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
cd /workspace/Game-AI-/game
exec xvfb-run -a -s "-screen 0 1280x720x24 -nolisten tcp" godot-4.5.1 --path /workspace/Game-AI-/game --rendering-method forward_plus --rendering-driver vulkan --audio-driver Dummy "$@"
RENDER
chmod +x "$tool_root/bin/shashlik-forward-render"
if ldd "$tool_root/vulkan/usr/lib/x86_64-linux-gnu/libvulkan_lvp.so" | rg 'not found'; then
    echo 'Vulkan software driver has unresolved system libraries' >&2
    exit 1
fi
echo 'Local software Vulkan installed; use shashlik-forward-render for Forward+.'

SHASHLIK_VULKAN_SETUP_V1
bash "$tool_root/setup-vulkan.sh"
cat > "$tool_root/setup-blender.sh" <<'SHASHLIK_BLENDER_SETUP_V1'
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

SHASHLIK_BLENDER_SETUP_V1
bash "$tool_root/setup-blender.sh"
