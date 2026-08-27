# Taxa de experiência (stages.lua) — implementado

**Status: APLICADO em `data/stages.lua` em 2026-08-07, e ATIVADO de verdade em
2026-08-23** (a tabela ficou pronta no arquivo mas `rateUseStages` continuou
`false` no `config.lua` por 16 dias — o servidor rodou nesse período com rate
flat 1x em tudo, sem ninguém perceber, até o Pedro perguntar e eu conferir o
config ao vivo). `rateUseStages = true` aplicado direto no container rodando
e também adicionado ao `sync-map-to-server.ps1` (mesmo padrão do
`toggleMapCustom`), porque `/canary/config.lua` não fica em volume
persistente — some se o container for recriado do zero. Este documento
registra o raciocínio/números por trás da tabela, pra caso alguém (Pedro,
Dan, ou eu numa sessão futura) precise entender o porquê de um valor
específico ou recalibrar depois de testes reais.

**Atualização 2026-08-27 — faixas 501+ reduzidas em ~40%.** Depois de rodar
com dado real, o Pedro identificou dois fatores que a calibração original (via
XP/hora do Tibia global) não tinha como prever: (1) as hunts do servidor vão
ter monstros customizados dando mais XP que os equivalentes globais, e (2) os
personagens batem muito mais forte por causa do escalonamento de dano por
skill (ver `docs/skill-power-design.md`), então matam mais rápido — as duas
coisas juntas fazem o XP/hora real ficar acima do baseline usado pra calcular
os multiplicadores, especificamente nas faixas altas (o 1-100 já tinha sido
ajustado à parte, ver histórico abaixo). Em vez de arriscar overshoot (difícil
de reverter sem nerfar quem já progrediu), a decisão foi começar conservador
de 501 em diante e subir depois se o playtest mostrar que ficou lento demais.
De quebra, isso resolveu um salto abrupto que incomodava (401-500 em 15x pra
501-700 em 34x, mais que o dobro) — a tabela nova suaviza essa transição.
1-500 não foi mexido nesta rodada.

## Objetivo original

Servidor privado, só para amigos, **sem bots permitidos** (tudo manual). Pedro queria uma
progressão de XP escalonada por level que:

- Não deixasse o jogo "rápido demais" logo no início (não quer alguém pular pro level 100-300
  em meia hora e já queimar as primeiras hunts/gear sem sentir).
- Ainda assim tornasse **level 2000, possivelmente 3000, factível** de alcançar (não uma
  fantasia inatingível).
- Não travasse numa faixa específica virando repetição estagnada.
- Desse tempo pros jogadores sentirem progressão de equipamento e testarem hunts diferentes,
  principalmente até o level 500.

## Metodologia

1. **Fórmula real de XP por level**, extraída do próprio código do Canary
   (`src/creatures/players/player.cpp:4438`, `Player::getExpForLevel`):
   ```
   exp(level) = (((level-6)*level + 17)*level - 12) / 6 * 100
   ```
   Essa curva é praticamente quadrática por level (cúbica no total) — o custo de cada level
   sozinho cresce muito mais rápido que o level em si. Ex: o custo do level 2999→3000 sozinho
   é maior que a soma de todos os levels de 1 até 1000.

2. **XP/hora real, sem boost**, coletada de duas fontes:
   - `tibiaroute.com/hunting-places` (agregador de hunting spots do Tibia global) — deu XP/h
     por faixa de level, 8+ até 1100+.
   - Canal do YouTube `youtube.com/@TibiaHunt` (formato de título padronizado: `<VOC> <LEVEL>
     Hunt <Solo/xN> <Local> <X>kk/h Raw`) — 17 vídeos catalogados, níveis 8 a 1357, incluindo
     comparação solo vs grupo x4. Guardado em
     `tibia-server/docs/tibia-global-exp-por-nivel.xlsx` (aba "Dados Brutos" + médias por
     faixa).
   - **Achado importante**: XP/hora manual real sobe muito mais rápido com o level do que se
     imaginava inicialmente (de ~20-25 mil/h no level 8 até ~9-11 milhões/h no level
     1000-1400) — o próprio jogo já compensa boa parte da curva através de gear/hunts
     melhores, não só através do multiplicador de rate.
   - **Bônus de grupo (x4) medido**: em média **~1,5x** mais XP/hora por pessoa que solo
     (variou de 1,1x a 1,9x conforme a faixa, nos exemplos catalogados).
   - Acima de ~1400 não existe dado real (Tibia oficial não tem muito conteúdo testado além
     disso) — os valores usados ali pra frente são **extrapolação/estimativa**, e dependem de
     Pedro desenhar hunts de level alto com XP compatível quando chegar a hora.

3. Multiplicadores calculados dividindo "XP/hora necessário pra bater um alvo de tempo" pela
   "XP/hora real médio naquele level", faixa por faixa, ao invés de chutar números por
   sensação.

## Tabela final de multiplicadores (aprovada em 2026-08-06, revisada em 2026-08-27)

1-100 mudou fora desta tabela original (ver histórico de decisões abaixo: 3x →
6x em 24/08 → 12x em 26/08, valor vigente). Faixas 501+ reduzidas em ~40% em
27/08 (ver atualização no topo do documento).

| Faixa de nível | Multiplicador original (06/08) | Vigente |
|---|---|---|
| 1-100 | 3x | **12x** |
| 101-200 | 7x | 7x |
| 201-300 | 11x | 11x |
| 301-400 | 13x | 13x |
| 401-500 | 15x | 15x |
| 501-700 | 34x | **20x** |
| 701-850 | 43x | **25x** |
| 851-1000 | 52x | **30x** |
| 1001-1200 | 58x | **34x** |
| 1201-1350 | 63x | **37x** |
| 1351-1500 | 68x | **40x** |
| 1501-1750 | 74x | **43x** |
| 1751-2000 | 80x | **47x** |
| 2001-2500 | 85x | **50x** |
| 2501-3000 | 91x | **53x** |

Sobe em degraus suaves de propósito — a versão inicial tinha só 5-6 faixas com saltos grandes
(ex: 58x → 100x direto no level 1000), o que criava uma inconsistência real: um jogador level
900 levava mais tempo pra subir um level que um jogador level 1100, só por causa do salto
abrupto de multiplicador bem na fronteira. Mais faixas = transição suave = sem esse efeito.

## Tempo estimado resultante (acumulado desde o level 1)

Coluna "Original" usa a tabela de 06/08 (com 1-100 ainda em 3x, sem o boost de
24/08 e 26/08). Coluna "Vigente" usa a tabela de 27/08 (1-100 em 12x, 501+
reduzido ~40%) — é a que reflete o comportamento real do servidor hoje. Não
considera o efeito de monstros customizados nem o dano extra por skill, que
na prática devem compensar parte do aumento abaixo.

| Nível | Original (solo) | Vigente (solo) |
|---|---|---|
| 100 | ~4,4h | ~1,1h |
| 500 | ~47,4h | ~44,1h |
| 700 | ~62h | ~72,2h |
| 850 | ~74,8h | ~94,2h |
| 1000 | ~88,5h | ~117,9h |
| 1200 | ~110,6h | ~155,6h |
| 1350 | ~130,6h | ~189,7h |
| 1500 | ~152,9h | ~227,6h |
| 1750 | ~195,4h | ~300,7h |
| 2000 | ~245,3h | ~385,6h |
| 2500 | ~369,6h | ~596,9h |
| 3000 | ~529,7h | ~871,7h |

(Grupo x4 continua na ordem de ~1,5x mais rápido que solo, mesma proporção
observada nos dados originais.)

Exemplos pontuais já calculados no processo:
- Level 80 → 100 sozinho: ~2h10min (quase metade do tempo total pra chegar no 100, mesmo
  sendo só os últimos 20 levels daquele trecho).
- Level 1400 → 1401 sozinho: ~8min.

## Histórico de decisões (por que os números são esses e não outros)

1. Primeira tentativa: multiplicador caindo com o level (padrão comum de servidor OT) — Pedro
   rejeitou, porque a curva de XP do próprio jogo já desacelera sozinha; multiplicador caindo
   em cima disso criava uma parede impossível lá na frente (level 3000 levaria milhares de
   horas).
2. Segunda tentativa: multiplicador crescendo bastante (até 1300x no topo) — funcionava
   matematicamente mas os números pareciam "estranhos"/artificiais.
3. Terceira tentativa: multiplicador estável/decrescente (25x→10x) — Pedro pediu pra testar
   essa direção; o cálculo mostrou que criava exatamente a "parede" do problema 1 (nível 2000
   levaria ~1150h, nível 3000 ~4300h) — descartado.
4. A partir daí, convergiu pro modelo atual: multiplicador crescendo, mas devagar e em muitos
   degraus pequenos, calibrado com dado real de XP/hora (não chute), com valores fixos
   pedidos explicitamente por Pedro (6x → depois revisado pra 3x no 1-100; 100x fixo do 1000
   em diante → depois quebrado em mais faixas e reduzido sutilmente pra 58x-91x).
5. Pedro achou o ritmo de 1-500 ainda rápido demais (queria mais tempo pra sentir progressão
   de gear) — multiplicadores dessa faixa foram reduzidos pela metade (6x→3x, 14x→7x,
   22x→11x, 25x→13x, 28x→15x), dobrando o tempo até o level 500.
6. Redução sutil final (~10-15%) nas faixas acima de 500, junto com mais subdivisão de
   faixas — versão de 06/08.
7. 1-100 dobrado duas vezes após playtest real (3x → 6x em 24/08, 6x → 12x em 26/08) — ver
   `CHANGELOG.md` de 26/08.
8. 27/08: faixas 501+ reduzidas em ~40% (ver "Atualização 2026-08-27" no topo deste
   documento) — motivo diferente das reduções anteriores: não foi sensação de ritmo, foi
   correção preventiva por dois fatores que a calibração original não incluía (monstros
   customizados com XP maior, dano mais alto por escalonamento de skill).

## Pendências pra quando for implementar de verdade

- Confirmar com Pedro se o `GroupStorage`/lógica de bônus de grupo do próprio Canary precisa
  de ajuste separado, ou se o bônus "~1,5x" observado no Tibia real já é um efeito natural de
  gameplay (matar mais rápido em grupo) que não precisa de código extra aqui — os
  multiplicadores acima já assumem que esse efeito acontece sozinho, não somam um bônus de
  grupo dentro do `stages.lua`.
- Quando Pedro desenhar hunts de nível 1000+, os monstros precisam dar XP compatível com o
  crescimento assumido (baseline extrapolado de ~9M/h em 1000 até ~13M/h em 3000) — senão o
  tempo real vai ficar mais lento que a tabela acima projeta.
- `skillsStages` e `magicLevelStages` (também em `data/stages.lua`) não foram discutidos nessa
  conversa — só a tabela `experienceStages`.
