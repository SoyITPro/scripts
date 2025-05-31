#Valida en los Path si existen archivos .vbs

$pathsToScan = @("C:\Users", "C:\ProgramData", "C:\Scripts")
$logPath = "C:\VBSScriptScan\VbsFiles_$(hostname).csv"

# Crear directorio si no existe
if (-not (Test-Path (Split-Path $logPath -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath -Parent) | Out-Null
}

$results = foreach ($path in $pathsToScan) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Filter *.vbs -Recurse -ErrorAction SilentlyContinue |
        Select-Object FullName, LastWriteTime, Length
    }
}

$results | Export-Csv -Path $logPath -NoTypeInformation
