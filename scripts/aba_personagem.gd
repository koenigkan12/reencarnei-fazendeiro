extends VBoxContainer
# Aba Personagem: status, atributos (ouro), habilidades automaticas e talentos.
const Cfg := preload("res://scripts/cfg.gd")

var estado
var _status: Label
var _attr: Array = []      # [{rotulo, botao}]
var _hab_rot: Array = []   # [{rotulo, botao}]
var _slots: Array = []     # OptionButtons
var _pontos: Label
var _tal: Array = []       # [{rotulo, botao}]
var _reset: Button
var _chave_slots := ""

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 16)
	add_child(_status)
	var sub := TabContainer.new()
	sub.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(sub)
	sub.add_child(_monta_atributos())
	sub.add_child(_monta_habilidades())
	sub.add_child(_monta_talentos())
	estado.mudou.connect(_atualiza)
	_atualiza()

func _linha(grade: GridContainer, largura_rotulo: int, largura_botao: int, texto_botao: String = "") -> Dictionary:
	var rot := Label.new()
	rot.custom_minimum_size = Vector2(largura_rotulo, 0)
	grade.add_child(rot)
	var bt := Button.new()
	bt.custom_minimum_size = Vector2(largura_botao, 30)
	grade.add_child(bt)
	return {"rotulo": rot, "botao": bt}

func _monta_atributos() -> Control:
	var grade := GridContainer.new()
	grade.name = "Atributos"
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 14)
	grade.add_theme_constant_override("v_separation", 6)
	for i in Cfg.ATRIBUTOS.size():
		var l := _linha(grade, 300, 150)
		l["botao"].pressed.connect(func(): estado.personagem.compra_atributo(i))
		_attr.append(l)
	return grade

func _monta_habilidades() -> Control:
	var v := VBoxContainer.new()
	v.name = "Habilidades"
	v.add_theme_constant_override("separation", 6)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 8)
	var t := Label.new()
	t.text = "Ordem de uso (esquerda → direita), a cada recarga:"
	topo.add_child(t)
	for s in Cfg.SLOTS_HABILIDADE:
		var ob := OptionButton.new()
		ob.custom_minimum_size = Vector2(170, 30)
		ob.item_selected.connect(func(idx: int): estado.personagem.define_slot_habilidade(s, ob.get_item_metadata(idx)))
		topo.add_child(ob)
		_slots.append(ob)
	v.add_child(topo)
	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 14)
	grade.add_theme_constant_override("v_separation", 6)
	v.add_child(grade)
	for i in Cfg.HABILIDADES.size():
		var l := _linha(grade, 300, 150)
		l["botao"].pressed.connect(func(): estado.personagem.sobe_habilidade(i))
		_hab_rot.append(l)
	return v

func _monta_talentos() -> Control:
	var v := VBoxContainer.new()
	v.name = "Talentos"
	v.add_theme_constant_override("separation", 6)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 20)
	_pontos = Label.new()
	topo.add_child(_pontos)
	_reset = Button.new()
	_reset.pressed.connect(func(): estado.personagem.reseta_talentos())
	topo.add_child(_reset)
	v.add_child(topo)
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(rolagem)
	var ramos := HBoxContainer.new()
	ramos.add_theme_constant_override("separation", 24)
	rolagem.add_child(ramos)
	var colunas := {}
	for t in Cfg.TALENTOS:
		if not colunas.has(t["ramo"]):
			var c := VBoxContainer.new()
			c.add_theme_constant_override("separation", 4)
			var tit := Label.new()
			tit.text = "— %s —" % t["ramo"]
			c.add_child(tit)
			ramos.add_child(c)
			colunas[t["ramo"]] = c
	for i in Cfg.TALENTOS.size():
		var t: Dictionary = Cfg.TALENTOS[i]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var rot := Label.new()
		rot.custom_minimum_size = Vector2(220, 0)
		rot.add_theme_font_size_override("font_size", 13)
		h.add_child(rot)
		var bt := Button.new()
		bt.text = "+"
		bt.custom_minimum_size = Vector2(36, 28)
		bt.pressed.connect(func(): estado.personagem.sobe_talento(i))
		h.add_child(bt)
		colunas[t["ramo"]].add_child(h)
		_tal.append({"rotulo": rot, "botao": bt})
	return v

func _atualiza() -> void:
	_status.text = "Estilo: %s   |   Nível %d   |   Vida %d   Ataque %d   Defesa %d   Crítico %d%% (x%.2f)   Vel. %.2f/s   Regen %.1f%%/s   |   CP %d" % [
		estado.personagem.nome_estilo(), estado.nivel, roundi(estado.personagem.vida_max()), roundi(estado.personagem.ataque()), roundi(estado.personagem.defesa()),
		roundi(estado.personagem.crit_chance() * 100.0), estado.personagem.crit_mult(), 1.0 / estado.personagem.intervalo(), estado.personagem.regen_pct() * 100.0, estado.personagem.cp()]
	for i in Cfg.ATRIBUTOS.size():
		var a: Dictionary = Cfg.ATRIBUTOS[i]
		var l: Dictionary = _attr[i]
		l["rotulo"].text = "%s  Nv %d   (%s)" % [a["nome"], estado.personagem.atributos[a["id"]], a["desc"]]
		if estado.personagem.atributo_no_maximo(i):
			l["botao"].text = "MÁXIMO"
			l["botao"].disabled = true
		else:
			var c: int = estado.personagem.custo_atributo(i)
			l["botao"].text = "Comprar: %d" % c
			l["botao"].disabled = estado.ouro < c
	# habilidades
	var chave := str(estado.nivel >= 0) + str(estado.personagem.hab_slots) + str(_liberadas())
	if chave != _chave_slots:
		_chave_slots = chave
		_reconstroi_slots()
	_atualiza_resto()

func _liberadas() -> int:
	var n := 0
	for i in Cfg.HABILIDADES.size():
		if estado.personagem.habilidade_liberada(i):
			n += 1
	return n

func _reconstroi_slots() -> void:
	for k in _slots.size():
		var ob: OptionButton = _slots[k]
		ob.clear()
		ob.add_item("(vazio)")
		ob.set_item_metadata(0, "")
		var sel := 0
		for i in Cfg.HABILIDADES.size():
			if estado.personagem.habilidade_liberada(i):
				ob.add_item(Cfg.HABILIDADES[i]["nome"])
				ob.set_item_metadata(ob.item_count - 1, Cfg.HABILIDADES[i]["id"])
				if estado.personagem.hab_slots[k] == Cfg.HABILIDADES[i]["id"]:
					sel = ob.item_count - 1
		ob.select(sel)

func _atualiza_resto() -> void:
	for i in Cfg.HABILIDADES.size():
		var h: Dictionary = Cfg.HABILIDADES[i]
		var l: Dictionary = _hab_rot[i]
		if estado.personagem.habilidade_liberada(i):
			l["rotulo"].text = "[%s] %s  Nv %d  (%s, recarga %d s)" % [Cfg.ESTILOS[h["estilo"]]["nome"], h["nome"], estado.personagem.hab_niveis[h["id"]], h["desc"], roundi(h["cd"] * estado.personagem.recarga_mult())]
			var c: int = estado.personagem.custo_habilidade(i)
			l["botao"].text = "Melhorar: %d" % c
			l["botao"].disabled = estado.ouro < c
		else:
			l["rotulo"].text = "[%s] %s  (libere na aba Talentos)" % [Cfg.ESTILOS[h["estilo"]]["nome"], h["nome"]]
			l["botao"].text = "Bloqueada"
			l["botao"].disabled = true
	# talentos
	_pontos.text = "Pontos de talento: %d  (1 por nível). Os nós com o nome de uma habilidade a liberam." % estado.personagem.pontos_talento()
	_reset.text = "Resetar talentos (%d ouro)" % estado.personagem.custo_reset_talentos()
	_reset.disabled = estado.personagem.pontos_talento_gastos() == 0 or estado.ouro < estado.personagem.custo_reset_talentos()
	for i in Cfg.TALENTOS.size():
		var t: Dictionary = Cfg.TALENTOS[i]
		var l: Dictionary = _tal[i]
		var req := ""
		if t["req"] != "" and estado.personagem.talentos[t["req"]] == 0:
			req = "  [requer %s]" % _nome_talento(t["req"])
		l["rotulo"].text = "%s %d/%d  %s%s" % [t["nome"], estado.personagem.talentos[t["id"]], t["max"], t["desc"], req]
		if t["efeito"] == "skill":
			l["rotulo"].add_theme_color_override("font_color", Cfg.ESTILOS[estado.personagem.habilidade_por_id(t["skill"])["estilo"]]["cor"])
		l["botao"].disabled = not estado.personagem.pode_talento(i)

func _nome_talento(id: String) -> String:
	for t in Cfg.TALENTOS:
		if t["id"] == id:
			return t["nome"]
	return id