# qactl installer
# Uso: irm https://cdn.jsdelivr.net/gh/rafaelncintra/qactl-releases@main/install.ps1 | iex

$repo      = "rafaelncintra/qactl-releases"
$installDir = "$env:APPDATA\qactl"

Write-Host ""
Write-Host "  qactl - instalador" -ForegroundColor Cyan
Write-Host "  -----------------------------------------"
Write-Host ""

# 1. Download (URL permanente do ultimo release - sem chamada de API)
$url    = "https://github.com/$repo/releases/latest/download/qactl.exe"
$tmpExe = Join-Path $env:TEMP "qactl-download.exe"
Write-Host "  Baixando qactl.exe..." -NoNewline
try {
    Invoke-WebRequest -Uri $url -OutFile $tmpExe -UseBasicParsing
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FALHOU" -ForegroundColor Red
    Write-Host "  Erro ao baixar: $_"
    return
}

# 2. Instalar
Write-Host "  Instalando em $installDir..." -NoNewline
try {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    Unblock-File -Path $tmpExe
    Copy-Item $tmpExe "$installDir\qactl.exe" -Force
    Remove-Item $tmpExe -Force
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FALHOU" -ForegroundColor Red
    Write-Host "  Erro ao instalar: $_"
    return
}

# 3. PATH
Write-Host "  Configurando PATH..." -NoNewline
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$installDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$userPath;$installDir", "User")
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " ja configurado" -ForegroundColor Yellow
}

# Notifica o Windows para recarregar o PATH em novos terminais
if (-not ("Win32.NativeMethods" -as [type])) {
    Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
      [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
      public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam,
        string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
"@
}
$result = [UIntPtr]::Zero
[Win32.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x1a, [UIntPtr]::Zero,
    "Environment", 2, 5000, [ref]$result) | Out-Null
$env:PATH = [Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
            [Environment]::GetEnvironmentVariable("PATH","User")

# 4. Validar
Write-Host "  Validando instalacao..." -NoNewline
try {
    $installed = & "$installDir\qactl.exe" --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " $installed" -ForegroundColor Green
    } else {
        Write-Host " FALHOU (exit $LASTEXITCODE)" -ForegroundColor Red
        return
    }
} catch {
    Write-Host " FALHOU" -ForegroundColor Red
    Write-Host "  Erro: $_"
    return
}

Write-Host ""
Write-Host "  [OK] $installed instalado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "  Proximo passo - abra um novo terminal e rode:" -ForegroundColor Yellow
Write-Host "  qactl configure" -ForegroundColor White
Write-Host ""
