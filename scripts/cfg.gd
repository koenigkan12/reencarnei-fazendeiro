extends RefCounted
# Todos os numeros da batalha ficam aqui. Balanceamento (dia 19) mexe so neste arquivo.

# Heroi
const HEROI_VIDA := 100.0
const HEROI_DANO := 6.0
const HEROI_INTERVALO := 1.0          # segundos entre ataques
const HEROI_VIDA_POR_NIVEL := 15.0
const HEROI_DANO_POR_NIVEL := 2.0
const HEROI_REGEN_PCT := 0.01         # % da vida maxima regenerada por segundo

# XP: precisa de XP_BASE * XP_CRESCIMENTO^(nivel-1) para subir do nivel
const XP_BASE := 10.0
const XP_CRESCIMENTO := 1.4

# Fases
const FASES_TOTAL := 20
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

# ---------- Upgrades por ouro (aba Personagem) ----------
# custo = custo_base * crescimento^nivel_atual ; "vida" e "dano" somam, "regen" soma % de vida maxima por segundo
const UPGRADES := [
	{"id": "vida", "nome": "Vitalidade", "bonus": 20.0, "custo_base": 10.0, "crescimento": 1.35, "desc": "+20 vida"},
	{"id": "dano", "nome": "Força", "bonus": 3.0, "custo_base": 12.0, "crescimento": 1.35, "desc": "+3 dano"},
	{"id": "regen", "nome": "Regeneração", "bonus": 0.004, "custo_base": 20.0, "crescimento": 1.5, "desc": "+0,4% vida/s"},
]

# ---------- Chefes (fase%10 == 5 mini boss; fase%10 == 0 boss) ----------
# Baseados no Orc, escalados pela fase, com limite de tempo para derrotar.
const CHEFES := {
	"mini": {"nome": "Mini Boss", "cor": Color(0.75, 0.3, 0.75), "tamanho": Vector2(90, 120), "vida_mult": 5.0, "dano_mult": 1.5, "ouro_mult": 5.0, "xp_mult": 5.0, "tempo": 30.0},
	"boss": {"nome": "BOSS", "cor": Color(0.85, 0.15, 0.2), "tamanho": Vector2(120, 150), "vida_mult": 12.0, "dano_mult": 2.0, "ouro_mult": 12.0, "xp_mult": 12.0, "tempo": 45.0},
}

# ---------- Equipamento ----------
const SLOTS := ["Arma", "Armadura", "Acessório"]
const NOMES_ITEM := ["Espada", "Armadura", "Amuleto"]
const RARIDADES := [
	{"nome": "Comum", "cor": Color(0.8, 0.8, 0.8), "mult": 1.0, "peso": 60.0},
	{"nome": "Raro", "cor": Color(0.35, 0.6, 1.0), "mult": 1.6, "peso": 28.0},
	{"nome": "Épico", "cor": Color(0.7, 0.4, 1.0), "mult": 2.5, "peso": 10.0},
	{"nome": "Lendário", "cor": Color(1.0, 0.7, 0.2), "mult": 4.0, "peso": 2.0},
]
const ITEM_DANO_BASE := 3.0          # arma: dano; acessorio: metade do dano e da vida
const ITEM_VIDA_BASE := 25.0         # armadura: vida
const ITEM_ESCALA_FASE := 1.2        # multiplicador por fase em que o item caiu
const DROP_CHANCE := 0.12            # por inimigo comum
const DROP_BONUS_RARIDADE_CHEFE := 3.0  # chefe: sempre dropa e raridades acima de Comum pesam isso vezes mais
const DESCANSO_SEGUNDOS := 10.0      # heroi derrotado descansa e volta
const VENDA_BASE := 5.0              # ouro ao vender = base * mult da raridade * escala da fase

# CP (poder de combate) = vida/CP_VIDA_DIV + dano*CP_DANO_MULT/intervalo
const CP_VIDA_DIV := 10.0
const CP_DANO_MULT := 5.0