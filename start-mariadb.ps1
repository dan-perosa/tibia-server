# Inicia o servico MariaDB. Precisa rodar como Administrador (o atalho ja pede isso sozinho).
$service = Get-Service MariaDB -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Host "Servico MariaDB nao encontrado." -ForegroundColor Red
} elseif ($service.Status -eq 'Running') {
    Write-Host "MariaDB ja estava rodando." -ForegroundColor Green
} else {
    Start-Service MariaDB
    Start-Sleep -Seconds 2
    $service.Refresh()
    if ($service.Status -eq 'Running') {
        Write-Host "MariaDB iniciado com sucesso." -ForegroundColor Green
    } else {
        Write-Host "Algo deu errado, status atual: $($service.Status)" -ForegroundColor Red
    }
}
Start-Sleep -Seconds 3
