#!/usr/bin/env python3
"""O'yin ovozlarini kod bilan yaratadi — tayyor audio fayllar yuklanmaydi.

Ishga tushirish:  python3 tool/make_audio.py
Natija:           assets/audio/*.ogg  (ffmpeg orqali siqiladi)

Hamma tovush sodda to'lqinlardan (kvadrat, uchburchak, shovqin) yig'iladi,
shuning uchun arcade uslubiga mos tushadi va hajmi kichik bo'ladi.
"""
import math
import os
import struct
import subprocess
import tempfile
import wave

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')


def square(t, freq, duty=0.5):
    return 1.0 if (t * freq) % 1.0 < duty else -1.0


def triangle(t, freq):
    p = (t * freq) % 1.0
    return 4 * abs(p - 0.5) - 1


def noise(state=[12345]):
    # Oddiy LCG — har safar bir xil natija chiqsin.
    state[0] = (1103515245 * state[0] + 12345) % (1 << 31)
    return state[0] / (1 << 30) - 1


def env(i, n, attack=0.01, release=0.4):
    """Hujum/so'nish konverti (0..1)."""
    a = int(n * attack)
    r = int(n * release)
    if i < a:
        return i / max(a, 1)
    if i > n - r:
        return max(0.0, (n - i) / max(r, 1))
    return 1.0


def write(name, samples, gain=0.6):
    peak = max(1e-9, max(abs(s) for s in samples))
    data = b''.join(
        struct.pack('<h', int(max(-1, min(1, s / peak * gain)) * 32767))
        for s in samples
    )
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        path = tmp.name
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)
    target = os.path.join(OUT, name)
    subprocess.run(
        ['ffmpeg', '-y', '-loglevel', 'error', '-i', path,
         '-c:a', 'libvorbis', '-q:a', '3', target],
        check=True,
    )
    os.unlink(path)
    print(f'{name}: {os.path.getsize(target) / 1024:.1f} KB')


def tone_seq(steps, wave_fn=square, duty=0.5):
    """steps: (chastota, davomiylik soniya, balandlik) ro'yxati."""
    out = []
    for freq, dur, amp in steps:
        n = int(RATE * dur)
        for i in range(n):
            t = i / RATE
            v = wave_fn(t, freq, duty) if wave_fn is square else wave_fn(t, freq)
            out.append(v * amp * env(i, n, 0.02, 0.5))
    return out


def sfx_capture():
    # Hudud egallandi — ko'tariluvchi arpeggio.
    return tone_seq([(523, 0.06, 0.8), (659, 0.06, 0.85),
                     (784, 0.06, 0.9), (1047, 0.14, 1.0)], duty=0.35)


def sfx_kill():
    # Raqibni yiqitdi — ikki zarbali, past-baland.
    out = tone_seq([(880, 0.05, 1.0), (1319, 0.12, 0.9)], duty=0.25)
    for i in range(int(RATE * 0.05)):
        out[i] += noise() * 0.35 * env(i, int(RATE * 0.05), 0.01, 0.9)
    return out


def sfx_death():
    # O'lim — pasayuvchi tovush.
    out = []
    n = int(RATE * 0.55)
    for i in range(n):
        t = i / RATE
        freq = 440 * math.pow(0.35, t / 0.55)
        out.append(square(t, freq, 0.5) * env(i, n, 0.01, 0.7))
    return out


def sfx_tap():
    # Interfeys bosilishi — juda qisqa blip.
    return tone_seq([(1200, 0.035, 1.0)], duty=0.5)


def music():
    """Takrorlanadigan arcade kuyi: bas + arpeggio + hi-hat."""
    bpm = 124
    beat = 60 / bpm
    step = beat / 2          # sakkizlik
    bars = 8
    steps_total = bars * 8   # har taktda 8 ta sakkizlik
    n_total = int(RATE * step * steps_total)
    out = [0.0] * n_total

    # Am - F - C - G (arcade uchun klassik aylanma).
    roots = [220.0, 174.61, 130.81, 196.0]
    arps = [
        [440.0, 523.25, 659.25, 523.25],
        [349.23, 440.0, 523.25, 440.0],
        [523.25, 659.25, 783.99, 659.25],
        [392.0, 493.88, 587.33, 493.88],
    ]

    for s in range(steps_total):
        chord = (s // 16) % len(roots)
        start = int(s * step * RATE)
        n = int(step * RATE)

        # Bas — uchburchak to'lqin, har chorakda.
        if s % 2 == 0:
            f = roots[chord]
            for i in range(min(n * 2, n_total - start)):
                t = i / RATE
                out[start + i] += triangle(t, f) * 0.5 * env(i, n * 2, 0.01, 0.5)

        # Arpeggio — kvadrat to'lqin, har sakkizlikda.
        f = arps[chord][s % 4]
        for i in range(min(n, n_total - start)):
            t = i / RATE
            out[start + i] += square(t, f, 0.25) * 0.26 * env(i, n, 0.02, 0.6)

        # Hi-hat — shovqin, zaif urg'uda.
        if s % 2 == 1:
            hn = int(RATE * 0.035)
            for i in range(min(hn, n_total - start)):
                out[start + i] += noise() * 0.16 * env(i, hn, 0.005, 0.9)

    # Halqa silliq ulanishi uchun oxirini boshiga qo'shib yumshatamiz.
    fade = int(RATE * 0.03)
    for i in range(fade):
        k = i / fade
        out[i] = out[i] * k + out[n_total - fade + i] * (1 - k)
    return out[: n_total - fade]


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    write('capture.ogg', sfx_capture())
    write('kill.ogg', sfx_kill())
    write('death.ogg', sfx_death())
    write('tap.ogg', sfx_tap(), gain=0.45)
    write('music.ogg', music(), gain=0.5)
