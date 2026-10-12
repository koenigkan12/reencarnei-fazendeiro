extends RefCounted
# Sistema EQUIPAMENTO: 3 espacos, mochila, drops com raridade e melhoria +N (ouro + minerio).
# Os drops vao para a mochila (ou sao equipados sozinhos se "auto_equipar" e o CP sobe).
# Os status somados ao heroi sao calculados em personagem.gd.
const Cfg := preload("res://scripts/cfg.gd")

var e                         # Estado (raiz)
var equipado: Array = [null, null, null]   # item (Dictionary) ou null por espaco
var mochila: Array = []                    # itens guardados (ate Cfg.MOCHILA_TAMANHO)
var auto_equipar := true                   # equipa sozinho o drop que aumenta o CP

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
	var it := {"slot": slot, "raridade": rar, "fase": fase, "zona2": zona2, "vida": 0.0, "dano": 0.0, "mais": 0, "tipo": -1}
	match slot:
		0:
			it["dano"] = Cfg.ITEM_DANO_BASE * m
			it["tipo"] = randi() % Cfg.TIPOS_ARMA.size()
		1: it["vida"] = Cfg.ITEM_VIDA_BASE * m
		2:
			it["dano"] = Cfg.ITEM_DANO_BASE * m * 0.5
			it["vida"] = Cfg.ITEM_VIDA_BASE * m * 0.5
	return it

# Sorteia drop. Equipa sozinho se auto_equipar e o CP sobe; senao guarda na mochila (cheia: vende o de menor valor).
# Devolve {} se nao dropou. info: {item, equipou, ouro (de venda automatica), acao (texto para a tela)}
func tenta_drop(fase: int, chefe: bool) -> Dictionary:
	if not chefe and randf() > Cfg.DROP_CHANCE:
		return {}
	var it := gera_item(fase, chefe)
	var info := {"item": it, "equipou": false, "ouro": 0, "acao": ""}
	if auto_equipar and cp_se_equipar(it) > e.personagem.cp():
		var antigo = equipado[it["slot"]]
		equipado[it["slot"]] = it
		info["equipou"] = true
		info["acao"] = "equipado"
		if antigo != null:
			info["ouro"] = _guarda(antigo)
	else:
		info["ouro"] = _guarda(it)
		info["acao"] = "na mochila" if info["ouro"] == 0 else "mochila cheia: vendido +%d ouro" % info["ouro"]
	e.ouro += info["ouro"]
	e.notifica()
	e.item_dropou.emit(info)
	return info

func cp_se_equipar(it: Dictionary) -> int:
	var teste := equipado.duplicate()
	teste[it["slot"]] = it
	return e.personagem.cp_com(teste)

# Guarda na mochila. Mochila cheia: vende o item de menor valor (pode ser o proprio). Devolve o ouro da venda (0 se coube).
func _guarda(it: Dictionary) -> int:
	if mochila.size() < Cfg.MOCHILA_TAMANHO:
		mochila.append(it)
		return 0
	var pior := -1          # -1 = o proprio item
	var valor_pior := valor_venda(it)
	for i in mochila.size():
		var v := valor_venda(mochila[i])
		if v < valor_pior:
			valor_pior = v
			pior = i
	if pior != -1:
		mochila[pior] = it
	return valor_pior

# ---------- mochila ----------
# Equipa o item da mochila trocando de lugar com o que estava no espaco
func equipa_da_mochila(i: int) -> bool:
	if i < 0 or i >= mochila.size():
		return false
	var it: Dictionary = mochila[i]
	var antigo = equipado[it["slot"]]
	equipado[it["slot"]] = it
	if antigo == null:
		mochila.remove_at(i)
	else:
		mochila[i] = antigo
	e.notifica()
	return true

func vende_da_mochila(i: int) -> bool:
	if i < 0 or i >= mochila.size():
		return false
	e.ouro += valor_venda(mochila[i])
	mochila.remove_at(i)
	e.notifica()
	return true

# Vende tudo da mochila ate a raridade dada (0 = so os Comuns). Devolve o ouro.
func vende_ate_raridade(max_raridade: int) -> int:
	var total := 0
	for i in range(mochila.size() - 1, -1, -1):
		if mochila[i]["raridade"] <= max_raridade:
			total += valor_venda(mochila[i])
			mochila.remove_at(i)
	e.ouro += total
	e.notifica()
	return total

# quanto o CP muda se o item da mochila for equipado
func delta_cp_mochila(i: int) -> int:
	return cp_se_equipar(mochila[i]) - e.personagem.cp()

func nome_base_item(it: Dictionary) -> String:
	if it["tipo"] >= 0:
		return Cfg.TIPOS_ARMA[it["tipo"]]["nome_zona2" if it["zona2"] else "nome"]
	return (Cfg.NOMES_ITEM_ZONA2 if it["zona2"] else Cfg.NOMES_ITEM)[it["slot"]]

func nome_item(it: Dictionary) -> String:
	var s := "%s %s" % [nome_base_item(it), Cfg.RARIDADES[it["raridade"]]["nome"]]
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
	if it["tipo"] >= 0:
		partes.append("estilo %s" % Cfg.ESTILOS[Cfg.TIPOS_ARMA[it["tipo"]]["estilo"]]["nome"])
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

# ---------- salvar ----------
func para_dict() -> Dictionary:
	return {"equipado": equipado.duplicate(true), "mochila": mochila.duplicate(true), "auto_equipar": auto_equipar}

func de_dict(d: Dictionary) -> void:
	var eq: Array = d.get("equipado", [])
	for k in mini(eq.size(), equipado.size()):
		equipado[k] = _item_de_dict(eq[k])
	mochila.clear()
	for it in d.get("mochila", []):
		if mochila.size() < Cfg.MOCHILA_TAMANHO:
			mochila.append(_item_de_dict(it))
	auto_equipar = d.get("auto_equipar", true)

# JSON devolve numeros como float: converte os inteiros do item de volta
func _item_de_dict(it):
	if it == null:
		return null
	for k in ["slot", "raridade", "fase", "mais", "tipo"]:
		it[k] = int(it[k])
	return it
