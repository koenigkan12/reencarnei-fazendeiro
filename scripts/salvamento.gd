extends RefCounted
# Salvamento e ganho offline. Tudo estatico: Salvamento.salvar(estado, batalha), Salvamento.carregar(estado, batalha),
# Salvamento.existe_save(), Salvamento.apagar() e Salvamento.mostra_resumo(pai, resumo).
# O menu/fluxo usa os atalhos em estado.gd: existe_save(), salva(), carrega(), apaga_save(). O arquivo e um JSON em Cfg.SAVE_ARQUIVO.
# O que cada sistema guarda esta em para_dict()/de_dict() do proprio sistema.
const Cfg := preload("res://scripts/cfg.gd")
const TelaOffline := preload("res://scripts/tela_offline.gd")

# Taxa de ouro e XP de combate por segundo (antes dos bonus), medida em janela deslizante e guardada no save
static var taxa_ouro := 0.0
static var taxa_xp := 0.0
static var _amostras: Array = []

static func existe_save() -> bool:
	return FileAccess.file_exists(Cfg.SAVE_ARQUIVO) or FileAccess.file_exists(Cfg.SAVE_ARQUIVO + ".bak")

static func apagar() -> void:
	for sufixo in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(Cfg.SAVE_ARQUIVO + sufixo):
			DirAccess.remove_absolute(Cfg.SAVE_ARQUIVO + sufixo)

# Mede a taxa de ganho de combate usando as ultimas amostras (uma por chamada de salvar)
static func _atualiza_taxa(estado) -> void:
	var agora: float = Time.get_ticks_msec() / 1000.0
	_amostras.append([agora, float(estado.ganho_ouro_total), float(estado.ganho_xp_total)])
	while _amostras.size() > 12:
		_amostras.pop_front()
	var primeira: Array = _amostras[0]
	var ultima: Array = _amostras[_amostras.size() - 1]
	var dt: float = ultima[0] - primeira[0]
	if dt >= 20.0:
		taxa_ouro = maxf((ultima[1] - primeira[1]) / dt, 0.0)
		taxa_xp = maxf((ultima[2] - primeira[2]) / dt, 0.0)

# Grava o jogo. Devolve true se gravou. Escreve num .tmp e troca, guardando a copia anterior em .bak.
static func salvar(estado, batalha) -> bool:
	_atualiza_taxa(estado)
	var dados := {
		"versao": Cfg.SAVE_VERSAO,
		"ts": Time.get_unix_time_from_system(),
		"ouro": estado.ouro, "nivel": estado.nivel, "xp": estado.xp, "minerio": estado.minerio,
		"taxa_ouro": taxa_ouro, "taxa_xp": taxa_xp,
		"personagem": estado.personagem.para_dict(),
		"equipamento": estado.equipamento.para_dict(),
		"fazenda": estado.fazenda.para_dict(),
		"comida": estado.comida.para_dict(),
		"batalha": {"fase": batalha.fase, "abates": batalha.abates, "derrotas": batalha.derrotas, "vitoria_final": batalha.vitoria_final, "endgame": batalha.endgame},
	}
	var tmp: String = Cfg.SAVE_ARQUIVO + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(dados, "\t"))
	f.close()
	if FileAccess.file_exists(Cfg.SAVE_ARQUIVO):
		DirAccess.copy_absolute(Cfg.SAVE_ARQUIVO, Cfg.SAVE_ARQUIVO + ".bak")
	return DirAccess.rename_absolute(tmp, Cfg.SAVE_ARQUIVO) == OK

static func _le(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var texto := FileAccess.get_file_as_string(caminho)
	var r = JSON.parse_string(texto)
	if typeof(r) == TYPE_DICTIONARY:
		return r
	return {}

# Carrega o save (ou a copia .bak se o principal estiver corrompido). Chame depois que a batalha estiver na arvore.
# Devolve {} se nao ha save; senao {"offline": resumo} (resumo vazio se a ausencia foi curta).
static func carregar(estado, batalha) -> Dictionary:
	var d := _le(Cfg.SAVE_ARQUIVO)
	if d.is_empty():
		d = _le(Cfg.SAVE_ARQUIVO + ".bak")
	if d.is_empty():
		return {}
	estado.ouro = float(d.get("ouro", 0.0))
	estado.nivel = maxi(int(d.get("nivel", 1)), 1)
	estado.xp = float(d.get("xp", 0.0))
	estado.minerio = int(d.get("minerio", 0))
	estado.personagem.de_dict(d.get("personagem", {}))
	estado.equipamento.de_dict(d.get("equipamento", {}))
	estado.fazenda.de_dict(d.get("fazenda", {}))
	estado.comida.de_dict(d.get("comida", {}))
	_restaura_batalha(batalha, d.get("batalha", {}))
	taxa_ouro = float(d.get("taxa_ouro", 0.0))
	taxa_xp = float(d.get("taxa_xp", 0.0))
	_amostras.clear()
	estado.notifica()
	var resumo := {}
	var fora: float = Time.get_unix_time_from_system() - float(d.get("ts", Time.get_unix_time_from_system()))
	if fora >= Cfg.OFFLINE_MIN_SEGUNDOS:
		resumo = aplica_offline(estado, fora)
	return {"offline": resumo}

static func _restaura_batalha(batalha, b: Dictionary) -> void:
	batalha.fase = clampi(int(b.get("fase", 1)), 1, Cfg.FASES_TOTAL)
	batalha.abates = clampi(int(b.get("abates", 0)), 0, Cfg.INIMIGOS_POR_FASE)
	batalha.derrotas = int(b.get("derrotas", 0))
	batalha.vitoria_final = bool(b.get("vitoria_final", false))
	batalha.endgame = bool(b.get("endgame", false))
	batalha.contra_chefe = false
	batalha.descanso = 0.0
	batalha._fundo.color = Color(0.22, 0.16, 0.28) if batalha.fase >= Cfg.ZONA2_A_PARTIR_DA_FASE else Color(0.16, 0.22, 0.28)
	batalha._painel_derrota.visible = false
	batalha._barra_chefe.visible = false
	batalha.heroi.revive()
	batalha.heroi.vivo = true
	batalha._novo_inimigo()
	batalha._sincroniza()
	batalha.heroi.vida = batalha.heroi.vida_max
	batalha.heroi.atualiza_barra()
	if batalha.vitoria_final:
		batalha._painel_derrota.visible = true
		batalha._texto_derrota.text = "Vitória! Você derrotou o chefe da fase %d.\n(Fim da zona 2. Continue fortalecendo o herói!)" % batalha.fase
	elif batalha.abates >= Cfg.INIMIGOS_POR_FASE and batalha._tipo_chefe_da_fase() != "":
		batalha._inicia_chefe()     # o save foi feito na luta contra o chefe: recomeca o chefe

# ---------- ganho offline ----------
static func _conta_prontas(estado) -> int:
	var n := 0
	for y in Cfg.LINHAS:
		for x in estado.fazenda.colunas_abertas():
			if estado.fazenda.lote_pronto(x, y):
				n += 1
	return n

static func _conta_pratos(estado) -> int:
	var n := 0
	for p in estado.comida.pratos:
		n += int(p)
	return n

# Aplica o que aconteceu enquanto o jogo estava fechado: ouro/XP de combate (taxa medida x eficiencia, limite de horas),
# a fazenda crescendo (plantas regadas ficam prontas) e a comida sendo consumida. Devolve o resumo para a tela.
static func aplica_offline(estado, segundos: float) -> Dictionary:
	var contados: float = minf(segundos, Cfg.OFFLINE_HORAS_MAX * 3600.0)
	var ouro_antes: float = estado.ouro
	var nivel_antes: int = estado.nivel
	var prontas_antes := _conta_prontas(estado)
	var pratos_antes := _conta_pratos(estado)
	var total_ouro: float = estado.ganho_ouro_total
	var total_xp: float = estado.ganho_xp_total
	estado.ganha(taxa_ouro * contados * Cfg.OFFLINE_EFICIENCIA, taxa_xp * contados * Cfg.OFFLINE_EFICIENCIA)
	estado.ganho_ouro_total = total_ouro      # ganho offline nao entra na medida da taxa
	estado.ganho_xp_total = total_xp
	var resta := contados
	while resta > 0.0:
		var dt: float = minf(5.0, resta)
		estado.fazenda.tick(dt)
		estado.comida.tick(dt)
		resta -= dt
	estado.notifica()
	return {"segundos": segundos, "contados": contados, "limitado": segundos > contados,
		"ouro": estado.ouro - ouro_antes, "nivel_antes": nivel_antes, "nivel_depois": estado.nivel,
		"prontas": maxi(_conta_prontas(estado) - prontas_antes, 0), "pratos_gastos": maxi(pratos_antes - _conta_pratos(estado), 0),
		"eficiencia": Cfg.OFFLINE_EFICIENCIA}

# ---------- ligacao com a interface ----------
# Mostra a tela "Bem-vindo de volta" por cima de pai (nao faz nada se o resumo for vazio)
static func mostra_resumo(pai: Control, resumo: Dictionary) -> void:
	if resumo.is_empty():
		return
	var t := TelaOffline.new()
	t.resumo = resumo
	pai.add_child(t)
