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

# ================= ESTILOS, TALENTOS E HABILIDADES =================
# O estilo do heroi (fisico/magico/distancia) vem das habilidades equipadas, nao de uma classe.
# Arma do mesmo estilo da habilidade dá AFINIDADE_CERTA no dano dela; outra arma (ou sem arma) dá AFINIDADE_ERRADA.
const ESTILOS := {
	"fisico": {"nome": "Físico", "cor": Color(1.0, 0.6, 0.3)},
	"magico": {"nome": "Mágico", "cor": Color(0.55, 0.65, 1.0)},
	"distancia": {"nome": "Distância", "cor": Color(0.5, 0.95, 0.5)},
}
const AFINIDADE_CERTA := 1.25
const AFINIDADE_ERRADA := 0.70

# ---------- Talentos (1 ponto por nivel do heroi) ----------
# efeito: dano_pct, vida_pct, regen, defesa_pct, crit, crit_mult, vel_pct, skill_pct (dano das habilidades),
#   recarga_pct (reduz a recarga), ouro_pct, xp_pct, colheita_pct, crescimento_pct, ou "skill" (libera a habilidade "skill")
# req = id do talento que precisa ter ao menos 1 ponto
const TALENTOS := [
	# --- Lamina (fisico) ---
	{"id": "golpe_forte", "ramo": "Lâmina", "nome": "Golpe Forte", "efeito": "dano_pct", "valor": 0.05, "max": 5, "req": "", "desc": "+5% ataque"},
	{"id": "t_giratorio", "ramo": "Lâmina", "nome": "Golpe Giratório", "efeito": "skill", "skill": "giratorio", "valor": 0.0, "max": 1, "req": "golpe_forte", "desc": "libera a habilidade"},
	{"id": "pele_grossa", "ramo": "Lâmina", "nome": "Pele Grossa", "efeito": "vida_pct", "valor": 0.05, "max": 5, "req": "golpe_forte", "desc": "+5% vida"},
	{"id": "t_postura", "ramo": "Lâmina", "nome": "Postura de Ferro", "efeito": "skill", "skill": "postura", "valor": 0.0, "max": 1, "req": "pele_grossa", "desc": "libera a habilidade"},
	{"id": "muralha", "ramo": "Lâmina", "nome": "Muralha", "efeito": "defesa_pct", "valor": 0.08, "max": 3, "req": "t_postura", "desc": "+8% defesa"},
	{"id": "t_enxadada", "ramo": "Lâmina", "nome": "Enxadada Lendária", "efeito": "skill", "skill": "enxadada", "valor": 0.0, "max": 1, "req": "t_giratorio", "desc": "libera a habilidade"},
	# --- Arcano (magico) ---
	{"id": "mente_clara", "ramo": "Arcano", "nome": "Mente Clara", "efeito": "skill_pct", "valor": 0.05, "max": 5, "req": "", "desc": "+5% dano de habilidades"},
	{"id": "t_fogo", "ramo": "Arcano", "nome": "Bola de Fogo", "efeito": "skill", "skill": "fogo", "valor": 0.0, "max": 1, "req": "mente_clara", "desc": "libera a habilidade"},
	{"id": "foco", "ramo": "Arcano", "nome": "Foco", "efeito": "recarga_pct", "valor": 0.04, "max": 4, "req": "mente_clara", "desc": "-4% recarga"},
	{"id": "t_raio", "ramo": "Arcano", "nome": "Raio Arcano", "efeito": "skill", "skill": "raio", "valor": 0.0, "max": 1, "req": "t_fogo", "desc": "libera a habilidade"},
	{"id": "t_cura", "ramo": "Arcano", "nome": "Cura Verde", "efeito": "skill", "skill": "cura", "valor": 0.0, "max": 1, "req": "foco", "desc": "libera a habilidade"},
	{"id": "vigor", "ramo": "Arcano", "nome": "Vigor", "efeito": "regen", "valor": 0.003, "max": 5, "req": "t_cura", "desc": "+0,3% vida/s"},
	# --- Arco (distancia) ---
	{"id": "olho_afiado", "ramo": "Arco", "nome": "Olho Afiado", "efeito": "crit", "valor": 0.02, "max": 5, "req": "", "desc": "+2% crítico"},
	{"id": "t_tiro", "ramo": "Arco", "nome": "Tiro Preciso", "efeito": "skill", "skill": "tiro", "valor": 0.0, "max": 1, "req": "olho_afiado", "desc": "libera a habilidade"},
	{"id": "ligeireza", "ramo": "Arco", "nome": "Ligeireza", "efeito": "vel_pct", "valor": 0.04, "max": 5, "req": "olho_afiado", "desc": "+4% vel. de ataque"},
	{"id": "t_chuva", "ramo": "Arco", "nome": "Chuva de Flechas", "efeito": "skill", "skill": "chuva", "valor": 0.0, "max": 1, "req": "t_tiro", "desc": "libera a habilidade"},
	{"id": "t_olho", "ramo": "Arco", "nome": "Olho de Águia", "efeito": "skill", "skill": "olho", "valor": 0.0, "max": 1, "req": "ligeireza", "desc": "libera a habilidade"},
	{"id": "ferocidade", "ramo": "Arco", "nome": "Ferocidade", "efeito": "crit_mult", "valor": 0.10, "max": 3, "req": "t_chuva", "desc": "+10% dano crítico"},
	# --- Cultivo (a fazenda lê estes bônus) ---
	{"id": "maos_ouro", "ramo": "Cultivo", "nome": "Mãos de Ouro", "efeito": "ouro_pct", "valor": 0.05, "max": 5, "req": "", "desc": "+5% ouro"},
	{"id": "estudioso", "ramo": "Cultivo", "nome": "Estudioso", "efeito": "xp_pct", "valor": 0.05, "max": 5, "req": "maos_ouro", "desc": "+5% XP"},
	{"id": "colheita_farta", "ramo": "Cultivo", "nome": "Colheita Farta", "efeito": "colheita_pct", "valor": 0.25, "max": 4, "req": "", "desc": "+25% colheita"},
	{"id": "polegar_verde", "ramo": "Cultivo", "nome": "Polegar Verde", "efeito": "crescimento_pct", "valor": 0.08, "max": 4, "req": "colheita_farta", "desc": "+8% crescimento"},
]
const RESET_TALENTOS_CUSTO := 100.0   # ouro por nivel do heroi

# ---------- Habilidades automaticas ----------
# Usadas da esquerda para a direita: a cada GCD usa a primeira pronta da fila. Sao liberadas pela arvore de
# talentos (exceto a "inicial"). tipo: dano (mult do ataque x golpes), cura (% vida),
# buff_crit (+chance critica por duracao), escudo (reducao de dano por duracao).
# efeito = animacao feita por codigo (ver skills.gd): corte, giro, projetil, raio, chuva, enxada, cura, escudo, mira
const SLOTS_HABILIDADE := 4
const GCD_HABILIDADE := 1.0
const HABILIDADE_BONUS_POR_NIVEL := 0.10   # +10% do efeito por nivel da habilidade (comprado com ouro)
const HABILIDADE_CUSTO_BASE := 30.0
const HABILIDADE_CUSTO_CRESC := 1.6
const HABILIDADES := [
	{"id": "golpe", "nome": "Corte Rápido", "estilo": "fisico", "inicial": true, "tipo": "dano", "mult": 1.8, "golpes": 1, "cd": 4.0, "efeito": "corte", "desc": "180% do ataque"},
	{"id": "giratorio", "nome": "Golpe Giratório", "estilo": "fisico", "tipo": "dano", "mult": 3.0, "golpes": 1, "cd": 8.0, "efeito": "giro", "desc": "300% do ataque"},
	{"id": "postura", "nome": "Postura de Ferro", "estilo": "fisico", "tipo": "escudo", "valor": 0.4, "duracao": 8.0, "cd": 14.0, "efeito": "escudo", "desc": "-40% dano por 8s"},
	{"id": "enxadada", "nome": "Enxadada Lendária", "estilo": "fisico", "tipo": "dano", "mult": 5.0, "golpes": 1, "cd": 12.0, "efeito": "enxada", "desc": "500% do ataque (a enxada do destino)"},
	{"id": "fogo", "nome": "Bola de Fogo", "estilo": "magico", "tipo": "dano", "mult": 2.0, "golpes": 1, "cd": 5.0, "efeito": "projetil", "cor": Color(1.0, 0.5, 0.15), "desc": "200% do ataque"},
	{"id": "raio", "nome": "Raio Arcano", "estilo": "magico", "tipo": "dano", "mult": 3.5, "golpes": 1, "cd": 9.0, "efeito": "raio", "cor": Color(0.6, 0.8, 1.0), "desc": "350% do ataque"},
	{"id": "cura", "nome": "Cura Verde", "estilo": "magico", "tipo": "cura", "valor": 0.25, "cd": 15.0, "efeito": "cura", "desc": "cura 25% da vida"},
	{"id": "tiro", "nome": "Tiro Preciso", "estilo": "distancia", "tipo": "dano", "mult": 1.7, "golpes": 1, "cd": 4.0, "efeito": "projetil", "cor": Color(0.85, 0.95, 0.5), "desc": "170% do ataque"},
	{"id": "chuva", "nome": "Chuva de Flechas", "estilo": "distancia", "tipo": "dano", "mult": 1.1, "golpes": 3, "cd": 8.0, "efeito": "chuva", "cor": Color(0.85, 0.95, 0.5), "desc": "3 golpes de 110%"},
	{"id": "olho", "nome": "Olho de Águia", "estilo": "distancia", "tipo": "buff_crit", "valor": 0.3, "duracao": 8.0, "cd": 14.0, "efeito": "mira", "desc": "+30% crítico por 8s"},
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
const NOMES_ITEM := ["Espada", "Armadura", "Amuleto"]            # o nome da arma vem de TIPOS_ARMA
const NOMES_ITEM_ZONA2 := ["Espada de Aço", "Armadura de Aço", "Amuleto de Prata"]
# A arma sorteia um tipo; o estilo dele combina com as habilidades do mesmo estilo (AFINIDADE_*)
const TIPOS_ARMA := [
	{"nome": "Espada", "nome_zona2": "Espada de Aço", "estilo": "fisico", "curto": "Esp"},
	{"nome": "Cajado", "nome_zona2": "Cajado de Carvalho", "estilo": "magico", "curto": "Caj"},
	{"nome": "Arco", "nome_zona2": "Arco Longo", "estilo": "distancia", "curto": "Arc"},
]
const MOCHILA_TAMANHO := 24          # drops ficam na mochila; cheia = o item de menor valor e vendido
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