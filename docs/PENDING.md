# Pendências do servidor

Lista viva do que falta fazer. Atualizada por sessão, mais recente no topo. Se você (Daniel)
implementar algo daqui, é só remover o item e registrar no `CHANGELOG.md`.

---

## Pendências de 2026-08-26 (PRIORIDADE — provavelmente precisa de C++, não só Lua)

- **Personagem gruda no monstro durante o ataque, mesmo com "modo perseguição" desmarcado na
  tela — com qualquer arma, inclusive distância (ex: snakebite rod, alcance 3, mas o personagem
  vai até alcance 1 mesmo assim).** Já acontecia antes de 25/08, não é regressão de nada mexido
  aqui. Investigação completa em `CHANGELOG.md` 2026-08-26 — resumo: confirmado com um comando de
  debug (`!checkchase`) que o servidor tem `followCreature` ativo durante o ataque mesmo com a
  tela mostrando desligado. Eliminado como causa: constantes do client, lógica do botão de
  toggle, lógica C++ do servidor (`Player::setChaseMode`/`setAttackedCreature`, ambos corretos),
  e nenhum script Lua do datapack mexendo nisso por fora do sistema normal. Suspeita: bug no
  binário compilado do OTClient (client-side, C++), fora do alcance de uma correção só em Lua —
  precisa instrumentar/recompilar o client pra ver o pacote de rede real saindo da máquina do
  jogador.
- **Barra de skill não sobe visualmente, mesmo depois de duas tentativas de correção.**
  Diagnóstico corrigido em 26/08 (à noite) — não é um bug de arredondamento nem de sinal de
  evento faltando: o progresso real (usado pelo servidor pra decidir o level-up) avança rápido e
  correto o tempo todo; é a **exibição no client** que fica presa num percentual pequeno/velho
  ("99% faltando") durante quase todo o percurso e só corrige o número certo bem no momento do
  level-up (por isso completa "em 2 hits" pra quem está olhando a tela, mesmo já tendo avançado
  bastante por trás). Polling (reler o valor com mais frequência) não resolve, porque o valor
  cacheado no client já está congelado — o defeito deve estar em como o binário compilado do
  OTClient processa certos pacotes de atualização em tempo real. Mesma classe de problema do item
  do chase mode acima — ver `CHANGELOG.md` 2026-08-26 pro histórico completo das duas tentativas.

## Pendências de 2026-08-25

**Balanceamento** (ajustado em 26/08, ver `CHANGELOG.md` — ainda não testado com jogo real
depois do ajuste, pode precisar de mais uma volta):
- Rate de XP 1-100: 6x → 12x (`data/stages.lua`)
- Expoente de dano por skill: 0,3 → 0,15 (`Player:onCombat`, `data/events/scripts/player.lua`)
- Rotworms no início da hunt: reduzidos pelo próprio Pedro direto no mapa

- Acelerar a velocidade de consumo das exercise weapons — talvez atrelar a alguma quest ou marco
  importante em vez de ser sempre rápido (`data/scripts/actions/items/exercise_training_weapons.lua`,
  `RATE_EXERCISE_TRAINING_SPEED`/multiplicador "fast-exercise")

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
