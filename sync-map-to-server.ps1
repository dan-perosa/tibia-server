# Sincroniza o mapa editado na RME para o servidor Canary e reinicia o servidor.
# Uso: rode este script (duplo clique ou no PowerShell) sempre que salvar o mapa no editor.
#
# Funciona tanto pra quem roda o servidor nativo (canary.exe local) quanto pra quem
# roda via Docker (docker/docker-compose.yml) — o script detecta automaticamente qual
# dos dois está disponível nesta máquina e usa a sequência certa. Não precisa editar
# nada aqui pra trocar de um modo pro outro; os dois ficam no mesmo arquivo, versionado,
# sem um sobrescrever a configuração do outro.

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
# meu-mapa/ location varies by checkout: on some machines (Daniel's) this script
# and meu-mapa/ are siblings, both directly at $repoRoot. On Pedro's machine,
# meu-mapa/ is the one the RME actually edits and lives ONE level up (this
# script is nested in a "canary/" subfolder of a separate outer repo) --
# $repoRoot\meu-mapa there is a stale, rarely-touched tracked copy from 21-25/08,
# NOT what gets edited. A 2026-08-25 fix handled Pedro's layout but got flipped
# back by a 2026-08-28 "fix" that assumed the sibling layout, which silently
# synced that stale copy to the live server (caught by Pedro same day: map
# "voltou pra uma versao antiga"). Fixed again, this time to pick whichever
# candidate's .otbm was actually modified more recently, so it self-adjusts to
# either layout instead of hardcoding one person's checkout.
$mapDirSibling = Join-Path $repoRoot "meu-mapa"
$mapDirOuter = Join-Path (Split-Path $repoRoot -Parent) "meu-mapa"
$mapName = "MAPA OFICIAL DE TRABALHO"
$siblingOtbm = Join-Path $mapDirSibling "$mapName.otbm"
$outerOtbm = Join-Path $mapDirOuter "$mapName.otbm"
$siblingTime = if (Test-Path $siblingOtbm) { (Get-Item $siblingOtbm).LastWriteTime } else { [DateTime]::MinValue }
$outerTime = if (Test-Path $outerOtbm) { (Get-Item $outerOtbm).LastWriteTime } else { [DateTime]::MinValue }
if ($outerTime -gt $siblingTime) {
    $mapDir = $mapDirOuter
} else {
    $mapDir = $mapDirSibling
}
Write-Host "meu-mapa detectado em: $mapDir (mais recente entre as duas localizacoes possiveis)" -ForegroundColor Cyan
$canaryExe = Join-Path $repoRoot "canary.exe"
$dockerComposeFile = Join-Path $repoRoot "docker\docker-compose.yml"
$dockerServiceName = "server" # nome do serviço em docker/docker-compose.yml

Write-Host "Corrigindo pisos incompativeis com o servidor..." -ForegroundColor Cyan
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if ($python) {
    & $python.Source (Join-Path $repoRoot "tools\otbm-tools\fix_ground_20888.py") "$mapDir\$mapName.otbm"
} else {
    Write-Host "Python nao encontrado no PATH - pulando correcao de piso (instale o Python se precisar dela)." -ForegroundColor Yellow
}

# ---- Detecta o modo: canary.exe local (nativo) ou container Docker rodando ----
$mode = $null
$dockerContainerId = $null

if (Test-Path $canaryExe) {
    $mode = "native"
} elseif (Test-Path $dockerComposeFile) {
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if ($docker) {
        Push-Location (Join-Path $repoRoot "docker")
        $dockerContainerId = (& docker compose ps -q $dockerServiceName 2>$null)
        Pop-Location
        if ($dockerContainerId) {
            $mode = "docker"
        }
    }
}

if (-not $mode) {
    Write-Host "Nao encontrei nem canary.exe local nem um container Docker do servico '$dockerServiceName' rodando." -ForegroundColor Red
    Write-Host "Baixe/rode o servidor primeiro (nativo ou 'docker compose up' na pasta docker/) antes de usar este script." -ForegroundColor Red
    Read-Host "Pressione Enter para fechar"
    exit 1
}

Write-Host "Modo detectado: $mode" -ForegroundColor Cyan

if ($mode -eq "native") {
    $worldDir = Join-Path $repoRoot "data-otservbr-global\world"
    $configPath = Join-Path $repoRoot "config.lua"

    Write-Host "Copiando arquivos do mapa para o servidor..." -ForegroundColor Cyan
    Copy-Item "$mapDir\$mapName.otbm" "$worldDir\$mapName.otbm" -Force
    Copy-Item "$mapDir\$mapName-house.xml" "$worldDir\$mapName-house.xml" -Force
    Copy-Item "$mapDir\$mapName-monster.xml" "$worldDir\$mapName-monster.xml" -Force
    Copy-Item "$mapDir\$mapName-npc.xml" "$worldDir\$mapName-npc.xml" -Force
    Copy-Item "$mapDir\$mapName-zones.xml" "$worldDir\$mapName-zones.xml" -Force

    $fixLogin = Join-Path $repoRoot "server-fixes\login.lua"
    if (Test-Path $fixLogin) {
        Write-Host "Reaplicando correcao do login.lua (evita crash em mapas customizados)..." -ForegroundColor Cyan
        Copy-Item $fixLogin (Join-Path $repoRoot "data-otservbr-global\scripts\creaturescripts\others\login.lua") -Force
    } else {
        Write-Host "server-fixes\login.lua nao encontrado nesta maquina - pulando (arquivo local, nao versionado no git)." -ForegroundColor Yellow
    }

    Write-Host "Apontando config.lua para o mapa correto..." -ForegroundColor Cyan
    $configContent = Get-Content $configPath -Raw
    $configContent = $configContent -replace 'mapName\s*=\s*"[^"]*"', "mapName = `"$mapName`""
    $configContent = $configContent -replace 'toggleMapCustom\s*=\s*true', 'toggleMapCustom = false'
    $configContent = $configContent -replace 'rateUseStages\s*=\s*false', 'rateUseStages = true'
    $configContent = $configContent -replace 'rateLoot\s*=\s*[\d.]+', 'rateLoot = 5'
    Set-Content -Path $configPath -Value $configContent -NoNewline

    Write-Host "Reiniciando o servidor..." -ForegroundColor Cyan
    Get-Process -Name "canary" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    # Saida redirecionada pra canary_live.log/canary_live_err.log (raiz do repo) --
    # sobrescrito a cada run -- pra dar pra investigar sem precisar ficar de olho na
    # janela do console. Adicionado 2026-08-28 durante o debug do chase mode/skill bar.
    $liveLog = Join-Path $repoRoot "canary_live.log"
    $liveLogErr = Join-Path $repoRoot "canary_live_err.log"
    Start-Process -FilePath $canaryExe -WorkingDirectory $repoRoot -RedirectStandardOutput $liveLog -RedirectStandardError $liveLogErr

    Write-Host "Aguardando o servidor subir..." -ForegroundColor Cyan
    # 8s nao e suficiente -- o boot completo (ate "server online" no log) leva uns
    # 26s medidos em 2026-08-28 (mais devagar ainda com logLevel=debug ligado, que e
    # bem mais verboso). Tentar conectar antes disso da "connection refused" porque
    # a porta do jogo ainda nao esta escutando.
    Start-Sleep -Seconds 30

    # O client oficial nao fala com o canary.exe diretamente pro login -- ele manda um
    # POST http pro login-server (login-server\login-server.exe), que fica escutando em
    # 8088 (ver client\conf\config.ini, loginWebService) e so depois redireciona pro
    # canary.exe (7172). Sem esse processo de pe, o client mostra "Connection refused"
    # mesmo com o canary.exe 100% saudavel -- confundiu a investigacao em 2026-08-28
    # porque o canary.exe sozinho parecia perfeito. Reiniciado junto porque ele guarda
    # a conexao com o canary.exe antigo na inicializacao e nao reconecta sozinho.
    $loginServerDir = Join-Path $repoRoot "login-server"
    $loginServerExe = Join-Path $loginServerDir "login-server.exe"
    if (Test-Path $loginServerExe) {
        Write-Host "Reiniciando o login-server..." -ForegroundColor Cyan
        Get-Process -Name "login-server" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 1
        $loginLiveLog = Join-Path $loginServerDir "login-server_live.log"
        $loginLiveLogErr = Join-Path $loginServerDir "login-server_live_err.log"
        Start-Process -FilePath $loginServerExe -WorkingDirectory $loginServerDir -RedirectStandardOutput $loginLiveLog -RedirectStandardError $loginLiveLogErr
        Start-Sleep -Seconds 3
    } else {
        Write-Host "login-server.exe nao encontrado em login-server\ -- pulando (login via client oficial vai falhar sem ele)." -ForegroundColor Yellow
    }
} else {
    # ---- Modo Docker: copia pra dentro do container e reinicia via docker compose ----
    $containerWorldDir = "/canary/data-otservbr-global/world"
    $containerConfigPath = "/canary/config.lua"

    Push-Location (Join-Path $repoRoot "docker")
    try {
        Write-Host "Copiando arquivos do mapa para o container..." -ForegroundColor Cyan
        & docker compose cp "$mapDir\$mapName.otbm" "${dockerServiceName}:${containerWorldDir}/$mapName.otbm"
        & docker compose cp "$mapDir\$mapName-house.xml" "${dockerServiceName}:${containerWorldDir}/$mapName-house.xml"
        & docker compose cp "$mapDir\$mapName-monster.xml" "${dockerServiceName}:${containerWorldDir}/$mapName-monster.xml"
        & docker compose cp "$mapDir\$mapName-npc.xml" "${dockerServiceName}:${containerWorldDir}/$mapName-npc.xml"
        & docker compose cp "$mapDir\$mapName-zones.xml" "${dockerServiceName}:${containerWorldDir}/$mapName-zones.xml"

        $fixLogin = Join-Path $repoRoot "server-fixes\login.lua"
        if (Test-Path $fixLogin) {
            Write-Host "Reaplicando correcao do login.lua (evita crash em mapas customizados)..." -ForegroundColor Cyan
            & docker compose cp $fixLogin "${dockerServiceName}:/canary/data-otservbr-global/scripts/creaturescripts/others/login.lua"
        } else {
            Write-Host "server-fixes\login.lua nao encontrado nesta maquina - pulando (arquivo local, nao versionado no git)." -ForegroundColor Yellow
        }

        Write-Host "Apontando config.lua (dentro do container) para o mapa correto..." -ForegroundColor Cyan
        & docker compose exec -T $dockerServiceName sh -c "sed -i 's/^mapName = \`".*\`"/mapName = \`"$mapName\`"/' $containerConfigPath"
        & docker compose exec -T $dockerServiceName sh -c "sed -i 's/^toggleMapCustom = true/toggleMapCustom = false/' $containerConfigPath"
        & docker compose exec -T $dockerServiceName sh -c "sed -i 's/^rateUseStages = false/rateUseStages = true/' $containerConfigPath"
        & docker compose exec -T $dockerServiceName sh -c "sed -i 's/^rateLoot = .*/rateLoot = 5/' $containerConfigPath"

        Write-Host "Reiniciando o container do servidor..." -ForegroundColor Cyan
        & docker compose restart $dockerServiceName

        Write-Host "Aguardando o servidor subir..." -ForegroundColor Cyan
        Start-Sleep -Seconds 8
    } finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "Pronto! Pode entrar no jogo agora." -ForegroundColor Green
Read-Host "Pressione Enter para fechar"
