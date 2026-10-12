extends Control
# Tela de opcoes: volume de musica e de efeitos, tela cheia e resolucao. Aplica na hora e salva ao fechar.
const Cfg := preload("res://scripts/cfg.gd")
const MenuUtil := preload("res://scripts/menu_util.gd")

signal fechou

var opcoes                      # opcoes.gd

func _ready() -> void:
	add_child(MenuUtil.fundo(Color(0.08, 0.1, 0.14, 0.97)))
	var col := MenuUtil.coluna(self, 14)
	col.add_child(MenuUtil.titulo("Opções", 44))
	_slider(col, "Volume da música", opcoes.volume_musica, func(v: float): opcoes.volume_musica = v)
	_slider(col, "Volume dos efeitos", opcoes.volume_efeitos, func(v: float): opcoes.volume_efeitos = v)
	var cheia := CheckButton.new()
	cheia.text = "Tela cheia"
	cheia.button_pressed = opcoes.tela_cheia
	cheia.toggled.connect(func(on: bool):
		opcoes.tela_cheia = on
		opcoes.aplica())
	col.add_child(cheia)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var rot := Label.new()
	rot.text = "Resolução da janela"
	rot.custom_minimum_size = Vector2(200, 0)
	h.add_child(rot)
	var ob := OptionButton.new()
	for r in Cfg.RESOLUCOES:
		ob.add_item("%d x %d" % [r.x, r.y])
	ob.select(opcoes.resolucao)
	ob.item_selected.connect(func(i: int):
		opcoes.resolucao = i
		opcoes.aplica())
	h.add_child(ob)
	col.add_child(h)
	var dica := Label.new()
	dica.text = "A resolução vale no modo janela."
	dica.modulate = Color(1, 1, 1, 0.5)
	col.add_child(dica)
	var bt := MenuUtil.botao("Voltar")
	bt.pressed.connect(fecha)
	col.add_child(bt)
	bt.grab_focus()

func _slider(col: VBoxContainer, texto: String, valor: float, ao_mudar: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var rot := Label.new()
	rot.text = texto
	rot.custom_minimum_size = Vector2(200, 0)
	h.add_child(rot)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = valor
	s.custom_minimum_size = Vector2(260, 24)
	var pct := Label.new()
	pct.text = "%d%%" % roundi(valor * 100.0)
	pct.custom_minimum_size = Vector2(50, 0)
	s.value_changed.connect(func(v: float):
		pct.text = "%d%%" % roundi(v * 100.0)
		ao_mudar.call(v)
		opcoes.aplica())
	h.add_child(s)
	h.add_child(pct)
	col.add_child(h)

func fecha() -> void:
	opcoes.salva()
	fechou.emit()
