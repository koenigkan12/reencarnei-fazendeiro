extends RefCounted
# Raiz do estado do jogo: o que e comum a todos os sistemas (ouro, nivel, XP, minerio) e as
# referencias para cada sistema. Cada sistema vive no seu script (ver ARQUIVOS.md).
const Cfg := preload("res://scripts/cfg.gd")
const Personagem := preload("res://scripts/personagem.gd")
const Equipamento := preload("res://scripts/equipamento.gd")
const Fazenda := preload("res://scripts/fazenda.gd")
const Loja := preload("res://scripts/loja.gd")
const Comida := preload("res://scripts/comida.gd")
const Salvamento := preload("res://scripts/salvamento.gd")

signal mudou               # qualquer numero mudou (no maximo uma vez por quadro; a UI so le)
signal item_dropou(info)   # info: {item, equipou, ouro}
signal voltou_offline(resumo)   # carrega() aplicou ganho offline; main.gd mostra a tela de resumo

var ouro := 0.0
var nivel := 1
var xp := 0.0
var minerio := 0
var ganho_ouro_total := 0.0   # soma do ouro/XP vindo do combate (antes dos bonus); salvamento.gd mede a taxa do ganho offline
var ganho_xp_total := 0.0

var personagem
var equipamento
var fazenda
var loja
var comida
var batalha                   # registrada por main.gd (estado.batalha = batalha); o save precisa da fase

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
	ganho_ouro_total += ouro_ganho
	ganho_xp_total += xp_ganho
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

# ---------- salvar / carregar (usados pelo fluxo dos menus; ver salvamento.gd) ----------
func existe_save() -> bool:
	return Salvamento.existe_save()

func salva() -> bool:
	return batalha != null and Salvamento.salvar(self, batalha)

# Carrega o save no estado atual; devolve false se nao ha save. Se houve ganho offline, emite voltou_offline.
func carrega() -> bool:
	if batalha == null:
		return false
	var r: Dictionary = Salvamento.carregar(self, batalha)
	if r.is_empty():
		return false
	var resumo: Dictionary = r.get("offline", {})
	if not resumo.is_empty():
		voltou_offline.emit(resumo)
	return true

func apaga_save() -> void:
	Salvamento.apagar()

# Desfaz as referencias circulares (subsistema <-> estado) ao fechar o jogo
func libera() -> void:
	personagem.e = null
	equipamento.e = null
	fazenda.e = null
	loja.e = null
	comida.e = null
	batalha = null
