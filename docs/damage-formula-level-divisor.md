# Divisor de level nas fórmulas de dano — level/5 → level/4

**Status: APLICADO em 2026-08-07.** Este documento registra o que foi mudado, onde, e por quê —
pra caso alguém (Pedro, o amigo dele, ou eu numa sessão futura) precise entender o porquê de um
valor específico ou reverter/recalibrar depois de testes reais.

## O que mudou

Toda fórmula de dano do servidor que usa o **level do personagem** como variável aditiva mudou o
divisor de `level / 5` para `level / 4` — ou seja, o nível do personagem passou a valer ~25% mais
na parte "base" do dano, em todas as categorias abaixo.

Isso foi decidido como primeiro passo de uma reformulação mais ampla das fórmulas de dano do
servidor (ver [`formulas-de-dano.html`](formulas-de-dano.html) na raiz do repositório pra
catálogo completo de todas as fórmulas de dano do projeto, C++ e Lua).

## O que NÃO mudou (de propósito, por decisão do Pedro)

- **Wand** — não usa level na fórmula de dano (é fixo, por item). Fica assim por hora.
- **Fallback genérico do C++** (`Combat::getLevelFormula`, `level*2 + maglevel*3`,
  em `src/creatures/combat/combat.cpp`) — confirmado que nenhuma magia/runa de dano do projeto
  usa esse caminho hoje (todas registram callback Lua próprio via
  `combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, ...)`, que sempre tem prioridade sobre o
  fallback). Deixado de lado por não ter efeito prático.
- **Skills/magic level** (`RATE_SKILL`/`RATE_MAGIC`/stages) — não tem nada a ver com esse tema.

## As 4 categorias alteradas

### 1. Armas (melee e distância) — C++

`src/items/weapons/weapons.cpp`. 7 ocorrências de `level / 5` (ou `player->getLevel() / 5`)
trocadas por `/ 4`, em:

- `Weapons::getMaxWeaponDamage` (usado por melee e distância)
- `Weapon::getCombatDamage`
- `WeaponMelee::getElementDamage`
- `WeaponMelee::getWeaponDamage`
- `WeaponDistance::getElementDamage`
- `WeaponDistance::getWeaponDamage`

Também entra aqui `data/scripts/weapons/scripts/diamond_arrow.lua` — não é o sistema genérico de
armas, é um override em Lua específico pra essa munição, mas usa a mesma fórmula
(`0.09 × factor × skill × attack + level/5`) então foi tratado como parte dessa categoria. Esse
arquivo é Lua, então **não precisa recompilar**, só reload/reinício.

**Importante: o código C++ (`weapons.cpp`) precisa recompilar o `canary.exe` pra valer.** Só editar o
arquivo não muda nada no servidor rodando — precisa gerar um build novo (workflow do GitHub
Actions ou compilação local) e trocar o executável.

### 2. Runas e magias de ataque (fórmula `level/X + maglevel×A + B`) — Lua

Todos os arquivos que seguem o padrão `local min = (level / 5) + (maglevel * A) + B`, em:

- `data/scripts/runes/*.lua` (14 arquivos: sudden_death, avalanche, fireball, great_fireball,
  icicle, holy_missile, explosion, heavy_magic_missile, stalagmite, light_magic_missile,
  lightest_missile, stone_shower, thunderstorm, light_stone_shower)
- `data/scripts/spells/attack/*.lua` (37 arquivos — todas as strikes elementais, waves, ultimate/
  strong variants, divine caldera/grenade, etc. Ver `formulas-de-dano.html` seção 6 pra lista
  completa com fórmula de cada uma)

Trocados via `sed` (substituição de texto simples `level / 5` → `level / 4`, escopo restrito só
a esses arquivos, não repo inteiro). São scripts Lua, recarregam com `/reload` no jogo ou reinício
do servidor — **não precisa recompilar**.

### 3. Magias skill-based (Berserk, Groundshaker, Ethereal Spear, etc.) — Lua

Mesmo tratamento, arquivos que usam `level` combinado com `skill`/`attack` em vez de `maglevel`:
`ethereal_spear`, `lesser_ethereal_spear`, `strong_ethereal_spear`, `whirlwind_throw`,
`groundshaker`, `berserk`, `fierce_berserk`, `front_sweep`, `lesser_front_sweep`, `brutal_strike`,
`executioners_throw`, `annihilation` (todos em `data/scripts/spells/attack/`).

Detalhe: 6 desses arquivos usam `player:getLevel() / 5` em vez de `level / 5` (variável local vs.
chamada de método) — precisou de uma segunda passada de substituição com o padrão certo
(`getLevel() / 5` → `getLevel() / 4`).

### 4. Combo do Monge (`calculateFlatDamageHealing`) — C++, progressivo

`src/creatures/players/player.cpp`, função `Player::calculateFlatDamageHealing` (linha 578).
Essa função não é um `/5` fixo — é uma baseline que **começa** num divisor e vai diminuindo o peso
do level (aumentando o divisor) a cada 500+600×tier levels. Só o **ponto de partida** mudou:

```cpp
// Antes: começava em 1/5, progressão 1/5 → 1/6 → 1/7 → 1/8...
double currentLevelFactor = 1.0 / 5.0;
...
currentLevelFactor = 1.0 / (5.0 + tierIndex);
previousLevelsAggregatedBaseline += threshold * (1.0 / (5.0 + tierIndex - 1));

// Depois: começa em 1/4, progressão 1/4 → 1/5 → 1/6 → 1/7...
double currentLevelFactor = 1.0 / 4.0;
...
currentLevelFactor = 1.0 / (4.0 + tierIndex);
previousLevelsAggregatedBaseline += threshold * (1.0 / (4.0 + tierIndex - 1));
```

Ou seja, a progressão continua idêntica (sobe 1 no divisor a cada tier), só desloca o ponto de
partida — no level 500 essa função já estava efetivamente em `/6` antes da mudança, e passa a
estar em `/5` agora; o formato da curva não muda, só o nível de referência.

**Também é C++ — precisa recompilar.**

## Onde verificar o resultado

O documento [`formulas-de-dano.html`](formulas-de-dano.html) foi atualizado com os novos
valores (`/4` em vez de `/5`) em todas as seções afetadas. Se decidirem mudar o divisor de novo,
atualizem os dois lugares: o código/scripts E esse HTML — eles não se sincronizam automaticamente.

## Encontrado mas NÃO alterado (fora do escopo — level de monstro, não de personagem)

Uma varredura final no repositório inteiro achou 2 magias de **monstro** (não de jogador) que
também usam um padrão `level / 5` dentro de `onGetFormulaValues`:
`data-otservbr-global/scripts/spells/monster/twisted_shaper_ice.lua` e
`.../ice_crystal_bomb.lua`. O parâmetro ali é o level/magic level de quem lança a magia — nesses
dois casos, o próprio monstro, não o personagem do jogador. Como o pedido foi especificamente
sobre o level do **personagem**, esses dois ficaram de fora. Se um dia quiserem revisar dano de
monstro que escala com o próprio level do monstro, é por aqui.

## Pendências

- Recompilar e publicar um novo `canary.exe` (as mudanças de armas e do combo do Monge só valem
  depois disso).
- Wand e o fallback genérico do C++ ficaram de fora por decisão explícita — revisitar se algum
  dia quiserem mexer neles também.
