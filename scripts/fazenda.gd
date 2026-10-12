extends RefCounted
# Sistema FAZENDA: terreno em grade, ferramentas (enxada, regador, picareta), sementes, crescimento
# (so cresce regado), colheita, rochas/minerio e o Cultivo (habilidade do heroi). Compras ficam em loja.gd.
const Cfg := preload("res://scripts/cfg.gd")

var e                         # Estado (raiz)

func _init(estado) -> void:
	e = estado
	for i in Cfg.LINHAS * Cfg.COLUNAS:
		terreno.append({"t": 0, "cultura": -1, "prog": 0.0, "agua": 0.0})
		if randf() < Cfg.ROCHA_INICIAL_CHANCE:
			terreno[i]["t"] = 2
	sementes[0] = 3

# terreno: Cfg.LINHAS x Cfg.COLUNAS (indice = y * COLUNAS + x)
# t: 0 grama, 1 terra, 2 rocha ; cultura -1 vazio ; prog = segundos de crescimento ; agua > 0 = regado (rega unica: dura ate a planta ficar pronta)
var terreno: Array = []
var sementes: Array = [0, 0, 0]
var colheita: Array = [0, 0, 0]
var cultivo_nivel := 1
var cultivo_xp := 0.0
var semente_selecionada := 0
var ferramentas := {"enxada": 1, "regador": 1, "picareta": 1}
var irrigacao := 0
var _timer_rocha := 0.0
var acoes_recentes: Array = []   # [{x, y, ferr}] acoes que mudaram um lote; a tela le e limpa (efeito visual)

func colunas_abertas() -> int:
	return mini(Cfg.COLUNAS, Cfg.COLUNAS_INICIAIS + cultivo_nivel - 1)

func lote_aberto(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and y < Cfg.LINHAS and x < colunas_abertas()

func lote(x: int, y: int) -> Dictionary:
	return terreno[y * Cfg.COLUNAS + x]

func cultivo_xp_para_subir() -> float:
	return Cfg.CULTIVO_XP_BASE * pow(Cfg.CULTIVO_XP_CRESC, cultivo_nivel - 1)

func cultura_liberada(i: int) -> bool:
	return cultivo_nivel >= Cfg.CULTURAS[i]["nivel"]

func agua_segundos() -> float:   # legado (rega agora dura ate ficar pronto); mantido por compatibilidade
	return Cfg.AGUA_SEGUNDOS + irrigacao * Cfg.AGUA_POR_IRRIGACAO

func autorega() -> bool:
	return irrigacao >= Cfg.IRRIGACAO_AUTOREGA_NIVEL

func _ganha_cultivo(xp: float) -> void:
	cultivo_xp += xp
	while cultivo_xp >= cultivo_xp_para_subir():
		cultivo_xp -= cultivo_xp_para_subir()
		cultivo_nivel += 1

# Acao do modo Auto no lote: rocha->picareta, grama->enxada, terra vazia->semente, pronto->colher, seco->regador
func acao_automatica(x: int, y: int) -> String:
	if not lote_aberto(x, y):
		return ""
	var l := lote(x, y)
	if l["t"] == 2:
		return "picareta"
	if l["t"] == 0:
		return "enxada"
	if l["cultura"] == -1:
		return "semente" if sementes[semente_selecionada] > 0 else ""
	if lote_pronto(x, y):
		return "mao"
	if l["agua"] <= 0.0:
		return "regador"
	return ""

func lote_pronto(x: int, y: int) -> bool:
	var l := lote(x, y)
	return l["cultura"] != -1 and l["prog"] >= Cfg.CULTURAS[l["cultura"]]["tempo"]

# Aplica a ferramenta no lote (x, y); a area depende do nivel da ferramenta.
func usa_ferramenta(nome: String, x: int, y: int) -> void:
	if nome == "auto":
		var a := acao_automatica(x, y)
		if a != "":
			usa_ferramenta(a, x, y)
		return
	var raio := 0
	if ferramentas.has(nome):
		raio = ferramentas[nome] - 1
	var mudou_algo := false
	if acoes_recentes.size() > 200:
		acoes_recentes.clear()    # ninguem esta lendo (tela fechada)
	for dy in range(-raio, raio + 1):
		for dx in range(-raio, raio + 1):
			if _aplica(nome, x + dx, y + dy):
				mudou_algo = true
				acoes_recentes.append({"x": x + dx, "y": y + dy, "ferr": nome})
	if mudou_algo:
		e.notifica()

func _aplica(nome: String, x: int, y: int) -> bool:
	if not lote_aberto(x, y):
		return false
	var l := lote(x, y)
	match nome:
		"enxada":
			if l["t"] == 0:
				l["t"] = 1
				_ganha_cultivo(Cfg.CULTIVO_XP_ARAR)
				return true
		"regador":
			# rega unica: so faz sentido em planta seca que ainda nao esta pronta
			if l["t"] == 1 and l["cultura"] != -1 and l["agua"] <= 0.0 and not lote_pronto(x, y):
				l["agua"] = 1.0
				_ganha_cultivo(Cfg.CULTIVO_XP_REGAR)
				return true
		"picareta":
			if l["t"] == 2:
				l["t"] = 0
				e.minerio += randi_range(Cfg.ROCHA_MINERIO_MIN, Cfg.ROCHA_MINERIO_MAX)
				return true
		"semente":
			if l["t"] == 1 and l["cultura"] == -1 and sementes[semente_selecionada] > 0:
				sementes[semente_selecionada] -= 1
				l["cultura"] = semente_selecionada
				l["prog"] = 0.0
				l["agua"] = 1.0 if autorega() else 0.0
				return true
		"mao":
			return _colhe(x, y)
	return false

func _colhe(x: int, y: int) -> bool:
	if not lote_pronto(x, y):
		return false
	var l := lote(x, y)
	var c: int = l["cultura"]
	colheita[c] += roundi(Cfg.RENDIMENTO * (1.0 + e.personagem.talento("colheita_pct")))
	l["cultura"] = -1
	l["prog"] = 0.0
	_ganha_cultivo(Cfg.CULTURAS[c]["xp"])
	if cultivo_nivel >= Cfg.AUTOPLANTIO_NIVEL and sementes[c] > 0:
		sementes[c] -= 1       # replantio automatico
		l["cultura"] = c
		l["agua"] = 1.0 if autorega() else 0.0
	return true

# Drop de semente dos inimigos: desligado por padrao (sementes vem da Loja). Ver Cfg.SEMENTE_DROP_ATIVO.
func tenta_semente(chefe: bool) -> void:
	if not Cfg.SEMENTE_DROP_ATIVO:
		return
	if not chefe and randf() > Cfg.SEMENTE_CHANCE:
		return
	var total := 0.0
	for i in Cfg.CULTURAS.size():
		if cultura_liberada(i):
			total += Cfg.CULTURAS[i]["peso"]
	var r := randf() * total
	var escolhida := 0
	for i in Cfg.CULTURAS.size():
		if cultura_liberada(i):
			r -= Cfg.CULTURAS[i]["peso"]
			if r <= 0.0:
				escolhida = i
				break
	sementes[escolhida] += Cfg.SEMENTES_CHEFE if chefe else 1
	e.notifica()

func vende_colheita(cultura: int) -> void:
	e.ouro += colheita[cultura] * Cfg.CULTURAS[cultura]["preco"]
	colheita[cultura] = 0
	e.notifica()


# Chamado todo quadro (a fazenda cresce mesmo com outra aba aberta)
func velocidade() -> float:
	return 1.0 + cultivo_nivel * Cfg.CULTIVO_CRESCIMENTO_POR_NIVEL + irrigacao * Cfg.IRRIGACAO_VEL_POR_NIVEL + e.personagem.talento("crescimento_pct")

func tick(delta: float) -> void:
	var vel: float = velocidade()
	for y in Cfg.LINHAS:
		for x in colunas_abertas():
			var l := lote(x, y)
			if l["agua"] > 0.0 and l["cultura"] != -1:
				l["prog"] += delta * vel
				if l["prog"] >= Cfg.CULTURAS[l["cultura"]]["tempo"]:
					l["agua"] = 0.0     # rega unica acabou: pronto para colher
	_timer_rocha += delta
	if _timer_rocha >= Cfg.ROCHA_RESPAWN_SEGUNDOS:
		_timer_rocha = 0.0
		_nasce_rocha()

func _nasce_rocha() -> void:
	var rochas := 0
	var livres: Array = []
	for y in Cfg.LINHAS:
		for x in colunas_abertas():
			var l := lote(x, y)
			if l["t"] == 2:
				rochas += 1
			elif l["t"] == 0:
				livres.append(l)
	if rochas < Cfg.ROCHA_MAX and not livres.is_empty():
		livres[randi() % livres.size()]["t"] = 2

# ---------- Save (o save global chama estes dois) ----------
func para_dicionario() -> Dictionary:
	return {"terreno": terreno.duplicate(true), "sementes": sementes.duplicate(), "colheita": colheita.duplicate(),
		"cultivo_nivel": cultivo_nivel, "cultivo_xp": cultivo_xp, "semente_selecionada": semente_selecionada,
		"ferramentas": ferramentas.duplicate(), "irrigacao": irrigacao}

func de_dicionario(d: Dictionary) -> void:
	terreno = d.get("terreno", terreno)
	sementes = d.get("sementes", sementes)
	colheita = d.get("colheita", colheita)
	cultivo_nivel = d.get("cultivo_nivel", cultivo_nivel)
	cultivo_xp = d.get("cultivo_xp", cultivo_xp)
	semente_selecionada = d.get("semente_selecionada", semente_selecionada)
	ferramentas = d.get("ferramentas", ferramentas)
	irrigacao = d.get("irrigacao", irrigacao)
	e.notifica()
