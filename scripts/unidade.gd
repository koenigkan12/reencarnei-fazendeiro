extends Control
# Combatente: sprite animado (quando ha arte) ou retangulo colorido (placeholder), barra de vida e nome.
# A posicao do node e o ponto dos pes do combatente.

var nome := ""
var vida_max := 1.0
var vida := 1.0
var dano := 1.0
var intervalo := 1.0
var tempo_ataque := 0.0
var vivo := true
var altura := 80.0          # altura visual (para barra, nome e numeros de dano)

var _corpo: ColorRect
var _sprite: AnimatedSprite2D
var _barra: ProgressBar
var _rotulo: Label
var _tamanho := Vector2(50, 80)
var _tint := Color.WHITE
var _escala := 1.0
var _flip := false

func configura(n: String, cor: Color, tamanho: Vector2, v: float, d: float, i: float, arte: Dictionary = {}) -> void:
	nome = n
	vida_max = v
	vida = v
	dano = d
	intervalo = i
	tempo_ataque = i * randf_range(0.3, 1.0)
	vivo = true
	_tamanho = tamanho
	if _corpo == null:
		_corpo = ColorRect.new()
		add_child(_corpo)
		_sprite = AnimatedSprite2D.new()
		add_child(_sprite)
		_barra = ProgressBar.new()
		_barra.show_percentage = false
		_barra.custom_minimum_size = Vector2(80, 10)
		_barra.size = Vector2(80, 10)
		_barra.modulate = Color(1, 0.35, 0.35)
		add_child(_barra)
		_rotulo = Label.new()
		_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rotulo.size = Vector2(120, 20)
		add_child(_rotulo)
	_barra.visible = true
	_rotulo.visible = true
	if arte.is_empty():
		_sprite.visible = false
		_corpo.visible = true
		_corpo.color = cor
		_corpo.size = tamanho
		_corpo.position = Vector2(-tamanho.x / 2.0, -tamanho.y)
		_tint = Color.WHITE
		altura = tamanho.y
	else:
		_corpo.visible = false
		_sprite.visible = true
		_sprite.sprite_frames = arte["frames"]
		_escala = arte["escala"]
		_tint = arte["tint"]
		_flip = arte["flip"]
		_sprite.scale = Vector2(_escala, _escala)
		_sprite.flip_h = _flip
		_sprite.modulate = _tint
		var frame_h: float = _sprite.sprite_frames.get_frame_texture("idle", 0).get_height()
		_sprite.position = Vector2(0, -frame_h * _escala / 2.0 + arte["pe"] * _escala)
		altura = (frame_h - arte["pe"]) * _escala * 0.8
		_sprite.play("idle")
	_barra.position = Vector2(-40, -altura - 18)
	_rotulo.position = Vector2(-60, -altura - 40)
	atualiza_barra()

func atualiza_barra() -> void:
	_barra.max_value = vida_max
	_barra.value = maxf(vida, 0.0)
	_rotulo.text = "%s  %d/%d" % [nome, ceili(maxf(vida, 0.0)), ceili(vida_max)]

func _visual() -> CanvasItem:
	return _sprite if _sprite.visible else _corpo

func recebe_dano(valor: float) -> void:
	vida -= valor
	if vida <= 0.0:
		vida = 0.0
		vivo = false
	atualiza_barra()
	var v := _visual()
	var base := _tint if _sprite.visible else Color.WHITE
	v.modulate = Color(2, 2, 2)
	create_tween().tween_property(v, "modulate", base, 0.12)

func cura(valor: float) -> void:
	vida = minf(vida + valor, vida_max)
	atualiza_barra()

func animacao_ataque(direcao: float) -> void:
	if _sprite.visible:
		if _sprite.sprite_frames.has_animation("ataque"):
			_sprite.play("ataque")
			if not _sprite.animation_finished.is_connected(_volta_idle):
				_sprite.animation_finished.connect(_volta_idle, CONNECT_ONE_SHOT)
		var t := create_tween()
		t.tween_property(_sprite, "position:x", 24.0 * direcao, 0.06)
		t.tween_property(_sprite, "position:x", 0.0, 0.10)
	else:
		var t2 := create_tween()
		t2.tween_property(_corpo, "position:x", -_tamanho.x / 2.0 + 24.0 * direcao, 0.06)
		t2.tween_property(_corpo, "position:x", -_tamanho.x / 2.0, 0.10)

func _volta_idle() -> void:
	if vivo and _sprite.visible:
		_sprite.play("idle")

# Chamado quando morre: toca a animacao de morte (se houver) e esconde barra e nome
func morte() -> void:
	_barra.visible = false
	_rotulo.visible = false
	if _sprite.visible and _sprite.sprite_frames.has_animation("morte"):
		if _sprite.animation_finished.is_connected(_volta_idle):
			_sprite.animation_finished.disconnect(_volta_idle)
		_sprite.play("morte")

func idle() -> void:
	if _sprite.visible:
		_sprite.play("idle")

# Volta a lutar depois de descansar (mostra de novo barra e nome)
func revive() -> void:
	_barra.visible = true
	_rotulo.visible = true
	idle()
