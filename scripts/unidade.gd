extends Control
# Combatente placeholder: retangulo colorido + barra de vida + nome.
# A posicao do node e o ponto dos pes do combatente.

var nome := ""
var vida_max := 1.0
var vida := 1.0
var dano := 1.0
var intervalo := 1.0
var tempo_ataque := 0.0
var vivo := true

var _corpo: ColorRect
var _barra: ProgressBar
var _rotulo: Label
var _tamanho := Vector2(50, 80)

func configura(n: String, cor: Color, tamanho: Vector2, v: float, d: float, i: float) -> void:
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
	_corpo.color = cor
	_corpo.size = tamanho
	_corpo.position = Vector2(-tamanho.x / 2.0, -tamanho.y)
	_barra.position = Vector2(-40, -tamanho.y - 18)
	_rotulo.position = Vector2(-60, -tamanho.y - 40)
	atualiza_barra()

func atualiza_barra() -> void:
	_barra.max_value = vida_max
	_barra.value = maxf(vida, 0.0)
	_rotulo.text = "%s  %d/%d" % [nome, ceili(maxf(vida, 0.0)), ceili(vida_max)]

func recebe_dano(valor: float) -> void:
	vida -= valor
	if vida <= 0.0:
		vida = 0.0
		vivo = false
	atualiza_barra()
	var t := create_tween()
	_corpo.modulate = Color(2, 2, 2)
	t.tween_property(_corpo, "modulate", Color(1, 1, 1), 0.12)

func cura(valor: float) -> void:
	vida = minf(vida + valor, vida_max)
	atualiza_barra()

func animacao_ataque(direcao: float) -> void:
	var t := create_tween()
	t.tween_property(_corpo, "position:x", -_tamanho.x / 2.0 + 24.0 * direcao, 0.06)
	t.tween_property(_corpo, "position:x", -_tamanho.x / 2.0, 0.10)
