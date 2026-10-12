extends Control
# Esqueleto do dia 2: area de batalha em cima, painel com 4 abas embaixo.
# A interface e montada por codigo para evitar .tscn escrito a mao.

const ABAS := ["Personagem", "Equipamento", "Fazenda", "Loja"]
const ALTURA_PAINEL := 280

func _ready() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)

	raiz.add_child(_cria_area_batalha())
	raiz.add_child(_cria_painel_abas())

func _cria_area_batalha() -> Control:
	var area := ColorRect.new()
	area.color = Color(0.16, 0.22, 0.28)
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.name = "AreaBatalha"
	var rotulo := Label.new()
	rotulo.text = "Área de batalha"
	rotulo.set_anchors_preset(Control.PRESET_CENTER)
	rotulo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rotulo.grow_vertical = Control.GROW_DIRECTION_BOTH
	area.add_child(rotulo)
	return area

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
