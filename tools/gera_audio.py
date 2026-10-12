"""Gera os efeitos sonoros e as musicas provisorias (sinteticos, feitos por codigo: sem licenca externa).
Uso: python tools/gera_audio.py   ->  escreve audio/*.wav
"""
import wave, os
import numpy as np

SR = 22050
rng = np.random.default_rng(7)
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
os.makedirs(OUT, exist_ok=True)

def salva(nome, x, vol=0.8):
    x = np.asarray(x, dtype=np.float64)
    pico = np.max(np.abs(x)) or 1.0
    x = x / pico * vol
    with wave.open(os.path.join(OUT, nome + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())

def t_(d): return np.arange(int(SR * d)) / SR
def env(n, a=0.005, r=0.1):
    e = np.ones(n); na = min(n, max(1, int(SR * a))); nr = min(n, max(1, int(SR * r)))
    e[:na] = np.linspace(0, 1, na); e[-nr:] = np.minimum(e[-nr:], np.linspace(1, 0, nr)); return e
def onda(f, d, tipo="quad", vol=1.0):
    t = t_(d); ph = 2 * np.pi * np.cumsum(np.broadcast_to(f, t.shape)) / SR
    if tipo == "quad": x = np.sign(np.sin(ph))
    elif tipo == "tri": x = 2 / np.pi * np.arcsin(np.sin(ph))
    elif tipo == "saw": x = 2 * ((ph / (2 * np.pi)) % 1) - 1
    else: x = np.sin(ph)
    return x * vol * env(len(t))
def ruido(d, vol=1.0): return rng.uniform(-1, 1, int(SR * d)) * vol
def desliza(f0, f1, d): return np.linspace(f0, f1, int(SR * d))
def mix(*xs):
    n = max(len(x) for x in xs); o = np.zeros(n)
    for x in xs: o[:len(x)] += x
    return o
def nota(m): return 440.0 * 2 ** ((m - 69) / 12)

# ---------- efeitos ----------
salva("golpe", mix(ruido(0.09) * env(int(SR * .09), .001, .08), onda(desliza(220, 80, .12), .12, "sin")))
salva("critico", mix(ruido(0.14) * env(int(SR * .14), .001, .12), onda(desliza(700, 200, .18), .18, "quad", .5), onda(desliza(1200, 600, .1), .1, "sin", .4)))
salva("dano_heroi", mix(ruido(0.1) * env(int(SR * .1), .001, .09) * .6, onda(desliza(140, 60, .16), .16, "tri")))
salva("skill", mix(onda(desliza(300, 1200, .28), .28, "saw", .5), ruido(.28) * env(int(SR * .28), .05, .2) * .25))
salva("morte_inimigo", onda(desliza(500, 90, .3), .3, "quad", .6))
salva("level_up", np.concatenate([onda(nota(m), .1, "quad", .6) for m in (72, 76, 79, 84)] + [onda(nota(84), .3, "quad", .6)]))
salva("drop", np.concatenate([onda(nota(m), .07, "sin") for m in (88, 91, 95)]))
salva("compra", np.concatenate([onda(nota(83), .06, "quad", .6), onda(nota(88), .22, "quad", .6)]))
salva("arar", mix(ruido(.14) * env(int(SR * .14), .002, .12) * .7, onda(desliza(110, 60, .14), .14, "sin")))
salva("regar", ruido(.35) * env(int(SR * .35), .08, .2) * np.sin(np.linspace(0, 40, int(SR * .35))) ** 2)
salva("colher", mix(onda(desliza(300, 700, .1), .1, "sin"), ruido(.05) * .3))
salva("clique", onda(900, .04, "quad", .5))
salva("derrota", np.concatenate([onda(nota(m), .22, "tri", .7) for m in (67, 64, 60, 55)]))
salva("aviso_chefe", np.concatenate([onda(nota(45) * (1 + .5 * (i % 2)), .18, "saw", .6) for i in range(4)]))
salva("vitoria", np.concatenate([onda(nota(m), d, "quad", .6) for m, d in ((72, .12), (72, .12), (72, .12), (76, .3), (74, .12), (79, .5))]))

# ---------- musicas (loop) ----------
def musica(nome, bpm, acordes, melodia, onda_mel="tri", oitava_baixo=-24, vol_mel=0.5):
    bt = 60.0 / bpm; total = []
    for ac, mel in zip(acordes, melodia):
        compasso = np.zeros(int(SR * bt * 4))
        raiz = ac[0]
        for b in range(4):  # baixo
            n = onda(nota(raiz + oitava_baixo), bt * .9, "tri", .6); i = int(SR * bt * b); compasso[i:i + len(n)] += n[:len(compasso) - i]
        for k, m in enumerate(mel):  # melodia em colcheias
            if m is None: continue
            n = onda(nota(m), bt * .5 * .95, onda_mel, vol_mel); i = int(SR * bt * .5 * k); compasso[i:i + len(n)] += n[:len(compasso) - i]
        for m in ac[1:]:  # pad leve
            n = onda(nota(m), bt * 4, "sin", .12); compasso += n[:len(compasso)]
        total.append(compasso)
    return np.concatenate(total)

# batalha: la menor pentatonica, ritmo medio
A, F, C, G = (57, 60, 64), (53, 57, 60), (48, 52, 55), (55, 59, 62)
mel_b = [[69, None, 72, 71, 69, None, 67, 64], [65, None, 69, 67, 65, None, 64, 60], [67, None, 72, 71, 67, None, 64, 67], [67, 71, 74, 71, 67, None, 62, None]]
salva("jogo", musica("b", 112, [A, F, C, G], mel_b, "quad", vol_mel=.28), vol=.5)
# fazenda: do maior, calma
C2, F2, G2, A2 = (48, 52, 55), (53, 57, 60), (55, 59, 62), (57, 60, 64)
mel_f = [[72, None, 76, None, 79, None, 76, None], [77, None, 81, None, 77, None, 74, None], [74, None, 79, None, 83, None, 79, None], [76, None, 72, None, 69, None, 72, None]]
salva("fazenda", musica("f", 84, [C2, F2, G2, A2], mel_f, "sin", vol_mel=.45), vol=.5)
# menu: lento e suave; fim: tema de vitoria mais alegre
salva("menu", musica("m", 72, [C2, A2, F2, G2], [[72, None, None, None, 76, None, None, None], [69, None, None, None, 72, None, None, None], [72, None, None, None, 77, None, None, None], [71, None, None, None, 74, None, None, None]], "sin", vol_mel=.5), vol=.5)
salva("fim", musica("e", 120, [C2, G2, A2, F2], [[79, 79, 79, None, 83, None, 79, None], [74, 74, 74, None, 79, None, 83, None], [76, 76, 76, None, 81, None, 84, None], [77, None, 81, None, 84, None, 81, None]], "quad", vol_mel=.28), vol=.5)
print("ok", sorted(os.listdir(OUT)))
