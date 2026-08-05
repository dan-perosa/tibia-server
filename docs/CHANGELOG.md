# Changelog do servidor privado

Registro do que foi feito, por quê, e o que aprendemos no processo. Mantido
por sessão de trabalho, mais recente no topo.

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
