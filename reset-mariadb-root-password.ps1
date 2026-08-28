# Reseta a senha do usuario root do MariaDB standalone (nao mexe no usuario
# 'canary', que continua com a senha de sempre).
# Rode este script como Administrador (clique direito -> Executar com PowerShell,
# numa janela ja aberta "como administrador").

$mariadbBin = "C:\Program Files\MariaDB 11.4\bin"
$dataDir = "C:\Program Files\MariaDB 11.4\data"
$novaSenha = "123"
$tempPort = 33061
$proc = $null

Write-Host "Parando o servico MariaDB (se estiver rodando)..." -ForegroundColor Cyan
Get-Service MariaDB -ErrorAction SilentlyContinue | Where-Object Status -eq 'Running' | Stop-Service -Force
Start-Sleep -Seconds 2

try {
    Write-Host "Iniciando MariaDB temporariamente em modo de recuperacao (porta alternativa, so localhost, sem senha)..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath "$mariadbBin\mysqld.exe" `
        -ArgumentList @("--datadir=$dataDir", "--skip-grant-tables", "--port=$tempPort", "--bind-address=127.0.0.1", "--skip-name-resolve") `
        -PassThru -WindowStyle Hidden

    Write-Host "Aguardando o MariaDB temporario ficar pronto..." -ForegroundColor Cyan
    $ready = $false
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 1
        if ($proc.HasExited) {
            Write-Host "O mysqld temporario encerrou sozinho (codigo $($proc.ExitCode))." -ForegroundColor Red
            break
        }
        $test = Test-NetConnection -ComputerName 127.0.0.1 -Port $tempPort -WarningAction SilentlyContinue
        if ($test.TcpTestSucceeded) {
            $ready = $true
            break
        }
    }

    if (-not $ready) {
        Write-Host "Nao consegui confirmar que o MariaDB temporario subiu. Veja o log de erro (Desktop.err) na pasta data." -ForegroundColor Red
    } else {
        Write-Host "Trocando a senha do root para '$novaSenha'..." -ForegroundColor Cyan
        & "$mariadbBin\mysql.exe" -h 127.0.0.1 -P $tempPort -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY '$novaSenha';"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Senha trocada com sucesso." -ForegroundColor Green
        } else {
            Write-Host "O comando de troca de senha falhou (codigo $LASTEXITCODE) -- veja a mensagem acima." -ForegroundColor Red
        }
        & "$mariadbBin\mysql.exe" -h 127.0.0.1 -P $tempPort -u root -e "ALTER USER 'root'@'127.0.0.1' IDENTIFIED BY '$novaSenha';" 2>$null
        & "$mariadbBin\mysql.exe" -h 127.0.0.1 -P $tempPort -u root -e "ALTER USER 'root'@'%' IDENTIFIED BY '$novaSenha';" 2>$null
    }
} finally {
    if ($proc -and -not $proc.HasExited) {
        Write-Host "Encerrando o MariaDB temporario (PID $($proc.Id))..." -ForegroundColor Cyan
        Stop-Process -Id $proc.Id -Force
        Start-Sleep -Seconds 3
    }

    Write-Host "Religando o servico MariaDB normal..." -ForegroundColor Cyan
    Start-Service MariaDB
    Start-Sleep -Seconds 2
    Get-Service MariaDB | Select-Object Name, Status
}

Write-Host ""
Write-Host "Fim do script." -ForegroundColor Green
Read-Host "Pressione Enter para fechar"
