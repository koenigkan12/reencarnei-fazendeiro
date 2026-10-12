extends Control
# Esqueleto do dia 2: area de batalha em cima, painel com 4 abas embaixo.
# A interface e montada por codigo para evitar .tscn escrito a mao.

const ABAS := ["Personagem", "Equipamento", "Fazenda", "Loja"]
const ALTURA_PAINEL := 280
const Batalha := preload("res://scripts/batalha.gd")

var batalha: Control
var fazenda: Control
var _indicador: Label

func _ready() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)

	var topo := Control.new()
	topo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	topo.clip_contents = true
	raiz.add_child(topo)
	var a := _cria_area_batalha()
	a.set_anchors_preset(Control.PRESET_FULL_RECT)
	topo.add_child(a)
	fazenda = _cria_fazenda()
	fazenda.set_anchors_preset(Control.PRESET_FULL_RECT)
	fazenda.visible = false
	topo.add_child(fazenda)
	var abas := _cria_painel_abas()
	abas.tab_changed.connect(_troca_aba)
	raiz.add_child(abas)

	if "--teste-batalha" in OS.get_cmdline_user_args():
		_roda_teste()


func _cria_area_batalha() -> Control:
	batalha = Batalha.new()
	batalha.name = "AreaBatalha"
	batalha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return batalha
# A tela de cima acompanha a aba: Fazenda mostra a fazenda, as outras mostram a batalha.
# A batalha continua rodando escondida (e idle).
func _troca_aba(indice: int) -> void:
	var na_fazenda: bool = ABAS[indice] == "Fazenda"
	fazenda.visible = na_fazenda
	batalha.visible = not na_fazenda

# Placeholder estatico da fazenda (arte real depois).
func _cria_fazenda() -> Control:
	var raiz := ColorRect.new()
	raiz.name = "AreaFazenda"
	raiz.color = Color(0.45, 0.68, 0.9)
	var grama := ColorRect.new()
	grama.color = Color(0.36, 0.6, 0.28)
	grama.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	grama.anchor_top = 0.35
	grama.offset_top = 0
	grama.offset_bottom = 0
	raiz.add_child(grama)
	var canteiros := GridContainer.new()
	canteiros.columns = 4
	canteiros.add_theme_constant_override("h_separation", 24)
	canteiros.add_theme_constant_override("v_separation", 20)
	canteiros.set_anchors_preset(Control.PRESET_CENTER)
	canteiros.grow_horizontal = Control.GROW_DIRECTION_BOTH
	canteiros.grow_vertical = Control.GROW_DIRECTION_BOTH
	for i in 8:
		var c := ColorRect.new()
		c.custom_minimum_size = Vector2(110, 70)
		c.color = Color(0.4, 0.27, 0.17)
		canteiros.add_child(c)
	raiz.add_child(canteiros)
	var titulo := Label.new()
	titulo.text = "Fazenda (placeholder)"
	titulo.position = Vector2(16, 10)
	titulo.add_theme_font_size_override("font_size", 22)
	raiz.add_child(titulo)
	_indicador = Label.new()
	_indicador.position = Vector2(16, 44)
	raiz.add_child(_indicador)
	return raiz

# Mini indicador da luta (que segue rodando) na tela da Fazenda.
func _process(_delta: float) -> void:
	if fazenda.visible:
		_indicador.text = "Luta: Fase %d  |  Vida do herói %d/%d  |  Ouro %d" % [batalha.fase, batalha.heroi.vida, batalha.heroi.vida_max, batalha.ouro]

func _cria_painel_abas() -> Control:
	var abas := TabContainer.new()
	abas.name = "PainelAbas"
	abas.custom_minimum_size = Vector2(0, ALTURA_PAINEL)
	for nome in ABAS:
		var conteudo := MarginContainer.new()
		conteudo.name = nome
		var texto := Label.new()
		texto.text = "(%s: vazio)" % nome
		conteudo.add_child(texto)
		abas.add_child(conteudo)
	return abas

# Teste headless: godot --headless --path . --quit-after 99999 -- --teste-batalha
# Simula 5 minutos de jogo em ~15s reais e imprime o estado de minuto em minuto.
func _roda_teste() -> void:
	Engine.time_scale = 20.0
	for minuto in range(1, 6):
		await get_tree().create_timer(60.0).timeout
		print("[teste] min %d: fase %d, abates %d, nivel %d, ouro %d, vida heroi %d/%d" % [minuto, batalha.fase, batalha.abates, batalha.nivel, batalha.ouro, batalha.heroi.vida, batalha.heroi.vida_max])
	get_tree().quit()