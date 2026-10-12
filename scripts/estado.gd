extends RefCounted
# Estado do jogo que as abas e a batalha compartilham.
const Cfg := preload("res://scripts/cfg.gd")

signal mudou               # numeros mudaram (ouro, xp, nivel, upgrades, equipamento)
signal item_dropou(info)   # info: {item, equipou, ouro}

var ouro := 0.0
var nivel := 1
var xp := 0.0
var upgrades := {"vida": 0, "dano": 0, "regen": 0}
var equipado: Array = [null, null, null]

# ---------- XP e ouro ----------
func xp_para_subir() -> float:
	return Cfg.XP_BASE * pow(Cfg.XP_CRESCIMENTO, nivel - 1)

# devolve true se subiu de nivel
func ganha(ouro_ganho: float, xp_ganho: float) -> bool:
	ouro += ouro_ganho
	xp += xp_ganho
	var subiu := false
	while xp >= xp_para_subir():
		xp -= xp_para_subir()
		nivel += 1
		subiu = true
	mudou.emit()
	return subiu

# ---------- stats ----------
func _soma_itens(itens: Array, campo: String) -> float:
	var s := 0.0
	for it in itens:
		if it != null:
			s += it[campo]
	return s

func _vida_com(itens: Array) -> float:
	return (Cfg.HEROI_VIDA + Cfg.HEROI_VIDA_POR_NIVEL * (nivel - 1) + upgrades["vida"] * Cfg.UPGRADES[0]["bonus"] + _soma_itens(itens, "vida")) * (1.0 + buff("vida"))

func _dano_com(itens: Array) -> float:
	return (Cfg.HEROI_DANO + Cfg.HEROI_DANO_POR_NIVEL * (nivel - 1) + upgrades["dano"] * Cfg.UPGRADES[1]["bonus"] + _soma_itens(itens, "dano")) * (1.0 + buff("dano"))

func vida_max() -> float:
	return _vida_com(equipado)

func dano() -> float:
	return _dano_com(equipado)

func intervalo() -> float:
	return Cfg.HEROI_INTERVALO

func regen_pct() -> float:
	return Cfg.HEROI_REGEN_PCT + upgrades["regen"] * Cfg.UPGRADES[2]["bonus"] + buff("regen")

func _cp_com(itens: Array) -> int:
	return floori(_vida_com(itens) / Cfg.CP_VIDA_DIV + _dano_com(itens) * Cfg.CP_DANO_MULT / intervalo())

func cp() -> int:
	return _cp_com(equipado)

# ---------- upgrades ----------
func custo_upgrade(i: int) -> int:
	var u: Dictionary = Cfg.UPGRADES[i]
	return floori(u["custo_base"] * pow(u["crescimento"], upgrades[u["id"]]))

func compra_upgrade(i: int) -> bool:
	var c := custo_upgrade(i)
	if ouro < c:
		return false
	ouro -= c
	upgrades[Cfg.UPGRADES[i]["id"]] += 1
	mudou.emit()
	return true

# ---------- itens ----------
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
	var it := {"slot": slot, "raridade": rar, "fase": fase, "zona2": zona2, "vida": 0.0, "dano": 0.0}
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
	mudou.emit()
	item_dropou.emit(info)
	return info
func nome_item(it: Dictionary) -> String:
	var nomes: Array = Cfg.NOMES_ITEM_ZONA2 if it["zona2"] else Cfg.NOMES_ITEM
	return "%s %s" % [nomes[it["slot"]], Cfg.RARIDADES[it["raridade"]]["nome"]]

func descricao_item(it: Dictionary) -> String:
	var partes: Array = []
	if it["dano"] > 0.0:
		partes.append("+%d dano" % roundi(it["dano"]))
	if it["vida"] > 0.0:
		partes.append("+%d vida" % roundi(it["vida"]))
	return ", ".join(partes)

func valor_venda(it: Dictionary) -> int:
	return floori(Cfg.VENDA_BASE * Cfg.RARIDADES[it["raridade"]]["mult"] * pow(Cfg.ITEM_ESCALA_FASE, it["fase"] - 1) * (Cfg.ITEM_ZONA2_MULT if it["zona2"] else 1.0))

# ---------- Fazenda e Cultivo ----------
var sementes: Array = [0, 0, 0]
var colheita: Array = [0, 0, 0]
var canteiros: Array = []        # [{cultura: -1 vazio, restante: segundos}]
var cultivo_nivel := 1
var cultivo_xp := 0.0
var semente_selecionada := 0

func _init() -> void:
	for i in Cfg.LOTES_TOTAL:
		canteiros.append({"cultura": -1, "restante": 0.0})
	sementes[0] = 3   # comeco: algumas sementes de trigo para o jogador aprender o loop

func lotes_abertos() -> int:
	return mini(Cfg.LOTES_TOTAL, Cfg.LOTES_BASE + (cultivo_nivel - 1) / Cfg.LOTES_A_CADA)

func cultivo_xp_para_subir() -> float:
	return Cfg.CULTIVO_XP_BASE * pow(Cfg.CULTIVO_XP_CRESC, cultivo_nivel - 1)

func cultura_liberada(i: int) -> bool:
	return cultivo_nivel >= Cfg.CULTURAS[i]["nivel"]

# Semente cai de inimigos (so das culturas que o Cultivo ja libera)
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
	mudou.emit()

func planta(lote: int, cultura: int) -> bool:
	if lote >= lotes_abertos() or canteiros[lote]["cultura"] != -1 or sementes[cultura] <= 0:
		return false
	sementes[cultura] -= 1
	canteiros[lote] = {"cultura": cultura, "restante": Cfg.CULTURAS[cultura]["tempo"]}
	mudou.emit()
	return true

func lote_pronto(lote: int) -> bool:
	return canteiros[lote]["cultura"] != -1 and canteiros[lote]["restante"] <= 0.0

func colhe(lote: int) -> bool:
	if lote >= lotes_abertos() or not lote_pronto(lote):
		return false
	var c: int = canteiros[lote]["cultura"]
	colheita[c] += Cfg.RENDIMENTO
	canteiros[lote] = {"cultura": -1, "restante": 0.0}
	cultivo_xp += Cfg.CULTURAS[c]["xp"]
	while cultivo_xp >= cultivo_xp_para_subir():
		cultivo_xp -= cultivo_xp_para_subir()
		cultivo_nivel += 1
	if cultivo_nivel >= Cfg.AUTOPLANTIO_NIVEL and sementes[c] > 0:
		planta(lote, c)   # replantio automatico
	mudou.emit()
	return true

func colhe_tudo() -> void:
	for i in Cfg.LOTES_TOTAL:
		colhe(i)

func planta_em_todos(cultura: int) -> void:
	for i in lotes_abertos():
		planta(i, cultura)

func vende_colheita(cultura: int) -> void:
	ouro += colheita[cultura] * Cfg.CULTURAS[cultura]["preco"]
	colheita[cultura] = 0
	mudou.emit()

# Chamado todo quadro (a fazenda cresce mesmo com outra aba aberta)
func tick(delta: float) -> void:
	_tick_comida(delta)
	for i in lotes_abertos():
		var c: Dictionary = canteiros[i]
		if c["cultura"] != -1 and c["restante"] > 0.0:
			c["restante"] = maxf(c["restante"] - delta, 0.0)
			if c["restante"] <= 0.0 and cultivo_nivel >= Cfg.AUTOPLANTIO_NIVEL:
				colhe(i)

# ---------- Comida ----------
var pratos: Array = [0, 0, 0]                 # estoque de cada prato
var slots_comida: Array = [                   # -1 = vazio
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
	mudou.emit()
	return true

func define_slot(i: int, prato: int) -> void:
	slots_comida[i]["prato"] = prato
	mudou.emit()

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
		mudou.emit()