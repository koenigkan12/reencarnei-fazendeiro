extends RefCounted
# Pecas de interface comuns aos menus (fundo, titulo, botao, coluna centralizada).

static func fundo(cor: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = cor
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	return r

static func titulo(texto: String, tamanho: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	return l

static func botao(texto: String, largura: float = 280.0) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(largura, 44)
	b.add_theme_font_size_override("font_size", 20)
	return b

# Coluna centralizada que ocupa a tela toda; devolve a coluna para colocar os filhos
static func coluna(pai: Control, separacao: int = 14) -> VBoxContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	pai.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separacao)
	c.add_child(v)
	return v

static func tempo_texto(segundos: float) -> String:
	var s: int = int(segundos)
	return "%dh %02dmin" % [s / 3600, (s % 3600) / 60] if s >= 3600 else "%dmin %02ds" % [s / 60, s % 60]
