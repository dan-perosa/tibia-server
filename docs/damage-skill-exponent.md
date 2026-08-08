# Expoente de skill/magic level nas fórmulas de dano — n = 1.1

**Status: APLICADO em 2026-08-07.** Segundo passo da reformulação das fórmulas de dano (o
primeiro foi [`damage-formula-level-divisor.md`](damage-formula-level-divisor.md), o divisor de
level `/5` → `/4`). Este documento registra o quê, onde e por quê — pra caso alguém (Pedro, o
amigo dele, ou eu numa sessão futura) precise entender ou recalibrar depois de testes reais.

## O problema que isso resolve

Antes dessa mudança, tanto a skill de arma (club/sword/axe/distance/fist) quanto o magic level
entravam nas fórmulas de dano **linearmente** — cada ponto valia exatamente o mesmo dano, do 5 ao
105. Só que o **custo** de cada ponto não é linear: subir de skill 100 pra 101 exige muito mais
tries/kills do que subir de 5 pra 6 (a própria taxa de ganho de skill, em `data/stages.lua`, já
reconhece isso). Queríamos que o dano por ponto acompanhasse esse custo crescente.

## A solução: expoente em vez de tabela de estágios

Duas opções foram avaliadas (ver [`damage-skill-exponent-simulation.html`](damage-skill-exponent-simulation.html)
pra simulação completa com gráfico e números): uma tabela de estágios (igual ao `stages.lua`) ou
um expoente matemático (`skill^n` em vez de `skill`). Optamos pelo **expoente**, com
**n = 1.1** — decidido depois de comparar 1.05 vs 1.1 num conjunto de runas/magias reais (Sudden
Death, Avalanche, Exori Gran, Exevo Mas San, Exevo Gran Mas Flam) em personagens de nível 50 até
2500.

Com n = 1.1, um ponto de skill/maglevel no nível 200 vale **~43% mais dano** que o mesmo ponto no
nível 5 (contra 0% de diferença antes). O crescimento total de dano entre skill 5 e 200 sobe de
40x pra ~58x — um aumento moderado, não uma explosão.

## O que mudou, e onde

### 1. Armas (melee e distância) — C++

`src/items/weapons/weapons.cpp`. Em `Weapons::getMaxWeaponDamage` e nas duas funções de
`WeaponDistance` (`getElementDamage`, `getWeaponDamage`), o `attackSkill` que entrava direto na
multiplicação agora passa por `std::pow(attackSkill, 1.1)` antes:

```cpp
const double scaledSkill = std::pow(static_cast<double>(attackSkill), 1.1);
// ... 0.085 * attackFactor * attackValue * scaledSkill + level/4  (melee)
// ... 0.09  * attackFactor * attackValue * scaledSkill + level/4  (distância)
```

`Weapons::getMaxMeleeDamage` (usada só para **monstros**, em `monsters.cpp`) foi deixada de fora —
Pedro pediu pra não mexer em nada de monstro por enquanto.

Também entra aqui `data/scripts/weapons/scripts/diamond_arrow.lua` (munição especial de
distância, Lua): `distanceSkill` → `distanceSkill ^ 1.1`.

**É C++, precisa recompilar o `canary.exe` pra valer** — mesma pendência do divisor `/4`.

### 2. Runas e magias de ataque (fórmula level+maglevel) — Lua, 51 arquivos

Todos os arquivos com o padrão `(maglevel * A) + B` (ou `magicLevel`, só `stone_shower.lua` e
`thunderstorm.lua` usam esse nome) tiveram o `maglevel` trocado por `(maglevel ^ 1.1)`:

- `data/scripts/runes/*.lua` — 14 arquivos (sudden_death, avalanche, fireball, great_fireball,
  icicle, holy_missile, explosion, heavy_magic_missile, stalagmite, light_magic_missile,
  lightest_missile, light_stone_shower — e `stone_shower`/`thunderstorm` com `magicLevel`)
- `data/scripts/spells/attack/*.lua` — 38 arquivos (todas as strikes, waves, ultimate/strong
  variants, divine caldera/grenade, hells core, etc. Ver `formulas-de-dano.html` seção 6 pra
  lista completa)

**As duas runas de cura** (`intense_healing_rune.lua`, `ultimate_healing_rune.lua`) foram
deixadas de fora, de propósito — não são dano, e o pedido original era sobre dano.

Scripts Lua recarregam com `/reload` ou reinício do servidor — **não precisa recompilar**.

### 3. Magias skill-based (12 arquivos) — Lua

Arquivos que usam `skill` combinado com `attack` (item da arma) em vez de `maglevel`:
`ethereal_spear`, `lesser_ethereal_spear`, `strong_ethereal_spear`, `whirlwind_throw`,
`groundshaker`, `berserk`, `fierce_berserk`, `front_sweep`, `lesser_front_sweep`, `brutal_strike`,
`executioners_throw`, `annihilation`.

Importante: o expoente foi aplicado **só na variável `skill`**, nunca em `attack` (que é uma
propriedade do item equipado, não algo que o jogador "sobe" com uso). Exemplos:

```lua
-- antes:                        local skillTotal = skill * attack
-- depois:                       local skillTotal = (skill ^ 1.1) * attack

-- antes:  local min = (level / 4) + (skill + attack) * 0.5
-- depois: local min = (level / 4) + ((skill ^ 1.1) + attack) * 0.5
```

## Encontrado mas NÃO alterado (fora do escopo)

- `Weapons::getMaxMeleeDamage` (`weapons.cpp`) — usada por magias de **monstro**
  (`spell->skill, spell->attack` em `monsters.cpp`), não por jogador. Fora do escopo por pedido
  explícito do Pedro.
- `intense_healing_rune.lua`, `ultimate_healing_rune.lua` — cura, não dano.
- Fallback genérico do C++ (`Combat::getLevelFormula`) e Wand — mesma exclusão já registrada em
  `damage-formula-level-divisor.md`.
- O combo do Monge (`calculateFlatDamageHealing`) já tinha sua própria fórmula progressiva, sem
  relação com skill de arma/maglevel — não foi tocado aqui.

## Onde verificar o resultado

O documento [`formulas-de-dano.html`](formulas-de-dano.html) foi atualizado com as fórmulas
finais (`skill^1.1` / `maglevel^1.1`). O simulador
[`damage-skill-exponent-simulation.html`](damage-skill-exponent-simulation.html) continua útil
pra comparar outros valores de `n` se decidirem recalibrar no futuro.

## Pendências

- Recompilar e publicar um novo `canary.exe` (a parte de armas só vale depois disso — as magias/
  runas em Lua já valem imediatamente com reload).
