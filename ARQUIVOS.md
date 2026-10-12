# Mapa dos arquivos (Reencarnei Fazendeiro)

Godot 4.7, GDScript. A interface e montada por codigo (sem .tscn escrito a mao). Todos os numeros
de balanceamento ficam em `scripts/cfg.gd`. Cada sistema tem um script proprio; os sistemas falam
entre si pelo `Estado` (variavel `e` dentro de cada sistema).

## Sistemas (logica, sem UI)
| Script | Sistema |
|---|---|
| `scripts/cfg.gd` | Todas as constantes e tabelas (atributos, talentos, habilidades, inimigos, itens, culturas...). |
| `scripts/estado.gd` | Raiz: ouro, nivel, XP, minerio, sinal `mudou`, `tick(delta)` e as referencias `personagem`, `equipamento`, `fazenda`, `loja`, `comida`. |
| `scripts/personagem.gd` | Atributos, talentos, habilidades automaticas e todos os stats derivados (vida, ataque, defesa, critico, CP). |
| `scripts/equipamento.gd` | 3 espacos, drops com raridade, auto-equipar/vender, melhoria +N (ouro + minerio). |
| `scripts/fazenda.gd` | Terreno, ferramentas, sementes, crescimento (regado), colheita, rochas, Cultivo. |
| `scripts/loja.gd` | Compras: sementes, ferramentas, irrigacao. |
| `scripts/comida.gd` | Pratos, estoque, 3 slots do heroi, buffs. |

## Batalha e interface
| Script | O que e |
|---|---|
| `scripts/batalha.gd` | Area de batalha: heroi vs inimigos, chefes, derrota/descanso, HUD, habilidades automaticas. |
| `scripts/arte.gd` | Carrega a arte do pack (assets/cute_fantasy/, fora do git), monta animacoes e recortes; sem a pasta, tudo cai nos placeholders coloridos. |
| `scripts/unidade.gd` | Combatente (retangulo colorido + barra de vida), placeholder da arte. |
| `scripts/main.gd` | Raiz da UI: tela de cima (batalha/fazenda), painel de abas, teste headless (`-- --teste-batalha`). |
| `scripts/aba_personagem.gd` | Aba Personagem (atributos, habilidades, talentos). |
| `scripts/aba_equipamento.gd` | Aba Equipamento. |
| `scripts/aba_fazenda.gd` | Aba Fazenda (semente do plantio, vender, cozinha, slots de comida). |
| `scripts/aba_loja.gd` | Aba Loja. |
| `scripts/fazenda_tela.gd` | Tela de cima da fazenda: barra de ferramentas + mapa. |
| `scripts/mapa_fazenda.gd` | Desenho e cliques do terreno. |

## Convencoes
- Chamar sistemas pelo estado: `estado.personagem.vida_max()`, `estado.fazenda.usa_ferramenta(...)`.
- Depois de mudar algo, o sistema chama `e.notifica()`; a UI le no sinal `estado.mudou` (1x por quadro).
- `assets/` fica fora do git (pack de arte com licenca propria).
- Testar: `godot --headless --path . --quit-after 99999 -- --teste-batalha` (bot joga 30 min simulados).
