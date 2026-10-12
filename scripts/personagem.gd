extends RefCounted
# Sistema PERSONAGEM: atributos, talentos, habilidades automaticas e todos os stats derivados
# (vida, ataque, defesa, critico, CP...). Le equipamento e comida atraves do Estado.
const Cfg := preload("res://scripts/cfg.gd")

var e                         # Estado (raiz)
var atributos := {}           # id -> nivel
var talentos := {}            # id -> rank
var hab_niveis := {}          # id da habilidade -> nivel (>= 1)
var hab_slots: Array = []     # ids na ordem de uso ("" = vazio)
var _talento_da_skill := {}   # id da habilidade -> id do talento que a libera

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
	for t in Cfg.TALENTOS:
		if t["efeito"] == "skill":
			_talento_da_skill[t["skill"]] = t["id"]

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
		var t: Dictionary = Cfg.TALENTOS[i]
		talentos[t["id"]] += 1
		if t["efeito"] == "skill":
			_equipa_se_houver_vaga(t["skill"])
		e.notifica()

func custo_reset_talentos() -> int:
	return floori(Cfg.RESET_TALENTOS_CUSTO * e.nivel)

func reseta_talentos() -> bool:
	if pontos_talento_gastos() == 0 or e.ouro < custo_reset_talentos():
		return false
	e.ouro -= custo_reset_talentos()
	for t in Cfg.TALENTOS:
		talentos[t["id"]] = 0
	for k in hab_slots.size():
		if hab_slots[k] != "" and not habilidade_liberada_id(hab_slots[k]):
			hab_slots[k] = ""
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
	return Cfg.HEROI_INTERVALO / (1.0 + _atr("vel_ataque") * _bonus("vel_ataque") + talento("vel_pct"))

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
# Uma habilidade esta liberada se e a inicial ou se o talento que a libera tem ponto
func habilidade_liberada_id(id: String) -> bool:
	var h := habilidade_por_id(id)
	if h.is_empty():
		return false
	return h.get("inicial", false) or (_talento_da_skill.has(id) and talentos[_talento_da_skill[id]] > 0)

func habilidade_liberada(i: int) -> bool:
	return habilidade_liberada_id(Cfg.HABILIDADES[i]["id"])

func fator_habilidade(id: String) -> float:
	return 1.0 + Cfg.HABILIDADE_BONUS_POR_NIVEL * (hab_niveis[id] - 1)

# multiplicador final do dano das habilidades: talentos de skill_pct e afinidade da arma com o estilo da habilidade
func dano_habilidade_mult(h: Dictionary) -> float:
	return (1.0 + talento("skill_pct")) * afinidade(h["estilo"])

# multiplicador da recarga das habilidades (talento "recarga_pct", no minimo 40% da recarga)
func recarga_mult() -> float:
	return maxf(1.0 - talento("recarga_pct"), 0.4)

# arma do mesmo estilo da habilidade = AFINIDADE_CERTA; outra arma ou sem arma = AFINIDADE_ERRADA
func afinidade(estilo: String) -> float:
	var arma = e.equipamento.equipado[0]
	if arma != null and Cfg.TIPOS_ARMA[arma["tipo"]]["estilo"] == estilo:
		return Cfg.AFINIDADE_CERTA
	return Cfg.AFINIDADE_ERRADA

# estilo dominante entre as habilidades equipadas ("" se nao ha nenhuma): e o que o jogador "e"
func estilo_dominante() -> String:
	var cont := {}
	for id in hab_slots:
		if id != "":
			var est: String = habilidade_por_id(id)["estilo"]
			cont[est] = cont.get(est, 0) + 1
	var melhor := ""
	for est in cont:
		if melhor == "" or cont[est] > cont[melhor]:
			melhor = est
	return melhor

func nome_estilo() -> String:
	var est := estilo_dominante()
	if est == "":
		return "Sem estilo"
	var arma = e.equipamento.equipado[0]
	var combina: bool = arma != null and Cfg.TIPOS_ARMA[arma["tipo"]]["estilo"] == est
	return "%s%s" % [Cfg.ESTILOS[est]["nome"], " (arma combina)" if combina else " (arma não combina)"]

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

func _equipa_se_houver_vaga(id: String) -> void:
	if not hab_slots.has(id):
		var livre := hab_slots.find("")
		if livre != -1:
			hab_slots[livre] = id

# Compatibilidade com estado.gd: as habilidades agora sao liberadas pelos talentos (ver sobe_talento)
func equipa_habilidades_novas() -> void:
	pass

func habilidade_por_id(id: String) -> Dictionary:
	for h in Cfg.HABILIDADES:
		if h["id"] == id:
			return h
	return {}

# ---------- salvar ----------
func para_dict() -> Dictionary:
	return {"atributos": atributos.duplicate(), "talentos": talentos.duplicate(), "hab_niveis": hab_niveis.duplicate(), "hab_slots": hab_slots.duplicate()}

func de_dict(d: Dictionary) -> void:
	for k in d.get("atributos", {}):
		if atributos.has(k):
			atributos[k] = int(d["atributos"][k])
	for k in d.get("talentos", {}):
		if talentos.has(k):
			talentos[k] = int(d["talentos"][k])
	for k in d.get("hab_niveis", {}):
		if hab_niveis.has(k):
			hab_niveis[k] = int(d["hab_niveis"][k])
	var slots: Array = d.get("hab_slots", [])
	for k in mini(slots.size(), hab_slots.size()):
		hab_slots[k] = slots[k] if habilidade_liberada_id(slots[k]) else ""
