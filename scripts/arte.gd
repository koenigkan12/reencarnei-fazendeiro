extends RefCounted
# Carrega a arte do pack Cute Fantasy (assets/cute_fantasy/, fora do git). Se a pasta nao existir,
# tudo devolve null e o jogo cai nos placeholders coloridos. Pastas e nomes estaveis: o pack gratis
# sera trocado pelo Premium antes de qualquer demo publica.
const BASE := "res://assets/cute_fantasy/"

static var _tex: Dictionary = {}
static var _frames: Dictionary = {}

static func tex(rel: String) -> Texture2D:
	if _tex.has(rel):
		return _tex[rel]
	var t: Texture2D = null
	if ResourceLoader.exists(BASE + rel):
		t = load(BASE + rel)
	_tex[rel] = t
	return t

# anims: {nome: [linha, quantidade, fps, loop]}
static func _sheet(rel: String, fw: int, fh: int, anims: Dictionary) -> SpriteFrames:
	var t := tex(rel)
	if t == null:
		return null
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for nome in anims.keys():
		var a: Array = anims[nome]
		sf.add_animation(nome)
		sf.set_animation_speed(nome, a[2])
		sf.set_animation_loop(nome, a[3])
		for c in a[1]:
			var at := AtlasTexture.new()
			at.atlas = t
			at.region = Rect2(c * fw, a[0] * fh, fw, fh)
			sf.add_frame(nome, at)
	return sf

# Cada "arte" e um Dictionary: {frames, escala, pe (px da base do quadro ate os pes), tint, flip}
static func heroi() -> Dictionary:
	if not _frames.has("heroi"):
		var sf := _sheet("Player/Player.png", 32, 32, {
			"idle": [1, 6, 8.0, true], "ataque": [7, 4, 14.0, false], "morte": [9, 4, 6.0, false]})
		_frames["heroi"] = {} if sf == null else {"frames": sf, "escala": 5.0, "pe": 3.0, "tint": Color.WHITE, "flip": false}
	return _frames["heroi"]

static func esqueleto(tint: Color = Color.WHITE, escala: float = 5.0) -> Dictionary:
	if not _frames.has("esqueleto"):
		_frames["esqueleto"] = _sheet("Enemies/Skeleton.png", 32, 32, {
			"idle": [1, 6, 8.0, true], "morte": [6, 4, 8.0, false]})
	if _frames["esqueleto"] == null:
		return {}
	return {"frames": _frames["esqueleto"], "escala": escala, "pe": 3.0, "tint": tint, "flip": false}

static func slime(tint: Color = Color.WHITE, escala: float = 3.5) -> Dictionary:
	if not _frames.has("slime"):
		_frames["slime"] = _sheet("Enemies/Slime_Green.png", 64, 64, {
			"idle": [0, 4, 6.0, true], "ataque": [1, 8, 14.0, false], "morte": [2, 8, 14.0, false]})
	if _frames["slime"] == null:
		return {}
	return {"frames": _frames["slime"], "escala": escala, "pe": 22.0, "tint": tint, "flip": false}

# Arte de cada inimigo/chefe pelo nome (os que nao tem arte propria reaproveitam slime/esqueleto tingidos)
static func inimigo(nome: String) -> Dictionary:
	match nome:
		"Slime": return slime()
		"Goblin": return esqueleto(Color(0.6, 1.0, 0.5), 4.5)
		"Orc": return esqueleto(Color(1.0, 0.55, 0.5), 5.5)
		"Lobo": return slime(Color(0.7, 0.75, 0.9), 3.5)
		"Esqueleto": return esqueleto()
		"Ogro": return slime(Color(0.8, 0.6, 0.35), 5.5)
		"Mini Boss": return esqueleto(Color(0.8, 0.45, 0.95), 7.0)
		"BOSS": return esqueleto(Color(1.0, 0.3, 0.3), 9.0)
	return {}

# ---- fazenda: recortes de Outdoor_Decor_Free.png (grade de 16 px) e tiles ----
const DECOR := "Outdoor decoration/Outdoor_Decor_Free.png"

static func decor_regiao(coluna: int, linha: int) -> Rect2:
	return Rect2(coluna * 16, linha * 16, 16, 16)

# [coluna, linha] por estagio de cada cultura (sem arte propria de Abobora: usa o broto verde tingido)
const CULTURA_ESTAGIOS := [
	[[5, 1], [5, 2], [6, 2]],    # Trigo
	[[3, 1], [3, 2], [4, 2]],    # Cenoura
	[[4, 1], [6, 1], [6, 1]],    # Abobora
]
const ROCHAS := [[0, 3], [1, 3], [2, 3]]
