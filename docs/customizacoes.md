# Customizações fora do padrão OTServBR-Global

Registro do que é **nosso**, diferente do datapack oficial — pra saber rápido
o que não vem "de fábrica" caso algo quebre numa atualização futura do
Canary/OTServBR-Global, ou pra não redescobrir como algo foi feito.

Não é lista de pendência (isso é `PENDING.md`) nem histórico de sessão (isso
é `CHANGELOG.md`) — é o "o que é diferente daqui pra frente".

---

## Itens

- **43946-43950, promotion scrolls da Wheel of Destiny** (`abridged`/`basic`/
  `revised`/`extended`/`advanced`) — não são itens inventados, são oficiais
  de verdade, mas **faltava a entrada no `items.xml`** (bug pré-existente:
  `data/scripts/actions/items/wheel_scrolls.lua` já tinha o script de uso
  pronto desde antes, mas o item nunca podia ser criado no jogo). Corrigido
  em 31/08/2026 -- agora funcionam como o mecanismo oficial pretendia
  (decifra, ganha pontos de Wheel, nível 51+).

## Comandos (talkactions)

- `!tptemplo` (`data/scripts/talkactions/player/tptemplo.lua`) — qualquer
  jogador, teleporta pro templo da própria cidade.
- `!lastdeath` (`data/scripts/talkactions/god/lastdeath.lua`, só grupo god)
  — teleporta pro tile exato da última morte do personagem. Depende de uma
  gravação extra de posição em `data/scripts/creaturescripts/player/death.lua`
  (KV do jogador, escopo `last-death`) que não existe no Canary padrão — só
  funciona pra mortes a partir de 28/08/2026.

## Configs mudadas do padrão

- `adventurersBlessingLevel = 30` (padrão do Canary: 21) — bless de graça
  vai até nível 30, depois disso precisa comprar.
- `freePremium = true` (padrão: false).
- `autoLoot = true` (padrão: false) — feature nativa do Canary, só ligada.
- `bestiaryKillMultiplier = 3` (padrão: 1) — cada kill conta 3x pro progresso
  do bestiário (01/09/2026, pedido do Daniel).

## Mecânicas

- **Recompensa ao completar o bestiário de uma criatura** (chegar no último
  estágio de kills de UMA espécie — pedido do Daniel, 30-31/08/2026,
  implementado 31/08/2026). Dá um dos 5 promotion scrolls (ver "Itens"
  acima), escolhido pela raridade oficial da criatura
  (`MonsterType:BestiaryStars()`, 1 a 5 -- estrela 0/sem classificação cai no
  tier mais baixo). Só na primeira vez por criatura por jogador (marcado no
  KV do jogador, escopo `bestiary-scroll-reward`).
  - `data/events/scripts/player.lua`, função `checkBestiaryPromotionReward`
    + hook em `Player:onGainExperience`. Detalhe de implementação: dispara
    via `addEvent(..., 0, ...)` porque `onGainExperience` roda ANTES do
    C++ atualizar a contagem de kill do bestiário
    (`Player::onKilledMonster` -> `IOBestiary::addBestiaryKill`, chamado
    logo depois na mesma função em `src/creatures/creature.cpp`) -- sem
    esse delay de 0ms, `player:isMonsterBestiaryUnlocked()` ainda refletiria
    o estado de ANTES da morte atual.
  - Só completar 1 criatura por vez conta (não categoria inteira, não 100%
    do bestiário).

### Nota técnica: como gerar a galeria de sprites livres de novo

`data/items/appearances.dat` é um protobuf (schema em
`src/protobuf/appearances.proto`) listando todo sprite válido que o client
conhece. `data/items/items.xml` é bem mais completo que o catálogo do RME
(`rme/canary-map-editor-v4.0-windows/data/items/items.xml` é só um
subconjunto antigo — não serve de referência pra achar "sprite livre").

Os arquivos de sprite (`client/assets/sprites-*.bmp.lzma`) usam LZMA cru,
não o formato `.xz`/`.lzma` padrão que biblioteca nenhuma abre direto:
- 24 bytes de padding zerado
- 8 bytes (não identificado, ignorado)
- a partir do byte 32: cabeçalho LZMA_ALONE de verdade (1 byte de props +
  4 bytes dict_size little-endian + 8 bytes que parecem tamanho descomprimido
  mas na prática não batem com a saída real — ignorar e deixar o decoder
  descomprimir até o fim)
- daí em diante, stream LZMA1 puro (`lzma.FORMAT_RAW` em Python, com
  `lc`/`lp`/`pb` extraídos do byte de props)

Cada planilha descomprime pra um BMP RGBA de 384×384 (grade 12×12 de
sprites 32×32). A cor de fundo transparente é magenta pura (255,0,255),
salva opaca nesse formato — precisa converter pra alpha=0 manualmente.
