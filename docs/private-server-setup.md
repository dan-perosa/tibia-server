# Servidor privado do Pedro — guia de instalação

Este fork do Canary é usado para rodar um servidor privado (só para amigos, sem
fins lucrativos), com um mapa próprio construído do zero. Este documento
explica como instalar o projeto do zero, tanto com Docker (recomendado) quanto
sem Docker.

## O que é customizado neste fork

- `meu-mapa/` — o mapa do servidor (`MAPA OFICIAL DE TRABALHO.otbm` + arquivos
  companheiros `-house.xml`, `-monster.xml`, `-npc.xml`, `-zones.xml`).
- `tools/otbm-tools/` — ferramentas em Python para ler/escrever o mapa `.otbm`
  sem precisar abrir o editor. Ver seção [Editando o mapa](#editando-o-mapa).
- `data-otservbr-global/npc/rashid.lua` e `rashid_custom.lua` — o NPC Rashid
  não exige mais completar a quest "The Travelling Trader" para negociar, e
  tem uma lista maior de itens que ele compra.
- `data-otservbr-global/scripts/globalevents/spawn/rashid.lua.disabled` —
  desativado (renomeado, não apagado). Esse script cria um segundo Rashid
  "oficial" todo dia em uma cidade oficial (Carlin/Svargrond/Liberty
  Bay/etc.), o que rouba o nome do NPC do nosso mapa e o nosso Rashid nunca
  aparece de verdade. Deixe desativado.
- `data-otservbr-global/scripts/creaturescripts/others/login.lua` — removida
  a lógica de "conta free expirada → teleporta pro Thais", que crashava
  sempre em mapas customizados (a cidade "Thais" do mundo oficial não existe
  no nosso mapa).
- `sync-map-to-server.ps1` — script que sincroniza o mapa editado no RME para
  o servidor rodando em Docker, aplica as correções acima automaticamente, e
  reinicia o servidor. **Os caminhos dentro desse script são fixos para a
  máquina do Pedro** (`C:\Users\Pedro\...`) — ajuste antes de usar em outra
  máquina.

---

## Instalação com Docker (recomendado)

### Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) com WSL2
  habilitado (Windows) ou Docker Engine (Linux/Mac).

### Passos

1. Clone o repositório e entre na pasta `docker`:

   ```powershell
   git clone https://github.com/Miracidio/tibia-server.git
   cd tibia-server/docker
   ```

2. Copie o arquivo de variáveis de ambiente e **troque as senhas padrão**
   (nunca deixe as senhas de exemplo em um servidor que outras pessoas vão
   acessar):

   ```powershell
   cp .env.dist .env
   ```

3. Suba a stack (MariaDB + Canary + MyAAC + login-server):

   ```powershell
   docker compose up -d --build
   ```

4. Copie o mapa customizado deste repositório para dentro do container e
   aponte o servidor para ele:

   ```powershell
   docker cp "..\meu-mapa\MAPA OFICIAL DE TRABALHO.otbm" otbr-server-1:/canary/data-otservbr-global/world/
   docker cp "..\meu-mapa\MAPA OFICIAL DE TRABALHO-house.xml" otbr-server-1:/canary/data-otservbr-global/world/
   docker cp "..\meu-mapa\MAPA OFICIAL DE TRABALHO-monster.xml" otbr-server-1:/canary/data-otservbr-global/world/
   docker cp "..\meu-mapa\MAPA OFICIAL DE TRABALHO-npc.xml" otbr-server-1:/canary/data-otservbr-global/world/
   docker cp "..\meu-mapa\MAPA OFICIAL DE TRABALHO-zones.xml" otbr-server-1:/canary/data-otservbr-global/world/
   ```

5. Dentro do container, edite `/canary/config.lua`:

   ```
   mapName = "MAPA OFICIAL DE TRABALHO"
   toggleMapCustom = false
   ```

   **`toggleMapCustom = false` é obrigatório.** Quando `true` (padrão do
   Canary), o servidor carrega por cima do seu mapa todo `.otbm` que estiver
   em `data-otservbr-global/world/custom/` — incluindo o mapa oficial
   "Oramond" que já vem com o datapack, cujas coordenadas colidem com a faixa
   que este projeto usa (a partir de x/y 935). Deixar isso ligado faz o chão
   virar água/terreno oficial silenciosamente, sem nenhum erro no log. Foi um
   bug que levou uma sessão inteira pra ser encontrado — ver
   [Problemas conhecidos](#problemas-conhecidos).

6. Reinicie o container:

   ```powershell
   docker restart otbr-server-1
   ```

7. Endereços padrão:
   - Site/admin (MyAAC): `http://localhost:8080`
   - Login do client: `http://localhost:8088/login`
   - Porta do jogo: `7172`

Depois da primeira vez, use o `sync-map-to-server.ps1` (ajustando os caminhos
pra sua máquina) para reenviar o mapa após editar no RME — ele já aplica os
passos 4-6 automaticamente, incluindo a correção de piso descrita abaixo.

---

## Instalação sem Docker

Rodar sem Docker significa compilar o Canary localmente e instalar o MariaDB
na própria máquina. É mais trabalhoso, mas útil se você quiser depurar o
código C++/Lua diretamente ou não puder usar Docker.

### 1. Compilar o Canary

Siga o guia oficial em
[`docs/building/windows-(cmake).md`](building/windows-(cmake).md) (Windows) ou
o guia equivalente para Linux em `docs/building/`. Resumo do caminho Windows:

1. Instale o [Git](https://git-scm.com/download/win) e o **Visual Studio 2026
   Community** com o workload "Desktop development with C++" (marcando MSVC
   Build Tools, C++ ATL, C++ CMake tools for Windows, Windows 11 SDK). Não
   marque a opção "vcpkg package manager" do instalador do Visual Studio.
2. Configure o vcpkg:
   ```powershell
   git clone https://github.com/microsoft/vcpkg
   cd vcpkg
   .\bootstrap-vcpkg.bat
   .\vcpkg integrate install
   ```
   e defina a variável de ambiente (PowerShell como Administrador):
   ```powershell
   [System.Environment]::SetEnvironmentVariable('VCPKG_ROOT','C:\vcpkg', [System.EnvironmentVariableTarget]::Machine)
   ```
3. Clone este repositório e abra a pasta no Visual Studio ("Open a local
   folder"). Ele vai gerar o cache do CMake e baixar as dependências
   sozinho — pode demorar alguns minutos na primeira vez.
4. Menu **Build → Build All**.

O binário compilado (`canary.exe`) fica em `build/bin/` (o caminho exato
depende do preset usado).

### 2. Instalar e configurar o MariaDB

1. Baixe e instale o [MariaDB Server](https://mariadb.org/download/) (versão
   10.6 ou mais recente).
2. Crie o banco e o usuário (via `mysql`/`mariadb` CLI ou uma ferramenta como
   o DBeaver):
   ```sql
   CREATE DATABASE canary CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   CREATE USER 'canary'@'localhost' IDENTIFIED BY 'escolha-uma-senha-forte';
   GRANT ALL PRIVILEGES ON canary.* TO 'canary'@'localhost';
   FLUSH PRIVILEGES;
   ```
3. Importe o schema:
   ```powershell
   mysql -u canary -p canary < schema.sql
   ```

### 3. Configurar o `config.lua`

1. Copie o modelo:
   ```powershell
   cp config.lua.dist config.lua
   ```
2. Preencha pelo menos:
   ```
   mysqlHost = "127.0.0.1"
   mysqlUser = "canary"
   mysqlPass = "a-senha-que-voce-criou"
   mysqlPort = 3306
   mysqlDatabase = "canary"
   ip = "127.0.0.1"          -- ou o IP da máquina, se outros forem conectar
   dataPackDirectory = "data-otservbr-global"
   mapName = "MAPA OFICIAL DE TRABALHO"
   toggleMapCustom = false   -- ver explicação na seção de Docker acima
   ```
   (`config.lua` está no `.gitignore` deste repositório de propósito, porque
   guarda credenciais reais — nunca commite esse arquivo preenchido.)

### 4. Colocar o mapa customizado no lugar

Copie os 5 arquivos de `meu-mapa/` deste repositório para
`data-otservbr-global/world/` (na raiz do repositório, ao lado da pasta
`data/`).

### 5. Rodar o servidor

Execute o binário compilado a partir da raiz do repositório (ele espera
encontrar `config.lua`, `data/` e `data-otservbr-global/` no diretório
atual):

```powershell
.\build\bin\canary.exe
```

O site (MyAAC) e o serviço de login (`login-server`) são opcionais — sem eles
você ainda consegue jogar apontando o client direto para o IP/porta do jogo
(`7172`), só não vai ter painel web nem tela de login por navegador.

---

## Editando o mapa

O mapa é editado manualmente no
[Remere's Map Editor / Canary Map Editor](https://github.com/opentibiabr/remeres-map-editor)
(RME). Para ajustes pontuais (mover um item, corrigir uma posição, gerar um
pedaço de terreno) sem precisar abrir o editor, `tools/otbm-tools/otbm.py` é
um leitor/escritor puro-Python do formato binário `.otbm` (suporta OTBM
versão 5, que é o que o Canary Map Editor 4.0 salva). Ver os scripts de
exemplo na mesma pasta.

**Importante ao criar um item de "chão" via script:** nem todo item que o RME
deixa pintar como piso é reconhecido como piso de verdade pelo Canary. O
servidor só marca um tile como `tile.ground` se o item tiver o grupo
`ITEM_GROUP_GROUND` nos dados de aparência (ver
`src/items/items.cpp` e `src/io/iomap.cpp`) — isso **não** é a mesma coisa que
aparecer em `data/materials/brushs/grounds.xml` do RME. Um jeito prático de
checar: no `items.xml`, itens com `primarytype="artificial tiles"` costumam
ser pisos de verdade; itens com `primarytype="tools"` (como o item 20888,
"marble floor") normalmente não são, mesmo tendo "floor" no nome. O script
`tools/otbm-tools/fix_ground_20888.py` corrige esse caso específico
automaticamente antes de cada deploy.

---

## Problemas conhecidos

- **Chão virando água sem motivo aparente:** ver `toggleMapCustom` acima —
  quase sempre é o mapa oficial extra (`world/custom/*.otbm`) sobrepondo as
  mesmas coordenadas do seu mapa, não um bug no arquivo em si.
- **NPC "sumindo" ou se comportando com uma versão antiga do script:** se
  existir mais de um arquivo `.lua` em `data-otservbr-global/npc/` registrando
  o mesmo nome de NPC (`npcConfig.name`), o que carregar por último
  sobrescreve o registro do NPC — mesmo que ambos existam por engano (ex.: uma
  cópia de teste esquecida na pasta). Confirme que só existe um `.lua` ativo
  por nome de NPC.
- **Crash ao logar em conta free expirada:** era causado pelo
  `login.lua` original tentando teleportar pra `Town("Thais")`, que não existe
  em mapas customizados. Já corrigido neste fork (ver acima).
