# Rate de skill/magic level e poder por dano — implementado 2026-08-24

**Status: APLICADO em `data/events/scripts/player.lua`** (`Player:onGainSkillTries` e
`Player:onCombat`). Este documento registra o raciocínio e o histórico de idas-e-voltas por trás
dos números, pra caso alguém (Pedro, Dan, ou eu numa sessão futura) precise entender ou
recalibrar depois de testes reais — mesmo padrão de [`exp-rate-design.md`](exp-rate-design.md).

Duas coisas separadas, desenhadas na mesma conversa:

1. **Rate de ganho de skill/magic level** — quão rápido cada ponto é conquistado.
2. **Poder por dano** — quanto cada ponto de skill/magic level vale em dano causado.

## 1. Rate de skill/magic level

### Por que não usar `skillsStages`/`magicLevelStages` (o sistema padrão do Canary)

O Canary já tem um sistema de tabela de faixas (`data/stages.lua`, mesmo mecanismo do
`experienceStages`), mas ele **tem teto** — a última faixa sem `maxlevel` fica com um
multiplicador fixo pra sempre. Pedro pediu explicitamente que o bônus **nunca pare de crescer**
(sem teto), então trocamos a tabela de faixas por uma **fórmula contínua**, calculada direto em
`Player:onGainSkillTries` (substituindo totalmente `getRateFromTable`/`skillsStages`/
`magicLevelStages`/`rateSkill`/`rateMagic` — esses ficam sem efeito nenhum agora).

### Metodologia (dados reais do próprio motor)

- **Custo bruto real:** `vocation.cpp:265` (`Vocation::getReqSkillTries`) — cada ponto de skill
  custa `skillBase[skill] × multiplicadorDaVocação^(nível-11)`. O multiplicador varia por
  vocação/skill: `1.1` pra skill principal de vocação dedicada (ex: espada de Knight) até `2.0`
  pra skills fora do papel da vocação. Pra magic level, `vocation.cpp:304`
  (`Vocation::getReqMana`) usa `1600 × manaMultiplier^(nível-1)` — mago dedicado também usa
  `1.1`.
- **Tries por hit real, medido no código:** `addSkillAdvance(SKILL_FIST, 1)` confirma 1 try por
  hit em combate normal. Pro treino em dummy (`exercise_training_weapons.lua`), cada hit dá
  **7 tries** (`player:addSkillTries(skill, 7 * rate)`, dummy padrão tem `rate=100` → 7 exatos),
  a cada `attackspeed da vocação (2000ms) / rateExerciseTrainingSpeed` — ou seja, 1 hit a cada 2s
  no padrão. Uma **arma de exercício com 14.400 cargas = exatamente 8 horas** de treino contínuo
  (14.400 × 2s = 28.800s).
- Com esses números batidos contra o Tibia oficial "puro" (rate 1x): chegar na skill 100 levaria
  **~26 armas de exercício (~211h)**; skill 150, **~3.100 armas (~24.800h)** — confirma por que
  todo servidor precisa de boost, o oficial é inviável de treinar até skill alta.

### Calibração (conversa iterativa com o Pedro, 2026-08-24)

Não existe fonte de dado externo real pra isso (diferente do XP, que teve `tibiaroute`/YouTube).
A calibração foi feita com âncoras do próprio Pedro, ajustadas em várias rodadas:

1. Primeira tentativa: expoente único `1,34 × 1,075^(skill-10)` calibrado por hora de hunt
   genérica (chute de 1.800 tries/hora) — Pedro achou 17h pra skill 200 rápido demais.
2. Corrigido o chute de tries/hora usando o **dummy real** (7 tries/hit, não 1) — ficaria ainda
   mais rápido se mantidas as mesmas constantes, confirmando que a rate precisava cair bem mais,
   não só um ajuste fino.
3. Pedro deu duas âncoras concretas em armas de exercício consumidas: **~5 armas até skill 100,
   ~30 armas até skill 200**. Calibração resultante: skill 100 em 40h — Pedro achou o **início**
   longo demais (queria muito mais rápido de 10 a 100).
4. Pedro admitiu não ter instinto suficiente pra cravar horas/armas com precisão antes de jogar
   de verdade — pediu um ponto de partida conceitual pra testar e ajustar ele mesmo depois.
   Ficaram dois critérios conceituais: (a) sem parede em nenhum ponto (nunca "impossível" de
   upar), (b) rate no nível de skill 150 equivalente a **~4.674x** (o próprio número calculado
   numa iteração anterior, que pareceu certo pro Pedro).
5. Um único expoente não consegue ser "rápido de 10 a 100" **e** pousar exatamente em 4.674x no
   150 **e** ficar mais difícil depois — por isso a fórmula final tem **3 fases**.

### Fórmula final

```lua
local function customSkillRate(currentSkillLevel)
	if currentSkillLevel <= 100 then
		return 1.34 * (1.0846 ^ (currentSkillLevel - 10))
	elseif currentSkillLevel <= 150 then
		return 2000 * (1.0171 ^ (currentSkillLevel - 100))
	else
		return 4674 * (1.05 ^ (currentSkillLevel - 150))
	end
end
```

Mesma fórmula pra skill de arma (`getSkillLevel(skill)`) e magic level
(`getBaseMagicLevel()`) — `Player:onGainSkillTries` escolhe qual usar.

| Skill | Multiplicador equivalente (rate 1x = oficial) | Tempo estimado (dummy) |
|---|---|---|
| 10 | 1,3x | 0h |
| 100 | 2.000x | ~30 min |
| 120 | ~2.809x | ~1h |
| **150** | **4.674x** (âncora do Pedro) | ~6,7h (~0,8 arma) |
| 200 | ~53.600x | ~105h (~13 armas) |
| 250 | ~614.600x | ~1.105h (~138 armas) |
| 300 | ~7.056.300x | ~11.365h (~1.421 armas) |

**Isso é chute calibrado por conversa, não medição real de playtest.** Pedro sinalizou
explicitamente que vai testar in-game e pedir ajuste. Os 3 números de crescimento (`1,0846` /
`1,0171` / `1,05`) são os botões certos pra mexer:
- `1,0846` (fase 10-100): sobe = início mais rápido ainda; desce = início mais devagar.
- `1,0171` (fase 100-150): ajusta a transição sem perder a âncora de 150 (se mudar, recalcular
  a constante de partida da fase 3 pra não perder os 4.674x — não é só trocar o número solto).
- `1,05` (fase 150+): sobe = fica mais fácil lá na frente (menos "parede"); desce = fica ainda
  mais difícil (mais "sem teto de verdade").

## 2. Poder por dano — bônus sobre skill/magic level

### Histórico: por que não é a abordagem antiga (`skill^n` dentro de cada fórmula)

Uma sessão anterior (07/08) já tinha implementado um conceito parecido — expoente `skill^1.1` /
`maglevel^1.1` editado direto dentro de cada fórmula de dano (ver
[`damage-skill-exponent.md`](damage-skill-exponent.md)). Esse approach tinha dois problemas
descobertos nesta conversa:

1. **Armas corpo-a-corpo/distância** ficam em `src/items/weapons/weapons.cpp` — código C++, que
   precisa ser **recompilado** pra valer. O servidor do Pedro roda via Docker com a imagem
   pronta `ghcr.io/opentibiabr/canary:latest` (não compila do código-fonte local), então essa
   parte **nunca chegou a valer de verdade** nesses 17 dias — só as 51 magias/runas em Lua
   (essas sim já ativas, recarregam com `/reload`).
2. Mesmo ignorando o problema do C++, precisaria editar dezenas de arquivos de magia/runa
   individualmente, e qualquer magia nova criada no futuro ficaria de fora até alguém lembrar de
   editá-la também.

### Solução: um hook central, fora da fórmula de cada arma/magia

`Player:onCombat(target, item, primaryDamage, primaryType, secondaryDamage, secondaryType)`
(`events.xml`, já habilitado) roda **depois** que o motor já calculou o dano, não importa se veio
de autoataque, magia ou runa — é chamado uma vez só, sempre, pra qualquer dano causado pelo
jogador (`combat.cpp:721`, `g_events().eventPlayerOnCombat`). Aplicando um multiplicador ali,
por cima do resultado final, cobre os três casos de uma vez, sem tocar em C++ e sem editar
arquivo de magia nenhum (nem os que ainda não existem).

**Trade-off assumido:** isso não reproduz exatamente os mesmos números que editar o expoente
dentro de cada fórmula produziria (o bônus multiplica o dano *total*, incluindo termos que não
deveriam crescer com skill, tipo o termo de `level/4`) — mas é uma aproximação aceitável dado o
objetivo (impacto exponencial perceptível, simplicidade, sem risco de infraestrutura). Pedro
confirmou que os números de referência usados pra calibrar (~10 mil de dano num Exori Gran em
nível 2500) foram um chute dele sem embasamento — **não são meta a bater**, só serviram de
sanity check de ordem de grandeza durante o desenho.

### Fórmula final

```lua
local powerMultiplier = (math.max(relevantStat, 10) / 10) ^ 0.3
primaryDamage = primaryDamage * powerMultiplier
secondaryDamage = secondaryDamage * powerMultiplier
```

- `relevantStat` = magic level (`getBaseMagicLevel()`) se o tipo de dano for mágico/elemental
  (energy/earth/fire/ice/holy/death/lifedrain/manadrain); senão, a skill de arma correspondente
  ao item equipado (mapeamento `WEAPON_SWORD→SKILL_SWORD` etc., fist como fallback pra
  desarmado).
- Cura (`COMBAT_HEALING`) fica de fora, de propósito — mesmo critério da sessão anterior.
- Bônus = **1x exatamente** na skill/ML inicial (10) — dano vanilla, sem mudança — e cresce **sem
  teto** dali em diante (nunca achata pra um valor fixo).

**Expoente ajustado em 24/08 (mesmo dia): 0,5 (raiz quadrada) → 0,3.** O Daniel mencionou já ter
escrito o esquema antigo de expoente embutido (`n = 1.1`, ver seção "Histórico" acima) — nunca
chegou a testar rodando (mesma limitação: precisa recompilar, ele roda nativo, não testou). Pedro
pediu um meio-termo entre esse `n = 1.1` antigo e o `√` que ficou forte demais. Comparando o
"quanto mais forte" na mesma régua (skill 10 → 200):

| Expoente | Dano a mais (skill 10→200) |
|---|---|
| `n = 1,1` (esquema antigo do Daniel, nunca testado rodando) | ~43% |
| `^0,3` (atual) | ~146% |
| `^0,5` / raiz quadrada (versão anterior de hoje) | ~347% |

Botão de ajuste: o `0.3` no final da fórmula — sobe = mais forte, desce = mais fraco (mantém o
mesmo formato "1x na skill 10, sem teto" não importa o valor).

| Skill/ML | Bônus |
|---|---|
| 10 | 1x |
| 100 | 2,00x |
| 200 | 2,46x |
| 300 | 2,78x |

## Pendências

- Validar os 3 números de crescimento da rate de skill jogando de verdade (ver seção 1).
- Se algum dia fizer sentido recompilar um `canary.exe` customizado (pro Dan, que já roda nativo),
  a abordagem antiga (`skill^1.1` dentro de `weapons.cpp`) continua lá, sem uso — não precisa
  reativar, já que o hook central cobre a mesma necessidade sem depender disso.
