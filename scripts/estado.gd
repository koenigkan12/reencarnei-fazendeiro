extends RefCounted
# Raiz do estado do jogo: o que e comum a todos os sistemas (ouro, nivel, XP, minerio) e as
# referencias para cada sistema. Cada sistema vive no seu script (ver ARQUIVOS.md).
const Cfg := preload("res://scripts/cfg.gd")
const Personagem := preload("res://scripts/personagem.gd")
const Equipamento := preload("res://scripts/equipamento.gd")
const Fazenda := preload("res://scripts/fazenda.gd")
const Loja := preload("res://scripts/loja.gd")
const Comida := preload("res://scripts/comida.gd")

signal mudou               # qualquer numero mudou (no maximo uma vez por quadro; a UI so le)
signal item_dropou(info)   # info: {item, equipou, ouro}

var ouro := 0.0
var nivel := 1
var xp := 0.0
var minerio := 0

var personagem
var equipamento
var fazenda
var loja
var comida

var _sujo := false

func _init() -> void:
	personagem = Personagem.new(self)
	equipamento = Equipamento.new(self)
	fazenda = Fazenda.new(self)
	loja = Loja.new(self)
	comida = Comida.new(self)

# Qualquer sistema chama isto ao mudar algo; a UI atualiza uma vez por quadro (em tick)
func notifica() -> void:
	_sujo = true

func xp_para_subir() -> float:
	return Cfg.XP_BASE * pow(Cfg.XP_CRESCIMENTO, nivel - 1)

# devolve true se subiu de nivel
func ganha(ouro_ganho: float, xp_ganho: float) -> bool:
	ouro += ouro_ganho * (1.0 + personagem.talento("ouro_pct"))
	xp += xp_ganho * (1.0 + personagem.talento("xp_pct"))
	var subiu := false
	while xp >= xp_para_subir():
		xp -= xp_para_subir()
		nivel += 1
		subiu = true
		personagem.equipa_habilidades_novas()
	notifica()
	return subiu

# Chamado todo quadro por main.gd (fazenda e comida andam com qualquer aba aberta)
func tick(delta: float) -> void:
	fazenda.tick(delta)
	comida.tick(delta)
	if _sujo:
		_sujo = false
		mudou.emit()

# Desfaz as referencias circulares (subsistema <-> estado) ao fechar o jogo
func libera() -> void:
	personagem.e = null
	equipamento.e = null
	fazenda.e = null
	loja.e = null
	comida.e = null
