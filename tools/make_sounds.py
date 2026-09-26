#!/usr/bin/env python3
"""Renders the game's synthesized sounds to assets/audio (standard library only).

    python tools/make_sounds.py

Everything is generated from code with a fixed random seed, so the files can be rebuilt
identically and tuned here instead of being edited by hand. Output is mono, 16-bit, 22.05 kHz.

  music/meadow_lullaby.wav     42 s seamless loop: music box, soft pad, warm bass
  ambience/wind.wav            16 s seamless loop
  ambience/stream.wav          12 s seamless loop
  ambience/bird_1..7.wav       short bird calls, played at random by the game
  sfx/step_path_1..4.wav       real footsteps on gravel (the path), sfx/step_water_1..4.wav real steps in mud (stand-in for the stream)
  sfx/step_1..4.wav            real footsteps in grass (a CC0 recording, see assets/audio/CREDITS.md),
                               cut to the landing and shortened so they thud, not swish
  sfx/bleat_1.wav              the lamb: a real sheep recording (CC0, see assets/audio/CREDITS.md),
                               pitched up, dried out and cleaned so it sounds small and close
  sfx/flutter.wav              butterflies taking off
  sfx/breath_loop.wav          a soft hush of air for Steady Hands; the game follows the breathing ring with its volume
  ambience/crickets.wav        12 s seamless loop for The King's Camp: a few soft chirps, not a wall of summer noise
  ambience/campfire.wav        8 s seamless loop: a small, dry crackle over a low warm hush
  sfx/owl_hoot.wav             the camp owl: two low, soft notes, "hoo-hoo"
  ambience/jonah_harbour.wav   12 s seamless Joppa bed: water, timber, rope and distant gulls
  ambience/jonah_storm.wav     12 s seamless wind, rain and low hull rumble
  ambience/jonah_market.wav    12 s seamless Nineveh bed: indistinct crowd and market movement

    python tools/make_sounds.py --camp   renders only the three King's Camp sounds
    python tools/make_sounds.py --jonah  renders only the three Chapter 5 ambience beds
"""
import math
import os
import random
import struct
import sys
import wave

SR = 22050
TAU = 2.0 * math.pi
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
rng = random.Random(7)


# -- Building blocks ---------------------------------------------------------------------------

def note(name):
    """'C4' -> frequency in Hz."""
    idx = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}[name[0]]
    midi = 12 * (int(name[1]) + 1) + idx
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def noise(n):
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


def biquad(x, kind, f, q=0.707, sr=SR):
    """RBJ biquad filter: 'lp', 'hp' or 'bp'."""
    w0 = TAU * f / sr
    cw, sw = math.cos(w0), math.sin(w0)
    alpha = sw / (2.0 * q)
    if kind == "lp":
        b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
    elif kind == "hp":
        b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
    else:
        b0, b1, b2 = alpha, 0.0, -alpha
    a0, a1, a2 = 1 + alpha, -2 * cw, 1 - alpha
    b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0
    y = [0.0] * len(x)
    x1 = x2 = y1 = y2 = 0.0
    for i, v in enumerate(x):
        o = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, v, y1, o
        y[i] = o
    return y


def reverb(x, wet=0.25, room=1.0):
    """A small Schroeder reverb (4 combs, 2 allpasses)."""
    combs = [int(d * room) for d in (778, 808, 745, 711)]
    fb = 0.8
    acc = [0.0] * len(x)
    for d in combs:
        y = [0.0] * len(x)
        for i in range(len(x)):
            y[i] = x[i] + (fb * y[i - d] if i >= d else 0.0)
        for i in range(len(x)):
            acc[i] += y[i] * 0.25
    for d, g in ((225, 0.5), (556, 0.5)):
        y = [0.0] * len(x)
        for i in range(len(x)):
            delayed = y[i - d] if i >= d else 0.0
            xd = acc[i - d] if i >= d else 0.0
            y[i] = -g * acc[i] + xd + g * delayed
        acc = y
    return [x[i] * (1.0 - wet * 0.5) + acc[i] * wet for i in range(len(x))]


def make_loop(x, n, fade):
    """x has n + fade samples; returns n samples whose end runs on into their start."""
    out = x[:n]
    for i in range(fade):
        a = i / fade
        out[i] = x[i] * math.sqrt(a) + x[n + i] * math.sqrt(1.0 - a)
    return out


def peak_of(x):
    return max(max(x), -min(x))


def normalize(x, peak):
    p = peak_of(x)
    g = peak / p if p > 0 else 1.0
    return [v * g for v in x]


def save(rel, x, peak, loop=False):
    x = normalize(x, peak)
    path = os.path.normpath(os.path.join(OUT, rel))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(int(max(-1.0, min(1.0, v)) * 32767).to_bytes(2, "little", signed=True) for v in x))
    rms = math.sqrt(sum(v * v for v in x) / len(x))
    info = "%-28s %6.2fs  peak %5.1f dBFS  rms %6.1f dBFS" % (rel, len(x) / SR, 20 * math.log10(peak_of(x)), 20 * math.log10(max(rms, 1e-9)))
    if loop:
        mean_step = sum(abs(x[i + 1] - x[i]) for i in range(0, len(x) - 1, 7)) / (len(x) / 7)
        jump = abs(x[0] - x[-1])
        info += "  seam %.1fx a normal step" % (jump / max(mean_step, 1e-9))
    print(info)


def add_at(buf, start, samples, wrap=False):
    n = len(buf)
    for i, v in enumerate(samples):
        j = start + i
        if j >= n:
            if not wrap:
                break
            j %= n
        buf[j] += v


# -- Music: a slow music-box lullaby in C major pentatonic --------------------------------------

BPM = 68
BEAT = 60.0 / BPM
BAR = 4 * BEAT
CHORDS = [("C3", "E3", "G3"), ("A2", "C3", "E3"), ("F2", "A2", "C3"), ("G2", "B2", "D3")] * 3
BASS = ["C2", "A2", "F2", "G2"] * 3
MELODY = [
    "G4 . E4 . G4 . A4 G4", "E4 . C5 . A4 . G4 .", "A4 . C5 . A4 . G4 E4", "D5 . G4 . A4 . G4 .",
    "E4 G4 A4 . C5 . A4 G4", "A4 . G4 E4 G4 . E4 .", "C5 . A4 . G4 A4 C5 .", "D5 . C5 . A4 . G4 .",
    "E5 . . . D5 . C5 .", "C5 . A4 . . . E4 .", "A4 . C5 . D5 . C5 .", "G4 . . . . . . .",
]


def bell(freq, amp, decay):
    """One music-box note: a bright pluck with a quickly fading overtone."""
    n = int(min(decay * 4.5, 4.0) * SR)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        env = math.exp(-t / decay) * (1.0 - math.exp(-t * 500.0))
        v = math.sin(TAU * freq * t) + 0.32 * math.sin(TAU * 2.0 * freq * t) * math.exp(-t * 4.0) \
            + 0.10 * math.sin(TAU * 4.17 * freq * t) * math.exp(-t * 9.0)
        out[i] = v * env * amp
    return out


def pad_tone(freq, length, amp):
    n = int((length + 1.4) * SR)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        att = min(1.0, t / 0.9)
        rel = 1.0 if t < length else max(0.0, 1.0 - (t - length) / 1.4)
        env = att * att * rel
        v = math.sin(TAU * freq * t) + math.sin(TAU * (freq + 0.55) * t) + 0.25 * math.sin(TAU * 2 * freq * t)
        out[i] = v * env * amp * 0.5
    return out


def render_music():
    n = int(BAR * len(CHORDS) * SR)
    tail = 4 * SR
    buf = [0.0] * (n + tail)
    for b, chord in enumerate(CHORDS):
        t0 = b * BAR
        for name in chord:
            add_at(buf, int(t0 * SR), pad_tone(note(name), BAR + 0.25, 0.10))
        for beat, amp in ((0, 0.11), (2, 0.06)):
            add_at(buf, int((t0 + beat * BEAT) * SR), bell(note(BASS[b]), amp, 1.2))
        for k, tok in enumerate(MELODY[b].split()):
            if tok == ".":
                continue
            when = t0 + k * BEAT / 2 + rng.gauss(0.0, 0.006)
            vel = 0.30 * (1.0 + rng.uniform(-0.12, 0.12))
            freq = note(tok)
            add_at(buf, int(when * SR), bell(freq, vel, 1.7 if freq < 600 else 1.3))
    # A few very quiet high sparkles for whimsy.
    for _ in range(7):
        add_at(buf, int(rng.uniform(0, n - SR) ), bell(note(rng.choice(["C6", "E6", "G6", "A6"])), 0.05, 0.9))
    buf = biquad(buf, "lp", 5200.0)
    buf = reverb(buf, wet=0.35, room=1.4)
    for i in range(tail):  # fold the reverb tail back onto the start so the loop is seamless
        buf[i] += buf[n + i]
    return buf[:n]


# -- Ambience ------------------------------------------------------------------------------------

def render_wind():
    n = 16 * SR
    fade = SR
    lead = SR // 2
    raw = noise(n + fade + lead)
    body = biquad(biquad(raw, "lp", 650.0), "lp", 900.0)
    hiss = biquad(biquad(raw, "bp", 3200.0, 0.6), "lp", 5000.0)
    body = make_loop(body[lead:], n, fade)
    hiss = make_loop(hiss[lead:], n, fade)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        gust = 0.55 + 0.25 * math.sin(TAU * t / 16.0 + 0.6) + 0.20 * math.sin(TAU * t / 8.0 + 2.1) \
            + 0.12 * math.sin(TAU * t / (16.0 / 3.0) + 4.0)
        gust = max(0.12, gust)
        out[i] = body[i] * gust + hiss[i] * gust * gust * 0.30
    return out


def render_stream():
    n = 12 * SR
    fade = SR
    lead = SR // 2
    raw = noise(n + fade + lead)
    low = biquad(raw, "bp", 850.0, 0.7)
    high = biquad(raw, "bp", 2600.0, 1.3)
    low = make_loop(low[lead:], n, fade)
    high = make_loop(high[lead:], n, fade)
    ks = [37, 56, 76, 107, 136]  # multiples of 1/12 Hz keep the bubbling periodic in the loop
    ph = [rng.uniform(0, TAU) for _ in ks]
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        bub = sum(math.sin(TAU * (k / 12.0) * t + p) for k, p in zip(ks, ph)) / len(ks)
        env = 0.65 + 0.45 * bub
        out[i] = low[i] * 0.9 * env + high[i] * 0.7 * (0.5 + 0.6 * env * env)
    for _ in range(26):  # tiny water droplets
        f0 = rng.uniform(600, 1300)
        dur = rng.uniform(0.04, 0.09)
        m = int(dur * SR)
        blip = [math.sin(TAU * (f0 * t + 0.5 * (f0 * 1.6) * t * t / dur)) * math.sin(math.pi * t / dur) ** 2 * 0.10
                for t in (j / SR for j in range(m))]
        add_at(out, rng.randrange(n), blip, wrap=True)
    return out


def chirp(segments, echo=True):
    """segments: ('t', f0, f1, dur, amp, vib_depth_hz, vib_rate) or ('g', gap_seconds)."""
    out = []
    phase = 0.0
    for seg in segments:
        if seg[0] == "g":
            out += [0.0] * int(seg[1] * SR)
            continue
        _, f0, f1, dur, amp, vd, vr = seg
        m = int(dur * SR)
        ramp = min(0.012, dur / 3.0)
        for j in range(m):
            t = j / SR
            f = f0 + (f1 - f0) * (t / dur) + vd * math.sin(TAU * vr * t)
            phase += TAU * f / SR
            env = min(1.0, t / ramp, (dur - t) / ramp)
            out.append((math.sin(phase) + 0.16 * math.sin(2 * phase)) * env * env * amp)
    if echo:
        pad = int(0.5 * SR)
        out += [0.0] * pad
        for delay, g in ((0.11, 0.26), (0.24, 0.11)):
            d = int(delay * SR)
            for i in range(len(out) - d - 1, d - 1, -1):
                out[i] += out[i - d] * g
    return out


BIRDS = [
    [("t", 2900, 3800, 0.11, 1, 0, 0), ("g", 0.07), ("t", 2900, 3800, 0.11, 1, 0, 0)],
    [seg for k in range(7) for seg in (("t", 3300 if k % 2 == 0 else 3800, 3000 if k % 2 == 0 else 3500, 0.045, 0.9, 0, 0), ("g", 0.02))],
    [("t", 4300, 2700, 0.38, 1, 40, 9)],
    [("t", 3100, 3100, 0.08, 1, 0, 0), ("g", 0.05), ("t", 3500, 3500, 0.08, 1, 0, 0), ("g", 0.05), ("t", 2700, 2500, 0.16, 0.9, 0, 0)],
    [("t", 3000, 3000, 0.55, 0.9, 380, 28)],
    [("t", 2500, 3300, 0.07, 1, 0, 0), ("g", 0.04), ("t", 4200, 3000, 0.09, 1, 0, 0)],
    [("t", 1100, 900, 0.25, 0.8, 0, 0), ("g", 0.08), ("t", 1100, 800, 0.3, 0.8, 0, 0)],
]


# -- Effects -------------------------------------------------------------------------------------

STEPS_SOURCE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "source", "steps_grass_slow_excerpt.wav")
STEP_SEGMENT = 0.5      # seconds each step occupies in the excerpt: 20 ms before the foot lands, then 0.48 s
STEP_LENGTH = 0.26      # how much of each step to keep
STEP_FADE = 0.09        # fade-out at the end, so no rustle drags on
STEP_DECAY = 0.10       # extra decay (time constant, s) after the landing: shortens the sustained "swish"
STEP_LOWPASS = 4500.0   # gentle high cut that takes the hiss out of the rustle


def render_steps():
    """Four real footsteps in grass, cut from the recording (see STEPS_SOURCE).

    The rustle that follows each landing sounded "swishy", so each step is kept short, decays faster
    than it did, and loses some of its highest frequencies.
    """
    x, rate = read_wav_24(STEPS_SOURCE)
    seg = int(STEP_SEGMENT * rate)
    steps = []
    for k in range(len(x) // seg):
        s = x[k * seg:(k + 1) * seg]
        s = biquad(biquad(s, "hp", 90.0, sr=rate), "hp", 90.0, sr=rate)
        s = biquad(s, "lp", STEP_LOWPASS, sr=rate)
        out = resample(s[:int(STEP_LENGTH * rate)], rate)
        lead = int(0.020 * SR)
        for i in range(len(out)):
            out[i] *= math.exp(-max(0.0, (i - lead) / SR) / STEP_DECAY)
        fade_in = int(0.004 * SR)
        for i in range(fade_in):
            out[i] *= i / fade_in
        fade_out = int(STEP_FADE * SR)
        for i in range(fade_out):
            out[-1 - i] *= (i / fade_out) ** 1.5
        steps.append(out)
    return steps


# Other ground. Same idea as the grass steps, but these recordings are not pre-cut, so each step is
# found by where the sound suddenly gets loud, unless the start times are given.
# (name, source file, keep, decay, fade, low-pass, high-pass, start times)
PATH_STEPS = ("path", "steps_gravel_bigsoundbank.wav", 0.24, 0.12, 0.08, 6500.0, 140.0, None)
# A real recording of walking through shallow water (not the earlier mud-pop stand-in): brighter
# and shorter than the path/mud steps so the splash's spray reads instead of a dull thud.
WATER_STEPS = ("water", "steps_water_bigsoundbank.wav", 0.30, 0.14, 0.10, 5200.0, 110.0, None)


def find_steps(x, rate, count=4, min_gap=0.42):
    """Start times (seconds) of the first `count` footfalls: where the loudness first jumps up."""
    frame = int(0.005 * rate)
    level = [math.sqrt(sum(v * v for v in x[i:i + frame]) / frame) for i in range(0, len(x) - frame, frame)]
    threshold = 0.30 * max(level)
    starts = []
    for i, v in enumerate(level):
        if v > threshold and (not starts or (i - starts[-1]) * frame / rate >= min_gap):
            j = i
            while j > 0 and level[j - 1] < level[j] and level[j - 1] > threshold * 0.25:
                j -= 1
            starts.append(j)
    return [j * frame / rate for j in starts[:count]]


def render_steps_from(kind):
    """Four real footsteps on another ground, cut from a recording in tools/source."""
    _, filename, keep, decay, fade, lowpass, highpass, given = kind
    x, rate = read_wav_24(os.path.join(os.path.dirname(os.path.abspath(__file__)), "source", filename))
    steps = []
    for t in (given or find_steps(x, rate)):
        a = max(int((t - 0.020) * rate), 0)
        s = x[a:a + int((keep + 0.05) * rate)]
        s = biquad(biquad(s, "hp", highpass, sr=rate), "hp", highpass, sr=rate)
        s = biquad(s, "lp", lowpass, sr=rate)
        out = resample(s[:int(keep * rate)], rate)
        lead = int(0.020 * SR)
        for i in range(len(out)):
            out[i] *= math.exp(-max(0.0, (i - lead) / SR) / decay)
        fade_in = int(0.004 * SR)
        for i in range(fade_in):
            out[i] *= i / fade_in
        fade_out = int(fade * SR)
        for i in range(fade_out):
            out[-1 - i] *= (i / fade_out) ** 1.5
        steps.append(out)
    return steps


SHEEP_SOURCE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "source", "sheep_2_bigsoundbank.wav")


def read_wav_24(path):
    """Reads a plain PCM WAV (16 or 24 bit, mono) without numpy; returns (samples, rate)."""
    d = open(path, "rb").read()
    fmt = d.index(b"fmt ")
    _, channels, rate, _, _, bits = struct.unpack("<HHIIHH", d[fmt + 8:fmt + 24])
    assert channels == 1 and bits in (16, 24), (channels, bits)
    i = d.index(b"data")
    size = struct.unpack("<I", d[i + 4:i + 8])[0]
    raw = d[i + 8:i + 8 + size]
    step = bits // 8
    full = 1 << (bits - 1)
    out = []
    for k in range(0, len(raw) - step + 1, step):
        v = int.from_bytes(raw[k:k + step], "little", signed=True)
        out.append(v / full)
    return out, rate


def active_rms_db(x):
    """Loudness of the parts that are actually sounding (windows within 40 dB of the loudest)."""
    win = 512
    levels = [math.sqrt(sum(v * v for v in x[i:i + win]) / len(x[i:i + win])) for i in range(0, len(x), win)]
    top = max(levels)
    live = [e for e in levels if e > top * 0.01]
    return 20 * math.log10(math.sqrt(sum(e * e for e in live) / len(live)))


def resample(x, rate, pitch=1.0):
    """Converts a recording to the game's sample rate, reading it `pitch` times faster
    (1.0 keeps the pitch), with a filter against aliasing."""
    ratio = pitch * rate / SR
    cut = min(10000.0, 0.9 * (SR / 2.0) / pitch)  # stay under the output's Nyquist once sped up
    x = biquad(biquad(x, "lp", cut, sr=rate), "lp", cut, sr=rate)
    out = []
    n = int((len(x) - 2) / ratio)
    for i in range(n):
        pos = i * ratio
        j = int(pos)
        frac = pos - j
        out.append(x[j] * (1.0 - frac) + x[j + 1] * frac)
    return out


def process_sheep(pitch, start, end, presence=0.25, gate_db=-30.0):
    """Turns the recorded sheep into a small, close lamb.

    - a high-pass takes out the boom of the room it was recorded in
    - a gate closes on the quiet echo after the bleat
    - reading it faster raises the pitch and, like a smaller body, moves the vowel sounds up too
    - a little 3 kHz keeps it clear and close
    """
    x, rate = read_wav_24(SHEEP_SOURCE)
    x = biquad(biquad(x, "hp", 220.0, sr=rate), "hp", 220.0, sr=rate)
    x = x[int(start * rate):int(end * rate)]
    # Gate: follow the loudness, close smoothly below the threshold.
    peak = peak_of(x)
    thr = peak * 10 ** (gate_db / 20.0)
    env = 0.0
    gain = 0.0
    hold = math.exp(-1.0 / (0.020 * rate))
    up = 1.0 - math.exp(-1.0 / (0.004 * rate))
    down = 1.0 - math.exp(-1.0 / (0.040 * rate))
    gated = []
    for v in x:
        env = max(abs(v), env * hold)
        target = 1.0 if env >= thr else (env / thr) ** 2
        gain += (target - gain) * (up if target > gain else down)
        gated.append(v * gain)
    # Read it `pitch` times faster, at the game's sample rate, with a filter against aliasing.
    out = resample(gated, rate, pitch)
    if presence > 0.0:
        pres = biquad(out, "bp", 3000.0, 0.8)
        out = [a + presence * b for a, b in zip(out, pres)]
    fade_in = int(0.004 * SR)
    for i in range(fade_in):
        out[i] *= i / fade_in
    fade_out = int(0.05 * SR)
    for i in range(fade_out):
        out[-1 - i] *= i / fade_out
    return out


def render_breath():
    """A soft, steady hush of air (8 s loop). Its level is not in the file: the game raises and lowers
    the volume with the breathing ring, so the sound swells as the child breathes in and fades as they let go."""
    n = 8 * SR
    fade = SR
    lead = SR // 2
    raw = noise(n + fade + lead)
    air = biquad(biquad(biquad(raw, "bp", 1100.0, 0.5), "lp", 2800.0), "lp", 2800.0)
    return make_loop(air[lead:], n, fade)


def render_flutter():
    n = int(0.42 * SR)
    src = biquad(biquad(noise(n), "bp", 3600.0, 0.9), "hp", 1500.0)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        flaps = abs(math.sin(TAU * 11.0 * t))
        env = (1.0 - math.exp(-t * 60.0)) * math.exp(-t / 0.15)
        out[i] = src[i] * flaps * env
    return out


# -- The King's Camp (chapter 2) -----------------------------------------------------------------
# Their own random source, so adding them never changes the sounds above.

camp_rng = random.Random(23)


def camp_noise(n):
    return [camp_rng.uniform(-1.0, 1.0) for _ in range(n)]


def render_owl():
    """Two low, round notes with a breath of air in them, a little night-air echo after."""
    out = [0.0] * int(0.25 * SR)
    for f0, f1, dur, amp in ((392.0, 370.0, 0.34, 1.0), (0.0, 0.0, 0.16, 0.0), (370.0, 330.0, 0.56, 0.9)):
        m = int(dur * SR)
        if amp == 0.0:
            out += [0.0] * m
            continue
        breath = biquad(biquad(camp_noise(m), "bp", f0 * 2.0, 1.2), "lp", 1800.0)
        phase = 0.0
        for j in range(m):
            t = j / SR
            f = f0 + (f1 - f0) * (t / dur) + 2.5 * math.sin(TAU * 5.0 * t)
            phase += TAU * f / SR
            att = min(1.0, t / 0.07)
            rel = min(1.0, (dur - t) / 0.16)
            env = att * att * max(0.0, rel) ** 1.5
            v = math.sin(phase) + 0.18 * math.sin(2.0 * phase) + 0.05 * math.sin(3.0 * phase)
            out.append((v + breath[j] * 0.35) * env * amp)
    out += [0.0] * int(0.6 * SR)
    return reverb(out, wet=0.22, room=1.3)


def cricket_chirp(freq, pulses, amp):
    """One chirp: a few very short buzzes of a high tone."""
    pulse = int(0.016 * SR)
    gap = int(0.02 * SR)
    out = []
    for _ in range(pulses):
        for j in range(pulse):
            t = j / SR
            env = math.sin(math.pi * j / pulse) ** 2
            out.append((math.sin(TAU * freq * t) + 0.25 * math.sin(TAU * freq * 2.0 * t)) * env * amp)
        out += [0.0] * gap
    return out


def render_crickets():
    n = 12 * SR
    out = [0.0] * n
    # Three crickets, each with its own pitch and pace, resting between runs of chirps.
    for freq, pace, amp in ((4300.0, 0.9, 0.9), (4750.0, 1.25, 0.6), (3950.0, 1.6, 0.45)):
        t = camp_rng.uniform(0.0, 2.0)
        while t < 12.0:
            run = camp_rng.randint(3, 7)
            for _ in range(run):
                chirp_amp = amp * camp_rng.uniform(0.75, 1.0)
                add_at(out, int(t * SR), cricket_chirp(freq * camp_rng.uniform(0.99, 1.01), camp_rng.choice((2, 3, 3, 4)), chirp_amp), wrap=True)
                t += pace * camp_rng.uniform(0.85, 1.15)
            t += camp_rng.uniform(1.5, 3.5)
    # Soften the edge of the tone so it is gentle on small speakers.
    return biquad(out, "lp", 6500.0)


def render_campfire():
    n = 8 * SR
    fade = SR
    lead = SR // 2
    raw = camp_noise(n + fade + lead)
    hush = biquad(biquad(raw, "lp", 420.0), "lp", 600.0)
    air = biquad(biquad(raw, "bp", 1800.0, 0.6), "lp", 3500.0)
    hush = make_loop(hush[lead:], n, fade)
    air = make_loop(air[lead:], n, fade)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        swell = 0.8 + 0.2 * math.sin(TAU * t / 8.0 + 1.0) + 0.1 * math.sin(TAU * t / 2.0)
        out[i] = hush[i] * 1.4 * swell + air[i] * 0.18 * swell
    # Crackles: tiny dry clicks, sometimes in little clusters, now and then one soft pop.
    t = 0.0
    while t < 8.0:
        cluster = camp_rng.choice((1, 1, 1, 2, 3, 4))
        for _ in range(cluster):
            m = int(camp_rng.uniform(0.002, 0.007) * SR)
            click = biquad(camp_noise(m + int(0.03 * SR)), "hp", camp_rng.uniform(1500.0, 3500.0))
            amp = camp_rng.uniform(0.25, 1.0)
            decay = camp_rng.uniform(0.004, 0.012)
            burst = [v * amp * math.exp(-(j / SR) / decay) for j, v in enumerate(click)]
            add_at(out, int(t * SR), burst, wrap=True)
            t += camp_rng.uniform(0.01, 0.05)
        if camp_rng.random() < 0.12:
            m = int(0.05 * SR)
            pop = biquad(camp_noise(m), "bp", camp_rng.uniform(500.0, 900.0), 1.5)
            add_at(out, int(t * SR), [v * 1.2 * math.exp(-(j / SR) / 0.015) for j, v in enumerate(pop)], wrap=True)
        t += camp_rng.uniform(0.06, 0.45)
    return out


def render_camp():
    save("ambience/crickets.wav", render_crickets(), 0.35, loop=True)
    save("ambience/campfire.wav", render_campfire(), 0.55, loop=True)
    save("sfx/owl_hoot.wav", render_owl(), 0.55)


# -- Jonah and the Great Fish (chapter 5) --------------------------------------------------------
jonah_rng = random.Random(505)


def jonah_noise(n):
    return [jonah_rng.uniform(-1.0, 1.0) for _ in range(n)]


def render_jonah_harbour():
    """Gentle water against stone, timber and rope movement, with very distant gull shapes."""
    n, fade, lead = 12 * SR, SR, SR // 2
    raw = jonah_noise(n + fade + lead)
    water = biquad(biquad(raw, "bp", 520.0, 0.45), "lp", 1800.0)
    wash = biquad(biquad(raw, "bp", 1800.0, 0.55), "lp", 4200.0)
    water = make_loop(water[lead:], n, fade)
    wash = make_loop(wash[lead:], n, fade)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        lap = 0.28 + 0.42 * max(0.0, math.sin(TAU * t / 2.7)) ** 2
        out[i] = water[i] * (0.75 + 0.18 * math.sin(TAU * t / 7.0)) + wash[i] * lap * 0.34
    # Hull/jetty creaks: short, low pitch falls, sparse enough to feel inhabited rather than busy.
    for t0 in (1.1, 4.8, 7.4, 10.6):
        dur = jonah_rng.uniform(0.18, 0.42)
        phase = 0.0
        creak = []
        for j in range(int(dur * SR)):
            t = j / SR
            phase += TAU * (420.0 + (170.0 - 420.0) * (t / dur)) / SR
            creak.append((math.sin(phase) + 0.25 * math.sin(phase * 2.03)) * math.sin(math.pi * t / dur) ** 2 * 0.20)
        add_at(out, int(t0 * SR), creak, wrap=True)
    # Two remote gull calls, deliberately soft and without a close bird's sharp edge.
    for t0, base in ((2.7, 1120.0), (8.9, 980.0)):
        call = chirp([("t", base, base * 1.25, 0.18, 0.10, 18, 5), ("g", 0.08),
                      ("t", base * 1.08, base * 0.9, 0.24, 0.08, 12, 4)], echo=True)
        add_at(out, int(t0 * SR), call, wrap=True)
    return out


def render_jonah_storm():
    """Broad wind and rain with a low wooden-hull strain; no sudden thunder or startling hits."""
    n, fade, lead = 12 * SR, SR, SR // 2
    raw = jonah_noise(n + fade + lead)
    wind = biquad(biquad(raw, "bp", 440.0, 0.40), "lp", 1500.0)
    rain = biquad(biquad(raw, "hp", 2300.0), "lp", 7800.0)
    low = biquad(biquad(raw, "lp", 150.0), "lp", 180.0)
    wind = make_loop(wind[lead:], n, fade)
    rain = make_loop(rain[lead:], n, fade)
    low = make_loop(low[lead:], n, fade)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        gust = 0.62 + 0.24 * math.sin(TAU * t / 5.7) + 0.12 * math.sin(TAU * t / 2.3 + 1.2)
        hull = math.sin(TAU * 43.0 * t + 0.8 * math.sin(TAU * t / 3.2)) * (0.025 + 0.020 * max(0.0, math.sin(TAU * t / 4.1)))
        out[i] = wind[i] * gust * 1.1 + rain[i] * (0.34 + gust * 0.18) + low[i] * 1.8 + hull
    return out


def render_jonah_market():
    """An indistinct human murmur with cloth, sandals and baskets; no intelligible speech."""
    n, fade, lead = 12 * SR, SR, SR // 2
    raw = jonah_noise(n + fade + lead)
    room = biquad(biquad(raw, "bp", 650.0, 0.55), "lp", 2100.0)
    shuffle = biquad(biquad(raw, "bp", 220.0, 0.7), "lp", 700.0)
    room = make_loop(room[lead:], n, fade)
    shuffle = make_loop(shuffle[lead:], n, fade)
    out = [room[i] * 0.23 + shuffle[i] * 0.18 for i in range(n)]
    # Overlapping vowel-like tones imply people at a distance without creating words.
    for _ in range(24):
        start = jonah_rng.uniform(0.0, 12.0)
        dur = jonah_rng.uniform(0.35, 1.2)
        fundamental = jonah_rng.uniform(105.0, 210.0)
        wobble_rate = jonah_rng.uniform(2.5, 4.5)
        phase = 0.0
        voice = []
        for j in range(int(dur * SR)):
            t = j / SR
            wobble = 1.0 + 0.018 * math.sin(TAU * wobble_rate * t)
            phase += TAU * fundamental * wobble / SR
            env = math.sin(math.pi * t / dur) ** 2
            voice.append((math.sin(phase) + 0.22 * math.sin(phase * 2.0) + 0.08 * math.sin(phase * 3.0)) * env * 0.018)
        add_at(out, int(start * SR), voice, wrap=True)
    # Occasional dry handling sounds from baskets or pottery, kept very soft.
    for t0 in (0.8, 3.6, 6.2, 9.7, 11.3):
        m = int(0.055 * SR)
        tap = biquad(jonah_noise(m), "bp", jonah_rng.uniform(700.0, 1400.0), 1.1)
        tap = [v * 0.08 * math.exp(-(j / SR) / 0.014) for j, v in enumerate(tap)]
        add_at(out, int(t0 * SR), tap, wrap=True)
    return out


def render_jonah():
    save("ambience/jonah_harbour.wav", render_jonah_harbour(), 0.48, loop=True)
    save("ambience/jonah_storm.wav", render_jonah_storm(), 0.58, loop=True)
    save("ambience/jonah_market.wav", render_jonah_market(), 0.40, loop=True)


# -- Render everything ---------------------------------------------------------------------------

def main():
    print("rendering to", os.path.normpath(OUT))
    save("music/meadow_lullaby.wav", render_music(), 0.55, loop=True)
    save("ambience/wind.wav", render_wind(), 0.50, loop=True)
    save("ambience/stream.wav", render_stream(), 0.50, loop=True)
    for i, segs in enumerate(BIRDS, 1):
        save("ambience/bird_%d.wav" % i, chirp(segs), 0.60)
    for i, step in enumerate(render_steps(), 1):
        # Matched by how loud the body of the step is (its first 120 ms), not by its peak, so a step with
        # a sharper landing does not end up quieter than the others.
        body = step[:int(0.12 * SR)]
        gain = 10 ** (-19.0 / 20.0) / math.sqrt(sum(v * v for v in body) / len(body))
        step = [v * gain for v in step]
        save("sfx/step_%d.wav" % i, step, min(peak_of(step), 0.90))
    for kind in (PATH_STEPS, WATER_STEPS):
        for i, step in enumerate(render_steps_from(kind), 1):
            body = step[:int(0.12 * SR)]
            gain = 10 ** (-19.0 / 20.0) / math.sqrt(sum(v * v for v in body) / len(body))
            step = [v * gain for v in step]
            save("sfx/step_%s_%d.wav" % (kind[0], i), step, min(peak_of(step), 0.90))
    # Normalised by how loud the bleat is while it sounds, not by its peak, so both lambs match.
    lamb = process_sheep(pitch=1.30, start=0.06, end=0.80, presence=0.25)
    lamb = [v * 10 ** ((-14.0 - active_rms_db(lamb)) / 20.0) for v in lamb]
    save("sfx/bleat_1.wav", lamb, min(peak_of(lamb), 0.90))
    save("sfx/flutter.wav", render_flutter(), 0.40)
    save("sfx/breath_loop.wav", render_breath(), 0.50, loop=True)
    render_camp()
    # Chapter-specific location beds share the same deterministic build.
    render_jonah()


if __name__ == "__main__":
    if "--camp" in sys.argv:
        print("rendering to", os.path.normpath(OUT))
        render_camp()
    elif "--jonah" in sys.argv:
        print("rendering to", os.path.normpath(OUT))
        render_jonah()
    else:
        main()
