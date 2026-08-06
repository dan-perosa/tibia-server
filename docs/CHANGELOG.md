# Changelog do servidor privado

Registro do que foi feito, por quê, e o que aprendemos no processo. Mantido
por sessão de trabalho, mais recente no topo.

---

## 2026-08-06

### Correção séria: liberação de magias tinha removido nível/vocação também
No dia anterior eu tinha adicionado a flag `ignorespellcheck="1"` no grupo
"player" achando que ela só pulava a exigência de comprar a magia do NPC.
**Errado**: essa flag é checada logo no topo de
`Spell::playerSpellCheck()` (`src/creatures/combat/spells.cpp`), então
qualquer jogador com ela conseguia lançar **qualquer magia, de qualquer
nível, de qualquer vocação** — inclusive magias de outras classes. Pedro
percebeu jogando de druida e conseguindo lançar magias de nível/classe
incompatíveis.

**Corrigido de verdade:** removida a flag de `groups.xml`. Em vez disso,
`data-otservbr-global/scripts/creaturescripts/others/login.lua` agora
"ensina" automaticamente pro jogador, no login, toda magia da vocação dele
(via `player:learnInstantSpell()`, extraído programaticamente de
`spell:name()`/`spell:vocation()` em todo `data/scripts/spells/`). Isso
remove só a exigência de pagar o NPC — nível, mana e vocação continuam
sendo checados normalmente na hora de lançar, porque essa checagem vive
numa função diferente e não é afetada.

### Sistema de baú de recompensa única (quest chests)
- Criado `data/scripts/actions/quests/custom_reward_chests.lua`: baú
  reusável (item 2472) que dá uma recompensa configurável **uma única vez**
  por jogador, controlado por Action ID. Suporta "group" opcional — baús do
  mesmo grupo compartilham uma única trava (usado nos 4 baús de kit
  inicial: abrir qualquer um deles bloqueia os outros 3 pro mesmo jogador).
- 4 baús de kit inicial (Knight/Paladin/Sorcerer/Druid) instalados na salinha
  de recompensa da hunt de orcs (979 a 973, 1087, z=7), cada um com placa
  (item 2012) do lado indicando a classe. Teleporte de volta pro templo
  (item 27589) no meio da sala.

### Bug importante descoberto: colisão de Action ID com scripts oficiais
Os 4 baús pareciam quebrados de formas diferentes e aleatórias (um abria
como baú vazio, um deixava andar por cima, um **virou uma alavanca de
verdade**). Causa raiz: o motor do Canary verifica ações registradas nesta
ordem de prioridade (`Actions::getAction` em `src/lua/creature/actions.cpp`):
posição > Unique ID > **Action ID** > ID do item. Meu script registra por
**ID do item** (prioridade mais baixa) — então se qualquer OUTRO script do
pacote oficial já usa a mesma Action ID que eu escolhi, aquele script ganha
a prioridade e roda no lugar do meu, silenciosamente.

Foi exatamente isso: as Action IDs que escolhi por padrão (30001-30004) já
eram usadas por `scripts/actions/dawnport/lever.lua` (uma alavanca de
verdade — daí o baú "virar alavanca") e por scripts de quests não
relacionadas (`the_new_frontier/action_arena.lua`,
`.../action_elevator.lua`, `movements/teleport/dark_cathedral_teleports.lua`).

**Lição / como evitar de novo:** antes de escolher uma Action ID nova pra
qualquer script custom, rodar:
```
grep -rhoE ':aid\([0-9, ]+\)|:actionid\([0-9, ]+\)' data/ data-otservbr-global/ | grep -oE '[0-9]+' | sort -n | uniq
```
e conferir se o número escolhido aparece na lista. A faixa **90000-91000**
foi verificada livre de colisão em 2026-08-06 e é a que uso agora pros
baús de kit inicial.

### Bug separado: rashid.lua quebrado desde a fusão das listas de itens
Descoberto durante a investigação acima: `data-otservbr-global/npc/rashid.lua`
tinha uma chave `}` sobrando no meio da lista de itens (linha 455),
resultado de um erro no script que uniu a lista original de 157 itens com
os itens extras adicionados depois. Isso quebrava o arquivo inteiro —
`unexpected symbol near '}'` no log a cada boot do servidor, e o Rashid
provavelmente não funcionava de verdade desde então. Corrigido.

---

## 2026-08-05

### NPC de compra (Yasir)
- Confirmado que `data-otservbr-global/npc/yasir.lua` (738 itens, sem trava de
  quest) está disponível como segundo NPC comprador, além do Rashid.
- **Desativado** `scripts/world_changes/oriental_trader.lua` (renomeado pra
  `.disabled`) — mesmo problema do Rashid: ~33% de chance a cada boot do
  servidor de criar um "Yasir oficial" em Ankrahmun/Carlin/Liberty Bay,
  roubando o nome do NPC do nosso mapa. Sempre checar `scripts/globalevents/`
  e `scripts/world_changes/` por esse padrão antes de adicionar qualquer NPC
  "famoso" do Tibia oficial.
- Pedro vai posicionar o Yasir manualmente no `-npc.xml` (nome exato: `Yasir`).

### Liberação de magias sem NPC
- Adicionada a flag `ignorespellcheck="1"` ao grupo `player` (padrão de todo
  personagem) em `data/XML/groups.xml`. Continua respeitando vocação/nível de
  cada magia, só remove a exigência de "comprar" ela do NPC.

---

## 2026-08-04

### Causa raiz do "chão virando água" (o bug mais demorado da sessão)
1. **Item de piso errado**: item `20888` ("marble floor" no RME) está
   catalogado como `primarytype="tools"` no `items.xml`, não como piso —
   Canary só reconhece um tile como chão de verdade se o item tiver o grupo
   `ITEM_GROUP_GROUND` nos dados de aparência (não é a mesma coisa que
   aparecer em `grounds.xml` do RME). Corrigido trocando por `20712`.
2. **Causa raiz de verdade**: `toggleMapCustom = true` (padrão do Canary) faz
   o servidor carregar por cima do nosso mapa qualquer `.otbm` na pasta
   `world/custom/` — incluindo o mapa oficial "Oramond" que vem com o
   datapack, cujas coordenadas colidem com a faixa que usamos (a partir de
   x/y 935). Corrigido com `toggleMapCustom = false`.
3. **Sidecar files sem atributo**: mapas gerados do zero via script Python
   precisam declarar `OTBM_ATTR_EXT_SPAWN_MONSTER_FILE` etc explicitamente,
   senão o Canary não acha os arquivos `-monster.xml`/`-house.xml`/etc mesmo
   eles existindo na pasta certa.

Ver [`docs/private-server-setup.md`](private-server-setup.md) pra detalhes
técnicos completos e como evitar repetir esse debug.

### Escadas (norte, leste, oeste)
- Mecânica de floorchange: cada tile só pode subir OU descer, nunca os dois —
  não existe uma "escada de mão dupla" numa única SQM. O pincel **"ramp"** do
  RME (paleta Doodads) resolve isso automaticamente colocando um par de tiles
  combinados (subida + descida) numa única pincelada.
- Construídas escadas nos 3 lados da cidade (leste e oeste exigiram abrir
  brecha na muralha, que era fechada).
- **Achado importante**: item `7888` ("stone stairs") tem um script
  hardcoded (`scripts/movements/rookgaard/rook_village.lua`) que expulsa
  qualquer jogador que pisar nele, em qualquer lugar do mapa — não usar esse
  item como escada decorativa em lugar nenhum.

### Buraco de caverna + corda
- Item `385` ("hole", floorchange=down) faz cair pro andar de baixo.
- Piso `386` ("cave ropespot", brush já pronto no RME) no ponto exato de
  aterrissagem (mesma x/y, um andar abaixo) libera o uso da corda pra subir
  de volta.

### Rashid
- Corrigida trava de quest ("The Travelling Trader") que impedia negociar.
- **Descoberto e corrigido**: `scripts/globalevents/spawn/rashid.lua`
  recriava um "Rashid oficial" todo boot do servidor numa cidade oficial
  aleatória, roubando o nome do nosso Rashid — mesmo padrão do Yasir acima.
  Desativado (`.disabled`).
- Restaurada a lista de itens original e completa do Rashid (157 itens —
  tinha sido reduzida pra 1 item em algum momento antes desta sessão) e
  mesclados mais alguns itens extras.

### Infraestrutura
- Instalado DBeaver.
- `docs/private-server-setup.md` criado: instalação com e sem Docker, mais
  seção de problemas conhecidos.
- Repositório GitHub mudou de local: agora é
  `github.com/dan-perosa/tibia-server` (remote `origin` já atualizado).
