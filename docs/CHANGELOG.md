# Changelog do servidor privado

Registro do que foi feito, por quê, e o que aprendemos no processo. Mantido
por sessão de trabalho, mais recente no topo.

---

## 2026-08-08

### Sala do "Demon" disfarçado (corredor de lava)
Pedro montou um desafio de lava com um monstro que deveria parecer um Demon de
verdade, mas usou o monstro oficial "Demon Goblin" (bem mais fraco) —
funcionou visualmente (os dois usam o mesmo `lookType`), mas o nome acima da
cabeça entregava "Demon Goblin", estragando a surpresa.

**Solução**: criado `data-otservbr-global/monster/demons/hidden_demon_goblin.lua`
— clone exato das estatísticas do Demon Goblin oficial, registrado sob um nome
interno diferente ("Hidden Demon Goblin", só pra não colidir com o registro do
Demon de verdade) e com `mType.onSpawn` chamando `monster:setName("Demon", "a
demon")` assim que nasce, antes de qualquer jogador ver. Resultado: nameplate e
texto de "olhar" mostram "Demon" normalmente; só o HP baixo denuncia na hora da
luta. Pedro trocou o monstro do spawn direto no RME.

### Sala de um jogador por vez
Pedido do Pedro: impedir que dois jogadores entrem na sala do Demon ao mesmo
tempo, e que a sala libere na hora se o único jogador lá dentro morrer (sem
esperar nenhum temporizador).

Criado `data/scripts/movements/quests/demon_goblin_room_lock.lua`: ao pisar no
tile de chegada do teleporte de entrada (971,967,7), o script confere ao vivo
— via `Game.getSpectators` sobre toda a área da sala, olhando só por
jogadores com vida > 0 — se já tem alguém lá dentro. Se tiver, o jogador é
devolvido pro tile logo antes do teleporte de entrada (967,967,7) com um
aviso, sem ser jogado pro templo. Não usa flag manual nem timeout: como a
checagem é sempre ao vivo, a sala libera sozinha assim que o único jogador lá
dentro morre (corpo não conta mais como "vivo") ou sai — nenhum caso extremo
deixa a sala travada.

### Recompensa do baú da sala do Demon
Baú em (979,967,7) configurado com Action ID 24701 → 1x Demon Legs (item
3389), usando o mesmo sistema reusável de `custom_reward_chests.lua`.

---

## 2026-08-07

### Fórmulas de cura: mesmo tratamento do dano (level/4 + maglevel^1.1)
Extensão das duas mudanças de dano pra cura, que usa a mesma estrutura de fórmula com sinal
positivo. Simulado antes com Exura Vita (nível 500/ML120: 958–1738 → 1484–2714, ~55% mais).
17 arquivos (15 magias + 2 runas de cura) tiveram o level `/5`→`/4` e o magic level virou
`^1.1`; 3 arquivos que já usavam um divisor de level diferente do padrão (`nature's_embrace`,
`restore_balance`, `magic_patch`) tiveram só o magic level ajustado, level ficou como estava, de
propósito. Cure de condição, heals de monstro e buffs de regeneração fixos não têm fórmula, não
foram tocados. Ver [`healing-formula-update.md`](healing-formula-update.md) pra lista completa.
Tudo Lua, vale já com `/reload`, sem precisar recompilar.

### Fórmulas de dano: expoente de skill/magic level n=1.1
Segundo passo da reformulação de dano (depois do `/5` → `/4`): skill de arma e magic level
deixaram de entrar linearmente nas fórmulas e passaram a usar `skill^1.1` / `maglevel^1.1`. Efeito:
um ponto de skill no nível 200 agora vale ~43% mais dano que um ponto no nível 5 (era 0% de
diferença antes) — decidido comparando n=1.05 vs n=1.1 num conjunto de magias/runas reais
(Sudden Death, Avalanche, Exori Gran, Exevo Mas San, Exevo Gran Mas Flam) em personagens de nível
50 a 2500. Afeta armas melee/distância (C++, `weapons.cpp`), 51 runas/magias com fórmula
level+maglevel, e 12 magias skill-based (todas em Lua). Curas (`intense_healing_rune`,
`ultimate_healing_rune`) e tudo relacionado a monstro ficaram de fora, de propósito. Ver
[`damage-skill-exponent.md`](damage-skill-exponent.md) pra lista completa de arquivos e
[`formulas-de-dano.html`](formulas-de-dano.html) pro catálogo geral (já atualizado).
**Mesma pendência de antes: a parte C++ (armas) só vale depois de recompilar e publicar um
`canary.exe` novo.**

### Fórmulas de dano: divisor de level level/5 → level/4
Primeiro passo da reformulação das fórmulas de dano do servidor: todo lugar onde o level do
personagem entra como termo aditivo numa fórmula de dano passou de `/5` para `/4` (~25% mais peso
pro level). Afeta armas melee/distância, todas as runas e magias de ataque com fórmula
`level+maglevel`, as magias skill-based (Berserk, Groundshaker, Ethereal Spear, etc.) e o ponto de
partida do combo do Monge (`calculateFlatDamageHealing`, que segue progressivo, só desloca o
início de `/5` pra `/4`). Wand e o fallback genérico do C++ ficaram de fora por decisão do Pedro.
Ver [`damage-formula-level-divisor.md`](damage-formula-level-divisor.md) pra lista completa de
arquivos tocados e [`formulas-de-dano.html`](formulas-de-dano.html) pro catálogo geral de
fórmulas de dano do projeto (já atualizado com os novos valores).
**Pendência: o lado C++ (armas + combo do Monge) só entra em vigor depois de recompilar e publicar
um `canary.exe` novo.**

### Taxa de experiência aplicada (`data/stages.lua`)
Implementada a tabela de `experienceStages` desenhada e aprovada na sessão anterior — ver
[`exp-rate-design.md`](exp-rate-design.md) pra metodologia completa, fontes de dado real e
histórico de decisão. Resumo: multiplicador começa em 3x (level 1-100) e sobe em 15 degraus
suaves até 91x (level 2501+), calibrado com XP/hora real do Tibia global (não chute) pra
manter level 2000-3000 factível sem tornar o início do jogo instantâneo. `skillsStages` e
`magicLevelStages` não foram mexidos, só `experienceStages`.

### Mapa consolidado num único local rastreado pelo git
O mapa vinha sendo editado numa cópia fora do repositório (`tibia-server/meu-mapa/`), enquanto
existia uma cópia bem antiga e desatualizada dentro do repositório (`canary/meu-mapa/`, sem
nenhuma das mudanças recentes). Sincronizado: `canary/meu-mapa/` agora é a fonte única de
verdade. `sync-map-to-server.ps1` e `tools/otbm-tools/fix_ground_20888.py` atualizados pra
apontar pro novo local.

---

## 2026-08-06 (continuação)

### Sala-cofre da tumba (dragões/aranhas/scarabs, cópia da Banshee Quest)
- Configurados os 6 baús (item 2472) que o Pedro colocou na sala: 4 nos
  cantos + 2 perto do portal de saída. Cada um é independente (sem grupo/
  trava compartilhada) — o jogador pode abrir todos os 6, um de cada vez:
  - (1216,1116,7) Action ID 24601 → life ring
  - (1230,1116,7) Action ID 24602 → stone skin amulet
  - (1216,1130,7) Action ID 24603 → small diamond x5
  - (1230,1130,7) Action ID 24604 → platinum coin x100
  - (1222,1132,7) Action ID 24605 → great mana potion x25
  - (1224,1132,7) Action ID 24606 → great health potion x25
- **Revisado logo em seguida**: Pedro pediu só 4 baús, não 6. Os 2 perto do
  portal (1222,1132,7 e 1224,1132,7) voltaram a ficar sem Action ID (baú
  inerte, sem função). Os 4 dos cantos foram reconfigurados com o pedido
  final: 1 peça de equipamento + 50k de gold (crystal coin x5) cada —
  200k no total, dividido igual entre os 4:
  - 24601 → pair of soft boots + 50k
  - 24602 → royal scale robe + 50k
  - 24603 → elite draken mail + 50k
  - 24604 → master archer's armor + 50k
- Portal de saída da sala (item 1949 em 1223,1133,7) tinha destino
  `(0,0,0)` (não configurado). Corrigido pra teleportar pro templo
  `(1000,1000,7)` — mesmo destino já usado pelo teleporte de volta da
  hunt de orcs (item 27589 em 976,1091,7), reaproveitado por consistência.

### Bug sério descoberto: Action ID acima de 65535 estoura silenciosamente no `.otbm`
A primeira tentativa usou Action IDs 90001-90006 pra esses baús (mesma
faixa "90000-91000" documentada como livre de colisão no
`custom_reward_chests.lua`). Depois de salvar, conferi o arquivo de novo e
os IDs realmente gravados eram **24465-24470** — dois deles (24465, 24466)
batendo em cima dos baús de kit inicial (Knight/Paladin) já existentes!

**Causa:** o campo Action ID dentro do arquivo `.otbm` é de 16 bits
(0-65535). `90001 mod 65536 = 24465`, e assim por diante — o valor estourou
e "deu a volta" silenciosamente, sem erro nenhum. A faixa 90000-91000 só
tinha sido validada contra chamadas `:aid()` dentro de scripts Lua (que
aceitam qualquer número), nunca contra o formato binário do mapa. Corrigido
usando a faixa 24601-24606 (verificada livre tanto nos scripts quanto no
mapa em si) e documentada essa distinção no cabeçalho do
`custom_reward_chests.lua` pra não repetir.

### Bug grave: RME aberto revertia TODAS as correções feitas por fora
Pedro pediu pra checar se os baús da sala-cofre estavam funcionando. Descoberto que **os 4
baús, o portal, a remoção da grade da escada e a correção da água tinham voltado ao estado
antigo** — nenhum dos 4 fixes anteriores estava mais valendo, nem no arquivo local nem no
container.

**Causa raiz**: o `canary-map-editor-x64` (RME) estava aberto desde as 15:49, rodando o tempo
inteiro em que os fixes acima foram aplicados via `otbm.py` direto no arquivo. Como o RME
mantém sua própria cópia do mapa em memória (carregada antes dos meus fixes), qualquer save
dele — manual ou automático — sobrescreve o `.otbm` inteiro com essa versão desatualizada,
sem aviso. Confirmado na prática: reapliquei os 4 fixes, salvei, e segundos depois o arquivo
já tinha voltado ao estado antigo de novo — só parou de acontecer depois que o Pedro fechou o
RME.

**Lição**: essa mesma armadilha já era conhecida pros arquivos `-npc.xml`/`-monster.xml`/etc
(RME reescreve eles do zero ao salvar), mas não estava documentado que o **`.otbm` em si**
sofre do mesmo problema. Daqui pra frente: **sempre confirmar que o RME está fechado antes de
editar o mapa via `otbm.py`**, e se o Pedro quiser deixar o RME aberto, ele precisa dar
File → Reload nele depois de qualquer edição minha, antes de salvar de novo por lá.

Todos os 4 fixes foram reaplicados com o RME fechado e confirmados persistentes desta vez:
baús (24601-24604), portal (→ templo), grade da escada removida, água da plataforma corrigida.

### Escada de subida da plataforma de fogo virou "sem volta" de verdade
Pedro queria que, depois de descer da plataforma elevada central (as
armadilhas de fogo, em z=6) de volta pro chão da sala (z=7), o jogador não
conseguisse subir de novo por ali — só saindo pelo teleporte. A primeira
tentativa foi colocar uma grade (item "bars", 2185) fixa em cima dos 3 tiles
da escada de subida (1222-1224,1114,7). **Isso não funcionaria**: se a
grade bloqueia passagem (como grades normalmente fazem no Tibia), ela
bloquearia também a primeira subida — ninguém jamais chegaria na plataforma.

Fui ver como a Banshee Quest oficial resolve exatamente esse problema
(`data-otservbr-global/scripts/quests/the_queen_of_the_banshees/
movement-1-first_seal_close_mw.lua`): a parede não fica no mapa desde o
início. Um `MoveEvent` na posição por onde o jogador PASSA depois do ponto
sem volta **cria** a parede ali (`Position(pos):createItem(2129)`),
selando o caminho retroativamente.

Apliquei a mesma técnica: removida a grade estática do mapa nos 3 tiles da
escada de subida. Criado `data/scripts/movements/quests/vault_room_seal.lua`
— um `MoveEvent` nos 3 tiles onde o jogador aterrissa ao descer a escada de
z=6 (1223,1116,7 / 1224,1116,7 / 1225,1115,7 — calculados a partir da lógica
real de `Tile::queryDestination` em `tile.cpp`, incluindo o ajuste que o
motor já faz pra não devolver o jogador em cima da própria escada de
subida). Ao pisar ali, o script cria a grade (2185) nos 3 tiles de subida
(1222-1224,1114,7), com checagem pra não duplicar se o jogador passar várias
vezes pelo gatilho.

**Observação**: igual à quest oficial, esse selo é do **tile**, não por
jogador — é estado compartilhado do mundo. Se dois jogadores estiverem na
sala ao mesmo tempo, o primeiro que descer sela a escada pros dois (fiel ao
comportamento da quest real, mas vale saber caso alguém fique "preso" em
cima esperando um amigo).

### Revisado: selo virou por jogador, não mais compartilhado
Pedro apontou que o comportamento "compartilhado" acima é ruim — com vários
jogadores na sala ao mesmo tempo, o primeiro a descer trancaria a escada
pros outros também, podendo prender alguém em cima. Pedido: cada jogador
precisa poder subir/descer de forma independente, e só fica bloqueado de
subir de novo DEPOIS que ELE MESMO descer.

Reescrito `vault_room_seal.lua` sem criar nenhuma parede/grade no mundo —
mais simples que a técnica da quest oficial e sem o problema de estado
compartilhado:
- Ao pisar num dos 3 tiles de chegada da escada de descida, grava
  `player:setStorageValue(62300, 1)` (flag individual do jogador).
- Ao pisar num dos 3 tiles da escada de subida (item 1956), o script checa
  essa storage; se já tiver descido, teleporta o jogador de volta pra onde
  ele veio antes da mudança de andar acontecer e cancela a subida.

Confirmado no código-fonte (`game.cpp`, `Game::internalMoveCreature`) que
o jogador já está fisicamente parado no tile de subida no momento em que
esse `onStepIn` roda — a troca de andar (`TILESTATE_FLOORCHANGE`) só é
resolvida DEPOIS, então teletransportar de volta nesse momento cancela a
subida de forma confiável, sem qualquer chance de o jogador ficar "preso"
entre andares.

### Bug de verdade: coordenadas erradas no script do selo da escada
Pedro reportou que às vezes conseguia subir de novo logo após descer, e só
ficava travado depois de andar um pouco. Causa: as posições de aterrissagem
usadas no `vault_room_seal.lua` estavam erradas em 2 dos 3 tiles (usei
y=1116 em vez de y=1115, resquício de um cálculo anterior que eu mesmo já
tinha corrigido no texto, mas esqueci de atualizar no código). Recalculei
com um script Python que reproduz exatamente `Tile::queryDestination`
(`tile.cpp`) em cima dos dados reais do mapa em vez de fazer conta de
cabeça — landing correto é (1223,1115,7) / (1224,1115,7) / (1225,1115,7),
todos na mesma linha. Corrigido e reimplantado.

### Água de verdade na plataforma de fogo (não era bug de config)
Pedro reportou boa parte da "cave de mamis escarabes" cheia de água, sem
aparecer no RME. Investigado a fundo (cheguei a suspeitar de novo do bug do
`toggleMapCustom` do dia 04 — confirmado que **não** é isso, está `false`
como deveria). Causa real: a própria plataforma elevada da sala (z=6, onde
ficam as armadilhas de fogo) tinha **465 tiles de chão "shallow water"**
de verdade (itens 4597-4633), espalhados por boa parte dela — provavelmente
um brush errado usado sem querer ao construir aquele andar no RME. A água
está realmente gravada no mapa; só não é visível se você olhar o andar
errado no editor (z=7 em vez de z=6, onde fica essa plataforma).

Substituídos os 465 tiles de água pelo piso "mountain" (item 1128), que já
era o chão predominante no resto da mesma plataforma (250 dos ~826 tiles).
É uma correção funcional — o encaixe visual nas bordas onde a água tocava
outros tipos de piso pode precisar de um retoque manual no RME depois, se
Pedro achar a transição feia.

### `server-fixes/login.lua` estava desatualizado (risco de regressão)
Descoberto de passagem: o `sync-map-to-server.ps1` (usado toda vez que o
Pedro salva o mapa no RME) sempre sobrescreve o `login.lua` do container a
partir de `server-fixes/login.lua` — e esse arquivo ainda era a versão
**antiga**, de antes do sistema de auto-aprender magias. Rodar o sync teria
revertido aquela correção sem aviso nenhum. Sincronizado com a versão atual
do repositório.

### NPC de promoção (Alexander the Novice Uncoverer)
- Criado `data-otservbr-global/npc/alexander_the_novice_uncoverer.lua`:
  promove a vocação do jogador (Sorcerer→Master Sorcerer etc, via
  `vocation:getPromotion()`) a partir do nível 20, cobrando os 20.000 gold
  clássicos. Posicionado em (1001,1010,7).

### Bug de duplicação de item nos baús de recompensa (espaço insuficiente)
Se `player:addItem()` falhasse no meio do loop de recompensa (inventário
cheio), o baú não era marcado como aberto, permitindo reabrir depois e
receber de novo os itens que já tinham entrado com sucesso na tentativa
anterior. Corrigido: `custom_reward_chests.lua` agora checa peso total e
slots livres pra recompensa INTEIRA antes de dar qualquer item — tudo ou
nada, nunca parcial. **Lição para o futuro:** sempre considerar esse
cenário (espaço insuficiente no meio da entrega) em qualquer recompensa
de quest nova.

### Correção: algumas magias exigiam conta premium
`freePremium = true` no `config.lua` — libera contas premium pra todo
mundo (opção oficial do Canary pra isso, diferente da tentativa anterior
com `ignorespellcheck`). Não afeta nível/vocação/mana, só a checagem de
`isPremium()`.

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
