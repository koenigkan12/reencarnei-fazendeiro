extends HBoxContainer
# Aba Equipamento: 3 espacos (Arma, Armadura, Acessorio) com melhoria +N (ouro + minerio) e a mochila.
# Toque num item da mochila para ver a comparacao e escolher Equipar ou Vender.
const Cfg := preload("res://scripts/cfg.gd")

const COLUNAS_MOCHILA := 8

var estado
var _cp: Label
var _linhas: Array = []       # [{rotulo, botao}]
var _casas: Array = []        # botoes da mochila
var _titulo_mochila: Label
var _detalhe: Label
var _bt_equipa: Button
var _bt_vende: Button
var _auto: CheckBox
var _bt_vende_comuns: Button
var _sel := -1                # item selecionado da mochila

func _ready() -> void:
	add_theme_constant_override("separation", 18)
	add_child(_monta_espacos())
	add_child(_monta_mochila())
	add_child(_monta_detalhe())
	estado.mudou.connect(_atualiza)
	_atualiza()

func _monta_espacos() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_cp = Label.new()
	_cp.add_theme_font_size_override("font_size", 18)
	v.add_child(_cp)
	for i in Cfg.SLOTS.size():
		var l := Label.new()
		l.custom_minimum_size = Vector2(330, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		var bt := Button.new()
		bt.custom_minimum_size = Vector2(330, 30)
		bt.pressed.connect(func(): estado.equipamento.melhora_item(i))
		v.add_child(bt)
		_linhas.append({"rotulo": l, "botao": bt})
	return v

func _monta_mochila() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_titulo_mochila = Label.new()
	v.add_child(_titulo_mochila)
	var grade := GridContainer.new()
	grade.columns = COLUNAS_MOCHILA
	grade.add_theme_constant_override("h_separation", 4)
	grade.add_theme_constant_override("v_separation", 4)
	v.add_child(grade)
	for i in Cfg.MOCHILA_TAMANHO:
		var bt := Button.new()
		bt.custom_minimum_size = Vector2(54, 40)
		bt.pressed.connect(func(): _seleciona(i))
		grade.add_child(bt)
		_casas.append(bt)
	_auto = CheckBox.new()
	_auto.text = "Equipar sozinho o que aumenta o CP"
	_auto.toggled.connect(func(on: bool): estado.equipamento.auto_equipar = on)
	v.add_child(_auto)
	_bt_vende_comuns = Button.new()
	_bt_vende_comuns.pressed.connect(_vende_comuns)
	v.add_child(_bt_vende_comuns)
	return v

func _monta_detalhe() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Vector2(250, 0)
	_detalhe = Label.new()
	_detalhe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detalhe.custom_minimum_size = Vector2(250, 120)
	v.add_child(_detalhe)
	_bt_equipa = Button.new()
	_bt_equipa.text = "Equipar"
	_bt_equipa.pressed.connect(_equipa)
	v.add_child(_bt_equipa)
	_bt_vende = Button.new()
	_bt_vende.pressed.connect(_vende)
	v.add_child(_bt_vende)
	return v

func _vende_comuns() -> void:
	_sel = -1
	estado.equipamento.vende_ate_raridade(0)

func _equipa() -> void:
	var i := _sel
	_sel = -1
	estado.equipamento.equipa_da_mochila(i)

func _vende() -> void:
	var i := _sel
	_sel = -1
	estado.equipamento.vende_da_mochila(i)

func _seleciona(i: int) -> void:
	_sel = i
	_atualiza()

func _atualiza() -> void:
	var eq = estado.equipamento
	_cp.text = "CP: %d      Minério: %d      Estilo: %s" % [estado.personagem.cp(), estado.minerio, estado.personagem.nome_estilo()]
	for i in Cfg.SLOTS.size():
		var it = eq.equipado[i]
		var l: Label = _linhas[i]["rotulo"]
		var bt: Button = _linhas[i]["botao"]
		if it == null:
			l.text = "%s:  (vazio)" % Cfg.SLOTS[i]
			l.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			bt.text = "—"
			bt.disabled = true
		else:
			l.text = "%s:  %s  (%s)" % [Cfg.SLOTS[i], eq.nome_item(it), eq.descricao_item(it)]
			l.add_theme_color_override("font_color", Cfg.RARIDADES[it["raridade"]]["cor"])
			if it["mais"] >= Cfg.MAIS_MAX:
				bt.text = "MÁXIMO (+%d)" % Cfg.MAIS_MAX
				bt.disabled = true
			else:
				bt.text = "Melhorar +%d: %d ouro + %d minério" % [it["mais"] + 1, eq.custo_mais_ouro(i), eq.custo_mais_minerio(i)]
				bt.disabled = not eq.pode_melhorar(i)
	# mochila
	if _sel >= eq.mochila.size():
		_sel = -1
	_titulo_mochila.text = "Mochila (%d/%d)" % [eq.mochila.size(), Cfg.MOCHILA_TAMANHO]
	for i in _casas.size():
		var c: Button = _casas[i]
		if i < eq.mochila.size():
			var it: Dictionary = eq.mochila[i]
			c.text = _texto_curto(it)
			c.disabled = false
			c.add_theme_color_override("font_color", Cfg.RARIDADES[it["raridade"]]["cor"])
			c.add_theme_color_override("font_hover_color", Cfg.RARIDADES[it["raridade"]]["cor"])
			c.modulate = Color(1.4, 1.4, 1.4) if i == _sel else Color.WHITE
		else:
			c.text = ""
			c.disabled = true
			c.modulate = Color.WHITE
	_auto.set_pressed_no_signal(eq.auto_equipar)
	_bt_vende_comuns.text = "Vender todos os Comuns"
	_atualiza_detalhe()

func _texto_curto(it: Dictionary) -> String:
	var base: String = Cfg.TIPOS_ARMA[it["tipo"]]["curto"] if it["tipo"] >= 0 else ["", "Arm", "Ace"][it["slot"]]
	return base + ("\n+%d" % it["mais"] if it["mais"] > 0 else "")

func _atualiza_detalhe() -> void:
	var eq = estado.equipamento
	if _sel < 0:
		_detalhe.text = "Toque num item da mochila para ver os detalhes."
		_bt_equipa.disabled = true
		_bt_vende.text = "Vender"
		_bt_vende.disabled = true
		return
	var it: Dictionary = eq.mochila[_sel]
	var delta: int = eq.delta_cp_mochila(_sel)
	var atual = eq.equipado[it["slot"]]
	var txt := "%s\n%s\nEspaço: %s\n" % [eq.nome_item(it), eq.descricao_item(it), Cfg.SLOTS[it["slot"]]]
	txt += "Equipado agora: %s\n" % ("(vazio)" if atual == null else eq.nome_item(atual))
	txt += "CP se equipar: %s%d" % ["+" if delta >= 0 else "", delta]
	if it["tipo"] >= 0:
		txt += "\nCombina com habilidades de estilo %s." % Cfg.ESTILOS[Cfg.TIPOS_ARMA[it["tipo"]]["estilo"]]["nome"]
	_detalhe.text = txt
	_detalhe.add_theme_color_override("font_color", Cfg.RARIDADES[it["raridade"]]["cor"])
	_bt_equipa.disabled = false
	_bt_vende.text = "Vender (+%d ouro)" % eq.valor_venda(it)
	_bt_vende.disabled = false
