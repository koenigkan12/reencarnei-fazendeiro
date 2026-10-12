extends Control
# Mapa da fazenda: grade de lotes desenhada por codigo (placeholder ate a arte final).
# Clique (ou arraste) aplica a ferramenta selecionada.
const Cfg := preload("res://scripts/cfg.gd")
const Arte := preload("res://scripts/arte.gd")

var estado
var ferramenta := "mao"
var _hover := Vector2i(-1, -1)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

func _tam() -> float:
	return minf(size.x / Cfg.COLUNAS, size.y / Cfg.LINHAS)

func _origem() -> Vector2:
	var t := _tam()
	return Vector2((size.x - t * Cfg.COLUNAS) / 2.0, (size.y - t * Cfg.LINHAS) / 2.0)

func _lote_em(pos: Vector2) -> Vector2i:
	var p := (pos - _origem()) / _tam()
	return Vector2i(floori(p.x), floori(p.y))

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var l := _lote_em(ev.position)
		if ev.button_mask & MOUSE_BUTTON_MASK_LEFT and l != _hover:
			_aplica(l)
		_hover = l
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		_hover = _lote_em(ev.position)
		_aplica(_hover)

func _aplica(l: Vector2i) -> void:
	if l.x >= 0 and l.y >= 0 and l.x < Cfg.COLUNAS and l.y < Cfg.LINHAS:
		estado.fazenda.usa_ferramenta(ferramenta, l.x, l.y)

func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()

func _draw() -> void:
	if estado == null:
		return
	var t := _tam()
	var o := _origem()
	var fonte := ThemeDB.fallback_font
	for y in Cfg.LINHAS:
		for x in Cfg.COLUNAS:
			var r := Rect2(o + Vector2(x, y) * t, Vector2(t, t))
			if not estado.fazenda.lote_aberto(x, y):
				draw_rect(r, Color(0.18, 0.2, 0.18))
				draw_rect(r, Color(0, 0, 0, 0.35), false, 1.0)
				continue
			var l: Dictionary = estado.fazenda.lote(x, y)
			var t_grama := Arte.tex("Tiles/Grass_Middle.png")
			var t_terra := Arte.tex("Tiles/FarmLand_Tile.png")
			var decor := Arte.tex(Arte.DECOR)
			if t_grama != null:
				draw_texture_rect(t_grama, r, false)
			else:
				draw_rect(r, Color(0.34, 0.58, 0.27) if (x + y) % 2 == 0 else Color(0.31, 0.54, 0.25))
			if l["t"] == 1:
				var molhada: bool = l["agua"] > 0.0
				if t_terra != null:
					draw_texture_rect_region(t_terra, r, Rect2(16, 16, 16, 16), Color(0.7, 0.6, 0.55) if molhada else Color.WHITE)
				else:
					draw_rect(r.grow(-2), Color(0.30, 0.19, 0.11) if molhada else Color(0.5, 0.35, 0.2))
			elif l["t"] == 2:
				if decor != null:
					var rc: Array = Arte.ROCHAS[(x * 7 + y * 3) % Arte.ROCHAS.size()]
					draw_texture_rect_region(decor, r, Arte.decor_regiao(rc[0], rc[1]))
				else:
					draw_rect(Rect2(r.position + Vector2(t, t) * 0.15, Vector2(t, t) * 0.7), Color(0.55, 0.55, 0.58))
			if l["cultura"] != -1:
				var cul: Dictionary = Cfg.CULTURAS[l["cultura"]]
				var p := clampf(l["prog"] / cul["tempo"], 0.0, 1.0)
				if decor != null:
					var est: Array = Arte.CULTURA_ESTAGIOS[l["cultura"]]
					var st: Array = est[0] if p < 0.34 else (est[1] if p < 1.0 else est[2])
					var tom := Color.WHITE if l["cultura"] != 2 else (Color(1.0, 0.6, 0.3) if p >= 1.0 else Color(0.9, 1.0, 0.8))
					draw_texture_rect_region(decor, r, Arte.decor_regiao(st[0], st[1]), tom)
				else:
					var lado := t * (0.2 + 0.5 * p)
					var c: Color = cul["cor"]
					if p < 1.0:
						c = c.lerp(Color(0.3, 0.7, 0.3), 1.0 - p)
					draw_rect(Rect2(r.position + (Vector2(t, t) - Vector2(lado, lado)) / 2.0, Vector2(lado, lado)), c)
				if p >= 1.0:
					draw_rect(r.grow(-1), Color(1, 1, 1, 0.9), false, 2.0)
				elif l["agua"] <= 0.0:
					draw_circle(r.position + Vector2(t * 0.82, t * 0.2), t * 0.1, Color(0.3, 0.6, 1.0))
			draw_rect(r, Color(0, 0, 0, 0.18), false, 1.0)
	# destaque da area da ferramenta
	if estado.fazenda.lote_aberto(_hover.x, _hover.y):
		var raio := 0
		if estado.fazenda.ferramentas.has(ferramenta):
			raio = estado.fazenda.ferramentas[ferramenta] - 1
		var ra := Rect2(o + Vector2(_hover.x - raio, _hover.y - raio) * t, Vector2(t, t) * (2 * raio + 1))
		draw_rect(ra, Color(1, 1, 1, 0.9), false, 2.0)