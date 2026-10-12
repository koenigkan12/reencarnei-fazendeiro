extends VBoxContainer
# Aba Personagem: status do heroi e upgrades comprados com ouro.
const Cfg := preload("res://scripts/cfg.gd")

var estado
var _status: Label
var _linhas: Array = []   # [{rotulo, botao}]

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 18)
	add_child(_status)
	for i in Cfg.UPGRADES.size():
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		var rot := Label.new()
		rot.custom_minimum_size = Vector2(380, 0)
		h.add_child(rot)
		var bt := Button.new()
		bt.custom_minimum_size = Vector2(180, 36)
		bt.pressed.connect(func(): estado.compra_upgrade(i))
		h.add_child(bt)
		add_child(h)
		_linhas.append({"rotulo": rot, "botao": bt})
	estado.mudou.connect(_atualiza)
	_atualiza()

func _atualiza() -> void:
	_status.text = "Nível %d   |   Vida %d   Dano %d   Regeneração %.1f%%/s   |   CP %d" % [
		estado.nivel, roundi(estado.vida_max()), roundi(estado.dano()), estado.regen_pct() * 100.0, estado.cp()]
	for i in Cfg.UPGRADES.size():
		var u: Dictionary = Cfg.UPGRADES[i]
		var l: Dictionary = _linhas[i]
		l["rotulo"].text = "%s  Nv %d   (%s por nível)" % [u["nome"], estado.upgrades[u["id"]], u["desc"]]
		var c: int = estado.custo_upgrade(i)
		l["botao"].text = "Comprar: %d ouro" % c
		l["botao"].disabled = estado.ouro < c