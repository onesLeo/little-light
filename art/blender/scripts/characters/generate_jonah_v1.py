"""Build Jonah's dedicated Chapter 5 model.

The shared paper-person rig and export path live with the Bethlehem cast, while Jonah adds his
own close curls, compact beard, strong nose and dusty-indigo travelling clothes.

Run from the repository root:
  blender --background --python art/blender/scripts/characters/generate_jonah_v1.py
"""
import importlib.util
from pathlib import Path


HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("paper_people", HERE / "generate_bethlehem_people_v1.py")
paper_people = importlib.util.module_from_spec(spec)
spec.loader.exec_module(paper_people)


if __name__ == "__main__":
    paper_people.build("jonah")
