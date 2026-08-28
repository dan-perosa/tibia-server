# Servidor privado de Tibia (Canary) — resumo do projeto

## O que é

Servidor privado de Tibia (motor open-source **Canary**, baseado no datapack OTServBR-Global),
feito pra jogar com amigos — não é pra lucrar nem abrir ao público. Comecei em 03/08/2026.
Não sei programar; um amigo (Dan) cuida da parte de código em C++/infraestrutura, e eu venho
usando o Claude Code pra fazer tudo o mais (mapa, NPCs, quests, balanceamento, documentação).
O mapa inteiro é feito à mão por mim no Remere's Map Editor (RME) — é o primeiro mapa que eu
já construí na vida.

## Estrutura do mundo (conceito, estilo "YourOTS clássico")

- Cidade principal no centro, com 4 saídas: Norte, Sul, Leste, Oeste.
- Cada direção é uma "hunt" temática com bioma e monstro principal próprios:
  - **Norte** — geleira/montanha nevada, criaturas de gelo
  - **Sul** — deserto escaldante, escorpiões/elementais de fogo
  - **Leste** — floresta/pântano, bestas/aranhas/espíritos da natureza
  - **Oeste** — terras amaldiçoadas, mortos-vivos/fantasmas
- Dentro de cada hunt, a dificuldade cresce conforme se afasta da cidade (a ideia original era
  ter mais de 5 estágios de dificuldade por hunt).
- Cada hunt seria liberada por teletransporte só depois de completar uma quest difícil
  específica daquela hunt (gate de progressão) — conceito ainda não totalmente implementado
  em todas as hunts.
- Escala pretendida: mundo médio, vários biomas — nem gigante tipo servidor público, nem
  minúsculo.

## Estado atual do mapa

- Já existem: cidade principal, várias hunts construídas (incluindo uma de scarab a leste,
  uma com Giant Spider/Putrid Mummy), uma sala de desafio disfarçada de "Demon" (na verdade um
  Demon Goblin travestido, pra dar susto sem ser fácil demais), baús de recompensa iniciais,
  NPC de promoção de vocação, sistema de quests com trava de duplicação de item.
- Estou construindo uma ilha com a Exaltation Forge.

### Problema em aberto — escala do mapa (decisão mais importante pendente)

Por ser meu primeiro mapa, a proporção ficou grande demais, principalmente a cidade principal:
o personagem fica visualmente pequeno em relação ao espaço, criando distâncias longas e áreas
muito vazias (sensação de "editor de mapa visto de cima", não de cidade habitada). Duas
direções possíveis, ainda não decidi qual:
- **Reduzir a escala** da cidade (e possivelmente de outras áreas), aproximando prédios/ruas.
- **Preencher os espaços vazios** com conteúdo útil/decorativo (NPCs, construções, detalhes)
  pra dar vida sem precisar refazer o layout.

Provavelmente vale decidir isso antes de investir tempo nos itens abaixo, já que pode mudar a
escala/densidade de tudo que for construído depois.

### Outras 3 pendências de mapa registradas

1. **Hunt de scarab** (leste da cidade) — uma das primeiras áreas que fiz, está "seca"/sem
   imersão. Precisa de mais decoração/ambientação, repensar o formato, e talvez trocar os
   monstros (do jeito que está não ficou uma hunt divertida).
2. **Nova cidade** a leste da hunt de Giant Spider / Putrid Mummy — ainda não construída.
3. **Transição visual grama→areia** ruim, pouco antes da Exaltation Forge (na ilha que estou
   construindo) — precisa suavizar.

## Sistemas de gameplay já definidos

- **Fórmulas de dano/cura**: reformuladas (divisor de level `/5`→`/4`, expoente de
  skill/magic level `^1.1`) — trabalho do Dan, já integrado no lado Lua; a parte C++
  (armas melee/distância) só entra em vigor depois de recompilar o servidor.
- **Taxa de experiência**: desenhei uma tabela completa de multiplicadores de XP por faixa de
  level, calibrada com dados reais de XP/hora do Tibia global (não chute) — servidor é 100%
  manual, sem bots permitidos, e a meta declarada é permitir chegar a level 2000-3000 sem ficar
  rápido demais no início nem impossível no fim.
- **Economia de munição (arrows/bolts)**: acabei de fechar um sistema de preços pras lojas de
  NPC baseado numa "regra de três" pelo ataque de cada munição em relação à munição vizinha na
  escala de dano, com um adicional de custo a cada degrau pra munição mais forte nunca dominar
  estritamente a mais fraca (a mais barata continua sendo uma opção econômica viável). Todas as
  bolts foram triplicadas de preço como um "gold sink" geral.
- **Segurança de recompensas**: todo baú/recompensa de quest checa espaço/peso do jogador antes
  de entregar itens, pra evitar duplicação por inventário cheio.

## Ideia de lore registrada, ainda não implementada

Quero colocar uma **chave** no caminho da Quest dos Orcs, ao lado de uma **placa** com um texto
tipo "essa chave pode vir a ser útil algum dia" — foreshadowing pra abrir, futuramente, a porta
de uma área relevante que ainda vou construir. A lore em volta disso (o que a porta leva, por
que a chave importa) ainda não foi pensada.

## O que eu gostaria de trocar ideia agora

Coisas que fazem sentido eu discutir num brainstorm sem precisar de código/acesso ao servidor:
- Decidir a questão da escala do mapa (reduzir vs. preencher).
- Ideias de tema/monstros/ambientação pra reformular a hunt de scarab.
- Conceito pra cidade nova a leste da hunt de Giant Spider/Putrid Mummy (nome, tema, NPCs,
  o que ela oferece que as outras não oferecem).
- Desenvolver a lore da chave da Quest dos Orcs — o que a porta esconde, por que vale a pena.
- Ideias gerais de progressão/gameplay pros próximos passos do servidor.

Não precisa (nem dá, na versão web) mexer em arquivo nenhum — é só pra pensar junto e me dar
sugestões que eu depois levo pro Claude Code implementar.
