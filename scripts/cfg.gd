extends RefCounted
# Todos os numeros do jogo ficam aqui. O balanceamento mexe so neste arquivo.

# ================= HEROI =================
const HEROI_VIDA := 100.0
const HEROI_DANO := 6.0
const HEROI_INTERVALO := 1.0          # segundos entre ataques
const HEROI_VIDA_POR_NIVEL := 15.0
const HEROI_DANO_POR_NIVEL := 2.0
const HEROI_REGEN_PCT := 0.01         # % da vida maxima regenerada por segundo
const HEROI_CRIT := 0.05              # chance de critico base
const HEROI_CRIT_MULT := 1.5          # dano critico base (x)
const DEFESA_CONSTANTE := 100.0       # dano recebido = dano * C / (C + defesa)
const DESCANSO_SEGUNDOS := 10.0       # heroi derrotado descansa e volta

# XP: precisa de XP_BASE * XP_CRESCIMENTO^(nivel-1) para subir do nivel
const XP_BASE := 10.0
const XP_CRESCIMENTO := 1.4

# ================= ATRIBUTOS (comprados com ouro, aba Personagem) =================
# custo = custo_base * crescimento^nivel_atual ; "max" = nivel maximo (0 = sem limite)
const ATRIBUTOS := [
	{"id": "ataque", "nome": "Ataque", "bonus": 3.0, "custo_base": 12.0, "crescimento": 1.35, "max": 0, "desc": "+3 ataque"},
	{"id": "vida", "nome": "Vida", "bonus": 20.0, "custo_base": 10.0, "crescimento": 1.35, "max": 0, "desc": "+20 vida"},
	{"id": "recuperacao", "nome": "Recuperação", "bonus": 0.004, "custo_base": 20.0, "crescimento": 1.5, "max": 0, "desc": "+0,4% vida/s"},
	{"id": "defesa", "nome": "Defesa", "bonus": 2.0, "custo_base": 15.0, "crescimento": 1.4, "max": 0, "desc": "+2 defesa"},
	{"id": "critico", "nome": "Crítico", "bonus": 0.01, "custo_base": 25.0, "crescimento": 1.5, "max": 40, "desc": "+1% chance crítica"},
	{"id": "dano_critico", "nome": "Dano crítico", "bonus": 0.05, "custo_base": 25.0, "crescimento": 1.5, "max": 0, "desc": "+5% dano crítico"},
	{"id": "vel_ataque", "nome": "Vel. de ataque", "bonus": 0.04, "custo_base": 30.0, "crescimento": 1.55, "max": 25, "desc": "+4% vel. de ataque"},
]

# ================= TALENTOS (1 ponto por nivel do heroi) =================
# efeito: dano_pct, vida_pct, regen, defesa_pct, crit, crit_mult, ouro_pct, xp_pct, colheita_pct, crescimento_pct
# req = id do talento que precisa ter ao menos 1 ponto
const TALENTOS := [
	{"id": "golpe_forte", "ramo": "Combate", "nome": "Golpe Forte", "efeito": "dano_pct", "valor": 0.05, "max": 5, "req": "", "desc": "+5% ataque"},
	{"id": "olho_afiado", "ramo": "Combate", "nome": "Olho Afiado", "efeito": "crit", "valor": 0.02, "max": 5, "req": "golpe_forte", "desc": "+2% crítico"},
	{"id": "furia_t", "ramo": "Combate", "nome": "Ferocidade", "efeito": "crit_mult", "valor": 0.10, "max": 3, "req": "olho_afiado", "desc": "+10% dano crítico"},
	{"id": "pele_grossa", "ramo": "Defesa", "nome": "Pele Grossa", "efeito": "vida_pct", "valor": 0.05, "max": 5, "req": "", "desc": "+5% vida"},
	{"id": "vigor", "ramo": "Defesa", "nome": "Vigor", "efeito": "regen", "valor": 0.003, "max": 5, "req": "pele_grossa", "desc": "+0,3% vida/s"},
	{"id": "muralha", "ramo": "Defesa", "nome": "Muralha", "efeito": "defesa_pct", "valor": 0.08, "max": 3, "req": "vigor", "desc": "+8% defesa"},
	{"id": "maos_ouro", "ramo": "Cultivo", "nome": "Mãos de Ouro", "efeito": "ouro_pct", "valor": 0.05, "max": 5, "req": "", "desc": "+5% ouro"},
	{"id": "estudioso", "ramo": "Cultivo", "nome": "Estudioso", "efeito": "xp_pct", "valor": 0.05, "max": 5, "req": "maos_ouro", "desc": "+5% XP"},
	{"id": "colheita_farta", "ramo": "Cultivo", "nome": "Colheita Farta", "efeito": "colheita_pct", "valor": 0.25, "max": 4, "req": "", "desc": "+25% colheita"},
	{"id": "polegar_verde", "ramo": "Cultivo", "nome": "Polegar Verde", "efeito": "crescimento_pct", "valor": 0.08, "max": 4, "req": "colheita_farta", "desc": "+8% crescimento"},
]
const RESET_TALENTOS_CUSTO := 100.0   # ouro por nivel do heroi

# ================= HABILIDADES AUTOMATICAS =================
# Usadas da esquerda para a direita: a cada GCD usa a primeira pronta da fila.
# tipo: dano (mult do ataque, golpes), cura (% vida), buff_dano (% por duracao), escudo (reducao de dano por duracao)
const SLOTS_HABILIDADE := 4
const GCD_HABILIDADE := 1.0
const HABILIDADE_BONUS_POR_NIVEL := 0.10   # +10% do efeito por nivel da habilidade
const HABILIDADE_CUSTO_BASE := 30.0
const HABILIDADE_CUSTO_CRESC := 1.6
const HABILIDADES := [
	{"id": "golpe", "nome": "Golpe Poderoso", "nivel": 1, "tipo": "dano", "mult": 2.5, "golpes": 1, "cd": 6.0, "desc": "250% do ataque"},
	{"id": "rajada", "nome": "Rajada", "nivel": 3, "tipo": "dano", "mult": 0.9, "golpes": 3, "cd": 10.0, "desc": "3 golpes de 90%"},
	{"id": "cura", "nome": "Cura Vital", "nivel": 6, "tipo": "cura", "valor": 0.25, "cd": 20.0, "desc": "cura 25% da vida"},
	{"id": "furia", "nome": "Fúria Selvagem", "nivel": 9, "tipo": "buff_dano", "valor": 0.5, "duracao": 8.0, "cd": 25.0, "desc": "+50% ataque por 8s"},
	{"id": "escudo", "nome": "Escudo de Luz", "nivel": 12, "tipo": "escudo", "valor": 0.5, "duracao": 6.0, "cd": 25.0, "desc": "-50% dano por 6s"},
	{"id": "tempestade", "nome": "Tempestade", "nivel": 15, "tipo": "dano", "mult": 5.0, "golpes": 1, "cd": 18.0, "desc": "500% do ataque"},
]

# ================= FASES / INIMIGOS =================
const FASES_TOTAL := 20
const INIMIGOS_POR_FASE := 10
const ESCALA_VIDA := 1.25             # multiplicador por fase
const ESCALA_DANO := 1.18
const ESCALA_OURO := 1.2
const ESCALA_XP := 1.15
const RESPAWN_SEGUNDOS := 0.5

const INIMIGOS := [
	{"nome": "Slime", "cor": Color(0.35, 0.8, 0.4), "tamanho": Vector2(56, 44), "vida": 20.0, "dano": 3.0, "intervalo": 1.2, "ouro": 2.0, "xp": 3.0},
	{"nome": "Goblin", "cor": Color(0.55, 0.7, 0.25), "tamanho": Vector2(48, 80), "vida": 30.0, "dano": 4.0, "intervalo": 1.0, "ouro": 3.0, "xp": 4.0},
	{"nome": "Orc", "cor": Color(0.7, 0.35, 0.3), "tamanho": Vector2(70, 100), "vida": 45.0, "dano": 6.0, "intervalo": 1.6, "ouro": 5.0, "xp": 6.0},
]
const ZONA2_A_PARTIR_DA_FASE := 11
const INIMIGOS_ZONA2 := [
	{"nome": "Lobo", "cor": Color(0.6, 0.6, 0.65), "tamanho": Vector2(70, 50), "vida": 35.0, "dano": 6.0, "intervalo": 0.9, "ouro": 4.0, "xp": 5.0},
	{"nome": "Esqueleto", "cor": Color(0.9, 0.9, 0.8), "tamanho": Vector2(44, 90), "vida": 50.0, "dano": 8.0, "intervalo": 1.1, "ouro": 6.0, "xp": 7.0},
	{"nome": "Ogro", "cor": Color(0.5, 0.4, 0.2), "tamanho": Vector2(85, 115), "vida": 80.0, "dano": 11.0, "intervalo": 1.7, "ouro": 9.0, "xp": 10.0},
]
# Chefes (fase%10 == 5 mini boss; fase%10 == 0 boss). Baseados no 3o inimigo da zona.
const CHEFES := {
	"mini": {"nome": "Mini Boss", "cor": Color(0.75, 0.3, 0.75), "tamanho": Vector2(90, 120), "vida_mult": 5.0, "dano_mult": 1.5, "ouro_mult": 5.0, "xp_mult": 5.0, "tempo": 30.0},
	"boss": {"nome": "BOSS", "cor": Color(0.85, 0.15, 0.2), "tamanho": Vector2(120, 150), "vida_mult": 12.0, "dano_mult": 2.0, "ouro_mult": 12.0, "xp_mult": 12.0, "tempo": 45.0},
}

# ================= EQUIPAMENTO =================
const SLOTS := ["Arma", "Armadura", "Acessório"]
const NOMES_ITEM := ["Espada", "Armadura", "Amuleto"]
const NOMES_ITEM_ZONA2 := ["Espada de Aço", "Armadura de Aço", "Amuleto de Prata"]
const RARIDADES := [
	{"nome": "Comum", "cor": Color(0.8, 0.8, 0.8), "mult": 1.0, "peso": 60.0},
	{"nome": "Raro", "cor": Color(0.35, 0.6, 1.0), "mult": 1.6, "peso": 28.0},
	{"nome": "Épico", "cor": Color(0.7, 0.4, 1.0), "mult": 2.5, "peso": 10.0},
	{"nome": "Lendário", "cor": Color(1.0, 0.7, 0.2), "mult": 4.0, "peso": 2.0},
]
const ITEM_DANO_BASE := 3.0          # arma: dano; acessorio: metade do dano e da vida
const ITEM_VIDA_BASE := 25.0         # armadura: vida
const ITEM_ESCALA_FASE := 1.2        # multiplicador por fase em que o item caiu
const ITEM_ZONA2_MULT := 1.5
const DROP_CHANCE := 0.12            # por inimigo comum
const DROP_BONUS_RARIDADE_CHEFE := 3.0  # chefe: sempre dropa e raridades acima de Comum pesam isso vezes mais
const VENDA_BASE := 5.0              # ouro ao vender = base * mult da raridade * escala da fase
# Melhoria +N (ouro + minerio da fazenda): cada +1 soma BONUS_POR_MAIS dos status base do item
const MAIS_MAX := 10
const MAIS_BONUS := 0.10
const MAIS_OURO_BASE := 40.0
const MAIS_OURO_CRESC := 1.5
const MAIS_MINERIO_BASE := 1
const MAIS_MINERIO_POR_NIVEL := 1     # minerio = base + N * isto
# CP (poder de combate)
const CP_VIDA_DIV := 10.0
const CP_DANO_MULT := 5.0
const CP_DEFESA_MULT := 2.0

# ================= FAZENDA =================
const CULTURAS := [
	{"nome": "Trigo", "cor": Color(0.9, 0.8, 0.3), "tempo": 20.0, "preco": 2.0, "xp": 1.0, "nivel": 1, "peso": 60.0, "semente": 3.0},
	{"nome": "Cenoura", "cor": Color(0.95, 0.55, 0.15), "tempo": 40.0, "preco": 6.0, "xp": 3.0, "nivel": 2, "peso": 30.0, "semente": 8.0},
	{"nome": "Abóbora", "cor": Color(0.95, 0.4, 0.1), "tempo": 80.0, "preco": 15.0, "xp": 8.0, "nivel": 4, "peso": 10.0, "semente": 20.0},
]
const COLUNAS := 12                   # tamanho do terreno
const LINHAS := 8
const COLUNAS_INICIAIS := 6           # colunas liberadas no Cultivo nivel 1; +1 por nivel
const ROCHA_INICIAL_CHANCE := 0.12
const ROCHA_RESPAWN_SEGUNDOS := 25.0
const ROCHA_MAX := 10
const ROCHA_MINERIO_MIN := 1
const ROCHA_MINERIO_MAX := 2
const AGUA_SEGUNDOS := 45.0           # quanto tempo um lote regado cresce
const AGUA_POR_IRRIGACAO := 20.0      # +segundos por nivel de Irrigacao
const RENDIMENTO := 2                 # unidades colhidas por lote
const SEMENTE_CHANCE := 0.2           # drop de semente por inimigo comum
const SEMENTES_CHEFE := 3
# Cultivo (a habilidade "inutil" do heroi): sobe colhendo. XP p/ subir = BASE * CRESC^(nivel-1)
const CULTIVO_XP_BASE := 5.0
const CULTIVO_XP_CRESC := 1.6
const CULTIVO_CRESCIMENTO_POR_NIVEL := 0.02   # +2% de velocidade de crescimento por nivel
const AUTOPLANTIO_NIVEL := 4          # a partir daqui o lote replanta sozinho se houver semente
# Ferramentas: nivel N atinge (2N-1)x(2N-1) lotes. Custos para subir do nivel 1->2 e 2->3.
const FERRAMENTAS := [
	{"id": "enxada", "nome": "Enxada", "custos": [150.0, 600.0]},
	{"id": "regador", "nome": "Regador", "custos": [150.0, 600.0]},
	{"id": "picareta", "nome": "Picareta", "custos": [200.0, 800.0]},
]
const IRRIGACAO_CUSTOS := [200.0, 500.0, 1200.0]   # niveis 1..3

# ================= COMIDA (cada cultura vira um prato) =================
# efeito: "regen" soma % de vida/s, "vida" multiplica a vida maxima, "dano" multiplica o ataque
const COZINHA_CUSTO := 4              # unidades da cultura gastas por prato
const SLOTS_COMIDA := 3
const PRATOS := [
	{"nome": "Pão", "efeito": "regen", "valor": 0.02, "duracao": 60.0, "desc": "+2% vida/s"},
	{"nome": "Ensopado", "efeito": "vida", "valor": 0.30, "duracao": 90.0, "desc": "+30% vida"},
	{"nome": "Torta", "efeito": "dano", "valor": 0.40, "duracao": 90.0, "desc": "+40% ataque"},
]

# ---- Fazenda: ajustes de 12/10 (rega unica, sementes so na Loja, acoes dao XP de Cultivo) ----
const SEMENTE_DROP_ATIVO := false     # sementes agora so na Loja (decisao do Vncs); true volta o drop dos inimigos
const CULTIVO_XP_ARAR := 0.5          # XP de Cultivo por lote arado
const CULTIVO_XP_REGAR := 0.5         # XP de Cultivo por lote regado
const IRRIGACAO_VEL_POR_NIVEL := 0.10 # +10% de velocidade de crescimento por nivel de Irrigacao
const IRRIGACAO_AUTOREGA_NIVEL := 2   # a partir daqui a planta ja nasce regada (nao precisa do regador)
# Nivel de Cultivo minimo para subir cada ferramenta (indice 0: nivel 1->2, indice 1: 2->3)
const FERRAMENTA_CULTIVO_MIN := {"enxada": [3, 6], "regador": [2, 5], "picareta": [4, 7]}
const FLASH_SEGUNDOS := 0.3           # brilho curto no lote quando uma acao acontece (placeholder da animacao)
