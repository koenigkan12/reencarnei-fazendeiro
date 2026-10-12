extends Node
# Gancho de AUDIO. O jogo ainda nao tem sons: este no procura arquivos em res://assets/audio/<nome>.ogg|mp3|wav
# e toca se existirem (se nao existirem, fica em silencio). Nomes usados pelo jogo: ver Cfg.AUDIO_NOMES.
# De qualquer lugar: Audio.toca_efeito("clique") e Audio.toca_musica("jogo").
const Cfg := preload("res://scripts/cfg.gd")

static var instancia = null

var _musica: AudioStreamPlayer
var _efeitos: Array = []      # AudioStreamPlayer em rodizio
var _prox := 0
var _musica_atual := ""

static func toca_efeito(nome: String) -> void:
	if instancia != null:
		instancia.efeito(nome)

static func toca_musica(nome: String) -> void:
	if instancia != null:
		instancia.musica(nome)

func _ready() -> void:
	instancia = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	garante_buses()
	_musica = AudioStreamPlayer.new()
	_musica.bus = "Musica"
	add_child(_musica)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Efeitos"
		add_child(p)
		_efeitos.append(p)

func _exit_tree() -> void:
	if instancia == self:
		instancia = null

# Cria os buses "Musica" e "Efeitos" (filhos do Master) se o projeto ainda nao tem
static func garante_buses() -> void:
	for nome in ["Musica", "Efeitos"]:
		if AudioServer.get_bus_index(nome) == -1:
			AudioServer.add_bus()
			var idx: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, nome)
			AudioServer.set_bus_send(idx, "Master")

static func define_volume(bus: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))

func _carrega(nome: String) -> AudioStream:
	for ext in ["ogg", "mp3", "wav"]:
		var caminho: String = "%s/%s.%s" % [Cfg.AUDIO_PASTA, nome, ext]
		if ResourceLoader.exists(caminho):
			return load(caminho) as AudioStream
	return null

func musica(nome: String) -> void:
	if nome == _musica_atual:
		return
	_musica_atual = nome
	var s: AudioStream = _carrega(nome)
	if s == null:
		_musica.stop()
		return
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2   # 16 bits, mono
	elif "loop" in s:
		s.set("loop", true)
	_musica.stream = s
	_musica.play()

func efeito(nome: String) -> void:
	var s: AudioStream = _carrega(nome)
	if s == null:
		return
	var p: AudioStreamPlayer = _efeitos[_prox]
	_prox = (_prox + 1) % _efeitos.size()
	p.stream = s
	p.play()
