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
const AbaFazenda := preload("res://scripts/aba_fazenda.gd")
const FazendaTela := preload("res://scripts/fazenda_tela.gd")

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
	_indicador = Label.new()
	_indicador.position = Vector2(560, 14)
	_indicador.visible = false
	topo.add_child(_indicador)
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
	_indicador.visible = na_fazenda

# Tela de cima da aba Fazenda (lotes clicaveis). A batalha continua rodando escondida.
func _cria_fazenda() -> Control:
	var tela := FazendaTela.new()
	tela.estado = estado
	tela.name = "AreaFazenda"
	return tela

# A fazenda cresce com qualquer aba aberta; mini indicador da luta aparece na tela da Fazenda.
func _process(delta: float) -> void:
	estado.tick(delta)
	if fazenda.visible:
		_indicador.text = "Luta: Fase %d  |  Vida do herói %d/%d  |  Ouro %d" % [batalha.fase, batalha.heroi.vida, batalha.heroi.vida_max, estado.ouro]
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
			estado.colhe_tudo()
			for c in [2, 1, 0]:
				if estado.cultura_liberada(c) and estado.sementes[c] > 0:
					estado.planta_em_todos(c)
					break
			for c in 3:
				estado.cozinha(c)
				estado.cozinha(c)
				estado.vende_colheita(c)
			var i := 0
			while i < 40:
				var barato := 0
				for u in 3:
					if estado.custo_upgrade(u) < estado.custo_upgrade(barato):
						barato = u
				if not estado.compra_upgrade(barato):
					break
				i += 1
		print("[teste] min %d: fase %d (%d/%d)%s nivel %d, ouro %d, CP %d, derrotas %d, cultivo %d, pratos %s, upg %s, equip %s" % [minuto, batalha.fase, batalha.abates, Cfg.INIMIGOS_POR_FASE, " CHEFE" if batalha.contra_chefe else "", estado.nivel, estado.ouro, estado.cp(), batalha.derrotas, estado.cultivo_nivel, str(estado.pratos), str(estado.upgrades), str(estado.equipado.map(func(x): return "-" if x == null else estado.nome_item(x)))])
		if batalha.vitoria_final:
			print("[teste] VITORIA FINAL")
			break
	get_tree().quit()