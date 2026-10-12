# Mapa dos arquivos (Reencarnei Fazendeiro)

Godot 4.7, GDScript. A interface e montada por codigo (sem .tscn escrito a mao). Todos os numeros
de balanceamento ficam em `scripts/cfg.gd`. Cada sistema tem um script proprio; os sistemas falam
entre si pelo `Estado` (variavel `e` dentro de cada sistema).

## Sistemas (logica, sem UI)
| Script | Sistema |
|---|---|
| `scripts/cfg.gd` | Todas as constantes e tabelas (atributos, talentos, habilidades, inimigos, itens, culturas...). |
| `scripts/estado.gd` | Raiz: ouro, nivel, XP, minerio, sinal `mudou`, `tick(delta)` e as referencias `personagem`, `equipamento`, `fazenda`, `loja`, `comida`. |
| `scripts/personagem.gd` | Atributos, talentos (liberam habilidades), habilidades equipadas, estilo, afinidade arma/habilidade e todos os stats derivados (vida, ataque, defesa, critico, CP). |
| `scripts/skills.gd` | Habilidades automaticas na luta: recarga, ordem esquerda->direita, dano, buffs e efeitos visuais por codigo. |
| `scripts/equipamento.gd` | 3 espacos, tipos de arma, mochila (24), drops com raridade, equipar/vender, auto-equipar opcional, melhoria +N (ouro + minerio). |
| `scripts/fazenda.gd` | Terreno, ferramentas, sementes, crescimento (regado), colheita, rochas, Cultivo. |
| `scripts/loja.gd` | Compras: sementes, ferramentas, irrigacao. |
| `scripts/comida.gd` | Pratos, estoque, 3 slots do heroi, buffs. |
| `scripts/salvamento.gd` | Salvar/carregar tudo (JSON em user://save.json, com .bak), ganho offline e ligacoes com a interface. |
| `scripts/autosave.gd` | No que salva a cada 30 s, ao fechar a janela e ao perder o foco. |
| `scripts/tela_offline.gd` | Tela "Bem-vindo de volta" com o resumo do ganho offline. |

## Batalha e interface
| Script | O que e |
|---|---|
| `scripts/batalha.gd` | Area de batalha: heroi vs inimigos, chefes, derrota/descanso, HUD, habilidades automaticas. |
| `scripts/arte.gd` | Carrega a arte do pack (assets/cute_fantasy/, fora do git), monta animacoes e recortes; sem a pasta, tudo cai nos placeholders coloridos. |
| `scripts/unidade.gd` | Combatente (retangulo colorido + barra de vida), placeholder da arte. |
| `scripts/main.gd` | Raiz da UI: tela de cima (batalha/fazenda), painel de abas, teste headless (`-- --teste-batalha`). |
| `scripts/aba_personagem.gd` | Aba Personagem (atributos, habilidades, talentos). |
| `scripts/aba_equipamento.gd` | Aba Equipamento (3 espacos, +N, mochila com Equipar/Vender). |
| `scripts/aba_fazenda.gd` | Aba Fazenda (semente do plantio, vender, cozinha, slots de comida). |
| `scripts/aba_loja.gd` | Aba Loja. |
| `scripts/fazenda_tela.gd` | Tela de cima da fazenda: barra de ferramentas + mapa. |
| `scripts/mapa_fazenda.gd` | Desenho e cliques do terreno. |
| `scripts/fluxo.gd` | Fluxo do jogo (camada por cima de tudo): menu principal, pausa com Esc, opcoes, tutorial de primeira vez e tela de fim da v1. Pausa a arvore enquanto uma tela esta aberta; nao age em `--teste-batalha` nem `--captura`. |
| `scripts/menu_principal.gd`, `menu_pausa.gd`, `tela_opcoes.gd`, `tutorial.gd`, `tela_fim.gd` | As telas do fluxo. Textos do tutorial, resolucoes e nomes de audio ficam em `cfg.gd`. |
| `scripts/opcoes.gd` | Opcoes do jogador em `user://opcoes.cfg` (volumes, tela cheia, resolucao, tutorial visto, tempo jogado). |
| `scripts/audio.gd` | Gancho de audio: toca `res://assets/audio/<nome>.ogg/.mp3/.wav` se existir (`Audio.toca_musica`, `Audio.toca_efeito`); nomes em `Cfg.AUDIO_NOMES`. |
| `scripts/menu_util.gd` | Pecas de UI dos menus. |

## Ganchos do fluxo
- **Save:** o fluxo chama em `main.estado`, se existirem: `existe_save() -> bool`, `salva() -> bool`, `carrega() -> bool`, `apaga_save()`. Sem eles, "Continuar" fica desabilitado. Autosave a cada `Cfg.AUTOSAVE_SEGUNDOS`. `personagem` e `equipamento` tem `para_dicionario()`/`de_dicionario(d)` como a fazenda.
- **Audio:** colocar os arquivos em `assets/audio/` com os nomes de `Cfg.AUDIO_NOMES`.
- **Fim da v1:** o fluxo detecta `batalha.vitoria_final`; "Continuar jogando" chama `batalha.continua_apos_vitoria()`.

## Convencoes
- Chamar sistemas pelo estado: `estado.personagem.vida_max()`, `estado.fazenda.usa_ferramenta(...)`.
- Depois de mudar algo, o sistema chama `e.notifica()`; a UI le no sinal `estado.mudou` (1x por quadro).
- `assets/` fica fora do git (pack de arte com licenca propria).
- Testar: `godot --headless --path . --quit-after 99999 -- --teste-batalha` (bot joga 30 min simulados).

## Salvamento (para o menu principal / main.gd)
- `Salvamento.existe_save() -> bool`, `Salvamento.apagar()` (novo jogo).
- `Salvamento.salvar(estado, batalha) -> bool`. Cada sistema guarda o seu em `para_dict()` / `de_dict(d)`.
- `Salvamento.carregar(estado, batalha) -> Dictionary`: chame DEPOIS que a batalha estiver na arvore (`_ready` feito). Devolve `{}` se nao ha save; senao `{"offline": resumo}` (ja aplicado ao estado).
- `Salvamento.mostra_resumo(pai, resumo)`: abre a tela de ganho offline por cima de `pai` (nao faz nada se `resumo` for vazio).
- `Salvamento.instala_autosave(pai, estado, batalha) -> Node`: instala o autosave; o no tem `ativo` (false enquanto nao ha jogo em andamento).
- Ganho offline: taxa de ouro/XP medida em janela deslizante, `OFFLINE_EFICIENCIA` (50%) e limite `OFFLINE_HORAS_MAX` (8 h) em `cfg.gd`; a fazenda e a comida avancam o tempo todo.
- Teste: `godot --headless --path . --script res://scripts/teste_salvamento.gd` (codigo de saida 0 = tudo certo).
