extends Control
# Tela de fim da v1, depois do chefe final: estatisticas e a opcao de continuar jogando.
const MenuUtil := preload("res://scripts/menu_util.gd")

signal continuar_jogando
signal menu

var estatisticas: Array = []     # [[nome, valor], ...]

func _ready() -> void:
	add_child(MenuUtil.fundo(Color(0.05, 0.07, 0.12, 0.93)))
	var col := MenuUtil.coluna(self, 10)
	var t := MenuUtil.titulo("Vitória!", 60)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	col.add_child(t)
	var sub := MenuUtil.titulo("O chefe final caiu. A enxada, afinal, era lendária.", 20)
	col.add_child(sub)
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 40)
	grade.add_theme_constant_override("v_separation", 6)
	col.add_child(grade)
	for par in estatisticas:
		var a := Label.new()
		a.text = par[0]
		a.modulate = Color(1, 1, 1, 0.7)
		grade.add_child(a)
		var b := Label.new()
		b.text = str(par[1])
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grade.add_child(b)
	var esp := Control.new()
	esp.custom_minimum_size = Vector2(0, 16)
	col.add_child(esp)
	var bt := MenuUtil.botao("Continuar jogando")
	bt.pressed.connect(func(): continuar_jogando.emit())
	col.add_child(bt)
	var bt2 := MenuUtil.botao("Menu principal")
	bt2.pressed.connect(func(): menu.emit())
	col.add_child(bt2)
	var nota := Label.new()
	nota.text = "Continuar jogando repete o chefe da fase 20 para você seguir fortalecendo o herói e a fazenda."
	nota.modulate = Color(1, 1, 1, 0.5)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(nota)
	bt.grab_focus()
