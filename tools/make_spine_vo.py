#!/usr/bin/env python3
"""Historical Edge-TTS stand-ins for the Chapter 1 spine rewrite.

The Juno/Bram Seed Audio recuts now live in assets/audio/vo/. Do not run this
to replace them — it would overwrite matching voices with Jenny/Guy. Kept only
as a record of the ids and wording that changed.
"""
from __future__ import annotations

import sys

print(
    "make_spine_vo.py is retired: Juno/Bram recuts are in assets/audio/vo/.\n"
    "See docs/voice-over.md.",
    file=sys.stderr,
)
sys.exit(1)
