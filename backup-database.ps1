# Faz um backup do banco 'canary' (a MariaDB standalone que o servidor realmente usa,
# ver memoria do projeto -- nao e o mysqld do XAMPP).
# Uso: duplo clique, ou agenda no Task Scheduler do Windows pra rodar sozinho todo dia.
# Mantem só os ultimos 14 backups (2 semanas), apaga os mais antigos automaticamente.

$ErrorActionPreference = "Stop"

$dumpExe = "C:\Program Files\MariaDB 11.4\bin\mariadb-dump.exe"
$backupDir = "C:\Users\Pedro\Desktop\tibia-server\backups"
$dbUser = "canary"
$dbPassword = "VVEPNLco8bU4oBwZNxu6"
$dbName = "canary"
$keepCount = 14

if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outFile = Join-Path $backupDir "canary_$timestamp.sql"

Write-Host "Fazendo backup do banco 'canary' para $outFile ..." -ForegroundColor Cyan
& $dumpExe -h 127.0.0.1 -P 3306 -u $dbUser "-p$dbPassword" --single-transaction --routines --triggers $dbName | Out-File -FilePath $outFile -Encoding utf8

if ((Get-Item $outFile).Length -eq 0) {
    Write-Host "ERRO: backup ficou vazio, algo deu errado." -ForegroundColor Red
    exit 1
}

Write-Host "Backup concluido ($((Get-Item $outFile).Length / 1MB) MB)." -ForegroundColor Green

# Limpa backups antigos, mantendo so os mais recentes
$old = Get-ChildItem -Path $backupDir -Filter "canary_*.sql" | Sort-Object LastWriteTime -Descending | Select-Object -Skip $keepCount
if ($old) {
    Write-Host "Removendo $($old.Count) backup(s) antigo(s)..." -ForegroundColor Yellow
    $old | Remove-Item -Force
}
