# Sincroniza o mapa editado no RME para o servidor Canary rodando no Docker.
# Uso: dê duplo clique (ou rode no PowerShell) sempre que salvar o mapa no editor.

$ErrorActionPreference = "Stop"
$docker = "C:\Users\Pedro\AppData\Local\Programs\DockerDesktop\resources\bin\docker.exe"
$mapDir = "C:\Users\Pedro\Desktop\tibia-server\meu-mapa"
$mapName = "MAPA OFICIAL DE TRABALHO"
$container = "otbr-server-1"
$worldPath = "/canary/data-otservbr-global/world"

Write-Host "Corrigindo pisos incompativeis com o servidor..." -ForegroundColor Cyan
$python = "C:\Users\Pedro\AppData\Local\Programs\Python\Python312\python.exe"
& $python "C:\Users\Pedro\Desktop\tibia-server\tools\otbm-tools\fix_ground_20888.py"

Write-Host "Copiando arquivos do mapa para o servidor..." -ForegroundColor Cyan
& $docker cp "$mapDir\$mapName.otbm" "${container}:${worldPath}/$mapName.otbm"
& $docker cp "$mapDir\$mapName-house.xml" "${container}:${worldPath}/$mapName-house.xml"
& $docker cp "$mapDir\$mapName-monster.xml" "${container}:${worldPath}/$mapName-monster.xml"
& $docker cp "$mapDir\$mapName-npc.xml" "${container}:${worldPath}/$mapName-npc.xml"
& $docker cp "$mapDir\$mapName-zones.xml" "${container}:${worldPath}/$mapName-zones.xml"

Write-Host "Reaplicando correcao do login.lua (evita crash em mapas customizados)..." -ForegroundColor Cyan
$fixDir = "C:\Users\Pedro\Desktop\tibia-server\server-fixes"
& $docker cp "$fixDir\login.lua" "${container}:/canary/data-otservbr-global/scripts/creaturescripts/others/login.lua"

Write-Host "Apontando config.lua para o mapa correto..." -ForegroundColor Cyan
& $docker exec $container sh -c "sed -i 's/^mapName = \`".*\`"/mapName = \`"$mapName\`"/' /canary/config.lua"

Write-Host "Desligando o mapa extra oficial (evita sobrepor seu mapa com agua/terreno oficial)..." -ForegroundColor Cyan
& $docker exec $container sh -c "sed -i 's/^toggleMapCustom = true/toggleMapCustom = false/' /canary/config.lua"

Write-Host "Reiniciando o servidor..." -ForegroundColor Cyan
& $docker restart $container | Out-Null

Write-Host "Aguardando o servidor subir..." -ForegroundColor Cyan
Start-Sleep -Seconds 8

Write-Host ""
Write-Host "Pronto! Pode entrar no jogo agora." -ForegroundColor Green
Read-Host "Pressione Enter para fechar"
