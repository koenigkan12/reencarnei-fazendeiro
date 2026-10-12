extends Control
# Raiz do jogo: tela de cima (batalha ou fazenda) e painel de abas embaixo.
# A interface e montada por codigo para evitar .tscn escrito a mao.

const ABAS := ["Personagem", "Equipamento", "Fazenda", "Loja"]
const ALTURA_PAINEL := 350
const Cfg := preload("res://scripts/cfg.gd")
const Audio := preload("res://scripts/audio.gd")
const Batalha := preload("res://scripts/batalha.gd")
const Estado := preload("res://scripts/estado.gd")
const AbaPersonagem := preload("res://scripts/aba_personagem.gd")
const AbaEquipamento := preload("res://scripts/aba_equipamento.gd")
const AbaFazenda := preload("res://scripts/aba_fazenda.gd")
const AbaLoja := preload("res://scripts/aba_loja.gd")
const FazendaTela := preload("res://scripts/fazenda_tela.gd")
const Fluxo := preload("res://scripts/fluxo.gd")
const Salvamento := preload("res://scripts/salvamento.gd")

var batalha: Control
var estado := Estado.new()
var abas: TabContainer
var fazenda: Control
var _voltar: Button       # botao "voltar a fazenda" mostrado sobre a batalha
var _vendo_batalha := false

func _ready() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)

	var topo := Control.new()
	topo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	topo.clip_contents = true
	raiz.add_child(topo)
	batalha = Batalha.new()
	batalha.estado = estado
	batalha.name = "AreaBatalha"
	batalha.pede_aba.connect(func(nome: String): abas.current_tab = ABAS.find(nome))
	batalha.set_anchors_preset(Control.PRESET_FULL_RECT)
	topo.add_child(batalha)
	fazenda = FazendaTela.new()
	fazenda.estado = estado
	fazenda.name = "AreaFazenda"
	fazenda.set_anchors_preset(Control.PRESET_FULL_RECT)
	fazenda.visible = false
	fazenda.ver_batalha.connect(func(): _mostra_topo(true))
	topo.add_child(fazenda)
	_voltar = Button.new()
	_voltar.text = "🌾 Voltar à fazenda"
	_voltar.visible = false
	_voltar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_voltar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_voltar.offset_left = -190
	_voltar.offset_top = 8
	_voltar.offset_right = -10
	_voltar.pressed.connect(func(): _mostra_topo(false))
	topo.add_child(_voltar)
	abas = _cria_painel_abas()
	abas.tab_changed.connect(_troca_aba)
	raiz.add_child(abas)

	estado.batalha = batalha     # o salvamento precisa da fase da batalha
	estado.voltou_offline.connect(func(resumo: Dictionary): Salvamento.mostra_resumo(self, resumo))
	var fluxo := Fluxo.new()    # menus, pausa, tutorial e fim da v1 (nao age nos modos de teste)
	fluxo.main = self
	add_child(fluxo)

	if "--teste-batalha" in OS.get_cmdline_user_args():
		_roda_teste()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--captura="):
			_captura(arg.substr(10))
		if arg.begins_with("--tela="):   # captura SEM pular os menus (ver menu principal etc.)
			_captura(arg.substr(7))

# A tela de cima acompanha a aba: Fazenda mostra a fazenda; as outras mostram a batalha.
# Na fazenda, o botao "Ver batalha" alterna. A batalha continua rodando escondida.
func _troca_aba(indice: int) -> void:
	_mostra_topo(ABAS[indice] == "Fazenda" and false)
	_vendo_batalha = false
	_atualiza_topo()

func _mostra_topo(ver_batalha: bool) -> void:
	_vendo_batalha = ver_batalha
	_atualiza_topo()

func _atualiza_topo() -> void:
	var na_fazenda: bool = ABAS[abas.current_tab] == "Fazenda"
	var mostra_fazenda := na_fazenda and not _vendo_batalha
	fazenda.visible = mostra_fazenda
	batalha.visible = not mostra_fazenda
	_voltar.visible = na_fazenda and _vendo_batalha
	Audio.toca_musica("fazenda" if mostra_fazenda else "jogo")

func _exit_tree() -> void:
	estado.libera()

# A fazenda e a comida andam com qualquer aba aberta
func _process(delta: float) -> void:
	estado.tick(delta)

func _cria_painel_abas() -> TabContainer:
	var painel := TabContainer.new()
	painel.name = "PainelAbas"
	painel.custom_minimum_size = Vector2(0, ALTURA_PAINEL)
	for nome in ABAS:
		var conteudo := MarginContainer.new()
		conteudo.name = nome
		conteudo.add_theme_constant_override("margin_left", 16)
		conteudo.add_theme_constant_override("margin_top", 10)
		conteudo.add_theme_constant_override("margin_right", 16)
		var aba: Control
		match nome:
			"Personagem": aba = AbaPersonagem.new()
			"Equipamento": aba = AbaEquipamento.new()
			"Fazenda": aba = AbaFazenda.new()
			_: aba = AbaLoja.new()
		aba.estado = estado
		conteudo.add_child(aba)
		painel.add_child(conteudo)
	return painel

# Tira um screenshot da janela (precisa rodar com tela, sem --headless):
# godot --path . -- --captura=C:/pasta/shot.png [--aba=2]
func _captura(caminho: String) -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--aba="):
			abas.current_tab = int(arg.substr(6))
	Engine.time_scale = 6.0
	await get_tree().create_timer(12.0).timeout
	if "--demo-fazenda" in OS.get_cmdline_user_args():
		Engine.time_scale = 1.0
		estado.fazenda.usa_ferramenta("enxada", 2, 3)
		await get_tree().create_timer(0.1).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(caminho)
	get_tree().quit()

# Teste headless: godot --headless --path . --quit-after 99999 -- --teste-batalha
# Simula 30 minutos de jogo em ~90s reais com um "jogador" automatico (compra, planta, rega, colhe,
# gasta talentos, melhora equipamento) e imprime o estado a cada minuto.
func _roda_teste() -> void:
	Engine.time_scale = 20.0
	for minuto in range(1, 31):
		for _s in 12:
			await get_tree().create_timer(5.0).timeout
			_bot()
		print("[teste] min %d: fase %d (%d/%d)%s nivel %d, ouro %d, CP %d, derrotas %d, cultivo %d, minerio %d, atr %s, equip %s" % [
			minuto, batalha.fase, batalha.abates, Cfg.INIMIGOS_POR_FASE, " CHEFE" if batalha.contra_chefe else "", estado.nivel, estado.ouro, estado.personagem.cp(),
			batalha.derrotas, estado.fazenda.cultivo_nivel, estado.minerio, str(estado.personagem.atributos.values()), str(estado.equipamento.equipado.map(func(x): return "-" if x == null else estado.equipamento.nome_item(x)))])
		if batalha.vitoria_final:
			print("[teste] VITORIA FINAL")
			break
	get_tree().quit()

func _bot() -> void:
	# fazenda: compra trigo, escolhe a melhor semente, ara, planta, rega, colhe e quebra rochas
	if estado.fazenda.sementes[0] < 6:
		estado.loja.compra_semente(0, 5)
	for c in [2, 1, 0]:
		if estado.fazenda.cultura_liberada(c) and estado.fazenda.sementes[c] > 0:
			estado.fazenda.semente_selecionada = c
			break
	for y in Cfg.LINHAS:
		for x in estado.fazenda.colunas_abertas():
			for f in ["mao", "picareta", "enxada", "semente", "regador"]:
				estado.fazenda.usa_ferramenta(f, x, y)
	for c in 3:
		estado.comida.cozinha(c)
		estado.fazenda.vende_colheita(c)
	for f in Cfg.FERRAMENTAS:
		estado.loja.melhora_ferramenta(f["id"])
	estado.loja.melhora_irrigacao()
	# personagem
	for i in 40:
		if estado.personagem.pontos_talento() > 0:
			for t in Cfg.TALENTOS.size():
				estado.personagem.sobe_talento(t)
		var barato := 0
		for u in Cfg.ATRIBUTOS.size():
			if not estado.personagem.atributo_no_maximo(u) and estado.personagem.custo_atributo(u) < estado.personagem.custo_atributo(barato):
				barato = u
		if not estado.personagem.compra_atributo(barato):
			break
	for h in Cfg.HABILIDADES.size():
		estado.personagem.sobe_habilidade(h)
	for s in 3:
		estado.equipamento.melhora_item(s) if estado.equipamento.equipado[s] != null else false