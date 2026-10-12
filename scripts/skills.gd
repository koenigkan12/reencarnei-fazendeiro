extends RefCounted
# Sistema HABILIDADES AUTOMATICAS (em batalha): a cada GCD usa a primeira habilidade pronta da fila
# (esquerda -> direita). Cuida de recarga, buffs, dano e dos efeitos visuais, todos feitos por codigo
# (piscar, tremer, projeteis, particulas, numeros e o nome da habilidade escrito na tela).
# Quem tem as habilidades equipadas e os talentos e o personagem.gd; aqui so ha o que acontece na luta.
const Cfg := preload("res://scripts/cfg.gd")

var b                          # batalha.gd (a cena onde os efeitos aparecem)
var e                          # Estado
var cd := {}                   # id da habilidade -> segundos de recarga restantes
var gcd := 0.0
var escudo_restante := 0.0
var escudo_valor := 0.0
var mira_restante := 0.0
var mira_valor := 0.0

func _init(batalha, estado) -> void:
	b = batalha
	e = estado

func reset() -> void:
	escudo_restante = 0.0
	mira_restante = 0.0
	gcd = 0.0

# chance de critico atual (personagem + buff de mira)
func crit_chance() -> float:
	return minf(e.personagem.crit_chance() + (mira_valor if mira_restante > 0.0 else 0.0), 0.95)

# multiplicador do dano recebido pelo heroi por causa do escudo
func escudo_mult() -> float:
	return 1.0 - escudo_valor if escudo_restante > 0.0 else 1.0

func tick(delta: float) -> void:
	escudo_restante = maxf(escudo_restante - delta, 0.0)
	mira_restante = maxf(mira_restante - delta, 0.0)
	for id in cd.keys():
		cd[id] = maxf(cd[id] - delta, 0.0)
	gcd -= delta
	if gcd > 0.0 or not b.inimigo.vivo or not b.heroi.vivo:
		return
	for id in e.personagem.hab_slots:
		if id == "" or cd.get(id, 0.0) > 0.0:
			continue
		var h: Dictionary = e.personagem.habilidade_por_id(id)
		if h["tipo"] == "cura" and b.heroi.vida > b.heroi.vida_max * 0.85:
			continue
		if h["tipo"] == "escudo" and escudo_restante > 0.0:
			continue
		if h["tipo"] == "buff_crit" and mira_restante > 0.0:
			continue
		_usa(h)
		cd[id] = h["cd"] * e.personagem.recarga_mult()
		gcd = Cfg.GCD_HABILIDADE
		return

func _usa(h: Dictionary) -> void:
	var f: float = e.personagem.fator_habilidade(h["id"])
	_nome(h)
	match h["tipo"]:
		"dano":
			_visual(h)
			for g in h["golpes"]:
				var dano: float = b.heroi.dano * h["mult"] * f * e.personagem.dano_habilidade_mult(h)
				var crit: bool = randf() < crit_chance()
				if crit:
					dano *= e.personagem.crit_mult()
				b.inimigo.recebe_dano(dano)
				b._numero_de_dano(b.inimigo, dano, false, crit)
				if not b.inimigo.vivo:
					b._inimigo_morreu()
					return
		"cura":
			var quanto: float = b.heroi.vida_max * h["valor"] * f
			b.heroi.cura(quanto)
			b._numero_de_dano(b.heroi, quanto, false, false, Color(0.4, 1.0, 0.5))
			_particulas(_centro(b.heroi), Color(0.4, 1.0, 0.5), 18, Vector2(0, -1), 60.0, 140.0)
			_pisca(b.heroi, Color(0.6, 2.0, 0.8))
		"escudo":
			escudo_restante = h["duracao"]
			escudo_valor = minf(h["valor"] * f, 0.9)
			_particulas(_centro(b.heroi), Color(0.85, 0.85, 1.0), 16, Vector2(0, -1), 40.0, 110.0)
			_pisca(b.heroi, Color(1.5, 1.5, 2.2))
		"buff_crit":
			mira_restante = h["duracao"]
			mira_valor = h["valor"] * f
			_particulas(_centro(b.heroi), Color(1.0, 0.9, 0.3), 14, Vector2(0, -1), 40.0, 100.0)
			_pisca(b.heroi, Color(2.0, 1.8, 1.0))

# ---------- efeitos visuais ----------
func _visual(h: Dictionary) -> void:
	var cor: Color = h.get("cor", Color(1, 1, 1))
	match h["efeito"]:
		"corte":
			b.heroi.animacao_ataque(1.0)
			_risco(_centro(b.inimigo), Color(1, 1, 1))
			_particulas(_centro(b.inimigo), Color(1, 0.9, 0.6), 8, Vector2(1, 0), 80.0, 160.0)
		"giro":
			b.heroi.animacao_ataque(1.0)
			_risco(_centro(b.inimigo), Color(1, 0.8, 0.4))
			_particulas(_centro(b.inimigo), Color(1, 0.6, 0.3), 22, Vector2(0, -1), 100.0, 240.0)
			_treme(b.inimigo, 14.0)
		"enxada":
			_arremessa(Color(0.55, 0.38, 0.2), Vector2(34, 10), true)
			_particulas(_centro(b.inimigo), Color(0.8, 0.6, 0.3), 30, Vector2(0, -1), 120.0, 300.0)
			_treme(b.inimigo, 22.0)
			_pisca(b.inimigo, Color(2, 2, 1.2))
		"projetil":
			b.heroi.animacao_ataque(1.0)
			_arremessa(cor, Vector2(20, 20), false)
			_particulas(_centro(b.inimigo), cor, 14, Vector2(0, -1), 80.0, 180.0)
		"chuva":
			b.heroi.animacao_ataque(1.0)
			for k in 3:
				_arremessa(cor, Vector2(26, 6), false, 0.08 * k)
			_particulas(_centro(b.inimigo), cor, 18, Vector2(0, -1), 80.0, 200.0)
		"raio":
			_raio(_centro(b.inimigo), cor)
			_particulas(_centro(b.inimigo), cor, 24, Vector2(0, -1), 120.0, 280.0)
			_treme(b.inimigo, 18.0)
			_pisca(b.inimigo, Color(1.5, 1.8, 3.0))

# nome da habilidade escrito acima do heroi, na cor do estilo
func _nome(h: Dictionary) -> void:
	var l := Label.new()
	l.text = h["nome"] + "!"
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Cfg.ESTILOS[h["estilo"]]["cor"])
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.position = b.heroi.position + Vector2(-70, -b.heroi.get_child(0).size.y - 90)
	b.add_child(l)
	var t := b.create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 30, 1.0)
	t.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.4)
	t.chain().tween_callback(l.queue_free)

func _centro(u: Control) -> Vector2:
	return u.position + Vector2(0, -u.get_child(0).size.y / 2.0)

func _pisca(u: Control, cor: Color) -> void:
	u.modulate = cor
	var t := b.create_tween()
	t.tween_property(u, "modulate", Color.WHITE, 0.25)

func _treme(u: Control, forca: float) -> void:
	var origem := u.position
	var t := b.create_tween()
	for k in 5:
		t.tween_property(u, "position", origem + Vector2(randf_range(-forca, forca), randf_range(-forca, forca) * 0.4), 0.03)
		forca *= 0.7
	t.tween_property(u, "position", origem, 0.03)

func _particulas(pos: Vector2, cor: Color, qtd: int, direcao: Vector2, vmin: float, vmax: float) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = false
	p.one_shot = true
	p.amount = qtd
	p.lifetime = 0.6
	p.explosiveness = 0.95
	p.direction = direcao
	p.spread = 180.0
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.gravity = Vector2(0, 300)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = cor
	b.add_child(p)
	p.emitting = true
	var t := b.create_tween()
	t.tween_interval(1.2)
	t.tween_callback(p.queue_free)

# risco claro que aparece no alvo e some (corte)
func _risco(pos: Vector2, cor: Color) -> void:
	var r := ColorRect.new()
	r.color = cor
	r.size = Vector2(90, 6)
	r.pivot_offset = r.size / 2.0
	r.position = pos - r.size / 2.0
	r.rotation = -0.6
	b.add_child(r)
	var t := b.create_tween()
	t.tween_property(r, "modulate:a", 0.0, 0.2)
	t.tween_callback(r.queue_free)

# projetil que sai do heroi e vai ate o inimigo
func _arremessa(cor: Color, tamanho: Vector2, gira: bool, atraso: float = 0.0) -> void:
	var r := ColorRect.new()
	r.color = cor
	r.size = tamanho
	r.pivot_offset = tamanho / 2.0
	r.position = _centro(b.heroi) - tamanho / 2.0
	r.visible = false
	b.add_child(r)
	var alvo := _centro(b.inimigo) - tamanho / 2.0
	var t := b.create_tween()
	if atraso > 0.0:
		t.tween_interval(atraso)
	t.tween_callback(func(): r.visible = true)
	t.tween_property(r, "position", alvo, 0.22)
	if gira:
		t.parallel().tween_property(r, "rotation", TAU * 2.0, 0.22)
	t.tween_callback(r.queue_free)

# coluna de luz que cai sobre o alvo
func _raio(pos: Vector2, cor: Color) -> void:
	var r := ColorRect.new()
	r.color = cor
	r.size = Vector2(16, pos.y + 40)
	r.position = Vector2(pos.x - 8, 0)
	b.add_child(r)
	var t := b.create_tween()
	t.tween_property(r, "modulate:a", 0.0, 0.25)
	t.tween_callback(r.queue_free)
