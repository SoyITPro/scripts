# Script corregido para instalar y configurar Oh My Posh en Windows PowerShell
# Autor original: @SoyITPro | Versión mejorada por @rubengg70

# Verificar si el módulo OhMyPosh ya está instalado
if (-not (Get-Module -ListAvailable -Name oh-my-posh)) {
    Write-Host "⏳ Instalando módulo Oh My Posh..."
    Install-Module oh-my-posh -Scope CurrentUser -Force
} else {
    Write-Host "✅ Oh My Posh ya está instalado."
}

# Verificar si el perfil existe, y crearlo si no
if (!(Test-Path -Path $PROFILE)) {
    Write-Host "📁 Perfil de PowerShell no encontrado. Creando..."
    New-Item -ItemType File -Path $PROFILE -Force
}

# Añadir línea para importar oh-my-posh si no existe
$poshInitLine = 'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression'

if (-not (Select-String -Path $PROFILE -Pattern "oh-my-posh init" -Quiet)) {
    Write-Host "➕ Agregando configuración de Oh My Posh al perfil..."
    Add-Content -Path $PROFILE -Value "`n$poshInitLine"
} else {
    Write-Host "📝 La configuración de Oh My Posh ya está en el perfil."
}

# Verificar si las fuentes NerdFont están instaladas (solo validación simple)
$fontPath = "$env:WINDIR\Fonts\CascadiaCodeNerdFont.ttf"
if (!(Test-Path $fontPath)) {
    Write-Host "⚠️ Fuente NerdFont no encontrada. Descarga manual recomendada:"
    Write-Host "🔗 https://www.nerdfonts.com/font-downloads"
} else {
    Write-Host "✅ Fuente NerdFont encontrada en el sistema."
}

Write-Host "🎉 Configuración finalizada. Reinicia tu terminal para aplicar los cambios."
