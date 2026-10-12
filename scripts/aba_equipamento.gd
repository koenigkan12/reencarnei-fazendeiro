extends VBoxContainer
# Aba Equipamento: 3 espacos (Arma, Armadura, Acessorio) e CP. Drops sao equipados
# automaticamente se o CP sobe; senao sao vendidos.
const Cfg := preload("res://scripts/cfg.gd")

var estado
var _cp: Label
var _slots: Array = []

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_cp = Label.new()
	_cp.add_theme_font_size_override("font_size", 20)
	add_child(_cp)
	for i in Cfg.SLOTS.size():
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 18)
		add_child(l)
		_slots.append(l)
	var dica := Label.new()
	dica.text = "Itens caem dos inimigos (chefes sempre dropam). O melhor é equipado sozinho; o resto é vendido."
	dica.modulate = Color(1, 1, 1, 0.6)
	add_child(dica)
	estado.mudou.connect(_atualiza)
	_atualiza()

func _atualiza() -> void:
	_cp.text = "Poder de combate (CP): %d" % estado.cp()
	for i in Cfg.SLOTS.size():
		var it = estado.equipado[i]
		var l: Label = _slots[i]
		if it == null:
			l.text = "%s:  (vazio)" % Cfg.SLOTS[i]
			l.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		else:
			l.text = "%s:  %s  (%s)" % [Cfg.SLOTS[i], estado.nome_item(it), estado.descricao_item(it)]
			l.add_theme_color_override("font_color", Cfg.RARIDADES[it["raridade"]]["cor"])