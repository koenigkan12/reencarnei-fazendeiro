extends Control
# Menu de pausa (Esc): Continuar, Salvar, Opcoes, Rever tutorial, Menu principal, Sair.
const MenuUtil := preload("res://scripts/menu_util.gd")

signal continuar
signal salvar
signal opcoes
signal tutorial
signal menu
signal sair

var pode_salvar := false
var _bt_menu: Button
var _bt_salvar: Button
var _confirma_menu := false

func configura(salva_disponivel: bool) -> void:
	pode_salvar = salva_disponivel

func _ready() -> void:
	add_child(MenuUtil.fundo(Color(0, 0, 0, 0.7)))
	var col := MenuUtil.coluna(self, 12)
	col.add_child(MenuUtil.titulo("Pausa", 44))
	var bt_cont := MenuUtil.botao("Continuar")
	bt_cont.pressed.connect(func(): continuar.emit())
	col.add_child(bt_cont)
	if pode_salvar:
		_bt_salvar = MenuUtil.botao("Salvar agora")
		_bt_salvar.pressed.connect(_clicou_salvar)
		col.add_child(_bt_salvar)
	var bt_op := MenuUtil.botao("Opções")
	bt_op.pressed.connect(func(): opcoes.emit())
	col.add_child(bt_op)
	var bt_tut := MenuUtil.botao("Rever tutorial")
	bt_tut.pressed.connect(func(): tutorial.emit())
	col.add_child(bt_tut)
	_bt_menu = MenuUtil.botao("Menu principal")
	_bt_menu.pressed.connect(_clicou_menu)
	col.add_child(_bt_menu)
	var bt_sair := MenuUtil.botao("Sair do jogo")
	bt_sair.pressed.connect(func(): sair.emit())
	col.add_child(bt_sair)
	bt_cont.grab_focus()

func _clicou_salvar() -> void:
	salvar.emit()
	_bt_salvar.text = "Salvo!"

# Sem save disponivel, voltar ao menu perde o progresso: pede um segundo clique
func _clicou_menu() -> void:
	if not pode_salvar and not _confirma_menu:
		_confirma_menu = true
		_bt_menu.text = "Sem save: o progresso se perde. Clique de novo"
		return
	menu.emit()
