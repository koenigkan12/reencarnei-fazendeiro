extends ColorRect
# Tela de cima da aba Fazenda: barra de ferramentas + mapa do terreno.
const Cfg := preload("res://scripts/cfg.gd")
const Mapa := preload("res://scripts/mapa_fazenda.gd")

signal ver_batalha

var estado
var _mapa: Control
var _cabecalho: Label
var _barra: ProgressBar
var _info: Label
var _sel: Label

func _ready() -> void:
	color = Color(0.2, 0.34, 0.2)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 12
	col.offset_top = 8
	col.offset_right = -12
	col.offset_bottom = -8
	col.add_theme_constant_override("separation", 6)
	add_child(col)

	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 10)
	col.add_child(topo)
	_cabecalho = Label.new()
	_cabecalho.add_theme_font_size_override("font_size", 20)
	topo.add_child(_cabecalho)
	_barra = ProgressBar.new()
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(140, 14)
	_barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_barra.modulate = Color(0.6, 1.0, 0.5)
	topo.add_child(_barra)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(esp)
	_info = Label.new()
	topo.add_child(_info)
	var bt := Button.new()
	bt.text = "⚔ Ver batalha"
	bt.pressed.connect(func(): ver_batalha.emit())
	topo.add_child(bt)

	var ferr := HBoxContainer.new()
	ferr.add_theme_constant_override("separation", 6)
	col.add_child(ferr)
	var grupo := ButtonGroup.new()
	var lista := [["mao", "✋ Colher"], ["enxada", "Enxada"], ["regador", "Regador"], ["picareta", "Picareta"], ["semente", "Semente"]]
	for par in lista:
		var b := Button.new()
		b.text = par[1]
		b.toggle_mode = true
		b.button_group = grupo
		b.custom_minimum_size = Vector2(110, 30)
		b.button_pressed = (par[0] == "mao")
		var id: String = par[0]
		b.pressed.connect(func(): _escolhe(id))
		ferr.add_child(b)
	_sel = Label.new()
	ferr.add_child(_sel)

	_mapa = Mapa.new()
	_mapa.estado = estado
	_mapa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mapa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_mapa)

func _escolhe(id: String) -> void:
	_mapa.ferramenta = id

func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	_cabecalho.text = "Fazenda   Cultivo Nv %d" % estado.cultivo_nivel
	_barra.max_value = estado.cultivo_xp_para_subir()
	_barra.value = estado.cultivo_xp
	_info.text = "Minério: %d    Ouro: %d" % [estado.minerio, floori(estado.ouro)]
	var c: Dictionary = Cfg.CULTURAS[estado.semente_selecionada]
	_sel.text = "Semente: %s (%d)   |   Dica: ara com a Enxada, planta, rega — a planta só cresce molhada" % [c["nome"], estado.sementes[estado.semente_selecionada]]