extends Control
# Tutorial de primeira vez: passos curtos (Cfg.TUTORIAL). Cada passo pode pedir uma aba (sinal abre_aba).
const Cfg := preload("res://scripts/cfg.gd")
const MenuUtil := preload("res://scripts/menu_util.gd")

signal abre_aba(nome: String)
signal terminou

var _passo := 0
var _titulo: Label
var _texto: Label
var _contador: Label
var _bt_ant: Button
var _bt_prox: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var painel := PanelContainer.new()
	painel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	painel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	painel.offset_top = 70
	painel.custom_minimum_size = Vector2(680, 0)
	add_child(painel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	painel.add_child(v)
	_titulo = MenuUtil.titulo("", 28)
	_titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	v.add_child(_titulo)
	_texto = Label.new()
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(640, 110)
	_texto.add_theme_font_size_override("font_size", 17)
	v.add_child(_texto)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	var pular := Button.new()
	pular.text = "Pular tutorial"
	pular.pressed.connect(func(): terminou.emit())
	h.add_child(pular)
	_contador = Label.new()
	_contador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(_contador)
	_bt_ant = Button.new()
	_bt_ant.text = "Anterior"
	_bt_ant.pressed.connect(func(): _vai(_passo - 1))
	h.add_child(_bt_ant)
	_bt_prox = Button.new()
	_bt_prox.custom_minimum_size = Vector2(120, 0)
	_bt_prox.pressed.connect(_proximo)
	h.add_child(_bt_prox)
	_vai(0)
	_bt_prox.grab_focus()

func _proximo() -> void:
	if _passo >= Cfg.TUTORIAL.size() - 1:
		terminou.emit()
	else:
		_vai(_passo + 1)

func _vai(i: int) -> void:
	_passo = clampi(i, 0, Cfg.TUTORIAL.size() - 1)
	var p: Dictionary = Cfg.TUTORIAL[_passo]
	_titulo.text = p["titulo"]
	_texto.text = p["texto"]
	_contador.text = "%d / %d" % [_passo + 1, Cfg.TUTORIAL.size()]
	_bt_ant.disabled = _passo == 0
	_bt_prox.text = "Começar!" if _passo == Cfg.TUTORIAL.size() - 1 else "Próximo"
	if p["aba"] != "":
		abre_aba.emit(p["aba"])
