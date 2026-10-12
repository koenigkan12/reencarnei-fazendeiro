extends Control
# Menu principal: Novo jogo, Continuar, Opcoes, Sair.
const Cfg := preload("res://scripts/cfg.gd")
const MenuUtil := preload("res://scripts/menu_util.gd")

signal novo_jogo
signal continuar
signal opcoes
signal sair

var tem_save := false
var _bt_novo: Button
var _confirma_novo := false

func configura(com_save: bool) -> void:
	tem_save = com_save

func _ready() -> void:
	add_child(MenuUtil.fundo(Color(0.08, 0.1, 0.14)))
	var col := MenuUtil.coluna(self, 16)
	var t := MenuUtil.titulo(Cfg.TITULO_JOGO, 56)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	col.add_child(t)
	var f := MenuUtil.titulo(Cfg.FRASE_JOGO, 16)
	f.modulate = Color(1, 1, 1, 0.75)
	f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	f.custom_minimum_size = Vector2(620, 0)
	col.add_child(f)
	var esp := Control.new()
	esp.custom_minimum_size = Vector2(0, 24)
	col.add_child(esp)
	_bt_novo = MenuUtil.botao("Novo jogo")
	_bt_novo.pressed.connect(_clicou_novo)
	col.add_child(_bt_novo)
	var bt_cont := MenuUtil.botao("Continuar" if tem_save else "Continuar (sem save)")
	bt_cont.disabled = not tem_save
	bt_cont.pressed.connect(func(): continuar.emit())
	col.add_child(bt_cont)
	var bt_op := MenuUtil.botao("Opções")
	bt_op.pressed.connect(func(): opcoes.emit())
	col.add_child(bt_op)
	var bt_sair := MenuUtil.botao("Sair")
	bt_sair.pressed.connect(func(): sair.emit())
	col.add_child(bt_sair)
	var v := Label.new()
	v.text = Cfg.VERSAO_JOGO
	v.modulate = Color(1, 1, 1, 0.4)
	v.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	v.offset_left = 12
	v.offset_top = -30
	add_child(v)
	(bt_cont if tem_save else _bt_novo).grab_focus()

# Com save existente, Novo jogo pede um segundo clique (apaga o save)
func _clicou_novo() -> void:
	if tem_save and not _confirma_novo:
		_confirma_novo = true
		_bt_novo.text = "Apagar o save e começar? Clique de novo"
		return
	novo_jogo.emit()
