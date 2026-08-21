# Changelog do servidor privado

Registro do que foi feito, por quê, e o que aprendemos no processo. Mantido
por sessão de trabalho, mais recente no topo.

---

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
