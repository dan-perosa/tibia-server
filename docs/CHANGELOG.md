# Changelog do servidor privado

Registro do que foi feito, por quê, e o que aprendemos no processo. Mantido
por sessão de trabalho, mais recente no topo.

---

## 2026-08-25

Dia longo: migração de infra completa, primeiro teste real com um amigo via Hamachi, e uma boa
quantidade de bugs de cliente/servidor encontrados e corrigidos ao vivo durante esse teste.

### Migração completa: Docker → XAMPP nativo
Pedro e o Tael (amigo do Dan, programador) tiraram o projeto do Docker de vez. Servidor agora roda
como `canary.exe` nativo direto de `canary/`, banco é uma **MariaDB 11.4 standalone** instalada
como serviço do Windows (não é o `mysqld` que vem junto do XAMPP — esse fica sem uso, só ocupando
espaço), site (MyAAC) direto em `C:\xampp\htdocs\` via Apache, phpMyAdmin pra administração do
banco. Detalhes completos e credenciais em `[[project-tibia-server]]` (memória do Claude).

### Bug feio: script de sync empurrava mapa de 3 dias atrás pro servidor
`canary/sync-map-to-server.ps1` calculava o caminho do mapa como `$PSScriptRoot\meu-mapa` — como o
script mora dentro de `canary/`, isso resolvia pra uma pasta **separada e congelada desde
21/08 20:32** (`canary/meu-mapa/`), não a pasta real que o RME edita (`meu-mapa/`, na raiz do
repo). Toda sincronização (várias rodadas ao longo do dia) mandava esse snapshot velho pro
servidor sem erro nenhum pra avisar — parecia que "áreas inteiras do mapa tinham sumido" (um
porto/barco inteiro, entre outras coisas) quando na real nada tinha sido perdido, só o servidor
estava sempre 3 dias atrasado. Corrigido resolvendo o caminho relativo à raiz do repo
(`Split-Path $repoRoot -Parent`), não à pasta do próprio script.

### Bugs de exibição no OTClient (várias telas de skill/combate)
- **Barra de skill "parecia cheia" ou travada**: `statsbar.lua`, `XPAanalyser.lua` e
  `offlinetraining1524.lua` liam o percentual bruto do protocolo (que vem multiplicado por 100)
  sem dividir de volta — resultado, a barra ficava cheia com qualquer progresso mínimo, ou
  mostrava número errado. Corrigido dividindo por 100 nesses três arquivos (o `skills.lua`
  principal já fazia isso certo desde 24/08).
- **Personagem persegue monstro sozinho mesmo com a caixa desmarcada**: bug de ordem de execução
  em `game_inventory/inventory.lua` — `onGameStart` restaurava o modo de combate salvo da sessão
  anterior *antes* de conectar o listener que sincroniza a caixinha visual, então a tela mentia
  sobre o estado real. Corrigido forçando um resync (`combatEvent()`) logo após restaurar.
- **Popup de "você subiu de skill" com o nome errado** (Shielding aparecia como "Distance
  Fighting", e a maioria das outras skills caía num texto genérico): a tabela `SkillId` em
  `game_notifications/controllers/infobanner.lua` usava uma sequência 1..8 chutada, em vez dos
  valores reais do protocolo (`CipbiaSkills_t` no C++ do Canary — só Magic Level por coincidência
  batia). Corrigido com os valores certos (Shield=6, Distance=7, Sword=8, Club=9, Axe=10, Fist=11,
  Fishing=13).

### Primeiro teste real com um amigo (via Hamachi) — bugs encontrados na hora
Processo completo documentado em `[[project-tibia-hamachi-onboarding]]`. Bugs reais achados e
corrigidos durante o teste:
- `site_url` do MyAAC fixo em `http://localhost/` quebrava CSS/JS pra qualquer um que não fosse o
  Pedro (recursos carregavam via URL absoluta apontando pra "localhost" da máquina de quem
  acessava). Corrigido pro IP do Hamachi.
- Tabela `myaac_account_actions` com esquema antigo, faltando a coluna `ipv6` — dava erro 500 toda
  vez que alguém criava conta/logava (a ação em si funcionava, só o log dela quebrava).
  `ALTER TABLE ... ADD COLUMN ipv6 VARBINARY(16)`.
- Baú de recompensa de quest (`custom_reward_chests.lua`) recusava dar o prêmio mesmo com espaço
  de sobra — a checagem de capacidade dividia `getFreeCapacity()` por 100 sem necessidade, exigindo
  100x mais espaço livre do que o item realmente pesava (confirmado no C++ que as duas grandezas já
  usam a mesma escala). Corrigido removendo a divisão.

### Limpeza de conteúdo "de fábrica" nunca customizado
- `custom_monster_loot.lua` tinha um exemplo/demo esquecido dando **Christmas Token com 100% de
  chance em todo monstro do jogo** — não era evento nenhum, só placeholder nunca removido.
  Esvaziado.
- `freePremium` ligado (`false` → `true`) — personagens não conseguiam conjurar magias que exigem
  conta premium.

### Melhorias pontuais
- Kits iniciais de classe (`custom_reward_chests.lua`, action ids 24465-24468) agora incluem uma
  exercise weapon apropriada por vocação (Knight: sword/axe/club, Paladin: bow, Sorcerer: wand,
  Druid: rod) — personagem novo já nasce podendo treinar.
- Baús de recompensa de quest (item 2472 "chest") agora têm `movable="0"` no `items.xml` — não
  podiam mais ser tirados do lugar por jogadores (frozen chest 7160/7161 já vinha travado por ser
  `primarytype="refuse"`; o "chest" comum não tinha equivalente). RME tem cópia própria de
  `items.xml` (`tools/rme/.../data/items/items.xml`) — espelhada a mesma mudança lá, mas o painel
  de propriedades do RME deriva "Movable" do `primarytype`, não do atributo `movable`, então
  continua mostrando "Yes" mesmo com o item já travado de verdade no servidor (confirmado
  testando in-game). Chest ainda não bloqueava passagem por cima do tile — isso é uma propriedade
  de sprite/aparência (`appearances.dat`, binário), não editável via texto; resolvido pelo Pedro
  colocando um objeto sólido adicional no local.
- NPC Carmeni Tigers (comerciante do porto) trocado de outfit "Oriental" pra "Pirate" (lookType
  155, mesmo tipo do Captain Dreadnought), combinando com o tema de expedições.

## 2026-08-24 (4)

### Expoente do bônus de dano reduzido (^0,5 → ^0,3)
Pedro conversou com o Daniel, que mencionou já ter escrito o esquema antigo de expoente embutido
(`n = 1.1`, nunca testado rodando — mesma limitação de recompilar). Pedindo um meio-termo entre
esse `n=1.1` e o `√(stat/10)` de mais cedo (que ficou forte demais, +347% no skill 200), ajustado
pra `(stat/10)^0.3` — fica em +146% no skill 200. Só troca o número final da fórmula em
`Player:onCombat`, mesma estrutura (1x na skill 10, sem teto). Detalhes e tabela comparativa em
`docs/skill-power-design.md`.

## 2026-08-24 (3)

### XP de nível baixo dobrada (faixa 1-100: 3x → 6x)
Pedro testou upar em level baixo (8-11) e achou muito devagar. Faixa `experienceStages` de
1-100 dobrada de 3x pra 6x em `data/stages.lua` — as outras faixas (101+) não foram tocadas.
Aplicado direto no container e no arquivo do repo.

### Comando de debug `!givemanapotions`
Criado `data/scripts/talkactions/player/givemanapotions_debug.lua` — dá 100 mana potions pra
quem digitar, sem precisar de conta GM. Só pra facilitar teste de rate de skill/ML; **temporário**,
remover quando não precisar mais.

### Confirmado: level/magic level sempre subiram certo por trás da tela
Sessão de debugging longa em cima de "não sobe de level"/"magic level travado" — conferido direto
no banco (`SELECT level, experience, maglevel, manaspent FROM players`) que a progressão sempre
funcionou (personagem de teste chegou a level 11/maglevel 13 normalmente). As causas reais eram
duas coisas separadas, nenhuma delas bug de verdade:
1. **Bug de exibição no OTClient**: o valor de "percentual pro próximo level" chega multiplicado
   por 100 (`ProtocolFeature::PlayerDataLevelPercentU16` do Canary, protocolo manda `percent*100`
   como u16) mas o cliente não estava dividindo de volta antes de mostrar — corrigido em
   `tools/otclient/modules/game_skills/skills.lua` (`onLevelChange`/`onMagicLevelChange`/
   `onSkillChange`, dividindo por 100). Ainda resta uma inconsistência (barra "sobe e desce"
   às vezes) não fechada — provavelmente outro lugar do cliente lendo o mesmo valor sem a
   correção; pendente de mais um print pra fechar.
2. **Perda de skill/magic level ao morrer é mecânica normal do jogo** (mesma lógica que reduz
   experiência — `player.cpp` em torno da linha 4047-4098), não bug. Confirmado com o Pedro que
   fica assim mesmo (decisão consciente, não é pra tirar).

### Tentativa de atualizar o OTClient (revertida)
Baixado um build mais novo do `opentibiabr/otclient` (release 4.1, 15/08) pra tentar corrigir os
bugs de protocolo acima — duas variantes testadas (`windows-solution-opengl`,
`windows-cmake-release`), **as duas travam ao abrir** no PC do Pedro (erro `0xc0000409`, sem gerar
log). Revertido pro binário antigo (12/06), que funciona. Backup da build antiga preservado em
`tools/otclient/_engine-backup-2026-06-12/` caso sirva de referência depois. **Efeito colateral
descoberto no processo**: um comando de backup mal-executado criou um arquivo com nome corrompido
dentro de `tools/otclient/` que impediu o cliente de abrir mesmo com o binário certo restaurado —
resolvido apagando o arquivo. Lição: sempre conferir que comandos com aspas/concatenação em lote
no PowerShell/bash realmente rodaram como esperado antes de assumir sucesso.

## 2026-08-24 (2)

### Rate de loot, rate de skill/magic level, e poder por dano — desenhados e implementados
Sessão longa desenhando três rates junto com o Pedro (ver
[`skill-power-design.md`](skill-power-design.md) pro raciocínio completo e histórico de
calibração):

- **`rateLoot = 5`** — simples, flat, ponto de partida pra testar (`config.lua`/
  `config.lua.dist`, e adicionado ao `sed` dos dois `sync-map-to-server.ps1` — raiz e `canary/`
  — pro mesmo motivo do `rateUseStages`: `/canary/config.lua` não é persistente, some se o
  container for recriado do zero).
- **Rate de skill/magic level**: trocado o sistema padrão do Canary (`skillsStages`/
  `magicLevelStages`, que tem teto) por uma fórmula contínua em 3 fases direto em
  `Player:onGainSkillTries` (`data/events/scripts/player.lua`) — rápida de skill 10 a 100,
  transição até 150 (ancorada num multiplicador de 4.674x que o Pedro validou), mais dura e sem
  teto dali em diante. `skillsStages`/`magicLevelStages`/`rateSkill`/`rateMagic` ficam sem efeito
  algum agora (tabelas mantidas vazias em `data/stages.lua` só de referência).
- **Poder por dano**: em vez de reativar/estender o expoente `skill^1.1` que uma sessão anterior
  (07/08) tinha deixado pela metade — a parte de armas (C++, `weapons.cpp`) nunca chegou a valer
  de verdade porque nunca foi recompilada, e o servidor do Pedro roda a imagem pronta do Docker,
  não um build próprio — implementamos um multiplicador central em `Player:onCombat`, que roda
  depois que qualquer dano (autoataque, magia, ou runa) já foi calculado. Bônus = `√(skill_ou_ML /
  10)`, 1x na skill inicial (10), sem teto dali em diante. Cobre os três tipos de dano de uma vez,
  sem tocar em C++ e sem precisar editar cada magia/runa individualmente (nem as que ainda não
  existem).

**Achado importante no processo**: a fórmula real de custo de skill do próprio motor
(`vocation.cpp`) já é fortemente exponencial por natureza (multiplicador de vocação composto por
nível), e uma arma de exercício de 14.400 cargas dá exatamente 8 horas de treino contínuo — usado
como âncora real pra calibrar a rate em vez de chutar horas abstratas.

**Pendência**: os números da rate de skill são chute calibrado por conversa, não medição de
playtest real — Pedro vai testar in-game e pedir ajuste fino nos 3 expoentes se necessário (ver
doc pra quais botões mexer). Também descoberto que o `sync-map-to-server.ps1` unificado (dentro
de `canary/`) tinha perdido a linha de `rateUseStages` que existia na versão antiga da raiz —
corrigido nesta sessão, senão a rate de XP também voltaria a desligar sozinha numa recriação de
container futura.

## 2026-08-24 (1)

### Furious Yeti criado pra terceira arena (gelo) + sincronização atrasada pega no processo
Pedro escolheu visual de Yeti pra sala de gelo, com força parecida com o
Stalking Stalk (dragon arena). Criado
`data-otservbr-global/monster/mammals/furious_yeti.lua` — mesma técnica já
usada no Hidden Demon Goblin (clone registrado sob nome interno próprio,
sem colidir com o "Yeti" oficial), mas ao contrário: aqui o visual é fraco
(Yeti clássico, lookType 110) e as stats são de boss. Copiado o HP (17.100),
defesa/armadura e formato de ataque do Stalking Stalk, só re-temizado pra
gelo: os dois ataques à distância/área viraram `COMBAT_ICEDAMAGE` (mesmos
números, efeitos `CONST_ME_ICEATTACK`/`CONST_ME_ICETORNADO`), e a tabela de
elementos foi invertida — fraco a fogo (-25%), resistente a gelo (+25%),
fraco a físico (-25%, igual ao stalk) — em vez do perfil "planta resistente
a fogo/terra" original. Loot trocado pra genérico (gold/platinum/diamond +
frosty heart/ice cube), já que o loot do Stalking Stalk era todo temático
de planta.

**Reward escolhida pelo Pedro**: Furious Frock (item 19391, armor 12, +2
ML, +5% fire absorb) — nota rápida pro registro: é restrito a
Sorcerer/Druid (mesma trava que os itens "Glacier" tinham) e o bônus é de
absorção de **fogo**, não gelo: detalhe que ele já sabia/aceitou ao
escolher, só documentando.

**Achado no meio do processo**: o Stalking Stalk que o Pedro tinha
adicionado sozinho no RME (sessão anterior) **nunca tinha sido sincronizado
pro servidor** — o container ainda estava rodando o `-monster.xml` de
antes, com o spawn (988,974,7) vazio (confirmado no log de boot: "Empty
spawn at position (988,974,7)"). Sincronizado agora o conjunto completo
(`.otbm` + `-monster.xml` + `-house.xml` + `-npc.xml` + `-zones.xml`) pra
zerar essa defasagem. Servidor reiniciado, boot limpo, warning do
(988,974,7) sumiu.

Spawn adicionado em (968,963,7), posição passada pelo Pedro. Sincronizado
e servidor reiniciado, boot limpo — sem warning de "empty spawn" nessa
posição, monstro carregado certo.

### Recompensa da sala de gelo: Furious Frock no baú congelado (968,959,7)
Placa da sala decidida: "Don't let the shaggy fur fool you. This is no
ordinary yeti." Pedro colocou o baú com o item temático **"frozen chest"
(7160/7161)**, não o "chest" genérico (2472) usado nas outras duas salas —
achado no processo: `custom_reward_chests.lua` só escutava `onUse` pro id
2472 (`questChest:id(2472)`), então o baú novo não ia funcionar sem
ajuste. Adicionado 7160/7161 ao registro do Action (`questChest:id(2472,
7160, 7161)`) e o comentário de uso no topo do arquivo atualizado, pra
qualquer baú "frozen chest" futuro já funcionar de cara.

Registrado Action ID **24703** → 1x Furious Frock (item 19391), aplicado
no baú em (968,959,7). Sincronizado (`.otbm` + `custom_reward_chests.lua`)
e servidor reiniciado, boot limpo. Não testado ao vivo ainda.

## 2026-08-23 (13)

### Isolada a ativação: só o rate de XP entra em vigor, skill/magic ficam flat 1x
Depois de perceber (item 12) que `rateUseStages = true` também ligava
`skillsStages`/`magicLevelStages` (valores de template, nunca desenhados
por nós), Pedro pediu pra ativar **só** o rate de XP por enquanto e deixar
skill/loot pra decidir depois.

**Achado no código-fonte**: `rateUseStages` é um único switch global —
`data/libs/functions/player.lua` (exp) e `data/events/scripts/player.lua`
(skill/magic) checam a mesma flag `configManager.getBoolean(RATE_USE_STAGES)`
separadamente, sem um jeito de ligar só uma tabela. Mas `getRateFromTable()`
(`data/libs/functions/functions.lua`) cai pro rate flat (`rateSkill`/
`rateMagic`, ambos 1) sempre que a tabela recebida é `nil` **ou não tem
nenhuma faixa que cubra o nível do jogador** — então esvaziar
`skillsStages`/`magicLevelStages` pra `{}` em `data/stages.lua` consegue
exatamente o efeito pedido sem mexer no `config.lua` de novo.

Valores antigos de skill/magic (os de template, nunca calibrados) mantidos
comentados no arquivo, não apagados — ficam ali prontos como referência
pra quando a gente desenhar essas taxas de verdade. Sincronizado
(`data/stages.lua`, esse já é versionado no repo, sem o problema de
persistência do `config.lua`) e servidor reiniciado, boot limpo.

**Adicionado nas pendências**: desenhar rate de skill e de loot com o
Pedro (nenhum dos dois foi discutido ainda — loot está no padrão flat 1x
de fábrica, nunca tocado).

## 2026-08-23 (12)

### Tabela de estágios de XP ativada de verdade (estava só no arquivo, desligada)
Pedro perguntou qual era a taxa de exp/skill/loot do servidor. Conferindo o
`config.lua` ao vivo no container: `rateExp/rateSkill/rateLoot/rateMagic/
rateSpawn` todos em 1 (flat, sem boost nenhum). E a tabela de estágios de XP
por level que a gente desenhou e aprovou em 06/08 (`docs/exp-rate-design.md`)
**já estava escrita em `data/stages.lua` desde 07/08, mas nunca tinha sido
ativada de verdade** — `rateUseStages = false` no `config.lua`. Ou seja, o
servidor rodou 16 dias no rate flat 1x sem ninguém perceber que a tabela
calibrada nunca entrou em vigor.

Pedro pediu pra ativar. Aplicado `rateUseStages = true` no container rodando
e, pra isso não se perder num recreate futuro do container (`/canary` não
está em volume persistente, só `/data` está — ver `docker-compose.yml`),
adicionada a mesma linha de `sed` no `sync-map-to-server.ps1`, junto do
`toggleMapCustom` que já seguia esse padrão. Servidor reiniciado, boot
limpo. `docs/exp-rate-design.md` atualizado com a data real de ativação.
Não testado ao vivo ainda (ganho de XP por level real).

## 2026-08-23 (11)

### Bloqueio de "um jogador por vez" reconectado aos 4 portões (cada um agora com pouso próprio)
Depois da correção do item (10), Pedro ajustou manualmente no RME os 4
teleportes de entrada da dupla de salas (Demon Goblin + dragon arena) —
cada um passou a ter seu **próprio tile de pouso** (antes, os 2 de cada
sala convergiam num pouso só). Efeito colateral não-intencional: os dois
scripts de bloqueio (`demon_goblin_room_lock.lua` e
`dragon_arena_room_lock.lua`) só disparam no pouso antigo/específico que
tinham hardcoded — como nenhum teleporte leva mais pra lá, **o bloqueio
de dupla-entrada ficou sem efeito nas duas salas**.

Os 4 pousos novos seguem um padrão consistente por banda de Y (não é
bagunça): os 2 portões "norte" (976,965,7 e 989,964,7) agora pousam em
y≈964-965 (sala do Demon Goblin); os 2 "sul" (982,974,7 e 995,973,7)
pousam em y≈973-974 (dragon arena) — inclusive dois portões trocaram de
sala em relação ao pouso compartilhado antigo, então essa não foi uma
mudança cosmética, foi reatribuir corretamente qual portão abre qual
sala.

**Correção**: os dois scripts agora registram o mesmo `onStepIn` em
**duas posições** (`ENTRANCE_LANDINGS`, lista) em vez de uma só — mesmo
padrão de `:position()` chamado em loop já usado em
`data-otservbr-global/scripts/movements/teleport/candia.lua`. Sala do
Demon Goblin: (979,965,7) e (993,964,7). Dragon arena: (985,974,7) e
(1000,973,7). Caixas de detecção (`ROOM_RANGE`) não mudaram, só a lista
de tiles que disparam o check.

Sincronizado os dois scripts e servidor reiniciado, boot limpo. Não
testado ao vivo ainda (recomendo testar com 2 contas nos 4 portões).

## 2026-08-23 (10)

### Nova "dragon arena" (irmã da sala do Demon Goblin): recompensa + bugs de teleporte/colisão de baú corrigidos
Pedro construiu um novo desafio parecido com a sala do Demon Goblin
(mesmo estilo de corredor de armadilhas), logo ao lado dela, e pediu 3
coisas: (1) recompensa de Dragon Scale Legs no baú novo, (2) checar se os
teleportes de entrada/saída estão funcionando (ele mudou a posição da
"primeira arena" e desconfiava que quebrou algo), (3) confirmar que o
formato de "um jogador por vez" continua valendo.

**Investigação** (mapa lido via `otbm.py`, cruzado com `-monster.xml` e o
código-fonte do sistema de recompensa): a sala antiga (Hidden Demon
Goblin) realmente foi movida — monstro agora em (982,965,7), baú em
(987,965,7) — mas continua íntegra e o baú ainda aponta pro Action ID
certo (24701). O problema estava todo na sala NOVA:

1. **Baú novo (993,974,7) tinha o MESMO Action ID do baú antigo (24701)**
   — herdado de ter copiado a sala antiga no RME como base. Isso fazia o
   baú novo dar a recompensa ERRADA (Demon Legs) e, pior, **compartilhar
   o storage de "já resgatado"** com o baú antigo — se o jogador já tivesse
   pego a recompensa de um dos dois em algum momento, o outro apareceria
   como "already empty" sem dar nada. Corrigido: novo Action ID **24702**,
   registrado em `custom_reward_chests.lua` com 1x Dragon Scale Legs
   (3363) — já tem inclusive uma cópia decorativa do item numa mesa do
   lado do baú, então bate com a intenção.

2. **Teleporte de entrada da sala nova estava quebrado de verdade**: as
   duas entradas ((989,964,7) e (995,973,7)) levavam pra (984,967,7), que
   hoje é **lava com uma parede em cima** — sobra de antes da sala do
   Demon Goblin ser movida pra cima dessa posição. Redirecionado as duas
   pra (983,967,7), tile vizinho confirmado andável.

3. **"Um jogador por vez" só existia pra sala antiga.** O
   `demon_goblin_room_lock.lua` (único script desse tipo no servidor) tinha
   uma caixa de checagem generosa (957-979 em y) que sem querer **também
   cobria a sala nova inteira** — ou seja, um jogador lutando na sala nova
   podia bloquear a entrada de outro jogador na sala antiga por engano.
   Criado `dragon_arena_room_lock.lua` (mesmo formato/sem flag manual, só
   `Game.getSpectators` ao vivo) pra sala nova, e cortada a caixa da sala
   antiga pra parar em y=968 (achado por mapear as paredes reais da sala
   — "brick wall" ids 1272-1276 — em vez de chutar).

**Pendência que fica pro Pedro confirmar**: o spawn de monstro da sala
nova, em (988,974,7), está **cadastrado no `-monster.xml` mas vazio**
(círculo de spawn sem nenhum monstro dentro). Não mexi nisso — escolher o
monstro é decisão de design, não técnica. As caixas de detecção das duas
salas foram inferidas a partir da posição real de parede/monstro/baú no
mapa (não visualmente confirmadas em jogo) — vale testar ao vivo entrando
com 2 contas pra confirmar que cada sala barra certo (e só a certa).

Backup do `.otbm` antes (`.bak_dragon_arena_fix_20260823`). Sincronizado
(mapa + 3 scripts) e servidor reiniciado, boot limpo (só um warning novo
não relacionado: item móvel 23703 numa casa em 1028,1017,7, pré-existente
e fora do escopo dessa sessão). Não testado ao vivo ainda.

## 2026-08-23 (9)

### Talon e Blood Herb na loja da Haani Homes
Pedro pediu pra Haani Homes (NPC de itens de casa/móveis, arquivo
`haani_homes.lua`) vender também **talon** (3034) e **blood herb** (3734).

Nenhum NPC do datapack vende esses dois pro jogador hoje — só compram
(Augustin/Rachel pagam 320 pelo talon, Chondur paga 500 pelo blood herb).
Como Pedro não passou preço, escolhi valores com uma margem acima desses
preços de venda já existentes (**talon 400, blood herb 650**) — abaixo
disso o servidor acusa desequilíbrio de economia (o mesmo warning de
"sold for a value greater than purchased" que já aparece pra outros itens
no boot). Confirmado no log após reiniciar: nenhum warning novo pros dois
itens.

Sincronizado e servidor reiniciado, boot limpo. Não testado ao vivo
ainda.

## 2026-08-23 (8)

### Beetle Necklace na box de (977,1046,5) + ferramenta ganhou suporte a container preenchido
Pedro pediu pra colocar um "Beetle Necklace" dentro da box que já existe
em (977,1046,5) — não como recompensa de quest via script, só um item
parado dentro do container, prêmio pra quem explora e mexe nas coisas do
mapa.

**Descoberta que travou o pedido no meio do caminho**: o `otbm.py`
(ferramenta Python que uso pra editar o `.otbm` fora do RME) tinha uma
limitação documentada — não sabia ler nem escrever itens dentro de
containers (`children`). Pior: o comportamento até então era **descartar
silenciosamente** o conteúdo de qualquer container ao reescrever o mapa
(lia os filhos do nó do item e simplesmente não guardava em lugar
nenhum). Antes de fazer qualquer coisa, escaneei o `.otbm` inteiro
procurando containers com conteúdo já existente — **resultado: zero, o
mapa inteiro não tinha nenhum container preenchido ainda**, então não
houve perda de dado nenhuma dessa vez, mas era uma armadilha real pra
qualquer edição futura via script.

Estendido o `otbm.py` (ver `tools/otbm-tools/otbm.py` e a skill
`tibia-map-building` atualizada com o novo comportamento): `OtbmItem`
ganhou campo `children`, leitura e escrita agora recursivas. Formato
confirmado direto no código-fonte do RME (`Container::serializeItemNode_OTBM`/
`unserializeItemNode_OTBM`) — conteúdo de container é só mais nós
`OTBM_ITEM` aninhados dentro do nó do próprio container, sem marcador
especial. Testei round-trip (ler -> adicionar filho de teste -> escrever
-> ler de novo -> comparar mapa inteiro) numa cópia antes de tocar no
mapa de verdade.

Com a ferramenta corrigida: backup do `.otbm`
(`.bak_beetle_necklace_box_20260823`), localizada a box (item 2469) na
tile (977,1046,5), confirmado que estava vazia, adicionado 1x Beetle
Necklace (10457) dentro dela. Sincronizado e servidor reiniciado, boot
limpo. Não testado ao vivo ainda.

## 2026-08-23 (7)

### Outfits ligados à função: Blessing Merchant, Sebastian Farwind, Captain Windrift
Continuação do ajuste de outfits do item (6) — Pedro gostou do resultado e
pediu pra estender a mesma ideia (visual amarrado à função do NPC no
servidor) pra mais três:

- **Blessing Merchant** (arquivo interno é `testserver_assistant.lua` —
  nome de exibição diferente do arquivo): trocado de "Citizen" genérico
  pras mesmas cores da **Norma** (`norma.lua`) — a NPC oficial de
  bênção do Tibia de verdade, mesmo outfit "Citizen" (136) com robe
  terroso, addons=2. Reaproveitado 1:1 porque é literalmente o mesmo papel
  (dar bênção).
- **Sebastian Farwind** (barco pequeno/chave dos orcs): trocado de
  "Hunter" pra **Pirate (151)**, cores do **Black Bert** (`black_bert.lua`
  — pirata oficial do Tibia), addons=1 — visual de marinheiro/barqueiro
  modesto, mais simples que o Windrift de propósito (ele é só um
  barqueiro local, não capitão de uma linha).
- **Captain Windrift** (Royal Tibia Line, viagens ainda desativadas —
  ver pendência em [[project-tibia-pending-items]]): trocado de "Hunter"
  pra **Nobleman (132)**, cores do **Admiral Wyrmslicer**
  (`admiral_wyrmslicer.lua`), addons=2 — visual distinto e mais
  distinguido que o Sebastian, condizente com capitão de uma companhia
  marítima oficial.

Critério usado nos três: sempre que existe um NPC oficial do próprio
datapack com a mesma função (bênção, pirata, almirante), reaproveitar as
cores dele em vez de inventar — outfit de NPC não tem risco de sprite
faltando (paleta de cor 0-132 sempre válida), mas o lookType em si
(Nobleman/Pirate/Citizen) já é validado por já estar em uso em outro NPC
funcionando nesse mesmo build.

Sincronizado os três arquivos e servidor reiniciado, boot limpo. Lembrete
pro Pedro: outfit só atualiza no RME com **F5 (File → Reload)** — reabrir
só o mapa dentro da mesma sessão do editor não recarrega os `.lua`
(descoberto nessa mesma sessão, ver conversa). Não testado ao vivo ainda.

## 2026-08-23 (6)

### Outfit da Rojan Training e da Eva Buffet trocados
Pedro pediu pra Rojan Training (treinamento) parecer uma instrutora de
combate, e pra Eva Buffet (a NPC do banco, apesar do nome) parecer uma
pessoa rica e bem-sucedida.

- **Rojan Training**: trocado de "Citizen" (136) pra **"Warrior" feminino
  (142)**, addons=3 (visual mais "equipada"). Cores reaproveitadas do
  `captain_breezelda.lua` (já usadas e renderizando certo no mesmo
  datapack).
- **Eva Buffet**: trocado de "Citizen" (136) pra **"Noblewoman" feminino
  (140)**, addons=3. Cores reaproveitadas do `alissa.lua` (mercadora com
  o mesmo outfit já em uso).

Reaproveitei combinações de cor já usadas em outros NPCs do datapack em
vez de inventar valores novos — outfit de NPC não tem risco de "sprite
faltando" que item tem (paleta de cor é sempre válida de 0-132), mas ainda
assim é o jeito mais seguro de garantir que fica com uma cara boa sem
precisar de confirmação visual antes.

Sincronizado os dois arquivos e servidor reiniciado, boot limpo. Não
testado ao vivo ainda.

## 2026-08-23 (5)

### Carmeni Tigers: The Cobra Amulet no tier 3 + pesos redistribuídos
Pedro pediu mais dois ajustes na Carmeni Tigers:
- Adicionado **The Cobra Amulet** (31631) no **tier 3 (Bom)**, junto do
  resto do set Cobra (axe/crossbow/wand/rod/bo) — mesma lógica usada pro
  Lion Amulet no tier 4 antes.
- Pesos por tier: Fraco 27->40, Mediano 43->35, Bom 25->20, Jackpot
  mantido em 5. Soma continua 100% (40+35+20+5=100), confirmado pro
  Pedro.

**Achado importante**: a tabela de pool/pesos existe **duplicada** em dois
arquivos — `npc/carmeni_tigers.lua` (usada pra descrever o item do dia em
diálogo) e `scripts/globalevents/carmeni_daily_roll.lua` (sorteia de
verdade 1x por dia, no horário de save). O próprio comentário no arquivo
já avisava disso ("se mudar uma, mude a outra"). Atualizei as duas juntas
pra não ficarem dessincronizadas — checar sempre os dois arquivos em
qualquer ajuste futuro desse NPC.

Sincronizado os dois arquivos e servidor reiniciado, boot limpo. O item
já sorteado hoje não muda até o próximo horário de save (o globalevent só
resorteia se `GlobalStorage.Carmeni.DailyItem` ainda não tiver sido
definido). Não testado ao vivo ainda.

## 2026-08-23 (4)

### Ajustes de preço/estoque: Elda Trinkets + Lion Amulet na Carmeni Tigers
Pedro pediu uma rodada de ajustes na loja de amuletos/anéis da **Elda
Trinkets** (`elda_trinkets.lua`):
- Adicionado **ring of healing** (3098) por 2000 gold — usei o mesmo preço
  que Yaman/Zuma Magehide já vendem esse item por no datapack, pra ficar
  consistente com a economia existente (Pedro não pediu um valor
  específico).
- **Might ring**: 3000 -> 6000 (dobrado).
- **Stone skin amulet**: 18000 -> 36000 (dobrado).
- **Shockwave amulet**: 35000 -> 25000.
- **Sacred tree amulet**: 35000 -> 25000.
- Adicionados **bonfire amulet** (9301) e **leviathan's amulet** (9303),
  25000 cada.
- Adicionado **amulet of loss** (3057) por 50000.

Também adicionado **Lion Amulet** (34158) no pool da **Carmeni Tigers**
(`carmeni_tigers.lua`, sistema de "achado do dia" — ver
`CARMENI_POOL`/`carmeni_daily_roll.lua`). Pedro só disse "itens vendidos
pelo NPC Tigers" sem especificar o tier — encaixei no **tier 4 (Jackpot,
200000 gold, 5% de chance no sorteio diário)** porque é exatamente onde já
estava o resto do "set Lion" (lion axe/longbow/wand/rod/claws) — mesma
coleção temática, só faltava o amulet.

Sincronizado os dois arquivos e servidor reiniciado, boot limpo (nenhum
warning novo de preço/NPC). Não testado ao vivo ainda.

## 2026-08-23 (3)

### Liane (NPC de parcels) recolocada no mapa
Pedro reportou que o NPC de envio de parcels tinha sumido. Não era bug
novo: a Liane (única NPC do datapack com a função de vender
label/letter/parcel e explicar o sistema `{mail}`) tinha sido removida de
propósito do `-npc.xml` em 22/08 (10), junto com outras renomeações — só
ninguém tinha reparado que isso também tirava a única fonte de parcels do
servidor. Achado bom no processo: já existe um mailbox de verdade
plantado em (980,987,7) e um item "parcel" de decoração em (980,990,7) —
ou seja, alguém já tinha montado uma salinha de correio, só faltava a
NPC.

Pedro pediu pra trazer ela de volta. `liane.lua` também não existia mais
dentro do container (só tinha sido removido o spawn, o arquivo local
ficou intocado) — copiado de volta via `docker cp` antes do restart.
Spawn novo: `centerx=982, centery=987, centerz=7` (dentro da salinha,
carpete livre a 2 tiles do mailbox). `sebastian_farwind.lua`/outros NPCs
removidos anteriormente não foram mexidos, só a Liane.

Sincronizado (`liane.lua` + `-npc.xml`) e servidor reiniciado, boot limpo
(o único erro no log, `NpcByTime: Failed to spawn:`, é recorrente desde
muito antes dessa mudança — sistema oficial de NPC por horário do
datapack, não relacionado). Não testado ao vivo ainda.

### Nome definitivo do NPC "Boatman" -> Sebastian Farwind
"Boatman" (chave dos orcs -> Mirror Island, ver
[[project-tibia-orc-quest-key-lore]]) era só nome provisório desde a
criação dele em 21/08. Pedro escolheu "Sebastian Farwind" — o mesmo nome
que já tinha ficado ali por engano em 22/08 antes de virar "Boatman"
(ver item acima, "Boatman recolocado no lugar do Sebastian Farwind").

**Achado que precisou de cuidado**: existia um `sebastian_farwind.lua`
antigo no datapack — um NPC genérico de capitão de navio, sem spawn desde
22/08, com viagens desativadas (coordenadas do mundo oficial). Ele
registrava `Game.createNpcType("Sebastian Farwind")`, e simplesmente
renomear o `boatman.lua` pra usar o mesmo nome interno criaria duas
definições conflitantes do mesmo NpcType. Removido o arquivo antigo (não
tinha spawn nem era referenciado em nenhum outro script — só ele mesmo e
o changelog) e renomeado `boatman.lua` -> `sebastian_farwind.lua`,
trocando `internalNpcName` pra "Sebastian Farwind" (mantida toda a lógica
da chave/storage/teleporte, intocada). Spawn atualizado no `-npc.xml`
((1032,986,7)) pro novo nome.

Sincronizado (removidos os dois arquivos antigos do container, copiado o
`sebastian_farwind.lua` novo + `-npc.xml`) e servidor reiniciado, boot
limpo — sem erro de NpcType duplicado nem de carregamento do npc.xml.
Não testado ao vivo ainda.

## 2026-08-23 (2)

### Escadas com desvio errado + gray sand voltou (3ª vez)
Pedro reportou que algumas escadas de descida jogam o jogador em lugar
errado — exemplo concreto: descida de (1117,1047,6) parava em
(1117,1047,7) em vez de (1117,1046,7).

**Causa raiz (mecânica que eu não tinha mapeado direito antes):** pra
rampa de descida (`floorchange="down"`), o desvio de destino **não vem
do item da própria rampa** — o motor (`Tile::queryDestination` em
`canary/src/items/tile.cpp`) olha se o tile **diretamente abaixo** do
ponto de queda tem, ele mesmo, uma flag de floorchange direcional
(north/south/east/west/southalt/eastalt). Sem isso, cai reto embaixo,
sem desvio nenhum. Fiz um script que reimplementa esse algoritmo
exatamente e rodei nas 110 rampas de descida do mapa inteiro: a grande
maioria (o "normal", sem reclamação) cai reto embaixo mesmo — é o
esperado pra buraco/escada vertical simples. Só um grupinho pequeno (as
que ficam perto de portas/salas específicas) tinha a peça direcional
certa no andar de baixo. Nenhuma colisão real de destino encontrada
(cada rampa cai num tile distinto).

Na posição reportada, já existia uma peça "ramp" (item 7545, variante
sem direção da família 7543-7549) bem em cima do ponto de queda —
faltava só ser a peça certa da família. Troquei:
- `(1117,1047,7)`: item 7545 -> **7546** (mesma peça visual, mas com
  `floorchange="south"`) -> agora (1117,1047,6) desce até (1117,1046,7).
- `(1117,1048,7)`: não tinha peça de rampa nenhuma, só chão quebrado ->
  adicionei 7546 -> agora (1117,1048,6) desce até (1117,1047,7).

Confirmado com reimplementação do algoritmo real antes de subir pro
servidor (não só testado no jogo).

**Gray sand, 3ª ocorrência:** ao inspecionar a área da escada achei o
mesmo bug de novo (ids 19271-19302), dessa vez 1653 tiles de ground e
2464 itens decorativos, floors 6/7/8. Mesma correção de sempre
(ground -> 422, remove itens soltos). Script:
`tools/otbm-tools/fix_gray_sand_v3_and_staircase.py`. Backup antes:
`MAPA OFICIAL DE TRABALHO.otbm.bak_staircase_offset_and_graysand_v3_*`.

**Para o Pedro**: são 3 rodadas agora por causa do brush "muddy
sand"/"gray sand" do RME — vale considerar remover esse brush da paleta
se der, já que sempre que ele é usado (ground ou decoração solta) quebra
o chão em runtime.

Ainda em aberto: Pedro mencionou que **outras** escadas (além dessa)
também têm problema — algumas "jogam dois esquemas pra frente", outras
com duas entradas de descida "vão parar no mesmo esquema". A varredura
completa das 110 rampas não achou nenhum destino colidindo de verdade,
então preciso das posições específicas dessas outras escadas pra
diagnosticar (provavelmente não são rampas `floorchange`, e sim outra
mecânica, tipo teleport).

## 2026-08-23 (1)

### Gray sand voltou (2ª vez) — dessa vez faixa maior, área nova pintada pelo Pedro
Ao investigar por que duas escadas de descida ((1117,1047,6) e
(1117,1048,6)) davam "not enough room" no destino, achei o mesmo bug do
"gray sand" de novo — mas **não era reversão do RME essa vez**, era área
nova que o Pedro pintou (confirmado: distribuição diferente da primeira
vez, floors 6 e 7 em vez de 6/7/8). Dessa vez usei toda a faixa que o
`items.xml` declara como "gray sand": **19271 a 19302** (a correção
anterior só cobria 19271-19278, os ids do brush "muddy sand" padrão do
RME — o Pedro também usou variantes soltas dentro da faixa mais ampla,
inclusive **como item decorativo em cima de outro chão**, não só como
ground).

Corrigido: 1635 tiles de ground (19271-19302 -> 422, mesma troca já
comprovada ao vivo) + 2434 itens decorativos soltos na mesma faixa
removidos (só textura, sem função — mesmo risco de não renderizar/travar
que o ground). Script: `tools/otbm-tools/fix_gray_sand_v2.py`. Backup
antes: `MAPA OFICIAL DE TRABALHO.otbm.bak_graysand2_*`.

**Para o Pedro**: se pintar chão novo de novo, **evitar o brush "muddy
sand"/"gray sand"** — é o único ground brush do RME confirmado quebrado
nesse servidor (existe no `items.xml` com nome válido, mas não carrega
como chão de verdade no Canary em runtime). Já são 2 rodadas de correção
por causa desse brush especificamente.

Confirmado também as duas rampas de descida da pergunta original: ambas
com `floorchange` correto e destino válido depois do fix. Sincronizado e
servidor reiniciado, boot limpo.

## 2026-08-22 (20)

### Mirror's Shadow: roteamento pra ilha clonada a partir da 2ª visita
Pedro construiu a segunda ilha (clone "resolvido") ele mesmo no RME — achei
via scan do mapa: corpo de "dead medusa" (item 9607) em (910,222,7),
pequena ilha própria em torno de x903-919/y218-230, separada da ilha
original. Escolhido (910,225,7) como ponto de chegada (chão limpo, perto
do corpo).

Atualizado `boatman.lua`: storage nova por jogador (900002,
`STORAGE_SECRET_ISLAND_VISITED`) marca a primeira vez que o jogador cai na
ilha secreta. Da segunda visita em diante (mesmo jogador), o sorteio de 5%
sempre manda pra ilha clonada em vez da original — Gorgo já morto, Corwin
não está mais lá. Cada jogador tem sua própria contagem, não é estado
compartilhado do mundo.

Sincronizado e servidor reiniciado, boot limpo. Não testado ao vivo ainda
(precisa cair na ilha 2x com a mesma conta pra confirmar o roteamento).

## 2026-08-22 (19)

### Castaway Corwin: visual de machucado + teleporte de fuga da ilha
Pacote completo de 5 itens pra deixar o Corwin visualmente ferido:
1. Barra de vida parcial (health 25/100).
2. Outfit trocado pro "Beggar" real do Tibia (lookType 157).
3. Efeito visual de dor ocasional (`CONST_ME_DRAWBLOOD`, ~1/30 chance por
   tick de onThink).
4. Falas de dor aleatórias via `npcConfig.voices` ("Ngh... my leg...",
   etc), intervalo 15s / 15% chance.
5. Gauze bandage (9649) + mancha de sangue (item 5) no chão do lado dele,
   (914,257,7) e (913,258,7).

**Teleporte de fuga da ilha**: achei o teleporte (item 1949) já colocado
em (908,251,7) — o "guardado por aquela coisa" que o Corwin menciona na
fala. Destino configurado pra (811,219,7), o mesmo ponto de chegada da
Mirror Island.

Backup do `.otbm` antes: `MAPA OFICIAL DE TRABALHO.otbm.bak_corwin_*`.
Sincronizado e servidor reiniciado, boot limpo.

## 2026-08-22 (18)

### Mirror's Shadow (ilha secreta): destino, NPC preso, item no corpo, destroços
Pedro passou a posição da ilha secreta e pediu 3 coisas:

1. **Destino real**: `SECRET_ISLAND_DESTINATION` no `boatman.lua` trocado
   do placeholder (templo) para (911,260,7) — confirmado que o tile já
   existe e é chão válido.
2. **Item dentro do corpo já existente na ilha** ("dead human", item 6560,
   em 912,257,7): colocado um **Haunted Mirror Piece** (19373) — sugestão
   minha, gancho de lore (mitologia clássica de espelho vs. Medusa, e o
   Castaway Corwin já menciona um guardião "de olhos amaldiçoados"). Como
   `otbm.py` não edita conteúdo de container e o item 6560 tem
   `decayTo`/`duration` no `items.xml` (risco do prop apodrecer e levar o
   item junto), implementado via script (`onStartup`) em vez de gravado
   direto no mapa — `mirror_shadow_corpse_item.lua`, garante o item lá
   toda vez que o servidor sobe, idempotente (não duplica se já existe).
3. **NPC preso**: criado **Castaway Corwin** (`npc/castaway_corwin.lua`),
   parado (sem andar, condizente com a perna quebrada que ele menciona na
   própria fala), em (913,257,7) — do lado do corpo. Fala exata (a que o
   Pedro já tinha definido em conversa anterior) direto no `MESSAGE_GREET`,
   sem loja, sem quest ainda — só o monólogo.
4. **Destroços do barco** (sugestão minha, decoração): "wrecked ship cabin
   wall" (5449) em (909,260,7) e "wrecked figurehead" (5450) em
   (910,261,7), encostados na praia perto do ponto de chegada.

Backup do `.otbm` antes: `MAPA OFICIAL DE TRABALHO.otbm.bak_mirrorshadow_*`.
Sincronizado tudo (mapa + npc.xml + 2 lua novos + boatman.lua) e servidor
reiniciado — boot limpo, nenhum warning do script de startup (significa
que achou o corpo e não precisou reclamar). Não testado ao vivo ainda.

## 2026-08-22 (17)

### Boatman recolocado no lugar do Sebastian Farwind
Pedro reportou o Sebastian Farwind com o diálogo errado ("deveria ter as
opções sobre a chave dos orcs"). Não era bug de diálogo — é confusão de
NPC: o `boatman.lua` (criado em 2026-08-21, já tinha exatamente a fala que
o Pedro descreveu: saudação, recusa sem a "bone key", primeira viagem
consome a chave, viagens seguintes) **não tinha spawn no `-npc.xml`**
(sumiu, mesma classe do bug de RME sobrescrevendo já visto hoje). O Pedro
confirmou que a posição do Sebastian (1032,986,7) sempre foi pra ser o
Boatman. Trocado `name="Sebastian Farwind"` -> `name="Boatman"` nesse
spawn. `sebastian_farwind.lua` continua no datapack, só sem spawn agora
(mesmo tratamento dado à Liane antes).

Confirmado que `MIRROR_ISLAND_DESTINATION` (811,219,7) já estava
corretamente configurado no `boatman.lua` desde 08-21 — tile ainda válido,
não precisou de coordenada nova. `SECRET_ISLAND_DESTINATION` continua
placeholder (templo) — a ilha secreta (Mirror's Shadow) ainda está sendo
construída pelo Pedro. Pendente: NPC preso na ilha secreta (fala já
fornecida pelo Pedro, falta nome + posição + a ilha em si existir) — vai
ser implementado quando a ilha estiver pronta.

Sincronizado (npc.xml + boatman.lua) e servidor reiniciado, boot limpo.

## 2026-08-22 (16)

### Level mínimo dos 3 portões: 100 -> 150
Pedro concordou que a sala do boss (Ashmunrah + Mahrdis + Dragon Lord + 2
Dragons + 4 Flamethrowers) estava pesada demais pra level 100 e decidiu
subir a trava. Action ID dos 3 portões em (1182,1095-1097,9) trocado de
1100 para **1150** (regra `1000 + nível`). Backup:
`MAPA OFICIAL DE TRABALHO.otbm.bak_gates150_*`. Sincronizado e reiniciado,
boot limpo.

## 2026-08-22 (15)

### Rede de teleportes + baús de recompensa da quest atrás dos portões
Pedro descreveu a estrutura da quest nova (atrás dos 3 portões de level
100): entrada -> sala intermediária -> sala final do boss -> volta pro
templo. 4 teleportes (item 1949) já estavam colocados no mapa, só
faltando o destino:

- (1213,1096,9) -> (1252,1096,9) — entrada. Tinha um `tele_dest` órfão
  apontando pra uma coordenada do mundo oficial (33259,32707,13), trocado.
- (1252,1097,9) -> (1211,1096,9) — retorno pra sala anterior.
- (1252,1114,9) -> (1251,1131,9) — acesso à sala final do boss.
- (1252,1143,9) -> (1000,1000,7) — saída final, volta pro templo de
  Skartholt. Também tinha um UID órfão (3952) do mapa oficial, limpo.

**5 baús de recompensa** (item 2472) inseridos na sala final do boss —
posições escolhidas dentro da área aberta central, evitando paredes/
decoração já existente: (1247,1131,9) / (1255,1136,9) / (1247,1139,9) /
(1255,1139,9) / (1251,1136,9). Cada um independente (sem grupo/trava
compartilhada), Action IDs 24901-24905 (confirmado livre em scripts E no
mapa antes de usar, seguindo o aviso já documentado no cabeçalho do
`custom_reward_chests.lua` sobre colisão de Action ID). Recompensa de cada
baú: 1 peça de equipamento + 250k gold (25x crystal coin):
- 24901: Helmet of the Ancients
- 24902: Prismatic Helmet
- 24903: Gill Gugel
- 24904: Dark Vision Bandana
- 24905: Dark Whispers

Script: `tools/otbm-tools/fix_boss_room_teleports_chests.py`. Backup antes:
`MAPA OFICIAL DE TRABALHO.otbm.bak_bossroom_*`. Sincronizado e servidor
reiniciado, boot limpo. Não testado ao vivo ainda.

## 2026-08-22 (14)

### 3 portões com level mínimo 100 (hunt nova, embaixo do teleporte da tumba)
Pedro construiu uma hunt nova logo abaixo do destino do teleporte da tumba
((1167,1082,8)) com uma quest acessada atravessando 3 portões, e queria o
mesmo critério de level já usado na quest dos Orcs no passado. Achei os 3
portões em (1182,1095,9)/(1182,1096,9)/(1182,1097,9) — item "gate of
expertise" (id 1664), que já faz parte do `LevelDoorTable` em
`data/libs/tables/doors.lua` (sistema pronto do datapack, mecanismo em
`data/scripts/movements/closing_door.lua`). Bastou setar o Action ID de
cada porta pra `1000 + nível` — nível 100 = Action ID **1100**. Sem
precisar escrever script novo.

Backup antes: `MAPA OFICIAL DE TRABALHO.otbm.bak_gates_*`. Sincronizado e
servidor reiniciado, boot limpo. Não testado ao vivo ainda.

## 2026-08-22 (13)

### Retorno da tumba + segunda rodada de renomeações revertidas pelo RME
Pedro construiu a sala da tumba em (1167,1082,8) com chama de retorno
("mystic flame", id 1959) em (1168,1082,8) e salvou no RME.

**Retorno da tumba implementado**: reaplicado o UID customizado do basin
(9039->60000, tinha revertido — ver abaixo), atribuído UID 60001 pra chama
de retorno, e criado `movements_skartholt_tomb_return.lua` — passo simples
na chama teleporta de volta pra (1014,1009,7), fora da entrada da tumba
original.

**Achado importante — mesmo problema de antes (RME sobrescrevendo mudança
feita fora do RME), mas dessa vez pegou coisa funcional, não só cosmética**:
o save do Pedro reverteu o `-npc.xml` pra uma versão de antes do segundo
lote de renomeações (Elda/Eva/Luna/Rojan/Haani/King Skartholt/remoção da
Liane) — só sobreviveram Captain Windrift e Carmeni Tigers (primeiro
lote). Como os arquivos `.lua` antigos desses NPCs foram **removidos** do
container quando renomeei, o nome no `-npc.xml` não batia mais com nenhum
NPC registrado — ou seja, **Elda, Eva, Luna, Rojan, Haani, King Skartholt e
Sebastian Farwind não estavam spawnando de verdade** até essa correção. O
UID customizado do coal basin (60000) também tinha revertido pra 9039
(oficial, quebrado). Reaplicado tudo, backup do `.otbm` antes:
`MAPA OFICIAL DE TRABALHO.otbm.bak_tomb2_*`.

**Achado bom no meio disso**: apareceu uma "Skartholt House #2" (154 SQM,
rent 120000, entryx=1022/entryy=1019/entryz=7) que o Pedro criou e que
sobreviveu certinho ao save.

**Padrão a vigiar (2ª vez que acontece)**: qualquer mudança feita direto em
`.otbm`/`-npc.xml`/scripts *fora* do RME (via Python ou edição manual de
arquivo) fica em risco de ser revertida se o Pedro tiver uma sessão do RME
aberta de antes daquela mudança e salvar por cima. Recomendação prática:
depois de qualquer edição minha direto no arquivo, avisar o Pedro pra
fechar e reabrir o mapa no RME antes de continuar editando nele, ou pelo
menos checar com ele se a sessão do RME já estava aberta antes da mudança.

Sincronizado (mapa + script de retorno + npc.xml corrigido) e servidor
reiniciado, boot limpo. Não testado ao vivo ainda (entrada nem retorno da
tumba, nem os NPCs re-corrigidos).

## 2026-08-22 (12)

### Entrada de tumba: coal basin + scarab coin -> teleporte
Pedro copiou um coal basin (item 2114, uid 9039) + mystic flame de uma
entrada de tumba oficial de Ankrahmun pro mapa custom
((1014,1010,7)/(1014,1011,7)) e queria a mecânica clássica: colocar scarab
coin em cima do basin, ficar na chama, teleportar.

**Achado bom**: essa mecânica já existe pronta no datapack —
`scripts/quests/the_ancient_tombs/movements_all_teleports_tombs_coal_basin.lua`,
parte da quest oficial "The Ancient Tombs". Só precisou registrar uma
entrada nova, não escrever a lógica do zero.

O UID 9039 do basin copiado era o mesmo id oficial já cadastrado nesse
script apontando pra uma posição do mundo oficial (não existe aqui) —
trocado pra UID customizado `60000` (não usado em nenhum outro tile do
mapa, conferido antes) pra não colidir com a entrada oficial. Nova
entrada no config do script: uid 60000 -> flame em (1014,1011,7), destino
(1167,1082,8).

**Pendências que o Pedro ainda precisa resolver**:
1. `(1167,1082,8)` (destino do teleporte) **ainda não existe no mapa** —
   tile totalmente vazio hoje. O basin já vai teleportar pra lá assim que
   testado, mas vai cair no vazio até essa sala ser construída.
2. Combinado o retorno numa "chama azul" em `(1168,1082,8)` — **também não
   existe ainda**. Falta implementar esse movimento de volta; só dá pra
   fazer depois que o Pedro colocar o item de chama lá de verdade (provável
   candidato: mesmo item "mystic flame", id 1959, usado na entrada).

Backup do `.otbm` antes: `MAPA OFICIAL DE TRABALHO.otbm.bak_tomb_*`.
Sincronizado e servidor reiniciado, boot limpo. Não testado ao vivo ainda.

## 2026-08-22 (11)

### Primeira casa do servidor: Skartholt House #1
Pedro construiu a primeira sala pra virar casa comprável e pediu ajuda pra
entender o sistema (SQM, vínculo com jogador, compra). Casa criada no RME:
94 SQM, town "Skartholt" (única cidade cadastrada), rent 80000, Client ID
1, porta em (1014,1020,7), saída em (1014,1019,7) — confirmado com
`otbm.py` que a saída fica fora dos tiles da casa (correto) e que a porta
tem `house_id=1` (correto). Uma casa vazia acidental ("Unnamed House #2")
apareceu no meio do processo e foi removida pelo Pedro.

**Dificuldade no meio do caminho**: a saída não gravava mesmo depois do
Pedro clicar em "Select Exit" — descobri lendo o código-fonte do RME
(`palette_house.cpp`) que esse botão só *ativa um modo*, é preciso clicar
no tile de verdade no mapa depois pra gravar (`House::setExit`). Resolvido
depois que o Pedro clicou no tile e salvou de novo.

**Sistema de compra**: confirmado no `config.lua` do servidor que
`houseRentPeriod = "monthly"` (não semanal). Tentamos primeiro o sistema
de leilão da Cyclopedia (`toggleCyclopediaHouseAuction = true`, padrão do
servidor) — mas a janela mostrou "Cozy Cottage"/"Merchant's Haven" com
prazo de leilão absurdo (negativo), que investiguei e são dados de
exemplo **fixos no próprio client OTClient** (`game_cyclopedia/utils.lua`),
não dados reais do servidor. Ou seja, a Cyclopedia não estava mostrando a
casa de verdade. Trocado pra `toggleCyclopediaHouseAuction = false`, que
habilita o comando clássico `!buyhouse` (mais simples de testar/confirmar
pra um servidor privado pequeno). `houseBuyLevel = 100` e `freePremium = true`
já configurados no servidor. Compra feita ficando parado no tile de saída,
olhando pra porta, digitando `!buyhouse` — desconta do banco, não da bolsa.

Ainda não testado ao vivo (compra em si) — falta o Pedro tentar com uma
conta que tenha gold no banco.

## 2026-08-22 (10)

### Mais renomeações + remoção da Liane + doação de outfit dourado removida
- **Luna -> Luna Foods**, **Rojan -> Rojan Training**, **Haani -> Haani
  Homes** (renomeação simples: arquivo + `internalNpcName` + `-npc.xml`).
- **King Tibianus -> King Skartholt** (nome da cidade custom). Também
  atualizada a fala de auto-apresentação ("I am your sovereign, King
  Skartholt..."). As referências a `Storage...KingTibianus` (chave de
  storage da quest "The New Frontier") foram mantidas — são identificador
  técnico, não texto de jogador, mudar isso quebraria a leitura da storage.
- **Removida a doação de outfit dourado** do King Skartholt (pedia até 1
  bilhão de gold por um outfit/addon, ligado a `Storage.Quest.U12_15.GoldenOutfits`).
  Removido o trigger da keyword "outfit"/"addon" e toda a lógica de
  armor/helmet/boots (topics 1-5 do `creatureSayCallback`); mantida intacta
  a questline "The New Frontier" (farmine/flatter, topics 6/10) e o sistema
  de promoção, que não têm relação com o outfit dourado.
- **Liane removida do mapa** — tirado o spawn dela do `-npc.xml`. O
  arquivo `liane.lua` do datapack original ficou intocado (só não tem mais
  spawn, então não existe mais em jogo — mesma lógica de qualquer um dos
  ~600 NPCs do datapack que nunca foram colocados no mapa).

**Nota técnica**: `king_tibianus.lua`, `luna.lua` e `haani.lua` estavam
salvos com quebra de linha CRLF (Windows) em vez de LF — a ferramenta de
edição de texto não confiava em correspondência exata de string nesses
arquivos por causa disso. Precisei editar via script Python em modo binário
pra esses três (`rojan.lua` era LF normal, editado direto). Vale saber
disso se aparecer o mesmo problema em outro arquivo do datapack no futuro.

Arquivos renomeados: `king_tibianus.lua`→`king_skartholt.lua`,
`luna.lua`→`luna_foods.lua`, `rojan.lua`→`rojan_training.lua`,
`haani.lua`→`haani_homes.lua`. Tudo sincronizado no container, servidor
reiniciado, boot limpo (sem erro de sintaxe Lua na edição manual do
King Skartholt, que foi a mais arriscada).

## 2026-08-22 (9)

### Mais renomeações: Elda, Eva e Sebastian (Nargor)
- **Elda -> Elda Trinkets** (joalheira, vende anéis/amuletos/plasma set).
- **Eva -> Eva Buffet** (NPC do banco — trocadilho com Warren Buffet, ideia
  do Pedro).
- **Sebastian (Nargor) -> Sebastian Farwind**. Esse arquivo é um dos *dois*
  "Sebastian" do datapack (`sebastian.lua` e `sebastian_nargor.lua`,
  mesmo `npcConfig.name` mas `Game.createNpcType` com chaves diferentes pra
  não colidir — padrão comum quando o Tibia oficial tem o mesmo nome em
  cidades diferentes). Só mexi no `_nargor`, o `sebastian.lua` original
  ficou intocado. Mesmo problema do Captain Windrift: viagem pra Liberty
  Bay/Meriana usava coordenada do mundo oficial — desativado e trocado por
  fala genérica em inglês (mesma frase do Windrift). **Esse NPC não tem
  spawn no mapa ainda** (não achei entrada `Sebastian` no `-npc.xml`) — só
  preparei o script, falta o Pedro posicionar ele no RME quando quiser.

Arquivos renomeados: `elda.lua`→`elda_trinkets.lua`,
`eva.lua`→`eva_buffet.lua`, `sebastian_nargor.lua`→`sebastian_farwind.lua`.
`-npc.xml` atualizado (Elda e Eva já tinham spawn). Arquivos antigos
removidos do container antes dos novos. Servidor reiniciado, boot limpo.

## 2026-08-22 (8)

### Renomeados: Captain Greyhound -> Captain Windrift, Carmeni -> Carmeni Tigers
Renomeação simples, dois NPCs: arquivo + `internalNpcName`/`npcConfig.name`
+ o `name=` correspondente no `-npc.xml` do mapa (Captain Greyhound tinha
2 spawns, em (1032,1011,6) e (1129,937,7) — ambos atualizados). Arquivos
renomeados também: `captain_greyhound.lua` -> `captain_windrift.lua`,
`carmeni.lua` -> `carmeni_tigers.lua`. Arquivos antigos removidos do
container antes de copiar os novos, pra não sobrar NPC fantasma com nome
velho. Servidor reiniciado, boot limpo.

## 2026-08-22 (7)

### Carmeni em inglês + Captain Greyhound sem destinos quebrados
Pedro salvou uma versão nova do mapa no RME (implementações próprias) e
pediu dois ajustes de NPC:

- **Carmeni** — toda a fala (greeting, expedição, farewell, mensagens de
  compra) traduzida de PT-BR pra inglês. Comentários no código continuam
  em PT-BR (não é texto de jogador).
- **Captain Greyhound** (adicionado pelo Pedro a partir do datapack
  global) — o script original vem com 6 destinos (Thais/Ab'Dendriel/
  Edron/Venore/Svargrond/Yalahar) usando coordenadas do mundo oficial do
  Tibia, que não existem neste mapa customizado — e um "kick" que também
  teleportava pra coordenada oficial quebrada. Removida toda a lógica de
  `StdModule.travel`/`StdModule.kick` com essas posições; as palavras-chave
  de viagem (sail/trip/passage/town/destination/go/route) agora respondem
  com uma linha padrão em inglês: destinos ainda não existem, serão
  adicionados quando as cidades customizadas forem construídas (item já
  pendente na lista de melhorias do mapa). Mantido o resto da
  personalidade dele (name/job/ship/company etc) intacto.

Mapa + os dois scripts sincronizados no container e servidor reiniciado,
boot limpo. Não testado ao vivo ainda.

## 2026-08-22 (6)

### Corrigido "água" intransponível na hunt de scarab (floor 6/7/8)
Pedro reportou água aparecendo na hunt de scarab, não só visual — impossível
de andar ali. Mesma classe de bug do `fix_ground_20888.py` (item 20888):
o ground usado (`19271-19278`, brush "muddy sand" no RME, item "gray sand"
no `items.xml`) **existe** no `items.xml` com nome válido, mas não carrega
como chão de verdade no Canary em runtime — os flags reais de "isGroundTile"
vêm de um dado de appearance separado (binário, não é o `items.xml` texto),
que não dá pra inspecionar por grep. Só descobrimos porque o Pedro confirmou
ao vivo que não conseguia andar ali (mesmo diagnóstico que da vez passada).

Troquei `19271-19278` → `9246` ("earth") em todo o mapa — não só na área
reportada, esse ground aparecia nos floors 6 (71 tiles), 7 (153) e 8 (1668).
Escolhi 9246 porque já era o ground mais usado bem do lado, já comprovado
funcionando (não foi reportado como quebrado).

Script: `tools/otbm-tools/fix_gray_sand.py`. Backup antes:
`meu-mapa/MAPA OFICIAL DE TRABALHO.otbm.bak_graysand_20260822_*`. Mapa
sincronizado e servidor reiniciado, mas não confirmado visualmente ainda —
falta o Pedro checar ao vivo depois de relogar.

**Padrão a vigiar**: qualquer ground "bonito" no RME que nunca foi
confirmado funcionando ao vivo neste servidor é suspeito, mesmo que exista
no `items.xml` com nome válido — existir no items.xml não é garantia (2ª
vez que isso acontece). Só confiar em ground já visto funcionando ao vivo.

**Correção do dia seguinte (mesmo dia)**: a troca por `9246` deu errado —
9246 não é chão, é o brush **"earth mountain"** do RME (parede rochosa,
bloqueia passagem). Confiei em "é o id mais comum do lado" como prova de
"chão seguro", sem checar se esse id era ele mesmo um brush de parede — foi
exatamente o erro #1 que o skill de mapa já documentava (confundir peça de
borda/parede com chão). Revertido pro backup de antes do fix (volta a
"água", pelo menos não bloqueia visualmente uma área enorme como parede
sólida). Pedro confirmou no RME (Properties do tile) que o chão andável de verdade
ao lado é `422`. Reaplicado o fix com `19271-19278 -> 422` (dessa vez com
dado real, não chute) e reimplantado no servidor. Backup antes desta
segunda tentativa: `MAPA OFICIAL DE TRABALHO.otbm.bak_graysand2_*`.
**Confirmado ao vivo pelo Pedro** — hunt de scarab andável normalmente.

## 2026-08-22 (5)

### Nota: barco/decoração do pátio do Yasir (entrada (2)) foram removidos de propósito
O barco novo e os caixotes/barris/rede de pesca adicionados via script na
entrada 2026-08-22 (2) sumiram depois de o Pedro salvar o mapa no RME.
Achei que era o RME tendo sobrescrito por cima (script escreveu direto no
`.otbm`, sem passar pela sessão do RME) e cheguei a montar um script pra
repor o barco — mas o Pedro confirmou que **apagou de propósito porque não
gostou**. Não é bug, não precisa repor. Deixando registrado pra não
tentar "consertar" isso de novo numa sessão futura.

## 2026-08-22 (4)

### Carmeni: trocado fluxo de compra por keyword pela janela de trade nativa
Pedro pediu um fluxo mais parecido com NPC comum: ao dar {greet}/interagir,
ele fala uma linha sobre a expedição do dia (sem revelar o item ainda), e
o jogador vê o item de verdade dando **Trade** nele, como em qualquer
mercador do jogo. Reescrito `carmeni.lua`: removido o fluxo antigo de
keyword "expedição" + confirmação "sim/não", trocado por
`npc:openShopWindowTable(player, items)` — API nativa que abre a janela de
trade com uma lista montada na hora (achei em
`src/lua/functions/creatures/npc/npc_functions.cpp`), reconstruída a cada
pedido de trade com o item sorteado do dia. `npcConfig.shop` fica vazio de
propósito, pra nunca ter itens de dias antigos disponíveis. O keyword
"expedição" continua funcionando como consulta opcional (fala o que tem
sem abrir a janela), mas não é mais necessário pra comprar.

## 2026-08-22 (3)

### NPC Carmeni: aventureiro que vende 1 item raro por dia
Implementado o NPC "Carmeni" (posição x=1030, y=999, z=7, na área do porto
perto do Yasir) — um aventureiro que sorteia 1 item por dia entre 4 faixas
de raridade e vende só esse item, pra qualquer classe, a um preço fixo por
faixa. Ideia original do Pedro: incentivar comércio/troca entre jogadores,
já que o item do dia pode não ser da vocação de quem compra.

**Faixas (chance / preço):**
- Fraco: 27% / 25.000g — Executioner (K), Elethriel's Elemental Bow (P),
  Dream Blossom Staff (S), Glacial Rod (D), Sai (M)
- Mediano: 43% / 60.000g — Warlord Sword (K), Royal Crossbow (P), Jungle
  Wand (S), Jungle Rod (D), Depth Claws (M)
- Bom: 25% / 120.000g — família Cobra (Axe/Crossbow/Wand/Rod/Bo)
- Jackpot: 5% / 200.000g — família Lion (Axe/Longbow/Wand/Rod/Claws)

Os itens de Bom/Jackpot foram escolhidos usando famílias reais do Tibia que
a CipSoft desenhou pra serem equivalentes entre vocações (mesmo nível, mesmo
boss de origem) — evita o problema de uma vocação sair ganhando um item
desproporcionalmente mais forte que as outras no mesmo sorteio (chegamos a
cogitar a família Sanguine nível 600 pro Jackpot, mas o Pedro preferiu
descer a régua pra evitar um item forte demais pra virar sorteio).

**Implementação técnica:**
- `canary/data-otservbr-global/npc/carmeni.lua` — NPC com fluxo de
  keyword+topic (pergunta "{expedição}", ele diz o item do dia e o preço,
  jogador confirma com "sim"). Sem usar o shop window nativo (que é
  estático) — decisão deliberada pra controlar o sorteio dinâmico e o
  limite de compra sem precisar mexer na API de shop em runtime.
- `canary/data-otservbr-global/scripts/globalevents/carmeni_daily_roll.lua`
  — sorteia o item às mesmas horas do server save diário
  (`configKeys.GLOBAL_SERVER_SAVE_TIME`), grava em
  `GlobalStorage.Carmeni.DailyTier/DailyItem`.
- O próprio NPC também sorteia sozinho (`ensureDailyItemRolled`) se ainda
  não tiver nenhum item sorteado (ex: primeiro boot do servidor, antes do
  primeiro save) — evita loja vazia.
- Limite de 1 compra por personagem por dia via
  `Storage.Carmeni.LastBuyDate` (per-player, compara com a data atual).
- Storage keys novas em `lib/core/storages.lua`: `GlobalStorage.Carmeni.*`
  (65100-65101) e `Storage.Carmeni.LastBuyDate` (900000) — ambas em faixas
  confirmadas livres (grep no arquivo inteiro antes de escolher).
- Spawn registrado em `meu-mapa/MAPA OFICIAL DE TRABALHO-npc.xml`. Posição
  conferida antes (tile livre, ground de madeira do píer, sem conflito com
  a decoração colocada no registro anterior).

**Não testado ao vivo ainda** — precisa de restart completo do servidor
(NPC novo + globalevent novo + storages novas só carregam no boot).

## 2026-08-22 (2)

### Porto do Yasir: barco novo ao sul + decoração no pátio vazio
Pedro achou o pátio a leste do depósito meio vazio (x~1019-1034, y~977-1002,
z=7) e pediu pra eu dar mais vida, colocando outro barco ao sul. Antes de
escrever qualquer coisa, escaneei o `.otbm` (leitura, via `otbm.py`) pra
achar o que já existe de verdade nessa vizinhança — a região mais ampla
tinha uma área completamente não relacionada (conteúdo de quest tipo
"Exaltation Forge"/cristais) bem colada, então tive que restringir bastante
o raio antes de tocar em qualquer coisa.

Achado: o barco pequeno já existente (coluna x=1033, y≈984-1000) é feito só
com itens decorativos empilhados sobre o ground que já estava lá — não é
nenhum sistema especial, só `small boat` (1755/1757/1758/1759) + `small
sail` (1766) + `anchor` (4973) + `hawser`/corda (4978/4979/4982) + `bollard`
(4972). Repliquei o mesmo padrão numa coluna nova (x=1026), começando com
uma amarração em terra (y=1000-1002, no chão que já é `1771`) e o casco
indo pra dentro d'água (y=1003-1008) até a proa com vela, sem mexer em
nenhum ground — só empilhei item em cima do que já existia.

Também espalhei 8 props decorativos (caixote 2471, barril 2523, rede de
pesca 2745/2748/2750) pelo pátio vazio, só em tiles que não tinham nenhum
item ainda (2 posições planejadas foram puladas automaticamente por já
terem item).

Script fica salvo em `tools/otbm-tools/fix_porto_yasir.py` (registro do que
foi feito, não é reutilizável pra outra área sem ajustar coordenadas).
Backup antes da mudança: `meu-mapa/MAPA OFICIAL DE TRABALHO.otbm.bak_porto_20260822_071652`.

**Não testado ao vivo ainda** — mudança de mapa só é aplicada com restart
completo do servidor, que o Pedro ainda não tinha feito no momento deste
registro. Também não confirmado visualmente no RME ainda.

## 2026-08-22 (1)

### Vitrine do Yasir também marcada como fixa
Pendência da entrada de 2026-08-21 (15) resolvida: Pedro confirmou que o
conjunto demon shield/golden armor/skull helmet (x995-997/y1011) é vitrine
do NPC Yasir. Marcados os 3 itens com Action ID 100
(`IMMOVABLE_ACTION_ID`), mesmo mecanismo engine-level das outras bancadas
— sem script novo. Feito manualmente no RME (Properties de cada item),
mapa salvo. Servidor ainda não reiniciado no momento deste registro —
mudança de mapa só é aplicada com restart completo, não `/reload`.

## 2026-08-21 (18)

### Elda: set completo de plasma (Falcon Bastion), um por vocação
Adicionados os 8 itens do set de plasma — anel + colar de cada cor
(vermelho=Knight, azul=Paladin, verde=Sorcerer/Druid, laranja=Monk),
travados por vocação no próprio item. **Diferente do resto da loja**:
são temporários (30min equipado, depois viram pó sozinhos) — no Tibia
oficial nenhum NPC vende isso normalmente, só quest, então não tinha
preço de referência real pra copiar. Preço estimado pensando na natureza
consumível: 5000g (anel) / 8000g (colar).

Testado ao vivo, sem erro.

## 2026-08-21 (17)

### Elda: mais 4 amuletos elementais (set clássico)
Adicionados Glacier Amulet, Lightning Pendant, Magma Amulet e Terra
Amulet — 1000g cada (preço de memória, sinalizar se errado). Loja da
Elda agora com 11 itens. Testado ao vivo, sem erro.

## 2026-08-21 (16)

### Elda: catálogo expandido (5 itens novos de joalheria)
Adicionados Energy Ring (1500g), Life Ring (1500g), Time Ring (5000g),
Shockwave Amulet (35000g) e Sacred Tree Amulet (35000g) — preços de
memória (Tibia Global), sinalizar se algum estiver errado. Loja da Elda
agora com 7 itens: os 5 novos + Might Ring e Stone Skin Amulet.

Testado ao vivo, sem erro.

## 2026-08-21 (15)

### Itens de vitrine (bancada dos NPCs) agora são fixos
Pedro percebeu que os itens de exemplo nas bancadas dos NPCs (potes/runas
do Asnarus, flechas/besta do Archery, ferramentas da Sarina) podiam ser
roubados pelos jogadores. Achada uma solução nativa do motor: existe uma
constante `IMMOVABLE_ACTION_ID` (valor 100) já usada em outros lugares do
datapack — qualquer item com esse Action ID fica impossível de mover/
pegar/girar (bloqueio no `data/events/scripts/player.lua`, engine-level).
Marcados os 9 itens identificados nas 3 bancadas (Asnarus, Archery,
Sarina) com esse Action ID direto no `.otbm`, sem precisar escrever
script nenhum.

**Não mexido**: achei um conjunto de armadura (demon shield/golden armor/
skull helmet, x995-997/y1011) que parece bancada de exibição também, mas
não corresponde a nenhum NPC de fato posicionado no mapa vendendo esses
itens — deixei de fora até confirmar com o Pedro se é de algum NPC
específico ou só decoração solta.

Backup do `.otbm` antes da mudança: `MAPA OFICIAL DE TRABALHO.otbm.bak5`.
Testado ao vivo, sem erro.

## 2026-08-21 (14)

### Testserver Assistant renomeado para Blessing Merchant; Elda criada
"Testserver Assistant" (o único NPC do mapa relacionado a bênção — na
verdade dá bless/money/exp/reset de graça, ferramenta de teste) renomeado
pra **Blessing Merchant**, a pedido. Só troca de nome, funcionalidade
igual — sinalizado pro Pedro que ele faz mais que só bênção, caso queira
separar depois.

Criado NPC **Elda** (posição 1021,991,7), vendendo só Might Ring (3000g)
e Stone Skin Amulet (18000g) — removidos da loja da Sarina, que volta a
vender só backpacks/ferramentas gerais.

**Nota de processo**: a renomeação do Testserver Assistant tinha sido
feita direto no `-npc.xml` antes, mas sumiu — o RME resalvou o arquivo
por cima antes de eu sincronizar (não fechou/reabriu entre uma coisa e
outra). Refeita a mudança em cima do estado mais recente do arquivo.

Testado ao vivo, sem erro.

## 2026-08-21 (13)

### Rojan reconstruído: vende os itens reais de exercise weapon (3 tiers)
Pedro apontou que eu estava reinventando a roda — não precisava de sistema
de "bulk order" customizado, o Tibia oficial já tem os 3 tiers como itens
separados de verdade: **exercise** (500 cargas), **durable exercise**
(1800 cargas) e **lasting exercise** (14400 cargas), cada arma/escudo/wraps
em cada tier. Como cada tier é um item id diferente, some completamente o
problema de preço-por-id que motivou o sistema customizado nas duas
tentativas anteriores (agora abandonadas) — voltou a ser loja padrão
simples, 24 itens.

Preços: exercise 2kk, durable exercise 5kk, lasting exercise 10kk (o
último confirmado pelo Pedro batendo com Tibia Global; os outros dois são
de memória, sinalizar se estiver errado). Removidas as "training weapons"
antigas (28540-28545) que eu tinha usado por engano na primeira tentativa
— eram de um sistema mais velho, sem relação com o "exercise dummy" que
realmente está no DP.

Testado ao vivo, sem erro.

## 2026-08-21 (12)

### Rojan reposicionado: os dummies de verdade ficam dentro do DP
O Rojan tinha sido colocado em (1342,585,7), perto de uns "training dummy"
(item 5787/5788) achados num scan geral do mapa — mas essa área fica longe
da cidade, provavelmente sobra da mesclagem com o mapa do Daniel, sem
conexão andável. Pedro confirmou que os dummies de verdade ficam **dentro
do DP**. Achado o item certo — **"exercise dummy" (28558)**, em (990,985,7),
a dupla certa das armas de treino (mesma leva de conteúdo) — diferente do
"training dummy" antigo que eu tinha achado por engano. Rojan movido pra
(989,986,7), logo ao lado.

**Lição**: ao procurar "onde fica X" por scan bruto do arquivo, sempre
conferir se o resultado bate com uma área que o jogador realmente visita
antes de assumir — nem todo item encontrado no mapa está num lugar
acessível ou é a versão "certa" quando existem variantes com nome
parecido.

Testado ao vivo, sem erro.

## 2026-08-21 (11)

### Rojan: pedido "bulk" de armas de treino com mais cargas
Pedro pediu versões das armas de treino com mais cargas, preço
proporcional. **Achado importante no motor**: o preço de item na loja de
NPC é resolvido só pelo item id (`src/creatures/npcs/npc.cpp`,
`Npc::onPlayerBuyItem`), sem considerar subtype/cargas — cadastrar o mesmo
id várias vezes na `npcConfig.shop` com preços diferentes faria toda
compra daquele id cobrar o preço da **última** entrada registrada,
independente da versão que o jogador clicasse (bug de preço/exploit em
potencial). Resolvido com um fluxo de diálogo customizado fora do sistema
de loja padrão: jogador fala `bulk` → escolhe a arma → escolhe 100/250/500
cargas → confirma → recebe o item com `subType` = cargas, cobrado
manualmente a 40 gold/carga (mesma taxa da versão base de 50 cargas/2000
gold).

### Sarina agora vende Might Ring e Stone Skin Amulet
Nenhum NPC do mapa vendia esses dois (só existiam em NPCs do datapack
original não posicionados em lugar nenhum). Adicionados na loja da
Sarina: Might Ring por 3000 gold, Stone Skin Amulet por 18000 gold —
valores de memória (Tibia global), não tem como conferir localmente por
não existir precedente no servidor.

Testado ao vivo (docker cp + restart), sem erro de Lua nos dois scripts.

## 2026-08-21 (10)

### NPC Rojan: vendedor de armas de treino, ao lado dos dummies
Faltava um NPC vendendo as armas de treino (sword/axe/club/bow/rod/wand +
shield/wraps, ids 28540-28545/44064/50292, 50 cargas cada) pra treinar nos
training dummies. Criado `rojan.lua`, preço 2000 gold cada (valor padrão
do Tibia global, de memória — não tem como conferir localmente já que não
existia NPC nenhum vendendo isso neste datapack antes). Posicionado em
(1342, 585, 7), logo ao sul dos 4 dummies achados em (1339-1346, 584, 7).

Testado ao vivo via `docker compose cp` (script + `-npc.xml`) + restart,
sem erro de Lua.

## 2026-08-21 (9)

### Investigado (não corrigido): Cledwyn mostra "Gold Coin" na janela de loja
Pedro achou que o Cledwyn estava vendendo o set Rotten Blood por gold coin
em vez de silver token. Conferido `cledwyn.lua`: **já tem**
`npcConfig.currency = 22516` (silver token) configurado corretamente —
não faltava nada no script (correção de uma suspeita minha errada na
mesma sessão, cheguei a achar que faltava a linha, mas só tinha lido um
trecho do arquivo).

Print do jogo mostrou a janela de loja com "Currency: Gold Coin" mesmo
assim. Investigação no C++ do servidor (`npc->getCurrency()`,
`NpcType::info.currencyId`, `protocolgame.cpp`) não achou nenhum bug —
o servidor sabe que a moeda é silver token (prova: o diálogo de encantar
item gera dinamicamente "5 silver tokens", lendo a mesma função). Suspeita
é bug **visual do lado do cliente (OTClient)**, não do servidor.

**Pendente**: Pedro precisa testar comprando 1 item pra confirmar se
desconta gold coin de verdade (bug real) ou só mostra errado na tela
(cosmético). Não mexi em nada no Cledwyn até essa confirmação.

## 2026-08-21 (8)

### Sala secreta da World Wolves: Hellflayer guardião + baú de recompensa
Definido o boss da sala do teleporte (fim da hunt secreta de Werewolf/
Wereboar/Werebear/Werebadger/Werefox, sul do DP): **Hellflayer** (14000 HP/
11720 exp, bem acima de tudo que já existe na hunt normal). Sem a flag
`rewardBoss` (decisão consciente — essa flag muda o sistema de auto-loot
pra tratar como boss oficial, não só visual; ficou de fora por simplicidade).

**Recompensa** (Action ID 24801, resgatável 1x por jogador, mesmo sistema
dos outros baús): uma backpack com 10x Stone Skin Amulet, uma backpack com
10x Might Ring, e 200k gold. Precisou estender `custom_reward_chests.lua`
pra suportar recompensa "empacotada numa mochila" (campo `backpack = true`
por entrada) — sistema só dava itens soltos antes.

**Bug pego na colocação**: o baú foi colocado no mapa com item id **2481**
("chest" — outra variante visual) em vez do **2472** que o script realmente
reconhece (dois itens diferentes, nome igual na paleta do RME). Corrigido
direto no `.otbm` via `otbm.py`, mantendo o Action ID. Backup antes da
correção: `MAPA OFICIAL DE TRABALHO.otbm.bak4`.

Chest em (1024,1086,10), Hellflayer em (1029,1086,10) — mesma sala,
confirmado. Testado ao vivo (script carrega sem erro, servidor sobe
limpo) — teste de interação real (abrir o baú in-game) ainda pendente,
não dá pra simular sem cliente de jogo.

## 2026-08-21 (7)

### Cidade principal renomeada para Skartholt
"Cidade de Spawn" (placeholder desde o início do projeto) virou
**Skartholt** — nome final da cidade onde todos nascem/respawnam
(temple em 1000,1000,7). Resolve um dos itens "pendente" registrados na
entrada do sistema de barco.

O nome existia em **dois lugares que precisavam ficar sincronizados**:
o registro de town dentro do `.otbm` (editado via `otbm.py`) e uma tabela
`towns` separada no banco de dados (usada pelo MyAAC e pela criação de
personagem) — só mudar o `.otbm` não seria suficiente, o site/criação de
conta continuaria mostrando o nome antigo. Os dois foram atualizados.

Backup do `.otbm` antes da mudança: `MAPA OFICIAL DE TRABALHO.otbm.bak3`.
Testado ao vivo (restart do servidor + confirmado que o nome novo
sobrevive ao reload da tabela `towns`), sem erro.

## 2026-08-21 (6)

### Protection Zone no píer de chegada da Mirror Island
Pedro pediu pra proteger a área de desembarque do barco (jogador chegava
direto perto de Medusa/Serpent Spawn sem chance de reagir). Localizado o
píer de madeira de verdade via scan do `.otbm` (só 6 tiles de drawbridge,
x810-812/y219-220) e a tartaruga de retorno (811,217). Aplicada a flag
`TILESTATE_PROTECTIONZONE` (bit 128) direto no `.otbm` numa caixa pequena
de 9x9 ao redor dos dois (x807-815/y215-223/z7, 81 tiles) — via
`otbm.py`, preservando outras flags já existentes no tile (ex: a tartaruga
já tinha a flag de teleporte, `|=` não apagou). Não usei o brush de PZ do
RME porque não achei uma definição clara dele nos arquivos de dados do
editor pra confirmar o caminho certo de cliques — mais seguro fazer via
script com coordenada exata.

Dois pontos dos spawns novos (centrados em 805,226 e 821,226, raio 7)
alcançam até y=219 na borda — intencional, é o padrão comum do Tibia de
"pequeno bolsão seguro dentro do território de monstros", não reduz o
resto da hunt.

Backup do `.otbm` antes da mudança: `MAPA OFICIAL DE TRABALHO.otbm.bak2`.
Testado ao vivo (restart do container), sem erro.

## 2026-08-21 (5)

### Mirror Island: bestiário trocado (frog/tortoise fraco -> Medusa/Serpent Spawn) + destino do barco ligado
Pedro construiu a Mirror Island copiando outra hunt do Tibia como base de
terreno, mas isso trouxe o bestiário fraco junto (Tortoise, Toad, Frog x5
variantes, Crab, Crocodile, Seagull — 41 pontos de spawn, 155 criaturas,
x787-881/y221-307/z7). Substituídas todas por **Medusa** (42, ~27%) e
**Serpent Spawn** (113, ~73%) — a dupla clássica do Tibia oficial pra esse
tema, ambas na faixa de HP 3000-4500 (tier alto). Mesmas posições/raios de
spawn originais, só trocado o nome da criatura em cada slot (script Python
com seed fixa, backup do XML original guardado como `.bak` antes de mexer).

**Atualizado o boatman.lua**: `MIRROR_ISLAND_DESTINATION` agora aponta pra
(811, 219, 7), a coordenada de chegada que o Pedro passou (dentro da ilha,
ground limpo, confirmado antes de aplicar). A ilha secreta (Gorgo) continua
com placeholder — falta ser construída.

**Ponto de atenção pro Pedro**: 155 criaturas de 3000-4500 HP na mesma
densidade de uma hunt desenhada pra bicho fraco pode ficar muito lotado/
difícil de navegar — vale testar in-game e avisar se quiser espaçar mais
os spawns antes de considerar pronta.

Testado ao vivo via `docker compose cp` (npc + monster.xml) + restart —
zero erro de Lua, nenhum aviso de "tipo de monstro não encontrado" pra
Medusa/Serpent Spawn (nomes confirmados corretos).

## 2026-08-21 (4)

### NPC Boatman criado — primeiro passo do sistema de barco pra Mirror Island
Implementa o gancho de lore da chave dos orcs (plantado em 2026-08-08, ver
placa em 959,1125,7 "This key might be useful someday") — a chave física
("bone key", item 2973) foi colocada por cima da placa (959,1124,7).

**NPC**: `data-otservbr-global/npc/boatman.lua`. Fica ao lado do DP, antes
da forja. Falas exatas definidas pelo Pedro (inglês, 4 cenários: sem chave,
primeira viagem/consome a chave, viagens seguintes, saudação). Sem chave →
recusa. Com chave (primeira vez) → consome 1x, marca storage `900001`
como liberado permanentemente, viaja. Já liberado → viaja direto, sem
checar a chave de novo.

**Pendente (aguardando construção do restante do sistema)**:
- Mirror Island e a ilha secreta **ainda não existem no mapa** — o destino
  do teleporte está com posição placeholder (temple da cidade, 1000,1000,7)
  pros dois casos, só pra não jogar o jogador em lugar quebrado. Atualizar
  `MIRROR_ISLAND_DESTINATION`/`SECRET_ISLAND_DESTINATION` no topo do script
  assim que as ilhas forem construídas.
- A chance de 5% de cair na ilha secreta (boss Gorgo/Medusa) já está
  implementada no script (`SECRET_ISLAND_CHANCE`), só falta o destino real.
- NPC preso na ilha secreta, boss Gorgo, item no corpo pra questline futura,
  nome final do Boatman e da cidade principal — tudo ainda não definido/não
  implementado, registrado aqui só pra não perder o contexto da conversa.

Testado ao vivo via `docker compose cp` + restart, sem erro de Lua.

## 2026-08-21 (3)

### Separada a loja do Asnarus: potes/runas ficam, distância vai pro Archery
Pedro decidiu especializar as lojas — Asnarus deveria vender só poções e
runas, e os itens de arqueiro/paladino (arrow, bolt, bow, crossbow,
quiver, spear, throwing star) foram movidos pra um NPC dedicado. Em vez de
criar um personagem do zero, reaproveitado o **Archery** — já existe no
datapack, já com esse tema (dono de uma "Archery's Hut"), só faltava os
preços calibrados: ele tinha só valores genéricos padrão do OTServBR (ex:
infernal bolt 13, spectral bolt 70), bem abaixo do trabalho de precificação
que o Daniel já tinha feito pro Asnarus (infernal bolt 114, spectral bolt
210) — os preços do Asnarus foram transplantados pra manter a economia
calibrada, e adicionado `poison arrow` que faltava no Archery. Removidos
também do Asnarus os itens de loot/troféu que não eram nem poção nem runa
(broken visor, frazzle skin/tongue, dead weight, hemp rope, etc.) — ficaram
de fora por ora, sem destino definido ainda.

Pedro já construiu o espaço físico pro Archery no mapa, logo ao norte do
Haani (983-1004, y≈1013, z7) — falta só ele posicionar o NPC ali dentro do
RME (feito por ele, não por script, pra não conflitar com a edição de mapa
em andamento).

Testado ao vivo via `docker compose cp` + restart nos dois arquivos: 49
itens no Asnarus, 31 no Archery, zero erro de Lua.

## 2026-08-21 (2)

### Sarina passou a vender todas as 35 backpacks de 20 slots
Pedro notou que a loja da Sarina só tinha 14 cores/temas de backpack, todas
de 20 slots (mesma capacidade, só cosmético) — comparado a uma lista
completa de backpacks do Tibia clássico, existem 35 modelos diferentes
nessa faixa de capacidade. Adicionadas as 20 que faltavam (birthday, buggy,
cake, changing, crystal, deepling, demon, dragon, expedition, feedbag,
glooth, minotaur, moon, mushroom, old and used, pannier, pirate, raccoon,
santa, wolf), todas a 20 gold, ids conferidos em `items.xml`
(`containersize=20` em todas). Backpacks com capacidade real maior (24+,
tipo Backpack of Holding) ficaram de fora de propósito — decisão do Pedro
de reservar essas pra serem obtidas de outra forma (loot/quest), não
compradas direto de NPC.

**Descoberta no caminho**: o container Docker rodando **não sincroniza**
`data-otservbr-global/npc/*.lua` do repositório automaticamente — só o
mapa tem esse sync (`sync-map-to-server.ps1`). Pra essa mudança realmente
valer no servidor de teste, precisou `docker compose cp` manual do arquivo
pro container + restart. Isso provavelmente significa que outras mudanças
de NPC/script feitas antes (Asnarus, fórmula de dano) também nunca foram
de fato testadas ao vivo neste container — só verificadas por leitura de
log de start-up, que usa a cópia própria da imagem, não a do repositório.
Vale revisitar esse gap de sync quando sobrar tempo.

## 2026-08-21

### Mesclado o mapa do Pedro com a hunt do pântano do Daniel (edição em paralelo)
Pedro voltou de viagem (fora 08/08-20/08) e o Dan tinha ficado trabalhando
sozinho no mapa sem sincronizar — os dois arquivos divergiram: o `.otbm` do
Pedro (salvo localmente, fora do git, em `tibia-server/meu-mapa/`) tinha
lapidações próprias que não existiam em nenhum outro lugar, e o do Dan
(commit `76af8c0a2`) tinha a hunt do pântano nova + ajustes em outras hunts,
sem ter sido puxado ainda.

**Resolução**: em vez de merge automático (formato `.otbm` é binário, não dá
pra mesclar tipo texto), o mapa do Dan foi copiado pra uma pasta separada
(`mapa-daniel-github/`) só de referência, e o Pedro trouxe manualmente as
partes que queria (a hunt do pântano) pro mapa dele via copiar/colar no RME,
numa área nova do mapa (~x673-1003/y403-1049) — sem sobrescrever a cidade
original.

**Verificação antes de subir**: comparação tile a tile com o `otbm.py`
confirmou 94,5% dos tiles da cidade original do Pedro presentes na mesma
coordenada no resultado final, 90,3% idênticos (ground + itens). Achado um
buraco de 3.120 tiles perto do centro da cidade (x941-1060/y922-1094/z7) —
o Pedro confirmou visualmente que não sentiu falta de nada, então foi
considerado intencional/aceitável.

**Lição pro futuro**: sempre que os dois estiverem editando o mapa na mesma
janela de tempo, checar antes se algum dos dois tem trabalho local não
commitado antes de decidir "quem está atualizado" — o commit mais recente no
GitHub não é necessariamente a versão mais completa se alguém esqueceu de
subir a própria.

## 2026-08-14 (4)

### 14 hunts vitrine: 2 por técnica nova sugerida
`build_technique_showcase.lua` — 2 variantes bem diferentes pra cada uma
das 7 técnicas discutidas: `algo.erode` (vale estreito x vale largo
ramificado), `algo.thermalErode` (encosta afiada x encosta suave),
`noise.cellular` (células grandes x células pequenas), `noise.warp`
(distorção sutil num círculo x distorção forte num tabuleiro),
`geo.pointInPolygon` (pentagrama exato x polígono irregular quebrado),
`geo.floodFill` (gruta pequena quase toda inundada x caverna grande com só
um bolsão de água num canto), e `algo.voronoi` com contagem de pontos
desigual (uma facção domina quase tudo x fronteira disputada com faixa
neutra no meio). Todas em x0-2040/y1180-1461 (faixa vazia verificada),
maiores que os lotes anteriores (até 260x100, formato baixo e largo pra
caber lado a lado).

**Erro pego antes de rodar**: a primeira fileira tinha 8 hunts planejadas
em 7 posições — sobrepunham. Corrigido movendo uma pro final da segunda
fileira, com espaçamento de 31 tiles reconferido em todas as 14.

## 2026-08-14 (3)

### Os 6 demos originais restantes corrigidos e substituídos
Endurecidos os últimos 6 scripts que ainda eram os demos originais sem
proteção: `cave_generator.lua` → `build_cave.lua`,
`dungeon_generator.lua` → `build_dungeon.lua`, `maze_generator.lua` →
`build_maze.lua`, `island_generator.lua` → `build_island.lua`,
`river_generator.lua` → `build_river.lua`, `street_generator.lua` →
`build_street.lua`. Originais apagados (mesma ressalva de sempre: `rme/`
está no `.gitignore`, sem desfazer pelo git).

Cada um ganhou: validação de brush, checagem de limite do mapa, e a
correção do "cancelar com X". Achados específicos no caminho:

- **Island Generator tinha quase todos os ids errados** — a "espada"
  (id 2376) é uma cadeira estofada vermelha neste servidor; árvore/flor
  usavam os mesmos ids errados (teia/parede) do Forest Generator. Trocado
  por brush de verdade (`green trees`, `flowers (yellow)`, `campfire`) ou
  id conferido de verdade (espada=3264, placa=2012).
- **Achei uma função nativa que eu não sabia que existia**:
  `creatureExists(nome)` — checa se um monstro tá registrado de verdade,
  sem precisar grepar arquivo. `setCreature` não dá erro em nome errado,
  só cria um "tipo de monstro faltando" — usar essa função antes de
  chamar `setCreature`, sempre.
- **Rio e rua são diferentes de caverna/masmorra/labirinto/ilha**: esses
  últimos são "auto-contidos" (qualquer conflito é erro de verdade, aborta
  tudo); rio e rua servem pra **ligar** lugares que já existem — então em
  vez de abortar tudo, eles agora **pulam** o tile que já tem algo (nunca
  sobrescrevem) e avisam quantos pintaram vs quantos puleram.

Tudo registrado na skill como mistake #8 e #9.

## 2026-08-14 (2)

### Limpeza: apagados os scripts deprecados
A pedido do Dan, apagados 4 scripts obsoletos do Script Manager:
`city_lot_generator.lua` (substituído por `build_city_lots.lua`),
`forest_generator.lua` (substituído por `build_forest.lua`),
`fix_swamp_hunt_cave.lua` e `fix_swamp_hunt_monster_placement.lua`
(correções já incorporadas em `build_swamp_hunt.lua`). `rme/` está no
`.gitignore`, então essa exclusão não passa pelo git — sem desfazer por
lá, mas o que cada um fazia já está registrado nas entradas anteriores
deste changelog. Os demos originais da RME (cave/dungeon/maze/island/
river/street generator) não foram apagados — não têm substituto corrigido
ainda, só ainda não passaram pelo mesmo tratamento de segurança.

## 2026-08-14

### Forest Generator corrigido (ids de árvore do demo eram de outro servidor)
O demo original (`forest_generator.lua`) usa `tile:addItem(id)` com ids
brutos fixos (2700-2709 pra árvore, 2725-2739 pra flor/cogumelo) e um
comentário próprio avisando "adjust for your server". Conferido contra
`data/items/items.xml` deste projeto: esses ids **não são árvore nem
flor aqui** — são teia de aranha, parede florida, parede com musgo. Se
tivesse rodado sem checar, teria colocado isso ao invés de vegetação.

Corrigido em `build_forest.lua`: em vez de id bruto, usa os brushes de
doodad reais desse build da RME (`green trees`/`birch trees`/`alternate
trees`, `flowers (yellow)/(moon)`/`sunflowers`, `light`/`dark mushrooms`,
conferidos em `trees.xml`/`flowers.xml`) — mesmo caminho validado
(`applyBrush` + `Brushes.get()`) que uso pra chão e parede, em vez de
`addItem` com id cru. Adicionadas as mesmas 4 proteções dos scripts
anteriores: validação de brush, checagem de conflito, limite do mapa, e
correção do cancelar-com-X. Local de teste padrão: (1550,1800), 60x60,
verificado vazio.

## 2026-08-13 (10)

### Diálogo gerava mesmo fechando com o X — corrigido, cidade agora 200x200
O Dan abriu o diálogo do `build_city_lots.lua`, fechou com o X (pra
cancelar) e ele gerou de qualquer jeito com os valores padrão. Causa:
`dlg:show()` retorna tanto quando clica no botão quanto quando fecha a
janela — não existe diferença nativa entre os dois; o script sempre segue
em frente lendo `dlg.data`. Corrigido com uma flag `confirmed` que só vira
`true` dentro do `onclick` do botão "Generate"; se `dlg:show()` retornar
sem essa flag, o script cancela sem tocar em nada. Aplicado nos dois
scripts com diálogo (`build_city_lots.lua`, `build_crystal_cave_test.lua`)
e registrado na skill como regra pra qualquer diálogo futuro.

Cidade padrão agora é 200x200 (era 80x80), 45 lotes, reposicionada pra
(1300,1750) — verificada vazia e longe de tudo (canyon, as 20+11 hunts,
cidade/pântano originais).

## 2026-08-13 (9)

### Teste de campo aberto (Cliff Canyon) e City Lot Generator corrigido
Testado `build_cliff_canyon.lua` (ideia própria: terreno de um único campo
de ruído contínuo `noise.fbm`, em vez de formas coladas). Resultado: a
variedade de textura do terreno melhorou, mas a geometria de
parede/rocha saiu errada — limiar de ruído puro não garante blob
conectado como cellular automata garante. Registrado como lição na skill
(mistake #6) e em memória (`map_terrain_noise_vs_walls.md`): ruído contínuo
é bom pra textura de chão já andável, nunca pra decidir o que é parede.

Também corrigido `scripts/city_lot_generator.lua` (script de exemplo da
própria RME) → `build_city_lots.lua`: o original não valida nome de brush
digitado no diálogo, não confere se as coordenadas já têm conteúdo, e não
confere limite do header do mapa (2048x2048) — as 3 lacunas que já
tínhamos corrigido nos outros scripts. Adicionadas as 3 checagens; posição
padrão (900,1900, 80x80) já verificada vazia e dentro do limite.

## 2026-08-13 (8)

### Mais 20 hunts, ainda mais espaçadas e diferentes entre si
Pedido: 20 hunts a mais, o mais diferentes possível entre si (tema, nível,
tamanho, formato), sempre no preto e sem sobrepor nada. Temas escolhidos
com ajuda de um agente que cruzou as pastas reais de monstro do datapack
com agrupamentos reais do tibiaroute.com/br/hunting-places (confirmando,
por exemplo, que Blue Djinn/Green Djinn/Efreet/Marid já formam uma hunt de
verdade no Tibia oficial — "Yalahar Djinns"). Todos os ~80 nomes de monstro
usados foram conferidos um por um contra `Game.createMonsterType("...")`
nos arquivos reais antes de escrever qualquer coisa no script.

1. Acampamento dos Dwarfs (masmorra BSP) — Dwarf, Dwarf Miner, Dwarf Guard, Dwarf Geomancer
2. Caverna dos Morcegos (caverna bem aberta) — Bat, Mutated/Exotic Bat, Vicious Manbat
3. Ninho de Insetos (labirinto pequeno) — Bug, Larva, Insect Swarm, Swarmer
4. Covil das Aranhas (caverna densa e alta) — Spider, Tarantula, Sacred Spider, Exotic Cave Spider, Spidris
5. Acampamento Goblin (mancha aberta pequena, nível baixo) — Goblin, Scavenger, Assassin, Leader
6. Floresta dos Lobisomens (mancha aberta média) — Werefox, Werebadger, Wereboar, Werebear
7. Território da Matilha (duas manchas unidas, forma de "amendoim") — Wolf, Winter Wolf, Gnarlhound, Ghost Wolf
8. Enseada Pirata (lago com costa de areia) — Pirate Skeleton/Marauder/Cutthroat/Ghost/Buccaneer
9. Labirinto do Minotauro (labirinto de verdade) — Minotaur Archer/Occultist/Mage/Guard
10. Recife Quara (lago com recife de coral) — Quara Constrictor/Mantassin/Pincher/Predator
11. Santuário da Esfinge (1 salão só, monstro raro/esparso) — Gazer, Bonelord, Sphinx, Feral Sphinx
12. Covil dos Trolls (caverna pequena, nível baixo) — Island/Frost Troll, Troll Guard/Legionnaire
13. Dunas dos Besouros (4 manchas sobrepostas, campo de dunas) — Sandcrawler, Terramite, Burrowing/Lancer Beetle
14. Mansão Assombrada (masmorra BSP, parede de madeira) — Ghost, Spectre, Lost Soul, Mean Lost Soul
15. Fundição dos Golens (masmorra BSP, parede de ferro) — Stone Golem, Iron Servant, Worker/War Golem
16. Templo das Nagas (regiões voronoi) — Corrupt/Rogue Naga, Naga Archer/Warrior
17. Recife das Serpentes (lago grande, chefe raro) — Young Sea Serpent, Sea Serpent, Seacrest Serpent, Mercurial Menace
18. Palácio dos Djinns (mancha aberta, pátio de deserto) — Blue/Green Djinn, Efreet, Marid
19. Reino dos Pesadelos (caverna alta e densa) — Nightmare Scion, Retching Horror, Choking Fear, Silencer
20. Bosque Carnisylvan (mancha aberta corrompida) — Carnisylvan Sapling/Poisonous/Dark/Hulking

Script: `build_twenty_hunts.lua`, grade de 20 blocos a leste de tudo (região
verificada vazia), tamanhos e formatos bem diferentes (manchas simples,
duas/quatro manchas unidas, masmorras BSP com parede diferente cada,
labirintos, voronoi, um salão único). Checagem de brush no início (mesma
proteção do lote anterior).

**Erro pego antes de rodar**: ao planejar a grade de 20 blocos, a coluna
mais a leste (com as hunts maiores) passava de x=2047 — o limite real do
mapa (header diz 2048x2048) — em até 27 tiles, o que podia corromper ou
falhar ao carregar. Só apareceu ao recalcular a caixa exata de cada uma das
20 (não só olhar "centro da coluna + tamanho típico"). Corrigido deslocando
a grade toda 50 tiles pra oeste. Registrado na skill: sempre confirmar os
cantos extremos de cada zona contra os limites do header, não só o espaço
entre vizinhas.

## 2026-08-13 (7)

### Caverna de Cristal (teste) agora se auto-limpa antes de gerar
O Dan ficou travado num ciclo de ABORT mesmo depois de rodar o
`clear_region.lua` manualmente — cada execução de um gerador cria 2+ undos
separados (terreno, depois monstro), então contar Ctrl+Z certo é frágil, e
o log do ABORT mostrava muito mais que os 5 tiles esperados (bug: o loop de
conflito era `for y do for x do ... break end end` — o `break` só saía do
loop de dentro, não do de fora, deixando escapar ~1 tile extra por linha).

Como `build_crystal_cave_test.lua` é justamente uma sandbox pra testar
parâmetro à vontade, mudei a lógica: em vez de abortar em conflito, ele
agora **limpa sozinho** a própria área fixa (x1125-1235/y245-355) antes de
gerar de novo — sem precisar do `clear_region.lua` nem contar Ctrl+Z. Só
roda "Build Crystal Cave (Test)" de novo quantas vezes quiser. Esse
autolimpar só é seguro aqui porque a área é fixa e pequena — os scripts que
geram conteúdo permanente (hunts novas, mapa principal) continuam
abortando em conflito, de propósito, pra nunca sobrescrever nada por
engano.

`clear_region.lua` continua existindo pra limpar qualquer outra área manualmente,
se precisar.

## 2026-08-13 (6)

### Caverna de Cristal — hunt de teste com diálogo pra ajustar parâmetros
O Dan pediu pra construir uma hunt junto, como teste, num lugar vazio perto
das outras 10. Criado `build_crystal_cave_test.lua` (11ª área, x1125-1235/
y245-355, verificada vazia) com monstros de tema cristal (Crystal Wolf,
Crystalcrusher, Enraged Crystal Golem, Crystal Spider). Diferente dos
scripts anteriores, esse abre um diálogo na RME antes de gerar, com os
parâmetros do `algo.generateCave` (fill %, iterações, birth/death limit,
seed, espaçamento de monstro) editáveis ali mesmo — dá pra ver o efeito de
cada um ao vivo sem precisar pedir pra eu editar o arquivo.

## 2026-08-13 (5)

### 10 hunts novas, bem espaçadas e temáticas diferentes entre si
Pedido: 10 opções de hunt diferentes, todas separadas na parte preta do
mapa (sem sobrepor nada), com temáticas bem distintas entre si. Escolhidas
pelas pastas reais de monstro do datapack
(`data-otservbr-global/monster/*`), conferindo `Game.createMonsterType("...")`
em cada arquivo pra garantir o nome exato (não adivinhado a partir do nome
do arquivo):

1. **Dunas Ardentes** (deserto, aberto) — Cobra, Dreadmaw, Adult Goanna, Liodile
2. **Fenda de Magma** (caverna vulcânica, cellular automata + poças de lava) — Fire Devil, Fire Elemental, Massive Fire Elemental, Lava Lurker, Diabolic Imp
3. **Planalto Congelado** (tundra aberta + lago congelado) — Frost Giant(ess), Ice Golem, Frost Dragon (Hatchling)
4. **Floresta de Esporos** (selva fúngica aberta) — Carniphila, Humongous/Hideous Fungus, Rootthing Nutshell
5. **Catacumbas Esquecidas** (masmorra BSP, salas pequenas) — Crypt Shambler/Warrior, Elder Mummy, Banshee, Betrayed Wraith
6. **Brecha da Realidade** (labirinto) — Sparkion, Breach Brood, Mitmah Scout/Seer
7. **Câmara Corrosiva** (caverna aberta) — Mercury/Acid/Death/Ink Blob
8. **Gruta Submersa** (lago com ilhas) — Crab, Blood Crab, Deepling Scout/Worker/Warrior, Crustacea Gigantica
9. **Bosque Encantado** (regiões voronoi, aberto) — Dryad, Pixie, Nymph, Dark Faun
10. **Bastião Ogro** (masmorra BSP, salões grandes) — Cyclops, Ogre Shaman/Brute/Savage

Técnicas de geração variadas de propósito (não é a mesma caverna reskinada
10x): blob com ruído (deserto/tundra/selva/gruta submersa), cellular
automata (vulcão/limo), BSP `algo.generateDungeon` (cripta/bastião, só
mudando tamanho de sala), labirinto `algo.generateMaze` (brecha), voronoi
`algo.voronoi` (bosque). Coordenadas verificadas vazias antes de gerar
(`x60-1040, y60-540`, bem ao norte de tudo que já existe).

**Erro pego antes de rodar**: usei `"dirt wall"` e `"dirt floor"` como nome
de brush pro Bastião Ogro — nomes de *item* válidos, mas não são nomes de
*brush* de verdade na RME (`applyBrush` falha **silenciosamente**, sem
erro, se o nome não existir — teria saído um forte sem parede nenhuma).
Trocado por `"muddy stone wall"` + `"cave"` (confirmados via grep direto em
`grounds.xml`/`walls.xml`). Adicionada uma checagem no início do script
(`Brushes.get(nome)` pra cada brush usado, aborta com lista clara se algum
não existir) — registrado na skill como regra permanente: nunca inferir
nome de brush a partir do nome do item, sempre grepar a definição real.

## 2026-08-13 (4)

### As duas correções incorporadas no script principal (não só nos fixes)
O Dan perguntou, com razão, se toda hunt nova ia precisar desses scripts de
"fix" separados. Não devia — os dois fixes (parâmetros do cellular automata,
checagem de vizinho antes de colocar spawn) agora estão dentro do
`build_swamp_hunt.lua` original, não só nos scripts de correção pontual.
Uma hunt nova gerada a partir dele já sai certa numa passada só.
`fix_swamp_hunt_cave.lua` e `fix_swamp_hunt_monster_placement.lua` continuam
no repositório como registro de como o problema foi corrigido sem redesenhar
a hunt inteira, mas não são mais o modelo pra copiar — isso agora é o
`build_swamp_hunt.lua`.

## 2026-08-13 (3)

### Monstros "dentro da parede" na gruta — faltava checar os vizinhos
Depois da caverna sair com a proporção certa de parede/piso, o Dan notou
alguns Werecrocodiles parecendo estar dentro da rocha. Causa: eu só chequei
"esse tile é piso?" pra escolher onde colocar spawn — não chequei se os
tiles vizinhos também eram piso. Num mapa isométrico, o sprite da parede
"vaza" visualmente sobre o tile vizinho, então um monstro numa frincha de
piso de 1 tile encostada na rocha aparenta estar dentro da parede, mesmo
estando em piso válido de verdade.

Criado `fix_swamp_hunt_monster_placement.lua`: limpa os spawns antigos da
área da gruta e recoloca só em tiles cujos 4 vizinhos ortogonais também são
piso não-bloqueado (`tile.hasGround and not tile.isBlocking`, lendo o estado
real do tile já borderizado, não o grid do gerador). Registrado na skill
`tibia-map-building` como regra geral pra qualquer spawn dentro de caverna.

## 2026-08-13 (2)

### Gruta saiu 91% parede sólida — parâmetros do cellular automata errados
O primeiro run do `build_swamp_hunt.lua` funcionou (checagem de segurança
passou, salvou, sobreviveu a fechar/reabrir a RME), mas o minimapa mostrou a
área da caverna quase inteiramente sólida, com só uns pontinhos marrons de
piso — log confirmou: `caveFloor=1057 caveWall=11203` (91% parede).

Causa: os parâmetros do `algo.generateCave` (`birthLimit=4, deathLimit=3`,
5 iterações) fazem esse autômato celular "fugir" pra quase todo mundo virar
parede. Diferente do algoritmo de borda (que é complexo e arriscado demais
pra eu simular sozinho), essa regra é simples e totalmente especificada — deu
pra portar pra Python (20 linhas, direto do `lua_api_algo.cpp`) e testar
várias combinações antes de sugerir qualquer coisa. Achado bom:
`fillProbability=0.45, iterations=4, birthLimit=5, deathLimit=4` → ~35%
parede, 99% do piso conectado numa região só (conferido com flood-fill).

Como o Dan já tinha fechado e reaberto a RME (perdendo o histórico de undo),
não dava pra desfazer e refazer tudo — criado `fix_swamp_hunt_cave.lua`, que
regenera **só** a área da gruta (limpa monstro/spawn antigo que possa ter
ficado em cima de rocha agora, repinta com os parâmetros corrigidos,
reborderiza só essa região) sem tocar no lago/pântano que já tinha saído bom.

Lição pra skill: parâmetros de algoritmo determinístico e simples valem
simulação em Python antes de recomendar (baixo risco, alta confiança);
lógica de borda/engine complexa não (alto risco de erro que só descobrimos
no print — foi exatamente o que aconteceu duas vezes antes).

## 2026-08-13

### Hunt do pântano refeita usando o script Lua da própria RME (não mais Python cru)
Depois do Borderize Selection "quase não mudar nada" no RME, o Dan mandou o
link de `OTAcademy/RME/scripts/terrain_generator_demo.lua` — que revelou que
o build da RME deste projeto (`rme/canary-map-editor-v4.0-windows/`) já vem
com um motor de script Lua embutido (menu **Scripts → Script Manager**),
com `algo.generateCave` (cellular automata — o mesmo algoritmo usado por
mapeadores reais pra cavernas orgânicas com loop), `noise.simplex` (raio
distorcido por ruído, pra lagos/pântanos irregulares), e principalmente
`tile:applyBrush(nome, false)` + `tile:borderize()` — que chamam o **mesmo
código de borda da própria RME**, em vez de eu adivinhar qual variante de
item usar (foi exatamente esse tipo de suposição que causou a parede quebrada
da primeira tentativa).

Também dá pra colocar monstro direto (`tile:setSpawn(1)` +
`tile:setCreature(nome, 60)`) sem editar XML na mão, e a RME grava isso no
`-monster.xml` sozinha ao salvar.

**Não existe forma de rodar isso sem abrir a RME** — o `.exe` só aceita um
caminho de mapa por linha de comando, sem flag pra rodar script headless
(checado no código-fonte, `application.cpp`). Então o fluxo agora é: eu
escrevo o `.lua`, o Dan abre a RME, Scripts → Script Manager → roda o
script, salva.

Restaurado o backup (desfeitas as duas tentativas em Python) e criado
`rme/canary-map-editor-v4.0-windows/scripts/build_swamp_hunt.lua`, que
regenera a hunt inteira (canal → lago/pântano com ruído → caverna orgânica
com sala/corredor via cellular automata → monstros) com verificação de
sobreposição embutida (aborta se algo já existir nas coordenadas). Skill
`tibia-map-building` atualizada pra apontar esse método como preferencial —
o `otbm.py` em Python continua útil só pra leitura/análise (contagem de
tiles, preview em ASCII), não mais pra escrever bordas/paredes/spawns.

## 2026-08-12

### Nova área de caça: pântano + gruta a oeste da cidade (nível 200+)
Pedido: criar uma hunt nova numa parte do mapa que ainda não tinha nenhum tile
colocado, sem sobrepor nada do que já existia. Analisamos o `.otbm` atual via
`tools/otbm-tools/otbm.py` e vimos que a borda oeste real do mapa inteiro
(nenhum tile em nenhum andar) é `x=917` — e que, coincidentemente, o rio que já
passa pela cidade termina exatamente ali, num "final abrupto". Em vez de abrir
uma brecha numa parede existente, a nova área simplesmente **continua esse
rio** para oeste.

Pesquisamos hunting spots reais do Tibia pra nível 200+ com tema de pântano e
usamos como base o Werecrocodile/Feral Werecrocodile (já existem como scripts
em `data-otservbr-global/monster/lycanthropes/`, ~4100-5400 exp, ~5300-6400 HP,
dificuldade "Hard"), com Hydra (`monster/dragons/hydra.lua`, 2100 exp) como
camada intermediária e Marsh Stalker/Swampling como monstros de enchimento nas
bordas mais fracas do pântano.

**Primeira versão ficou ruim e foi refeita.** O Dan apontou dois problemas
depois de ver o print no RME: (1) o layout era geometricamente perfeito —
lago em círculo exato, gruta em retângulo exato, corredor reto, monstros num
grid — nada parecido com uma hunt de verdade (comparou com um print de uma
hunt real, toda com curvas e salas irregulares); (2) a parede da gruta usava
o id 4457 ("mountain") nos 4 lados do retângulo, mas esse id é só a peça de
borda **leste** de um conjunto de ~46 variantes direcionais (`borders.xml` da
própria RME, border id 29) — usado nos 4 lados, ficou uma textura quebrada
tipo grade/cerca em vez de rocha.

**Correção**: em vez de tentar adivinhar à mão qual das ~46 variantes de borda
usar em cada ponto (é exatamente esse tipo de escolha manual que causou o
problema), o script agora só escreve **ground puro** (lago, pântano, piso de
caverna, rocha de gruta) usando os mesmos ids/pesos que os brushes da própria
RME declaram em `rme/canary-map-editor-v4.0-windows/data/materials/brushs/grounds.xml`
— e a transição de borda entre eles fica pra RME resolver com
**Edit → Border Options → Borderize Selection (Ctrl+B)**, que é a ferramenta
feita exatamente pra isso e usa as mesmas regras de `borders.xml`. A gruta virou
o brush "grotto" (ids 13594/13644/13645, rocha sólida) esculpido por uma
caminhada aleatória (drunkard's walk com ricochete nas bordas do retângulo em
vez de "colar" nelas) formando túneis e salas de tamanho variável — não mais
um retângulo murado. O lago e o pântano usam raio perturbado por senoides (em
vez de raio fixo) mais 4 "baías" extras coladas por cima, pra ter reentrâncias
e não ficar um anel perfeito. Os spawns usam amostragem com espaçamento mínimo
(tipo Poisson-disk) e clusters ocasionais de 2 monstros por ponto, em vez de
grid fixo.

**Layout final** (`tools/otbm-tools/build_swamp_hunt.py`, x685-920/y1010-1160, z=7):
canal (continuação do rio, meandrando) → lago irregular (centro 818,1087) →
pântano irregular com baías (Marsh Stalker/Swampling espalhados, Hydra na
faixa mais úmida) → conector garantido → sistema de túneis/salas esculpidos
na rocha "grotto" (Werecrocodile/Feral Werecrocodile).

O script lê o `.otbm`, calcula os tiles novos, e **aborta sem escrever nada**
se qualquer coordenada planejada já existir no mapa. Também acrescenta os
spawns direto no `MAPA OFICIAL DE TRABALHO-monster.xml`, no mesmo formato que o
resto do arquivo já usa. Backup dos dois arquivos (`.otbm.bak`,
`-monster.xml.bak`) feito antes de rodar, e é seguro rodar de novo (não
duplica — aborta no conflito).

**Ainda falta**: abrir no RME, selecionar a área nova e rodar Borderize
Selection (Ctrl+B) pra gerar as transições de borda corretas entre
água/pântano/caverna/rocha antes de salvar.

### Correção: quadrados pretos no pântano + skill de criação de mapa
Depois de ver print no RME, apareceram vários quadrados pretos (não
caminháveis, mas também sem parede) espalhados pelo pântano. Diagnóstico:
os itens de decoração que o gerador espalhava (`swamp reed` 3688,
`swamp lily` 3689, `swamp grass` 9686, ~8% dos tiles de lama) são válidos no
`items.xml` do servidor mas não têm sprite no client carregado pela RME —
preto sólido é exatamente como a RME renderiza um id sem sprite. Removidos
do `build_swamp_hunt.py`; mapa regenerado sem eles.

Como ainda não é 100% certo que a causa era só a decoração (os ids de
"swamp" do ground em si — 4680 e variantes — também nunca tinham sido usados
neste mapa antes, só confirmados por print como "parecem ok" na textura
geral), se ainda sobrar algum quadrado preto depois de reabrir, o próximo
passo é o Dan clicar/passar o mouse no tile pra ver o id exato na RME, em
vez de eu adivinhar de novo.

Também criada a skill `tibia-map-building`
(`.claude/skills/tibia-map-building/SKILL.md`) com tudo que foi aprendido
fazendo essa hunt: o fluxo obrigatório de backup/planejar/checar
sobreposição antes de escrever, onde estão os dados reais de border/wall da
própria RME (`rme/canary-map-editor-v4.0-windows/data/materials/`), a
diferença entre "ground que bloqueia" (mountain/grotto) e "wall brush"
(stone wall com peças horizontal/vertical/corner/pole), receitas de forma
orgânica (raio perturbado por seno, drunkard's walk com ricochete,
espalhamento tipo Poisson-disk pra monstro), e as duas lições tiradas dos
erros desta sessão (nunca usar 1 variante de borda em todos os lados; nunca
confiar que um id "existe no items.xml" prova que ele renderiza).

Requer **restart completo do servidor** pra aparecer (mudança de mapa não é
coberta por `/reload` nem por `Game.reload()` — ver decisão anterior sobre
isso).

## 2026-08-08

### Loja da Asnarus: expansão de runes/munição, repreço completo das bolts
Loja da Asnarus (`data-otservbr-global/npc/asnarus.lua`) expandida com o catálogo de runes e
munições que faltavam em relação ao NPC oficial "Archery's Hut" (que não fica spawnado no
mapa, então não há risco de arbitragem). `burst arrow` (13gp, ancorada na `envenomed arrow`
por ser munição de efeito, não física pura) e `infernal bolt` reprecificadas com fórmula
própria documentada em `docs/ammo-pricing-formula.md` (regra de três pelo `attack` do vizinho
mais próximo já precificado, com prêmio adicional — dividido entre os dois degraus quando o
item novo fica entre dois preços já fixos). Em seguida, a pedido do Pedro, **todas as 8 bolts
foram triplicadas** como gold sink geral: bolt 12, piercing 15, vortex 18, power 21, drill 36,
prismatic 60, infernal 114, spectral 210 — infernal mantida acima da prismatic por ter mais
ataque (72 vs 66), mesmo sendo menos usada na prática por ser mais rara.

Cobertura completa de arrows também fechada: adicionada `poison arrow` (10gp — descoberto que
o script da arma sobrescreve o ataque do items.xml de 23 pra 21 e aplica veneno de verdade,
então foi tratada como item de efeito, ancorada na envenomed arrow). `simple arrow` (item de
tutorial, baixa precisão) e as "storm arrows" (não existem neste datapack ainda) ficaram de
fora por decisão/limitação, não por descuido. `diamond arrow` mantida fixa em 130gp por pedido
explícito do Pedro.

Loja da Sarina finalizada: reorganizada em ordem alfabética (os backpacks novos tinham sido só
colados no fim da lista) — conteúdo (remoção de itens genéricos, adição da linha completa de
backpacks) já estava certo, só faltava esse ajuste de formatação. Nenhum dos dois arquivos foi
commitado ainda nesta sessão.

### `sync-map-to-server.ps1` agora detecta sozinho nativo vs Docker
Dan roda o servidor nativo (`canary.exe` local), Pedro roda via Docker
(`docker/docker-compose.yml`, serviço `server`) — um único script não dava pra
funcionar pros dois sem um sobrescrever a configuração do outro a cada
`git pull`. Reescrito pra detectar automaticamente qual dos dois está disponível
na máquina (`canary.exe` existe → modo nativo; senão, container do serviço
`server` rodando via `docker compose ps -q server` → modo Docker) e escolher a
sequência de comandos certa sozinho. Nenhuma configuração manual necessária;
o arquivo continua único e versionado, sem risco de conflito entre as duas
formas de rodar o servidor.

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
