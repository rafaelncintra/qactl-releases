# qactl installer
# Uso: irm https://raw.githubusercontent.com/rafaelncintra/qactl-releases/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'

$repo      = "rafaelncintra/qactl-releases"
$installDir = "$env:APPDATA\qactl"

Write-Host ""
Write-Host "  qactl" -ForegroundColor Cyan -NoNewline
Write-Host " — instalador"
Write-Host "  ─────────────────────────────────────────"
Write-Host ""

# 1. Versão mais recente
Write-Host "  Verificando versao disponivel..." -NoNewline
try {
    $release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
    $version = $release.tag_name
    Write-Host " $version" -ForegroundColor Green
} catch {
    Write-Host " FALHOU" -ForegroundColor Red
    Write-Host "  Erro ao consultar GitHub: $_"
    exit 1
}

# 2. Download
$url    = "https://github.com/$repo/releases/download/$version/qactl.exe"
$tmpExe = Join-Path $env:TEMP "qactl-download.exe"
Write-Host "  Baixando qactl.exe $version..." -NoNewline
try {
    Invoke-WebRequest -Uri $url -OutFile $tmpExe -UseBasicParsing
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FALHOU" -ForegroundColor Red
    Write-Host "  Erro ao baixar: $_"
    exit 1
}

# 3. Instalar
Write-Host "  Instalando em $installDir..." -NoNewline
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Unblock-File -Path $tmpExe
Copy-Item $tmpExe "$installDir\qactl.exe" -Force
Remove-Item $tmpExe -Force
Write-Host " OK" -ForegroundColor Green

# 4. PATH
Write-Host "  Configurando PATH..." -NoNewline
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$userPath;$installDir", "User")
    $env:PATH = "$env:PATH;$installDir"
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " ja configurado" -ForegroundColor Yellow
}

# 5. Validar
Write-Host "  Validando instalacao..." -NoNewline
$installed = & "$installDir\qactl.exe" --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host " $installed" -ForegroundColor Green
} else {
    Write-Host " FALHOU" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  ✓ $installed instalado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "  Proximo passo — abra um novo terminal e rode:" -ForegroundColor Yellow
Write-Host "  qactl configure" -ForegroundColor White
Write-Host ""
