<#
.SYNOPSIS
    Descripción general del script.

.DESCRIPTION
    Realiza la validación de una carpeta dentro de un Script y sino existe la crea en el Path que le especifiquen.

.AUTHOR
    @SoyITPro
#>

$folderPath = "C:\Temp"

#verificar la carpeta
if (-not (Test-Path -Path $folderPath -PathType Container)) {
    try {
        # Crear la carpeta si no existe

        Write-Host "[STATUS] La carpeta $folderPath no existe, creandola..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $folderPath -ErrorAction Stop | Out-Null
        Write-Host "[SUCCESS] Carpeta creada exitosamente en $folderPath" -ForegroundColor Green
    }

    catch {

        Write-Host "[ERROR] Fallo al crear la carpeta $folderPath : $_" -ForegroundColor Red
        exit 1
    }

}    