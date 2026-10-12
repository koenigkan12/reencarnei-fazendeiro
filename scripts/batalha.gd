extends Control
# Area de batalha: heroi (esquerda) luta sozinho contra inimigos (direita).
# Ouro, XP, nivel, upgrades e equipamento vivem no Estado (compartilhado com as abas).

const Cfg := preload("res://scripts/cfg.gd")
const Unidade := preload("res://scripts/unidade.gd")

signal pede_aba(nome: String)

var estado
var heroi: Control
var inimigo: Control
var fase := 1
var abates := 0               # inimigos mortos na fase atual
var respawn := 0.0
var contra_chefe := false
var chefe_tipo := ""
var tempo_chefe := 0.0
var descanso := 0.0           # > 0: heroi derrotado, descansando
var derrotas := 0
var vitoria_final := false

var _fundo: ColorRect
var _chao: ColorRect
var _hud_texto: Label
var _barra_xp: ProgressBar
var _barra_fase: ProgressBar
var _rotulo_fase: Label
var _barra_chefe: ProgressBar
var _aviso: Label
var _msg_drop: Label
var _hud_comida: Label
var _caixas_hab: Array = []   # [{painel, rotulo}]
var cd_hab := {}                # id -> segundos restantes
var gcd := 0.0
var furia_restante := 0.0
var escudo_restante := 0.0
var _painel_derrota: PanelContainer
var _texto_derrota: Label

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
	heroi.configura("Herói", Color(0.3, 0.5, 0.95), Vector2(50, 90), estado.personagem.vida_max(), estado.personagem.ataque(), estado.personagem.intervalo())
	inimigo = Unidade.new()
	add_child(inimigo)
	_novo_inimigo()

	_cria_hud()
	_cria_derrota()
	estado.mudou.connect(_sincroniza)
	estado.item_dropou.connect(_mostra_drop)
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
	_barra_chefe = ProgressBar.new()
	_barra_chefe.show_percentage = false
	_barra_chefe.size = Vector2(360, 14)
	_barra_chefe.modulate = Color(1.0, 0.3, 0.3)
	_barra_chefe.visible = false
	add_child(_barra_chefe)
	_aviso = Label.new()
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 40)
	_aviso.add_theme_color_override("font_color", Color(1, 0.25, 0.2))
	_aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override("outline_size", 8)
	_aviso.modulate.a = 0.0
	add_child(_aviso)
	_hud_comida = Label.new()
	add_child(_hud_comida)
	for i in Cfg.SLOTS_HABILIDADE:
		var p := PanelContainer.new()
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(110, 40)
		p.add_child(l)
		add_child(p)
		_caixas_hab.append({"painel": p, "rotulo": l})
	_msg_drop = Label.new()
	_msg_drop.add_theme_font_size_override("font_size", 18)
	_msg_drop.add_theme_color_override("font_outline_color", Color.BLACK)
	_msg_drop.add_theme_constant_override("outline_size", 4)
	_msg_drop.modulate.a = 0.0
	add_child(_msg_drop)

func _cria_derrota() -> void:
	_painel_derrota = PanelContainer.new()
	_painel_derrota.visible = false
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_painel_derrota.add_child(v)
	_texto_derrota = Label.new()
	_texto_derrota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_texto_derrota)
	var dica := Label.new()
	dica.text = "Como ficar mais forte:"
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dica)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	for nome in ["Personagem", "Equipamento", "Fazenda"]:
		var bt := Button.new()
		bt.text = {"Personagem": "Upgrades", "Equipamento": "Equipamento", "Fazenda": "Comida"}[nome]
		bt.pressed.connect(func(): pede_aba.emit(nome))
		h.add_child(bt)
	add_child(_painel_derrota)

func _posiciona() -> void:
	var chao_y := size.y * 0.78
	_chao.position = Vector2(0, chao_y)
	_chao.size = Vector2(size.x, size.y - chao_y)
	heroi.position = Vector2(size.x * 0.25, chao_y)
	inimigo.position = Vector2(size.x * 0.72, chao_y)
	_rotulo_fase.position = Vector2(size.x / 2.0 - 180, 10)
	_rotulo_fase.size = Vector2(360, 24)
	_barra_fase.position = Vector2(size.x / 2.0 - 180, 38)
	_barra_chefe.position = Vector2(size.x / 2.0 - 180, 58)
	_aviso.position = Vector2(0, size.y * 0.25)
	_aviso.size = Vector2(size.x, 60)
	_msg_drop.position = Vector2(16, 70)
	_hud_comida.position = Vector2(16, size.y - 34)
	for i in _caixas_hab.size():
		_caixas_hab[i]["painel"].position = Vector2(size.x - 16 - (_caixas_hab.size() - i) * 122, size.y - 62)
	_painel_derrota.position = Vector2(size.x / 2.0 - 190, size.y * 0.3)
	_painel_derrota.size = Vector2(380, 150)

# ---------- chefes e inimigos ----------
func _tipo_chefe_da_fase() -> String:
	if fase % 10 == 5:
		return "mini"
	if fase % 10 == 0:
		return "boss"
	return ""

func _novo_inimigo() -> void:
	var e := fase - 1
	if contra_chefe:
		var c: Dictionary = Cfg.CHEFES[chefe_tipo]
		var base: Dictionary = _lista_inimigos()[2]
		inimigo.configura(c["nome"], c["cor"], c["tamanho"],
			base["vida"] * c["vida_mult"] * pow(Cfg.ESCALA_VIDA, e), base["dano"] * c["dano_mult"] * pow(Cfg.ESCALA_DANO, e), base["intervalo"])
		inimigo.set_meta("ouro", base["ouro"] * c["ouro_mult"] * pow(Cfg.ESCALA_OURO, e))
		inimigo.set_meta("xp", base["xp"] * c["xp_mult"] * pow(Cfg.ESCALA_XP, e))
	else:
		var lista := _lista_inimigos()
		var base2: Dictionary = lista[randi() % lista.size()]
		inimigo.configura(base2["nome"], base2["cor"], base2["tamanho"],
			base2["vida"] * pow(Cfg.ESCALA_VIDA, e), base2["dano"] * pow(Cfg.ESCALA_DANO, e), base2["intervalo"])
		inimigo.set_meta("ouro", base2["ouro"] * pow(Cfg.ESCALA_OURO, e))
		inimigo.set_meta("xp", base2["xp"] * pow(Cfg.ESCALA_XP, e))
	inimigo.visible = true

func _lista_inimigos() -> Array:
	return Cfg.INIMIGOS_ZONA2 if fase >= Cfg.ZONA2_A_PARTIR_DA_FASE else Cfg.INIMIGOS

func _inicia_chefe() -> void:
	contra_chefe = true
	chefe_tipo = _tipo_chefe_da_fase()
	tempo_chefe = Cfg.CHEFES[chefe_tipo]["tempo"]
	_novo_inimigo()
	_barra_chefe.visible = true
	_aviso.text = "⚠ WARNING ⚠\n%s!" % Cfg.CHEFES[chefe_tipo]["nome"]
	_aviso.size.y = 110
	var t := create_tween()
	_aviso.modulate.a = 1.0
	t.tween_interval(1.2)
	t.tween_property(_aviso, "modulate:a", 0.0, 0.6)

# ---------- loop ----------
func _process(delta: float) -> void:
	_atualiza_comida()
	if descanso > 0.0:
		descanso -= delta
		_texto_derrota.text = "Derrotado! O herói descansa... %d s" % ceili(maxf(descanso, 0.0))
		if descanso <= 0.0:
			_levanta()
		return
	if vitoria_final:
		return
	heroi.cura(heroi.vida_max * estado.personagem.regen_pct() * delta)
	_tick_habilidades(delta)
	if contra_chefe:
		tempo_chefe -= delta
		_barra_chefe.max_value = Cfg.CHEFES[chefe_tipo]["tempo"]
		_barra_chefe.value = maxf(tempo_chefe, 0.0)
		if tempo_chefe <= 0.0:
			_derrota("Tempo esgotado!")
			return
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
			_derrota("O herói caiu!")

func _ataca(atacante: Control, alvo: Control, direcao: float) -> void:
	atacante.animacao_ataque(direcao)
	if atacante == heroi:
		var dano: float = atacante.dano * (1.0 + _furia_valor())
		var crit: bool = randf() < estado.personagem.crit_chance()
		if crit:
			dano *= estado.personagem.crit_mult()
		alvo.recebe_dano(dano)
		_numero_de_dano(alvo, dano, false, crit)
	else:
		var dano2: float = atacante.dano * estado.personagem.reducao_dano()
		if escudo_restante > 0.0:
			dano2 *= 1.0 - _escudo_valor()
		alvo.recebe_dano(dano2)
		_numero_de_dano(alvo, dano2, true, false)

func _furia_valor() -> float:
	return Cfg.HABILIDADES[3]["valor"] * estado.personagem.fator_habilidade("furia") if furia_restante > 0.0 else 0.0

func _escudo_valor() -> float:
	return minf(Cfg.HABILIDADES[4]["valor"] * estado.personagem.fator_habilidade("escudo"), 0.9)

# Habilidades automaticas: a cada GCD usa a primeira pronta da esquerda para a direita
func _tick_habilidades(delta: float) -> void:
	furia_restante = maxf(furia_restante - delta, 0.0)
	escudo_restante = maxf(escudo_restante - delta, 0.0)
	for id in cd_hab.keys():
		cd_hab[id] = maxf(cd_hab[id] - delta, 0.0)
	gcd -= delta
	if gcd > 0.0 or not inimigo.vivo or not heroi.vivo:
		return
	for id in estado.personagem.hab_slots:
		if id == "" or cd_hab.get(id, 0.0) > 0.0:
			continue
		var h: Dictionary = estado.personagem.habilidade_por_id(id)
		if h["tipo"] == "cura" and heroi.vida > heroi.vida_max * 0.85:
			continue
		if h["tipo"] == "buff_dano" and furia_restante > 0.0:
			continue
		if h["tipo"] == "escudo" and escudo_restante > 0.0:
			continue
		_usa_habilidade(h)
		cd_hab[id] = h["cd"]
		gcd = Cfg.GCD_HABILIDADE
		return

func _usa_habilidade(h: Dictionary) -> void:
	var f: float = estado.personagem.fator_habilidade(h["id"])
	_nome_habilidade(h["nome"])
	match h["tipo"]:
		"dano":
			heroi.animacao_ataque(1.0)
			for g in h["golpes"]:
				var dano: float = heroi.dano * (1.0 + _furia_valor()) * h["mult"] * f
				var crit: bool = randf() < estado.personagem.crit_chance()
				if crit:
					dano *= estado.personagem.crit_mult()
				inimigo.recebe_dano(dano)
				_numero_de_dano(inimigo, dano, false, crit)
				if not inimigo.vivo:
					_inimigo_morreu()
					return
		"cura":
			var quanto: float = heroi.vida_max * h["valor"] * f
			heroi.cura(quanto)
			_numero_de_dano(heroi, quanto, false, false, Color(0.4, 1.0, 0.5))
		"buff_dano":
			furia_restante = h["duracao"]
		"escudo":
			escudo_restante = h["duracao"]

func _nome_habilidade(nome: String) -> void:
	var l := Label.new()
	l.text = nome + "!"
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.position = heroi.position + Vector2(-70, -heroi.get_child(0).size.y - 90)
	add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 30, 1.0)
	t.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.4)
	t.chain().tween_callback(l.queue_free)
func _numero_de_dano(alvo: Control, valor: float, no_heroi: bool, crit: bool, cor: Color = Color(0, 0, 0, 0)) -> void:
	var l := Label.new()
	l.text = ("%d!" if crit else "%d") % roundi(valor)
	l.add_theme_font_size_override("font_size", 34 if crit else 24)
	var c := Color(1, 0.35, 0.35) if no_heroi else (Color(1, 0.6, 0.15) if crit else Color(1, 0.95, 0.5))
	if cor.a > 0.0:
		c = cor
	l.add_theme_color_override("font_color", c)
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
	var era_chefe := contra_chefe
	var subiu: bool = estado.ganha(inimigo.get_meta("ouro"), inimigo.get_meta("xp"))
	if subiu:
		heroi.vida = heroi.vida_max
	estado.equipamento.tenta_drop(fase, era_chefe)
	estado.fazenda.tenta_semente(era_chefe)
	if era_chefe:
		contra_chefe = false
		_barra_chefe.visible = false
		_avanca_fase()
	else:
		abates += 1
		if abates >= Cfg.INIMIGOS_POR_FASE:
			if _tipo_chefe_da_fase() != "":
				abates = Cfg.INIMIGOS_POR_FASE
				_inicia_chefe()
			else:
				_avanca_fase()
	_sincroniza()

func _avanca_fase() -> void:
	abates = 0
	if fase < Cfg.FASES_TOTAL:
		fase += 1
		_fundo.color = Color(0.22, 0.16, 0.28) if fase >= Cfg.ZONA2_A_PARTIR_DA_FASE else Color(0.16, 0.22, 0.28)
	else:
		vitoria_final = true
		_painel_derrota.visible = true
		_texto_derrota.text = "Vitória! Você derrotou o chefe da fase %d.\n(Fim da zona 1. Continue fortalecendo o herói!)" % fase
	heroi.cura(heroi.vida_max)

func _derrota(motivo: String) -> void:
	derrotas += 1
	descanso = Cfg.DESCANSO_SEGUNDOS
	contra_chefe = false
	_barra_chefe.visible = false
	abates = 0
	heroi.modulate = Color(0.5, 0.5, 0.5)
	inimigo.visible = false
	_texto_derrota.text = motivo
	_painel_derrota.visible = true
	_atualiza_hud()

func _levanta() -> void:
	furia_restante = 0.0
	escudo_restante = 0.0
	heroi.modulate = Color.WHITE
	heroi.vivo = true
	heroi.vida = heroi.vida_max
	heroi.atualiza_barra()
	_painel_derrota.visible = false
	_novo_inimigo()
	_atualiza_hud()

# ---------- sincronia com o Estado ----------
func _sincroniza() -> void:
	var razao: float = heroi.vida / heroi.vida_max
	heroi.vida_max = estado.personagem.vida_max()
	heroi.vida = minf(razao * heroi.vida_max + 0.0, heroi.vida_max)
	heroi.dano = estado.personagem.ataque()
	heroi.intervalo = estado.personagem.intervalo()
	heroi.atualiza_barra()
	_atualiza_hud()

func _mostra_drop(info: Dictionary) -> void:
	var it: Dictionary = info["item"]
	var r: Dictionary = Cfg.RARIDADES[it["raridade"]]
	var acao := "equipado" if info["equipou"] else "vendido +%d ouro" % info["ouro"]
	_msg_drop.text = "Drop: %s (%s) - %s" % [estado.equipamento.nome_item(it), estado.equipamento.descricao_item(it), acao]
	_msg_drop.add_theme_color_override("font_color", r["cor"])
	_msg_drop.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(2.5)
	t.tween_property(_msg_drop, "modulate:a", 0.0, 0.8)

func _atualiza_hud() -> void:
	_hud_texto.text = "Nível %d      Ouro: %d      CP: %d" % [estado.nivel, floori(estado.ouro), estado.personagem.cp()]
	_barra_xp.max_value = estado.xp_para_subir()
	_barra_xp.value = estado.xp
	var rot := "Fase %d/%d   Inimigos %d/%d" % [fase, Cfg.FASES_TOTAL, abates, Cfg.INIMIGOS_POR_FASE]
	if _tipo_chefe_da_fase() != "":
		rot += "   [%s]" % Cfg.CHEFES[_tipo_chefe_da_fase()]["nome"]
	_rotulo_fase.text = rot
	_barra_fase.max_value = Cfg.INIMIGOS_POR_FASE
	_barra_fase.value = abates

func _atualiza_comida() -> void:
	for i in _caixas_hab.size():
		var id: String = estado.personagem.hab_slots[i]
		var l: Label = _caixas_hab[i]["rotulo"]
		if id == "":
			l.text = "(vazio)"
		else:
			var h: Dictionary = estado.personagem.habilidade_por_id(id)
			var cd: float = cd_hab.get(id, 0.0)
			l.text = h["nome"] + ("\npronto" if cd <= 0.0 else "\n%.1f s" % cd)
	var partes: Array = []
	for sl in estado.comida.slots_comida:
		if sl["prato"] == -1:
			partes.append("[vazio]")
		elif sl["restante"] > 0.0:
			partes.append("[%s %d s]" % [Cfg.PRATOS[sl["prato"]]["nome"], ceili(sl["restante"])])
		else:
			partes.append("[%s: sem estoque]" % Cfg.PRATOS[sl["prato"]]["nome"])
	_hud_comida.text = "Comida: " + "  ".join(partes)