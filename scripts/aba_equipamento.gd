extends VBoxContainer
# Aba Equipamento: 3 espacos (Arma, Armadura, Acessorio), CP e melhoria +N (ouro + minerio).
# Drops sao equipados automaticamente se o CP sobe; senao vendidos.
const Cfg := preload("res://scripts/cfg.gd")

var estado
var _cp: Label
var _linhas: Array = []   # [{rotulo, botao}]

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_cp = Label.new()
	_cp.add_theme_font_size_override("font_size", 20)
	add_child(_cp)
	for i in Cfg.SLOTS.size():
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		var l := Label.new()
		l.custom_minimum_size = Vector2(620, 0)
		l.add_theme_font_size_override("font_size", 18)
		h.add_child(l)
		var bt := Button.new()
		bt.custom_minimum_size = Vector2(230, 34)
		bt.pressed.connect(func(): estado.equipamento.melhora_item(i))
		h.add_child(bt)
		add_child(h)
		_linhas.append({"rotulo": l, "botao": bt})
	var dica := Label.new()
	dica.text = "Itens caem dos inimigos (chefes sempre dropam). O melhor é equipado sozinho e o resto é vendido.\nMinério vem da fazenda: quebre rochas com a picareta."
	dica.modulate = Color(1, 1, 1, 0.6)
	add_child(dica)
	estado.mudou.connect(_atualiza)
	_atualiza()

func _atualiza() -> void:
	_cp.text = "Poder de combate (CP): %d      Minério: %d" % [estado.personagem.cp(), estado.minerio]
	for i in Cfg.SLOTS.size():
		var it = estado.equipamento.equipado[i]
		var l: Label = _linhas[i]["rotulo"]
		var bt: Button = _linhas[i]["botao"]
		if it == null:
			l.text = "%s:  (vazio)" % Cfg.SLOTS[i]
			l.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			bt.text = "—"
			bt.disabled = true
		else:
			l.text = "%s:  %s  (%s)" % [Cfg.SLOTS[i], estado.equipamento.nome_item(it), estado.equipamento.descricao_item(it)]
			l.add_theme_color_override("font_color", Cfg.RARIDADES[it["raridade"]]["cor"])
			if it["mais"] >= Cfg.MAIS_MAX:
				bt.text = "MÁXIMO (+%d)" % Cfg.MAIS_MAX
				bt.disabled = true
			else:
				bt.text = "Melhorar: %d ouro + %d minério" % [estado.equipamento.custo_mais_ouro(i), estado.equipamento.custo_mais_minerio(i)]
				bt.disabled = not estado.equipamento.pode_melhorar(i)