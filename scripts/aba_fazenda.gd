extends HBoxContainer
# Aba Fazenda (painel de baixo): escolher semente, vender colheita, cozinhar e slots de comida.
const Cfg := preload("res://scripts/cfg.gd")

var estado
var _linhas: Array = []   # por cultura: {sel, info, vende}
var _cozinha: Array = []  # por prato: {rotulo, botao}

func _ready() -> void:
	add_theme_constant_override("separation", 30)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	var tit := Label.new()
	tit.text = "Semente do plantio e colheita"
	col.add_child(tit)
	var grupo := ButtonGroup.new()
	for i in Cfg.CULTURAS.size():
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var sel := Button.new()
		sel.toggle_mode = true
		sel.button_group = grupo
		sel.custom_minimum_size = Vector2(190, 32)
		sel.button_pressed = (i == estado.fazenda.semente_selecionada)
		sel.pressed.connect(func(): estado.fazenda.semente_selecionada = i)
		h.add_child(sel)
		var info := Label.new()
		info.custom_minimum_size = Vector2(110, 0)
		h.add_child(info)
		var vende := Button.new()
		vende.custom_minimum_size = Vector2(150, 32)
		vende.pressed.connect(func(): estado.fazenda.vende_colheita(i))
		h.add_child(vende)
		col.add_child(h)
		_linhas.append({"sel": sel, "info": info, "vende": vende})
	var dica := Label.new()
	dica.text = "Compre sementes na Loja.\nRegue uma vez; a planta cresce sozinha."
	dica.modulate = Color(1, 1, 1, 0.6)
	col.add_child(dica)

	add_child(VSeparator.new())
	var col2 := VBoxContainer.new()
	col2.add_theme_constant_override("separation", 8)
	add_child(col2)
	var t2 := Label.new()
	t2.text = "Cozinha (gasta colheita; cada prato dura um tempo)"
	col2.add_child(t2)
	for i in Cfg.PRATOS.size():
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var rot := Label.new()
		rot.custom_minimum_size = Vector2(270, 0)
		h.add_child(rot)
		var bt := Button.new()
		bt.custom_minimum_size = Vector2(190, 32)
		bt.pressed.connect(func(): estado.comida.cozinha(i))
		h.add_child(bt)
		col2.add_child(h)
		_cozinha.append({"rotulo": rot, "botao": bt})
	var t3 := Label.new()
	t3.text = "Slots de comida do herói (usam o estoque sozinhos):"
	col2.add_child(t3)
	var hs := HBoxContainer.new()
	hs.add_theme_constant_override("separation", 10)
	col2.add_child(hs)
	for s in Cfg.SLOTS_COMIDA:
		var ob := OptionButton.new()
		ob.custom_minimum_size = Vector2(150, 32)
		ob.add_item("(vazio)", 0)
		for p in Cfg.PRATOS:
			ob.add_item(p["nome"])
		ob.select(estado.comida.slots_comida[s]["prato"] + 1)
		ob.item_selected.connect(func(idx: int): estado.comida.define_slot_comida(s, idx - 1))
		hs.add_child(ob)
	estado.mudou.connect(_atualiza)
	_atualiza()

func _atualiza() -> void:
	for i in Cfg.CULTURAS.size():
		var cul: Dictionary = Cfg.CULTURAS[i]
		var l: Dictionary = _linhas[i]
		var lib: bool = estado.fazenda.cultura_liberada(i)
		l["sel"].disabled = not lib
		l["sel"].text = "%s (%d sementes)" % [cul["nome"], estado.fazenda.sementes[i]] if lib else "%s (Cultivo Nv %d)" % [cul["nome"], cul["nivel"]]
		l["info"].text = "Colheita: %d" % estado.fazenda.colheita[i]
		l["vende"].text = "Vender: +%d ouro" % floori(estado.fazenda.colheita[i] * cul["preco"])
		l["vende"].disabled = estado.fazenda.colheita[i] <= 0
	for i in Cfg.PRATOS.size():
		var p: Dictionary = Cfg.PRATOS[i]
		var c: Dictionary = _cozinha[i]
		c["rotulo"].text = "%s (%s, %d s)  estoque: %d" % [p["nome"], p["desc"], roundi(p["duracao"]), estado.comida.pratos[i]]
		c["botao"].text = "Cozinhar: %d %s" % [Cfg.COZINHA_CUSTO, Cfg.CULTURAS[i]["nome"]]
		c["botao"].disabled = estado.fazenda.colheita[i] < Cfg.COZINHA_CUSTO