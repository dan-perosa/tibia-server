# Pedro: como usar o mesmo client que o Daniel

O Daniel joga com o client oficial da CipSoft (fechado, sem código-fonte —
não é o OTClient). O Pedro hoje usa o OTClient Redemption
(`tools/otclient/`), que é outro client, então bugs de um lado podem não
bater com o outro. Passos pra ficar igual.

## 1. Baixar o mesmo client oficial

O client não é versionado no Git (é 600MB+ de assets/binário), mas a versão
exata usada está fixada em `client/TIBIA_CLIENT_SOURCE.txt`:

```
client_repository=dudantas/tibia-client
client_tag=15.25.0a00a0
client_commit_sha=1b6faec234d5b549d5302d82c16c510184ee937d
```

Na raiz do seu repositório (`canary/` ou onde estiver o `config.lua`), rode:

```powershell
git clone https://github.com/dudantas/tibia-client.git client
cd client
git checkout 1b6faec234d5b549d5302d82c16c510184ee937d
cd ..
```

Isso cria a pasta `client/` com o `client.exe` (o mesmo executável do
Daniel, byte a byte).

## 2. Pegar o `login-server.exe`

Esse binário também não é versionado no repo do Canary, mas é um projeto
separado open-source com release oficial no GitHub —
[`opentibiabr/login-server`](https://github.com/opentibiabr/login-server/releases).
O arquivo do Daniel (`login-server.exe`, 22/nov/2021) bate exatamente com a
release **v1.1.3** (23/nov/2021), então é só baixar essa:

```powershell
# Baixa e extrai login-server-v1.1.3-windows-amd64.zip pra uma pasta login-server/
```

Ou direto pelo browser:
`https://github.com/opentibiabr/login-server/releases/tag/v1.1.3` →
`login-server-v1.1.3-windows-amd64.zip`.

Depois de extrair, criar um `login-server/.env` com suas próprias
credenciais de MySQL locais (mesmo formato do exemplo abaixo — já devem
estar iguais às do Daniel, `root`/`123`, se vocês já sincronizaram isso):

```
ENV=dev
LOGIN_IP=0.0.0.0
LOGIN_HTTP_PORT=8088
LOGIN_GRPC_PORT=9090
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_DBNAME=canary
MYSQL_USER=root
MYSQL_PASS=123
SERVER_NAME=OTServBR-Global
SERVER_IP=127.0.0.1
SERVER_PORT=7172
SERVER_LOCATION=BRA
RATE_LIMITER_RATE=2
RATE_LIMITER_BURST=5
```

## 3. Configurar o `client/conf/config.ini` do seu client novo

Ele já vem assim por padrão (é sempre `127.0.0.1`, aponta pra máquina local
de cada um, não precisa mudar nada em relação ao do Daniel):

```ini
loginWebService=http://127.0.0.1:8088/login
clientWebService=http://127.0.0.1:8088/login
```

Se por algum motivo vier diferente, ajuste pra isso.

## 4. Rodar

Mesma ordem que o Daniel usa:

1. `canary.exe` (espera uns 26s pra terminar de subir, ver o log até
   aparecer "server online").
2. `login-server/login-server.exe`.
3. `client/client.exe` — logar normalmente.

## 5. O que fazer com o OTClient antigo

Não precisa apagar `tools/otclient/` — ele continua no repositório (é onde
o Pedro já achou/corrigiu parte do bug da barra de skill, ver
`docs/CHANGELOG.md` 2026-08-24/25). Só não é mais o client usado pra
jogar/testar no dia a dia — isso passa a ser sempre o client oficial, igual
o Daniel.
