"""Shared output paths for Little Light Blender generators."""
import os
from pathlib import Path

REPO_BLENDER_ROOT = Path(__file__).resolve().parents[1]  # art/blender

def art_out() -> Path:
    env = os.environ.get("LITTLE_LIGHT_ART_OUT")
    if env:
        return Path(env).expanduser().resolve()
    return (REPO_BLENDER_ROOT / "output").resolve()

def grain_png() -> Path:
    return REPO_BLENDER_ROOT / "assets" / "textures" / "paper_grain.png"
