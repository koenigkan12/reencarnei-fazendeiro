extends RefCounted
# Opcoes do jogador (volumes, tela cheia, resolucao) e marcas de primeira vez. Ficam em user://opcoes.cfg,
# separado do save do jogo. Tambem guarda o tempo jogado do save atual (para a tela de fim).
const Cfg := preload("res://scripts/cfg.gd")
const Audio := preload("res://scripts/audio.gd")

const CAMINHO := "user://opcoes.cfg"

var volume_musica := 0.8
var volume_efeitos := 0.8
var tela_cheia := false
var resolucao := 0                # indice em Cfg.RESOLUCOES
var tutorial_visto := false

func carrega() -> void:
	var c := ConfigFile.new()
	if c.load(CAMINHO) != OK:
		return
	volume_musica = clampf(float(c.get_value("opcoes", "volume_musica", volume_musica)), 0.0, 1.0)
	volume_efeitos = clampf(float(c.get_value("opcoes", "volume_efeitos", volume_efeitos)), 0.0, 1.0)
	tela_cheia = bool(c.get_value("opcoes", "tela_cheia", tela_cheia))
	resolucao = clampi(int(c.get_value("opcoes", "resolucao", resolucao)), 0, Cfg.RESOLUCOES.size() - 1)
	tutorial_visto = bool(c.get_value("jogo", "tutorial_visto", tutorial_visto))

func salva() -> void:
	var c := ConfigFile.new()
	c.load(CAMINHO)   # mantem o que ja estava (ex.: tempo jogado)
	c.set_value("opcoes", "volume_musica", volume_musica)
	c.set_value("opcoes", "volume_efeitos", volume_efeitos)
	c.set_value("opcoes", "tela_cheia", tela_cheia)
	c.set_value("opcoes", "resolucao", resolucao)
	c.set_value("jogo", "tutorial_visto", tutorial_visto)
	c.save(CAMINHO)

func aplica() -> void:
	Audio.garante_buses()
	Audio.define_volume("Musica", volume_musica)
	Audio.define_volume("Efeitos", volume_efeitos)
	if tela_cheia:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var tam: Vector2i = Cfg.RESOLUCOES[resolucao]
		var tela: Vector2i = DisplayServer.screen_get_size()
		DisplayServer.window_set_size(tam)
		if tela.x > 0:
			DisplayServer.window_set_position(Vector2i((tela.x - tam.x) / 2, maxi((tela.y - tam.y) / 2, 0)))

# ---------- tempo jogado do save atual ----------
func tempo_jogado() -> float:
	var c := ConfigFile.new()
	if c.load(CAMINHO) != OK:
		return 0.0
	return float(c.get_value("progresso", "tempo_jogado", 0.0))

func salva_tempo_jogado(segundos: float) -> void:
	var c := ConfigFile.new()
	c.load(CAMINHO)
	c.set_value("progresso", "tempo_jogado", segundos)
	c.save(CAMINHO)
