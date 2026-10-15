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
