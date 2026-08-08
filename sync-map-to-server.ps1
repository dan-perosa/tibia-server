# Sincroniza o mapa editado na RME para o servidor Canary local e reinicia o canary.exe.
# Uso: rode este script (duplo clique ou no PowerShell) sempre que salvar o mapa no editor.
# Funciona em qualquer maquina/usuario: todos os caminhos sao relativos a pasta do repositorio
# (a mesma pasta onde este script esta salvo), nao ha nada fixo pro seu usuario ou pro meu.

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$mapDir = Join-Path $repoRoot "meu-mapa"
$mapName = "MAPA OFICIAL DE TRABALHO"
$worldDir = Join-Path $repoRoot "data-otservbr-global\world"
$configPath = Join-Path $repoRoot "config.lua"
$canaryExe = Join-Path $repoRoot "canary.exe"

if (-not (Test-Path $canaryExe)) {
    Write-Host "canary.exe nao encontrado em $repoRoot - baixe o build antes de rodar este script." -ForegroundColor Red
    Read-Host "Pressione Enter para fechar"
    exit 1
}

Write-Host "Corrigindo pisos incompativeis com o servidor..." -ForegroundColor Cyan
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if ($python) {
    & $python.Source (Join-Path $repoRoot "tools\otbm-tools\fix_ground_20888.py") "$mapDir\$mapName.otbm"
} else {
    Write-Host "Python nao encontrado no PATH - pulando correcao de piso (instale o Python se precisar dela)." -ForegroundColor Yellow
}

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

Write-Host ""
Write-Host "Pronto! Pode entrar no jogo agora." -ForegroundColor Green
Read-Host "Pressione Enter para fechar"
