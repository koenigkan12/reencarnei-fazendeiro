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
	return Cfg.HEROI_VIDA + Cfg.HEROI_VIDA_POR_NIVEL * (nivel - 1) + upgrades["vida"] * Cfg.UPGRADES[0]["bonus"] + _soma_itens(itens, "vida")

func _dano_com(itens: Array) -> float:
	return Cfg.HEROI_DANO + Cfg.HEROI_DANO_POR_NIVEL * (nivel - 1) + upgrades["dano"] * Cfg.UPGRADES[1]["bonus"] + _soma_itens(itens, "dano")

func vida_max() -> float:
	return _vida_com(equipado)

func dano() -> float:
	return _dano_com(equipado)

func intervalo() -> float:
	return Cfg.HEROI_INTERVALO

func regen_pct() -> float:
	return Cfg.HEROI_REGEN_PCT + upgrades["regen"] * Cfg.UPGRADES[2]["bonus"]

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
	var m: float = Cfg.RARIDADES[rar]["mult"] * pow(Cfg.ITEM_ESCALA_FASE, fase - 1)
	var it := {"slot": slot, "raridade": rar, "fase": fase, "vida": 0.0, "dano": 0.0}
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
	return "%s %s" % [Cfg.NOMES_ITEM[it["slot"]], Cfg.RARIDADES[it["raridade"]]["nome"]]

func descricao_item(it: Dictionary) -> String:
	var partes: Array = []
	if it["dano"] > 0.0:
		partes.append("+%d dano" % roundi(it["dano"]))
	if it["vida"] > 0.0:
		partes.append("+%d vida" % roundi(it["vida"]))
	return ", ".join(partes)

func valor_venda(it: Dictionary) -> int:
	return floori(Cfg.VENDA_BASE * Cfg.RARIDADES[it["raridade"]]["mult"] * pow(Cfg.ITEM_ESCALA_FASE, it["fase"] - 1))
