extends ColorRect
# Tela "Bem-vindo de volta": resumo do que aconteceu enquanto o jogo estava fechado.
# Use Salvamento.mostra_resumo(pai, resumo); fecha no botao Continuar.

var resumo := {}

func _ready() -> void:
	color = Color(0, 0, 0, 0.7)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var painel := PanelContainer.new()
	centro.add_child(painel)
	var margem := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 24)
	painel.add_child(margem)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.custom_minimum_size = Vector2(440, 0)
	margem.add_child(col)
	var tit := Label.new()
	tit.text = "Bem-vindo de volta!"
	tit.add_theme_font_size_override("font_size", 26)
	col.add_child(tit)
	var linhas: Array = []
	linhas.append("Você ficou fora por %s." % _tempo(float(resumo.get("segundos", 0.0))))
	if resumo.get("limitado", false):
		linhas.append("(Contamos no máximo %s offline.)" % _tempo(float(resumo.get("contados", 0.0))))
	linhas.append("O herói treinou sozinho a %d%% do ritmo normal:" % roundi(float(resumo.get("eficiencia", 0.5)) * 100.0))
	linhas.append("  + %d de ouro" % roundi(float(resumo.get("ouro", 0.0))))
	if int(resumo.get("nivel_depois", 1)) > int(resumo.get("nivel_antes", 1)):
		linhas.append("  Nível %d → %d" % [int(resumo.get("nivel_antes", 1)), int(resumo.get("nivel_depois", 1))])
	var prontas := int(resumo.get("prontas", 0))
	if prontas > 0:
		linhas.append("Fazenda: %d planta(s) ficaram prontas para colher." % prontas)
	var pratos := int(resumo.get("pratos_gastos", 0))
	if pratos > 0:
		linhas.append("Comida: %d prato(s) foram consumidos." % pratos)
	var texto := Label.new()
	texto.text = "\n".join(linhas)
	col.add_child(texto)
	var botao := Button.new()
	botao.text = "Continuar"
	botao.custom_minimum_size = Vector2(0, 36)
	botao.pressed.connect(queue_free)
	col.add_child(botao)

func _tempo(seg: float) -> String:
	var min_total := int(seg / 60.0)
	var h := min_total / 60
	var m := min_total % 60
	if h > 0:
		return "%d h %d min" % [h, m]
	return "%d min" % maxi(m, 1)
