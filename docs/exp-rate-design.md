# Taxa de experiência (stages.lua) — implementado

**Status: APLICADO em `data/stages.lua` em 2026-08-07.** Este documento registra o
raciocínio/números por trás da tabela, pra caso alguém (Pedro, Dan, ou eu numa sessão futura)
precise entender o porquê de um valor específico ou recalibrar depois de testes reais.

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

## Tabela final de multiplicadores (aprovada em 2026-08-06)

| Faixa de nível | Multiplicador |
|---|---|
| 1-100 | 3x |
| 101-200 | 7x |
| 201-300 | 11x |
| 301-400 | 13x |
| 401-500 | 15x |
| 501-700 | 34x |
| 701-850 | 43x |
| 851-1000 | 52x |
| 1001-1200 | 58x |
| 1201-1350 | 63x |
| 1351-1500 | 68x |
| 1501-1750 | 74x |
| 1751-2000 | 80x |
| 2001-2500 | 85x |
| 2501-3000 | 91x |

Sobe em degraus suaves de propósito — a versão inicial tinha só 5-6 faixas com saltos grandes
(ex: 58x → 100x direto no level 1000), o que criava uma inconsistência real: um jogador level
900 levava mais tempo pra subir um level que um jogador level 1100, só por causa do salto
abrupto de multiplicador bem na fronteira. Mais faixas = transição suave = sem esse efeito.

## Tempo estimado resultante (acumulado desde o level 1)

| Nível | Solo | Grupo x4 |
|---|---|---|
| 100 | ~4,4h | ~2,9h |
| 200 | ~12,1h | ~8,1h |
| 300 | ~23,9h | ~15,9h |
| 400 | ~35,6h | ~23,8h |
| 500 | ~47,4h | ~31,6h |
| 700 | ~62h | ~41,3h |
| 850 | ~74,8h | ~49,9h |
| 1000 | ~88,5h | ~59h |
| 1200 | ~110,6h | ~73,8h |
| 1350 | ~130,6h | ~87h |
| 1500 | ~152,9h | ~101,9h |
| 1750 | ~195,4h | ~130,2h |
| 2000 | ~245,3h | ~163,5h |
| 2500 | ~369,6h | ~246,4h |
| 3000 | ~529,7h | ~353,1h |

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
   faixas — versão vigente deste documento.

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
