# ==========================================
# Windows Boot Analyzer
# ==========================================

Write-Host ""
Write-Host "Analizando último arranque (PRO++)..." -ForegroundColor Cyan
Write-Host ""

# 1️⃣ Inicio del kernel
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

# 2️⃣ Kernel listo (Event ID 12)
$kernelEvent = Get-WinEvent -FilterHashtable @{
    LogName="System"
    Id=12
} -MaxEvents 1

$kernelReady = $kernelEvent.TimeCreated
$kernelSeconds = [math]::Round(($kernelReady - $bootTime).TotalSeconds,2)

# 3️⃣ Logon interactivo (4624 tipo 2)
$logonEvent = Get-WinEvent -FilterHashtable @{
    LogName="Security"
    Id=4624
} | Where-Object {
    $_.TimeCreated -gt $bootTime -and $_.Properties[8].Value -eq 2
} | Select-Object -First 1

if ($logonEvent) {
    $logonTime = $logonEvent.TimeCreated
    $logonSeconds = [math]::Round(($logonTime - $bootTime).TotalSeconds,2)
} else {
    $logonTime = $null
    $logonSeconds = "N/A"
}

# 4️⃣ Inicio de Explorer (Desktop ready aproximado)
$explorerProcess = Get-CimInstance Win32_Process |
Where-Object { $_.Name -eq "explorer.exe" } |
Sort-Object CreationDate |
Select-Object -First 1

if ($explorerProcess) {
    $explorerStart = $explorerProcess.CreationDate
    $desktopSeconds = [math]::Round(($explorerStart - $bootTime).TotalSeconds,2)
} else {
    $explorerStart = $null
    $desktopSeconds = "N/A"
}

# 5️⃣ Mostrar resultados estilo Linux
Write-Host "--------------------------------------------------"
Write-Host "        Windows Boot Analysis PRO++"
Write-Host "--------------------------------------------------"
Write-Host ""

Write-Host "Kernel initialization  :" $kernelSeconds "seconds"

if ($logonSeconds -ne "N/A") {
    Write-Host "Time to user logon     :" $logonSeconds "seconds"
}

if ($desktopSeconds -ne "N/A") {
    Write-Host "Time to desktop ready  :" $desktopSeconds "seconds"
}

Write-Host ""

if ($desktopSeconds -ne "N/A") {
    Write-Host "Startup finished in $desktopSeconds seconds (kernel + logon + desktop)"
} elseif ($logonSeconds -ne "N/A") {
    Write-Host "Startup finished in $logonSeconds seconds (kernel + logon)"
} else {
    Write-Host "Startup finished in $kernelSeconds seconds (kernel only)"
}

Write-Host ""