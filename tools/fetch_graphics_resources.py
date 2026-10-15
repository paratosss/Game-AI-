#!/usr/bin/env python3
"""Restore the pinned, CC0 photographic maps without changing their pixels."""
from pathlib import Path
import hashlib
import json
import urllib.request

project = Path(__file__).resolve().parents[1] / "game"
manifest = project / "assets/textures/quality/RESOURCE_MANIFEST.json"
for item in json.loads(manifest.read_text()):
    destination = project / item["file"]
    if destination.exists() and hashlib.sha256(destination.read_bytes()).hexdigest() == item["sha256"]:
        print("Verified", destination.name)
        continue
    request = urllib.request.Request(item["url"], headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=60) as response:
        data = response.read()
    if len(data) != item["bytes"] or hashlib.sha256(data).hexdigest() != item["sha256"]:
        raise RuntimeError(f"Resource integrity check failed: {destination.name}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    temporary.write_bytes(data)
    temporary.replace(destination)
    print("Restored", destination.name)
