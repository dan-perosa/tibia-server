# Migrando o Pedro de Docker para instalação nativa

Este guia é para quando o Pedro (que hoje roda o servidor via Docker) troca
para rodar nativamente, do mesmo jeito que o Dan já roda. Ele existe separado
de [`docs/private-server-setup.md`](private-server-setup.md) porque cobre um
caso que aquele documento não cobre: **migrar uma instalação Docker que já
tem contas e personagens criados**, sem perder esses dados.

Se é a primeira vez que o Pedro instala o projeto (nunca rodou nada, banco
vazio), pode pular direto para a seção ["Instalação sem
Docker"](private-server-setup.md#instalação-sem-docker) do outro documento —
não precisa migrar nada.

Se ele já jogou/testou via Docker e quer manter as contas, siga a ordem
abaixo. **Não desligue nem apague a stack Docker antes de confirmar que o
backup do banco foi feito com sucesso.**

## 1. Descobrir as credenciais do banco Docker atual

O nome do banco/usuário/senha usados pelo Docker ficam no arquivo `.env`
dentro da pasta `docker/` (criado a partir de `docker/.env.dist` na
instalação original). Abra `docker/.env` e anote:

```
CANARY_DB_NAME=...       # padrão: canary
CANARY_DB_USER=...       # padrão: canary
CANARY_DB_PASSWORD=...   # padrão: canary
CANARY_DB_ROOT_PASSWORD=... # padrão: root
```

Se o arquivo `.env` não existir mais ou os valores não foram trocados, os
padrões acima (definidos em `docker/docker-compose.yml`) são os que valem.

## 2. Exportar (dump) o banco de dentro do container

Com a stack Docker ainda rodando (`docker compose ps` deve mostrar o serviço
`db` como `healthy`), rode a partir da pasta `docker/`:

```powershell
docker compose exec db mariadb-dump -u root -p"SENHA_ROOT_DO_ENV" canary > "..\canary_backup.sql"
```

Troque `SENHA_ROOT_DO_ENV` pelo valor de `CANARY_DB_ROOT_PASSWORD` do passo 1
e `canary` (o último argumento, nome do banco) pelo valor de
`CANARY_DB_NAME` se ele foi customizado.

Confirme que `canary_backup.sql` foi criado na raiz do repositório e não está
vazio (deve ter pelo menos as tabelas `accounts`, `players`, `player_storage`,
etc. — abra o arquivo e procure por `CREATE TABLE`). **Só prossiga depois de
confirmar isso.**

## 3. Instalar o Canary nativamente

Siga [`docs/private-server-setup.md` → "Instalação sem
Docker"](private-server-setup.md#instalação-sem-docker) para:

1. Compilar o `canary.exe` (Visual Studio 2026 + vcpkg).
2. Instalar o MariaDB Server localmente e criar o banco/usuário
   (`CREATE DATABASE`, `CREATE USER`, `GRANT`) — pode usar o mesmo
   usuário/senha do Docker ou um novo, não precisa ser igual.
3. Importar o schema vazio (`schema.sql`) **só se for começar um banco do
   zero**. Como neste caso já existem dados, pule o `schema.sql` e vá direto
   para o passo 4 abaixo — o dump já traz o schema completo junto com os
   dados.

## 4. Importar o backup no MariaDB nativo

Com o banco e usuário já criados no MariaDB local (passo 3.2):

```powershell
mysql -u canary -p canary < canary_backup.sql
```

Troque `canary` (usuário) e `canary` (nome do banco, segundo argumento) pelos
valores que você criou no MariaDB nativo. Vai pedir a senha do usuário nativo
(não a do Docker).

## 5. Configurar `config.lua` e copiar o mapa

Siga o resto de ["Instalação sem
Docker"](private-server-setup.md#instalação-sem-docker): preencher
`config.lua` apontando para o MariaDB nativo (`mysqlHost`, `mysqlUser`,
`mysqlPass`, `mysqlDatabase`) e copiar os 5 arquivos de `meu-mapa/` para
`data-otservbr-global/world/`.

## 6. Parar a stack Docker antes de rodar o nativo

Os dois modos usam as mesmas portas (7171-7175, 7173). Rodar os dois ao mesmo
tempo faz o `canary.exe` nativo falhar ao subir (porta ocupada) ou o cliente
conectar no servidor errado. Antes de testar o nativo:

```powershell
cd docker
docker compose down
```

Isso **não apaga** os dados — o volume `db-volume` continua existindo até
alguém rodar `docker compose down -v` ou apagar o volume manualmente. Deixe
esse volume como está por enquanto, é o backup de segurança caso algo dê
errado na migração.

## 7. Rodar e validar

Rode `.\canary.exe` (ou `.\build\bin\canary.exe`, dependendo de onde ficou o
binário compilado) a partir da raiz do repositório e confirme no log que ele
conectou no MySQL sem erro. Entre no jogo com uma conta que já existia antes
da migração e confirme que o personagem, inventário e posição no mapa estão
como esperado.

`sync-map-to-server.ps1` já detecta sozinho que agora existe um `canary.exe`
na raiz e passa a usar o modo nativo automaticamente — nenhuma edição no
script é necessária.

## 8. Depois de confirmar que está tudo certo

Só depois de jogar um pouco no modo nativo e confirmar que os dados estão
corretos, é seguro remover a stack Docker de vez, se quiser liberar espaço:

```powershell
cd docker
docker compose down -v
```

O `-v` aqui **apaga o volume do banco** — só rode isso quando tiver certeza
de que não vai precisar mais dele. Guarde o `canary_backup.sql` por mais uns
dias mesmo depois disso, por segurança.
