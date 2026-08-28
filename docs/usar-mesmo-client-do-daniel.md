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

Esse binário também não é versionado, e diferente do client não tem uma
fonte/commit fixado documentado em lugar nenhum — o Daniel vai te mandar o
arquivo diretamente (Discord/Drive/etc), pasta `login-server/` inteira:

- `login-server.exe`
- `.env` — **não copiar o do Daniel direto**, os dois precisam ter as
  mesmas credenciais de MySQL (`MYSQL_USER`/`MYSQL_PASS`) que vocês já
  combinaram deixar iguais (`root`/`123`) — se já estiver assim, pode
  copiar sem problema.

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
