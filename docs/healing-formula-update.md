# Fórmulas de cura — mesmo tratamento do dano (level/4 + maglevel^1.1)

**Status: APLICADO em 2026-08-07.** Extensão das duas mudanças já feitas em dano
([`damage-formula-level-divisor.md`](damage-formula-level-divisor.md) e
[`damage-skill-exponent.md`](damage-skill-exponent.md)) pras magias e runas de **cura**, que
usam a mesma estrutura matemática (`level/5 + maglevel×A + B`) só com sinal positivo e tipo
`COMBAT_HEALING`.

## Exemplo que motivou a decisão

Simulado antes de aplicar (Exura Vita = Ultimate Healing):

| Personagem | Hoje (level/5, ML linear) | Com a mudança (level/4, ML^1.1) | Ganho |
|---|---|---|---|
| Nível 500, ML 120 | 958–1738 | 1484–2714 | ~55% |
| Nível 1500, ML 40 | 614–906 | 810–1211 | ~33% |
| Nível 1500, ML 140 | 1294–2196 | 1977–3425 | ~54% |

## O que mudou

Levantei os 30 arquivos de cura (28 em `data/scripts/spells/healing/` + 2 runas em
`data/scripts/runes/`) e categorizei antes de tocar:

### Grupo A — level em `/5` (ou equivalente `* 0.2`) → `/4` (`* 0.25`), e magic level → `^1.1`

17 arquivos:

- **Runas**: `intense_healing_rune.lua`, `ultimate_healing_rune.lua`
- **Magias**: `bruise_bane`, `divine_healing`, `fair_wound_cleansing`, `heal_friend`,
  `intense_healing`, `intense_wound_cleansing`, `light_healing`, `salvation`, `spirit_mend`,
  `ultimate_healing` (Exura Vita), `wound_cleansing`, `mass_healing`, `mass_spirit_mend`

`restoration.lua` é um caso especial: usa `level * 1.4 / 5` (a nota no código diz "40% extra em
cima da Ultimate Healing") — mantive a proporção, virou `level * 1.4 / 4`.

### Grupo B — level com divisor DIFERENTE de 5, não tocado (só magic level virou `^1.1`)

3 arquivos, onde o level já usava uma proporção customizada, diferente do padrão `/5` — deixei
como o autor original decidiu, só a parte do magic level entrou no padrão novo:

- `nature's_embrace.lua` — usa `level / 2.5` (o dobro do peso padrão)
- `restore_balance.lua` — usa `level * 0.5` (2.5x o peso padrão)
- `magic_patch.lua` — usa `level * 0` (level não conta nada nessa magia, deliberado)

### Grupo C — sem fórmula, nada a mudar

- `cure_bleeding`, `cure_burning`, `cure_curse`, `cure_electrification`, `cure_poison` — só
  removem condição, não curam quantidade
- `heal_malice` (15000/30000 fixo), `heal_monsters`/`heal_monsters_9x9` (curam **monstro**, valor
  fixo), `practise_healing` (5/9 fixo, magia de treino)
- `recovery`/`intense_recovery` (Utura/Utura Gran) — buff de regeneração com ganho fixo por
  tick (20/40), não é uma fórmula de "cura instantânea"

## Onde verificar

As 2 linhas de referência em [`formulas-de-dano.html`](formulas-de-dano.html) (seção de Runas)
foram atualizadas com os novos valores. As magias de `data/scripts/spells/healing/` não estavam
catalogadas nesse HTML (ele é focado em dano) — a lista completa fica só aqui.

Tudo em Lua — **não precisa recompilar**, só `/reload` ou reinício do servidor.
