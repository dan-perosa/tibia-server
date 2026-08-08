# Fórmula de preço de arrows/bolts — implementado

**Status: aplicado em `data-otservbr-global/npc/asnarus.lua` em 2026-08-08.** Este documento
registra a regra usada pra precificar munição nova (arrows/bolts), pra reaplicar de forma
consistente da próxima vez que uma nova arrow ou bolt for adicionada à loja.

## Objetivo

A Asnarus vende munição copiando a base do NPC oficial "Archery's Hut"
(`data-otservbr-global/npc/archery.lua`), mas dois itens desse NPC oficial (`burst arrow`,
`infernal bolt`) tinham preços claramente fora de proporção com o resto da progressão de dano
(ex.: infernal bolt custava só 13gp com 72 de ataque, menos por ponto de dano que itens muito
mais fracos). Em vez de copiar esses valores cegamente, definimos uma regra própria.

## Metodologia

1. Ordenar as munições da mesma família (arrows entre si, bolts entre si) por atributo
   `attack` (`data/items/items.xml`), do menor pro maior.
2. Pra cada item, olhar o **item imediatamente anterior na escala de ataque que já tem preço
   definido** (não necessariamente o item base da família — ver nota sobre munição "de
   efeito" abaixo).
3. Regra de três simples pelo ataque:
   `preço_bruto = preço_anterior × (ataque_novo / ataque_anterior)`
4. Adicionar 10% em cima do resultado:
   `preço_final = preço_bruto × 1.10`
5. Arredondar pro inteiro mais próximo (gold não tem casas decimais).

Esse +10% por degrau é proposital: cria uma penalidade progressiva de custo-por-dano conforme
sobe de tier, então munição mais fraca/barata continua sendo uma opção economicamente viável
pra caçar, em vez de virar sempre estritamente pior que a de cima.

**Munição "de efeito" (poison, splash/área, elemental) não usa o item base puro como
"anterior"** — usar outro item de efeito de ataque parecido como âncora, já que o preço desses
itens embute um prêmio pelo efeito especial, não só pelo dano bruto. Ex.: `burst arrow` (27 de
ataque, dano em área) foi ancorada em `envenomed arrow` (27 de ataque, efeito de veneno) em vez
da `arrow` simples (25 de ataque, sem efeito) — usar a arrow base teria dado um preço
artificialmente baixo (~2gp) que ignora o valor do efeito.

## Exemplo aplicado (2026-08-08)

- **burst arrow** (27 ataque) — anterior: `envenomed arrow` (27 ataque, mesmo tier de ataque,
  também item de efeito, 12gp).
  `12 × (27/27) = 12` → `× 1.10 = 13,2 → 13gp`

### Revisão: infernal bolt e reajuste geral de bolts

A primeira tentativa (regra de três só contra o vizinho de baixo, `prismatic bolt`) deu 24gp
pra infernal bolt — Pedro apontou que isso ficava desproporcional frente à `spectral bolt`
(78 ataque, 70gp, preço legado/fixo): entre `prismatic`(66,20) e `spectral`(78,70) o "prêmio"
real observado (além do proporcional por ataque) é de quase 200%, um salto muito maior que o
+10% por degrau usado nos degraus mais baixos — porque esse trecho pula direto sobre a
`infernal bolt`, que fica exatamente no meio.

**Correção:** quando o item novo fica entre dois preços já fixos/estabelecidos, dividir esse
prêmio "pulado" em partes iguais (raiz quadrada do fator total) entre os dois degraus, em vez
de aplicar só +10% contra um dos lados:
```
fator_total = (preço_acima / preço_abaixo) / (ataque_acima / ataque_abaixo)
premio_por_degrau = sqrt(fator_total)
preço_novo = preço_abaixo × (ataque_novo / ataque_abaixo) × premio_por_degrau
```
Pra infernal bolt: `fator_total = (70/20)/(78/66) = 2,96`, `sqrt = 1,72`.
`preço = 20 × (72/66) × 1,72 ≈ 38gp` (confere: `38 × (78/72) × 1,72 ≈ 70gp`, bate com a
spectral bolt).

**Depois disso, Pedro pediu pra triplicar o preço de TODAS as bolts** (gold sink geral, não só
correção da infernal) — mantendo infernal acima da prismatic, já que ela tem mais ataque (72 vs
66) apesar de ser menos usada na prática por ser mais rara/exigir level mais alto.

## Tabela final de bolts (2026-08-08)

| bolt | ataque | preço |
|---|---|---|
| bolt | 30 | 12 |
| piercing bolt | 33 | 15 |
| vortex bolt | 36 | 18 |
| power bolt | 40 | 21 |
| drill bolt | 56 | 36 |
| prismatic bolt | 66 | 60 |
| infernal bolt | 72 | 114 |
| spectral bolt | 78 | 210 |

Confirmado contra `https://www.tibiawiki.com.br/wiki/Munição` que essas são as 8 únicas bolts
oficiais que existem — não falta nenhuma.

## Cobertura final: "todas as arrows e bolts disponíveis no jogo" (2026-08-08)

Pedro pediu pra Asnarus vender literalmente todas as arrows/bolts do jogo, com preço coerente
por ataque em tudo exceto a `diamond arrow` (mantida fixa em 130gp por decisão explícita dele,
item de raridade, não de dano). Checagem final:

- **Bolts**: as 8 oficiais (ver tabela acima) — completo.
- **Arrows físicas**: `arrow`(25,2), `sniper arrow`(28,5), `tarsal arrow`(33,6),
  `onyx arrow`(38,7), `crystalline arrow`(65,20), `diamond arrow`(37,130 fixo) — completo.
  **Nota**: o salto `arrow`→`sniper arrow` (2gp→5gp) é maior que o padrão dos degraus
  seguintes (a fórmula prevê ~2,5gp); Pedro decidiu explicitamente **não mexer** nisso, manter
  os 4 preços como já estavam.
- **Arrows de efeito**: `flash/shiver/flaming/earth arrow`(14, 5 cada), `envenomed arrow`(27,
  12), `burst arrow`(27, 13) — completo.
- **`poison arrow`** (id 3448) estava faltando — adicionada. **Cuidado**: o `items.xml` lista
  ataque 23, mas o script de arma real (`data/scripts/weapons/scripts/poison_arrow.lua`)
  sobrescreve pra **21** e aplica uma condição de veneno de verdade (`CONDITION_POISON`,
  dano ao longo do tempo) — é item de efeito, não físico puro. Ancorada na `envenomed arrow`
  (mesma categoria de efeito): `12 × (21/27) × 1.10 ≈ 10gp`.
- **`simple arrow`** (id 21470, 20 ataque, só 40% de chance de acerto — item de
  tutorial/starter): existe no datapack, mas Pedro decidiu **não incluir** na loja normal.
- **Storm arrows** (Firestorm/Froststorm/Terrastorm/Thunderstorm, Shatterstorm): **não existem
  neste datapack do Canary/OTServBR-Global** (conteúdo oficial mais recente ainda não
  portado) — impossível adicionar, não é uma escolha de design.
- **`crystal arrow`** (id 3239): item de quest específica ("não serve pra bows normais, parece
  estar apodrecendo"), não é munição de combate normal — excluída da loja.

**Lição geral (vale para qualquer item de arma/munição futuro):** sempre checar
`data/scripts/weapons/scripts/` além do `items.xml` antes de fixar um preço por ataque — alguns
itens têm o `attack` real definido/sobrescrito no script Lua da arma, diferente do que está no
XML, e podem ter efeitos (condição, área) que o XML sozinho não mostra.

## Como aplicar da próxima vez

Ao adicionar uma munição nova: (1) achar o `attack` dela em `items.xml`, (2) achar o item já
precificado mais próximo por baixo na mesma família/categoria de efeito, (3) aplicar a regra de
três + 10% acima, (4) se o resultado destoar muito da munição imediatamente acima na escala
(ex.: ficar mais caro que ela), reavaliar manualmente — a fórmula assume uma progressão local
suave, não substitui o bom senso quando os vizinhos da escala já tiverem preços legados
inconsistentes entre si.
