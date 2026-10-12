extends RefCounted
# Sistema COMIDA: cada cultura vira um prato; 3 slots do heroi consomem sozinhos o proximo
# prato do estoque quando o efeito acaba. Os efeitos entram nos stats via buff() (ver personagem.gd).
const Cfg := preload("res://scripts/cfg.gd")

var e                         # Estado (raiz)

func _init(estado) -> void:
	e = estado

var pratos: Array = [0, 0, 0]                 # estoque de cada prato
var slots_comida: Array = [                   # prato -1 = vazio
	{"prato": 0, "restante": 0.0}, {"prato": 1, "restante": 0.0}, {"prato": 2, "restante": 0.0}]

# soma dos efeitos ativos de um tipo ("regen", "vida", "dano")
func buff(efeito: String) -> float:
	var s := 0.0
	for sl in slots_comida:
		if sl["prato"] != -1 and sl["restante"] > 0.0:
			var p: Dictionary = Cfg.PRATOS[sl["prato"]]
			if p["efeito"] == efeito:
				s += p["valor"]
	return s

func cozinha(prato: int) -> bool:
	if e.fazenda.colheita[prato] < Cfg.COZINHA_CUSTO:
		return false
	e.fazenda.colheita[prato] -= Cfg.COZINHA_CUSTO
	pratos[prato] += 1
	e.notifica()
	return true

func define_slot_comida(i: int, prato: int) -> void:
	slots_comida[i]["prato"] = prato
	e.notifica()

# Consome sozinho a proxima unidade do estoque quando o efeito do slot acaba
func tick(delta: float) -> void:
	var mudaram := false
	for sl in slots_comida:
		if sl["prato"] == -1:
			continue
		if sl["restante"] > 0.0:
			sl["restante"] = maxf(sl["restante"] - delta, 0.0)
			if sl["restante"] <= 0.0:
				mudaram = true
		if sl["restante"] <= 0.0 and pratos[sl["prato"]] > 0:
			pratos[sl["prato"]] -= 1
			sl["restante"] = Cfg.PRATOS[sl["prato"]]["duracao"]
			mudaram = true
	if mudaram:
		e.notifica()

# ---------- Salvar ----------
func para_dict() -> Dictionary:
	return {"pratos": pratos.duplicate(), "slots": slots_comida.duplicate(true)}

func de_dict(d: Dictionary) -> void:
	var p: Array = d.get("pratos", [])
	for i in mini(p.size(), pratos.size()):
		pratos[i] = int(p[i])
	var sl: Array = d.get("slots", [])
	for i in mini(sl.size(), slots_comida.size()):
		var src: Dictionary = sl[i]
		var prato := int(src.get("prato", -1))
		slots_comida[i] = {"prato": prato if prato < Cfg.PRATOS.size() else -1, "restante": float(src.get("restante", 0.0))}
	e.notifica()

# nomes alternativos usados pelo fluxo/menus
func para_dicionario() -> Dictionary:
	return para_dict()

func de_dicionario(d: Dictionary) -> void:
	de_dict(d)
