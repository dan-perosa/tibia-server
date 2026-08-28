# Pendências do servidor

Lista viva do que falta fazer. Atualizada por sessão, mais recente no topo. Se você (Daniel)
implementar algo daqui, é só remover o item e registrar no `CHANGELOG.md`.

---

## Pendências de 2026-08-28

- **Revisar os starter kits de cada vocação** (`data/scripts/actions/quests/custom_reward_chests.lua`,
  storage `starter_kit` — chests 24465-24468). Pedido do Daniel, sem detalhe ainda de o que
  exatamente revisar (itens, quantidades, balanceamento) -- perguntar antes de mexer.

## Pendências de 2026-08-26 (PRIORIDADE — plano de instrumentação pronto, ainda não executado)

Confirmado em 27/08: `dudantas/tibia-client` (repo pinado em `client/TIBIA_CLIENT_SOURCE.txt`)
não tem código-fonte nenhum — é só distribuição de assets/binário do client oficial fechado da
CipSoft. Não dá pra ler/corrigir o client diretamente. A camada de protocolo/parsing do servidor
(`parseFightModes`/`parseAttack` em `protocolgame.cpp`, e `Player::addSkillAdvance` +
`AddPlayerSkills` pro skill bar) já foi lida com cuidado e está correta.

**Plano de diagnóstico (chegou a ser implementado e testado em 27/28-08, depois revertido por ser
só instrumentação temporária, não um fix -- reaplicar quando alguém for reproduzir de verdade):**
adicionar `g_logger().debug(...)` em `parseFightModes`/`parseAttack`
(`src/server/network/protocol/protocolgame.cpp`) logando o valor de chaseMode recebido a cada
pacote, e em `Player::addSkillAdvance` (`src/creatures/players/player.cpp`) logando cada mudança
de percentual de skill. Precisa compilar com `-DDEBUG_LOG=ON` (flag do CMake, off por padrão --
não é o `logLevel` do `config.lua` sozinho) e rodar com `logLevel = "debug"`. Reproduzir os bugs e
grepar o log do servidor pela tag específica (ex: `[chase-debug]`) -- com debug ligado o log fica
MUITO verboso, não dá pra ler sem filtrar. Se o log mostrar o pacote/update chegando certo mesmo
com o bug acontecendo na tela, confirma que é 100% client-side, sem solução por código. Se mostrar
o servidor calado num momento que devia estar mandando update, aí tem algo a caçar no servidor.

- **Personagem gruda no monstro durante o ataque, mesmo com "modo perseguição" desmarcado na
  tela — com qualquer arma, inclusive distância (ex: snakebite rod, alcance 3, mas o personagem
  vai até alcance 1 mesmo assim).** Já acontecia antes de 25/08, não é regressão de nada mexido
  aqui. Investigação completa em `CHANGELOG.md` 2026-08-26 e 2026-08-27 — eliminado como causa:
  constantes do client, lógica do botão de toggle, lógica C++ do servidor
  (`Player::setChaseMode`/`setAttackedCreature`, confirmados corretos de novo em 27/08 -- limpa
  `followCreature` corretamente assim que recebe chaseMode false), e a camada de
  protocolo/parsing. Suspeita mais forte: chase mode viaja num pacote separado do de ataque
  (opcode `0xA0` vs `0xA1`), e o client pode não reenviar o pacote de "tactics" quando o jogador
  usa um toggle rápido durante o combate (só a caixa de diálogo completa reenviaria) -- ou reenvia
  com o valor errado. Ver plano de diagnóstico acima pra confirmar com dado real. Também dá pra
  cruzar com `!checkchase` (já existe em
  `data/scripts/talkactions/player/givemanapotions_debug.lua`).
- **Barra de skill não sobe visualmente, mesmo depois de duas tentativas de correção.**
  Diagnóstico corrigido em 26/08 (à noite): não é bug de arredondamento nem de sinal de evento
  faltando -- o progresso real avança certo o tempo todo, é a **exibição no client** que fica
  presa. Checado em 27/08, a fundo: toda a cadeia do servidor está correta, do cálculo
  (`Player::addSkillAdvance`) até a serialização de rede (`AddPlayerSkills` em `protocolgame.cpp`,
  manda o percentual com precisão total, sem arredondamento grosseiro). Ver plano de diagnóstico
  acima -- mesma abordagem, pra confirmar (não só suspeitar) que é renderização no client.

## Pendências de 2026-08-25

**Balanceamento** (ajustado em 26/08, ver `CHANGELOG.md` — ainda não testado com jogo real
depois do ajuste, pode precisar de mais uma volta):
- Rate de XP 1-100: 6x → 12x (`data/stages.lua`)
- Expoente de dano por skill: 0,3 → 0,15 (`Player:onCombat`, `data/events/scripts/player.lua`)
- Rotworms no início da hunt: reduzidos pelo próprio Pedro direto no mapa

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
  **Em progresso (26/08)**: primeiro buraco de acesso criado em (963,958,7) — usar pick ali
  teleporta pro andar de baixo (963,958,8), ver `onUsePick` em
  `data-otservbr-global/scripts/lib/register_actions.lua`. O andar de baixo ainda está vazio
  (só o chão), falta construir a hunt de verdade do Frost Dragon lá.

## Pendências de 2026-08-23

- **Sala de recompensas por número de arenas completadas.** Adiado de propósito (27/08): as
  storages de conclusão das 3 arenas existentes já foram achadas (chests 24701/24702/24703 ->
  storages 86701-86703, `BASE_STORAGE + actionId` em `custom_reward_chests.lua`), mas com só 3
  arenas uma sala em faixas (2=bronze, 4=prata) ainda não tem massa crítica. Retomar quando
  houver mais arenas. Ideia complementar: exigir X arenas completadas como requisito pra uma
  ilha/quest nova.

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
