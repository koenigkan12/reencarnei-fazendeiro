extends Control
# Area de batalha: heroi (esquerda) luta sozinho contra inimigos (direita).
# Dia 4: cena + barras + HUD. Dia 5: combate automatico. Dia 6: ouro, XP, nivel, fases.

const Cfg := preload("res://scripts/cfg.gd")
const Unidade := preload("res://scripts/unidade.gd")

var heroi: Control
var inimigo: Control
var fase := 1
var abates := 0          # inimigos mortos na fase atual
var nivel := 1
var xp := 0.0
var ouro := 0.0
var respawn := 0.0

var _fundo: ColorRect
var _chao: ColorRect
var _hud_texto: Label
var _barra_xp: ProgressBar
var _barra_fase: ProgressBar
var _rotulo_fase: Label

func _ready() -> void:
	clip_contents = true
	_fundo = ColorRect.new()
	_fundo.color = Color(0.16, 0.22, 0.28)
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fundo)
	_chao = ColorRect.new()
	_chao.color = Color(0.22, 0.3, 0.2)
	add_child(_chao)

	heroi = Unidade.new()
	add_child(heroi)
	heroi.configura("Herói", Color(0.3, 0.5, 0.95), Vector2(50, 90), _vida_heroi(), _dano_heroi(), Cfg.HEROI_INTERVALO)
	inimigo = Unidade.new()
	add_child(inimigo)
	_novo_inimigo()

	_cria_hud()
	resized.connect(_posiciona)
	_posiciona()
	_atualiza_hud()

func _cria_hud() -> void:
	_hud_texto = Label.new()
	_hud_texto.position = Vector2(16, 10)
	_hud_texto.add_theme_font_size_override("font_size", 22)
	add_child(_hud_texto)
	_barra_xp = ProgressBar.new()
	_barra_xp.position = Vector2(16, 46)
	_barra_xp.size = Vector2(260, 14)
	_barra_xp.show_percentage = false
	_barra_xp.modulate = Color(0.6, 0.5, 1.0)
	add_child(_barra_xp)
	_rotulo_fase = Label.new()
	_rotulo_fase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_rotulo_fase)
	_barra_fase = ProgressBar.new()
	_barra_fase.show_percentage = false
	_barra_fase.size = Vector2(360, 14)
	_barra_fase.modulate = Color(1.0, 0.8, 0.3)
	add_child(_barra_fase)

func _posiciona() -> void:
	var chao_y := size.y * 0.78
	_chao.position = Vector2(0, chao_y)
	_chao.size = Vector2(size.x, size.y - chao_y)
	heroi.position = Vector2(size.x * 0.25, chao_y)
	inimigo.position = Vector2(size.x * 0.72, chao_y)
	_rotulo_fase.position = Vector2(size.x / 2.0 - 180, 10)
	_rotulo_fase.size = Vector2(360, 24)
	_barra_fase.position = Vector2(size.x / 2.0 - 180, 38)

# ---------- formulas ----------
func _vida_heroi() -> float:
	return Cfg.HEROI_VIDA + Cfg.HEROI_VIDA_POR_NIVEL * (nivel - 1)

func _dano_heroi() -> float:
	return Cfg.HEROI_DANO + Cfg.HEROI_DANO_POR_NIVEL * (nivel - 1)

func _xp_para_subir() -> float:
	return Cfg.XP_BASE * pow(Cfg.XP_CRESCIMENTO, nivel - 1)

func _novo_inimigo() -> void:
	var base: Dictionary = Cfg.INIMIGOS[randi() % Cfg.INIMIGOS.size()]
	var e := fase - 1
	inimigo.configura(base["nome"], base["cor"], base["tamanho"],
		base["vida"] * pow(Cfg.ESCALA_VIDA, e), base["dano"] * pow(Cfg.ESCALA_DANO, e), base["intervalo"])
	inimigo.set_meta("ouro", base["ouro"] * pow(Cfg.ESCALA_OURO, e))
	inimigo.set_meta("xp", base["xp"] * pow(Cfg.ESCALA_XP, e))
	inimigo.visible = true

# ---------- loop ----------
func _process(delta: float) -> void:
	if not heroi.vivo:
		return
	heroi.cura(heroi.vida_max * Cfg.HEROI_REGEN_PCT * delta)
	if not inimigo.vivo:
		respawn -= delta
		if respawn <= 0.0:
			_novo_inimigo()
		return
	heroi.tempo_ataque -= delta
	if heroi.tempo_ataque <= 0.0:
		heroi.tempo_ataque += heroi.intervalo
		_ataca(heroi, inimigo, 1.0)
		if not inimigo.vivo:
			_inimigo_morreu()
			return
	inimigo.tempo_ataque -= delta
	if inimigo.tempo_ataque <= 0.0:
		inimigo.tempo_ataque += inimigo.intervalo
		_ataca(inimigo, heroi, -1.0)
		if not heroi.vivo:
			_heroi_morreu()

func _ataca(atacante: Control, alvo: Control, direcao: float) -> void:
	atacante.animacao_ataque(direcao)
	alvo.recebe_dano(atacante.dano)
	_numero_de_dano(alvo, atacante.dano, atacante == inimigo)

func _numero_de_dano(alvo: Control, valor: float, no_heroi: bool) -> void:
	var l := Label.new()
	l.text = str(roundi(valor))
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(1, 0.35, 0.35) if no_heroi else Color(1, 0.95, 0.5))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.position = alvo.position + Vector2(randf_range(-20, 20), -alvo.get_child(0).size.y - 50)
	add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 50, 0.7)
	t.tween_property(l, "modulate:a", 0.0, 0.7)
	t.chain().tween_callback(l.queue_free)

func _inimigo_morreu() -> void:
	inimigo.visible = false
	respawn = Cfg.RESPAWN_SEGUNDOS
	ouro += inimigo.get_meta("ouro")
	xp += inimigo.get_meta("xp")
	while xp >= _xp_para_subir():
		xp -= _xp_para_subir()
		nivel += 1
		heroi.vida_max = _vida_heroi()
		heroi.dano = _dano_heroi()
		heroi.vida = heroi.vida_max
		heroi.atualiza_barra()
	abates += 1
	if abates >= Cfg.INIMIGOS_POR_FASE:
		abates = 0
		if fase < Cfg.FASES_TOTAL:
			fase += 1   # na ultima fase continua farmando ela (boss entra no dia 9)
		heroi.cura(heroi.vida_max)
	_atualiza_hud()

func _heroi_morreu() -> void:
	# Derrota simples: recomeca a fase com vida cheia (tela de derrota vem no dia 9)
	abates = 0
	heroi.vivo = true
	heroi.vida = heroi.vida_max
	heroi.atualiza_barra()
	_novo_inimigo()
	_atualiza_hud()

func _atualiza_hud() -> void:
	_hud_texto.text = "Nível %d      Ouro: %d" % [nivel, floori(ouro)]
	_barra_xp.max_value = _xp_para_subir()
	_barra_xp.value = xp
	_rotulo_fase.text = "Fase %d/%d   Inimigos %d/%d" % [fase, Cfg.FASES_TOTAL, abates, Cfg.INIMIGOS_POR_FASE]
	_barra_fase.max_value = Cfg.INIMIGOS_POR_FASE
	_barra_fase.value = abates
