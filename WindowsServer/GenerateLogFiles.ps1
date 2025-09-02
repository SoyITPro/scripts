<#
.SYNOPSIS
    Genera carpetas y archivos de log con tamaño específico.
.DESCRIPTION
    Crea 20 carpetas y dentro de cada una 100 archivos de log.
.NOTES
    File Name      : GenerateLogFiles.ps1
    Author         : @SoyITPro
    Prerequisite   : PowerShell 5.1 o superior
#>

# Configuración
$basePath = "C:\Logs"  # Cambia esta ruta según necesites
$folderCount = 20
$filesPerFolder = 100
$fileSizeMB = 10
$fileSizeBytes = $fileSizeMB * 1MB

# Crear directorio base si no existe
if (-not (Test-Path -Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
    Write-Host "Directorio base creado en: $basePath"
}

# Generar las carpetas y archivos
for ($i = 1; $i -le $folderCount; $i++) {
    $folderName = "LogFolder_$i"
    $folderPath = Join-Path -Path $basePath -ChildPath $folderName
    
    # Crear carpeta
    New-Item -ItemType Directory -Path $folderPath | Out-Null
    
    Write-Host "Creando archivos en $folderName..."
    
    # Generar archivos en la carpeta actual
    for ($j = 1; $j -le $filesPerFolder; $j++) {
        $fileName = "logfile_$j.log"
        $filePath = Join-Path -Path $folderPath -ChildPath $fileName
        
        # Crear archivo con contenido aleatorio del tamaño especificado
        $randomContent = [System.IO.Path]::GetRandomFileName() * ($fileSizeBytes / 22)
        Set-Content -Path $filePath -Value $randomContent -NoNewline
        
        # Mostrar progreso cada 10 archivos
        if ($j % 10 -eq 0) {
            Write-Host "  Creados $j/$filesPerFolder archivos..."
        }
    }
    
    Write-Host "Finalizada la creación en $folderName ($filesPerFolder archivos de $fileSizeMB MB cada uno)"
}

Write-Host "Proceso completado!"
Write-Host "Total carpetas creadas: $folderCount"
Write-Host "Total archivos creados: $($folderCount * $filesPerFolder)"
Write-Host "Tamaño total aproximado: $($folderCount * $filesPerFolder * $fileSizeMB) MB"