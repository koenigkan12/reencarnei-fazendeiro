extends RefCounted
# Sistema PERSONAGEM: atributos, talentos, habilidades automaticas e todos os stats derivados
# (vida, ataque, defesa, critico, CP...). Le equipamento e comida atraves do Estado.
const Cfg := preload("res://scripts/cfg.gd")

var e                         # Estado (raiz)
var atributos := {}           # id -> nivel
var talentos := {}            # id -> rank
var hab_niveis := {}          # id da habilidade -> nivel (>= 1)
var hab_slots: Array = []     # ids na ordem de uso ("" = vazio)

func _init(estado) -> void:
	e = estado
	for a in Cfg.ATRIBUTOS:
		atributos[a["id"]] = 0
	for t in Cfg.TALENTOS:
		talentos[t["id"]] = 0
	for h in Cfg.HABILIDADES:
		hab_niveis[h["id"]] = 1
	hab_slots.resize(Cfg.SLOTS_HABILIDADE)
	hab_slots.fill("")
	hab_slots[0] = "golpe"

# ---------- talentos ----------
func talento(efeito: String) -> float:
	var s := 0.0
	for t in Cfg.TALENTOS:
		if t["efeito"] == efeito:
			s += talentos[t["id"]] * t["valor"]
	return s

func pontos_talento_gastos() -> int:
	var s := 0
	for t in Cfg.TALENTOS:
		s += talentos[t["id"]]
	return s

func pontos_talento() -> int:
	return (e.nivel - 1) - pontos_talento_gastos()

func pode_talento(i: int) -> bool:
	var t: Dictionary = Cfg.TALENTOS[i]
	if pontos_talento() <= 0 or talentos[t["id"]] >= t["max"]:
		return false
	return t["req"] == "" or talentos[t["req"]] > 0

func sobe_talento(i: int) -> void:
	if pode_talento(i):
		talentos[Cfg.TALENTOS[i]["id"]] += 1
		e.notifica()

func custo_reset_talentos() -> int:
	return floori(Cfg.RESET_TALENTOS_CUSTO * e.nivel)

func reseta_talentos() -> bool:
	if pontos_talento_gastos() == 0 or e.ouro < custo_reset_talentos():
		return false
	e.ouro -= custo_reset_talentos()
	for t in Cfg.TALENTOS:
		talentos[t["id"]] = 0
	e.notifica()
	return true

# ---------- stats ----------
func _soma_itens(itens: Array, campo: String) -> float:
	var s := 0.0
	for it in itens:
		if it != null:
			s += it[campo] * (1.0 + Cfg.MAIS_BONUS * it["mais"])
	return s

func _atr(id: String) -> int:
	return atributos[id]

func _bonus(id: String) -> float:
	for a in Cfg.ATRIBUTOS:
		if a["id"] == id:
			return a["bonus"]
	return 0.0

func _vida_com(itens: Array) -> float:
	var base: float = Cfg.HEROI_VIDA + Cfg.HEROI_VIDA_POR_NIVEL * (e.nivel - 1) + _atr("vida") * _bonus("vida") + _soma_itens(itens, "vida")
	return base * (1.0 + e.comida.buff("vida") + talento("vida_pct"))

func _ataque_com(itens: Array) -> float:
	var base: float = Cfg.HEROI_DANO + Cfg.HEROI_DANO_POR_NIVEL * (e.nivel - 1) + _atr("ataque") * _bonus("ataque") + _soma_itens(itens, "dano")
	return base * (1.0 + e.comida.buff("dano") + talento("dano_pct"))

func vida_max() -> float:
	return _vida_com(e.equipamento.equipado)

func ataque() -> float:
	return _ataque_com(e.equipamento.equipado)

func defesa() -> float:
	return _atr("defesa") * _bonus("defesa") * (1.0 + talento("defesa_pct"))

func reducao_dano() -> float:    # multiplicador do dano recebido
	return Cfg.DEFESA_CONSTANTE / (Cfg.DEFESA_CONSTANTE + defesa())

func crit_chance() -> float:
	return minf(Cfg.HEROI_CRIT + _atr("critico") * _bonus("critico") + talento("crit"), 0.8)

func crit_mult() -> float:
	return Cfg.HEROI_CRIT_MULT + _atr("dano_critico") * _bonus("dano_critico") + talento("crit_mult")

func intervalo() -> float:
	return Cfg.HEROI_INTERVALO / (1.0 + _atr("vel_ataque") * _bonus("vel_ataque"))

func regen_pct() -> float:
	return Cfg.HEROI_REGEN_PCT + _atr("recuperacao") * _bonus("recuperacao") + talento("regen") + e.comida.buff("regen")

func cp_com(itens: Array) -> int:
	var dps := _ataque_com(itens) / intervalo() * (1.0 + crit_chance() * (crit_mult() - 1.0))
	return floori(_vida_com(itens) / Cfg.CP_VIDA_DIV + dps * Cfg.CP_DANO_MULT + defesa() * Cfg.CP_DEFESA_MULT)

func cp() -> int:
	return cp_com(e.equipamento.equipado)

# ---------- atributos (compra) ----------
func custo_atributo(i: int) -> int:
	var a: Dictionary = Cfg.ATRIBUTOS[i]
	return floori(a["custo_base"] * pow(a["crescimento"], atributos[a["id"]]))

func atributo_no_maximo(i: int) -> bool:
	var a: Dictionary = Cfg.ATRIBUTOS[i]
	return a["max"] > 0 and atributos[a["id"]] >= a["max"]

func compra_atributo(i: int) -> bool:
	if atributo_no_maximo(i):
		return false
	var c := custo_atributo(i)
	if e.ouro < c:
		return false
	e.ouro -= c
	atributos[Cfg.ATRIBUTOS[i]["id"]] += 1
	e.notifica()
	return true

# ---------- habilidades ----------
func habilidade_liberada(i: int) -> bool:
	return e.nivel >= Cfg.HABILIDADES[i]["nivel"]

func fator_habilidade(id: String) -> float:
	return 1.0 + Cfg.HABILIDADE_BONUS_POR_NIVEL * (hab_niveis[id] - 1)

func custo_habilidade(i: int) -> int:
	return floori(Cfg.HABILIDADE_CUSTO_BASE * pow(Cfg.HABILIDADE_CUSTO_CRESC, hab_niveis[Cfg.HABILIDADES[i]["id"]] - 1))

func sobe_habilidade(i: int) -> bool:
	var c := custo_habilidade(i)
	if not habilidade_liberada(i) or e.ouro < c:
		return false
	e.ouro -= c
	hab_niveis[Cfg.HABILIDADES[i]["id"]] += 1
	e.notifica()
	return true

func define_slot_habilidade(slot: int, id: String) -> void:
	if id != "":
		for k in hab_slots.size():
			if hab_slots[k] == id:
				hab_slots[k] = ""     # uma habilidade so pode estar em um slot
	hab_slots[slot] = id
	e.notifica()

func equipa_habilidades_novas() -> void:
	for h in Cfg.HABILIDADES:
		if e.nivel == h["nivel"] and not hab_slots.has(h["id"]):
			var livre := hab_slots.find("")
			if livre != -1:
				hab_slots[livre] = h["id"]

func habilidade_por_id(id: String) -> Dictionary:
	for h in Cfg.HABILIDADES:
		if h["id"] == id:
			return h
	return {}
