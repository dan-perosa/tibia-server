# Pendências do servidor

Lista viva do que falta fazer. Atualizada por sessão, mais recente no topo. Se você (Daniel)
implementar algo daqui, é só remover o item e registrar no `CHANGELOG.md`.

---

## Pendências de 2026-08-25

**Pra reconferir ao vivo** (já corrigidos ontem, só falta confirmar em jogo — ver `CHANGELOG.md`
2026-08-25 pra detalhes de cada bug):
- Barra de skill não sobe (bug de escala de percentual corrigido em vários arquivos do client)
- Personagem persegue monstro sozinho mesmo com "modo perseguição" desmarcado (bug de ordem de
  execução corrigido em `game_inventory/inventory.lua` — mas o fix só corrige a exibição, pode
  sobrar comportamento real de perseguição num modo que ficou "ligado" de sessão anterior)
- Popup de "você subiu de skill" com nome errado (`infobanner.lua` — IDs de skill corrigidos pra
  bater com o enum real do protocolo)

**Balanceamento:**
- Reduzir o número de rotworms no início da hunt
- Espalhar bichos mais fracos ao redor dos pontos de teleporte (ex: larva perto da hunt de
  scarab) — transição suave de dificuldade
- Rate de level muito devagar nos levels baixos (distinto da rate de skill/ML, essa é XP pra
  level)
- Acelerar a velocidade de consumo das exercise weapons — talvez atrelar a alguma quest ou marco
  importante em vez de ser sempre rápido (`data/scripts/actions/items/exercise_training_weapons.lua`,
  `RATE_EXERCISE_TRAINING_SPEED`/multiplicador "fast-exercise")
- Reduzir o escalonamento de dano por skill — personagens causando dano alto cedo demais em
  relação ao level, enquanto upar level continua lento (mesmo desbalanceamento do item acima,
  visto junto). É o bônus `√(skill_ou_ML/10)` central em `Player:onCombat`
  (`data/events/scripts/player.lua`) — os expoentes/âncoras de lá são os botões certos pra
  recalibrar pra baixo.

**Decisão de escopo pendente (perguntar pro Pedro antes de mexer):**
- NPC de bless (`data-otservbr-global/npc/test_server.lua`) dá dinheiro e experiência de graça
  junto com outros cheats de debug (level X, reset, promoção, skill máximo). Pedro quer tirar
  dinheiro/experiência — não ficou definido se é só isso ou se o NPC inteiro devia virar GM-only.

## Pendências de 2026-08-24

- **Nova viagem do barco (Sebastian Farwind): ilha de lava, "mega hunt de Dragon Lord".** Acesso
  vai exigir o item **dragon claw** (dropado pelo **Demodras**,
  `monster/quests/killing_in_the_name_of/demodras.lua`, 4.500 HP, 100% de drop). Plano: colocar o
  Demodras na hunt de Dragon Lord ao norte do DP, num espaço secreto — cogitada uma **pick**
  (picareta) pra abrir caminho (parede quebrável). Nada construído ainda; usar
  `sebastian_farwind.lua` (`MIRROR_ISLAND_DESTINATION`/lógica de chave já existente) como padrão.

- **As 3 arenas de desafio (Demon Goblin, dragon/Stalking Stalk, gelo/Furious Yeti), quando
  completadas pelo mesmo jogador, liberam uma NOVA área/desafio via NPC na mesma região.** Ideia
  de conteúdo: boss com rotação diária/semanal, recompensa variando por dificuldade e/ou contador
  acumulado de quantas vezes o jogador já matou aquele boss. Gate de progressão pra conteúdo
  novo, não só uma sala de prêmio.

- **Ao redor da terceira arena (gelo)**: preencher com gelo/decorações, esconder um
  buraco/passagem descendo até uma hunt de Frost Dragon (`monster/dragons/frost_dragon.lua`,
  1.800 HP — bem mais fraco que os bosses das arenas, é hunt de farm/nível mais baixo).

## Pendências de 2026-08-23

- **Sala de recompensas por número de arenas completadas.** Reaproveitar as storages de
  conclusão que cada baú já grava por jogador, contar quantas arenas completou, liberar prêmios
  em faixas (2 arenas = bronze, 4 = prata, etc). Só compensa se houver mais arenas no futuro.
  Ideia complementar: exigir X arenas completadas como requisito pra uma ilha/quest nova.

- **Loot Pouch + Seal of Quality** (sistema oficial do Tibia). Loot Pouch recebe drops
  automaticamente (limite de itens/tempo, não ilimitado); Seal of Quality vende tudo da pouch de
  uma vez a cada 1 minuto pelo preço de NPC, gold direto na conta. Ainda não checado se o
  Canary/OTServBR-Global já tem isso pronto no datapack ou se precisa implementar do zero —
  checar isso primeiro.

## Pendências de 2026-08-22

- **Destino do Castaway Corwin após "libertado"** — em aberto de propósito, Pedro decide no
  futuro.
- **Captain Windrift sem destino real** — viagens desativadas (fala genérica) porque as
  coordenadas originais eram do mundo oficial. Falta construir cidades customizadas de destino e
  reativar `addTravelKeyword` em `captain_windrift.lua`.
- **Cledwyn — loja com token especial (item 22516, silver token) sem fonte no servidor.** Não
  bloqueia nada agora — Pedro vai criar um hub de bosses que dropa esse token no futuro.

## Referência (não é pendência)

- Hunt de Nightmare nível baixo no mapa oficial do Tibia (`{x=33616, y=31571, z=8}`), marcada em
  2026-08-22 pra talvez copiar pro mapa custom (mesmo esquema usado pra Mirror Island).
