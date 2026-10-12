extends ColorRect
# Tela de cima da aba Fazenda: lotes clicaveis (placeholder visual).
# Clique em lote vazio planta a semente selecionada; em lote pronto, colhe.
const Cfg := preload("res://scripts/cfg.gd")

var estado
var _col: VBoxContainer
var _botoes: Array = []
var _cabecalho: Label
var _barra: ProgressBar

func _ready() -> void:
	color = Color(0.36, 0.6, 0.28)
	_col = VBoxContainer.new()
	_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	_col.offset_left = 16
	_col.offset_top = 10
	_col.offset_right = -16
	_col.offset_bottom = -10
	_col.add_theme_constant_override("separation", 12)
	add_child(_col)
	_cabecalho = Label.new()
	_cabecalho.add_theme_font_size_override("font_size", 22)
	_col.add_child(_cabecalho)
	_barra = ProgressBar.new()
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(260, 14)
	_barra.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_barra.modulate = Color(0.6, 1.0, 0.5)
	_col.add_child(_barra)
	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 20)
	grade.add_theme_constant_override("v_separation", 16)
	grade.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grade.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_col.add_child(grade)
	for i in Cfg.LOTES_TOTAL:
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 80)
		b.pressed.connect(func(): _clicou(i))
		grade.add_child(b)
		_botoes.append(b)

func _clicou(i: int) -> void:
	if estado.lote_pronto(i):
		estado.colhe(i)
	elif estado.canteiros[i]["cultura"] == -1:
		estado.planta(i, estado.semente_selecionada)

func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	_cabecalho.text = "Fazenda   |   Cultivo Nv %d" % estado.cultivo_nivel
	_barra.max_value = estado.cultivo_xp_para_subir()
	_barra.value = estado.cultivo_xp
	var abertos: int = estado.lotes_abertos()
	for i in Cfg.LOTES_TOTAL:
		var b: Button = _botoes[i]
		var c: Dictionary = estado.canteiros[i]
		b.disabled = false
		if i >= abertos:
			b.text = "Bloqueado\n(sobe o Cultivo)"
			b.disabled = true
		elif c["cultura"] == -1:
			b.text = "Vazio\n(clique para plantar)"
		else:
			var cul: Dictionary = Cfg.CULTURAS[c["cultura"]]
			if c["restante"] <= 0.0:
				b.text = "%s\nPRONTO! Colher" % cul["nome"]
			else:
				b.text = "%s\n%d s" % [cul["nome"], ceili(c["restante"])]