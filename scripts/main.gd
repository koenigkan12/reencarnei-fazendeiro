extends Control
# Esqueleto do dia 2: area de batalha em cima, painel com 4 abas embaixo.
# A interface e montada por codigo para evitar .tscn escrito a mao.

const ABAS := ["Personagem", "Equipamento", "Fazenda", "Loja"]
const ALTURA_PAINEL := 280
const Cfg := preload("res://scripts/cfg.gd")
const Batalha := preload("res://scripts/batalha.gd")
const Estado := preload("res://scripts/estado.gd")
const AbaPersonagem := preload("res://scripts/aba_personagem.gd")
const AbaEquipamento := preload("res://scripts/aba_equipamento.gd")

var batalha: Control
var estado := Estado.new()
var abas: TabContainer
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
	abas = _cria_painel_abas()
	abas.tab_changed.connect(_troca_aba)
	raiz.add_child(abas)

	if "--teste-batalha" in OS.get_cmdline_user_args():
		_roda_teste()


func _cria_area_batalha() -> Control:
	batalha = Batalha.new()
	batalha.estado = estado
	batalha.pede_aba.connect(func(nome: String): abas.current_tab = ABAS.find(nome))
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

func _cria_painel_abas() -> TabContainer:
	var painel := TabContainer.new()
	painel.name = "PainelAbas"
	painel.custom_minimum_size = Vector2(0, ALTURA_PAINEL)
	for nome in ABAS:
		var conteudo := MarginContainer.new()
		conteudo.name = nome
		conteudo.add_theme_constant_override("margin_left", 16)
		conteudo.add_theme_constant_override("margin_top", 12)
		conteudo.add_theme_constant_override("margin_right", 16)
		match nome:
			"Personagem":
				var a := AbaPersonagem.new()
				a.estado = estado
				conteudo.add_child(a)
			"Equipamento":
				var a := AbaEquipamento.new()
				a.estado = estado
				conteudo.add_child(a)
			_:
				var texto := Label.new()
				texto.text = "(%s: vazio)" % nome
				conteudo.add_child(texto)
		painel.add_child(conteudo)
	return painel
# Teste headless: godot --headless --path . --quit-after 99999 -- --teste-batalha
# Simula 30 minutos de jogo em ~90s reais, com um "jogador" que compra o upgrade mais barato
# sempre que pode, e imprime o estado a cada minuto.
func _roda_teste() -> void:
	Engine.time_scale = 20.0
	for minuto in range(1, 31):
		for _s in 12:
			await get_tree().create_timer(5.0).timeout
			var i := 0
			while i < 40:
				var barato := 0
				for u in 3:
					if estado.custo_upgrade(u) < estado.custo_upgrade(barato):
						barato = u
				if not estado.compra_upgrade(barato):
					break
				i += 1
		print("[teste] min %d: fase %d (%d/%d)%s nivel %d, ouro %d, CP %d, derrotas %d, upg %s, equip %s" % [minuto, batalha.fase, batalha.abates, Cfg.INIMIGOS_POR_FASE, " CHEFE" if batalha.contra_chefe else "", estado.nivel, estado.ouro, estado.cp(), batalha.derrotas, str(estado.upgrades), str(estado.equipado.map(func(x): return "-" if x == null else estado.nome_item(x)))])
		if batalha.vitoria_final:
			print("[teste] VITORIA FINAL")
			break
	get_tree().quit()