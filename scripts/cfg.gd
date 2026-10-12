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
# ---------- Fazenda ----------
const CULTURAS := [
	{"nome": "Trigo", "cor": Color(0.9, 0.8, 0.3), "tempo": 15.0, "preco": 2.0, "xp": 1.0, "nivel": 1, "peso": 60.0},
	{"nome": "Cenoura", "cor": Color(0.95, 0.55, 0.15), "tempo": 30.0, "preco": 6.0, "xp": 3.0, "nivel": 2, "peso": 30.0},
	{"nome": "Abóbora", "cor": Color(0.95, 0.4, 0.1), "tempo": 60.0, "preco": 15.0, "xp": 8.0, "nivel": 4, "peso": 10.0},
]
const LOTES_TOTAL := 8
const LOTES_BASE := 2                 # lotes abertos no Cultivo nivel 1; +1 a cada LOTES_A_CADA niveis
const LOTES_A_CADA := 2
const RENDIMENTO := 2                 # unidades colhidas por lote
const SEMENTE_CHANCE := 0.2           # por inimigo comum derrotado
const SEMENTES_CHEFE := 3
# Cultivo (a habilidade "inutil" do heroi): sobe colhendo. XP p/ subir = BASE * CRESC^(nivel-1)
const CULTIVO_XP_BASE := 5.0
const CULTIVO_XP_CRESC := 1.6
const AUTOPLANTIO_NIVEL := 4          # a partir daqui o lote replanta sozinho se houver semente
# ---------- Comida (cada cultura vira um prato) ----------
# efeito: "regen" soma % de vida/s, "vida" multiplica a vida maxima, "dano" multiplica o dano
const COZINHA_CUSTO := 4              # unidades da cultura gastas por prato
const SLOTS_COMIDA := 3
const PRATOS := [
	{"nome": "Pão", "efeito": "regen", "valor": 0.02, "duracao": 60.0, "desc": "+2% vida/s"},
	{"nome": "Ensopado", "efeito": "vida", "valor": 0.30, "duracao": 90.0, "desc": "+30% vida"},
	{"nome": "Torta", "efeito": "dano", "valor": 0.40, "duracao": 90.0, "desc": "+40% dano"},
]

# ---------- Zona 2 (fases 11 a 20) ----------
const ZONA2_A_PARTIR_DA_FASE := 11
const INIMIGOS_ZONA2 := [
	{"nome": "Lobo", "cor": Color(0.6, 0.6, 0.65), "tamanho": Vector2(70, 50), "vida": 35.0, "dano": 6.0, "intervalo": 0.9, "ouro": 4.0, "xp": 5.0},
	{"nome": "Esqueleto", "cor": Color(0.9, 0.9, 0.8), "tamanho": Vector2(44, 90), "vida": 50.0, "dano": 8.0, "intervalo": 1.1, "ouro": 6.0, "xp": 7.0},
	{"nome": "Ogro", "cor": Color(0.5, 0.4, 0.2), "tamanho": Vector2(85, 115), "vida": 80.0, "dano": 11.0, "intervalo": 1.7, "ouro": 9.0, "xp": 10.0},
]
const NOMES_ITEM_ZONA2 := ["Espada de Aço", "Armadura de Aço", "Amuleto de Prata"]
const ITEM_ZONA2_MULT := 1.5          # itens da zona 2 sao mais fortes