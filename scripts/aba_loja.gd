extends VBoxContainer
# Aba Loja: sementes e melhorias de ferramentas da fazenda.
const Cfg := preload("res://scripts/cfg.gd")

var estado
var _sem: Array = []    # por cultura: {rotulo, b1, b5}
var _ferr: Array = []   # por ferramenta: {rotulo, botao}
var _irr: Dictionary
var _vende: Button

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	var t := Label.new()
	t.text = "Sementes"
	add_child(t)
	for i in Cfg.CULTURAS.size():
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var rot := Label.new()
		rot.custom_minimum_size = Vector2(380, 0)
		h.add_child(rot)
		var b1 := Button.new()
		b1.custom_minimum_size = Vector2(130, 30)
		b1.pressed.connect(func(): estado.loja.compra_semente(i, 1))
		h.add_child(b1)
		var b5 := Button.new()
		b5.custom_minimum_size = Vector2(130, 30)
		b5.pressed.connect(func(): estado.loja.compra_semente(i, 5))
		h.add_child(b5)
		add_child(h)
		_sem.append({"rotulo": rot, "b1": b1, "b5": b5})
	var t2 := Label.new()
	t2.text = "Ferramentas (nível N atinge (2N-1)x(2N-1) lotes de uma vez)"
	add_child(t2)
	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 14)
	grade.add_theme_constant_override("v_separation", 6)
	add_child(grade)
	for f in Cfg.FERRAMENTAS:
		var rot := Label.new()
		rot.custom_minimum_size = Vector2(300, 0)
		grade.add_child(rot)
		var bt := Button.new()
		bt.custom_minimum_size = Vector2(170, 30)
		var id: String = f["id"]
		bt.pressed.connect(func(): estado.loja.melhora_ferramenta(id))
		grade.add_child(bt)
		_ferr.append({"rotulo": rot, "botao": bt})
	var rot2 := Label.new()
	rot2.custom_minimum_size = Vector2(300, 0)
	grade.add_child(rot2)
	var bt2 := Button.new()
	bt2.custom_minimum_size = Vector2(170, 30)
	bt2.pressed.connect(func(): estado.loja.melhora_irrigacao())
	grade.add_child(bt2)
	_irr = {"rotulo": rot2, "botao": bt2}
	_vende = Button.new()
	_vende.custom_minimum_size = Vector2(260, 30)
	_vende.pressed.connect(func(): estado.loja.vende_tudo())
	add_child(_vende)
	estado.mudou.connect(_atualiza)
	_atualiza()

func _atualiza() -> void:
	for i in Cfg.CULTURAS.size():
		var c: Dictionary = Cfg.CULTURAS[i]
		var l: Dictionary = _sem[i]
		var lib: bool = estado.fazenda.cultura_liberada(i)
		var p: int = floori(c["semente"])
		if lib:
			l["rotulo"].text = "Semente de %s  (%d ouro cada, cresce em %d s depois de regar)  você tem: %d" % [c["nome"], p, roundi(c["tempo"]), estado.fazenda.sementes[i]]
		else:
			l["rotulo"].text = "Semente de %s  (libera no Cultivo nível %d)" % [c["nome"], c["nivel"]]
		l["b1"].text = "Comprar 1: %d" % p
		l["b5"].text = "Comprar 5: %d" % (p * 5)
		l["b1"].disabled = not lib or estado.ouro < p
		l["b5"].disabled = not lib or estado.ouro < p * 5
	for k in Cfg.FERRAMENTAS.size():
		var f: Dictionary = Cfg.FERRAMENTAS[k]
		var l: Dictionary = _ferr[k]
		l["rotulo"].text = "%s  nível %d" % [f["nome"], estado.fazenda.ferramentas[f["id"]]]
		var c: int = estado.loja.custo_ferramenta(f["id"])
		if c < 0:
			l["botao"].text = "MÁXIMO"
			l["botao"].disabled = true
		else:
			var cm: int = estado.loja.cultivo_min_ferramenta(f["id"])
			if estado.fazenda.cultivo_nivel < cm:
				l["botao"].text = "Cultivo Nv %d" % cm
				l["botao"].disabled = true
			else:
				l["botao"].text = "Melhorar: %d" % c
				l["botao"].disabled = estado.ouro < c
	_irr["rotulo"].text = "Irrigação  nível %d  (+%d%% crescimento%s)" % [estado.fazenda.irrigacao, roundi(estado.fazenda.irrigacao * Cfg.IRRIGACAO_VEL_POR_NIVEL * 100.0), ", planta já nasce regada" if estado.fazenda.autorega() else "; nível %d: nasce regada" % Cfg.IRRIGACAO_AUTOREGA_NIVEL]
	var ci: int = estado.loja.custo_irrigacao()
	if ci < 0:
		_irr["botao"].text = "MÁXIMO"
		_irr["botao"].disabled = true
	else:
		_irr["botao"].text = "Melhorar: %d" % ci
		_irr["botao"].disabled = estado.ouro < ci
	var vt: int = estado.loja.valor_colheita()
	_vende.text = "Vender toda a colheita: +%d ouro" % vt
	_vende.disabled = vt <= 0
