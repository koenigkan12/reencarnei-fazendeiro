extends RefCounted
# Sistema LOJA: compra de sementes e melhorias de ferramentas e irrigacao (ouro). Altera o estado da fazenda.
const Cfg := preload("res://scripts/cfg.gd")

var e                         # Estado (raiz)

func _init(estado) -> void:
	e = estado

func compra_semente(cultura: int, qtd: int) -> bool:
	var custo: float = Cfg.CULTURAS[cultura]["semente"] * qtd
	if not e.fazenda.cultura_liberada(cultura) or e.ouro < custo:
		return false
	e.ouro -= custo
	e.fazenda.sementes[cultura] += qtd
	e.notifica()
	return true

func custo_ferramenta(id: String) -> int:
	var nv: int = e.fazenda.ferramentas[id]
	for f in Cfg.FERRAMENTAS:
		if f["id"] == id and nv - 1 < f["custos"].size():
			return floori(f["custos"][nv - 1])
	return -1    # no maximo

func melhora_ferramenta(id: String) -> bool:
	var c := custo_ferramenta(id)
	if c < 0 or e.ouro < c:
		return false
	e.ouro -= c
	e.fazenda.ferramentas[id] += 1
	e.notifica()
	return true

func custo_irrigacao() -> int:
	return floori(Cfg.IRRIGACAO_CUSTOS[e.fazenda.irrigacao]) if e.fazenda.irrigacao < Cfg.IRRIGACAO_CUSTOS.size() else -1

func melhora_irrigacao() -> bool:
	var c := custo_irrigacao()
	if c < 0 or e.ouro < c:
		return false
	e.ouro -= c
	e.fazenda.irrigacao += 1
	e.notifica()
	return true

# Valor total da colheita em estoque e venda de tudo de uma vez (aba Loja)
func valor_colheita() -> int:
	var v := 0.0
	for i in Cfg.CULTURAS.size():
		v += e.fazenda.colheita[i] * Cfg.CULTURAS[i]["preco"]
	return floori(v)

func vende_tudo() -> void:
	for i in Cfg.CULTURAS.size():
		e.fazenda.vende_colheita(i)
