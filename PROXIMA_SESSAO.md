# Onde paramos (12/10/2026) e o que fica para a proxima sessao

## Estado
A v1 completa roda no Godot (`project.godot`, F5): menu principal, tutorial, batalha com arte do Cute Fantasy (gratis), personagem (atributos, talentos, skills automaticas), equipamento com mochila e +N, fazenda estilo Stardew (mapa, ferramentas, regar, colher, rochas), loja, comida, salvamento com ganho offline, pausa, opcoes e tela de fim. Sons e musicas provisorios sinteticos. Jogada completa menu -> fim passa em `--teste-fluxo`. Mapa dos arquivos: `ARQUIVOS.md`.

## Para a proxima sessao
1. **Balanceamento pelo feedback do Vncs**: ele ainda nao jogou a versao integrada. Referencia: rodada C (15 inimigos por fase, chefes 4,8x/10,5x): vence em ~13 a 18 min simulados; ver `testes/balanceamento/` na branch `balanceamento-baseline`.
2. **Ouvir o audio**: nunca foi ouvido por quem escreveu (so por codigo). Ajustar volumes/timbres em `tools/gera_audio.py` pelo ouvido do Vncs.
3. **Arte dos inimigos que faltam**: goblin, orc, lobo e ogro usam esqueleto/slime tingidos (`scripts/arte.gd`). Packs em avaliacao na conversa "Escolha da arte do jogo". Antes de qualquer demo publica ou da Steam, trocar o pack gratis pelo Premium (licenca gratis nao permite uso comercial). `assets/` fica fora do git.
4. **.exe so no fim**: o Vncs dispensou por enquanto. Exigiria baixar os modelos de exportacao 4.7.2 do Godot (~1 GB) com autorizacao dele.
5. **Limpeza do historico git**: o pack gratis (`Cute_Fantasy_Free/`) entrou por engano no commit `44823a4` e continua no historico do repositorio privado. Remover exige reescrever o historico com force push, **ainda sem autorizacao do Vncs**.
6. Menores: teste_salvamento e bot dependem das APIs atuais; `godot-mcp` nao instalado (so afeta as skills godot-interactive/godot-live-edit, nao copiadas).
