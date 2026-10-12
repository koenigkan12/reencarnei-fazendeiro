extends RefCounted
# Estado do jogo que a batalha e as abas compartilham.
const Cfg := preload("res://scripts/cfg.gd")

signal mudou               # qualquer numero mudou (ouro, xp, atributos, itens, fazenda...)
signal item_dropou(info)   # info: {item, equipou, ouro}

var ouro := 0.0
var nivel := 1
var xp := 0.0
var minerio := 0

# ---------- atributos, talentos, habilidades ----------
var atributos := {}          # id -> nivel
var talentos := {}           # id -> rank
var hab_niveis := {}         # id da habilidade -> nivel (>= 1)
var hab_slots: Array = []    # ids na ordem de uso ("" = vazio)

func _init() -> void:
	for a in Cfg.ATRIBUTOS:
		atributos[a["id"]] = 0
	for t in Cfg.TALENTOS:
		talentos[t["id"]] = 0
	for h in Cfg.HABILIDADES:
		hab_niveis[h["id"]] = 1
	hab_slots.resize(Cfg.SLOTS_HABILIDADE)
	hab_slots.fill("")
	hab_slots[0] = "golpe"
	for i in Cfg.LINHAS * Cfg.COLUNAS:
		terreno.append({"t": 0, "cultura": -1, "prog": 0.0, "agua": 0.0})
		if randf() < Cfg.ROCHA_INICIAL_CHANCE:
			terreno[i]["t"] = 2
	sementes[0] = 3

# Coalesce as notificacoes: a UI so atualiza uma vez por quadro (em tick)
var _sujo := false

func _notifica() -> void:
	_sujo = true

# ---------- XP e ouro ----------
func xp_para_subir() -> float:
	return Cfg.XP_BASE * pow(Cfg.XP_CRESCIMENTO, nivel - 1)

# devolve true se subiu de nivel
func ganha(ouro_ganho: float, xp_ganho: float) -> bool:
	ouro += ouro_ganho * (1.0 + talento("ouro_pct"))
	xp += xp_ganho * (1.0 + talento("xp_pct"))
	var subiu := false
	while xp >= xp_para_subir():
		xp -= xp_para_subir()
		nivel += 1
		subiu = true
		_equipa_habilidades_novas()
	_notifica()
	return subiu

# ---------- talentos ----------
func talento(efeito: String) -> float:
	var s := 0.0
	for t in Cfg.TALENTOS:
		if t["efeito"] == efeito:
			s += talentos[t["id"]] * t["valor"]
	return s

func pontos_talento_gastos() -> int:
	var s := 0
	for t in Cfg.TALENTOS:
		s += talentos[t["id"]]
	return s

func pontos_talento() -> int:
	return (nivel - 1) - pontos_talento_gastos()

func pode_talento(i: int) -> bool:
	var t: Dictionary = Cfg.TALENTOS[i]
	if pontos_talento() <= 0 or talentos[t["id"]] >= t["max"]:
		return false
	return t["req"] == "" or talentos[t["req"]] > 0

func sobe_talento(i: int) -> void:
	if pode_talento(i):
		talentos[Cfg.TALENTOS[i]["id"]] += 1
		_notifica()

func custo_reset_talentos() -> int:
	return floori(Cfg.RESET_TALENTOS_CUSTO * nivel)

func reseta_talentos() -> bool:
	if pontos_talento_gastos() == 0 or ouro < custo_reset_talentos():
		return false
	ouro -= custo_reset_talentos()
	for t in Cfg.TALENTOS:
		talentos[t["id"]] = 0
	_notifica()
	return true

# ---------- stats ----------
func _soma_itens(itens: Array, campo: String) -> float:
	var s := 0.0
	for it in itens:
		if it != null:
			s += it[campo] * (1.0 + Cfg.MAIS_BONUS * it["mais"])
	return s

func _atr(id: String) -> int:
	return atributos[id]

func _bonus(id: String) -> float:
	for a in Cfg.ATRIBUTOS:
		if a["id"] == id:
			return a["bonus"]
	return 0.0

func _vida_com(itens: Array) -> float:
	var base := Cfg.HEROI_VIDA + Cfg.HEROI_VIDA_POR_NIVEL * (nivel - 1) + _atr("vida") * _bonus("vida") + _soma_itens(itens, "vida")
	return base * (1.0 + buff("vida") + talento("vida_pct"))

func _ataque_com(itens: Array) -> float:
	var base := Cfg.HEROI_DANO + Cfg.HEROI_DANO_POR_NIVEL * (nivel - 1) + _atr("ataque") * _bonus("ataque") + _soma_itens(itens, "dano")
	return base * (1.0 + buff("dano") + talento("dano_pct"))

func vida_max() -> float:
	return _vida_com(equipado)

func ataque() -> float:
	return _ataque_com(equipado)

func defesa() -> float:
	return _atr("defesa") * _bonus("defesa") * (1.0 + talento("defesa_pct"))

func reducao_dano() -> float:    # multiplicador do dano recebido
	return Cfg.DEFESA_CONSTANTE / (Cfg.DEFESA_CONSTANTE + defesa())

func crit_chance() -> float:
	return minf(Cfg.HEROI_CRIT + _atr("critico") * _bonus("critico") + talento("crit"), 0.8)

func crit_mult() -> float:
	return Cfg.HEROI_CRIT_MULT + _atr("dano_critico") * _bonus("dano_critico") + talento("crit_mult")

func intervalo() -> float:
	return Cfg.HEROI_INTERVALO / (1.0 + _atr("vel_ataque") * _bonus("vel_ataque"))

func regen_pct() -> float:
	return Cfg.HEROI_REGEN_PCT + _atr("recuperacao") * _bonus("recuperacao") + talento("regen") + buff("regen")

func _cp_com(itens: Array) -> int:
	var dps := _ataque_com(itens) / intervalo() * (1.0 + crit_chance() * (crit_mult() - 1.0))
	return floori(_vida_com(itens) / Cfg.CP_VIDA_DIV + dps * Cfg.CP_DANO_MULT + defesa() * Cfg.CP_DEFESA_MULT)

func cp() -> int:
	return _cp_com(equipado)

# ---------- atributos (compra) ----------
func custo_atributo(i: int) -> int:
	var a: Dictionary = Cfg.ATRIBUTOS[i]
	return floori(a["custo_base"] * pow(a["crescimento"], atributos[a["id"]]))

func atributo_no_maximo(i: int) -> bool:
	var a: Dictionary = Cfg.ATRIBUTOS[i]
	return a["max"] > 0 and atributos[a["id"]] >= a["max"]

func compra_atributo(i: int) -> bool:
	if atributo_no_maximo(i):
		return false
	var c := custo_atributo(i)
	if ouro < c:
		return false
	ouro -= c
	atributos[Cfg.ATRIBUTOS[i]["id"]] += 1
	_notifica()
	return true

# ---------- habilidades ----------
func habilidade_liberada(i: int) -> bool:
	return nivel >= Cfg.HABILIDADES[i]["nivel"]

func fator_habilidade(id: String) -> float:
	return 1.0 + Cfg.HABILIDADE_BONUS_POR_NIVEL * (hab_niveis[id] - 1)

func custo_habilidade(i: int) -> int:
	return floori(Cfg.HABILIDADE_CUSTO_BASE * pow(Cfg.HABILIDADE_CUSTO_CRESC, hab_niveis[Cfg.HABILIDADES[i]["id"]] - 1))

func sobe_habilidade(i: int) -> bool:
	var c := custo_habilidade(i)
	if not habilidade_liberada(i) or ouro < c:
		return false
	ouro -= c
	hab_niveis[Cfg.HABILIDADES[i]["id"]] += 1
	_notifica()
	return true

func define_slot_habilidade(slot: int, id: String) -> void:
	if id != "":
		for k in hab_slots.size():
			if hab_slots[k] == id:
				hab_slots[k] = ""     # uma habilidade so pode estar em um slot
	hab_slots[slot] = id
	_notifica()

func _equipa_habilidades_novas() -> void:
	for h in Cfg.HABILIDADES:
		if nivel == h["nivel"] and not hab_slots.has(h["id"]):
			var livre := hab_slots.find("")
			if livre != -1:
				hab_slots[livre] = h["id"]

func habilidade_por_id(id: String) -> Dictionary:
	for h in Cfg.HABILIDADES:
		if h["id"] == id:
			return h
	return {}

# ---------- equipamento ----------
var equipado: Array = [null, null, null]

func _sorteia_raridade(chefe: bool) -> int:
	var total := 0.0
	var pesos: Array = []
	for i in Cfg.RARIDADES.size():
		var p: float = Cfg.RARIDADES[i]["peso"]
		if chefe and i > 0:
			p *= Cfg.DROP_BONUS_RARIDADE_CHEFE
		pesos.append(p)
		total += p
	var r := randf() * total
	for i in pesos.size():
		r -= pesos[i]
		if r <= 0.0:
			return i
	return 0

func gera_item(fase: int, chefe: bool) -> Dictionary:
	var slot := randi() % 3
	var rar := _sorteia_raridade(chefe)
	var zona2 := fase >= Cfg.ZONA2_A_PARTIR_DA_FASE
	var m: float = Cfg.RARIDADES[rar]["mult"] * pow(Cfg.ITEM_ESCALA_FASE, fase - 1) * (Cfg.ITEM_ZONA2_MULT if zona2 else 1.0)
	var it := {"slot": slot, "raridade": rar, "fase": fase, "zona2": zona2, "vida": 0.0, "dano": 0.0, "mais": 0}
	match slot:
		0: it["dano"] = Cfg.ITEM_DANO_BASE * m
		1: it["vida"] = Cfg.ITEM_VIDA_BASE * m
		2:
			it["dano"] = Cfg.ITEM_DANO_BASE * m * 0.5
			it["vida"] = Cfg.ITEM_VIDA_BASE * m * 0.5
	return it

# Sorteia drop. Equipa sozinho se o CP sobe; senao vende. Devolve {} se nao dropou.
func tenta_drop(fase: int, chefe: bool) -> Dictionary:
	if not chefe and randf() > Cfg.DROP_CHANCE:
		return {}
	var it := gera_item(fase, chefe)
	var teste := equipado.duplicate()
	teste[it["slot"]] = it
	var info := {"item": it, "equipou": false, "ouro": 0}
	if _cp_com(teste) > cp():
		equipado[it["slot"]] = it
		info["equipou"] = true
	else:
		info["ouro"] = valor_venda(it)
		ouro += info["ouro"]
	_notifica()
	item_dropou.emit(info)
	return info

func nome_item(it: Dictionary) -> String:
	var nomes: Array = Cfg.NOMES_ITEM_ZONA2 if it["zona2"] else Cfg.NOMES_ITEM
	var s := "%s %s" % [nomes[it["slot"]], Cfg.RARIDADES[it["raridade"]]["nome"]]
	if it["mais"] > 0:
		s += " +%d" % it["mais"]
	return s

func descricao_item(it: Dictionary) -> String:
	var f: float = 1.0 + Cfg.MAIS_BONUS * it["mais"]
	var partes: Array = []
	if it["dano"] > 0.0:
		partes.append("+%d ataque" % roundi(it["dano"] * f))
	if it["vida"] > 0.0:
		partes.append("+%d vida" % roundi(it["vida"] * f))
	return ", ".join(partes)

func valor_venda(it: Dictionary) -> int:
	return floori(Cfg.VENDA_BASE * Cfg.RARIDADES[it["raridade"]]["mult"] * pow(Cfg.ITEM_ESCALA_FASE, it["fase"] - 1) * (Cfg.ITEM_ZONA2_MULT if it["zona2"] else 1.0))

# melhoria +N do item equipado no slot
func custo_mais_ouro(slot: int) -> int:
	return floori(Cfg.MAIS_OURO_BASE * pow(Cfg.MAIS_OURO_CRESC, equipado[slot]["mais"]))

func custo_mais_minerio(slot: int) -> int:
	return Cfg.MAIS_MINERIO_BASE + equipado[slot]["mais"] * Cfg.MAIS_MINERIO_POR_NIVEL

func pode_melhorar(slot: int) -> bool:
	var it = equipado[slot]
	return it != null and it["mais"] < Cfg.MAIS_MAX and ouro >= custo_mais_ouro(slot) and minerio >= custo_mais_minerio(slot)

func melhora_item(slot: int) -> bool:
	if not pode_melhorar(slot):
		return false
	ouro -= custo_mais_ouro(slot)
	minerio -= custo_mais_minerio(slot)
	equipado[slot]["mais"] += 1
	_notifica()
	return true

# ================= FAZENDA =================
# terreno: Cfg.LINHAS x Cfg.COLUNAS (indice = y * COLUNAS + x)
# t: 0 grama, 1 terra, 2 rocha ; cultura -1 vazio ; prog = segundos regados de crescimento ; agua = segundos de agua restante
var terreno: Array = []
var sementes: Array = [0, 0, 0]
var colheita: Array = [0, 0, 0]
var cultivo_nivel := 1
var cultivo_xp := 0.0
var semente_selecionada := 0
var ferramentas := {"enxada": 1, "regador": 1, "picareta": 1}
var irrigacao := 0
var _timer_rocha := 0.0

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

func agua_segundos() -> float:
	return Cfg.AGUA_SEGUNDOS + irrigacao * Cfg.AGUA_POR_IRRIGACAO

func lote_pronto(x: int, y: int) -> bool:
	var l := lote(x, y)
	return l["cultura"] != -1 and l["prog"] >= Cfg.CULTURAS[l["cultura"]]["tempo"]

# Aplica a ferramenta no lote (x, y); a area depende do nivel da ferramenta.
func usa_ferramenta(nome: String, x: int, y: int) -> void:
	var raio := 0
	if ferramentas.has(nome):
		raio = ferramentas[nome] - 1
	var mudou_algo := false
	for dy in range(-raio, raio + 1):
		for dx in range(-raio, raio + 1):
			if _aplica(nome, x + dx, y + dy):
				mudou_algo = true
	if mudou_algo:
		_notifica()

func _aplica(nome: String, x: int, y: int) -> bool:
	if not lote_aberto(x, y):
		return false
	var l := lote(x, y)
	match nome:
		"enxada":
			if l["t"] == 0:
				l["t"] = 1
				return true
		"regador":
			if l["t"] == 1:
				l["agua"] = agua_segundos()
				return true
		"picareta":
			if l["t"] == 2:
				l["t"] = 0
				minerio += randi_range(Cfg.ROCHA_MINERIO_MIN, Cfg.ROCHA_MINERIO_MAX)
				return true
		"semente":
			if l["t"] == 1 and l["cultura"] == -1 and sementes[semente_selecionada] > 0:
				sementes[semente_selecionada] -= 1
				l["cultura"] = semente_selecionada
				l["prog"] = 0.0
				return true
		"mao":
			return _colhe(x, y)
	return false

func _colhe(x: int, y: int) -> bool:
	if not lote_pronto(x, y):
		return false
	var l := lote(x, y)
	var c: int = l["cultura"]
	colheita[c] += roundi(Cfg.RENDIMENTO * (1.0 + talento("colheita_pct")))
	l["cultura"] = -1
	l["prog"] = 0.0
	cultivo_xp += Cfg.CULTURAS[c]["xp"]
	while cultivo_xp >= cultivo_xp_para_subir():
		cultivo_xp -= cultivo_xp_para_subir()
		cultivo_nivel += 1
	if cultivo_nivel >= Cfg.AUTOPLANTIO_NIVEL and sementes[c] > 0:
		sementes[c] -= 1       # replantio automatico
		l["cultura"] = c
	return true

# Tenta fazer a semente cair de um inimigo (so das culturas que o Cultivo ja libera)
func tenta_semente(chefe: bool) -> void:
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
	_notifica()

func vende_colheita(cultura: int) -> void:
	ouro += colheita[cultura] * Cfg.CULTURAS[cultura]["preco"]
	colheita[cultura] = 0
	_notifica()

# ---------- loja ----------
func compra_semente(cultura: int, qtd: int) -> bool:
	var custo: float = Cfg.CULTURAS[cultura]["semente"] * qtd
	if not cultura_liberada(cultura) or ouro < custo:
		return false
	ouro -= custo
	sementes[cultura] += qtd
	_notifica()
	return true

func custo_ferramenta(id: String) -> int:
	var nv: int = ferramentas[id]
	for f in Cfg.FERRAMENTAS:
		if f["id"] == id and nv - 1 < f["custos"].size():
			return floori(f["custos"][nv - 1])
	return -1    # no maximo

func melhora_ferramenta(id: String) -> bool:
	var c := custo_ferramenta(id)
	if c < 0 or ouro < c:
		return false
	ouro -= c
	ferramentas[id] += 1
	_notifica()
	return true

func custo_irrigacao() -> int:
	return floori(Cfg.IRRIGACAO_CUSTOS[irrigacao]) if irrigacao < Cfg.IRRIGACAO_CUSTOS.size() else -1

func melhora_irrigacao() -> bool:
	var c := custo_irrigacao()
	if c < 0 or ouro < c:
		return false
	ouro -= c
	irrigacao += 1
	_notifica()
	return true

# Chamado todo quadro (a fazenda cresce mesmo com outra aba aberta)
func tick(delta: float) -> void:
	_tick_comida(delta)
	if _sujo:
		_sujo = false
		mudou.emit()
	var vel := 1.0 + cultivo_nivel * Cfg.CULTIVO_CRESCIMENTO_POR_NIVEL + talento("crescimento_pct")
	for y in Cfg.LINHAS:
		for x in colunas_abertas():
			var l := lote(x, y)
			if l["agua"] > 0.0:
				l["agua"] = maxf(l["agua"] - delta, 0.0)
				if l["cultura"] != -1:
					l["prog"] += delta * vel
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

# ================= COMIDA =================
var pratos: Array = [0, 0, 0]                 # estoque de cada prato
var slots_comida: Array = [                   # prato -1 = vazio
	{"prato": 0, "restante": 0.0}, {"prato": 1, "restante": 0.0}, {"prato": 2, "restante": 0.0}]

# soma dos efeitos ativos de um tipo ("regen", "vida", "dano")
func buff(efeito: String) -> float:
	var s := 0.0
	for sl in slots_comida:
		if sl["prato"] != -1 and sl["restante"] > 0.0:
			var p: Dictionary = Cfg.PRATOS[sl["prato"]]
			if p["efeito"] == efeito:
				s += p["valor"]
	return s

func cozinha(prato: int) -> bool:
	if colheita[prato] < Cfg.COZINHA_CUSTO:
		return false
	colheita[prato] -= Cfg.COZINHA_CUSTO
	pratos[prato] += 1
	_notifica()
	return true

func define_slot_comida(i: int, prato: int) -> void:
	slots_comida[i]["prato"] = prato
	_notifica()

# Consome sozinho a proxima unidade do estoque quando o efeito do slot acaba
func _tick_comida(delta: float) -> void:
	var mudaram := false
	for sl in slots_comida:
		if sl["prato"] == -1:
			continue
		if sl["restante"] > 0.0:
			sl["restante"] = maxf(sl["restante"] - delta, 0.0)
			if sl["restante"] <= 0.0:
				mudaram = true
		if sl["restante"] <= 0.0 and pratos[sl["prato"]] > 0:
			pratos[sl["prato"]] -= 1
			sl["restante"] = Cfg.PRATOS[sl["prato"]]["duracao"]
			mudaram = true
	if mudaram:
		_notifica()