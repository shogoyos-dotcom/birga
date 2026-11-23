#!/usr/bin/env python3
"""Fon musiqasini kod bilan yaratadi — uchta kuy.

Ishga tushirish:  python3 tool/make_music.py
Natija:           assets/audio/music_pulse.ogg
                  assets/audio/music_neon.ogg
                  assets/audio/music_sprint.ogg

Eski `music.ogg` sof kvadrat to'lqinlardan yig'ilgan edi va quloqni
tez charchatardi. Bu yerda:

  * ovozlar **additiv** usulda (garmonikalar yig'indisi) quriladi —
    shuning uchun "aliasing" shovqini yo'q, tovush yumshoq;
  * har bir nota ADSR konverti va garmonika-kesish ("filtr") bilan
    bo'yaladi;
  * baraban haqiqiy sintez: bochka chastotasi pasayadi, malenkiy
    baraban shovqin + ton, hi-hat yorqin shovqin;
  * aks-sado (delay) va zal effekti (FFT reverb) qo'shiladi;
  * stereo — bass markazda, arpeggio chapda/o'ngda.

Halqa (loop) uzluksiz: kuy bir marta chiziladi, undan keyingi "dum"
(reverb quyrug'i) boshiga qo'shiladi — shuning uchun takrorlanganda
tikish sezilmaydi.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
TAIL = 2.5          # reyverb dumi uchun qo'shimcha soniya

# ——— Yordamchilar ———


def midi(name: str) -> float:
    """"A4", "C#3" kabi nomni chastotaga aylantiradi."""
    steps = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}
    i = 1
    semi = steps[name[0].upper()]
    if name[i] in '#b':
        semi += 1 if name[i] == '#' else -1
        i += 1
    octave = int(name[i:])
    return 440.0 * 2 ** ((semi + (octave - 4) * 12 - 9) / 12.0)


def axis(n: int) -> np.ndarray:
    return np.arange(n, dtype=np.float64) / RATE


def adsr(n, attack, decay, release, sustain=0.65):
    """Hujum / pasayish / ushlab turish / so'nish konverti."""
    e = np.zeros(n)
    a = min(int(attack * RATE), n)
    d = min(int(decay * RATE), n - a)
    r = min(int(release * RATE), n - a - d)
    s = n - a - d - r
    if a:
        e[:a] = np.linspace(0.0, 1.0, a, endpoint=False) ** 0.7
    if d:
        e[a:a + d] = np.linspace(1.0, sustain, d, endpoint=False)
    if s:
        e[a + d:a + d + s] = sustain
    if r:
        e[a + d + s:] = np.linspace(sustain, 0.0, r) ** 1.4
    return e


def decay_env(n, tau, hold=0.0):
    """Eksponensial so'nish — baraban va "pluck" uchun."""
    t = axis(n)
    e = np.exp(-np.maximum(t - hold, 0.0) / tau)
    return e


# Tembr: (garmonika raqami, balandligi). Kasr raqam — noaniq
# (inharmonik) ohang, qo'ng'iroqqa o'xshaydi.
def saw_timbre(count=24, tilt=1.0):
    return [(h, 1.0 / h ** tilt) for h in range(1, count + 1)]


def square_timbre(count=17):
    return [(h, 1.0 / h) for h in range(1, count + 1, 2)]


def pluck_timbre(count=12):
    return [(h, 1.0 / h ** 1.5) for h in range(1, count + 1)]


BELL_TIMBRE = [(1.0, 1.0), (2.0, 0.45), (3.01, 0.2),
               (4.16, 0.12), (5.43, 0.07), (6.8, 0.04)]
PAD_TIMBRE = [(1, 1.0), (2, 0.42), (3, 0.16), (4, 0.09), (5, 0.05)]


def osc(freq, n, timbre, cutoff=6000.0, voices=1, detune=0.0, phase=0.0):
    """Garmonikalar yig'indisi. `cutoff` — yuqori ohanglarni yumshatadi."""
    t = axis(n)
    out = np.zeros(n)
    for v in range(voices):
        shift = 0.0 if voices == 1 else detune * (v / (voices - 1.0) - 0.5)
        f = freq * 2 ** (shift / 1200.0)
        for h, amp in timbre:
            fh = f * h
            if fh > RATE * 0.45:
                continue
            # Bir qutbli past o'tkazgich filtrning kuchaytirish egri chizig'i.
            g = amp / np.sqrt(1.0 + (fh / cutoff) ** 2)
            if g < 0.0015:
                continue
            out += g * np.sin(2 * np.pi * fh * t + phase + v * 1.31 + h * 0.21)
    return out / voices


# ——— Baraban ———


def kick(n, rng, pitch=118.0, tau=0.17):
    t = axis(n)
    f = pitch * np.exp(-t / 0.030) + 46.0
    ph = 2 * np.pi * np.cumsum(f) / RATE
    body = np.sin(ph) * decay_env(n, tau)
    click = rng.standard_normal(n) * np.exp(-t / 0.0035) * 0.22
    return np.tanh((body + click) * 1.4)


def snare(n, rng, tau=0.085, tone=0.45):
    t = axis(n)
    nz = rng.standard_normal(n)
    # Yuqori o'tkazgich: o'zidan silliqlangan nusxasini ayiramiz.
    nz = nz - np.convolve(nz, np.ones(10) / 10.0, mode='same')
    body = 0.5 * (np.sin(2 * np.pi * 186 * t) + np.sin(2 * np.pi * 331 * t))
    return (nz * 0.85 + body * tone) * decay_env(n, tau)


def hat(n, rng, tau=0.028, bright=1.0):
    nz = rng.standard_normal(n)
    nz = np.diff(nz, prepend=0.0) * bright
    return nz * decay_env(n, tau) * 0.45


def shaker(n, rng, tau=0.055):
    nz = rng.standard_normal(n)
    nz = nz - np.convolve(nz, np.ones(4) / 4.0, mode='same')
    return nz * decay_env(n, tau) * 0.35


# ——— Effektlar ———


def echo(sig, time_s, feedback=0.42, mix=0.3, taps=7):
    """Aks-sado. Vektorlashgan: har takror — bitta siljish."""
    d = int(time_s * RATE)
    if d <= 0:
        return sig
    out = sig.copy()
    for k in range(1, taps + 1):
        g = feedback ** k * mix
        if g < 0.004:
            break
        out[d * k:] += sig[:len(sig) - d * k] * g
    return out


def reverb(sig, decay=1.3, mix=0.2, seed=7, damp=0.55):
    """Zal effekti: so'nuvchi shovqin impuls-javobi bilan FFT burama."""
    rng = np.random.default_rng(seed)
    ir_n = int(decay * RATE)
    t = axis(ir_n)
    ir = rng.standard_normal(ir_n) * np.exp(-t / (decay * 0.33))
    # Yuqori chastotalar tezroq so'nsin — tabiiyroq eshitiladi.
    ir = np.convolve(ir, np.ones(int(RATE * 0.0004 * (1 + damp))) /
                     max(int(RATE * 0.0004 * (1 + damp)), 1), mode='same')
    ir[:int(RATE * 0.012)] = 0.0          # oldingi aks-sado bo'shlig'i
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    size = 1
    while size < len(sig) + ir_n:
        size *= 2
    wet = np.fft.irfft(np.fft.rfft(sig, size) * np.fft.rfft(ir, size))
    return sig + wet[:len(sig)] * mix


# Master EQ egri chizig'i: (chastota Gc, kuchaytirish dB).
#
# Additiv sintezda bass tabiiy ravishda butun quvvatni egallab oladi —
# telefon karnayi esa 400 Gc dan pastini deyarli chiqarmaydi, natijada
# kuy loyqa va bo'sh eshitiladi. Shuning uchun gumburlash kesiladi va
# o'rta/yuqori chastotalar ko'tariladi.
EQ_CURVE = [
    (20.0, -30.0), (30.0, -20.0), (45.0, -9.0), (70.0, -3.5),
    (110.0, 0.0), (200.0, 0.5), (400.0, 3.0), (900.0, 5.5),
    (2000.0, 7.0), (5000.0, 5.5), (9000.0, 3.0), (14000.0, -3.0),
    # 16 kGc dan yuqorisi kesiladi: telefonda eshitilmaydi, lekin
    # OGG kodlagichi uni "jiringlatib" cho'qqini oshirib yuboradi.
    (16500.0, -24.0), (22050.0, -60.0),
]


def master_eq(sig):
    """Butun miksni bir marta FFT orqali tenglashtiradi."""
    size = 1
    while size < len(sig):
        size *= 2
    spec = np.fft.rfft(sig, size)
    f = np.fft.rfftfreq(size, 1.0 / RATE)
    f[0] = 1.0
    xs = np.log10([p[0] for p in EQ_CURVE])
    ys = [p[1] for p in EQ_CURVE]
    gain = 10.0 ** (np.interp(np.log10(f), xs, ys) / 20.0)
    return np.fft.irfft(spec * gain)[:len(sig)]


def _ring_smooth(sig, length):
    """Halqa bo'ylab silliqlash — boshi va oxiri ulanib turadi."""
    if length < 3:
        return sig
    k = np.hanning(length)
    k /= np.sum(k)
    padded = np.concatenate([sig[-length:], sig, sig[:length]])
    return np.convolve(padded, k, mode='same')[length:length + len(sig)]


def limiter(mix, ceiling=0.86, win=0.012, smooth=0.06):
    """Oldinga qarab ishlaydigan cheklovchi.

    Ovozni `tanh` bilan "yanchish" garmonik buzilish beradi va OGG
    kodlagichi uni yanada yomonlashtiradi. Bu yerda esa faqat baland
    joylarda kuchaytirish silliq pasaytiriladi — buzilish yo'q.
    """
    a = np.max(np.abs(mix), axis=1)
    w = max(int(win * RATE), 1)
    pad = (-len(a)) % w
    blocks = np.pad(a, (0, pad), mode='wrap').reshape(-1, w).max(axis=1)
    blocks = np.maximum(blocks, np.roll(blocks, 1))
    blocks = np.maximum(blocks, np.roll(blocks, -1))
    env = np.repeat(blocks, w)[:len(a)]
    gain = np.minimum(1.0, ceiling / np.maximum(env, 1e-9))
    gain = _ring_smooth(gain, max(int(smooth * RATE), 3))
    return mix * gain[:, None]


def soft_clip(mix, knee=0.78):
    """Qolgan yolg'iz cho'qqilarni yumshoq egadi (faqat tepasini)."""
    out = mix.copy()
    over = np.abs(mix) > knee
    if np.any(over):
        extra = (np.abs(mix[over]) - knee) / (1.0 - knee)
        out[over] = np.sign(mix[over]) * (knee + (1.0 - knee) * np.tanh(extra))
    return out


# ——— Sekvenser ———


class Track:
    """Nota va baraban zarbalarini stereo buferga chizadi."""

    def __init__(self, bpm, bars, beats_per_bar=4):
        self.beat = 60.0 / bpm
        self.step = self.beat / 4.0            # o'n oltilik
        self.loop_n = int(self.beat * beats_per_bar * bars * RATE)
        self.n = self.loop_n + int(TAIL * RATE)
        self.left = np.zeros(self.n)
        self.right = np.zeros(self.n)
        self.rng = np.random.default_rng(2024)

    def at(self, step_index):
        return int(step_index * self.step * RATE)

    def put(self, buf_l, buf_r, start, sig, gain, pan=0.0):
        """`pan`: -1 chap, 0 markaz, +1 o'ng."""
        if start >= self.n:
            return
        end = min(self.n, start + len(sig))
        part = sig[:end - start] * gain
        l = np.sqrt((1.0 - pan) * 0.5)
        r = np.sqrt((1.0 + pan) * 0.5)
        buf_l[start:end] += part * l
        buf_r[start:end] += part * r

    def note(self, step_index, dur_steps, freq, timbre, gain=0.2,
             cutoff=6000.0, voices=1, detune=0.0, pan=0.0,
             env=(0.01, 0.06, 0.25, 0.7), layer=None):
        n = int(dur_steps * self.step * RATE)
        if n < 32:
            return
        wave_data = osc(freq, n, timbre, cutoff, voices, detune)
        wave_data *= adsr(n, env[0], env[1], env[2], env[3])
        l, r = (self.left, self.right) if layer is None else layer
        self.put(l, r, self.at(step_index), wave_data, gain, pan)

    def pluck(self, step_index, dur_steps, freq, gain=0.2, tau=0.22,
              cutoff=4200.0, pan=0.0, timbre=None, layer=None):
        n = int(dur_steps * self.step * RATE)
        if n < 32:
            return
        wave_data = osc(freq, n, timbre or pluck_timbre(), cutoff)
        wave_data *= decay_env(n, tau) * (1.0 - np.exp(-axis(n) / 0.004))
        l, r = (self.left, self.right) if layer is None else layer
        self.put(l, r, self.at(step_index), wave_data, gain, pan)

    def drum(self, step_index, sig, gain=0.5, pan=0.0):
        self.put(self.left, self.right, self.at(step_index), sig, gain, pan)

    def finish(self, head=0.0, target_rms=0.26, peak=0.80):
        """Halqani yopadi, tenglashtiradi va balandligini bir xil qiladi.

        Uchta kuy bir xil `target_rms` ga keltiriladi — shunda kuyni
        almashtirganda ovoz birdan baland yoki jim bo'lib ketmaydi.
        """
        tail = self.n - self.loop_n
        out = []
        for ch in (self.left, self.right):
            ch = ch.copy()
            # Dum boshiga qo'shiladi — takrorlanish joyi sezilmaydi.
            ch[:tail] += ch[self.loop_n:self.loop_n + tail]
            ch = ch[:self.loop_n]
            if head > 0.0:
                k = int(head * RATE)
                ch[:k] *= np.linspace(0.3, 1.0, k)
            out.append(master_eq(ch))
        mix = np.stack(out, axis=1)
        rms = np.sqrt(np.mean(mix ** 2))
        mix *= target_rms / (rms + 1e-9)
        mix = soft_clip(limiter(mix, ceiling=peak), knee=peak * 0.92)
        return mix


def pattern(text):
    """"x..x" kabi satrdan zarba indekslarini oladi."""
    return [i for i, c in enumerate(text.replace(' ', '')) if c != '.']


# ——— Kuy 1: "Pulse" — issiq, o'rtacha tezlik (asosiy) ———


def track_pulse():
    bars = 16
    tr = Track(112, bars)
    rng = tr.rng
    k = kick(int(0.4 * RATE), rng)
    sn = snare(int(0.3 * RATE), rng)
    hh = hat(int(0.12 * RATE), rng)
    oh = hat(int(0.3 * RATE), rng, tau=0.09, bright=0.8)

    # Em – Cmaj7 – Gmaj – Dsus2 : ko'tarilib turadigan aylanma.
    chords = [
        (['E2', 'E3'], ['E4', 'G4', 'B4', 'E5']),
        (['C2', 'C3'], ['C4', 'E4', 'G4', 'B4']),
        (['G1', 'G2'], ['D4', 'G4', 'B4', 'D5']),
        (['D2', 'D3'], ['D4', 'A4', 'D5', 'E5']),
    ]
    bass_hits = pattern('x..x..x. x..x.x..')
    arp_order = [0, 1, 2, 3, 2, 1, 3, 2]

    for bar in range(bars):
        base = bar * 16
        bass_notes, chord_notes = chords[bar % 4]
        busy = bar % 4 >= 2            # ikkinchi yarmida zichroq
        # Bass — ikki ovozli, bir oz sozdan chiqarilgan arra to'lqini.
        for j, s in enumerate(bass_hits):
            freq = midi(bass_notes[1 if (j % 4 == 3) else 0])
            tr.note(base + s, 2.0, freq, saw_timbre(14), gain=0.26,
                    cutoff=460.0 + (140.0 if busy else 0.0), voices=2,
                    detune=14.0, env=(0.004, 0.05, 0.2, 0.55))
        # Pad — orqa fonda uzun akkord.
        for i, name in enumerate(chord_notes[:3]):
            tr.note(base, 16.0, midi(name) * 0.5, PAD_TIMBRE, gain=0.055,
                    cutoff=1500.0, voices=3, detune=18.0,
                    pan=-0.5 + i * 0.5, env=(0.5, 0.5, 2.0, 0.85))
        # Arpeggio — "pluck", chapdan o'ngga sakrab turadi.
        for s in range(0, 16, 2):
            idx = arp_order[(s // 2) % len(arp_order)]
            note_name = chord_notes[idx]
            tr.pluck(base + s, 3.0, midi(note_name), gain=0.17,
                     tau=0.19, cutoff=5200.0,
                     pan=0.55 if (s // 2) % 2 else -0.55)
        # Yakka ohang — har to'rtinchi taktda javob beradi.
        if bar % 4 == 3:
            for s, name in [(8, chord_notes[3]), (11, chord_notes[2]),
                            (13, chord_notes[1])]:
                tr.pluck(base + s, 4.0, midi(name) * 2.0, gain=0.1,
                         tau=0.3, cutoff=7000.0, pan=0.2)
        # Baraban.
        for s in pattern('x...x..x x...x...'):
            tr.drum(base + s, k, 0.62)
        for s in pattern('....x... ....x..x' if busy else '....x... ....x...'):
            tr.drum(base + s, sn, 0.34)
        for s in range(2, 16, 4):
            tr.drum(base + s, hh, 0.2, pan=0.25)
        for s in range(0, 16, 4):
            tr.drum(base + s, hh, 0.11, pan=-0.2)
        if busy:
            tr.drum(base + 14, oh, 0.15, pan=0.3)

    tr.left = echo(tr.left, tr.step * 3, 0.34, 0.22)
    tr.right = echo(tr.right, tr.step * 4, 0.34, 0.22)
    tr.left = reverb(tr.left, 1.25, 0.17, seed=3)
    tr.right = reverb(tr.right, 1.25, 0.17, seed=11)
    return tr.finish()


# ——— Kuy 2: "Neon" — sokin, qo'ng'iroqsimon ———


def track_neon():
    bars = 16
    tr = Track(92, bars)
    rng = tr.rng
    k = kick(int(0.5 * RATE), rng, pitch=96.0, tau=0.22)
    sh = shaker(int(0.2 * RATE), rng)
    sn = snare(int(0.35 * RATE), rng, tau=0.11, tone=0.25)

    # Dm9 – Bbmaj7 – Fmaj7 – Csus4 : yumshoq, hikoyasimon.
    chords = [
        ('D2', ['D4', 'F4', 'A4', 'E5']),
        ('Bb1', ['D4', 'F4', 'A4', 'D5']),
        ('F2', ['C4', 'F4', 'A4', 'C5']),
        ('C2', ['C4', 'F4', 'G4', 'C5']),
    ]

    for bar in range(bars):
        base = bar * 16
        bass_name, chord_notes = chords[bar % 4]
        # Chuqur, uzun bass.
        tr.note(base, 15.0, midi(bass_name), saw_timbre(10, 1.2), gain=0.24,
                cutoff=300.0, voices=2, detune=10.0,
                env=(0.06, 0.3, 2.6, 0.7))
        # Keng pad.
        for i, name in enumerate(chord_notes):
            tr.note(base, 16.0, midi(name) * 0.5, PAD_TIMBRE, gain=0.07,
                    cutoff=1250.0, voices=3, detune=22.0,
                    pan=-0.6 + i * 0.4, env=(0.9, 0.6, 2.5, 0.9))
        # Qo'ng'iroq arpeggio — sakkizliklarda, sekin kezadi.
        order = [0, 2, 1, 3, 2, 0, 3, 1]
        for j, s in enumerate(range(0, 16, 2)):
            name = chord_notes[order[j % len(order)]]
            octave = 2.0 if (bar % 4 == 2 and j % 2 == 0) else 1.0
            tr.pluck(base + s, 4.0, midi(name) * octave, gain=0.18,
                     tau=0.45, cutoff=9000.0, timbre=BELL_TIMBRE,
                     pan=-0.45 + (j % 4) * 0.3)
        # Baraban — juda yumshoq.
        for s in pattern('x....... x.......'):
            tr.drum(base + s, k, 0.5)
        if bar % 2 == 1:
            tr.drum(base + 8, sn, 0.16)
        for s in range(2, 16, 4):
            tr.drum(base + s, sh, 0.2, pan=0.3 if s % 8 else -0.3)
        # Yuqori oktavada yolg'iz "chirog'" — ohangga yorqinlik beradi.
        if bar % 4 in (1, 3):
            tr.pluck(base + 6, 6.0, midi(chord_notes[3]) * 2.0, gain=0.09,
                     tau=0.6, cutoff=11000.0, timbre=BELL_TIMBRE, pan=0.5)

    tr.left = echo(tr.left, tr.step * 6, 0.46, 0.3)
    tr.right = echo(tr.right, tr.step * 8, 0.46, 0.3)
    tr.left = reverb(tr.left, 2.1, 0.3, seed=5, damp=0.8)
    tr.right = reverb(tr.right, 2.1, 0.3, seed=17, damp=0.8)
    # Sokin kuy — qolganidan 2 dB jimroq tursin.
    return tr.finish(target_rms=0.2)


# ——— Kuy 3: "Sprint" — tez, shiddatli ———


def track_sprint():
    bars = 16
    tr = Track(140, bars)
    rng = tr.rng
    k = kick(int(0.32 * RATE), rng, pitch=135.0, tau=0.12)
    sn = snare(int(0.26 * RATE), rng, tau=0.07, tone=0.5)
    hh = hat(int(0.1 * RATE), rng, tau=0.019)
    oh = hat(int(0.26 * RATE), rng, tau=0.07, bright=0.9)

    # Am – F – G – E : klassik shiddatli aylanma.
    chords = [
        ('A1', ['A4', 'C5', 'E5', 'A5']),
        ('F1', ['F4', 'A4', 'C5', 'F5']),
        ('G1', ['G4', 'B4', 'D5', 'G5']),
        ('E1', ['E4', 'G#4', 'B4', 'E5']),
    ]

    for bar in range(bars):
        base = bar * 16
        bass_name, chord_notes = chords[bar % 4]
        hot = bar % 8 >= 4
        # Bass — har o'n oltilikda, shiddat beradi.
        for s in range(16):
            octave = 2.0 if s % 8 == 7 else 1.0
            tr.note(base + s, 1.0, midi(bass_name) * 2.0 * octave,
                    saw_timbre(16), gain=0.2,
                    cutoff=520.0 + (s % 4) * 90.0 + (200.0 if hot else 0.0),
                    voices=2, detune=12.0, env=(0.002, 0.03, 0.1, 0.4))
        # Yakka ohang — kvadrat to'lqin, o'tkir.
        lead = [0, 1, 2, 3, 2, 3, 1, 0] if hot else [0, 2, 1, 2, 3, 2, 1, 0]
        for j, s in enumerate(range(0, 16, 2)):
            tr.note(base + s, 2.0, midi(chord_notes[lead[j % 8]]),
                    square_timbre(13), gain=0.16, cutoff=4200.0,
                    pan=0.4 if j % 2 else -0.4,
                    env=(0.004, 0.04, 0.12, 0.5))
        if hot:
            for i, name in enumerate(chord_notes[:3]):
                tr.note(base, 16.0, midi(name) * 0.5, PAD_TIMBRE, gain=0.05,
                        cutoff=1700.0, voices=3, detune=20.0,
                        pan=-0.5 + i * 0.5, env=(0.4, 0.4, 2.0, 0.8))
        # Baraban — to'rt zarbali.
        for s in pattern('x...x...x...x...'):
            tr.drum(base + s, k, 0.6)
        for s in pattern('....x.......x..x' if hot else '....x.......x...'):
            tr.drum(base + s, sn, 0.3)
        for s in range(0, 16, 2):
            tr.drum(base + s, hh, 0.1 if s % 4 else 0.14,
                    pan=0.2 if (s // 2) % 2 else -0.2)
        if bar % 4 == 3:
            tr.drum(base + 12, oh, 0.14)
            for s in (13, 14, 15):
                tr.drum(base + s, sn, 0.18 + (s - 13) * 0.05)

    tr.left = echo(tr.left, tr.step * 3, 0.3, 0.16)
    tr.right = echo(tr.right, tr.step * 2, 0.3, 0.16)
    tr.left = reverb(tr.left, 0.9, 0.12, seed=9, damp=0.4)
    tr.right = reverb(tr.right, 0.9, 0.12, seed=23, damp=0.4)
    return tr.finish()


# ——— Yozish ———


def write(name, mix, quality='4'):
    data = (np.clip(mix, -1.0, 1.0) * 32767.0).astype('<i2')
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        path = tmp.name
    with wave.open(path, 'wb') as w:
        w.setnchannels(mix.shape[1])
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    target = os.path.join(OUT, name)
    subprocess.run(
        ['ffmpeg', '-y', '-loglevel', 'error', '-i', path,
         '-c:a', 'libvorbis', '-q:a', quality, target], check=True)
    os.unlink(path)
    seconds = len(mix) / RATE
    print(f'{name}: {os.path.getsize(target) / 1024:.0f} KB, '
          f'{seconds:.1f} s, cho\'qqi {np.max(np.abs(mix)):.2f}')


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    write('music_pulse.ogg', track_pulse())
    write('music_neon.ogg', track_neon())
    write('music_sprint.ogg', track_sprint())
