extends RefCounted
# Sistema EQUIPAMENTO: 3 espacos, drops com raridade, auto-equipar o melhor / vender o resto
# e melhoria +N (ouro + minerio). Os status somados ao heroi sao calculados em personagem.gd.
const Cfg := preload("res://scripts/cfg.gd")

var e                         # Estado (raiz)
var equipado: Array = [null, null, null]   # item (Dictionary) ou null por espaco

func _init(estado) -> void:
	e = estado

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
	if e.personagem.cp_com(teste) > e.personagem.cp():
		equipado[it["slot"]] = it
		info["equipou"] = true
	else:
		info["ouro"] = valor_venda(it)
		e.ouro += info["ouro"]
	e.notifica()
	e.item_dropou.emit(info)
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
	return it != null and it["mais"] < Cfg.MAIS_MAX and e.ouro >= custo_mais_ouro(slot) and e.minerio >= custo_mais_minerio(slot)

func melhora_item(slot: int) -> bool:
	if not pode_melhorar(slot):
		return false
	e.ouro -= custo_mais_ouro(slot)
	e.minerio -= custo_mais_minerio(slot)
	equipado[slot]["mais"] += 1
	e.notifica()
	return true

