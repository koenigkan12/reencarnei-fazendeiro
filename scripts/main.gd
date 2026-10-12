extends Control
# Esqueleto do dia 2: area de batalha em cima, painel com 4 abas embaixo.
# A interface e montada por codigo para evitar .tscn escrito a mao.

const ABAS := ["Personagem", "Equipamento", "Fazenda", "Loja"]
const ALTURA_PAINEL := 280
const Batalha := preload("res://scripts/batalha.gd")

var batalha: Control

func _ready() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)

	raiz.add_child(_cria_area_batalha())
	raiz.add_child(_cria_painel_abas())

	if "--teste-batalha" in OS.get_cmdline_user_args():
		_roda_teste()


func _cria_area_batalha() -> Control:
	batalha = Batalha.new()
	batalha.name = "AreaBatalha"
	batalha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return batalha
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