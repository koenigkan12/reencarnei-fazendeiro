extends Node
# Salva o jogo sozinho a cada Cfg.AUTOSAVE_SEGUNDOS, ao fechar a janela e ao perder o foco.
# Instalado por Salvamento.instala_autosave(pai, estado, batalha).
const Cfg := preload("res://scripts/cfg.gd")
const Salvamento := preload("res://scripts/salvamento.gd")

var estado
var batalha
var ativo := true       # o menu principal pode desligar enquanto nao ha jogo em andamento
var _t := 0.0

func _process(delta: float) -> void:
	if not ativo:
		return
	_t += delta
	if _t >= Cfg.AUTOSAVE_SEGUNDOS:
		_t = 0.0
		Salvamento.salvar(estado, batalha)

func _notification(what: int) -> void:
	if not ativo or estado == null or batalha == null:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Salvamento.salvar(estado, batalha)
