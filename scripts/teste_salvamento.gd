extends SceneTree
# Teste de ida e volta do salvamento e do ganho offline (sem janela):
#   godot --headless --path . --script res://scripts/teste_salvamento.gd
# Imprime "[teste-save] ..." por checagem e termina com codigo 0 (tudo certo) ou 1 (alguma falha).
const Cfg := preload("res://scripts/cfg.gd")
const Estado := preload("res://scripts/estado.gd")
const Batalha := preload("res://scripts/batalha.gd")
const Salvamento := preload("res://scripts/salvamento.gd")

var _falhas := 0

func _checa(nome: String, ok: bool) -> void:
	print("[teste-save] %s: %s" % ["ok" if ok else "FALHOU", nome])
	if not ok:
		_falhas += 1

func _initialize() -> void:
	Salvamento.apagar()
	var e1 := Estado.new()
	var b1 := Batalha.new()
	b1.estado = e1
	root.add_child(b1)
	await process_frame
	# deixa o jogo num estado "diferente do inicial" em todos os sistemas
	e1.ouro = 1234.5
	e1.nivel = 7
	e1.xp = 3.0
	e1.minerio = 5
	var atr: String = Cfg.ATRIBUTOS[0]["id"]
	var tal: String = Cfg.TALENTOS[0]["id"]
	e1.personagem.atributos[atr] = 4
	e1.personagem.talentos[tal] = 1
	e1.personagem.hab_niveis["golpe"] = 3
	e1.equipamento.equipado[0] = e1.equipamento.gera_item(3, true)
	e1.equipamento.equipado[0]["mais"] = 2
	e1.equipamento.mochila.append(e1.equipamento.gera_item(5, false))
	e1.fazenda.terreno[0] = {"t": 1, "cultura": 1, "prog": 12.0, "agua": 1.0}
	e1.fazenda.sementes[2] = 9
	e1.fazenda.colheita[0] = 6
	e1.fazenda.cultivo_nivel = 3
	e1.fazenda.ferramentas["regador"] = 2
	e1.fazenda.irrigacao = 1
	e1.comida.pratos[1] = 4
	e1.comida.slots_comida[0] = {"prato": 2, "restante": 33.0}
	e1.comida.slots_comida[1] = {"prato": -1, "restante": 0.0}     # slots vazios: o offline nao gasta o estoque de pratos
	e1.comida.slots_comida[2] = {"prato": -1, "restante": 0.0}
	b1.fase = 12
	b1.abates = 4
	b1.derrotas = 2
	Salvamento.taxa_ouro = 2.0
	Salvamento.taxa_xp = 1.0
	_checa("salvar grava o arquivo", Salvamento.salvar(e1, b1) and Salvamento.existe_save())
	# finge que o jogo ficou 2 horas fechado
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Cfg.SAVE_ARQUIVO))
	d["ts"] = Time.get_unix_time_from_system() - 7200.0
	var f := FileAccess.open(Cfg.SAVE_ARQUIVO, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()

	var e2 := Estado.new()
	var b2 := Batalha.new()
	b2.estado = e2
	root.add_child(b2)
	await process_frame
	var r: Dictionary = Salvamento.carregar(e2, b2)
	_checa("carregar devolve resultado", r.has("offline"))
	_checa("nivel e minerio", e2.nivel >= 7 and e2.minerio == 5)
	_checa("atributo e talento", e2.personagem.atributos[atr] == 4 and e2.personagem.talentos[tal] == 1)
	_checa("nivel da habilidade", e2.personagem.hab_niveis["golpe"] == 3)
	_checa("arma equipada com +2", e2.equipamento.equipado[0] != null and e2.equipamento.equipado[0]["mais"] == 2)
	_checa("mochila", e2.equipamento.mochila.size() == 1 and typeof(e2.equipamento.mochila[0]["fase"]) == TYPE_INT)
	_checa("lote plantado", e2.fazenda.terreno[0]["cultura"] == 1 and e2.fazenda.terreno[0]["t"] == 1)
	_checa("sementes e colheita", e2.fazenda.sementes[2] == 9 and e2.fazenda.colheita[0] == 6)
	_checa("cultivo e ferramentas", e2.fazenda.cultivo_nivel == 3 and e2.fazenda.ferramentas["regador"] == 2 and e2.fazenda.irrigacao == 1)
	_checa("pratos", e2.comida.pratos[1] == 4)
	_checa("fase da batalha", b2.fase == 12 and b2.abates == 4 and b2.derrotas == 2)
	var resumo: Dictionary = r.get("offline", {})
	_checa("resumo offline existe", not resumo.is_empty())
	_checa("ganho offline de ouro (~7200)", e2.ouro > 1234.5 + 3000.0 and float(resumo.get("ouro", 0.0)) > 3000.0)
	_checa("lote regado ficou pronto", e2.fazenda.lote_pronto(0, 0))
	# save corrompido: o principal estraga, o .bak (copia anterior) salva
	Salvamento.salvar(e2, b2)     # copia o principal para .bak e grava o novo
	var g := FileAccess.open(Cfg.SAVE_ARQUIVO, FileAccess.WRITE)
	g.store_string("{ isto nao e json")
	g.close()
	var e3 := Estado.new()
	var b3 := Batalha.new()
	b3.estado = e3
	root.add_child(b3)
	await process_frame
	_checa("save corrompido: carrega do .bak", Salvamento.carregar(e3, b3).has("offline") and e3.nivel >= 7)
	Salvamento.apagar()
	print("[teste-save] %s" % ("TUDO CERTO" if _falhas == 0 else "%d FALHA(S)" % _falhas))
	quit(0 if _falhas == 0 else 1)
