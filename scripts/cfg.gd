extends RefCounted
# Todos os numeros da batalha ficam aqui. Balanceamento (dia 19) mexe so neste arquivo.

# Heroi
const HEROI_VIDA := 100.0
const HEROI_DANO := 6.0
const HEROI_INTERVALO := 1.0          # segundos entre ataques
const HEROI_VIDA_POR_NIVEL := 15.0
const HEROI_DANO_POR_NIVEL := 2.0
const HEROI_REGEN_PCT := 0.03         # % da vida maxima regenerada por segundo

# XP: precisa de XP_BASE * XP_CRESCIMENTO^(nivel-1) para subir do nivel
const XP_BASE := 10.0
const XP_CRESCIMENTO := 1.4

# Fases
const FASES_TOTAL := 10
const INIMIGOS_POR_FASE := 10
const ESCALA_VIDA := 1.25             # multiplicador por fase
const ESCALA_DANO := 1.18
const ESCALA_OURO := 1.2
const ESCALA_XP := 1.15

# Tempo entre um inimigo morrer e o proximo aparecer
const RESPAWN_SEGUNDOS := 0.5

# Inimigos base (fase 1). Sorteado entre estes a cada spawn.
const INIMIGOS := [
	{"nome": "Slime", "cor": Color(0.35, 0.8, 0.4), "tamanho": Vector2(56, 44), "vida": 20.0, "dano": 3.0, "intervalo": 1.2, "ouro": 2.0, "xp": 3.0},
	{"nome": "Goblin", "cor": Color(0.55, 0.7, 0.25), "tamanho": Vector2(48, 80), "vida": 30.0, "dano": 4.0, "intervalo": 1.0, "ouro": 3.0, "xp": 4.0},
	{"nome": "Orc", "cor": Color(0.7, 0.35, 0.3), "tamanho": Vector2(70, 100), "vida": 45.0, "dano": 6.0, "intervalo": 1.6, "ouro": 5.0, "xp": 6.0},
]
