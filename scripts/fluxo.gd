extends CanvasLayer
# FLUXO DO JOGO: menu principal, pausa (Esc), opcoes, tutorial de primeira vez e fim da v1.
# Fica por cima de tudo e pausa a arvore enquanto uma tela esta aberta. Nao muda a logica dos sistemas.
#
# Ganchos de SAVE (o fluxo chama estes metodos de main.estado se existirem; o autor do save so implementa):
#   existe_save() -> bool    salva() -> bool    carrega() -> bool    apaga_save() -> void
# Ganchos de AUDIO: ver audio.gd (Audio.toca_efeito / Audio.toca_musica) e Cfg.AUDIO_NOMES.
const Cfg := preload("res://scripts/cfg.gd")
const MenuUtil := preload("res://scripts/menu_util.gd")
const Opcoes := preload("res://scripts/opcoes.gd")
const Audio := preload("res://scripts/audio.gd")
const MenuPrincipal := preload("res://scripts/menu_principal.gd")
const MenuPausa := preload("res://scripts/menu_pausa.gd")
const TelaOpcoes := preload("res://scripts/tela_opcoes.gd")
const Tutorial := preload("res://scripts/tutorial.gd")
const TelaFim := preload("res://scripts/tela_fim.gd")

# "Novo jogo" e "Menu principal" recarregam a cena; isto diz ao novo fluxo para pular o menu
static var pular_menu := false

var main                          # main.gd
var opcoes := Opcoes.new()
var tempo_jogado := 0.0           # segundos de jogo (nao conta menus nem pausa)

var _audio: Node
var _tela: Control = null
var _modo := "menu"               # menu, jogo, pausa, opcoes, tutorial, fim
var _modo_antes_opcoes := "menu"
var _fim_visto := false
var _desde_autosave := 0.0
var _bt_menu: Button

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Testes automaticos (bot e capturas) rodam direto no jogo, sem menus
	for arg in OS.get_cmdline_user_args():
		if arg == "--teste-batalha" or arg.begins_with("--captura"):
			set_process(false)
			set_process_unhandled_key_input(false)
			return
	opcoes.carrega()
	opcoes.aplica()
	_audio = Audio.new()
	add_child(_audio)
	_bt_menu = Button.new()
	_bt_menu.text = "☰ Menu (Esc)"
	_bt_menu.visible = false
	_bt_menu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_bt_menu.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_bt_menu.offset_left = -130
	_bt_menu.offset_right = -10
	_bt_menu.offset_top = 44
	_bt_menu.pressed.connect(_abre_pausa)
	add_child(_bt_menu)
	if pular_menu:
		pular_menu = false
		_comeca_jogo(true)
	else:
		_mostra_menu()

# ---------- ganchos de save ----------
func _chama(metodo: String, padrao: Variant = false) -> Variant:
	var est = main.estado
	if est != null and est.has_method(metodo):
		return est.call(metodo)
	return padrao

func _tem_save() -> bool:
	return bool(_chama("existe_save"))

func _pode_salvar() -> bool:
	return main.estado != null and main.estado.has_method("salva")

func _salva() -> void:
	if _pode_salvar():
		_chama("salva")
		opcoes.salva_tempo_jogado(tempo_jogado)

# ---------- telas ----------
func _troca_tela(nova: Control) -> void:
	if _tela != null:
		_tela.queue_free()
	_tela = nova
	if nova != null:
		add_child(nova)

func _mostra_menu() -> void:
	_modo = "menu"
	get_tree().paused = true
	_bt_menu.visible = false
	var m := MenuPrincipal.new()
	m.configura(_tem_save())
	m.novo_jogo.connect(_novo_jogo)
	m.continuar.connect(_continuar)
	m.opcoes.connect(_abre_opcoes)
	m.sair.connect(_sair)
	_troca_tela(m)
	Audio.toca_musica("menu")

func _novo_jogo() -> void:
	Audio.toca_efeito("clique")
	_chama("apaga_save")
	opcoes.salva_tempo_jogado(0.0)
	_comeca_jogo(true)

func _continuar() -> void:
	Audio.toca_efeito("clique")
	if not bool(_chama("carrega")):
		return
	tempo_jogado = opcoes.tempo_jogado()
	_comeca_jogo(false)

func _comeca_jogo(com_tutorial: bool) -> void:
	_troca_tela(null)
	_modo = "jogo"
	_bt_menu.visible = true
	get_tree().paused = false
	Audio.toca_musica("jogo")
	if com_tutorial and not opcoes.tutorial_visto:
		_abre_tutorial()

func _abre_pausa() -> void:
	if _modo != "jogo":
		return
	_modo = "pausa"
	get_tree().paused = true
	var p := MenuPausa.new()
	p.configura(_pode_salvar())
	p.continuar.connect(_fecha_pausa)
	p.salvar.connect(_salva)
	p.opcoes.connect(_abre_opcoes)
	p.tutorial.connect(_abre_tutorial)
	p.menu.connect(_volta_ao_menu)
	p.sair.connect(_sair)
	_troca_tela(p)

func _fecha_pausa() -> void:
	Audio.toca_efeito("clique")
	_troca_tela(null)
	_modo = "jogo"
	get_tree().paused = false

func _abre_opcoes() -> void:
	Audio.toca_efeito("clique")
	_modo_antes_opcoes = _modo
	_modo = "opcoes"
	var o := TelaOpcoes.new()
	o.opcoes = opcoes
	o.fechou.connect(_fecha_opcoes)
	_troca_tela(o)

func _fecha_opcoes() -> void:
	Audio.toca_efeito("clique")
	if _modo_antes_opcoes == "pausa":
		_modo = "jogo"
		_abre_pausa()
	else:
		_mostra_menu()

func _abre_tutorial() -> void:
	_modo = "tutorial"
	get_tree().paused = true
	var t := Tutorial.new()
	t.abre_aba.connect(_abre_aba)
	t.abre_aba.connect(func(_n: String): Audio.toca_efeito("tutorial_passo"))
	t.terminou.connect(_fecha_tutorial)
	_troca_tela(t)

func _abre_aba(nome: String) -> void:
	var i: int = main.ABAS.find(nome)
	if i != -1:
		main.abas.current_tab = i

func _fecha_tutorial() -> void:
	opcoes.tutorial_visto = true
	opcoes.salva()
	_abre_aba("Personagem")
	_troca_tela(null)
	_modo = "jogo"
	get_tree().paused = false

func _volta_ao_menu() -> void:
	Audio.toca_efeito("clique")
	_salva()
	pular_menu = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func _sair() -> void:
	_salva()
	get_tree().quit()

# ---------- fim da v1 ----------
func _mostra_fim() -> void:
	_fim_visto = true
	_modo = "fim"
	get_tree().paused = true
	_salva()
	var f := TelaFim.new()
	f.estatisticas = _estatisticas()
	f.continuar_jogando.connect(_continua_apos_fim)
	f.menu.connect(_volta_ao_menu)
	_troca_tela(f)
	Audio.toca_musica("fim")
	Audio.toca_efeito("vitoria")

func _continua_apos_fim() -> void:
	Audio.toca_efeito("clique")
	main.batalha.continua_apos_vitoria()
	_troca_tela(null)
	_modo = "jogo"
	get_tree().paused = false
	Audio.toca_musica("jogo")

func _estatisticas() -> Array:
	var est = main.estado
	var talentos: int = est.personagem.pontos_talento_gastos()
	return [
		["Tempo de jogo", MenuUtil.tempo_texto(tempo_jogado)],
		["Nível do herói", est.nivel],
		["Poder de combate (CP)", est.personagem.cp()],
		["Estilo", est.personagem.nome_estilo()],
		["Pontos de talento gastos", talentos],
		["Nível de Cultivo", est.fazenda.cultivo_nivel],
		["Derrotas no caminho", main.batalha.derrotas],
		["Ouro em mãos", floori(est.ouro)],
	]

# ---------- loop e teclado ----------
func _process(delta: float) -> void:
	if _modo == "jogo":
		tempo_jogado += delta
		_desde_autosave += delta
		if _desde_autosave >= Cfg.AUTOSAVE_SEGUNDOS:
			_desde_autosave = 0.0
			_salva()
		if main.batalha.vitoria_final and not _fim_visto:
			_mostra_fim()

func _unhandled_key_input(evento: InputEvent) -> void:
	var ev := evento as InputEventKey
	if ev == null or not ev.pressed or ev.echo or ev.keycode != KEY_ESCAPE:
		return
	match _modo:
		"jogo":
			_abre_pausa()
		"pausa":
			_fecha_pausa()
		"opcoes":
			if _tela != null and _tela.has_method("fecha"):
				_tela.call("fecha")
	get_viewport().set_input_as_handled()
