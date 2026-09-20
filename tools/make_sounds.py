#!/usr/bin/env python3
"""Renders the game's synthesized sounds to assets/audio (standard library only).

    python tools/make_sounds.py

Everything is generated from code with a fixed random seed, so the files can be rebuilt
identically and tuned here instead of being edited by hand. Output is mono, 16-bit, 22.05 kHz.

  music/meadow_lullaby.wav     42 s seamless loop: music box, soft pad, warm bass
  ambience/wind.wav            16 s seamless loop
  ambience/stream.wav          12 s seamless loop
  ambience/bird_1..7.wav       short bird calls, played at random by the game
  sfx/step_1..4.wav            soft footsteps on grass
  sfx/bleat_1..2.wav           the lamb
  sfx/flutter.wav              butterflies taking off
"""
import math
import os
import random
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


def biquad(x, kind, f, q=0.707):
    """RBJ biquad filter: 'lp', 'hp' or 'bp'."""
    w0 = TAU * f / SR
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

def render_step(cut, thump):
    n = int(0.17 * SR)
    src = biquad(biquad(noise(n), "hp", 500.0), "lp", cut)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        env = (1.0 - math.exp(-t * 900.0)) * math.exp(-t / 0.032)
        low = math.sin(TAU * thump * t * (1.0 - 2.0 * t)) * math.exp(-t / 0.028) * 0.55
        out[i] = src[i] * env + low
    return out


def render_bleat(dur, f_start, f_end, f1, f2, seed):
    """A lamb's "baa": a rough, fast-vibrato voice shaped by two vowel formants."""
    r = random.Random(seed)
    n = int(dur * SR)
    out = [0.0] * n
    phase = 0.0
    breath = biquad(noise(n), "bp", 2200.0, 0.8)
    for i in range(n):
        t = i / SR
        x = t / dur
        contour = f_start + (f_end - f_start) * x + 30.0 * math.exp(-t * 20.0)
        vib = 1.0 + 0.055 * math.sin(TAU * 27.0 * t) + 0.012 * math.sin(TAU * 5.0 * t)
        f0 = contour * vib
        phase += TAU * f0 / SR
        v = 0.0
        h = 1
        while h * f0 < 4500.0:
            fh = h * f0
            w = math.exp(-((fh - f1) / 260.0) ** 2) + 0.7 * math.exp(-((fh - f2) / 340.0) ** 2) + 0.05
            v += math.sin(h * phase) * w / (h ** 0.6)
            h += 1
        rough = 0.72 + 0.28 * math.sin(TAU * 29.0 * t + r.uniform(0, 0.3))
        env = min(1.0, t / 0.05) * min(1.0, (dur - t) / 0.16)
        out[i] = (v * rough + breath[i] * 0.05) * env
    return out


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


# -- Render everything ---------------------------------------------------------------------------

def main():
    print("rendering to", os.path.normpath(OUT))
    save("music/meadow_lullaby.wav", render_music(), 0.55, loop=True)
    save("ambience/wind.wav", render_wind(), 0.50, loop=True)
    save("ambience/stream.wav", render_stream(), 0.50, loop=True)
    for i, segs in enumerate(BIRDS, 1):
        save("ambience/bird_%d.wav" % i, chirp(segs), 0.60)
    for i, (cut, thump) in enumerate(((3000, 110), (3500, 96), (3900, 120), (2600, 104)), 1):
        save("sfx/step_%d.wav" % i, render_step(cut, thump), 0.50)
    save("sfx/bleat_1.wav", render_bleat(0.78, 470, 380, 850, 1500, 1), 0.60)
    save("sfx/bleat_2.wav", render_bleat(0.38, 520, 430, 800, 1650, 2), 0.60)
    save("sfx/flutter.wav", render_flutter(), 0.40)


if __name__ == "__main__":
    main()
