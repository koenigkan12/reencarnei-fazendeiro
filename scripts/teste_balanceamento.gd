extends SceneTree
# Simulador de balanceamento SEM janela e mais rapido que o tempo real: roda a batalha e a fazenda passo a passo
# com um jogador automatico (mesma logica do bot de main.gd) e imprime o ritmo da v1 e todas as derrotas.
#   godot --headless --path . --script res://scripts/teste_balanceamento.gd -- --seeds=5 --bot-intervalo=5 --max-min=120
# --seeds=N        quantas partidas (cada uma com semente fixa 1..N, resultado reproduzivel)
# --bot-intervalo  segundos de jogo entre uma jogada do bot e a proxima (5 = jogador perfeito; 30 = mais humano)
# --max-min        limite de minutos de jogo por partida
# Linhas: "[bal] fase F ..." (quando entra em cada fase), "[bal] DERROTA ..." (causa e numeros) e "[bal] resumo ...".
const Cfg := preload("res://scripts/cfg.gd")
const Estado := preload("res://scripts/estado.gd")
const Batalha := preload("res://scripts/batalha.gd")

const PASSO := 0.1

var e
var b

func _arg(nome: String, padrao: float) -> float:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + nome + "="):
			return float(a.substr(nome.length() + 3))
	return padrao

func _initialize() -> void:
	var seeds := int(_arg("seeds", 3.0))
	var intervalo: float = _arg("bot-intervalo", 5.0)
	var max_min: float = _arg("max-min", 120.0)
	var tempos: Array = []
	var derrotas_por_fase := {}
	var venceu := 0
	for s in range(1, seeds + 1):
		seed(s)
		var r: Dictionary = await _partida(s, intervalo, max_min)
		if r["venceu"]:
			venceu += 1
			tempos.append(r["minutos"])
		for fase in r["derrotas"]:
			derrotas_por_fase[fase] = derrotas_por_fase.get(fase, 0) + 1
	tempos.sort()
	print("[bal] resumo: %d/%d partidas chegaram ao fim. minutos para vencer: %s" % [venceu, seeds, str(tempos)])
	print("[bal] derrotas por fase (somando as partidas): %s" % str(derrotas_por_fase))
	quit(0)

func _partida(numero: int, intervalo: float, max_min: float) -> Dictionary:
	e = Estado.new()
	b = Batalha.new()
	b.estado = e
	e.batalha = b
	root.add_child(b)
	await process_frame
	b.set_process(false)      # quem anda o tempo aqui e este script
	var t := 0.0
	var prox_bot := 0.0
	var fase_vista := 0
	var derrotas_fases: Array = []
	var resultado := {"venceu": false, "minutos": 0.0, "derrotas": derrotas_fases}
	var ultimo_yield := 0.0
	while t < max_min * 60.0:
		if t >= prox_bot:
			_bot()
			prox_bot += intervalo
		if b.fase != fase_vista:
			fase_vista = b.fase
			print("[bal] #%d min %.1f: fase %d  nivel %d  CP %d  derrotas %d" % [numero, t / 60.0, b.fase, e.nivel, e.personagem.cp(), b.derrotas])
		var derrotas_antes: int = b.derrotas
		var era_chefe: bool = b.contra_chefe
		var tempo_chefe_antes: float = b.tempo_chefe
		b._process(PASSO)
		e.tick(PASSO)
		if b.derrotas > derrotas_antes:
			var causa := "tempo esgotado" if (era_chefe and tempo_chefe_antes - PASSO <= 0.0) else "o heroi caiu"
			derrotas_fases.append(b.fase)
			print("[bal] #%d min %.1f: DERROTA na fase %d%s (%s). heroi: vida %d ataque %d intervalo %.2f CP %d | inimigo: vida %d dano %d intervalo %.2f" % [
				numero, t / 60.0, b.fase, " (chefe)" if era_chefe else "", causa, b.heroi.vida_max, b.heroi.dano, b.heroi.intervalo,
				e.personagem.cp(), b.inimigo.vida_max, b.inimigo.dano, b.inimigo.intervalo])
		if b.vitoria_final:
			resultado["venceu"] = true
			resultado["minutos"] = snappedf(t / 60.0, 0.1)
			print("[bal] #%d VITORIA em %.1f min de jogo, %d derrotas, nivel %d, CP %d" % [numero, t / 60.0, b.derrotas, e.nivel, e.personagem.cp()])
			break
		t += PASSO
		# deixa os tweens visuais andarem de vez em quando para nao acumular nos
		if t - ultimo_yield >= 30.0:
			ultimo_yield = t
			await process_frame
	if not resultado["venceu"]:
		print("[bal] #%d NAO TERMINOU em %.0f min: fase %d, derrotas %d, CP %d" % [numero, max_min, b.fase, b.derrotas, e.personagem.cp()])
	b.queue_free()
	e.libera()
	await process_frame
	return resultado

# Mesma logica do _bot() de main.gd (fazenda, loja, atributos, talentos, habilidades e +N)
func _bot() -> void:
	if e.fazenda.sementes[0] < 6:
		e.loja.compra_semente(0, 5)
	for c in [2, 1, 0]:
		if e.fazenda.cultura_liberada(c) and e.fazenda.sementes[c] > 0:
			e.fazenda.semente_selecionada = c
			break
	for y in Cfg.LINHAS:
		for x in e.fazenda.colunas_abertas():
			for f in ["mao", "picareta", "enxada", "semente", "regador"]:
				e.fazenda.usa_ferramenta(f, x, y)
	for c in 3:
		e.comida.cozinha(c)
		e.fazenda.vende_colheita(c)
	for f in Cfg.FERRAMENTAS:
		e.loja.melhora_ferramenta(f["id"])
	e.loja.melhora_irrigacao()
	for i in 40:
		if e.personagem.pontos_talento() > 0:
			for t in Cfg.TALENTOS.size():
				e.personagem.sobe_talento(t)
		var barato := 0
		for u in Cfg.ATRIBUTOS.size():
			if not e.personagem.atributo_no_maximo(u) and e.personagem.custo_atributo(u) < e.personagem.custo_atributo(barato):
				barato = u
		if not e.personagem.compra_atributo(barato):
			break
	for h in Cfg.HABILIDADES.size():
		e.personagem.sobe_habilidade(h)
	for s in 3:
		if e.equipamento.equipado[s] != null:
			e.equipamento.melhora_item(s)
