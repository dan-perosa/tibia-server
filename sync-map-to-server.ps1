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
$mapDir = Join-Path $repoRoot "meu-mapa"
$mapName = "MAPA OFICIAL DE TRABALHO"
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
    Set-Content -Path $configPath -Value $configContent -NoNewline

    Write-Host "Reiniciando o servidor..." -ForegroundColor Cyan
    Get-Process -Name "canary" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    Start-Process -FilePath $canaryExe -WorkingDirectory $repoRoot

    Write-Host "Aguardando o servidor subir..." -ForegroundColor Cyan
    Start-Sleep -Seconds 8
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
