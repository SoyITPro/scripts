<#
.SYNOPSIS
    Crea usuarios de Active Directory de forma aleatoria con nombres y apellidos desde archivos separados
.DESCRIPTION
    Este script crea usuarios en Active Directory con nombres aleatorios desde Firstnames.txt,
    apellidos aleatorios desde Lastnames.txt, departamentos aleatorios de una lista predefinida,
    y una contraseña inicial común. Incluye sistema anti-duplicados para samAccountName.
.PARAMETER OUPath
    Ruta de la Unidad Organizativa donde se crearán los usuarios (ej: "OU=Usuarios,DC=dominio,DC=local")
.PARAMETER DomainName
    Nombre del dominio (ej: "dominio.local")
.PARAMETER UserCount
    Número de usuarios a crear
.PARAMETER InitialPassword
    Contraseña inicial para todos los usuarios (debe cumplir con la política de contraseñas)
.PARAMETER FirstNamesFile
    Ruta al archivo con nombres (por defecto: .\Firstnames.txt)
.PARAMETER LastNamesFile
    Ruta al archivo con apellidos (por defecto: .\Lastnames.txt)
.EXAMPLE
    .\CrearUsuariosAD.ps1 -OUPath "OU=Usuarios,DC=midominio,DC=local" -DomainName "midominio.local" -UserCount 50 -InitialPassword "P@ssw0rd123"
.EXAMPLE
    .\CrearUsuariosAD.ps1 -OUPath "OU=Usuarios,DC=midominio,DC=local" -DomainName "midominio.local" -UserCount 100 -InitialPassword "P@ssw0rd123" -FirstNamesFile "C:\Data\nombres.txt" -LastNamesFile "C:\Data\apellidos.txt"
.NOTES
    Autor: @SoyITPro
    Fecha: $(Get-Date -Format "dd/MM/yyyy")
    Requisitos: Módulo ActiveDirectory, archivos Firstnames.txt y Lastnames.txt
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Ingrese la ruta de la OU (ej: OU=Usuarios,DC=dominio,DC=local)")]
    [string]$OUPath,
    
    [Parameter(Mandatory=$true, HelpMessage="Ingrese el nombre del dominio (ej: dominio.local)")]
    [string]$DomainName,
    
    [Parameter(Mandatory=$true, HelpMessage="Ingrese la cantidad de usuarios a crear")]
    [int]$UserCount,
    
    [Parameter(Mandatory=$true, HelpMessage="Ingrese la contraseña inicial para todos los usuarios")]
    [string]$InitialPassword,
    
    [Parameter(Mandatory=$false)]
    [string]$FirstNamesFile = ".\Firstnames.txt",
    
    [Parameter(Mandatory=$false)]
    [string]$LastNamesFile = ".\Lastnames.txt"
)

# Importar el módulo de Active Directory
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Host "✅ Módulo Active Directory importado correctamente." -ForegroundColor Green
} catch {
    Write-Error "❌ No se pudo importar el módulo Active Directory. Asegúrese de tener instalado RSAT-AD-PowerShell."
    exit 1
}

# Verificar que la OU existe o crearla
try {
    $ouExists = Get-ADOrganizationalUnit -Identity $OUPath -ErrorAction Stop
    Write-Host "✅ OU encontrada: $OUPath" -ForegroundColor Green
} catch {
    Write-Host "⚠️ La OU especificada no existe. Creando..." -ForegroundColor Yellow
    try {
        $ouName = ($OUPath -split ',')[0] -replace 'OU=',''
        $ouParent = $OUPath -replace 'OU=[^,]+,',''
        New-ADOrganizationalUnit -Name $ouName -Path $ouParent -ProtectedFromAccidentalDeletion $false
        Write-Host "✅ OU creada exitosamente." -ForegroundColor Green
    } catch {
        Write-Error "❌ No se pudo crear la OU: $_"
        exit 1
    }
}

# Verificar política de contraseñas
if ($InitialPassword.Length -lt 8) {
    Write-Warning "⚠️ La contraseña debe tener al menos 8 caracteres para cumplir con la política de AD."
    exit 1
}

# Verificar y crear archivos de nombres y apellidos si no existen
function Initialize-NameFiles {
    param(
        [string]$FirstNamesFile,
        [string]$LastNamesFile
    )
    
    # Crear archivo de nombres si no existe
    if (-not (Test-Path $FirstNamesFile)) {
        Write-Host "⚠️ No se encontró $FirstNamesFile. Creando archivo de ejemplo..." -ForegroundColor Yellow
        
        $nombres = @(
            "Juan", "María", "Carlos", "Ana", "Luis", "Laura", "Pedro", "Carmen", "Miguel", "Isabel",
            "Javier", "Patricia", "David", "Elena", "Francisco", "Teresa", "José", "Silvia", "Antonio", "Raquel",
            "Manuel", "Rosa", "Pablo", "Marta", "Jesús", "Sara", "Alejandro", "Paula", "Daniel", "Eva",
            "Adrián", "Cristina", "Enrique", "Natalia", "Diego", "Carolina", "Andrés", "Julia", "Óscar", "Nuria",
            "Sergio", "Alicia", "Roberto", "Marina", "Rafael", "Paula", "Jaime", "Olga", "José Antonio", "Beatriz",
            "Ramon", "Ángeles", "Jorge", "Pilar", "Vicente", "Elena", "Tomás", "Gloria", "Álvaro", "Susana",
            "Mario", "Inmaculada", "Fernando", "Dolores", "Roberto", "Cristina", "Emilio", "Ainhoa", "Marcos", "Esther",
            "Gustavo", "Lidia", "Arturo", "Victoria", "Hugo", "Sofía", "Lucas", "Mia", "Mateo", "Maya",
            "Iván", "Valeria", "Alejandra", "Nicolás", "Martina", "Santiago", "Leo", "Noah", "Alma", "Matías",
            "Liam", "Olivia", "Ethan", "Isabella", "Mason", "Ava", "Logan", "Sophia", "Oliver", "Camila",
            "Benjamin", "Mila", "Elijah", "James", "Nora", "Alexander", "Zoe", "Sebastián", "Chloe", "Daniel",
            "Avery", "Mateo", "Victoria", "Pablo", "Sofía", "Alejandro", "Carmen", "Javier", "Isabel", "Manuel"
        )
        
        $nombres | Out-File -FilePath $FirstNamesFile -Encoding UTF8
        Write-Host "✅ Archivo de nombres creado: $FirstNamesFile" -ForegroundColor Green
    }
    
    # Crear archivo de apellidos si no existe
    if (-not (Test-Path $LastNamesFile)) {
        Write-Host "⚠️ No se encontró $LastNamesFile. Creando archivo de ejemplo..." -ForegroundColor Yellow
        
        $apellidos = @(
            "Pérez", "García", "Rodríguez", "Martínez", "López", "González", "Fernández", "Ruiz", "Díaz", "Álvarez",
            "Moreno", "Jiménez", "Sánchez", "Romero", "Torres", "Vázquez", "Morales", "Ramos", "Castro", "Ortega",
            "Sanz", "Iglesias", "Gil", "Molina", "Reyes", "Blanco", "Herrera", "Pérez", "Rodríguez", "García",
            "Martínez", "López", "González", "Fernández", "Ruiz", "Díaz", "Álvarez", "Moreno", "Jiménez", "Sánchez",
            "Romero", "Torres", "Vázquez", "Morales", "Ramos", "Castro", "Ortega", "Sanz", "Iglesias", "Gil",
            "Molina", "Reyes", "Blanco", "Herrera", "Delgado", "Núñez", "Serrano", "Mendoza", "Fuentes", "Peña",
            "Márquez", "Rivera", "Padilla", "Benítez", "Rivas", "Soto", "Vargas", "Guerrero", "Domínguez", "Martí",
            "Calvo", "Durán", "Vidal", "Vega", "Vera", "Cabrera", "Salazar", "Santos", "Gallego", "Cortés",
            "Palacios", "Marín", "Caballero", "Guerra", "Ortiz", "Franco", "Rey", "Suárez", "Campos", "Lara",
            "Alonso", "Muñoz", "Flores", "Gutiérrez", "Navarro", "Pascual", "Cano", "Pastor", "Soler", "Mora"
        )
        
        $apellidos | Out-File -FilePath $LastNamesFile -Encoding UTF8
        Write-Host "✅ Archivo de apellidos creado: $LastNamesFile" -ForegroundColor Green
    }
}

# Inicializar archivos
Initialize-NameFiles -FirstNamesFile $FirstNamesFile -LastNamesFile $LastNamesFile

# Cargar nombres y apellidos desde archivos
try {
    $firstNames = Get-Content -Path $FirstNamesFile -Encoding UTF8 | Where-Object { $_ -ne "" } | ForEach-Object { $_.Trim() }
    $lastNames = Get-Content -Path $LastNamesFile -Encoding UTF8 | Where-Object { $_ -ne "" } | ForEach-Object { $_.Trim() }
    
    if ($firstNames.Count -eq 0 -or $lastNames.Count -eq 0) {
        Write-Error "❌ Los archivos de nombres o apellidos están vacíos."
        exit 1
    }
    
    Write-Host "✅ Cargados $($firstNames.Count) nombres y $($lastNames.Count) apellidos." -ForegroundColor Green
} catch {
    Write-Error "❌ Error al leer los archivos: $_"
    exit 1
}

# Lista de departamentos
$departamentos = @(
    "Ventas", "Marketing", "Recursos Humanos", "Tecnología de la Información", "Finanzas",
    "Investigación y Desarrollo", "Atención al Cliente", "Logística", "Calidad", "Producción",
    "Compras", "Dirección General", "Seguridad", "Mantenimiento", "Administración",
    "Ingeniería", "Operaciones", "Legal", "Consultoría", "Formación"
)

# Función para generar samAccountName único
function Generate-UniqueSamAccountName {
    param(
        [string]$Nombre,
        [string]$Apellido,
        [System.Collections.Generic.HashSet[string]]$UsedSamNames
    )
    
    $maxAttempts = 100
    $attempt = 0
    $baseSam = ""
    
    # Limpiar caracteres especiales y convertir a minúsculas
    $nombreClean = $Nombre -replace '[^a-zA-Z]', '' -replace ' ', ''
    $apellidoClean = $Apellido -replace '[^a-zA-Z]', '' -replace ' ', ''
    
    # Generar diferentes combinaciones
    $combinaciones = @(
        # Combinación 1: primeras letras del nombre + apellido completo (si es corto)
        { 
            $n = $nombreClean.Substring(0, [Math]::Min(2, $nombreClean.Length))
            $a = $apellidoClean.Substring(0, [Math]::Min(5, $apellidoClean.Length))
            ($n + $a).ToLower()
        },
        # Combinación 2: nombre completo + primeras letras del apellido
        {
            $n = $nombreClean.Substring(0, [Math]::Min(4, $nombreClean.Length))
            $a = $apellidoClean.Substring(0, [Math]::Min(2, $apellidoClean.Length))
            ($n + $a).ToLower()
        },
        # Combinación 3: primera letra del nombre + apellido completo
        {
            $n = $nombreClean.Substring(0, 1)
            $a = $apellidoClean.Substring(0, [Math]::Min(7, $apellidoClean.Length))
            ($n + $a).ToLower()
        },
        # Combinación 4: nombre completo + primera letra del apellido
        {
            $n = $nombreClean.Substring(0, [Math]::Min(5, $nombreClean.Length))
            $a = $apellidoClean.Substring(0, 1)
            ($n + $a).ToLower()
        },
        # Combinación 5: apellido + primera letra del nombre
        {
            $a = $apellidoClean.Substring(0, [Math]::Min(5, $apellidoClean.Length))
            $n = $nombreClean.Substring(0, 1)
            ($a + $n).ToLower()
        },
        # Combinación 6: las primeras 3 del nombre + las primeras 3 del apellido
        {
            $n = $nombreClean.Substring(0, [Math]::Min(3, $nombreClean.Length))
            $a = $apellidoClean.Substring(0, [Math]::Min(3, $apellidoClean.Length))
            ($n + $a).ToLower()
        }
    )
    
    # Intentar generar un nombre único
    do {
        $attempt++
        
        if ($attempt -le $combinaciones.Count) {
            # Usar las combinaciones predefinidas
            $baseSam = & $combinaciones[$attempt - 1]
        } else {
            # Si se agotan las combinaciones, usar la primera y agregar un número
            $baseSam = & $combinaciones[0]
            $suffix = Get-Random -Minimum 1 -Maximum 999
            $baseSam = $baseSam + $suffix.ToString()
        }
        
        # Si el nombre tiene menos de 3 caracteres, rellenar con números
        if ($baseSam.Length -lt 3) {
            $baseSam = $baseSam + (Get-Random -Minimum 10 -Maximum 99).ToString()
        }
        
        # Verificar si ya existe en el hashset de nombres usados
        $existsInHash = $UsedSamNames.Contains($baseSam)
        
        # Verificar si ya existe en Active Directory
        $existsInAD = $false
        if (-not $existsInHash) {
            try {
                $existingUser = Get-ADUser -Filter "SamAccountName -eq '$baseSam'" -ErrorAction SilentlyContinue
                if ($existingUser) {
                    $existsInAD = $true
                }
            } catch {
                # Si hay error, asumir que no existe
                $existsInAD = $false
            }
        }
        
        # Si no existe en ningún lado, es válido
        if (-not $existsInHash -and -not $existsInAD) {
            $UsedSamNames.Add($baseSam) | Out-Null
            return $baseSam
        }
        
        # Si existe, agregar un número aleatorio al final
        if ($attempt -gt 10) {
            $randomNum = Get-Random -Minimum 1 -Maximum 9999
            $baseSam = ($baseSam -replace '\d+$', '') + $randomNum.ToString()
            if (-not $UsedSamNames.Contains($baseSam)) {
                $UsedSamNames.Add($baseSam) | Out-Null
                return $baseSam
            }
        }
        
    } while ($attempt -lt $maxAttempts)
    
    # Si no se puede generar un nombre único, usar timestamp
    $timestamp = Get-Date -Format "HHmmssfff"
    $finalSam = ($nombreClean.Substring(0, [Math]::Min(2, $nombreClean.Length)) + $apellidoClean.Substring(0, [Math]::Min(2, $apellidoClean.Length)) + $timestamp).ToLower()
    $UsedSamNames.Add($finalSam) | Out-Null
    return $finalSam
}

# Función para crear un usuario
function Create-ADUser {
    param(
        [string]$Nombre,
        [string]$Apellido,
        [string]$Departamento,
        [string]$OUPath,
        [string]$DomainName,
        [string]$InitialPassword,
        [string]$SamAccountName,
        [int]$UserNumber,
        [int]$TotalUsers
    )
    
    # Construir el nombre completo
    $displayName = "$Nombre $Apellido"
    $givenName = $Nombre
    $sn = $Apellido
    $userPrincipalName = "$SamAccountName@$DomainName"
    
    # Configurar atributos del usuario
    $userParams = @{
        Name = $displayName
        GivenName = $givenName
        Surname = $sn
        SamAccountName = $SamAccountName
        UserPrincipalName = $userPrincipalName
        DisplayName = $displayName
        Department = $Departamento
        Path = $OUPath
        AccountPassword = (ConvertTo-SecureString -String $InitialPassword -AsPlainText -Force)
        Enabled = $true
        PassThru = $true
        ChangePasswordAtLogon = $true
        ErrorAction = 'Stop'
    }
    
    try {
        # Crear el usuario
        $newUser = New-ADUser @userParams
        
        Write-Host "✅ [$UserNumber/$TotalUsers] Usuario creado: $displayName" -ForegroundColor Green
        Write-Host "   🔹 SAM: $SamAccountName" -ForegroundColor Cyan
        Write-Host "   🔹 UPN: $userPrincipalName" -ForegroundColor Cyan
        Write-Host "   🔹 Depto: $Departamento" -ForegroundColor Cyan
        Write-Host "   🔹 Ruta: $OUPath" -ForegroundColor Cyan
        
        return @{
            Success = $true
            User = $newUser
            SamAccountName = $SamAccountName
            DisplayName = $displayName
        }
    } catch {
        Write-Error "❌ Error al crear usuario $displayName : $_"
        return @{
            Success = $false
            Error = $_
            SamAccountName = $SamAccountName
            DisplayName = $displayName
        }
    }
}

# --- PROGRAMA PRINCIPAL ---

Write-Host "`n" + "="*60 -ForegroundColor Magenta
Write-Host "   CREACIÓN ALEATORIA DE USUARIOS ACTIVE DIRECTORY" -ForegroundColor Magenta
Write-Host "   (Con nombres y apellidos desde archivos separados)" -ForegroundColor Magenta
Write-Host "="*60 -ForegroundColor Magenta
Write-Host ""
Write-Host "📋 Parámetros de configuración:" -ForegroundColor Yellow
Write-Host "  OU: $OUPath" -ForegroundColor White
Write-Host "  Dominio: $DomainName" -ForegroundColor White
Write-Host "  Usuarios a crear: $UserCount" -ForegroundColor White
Write-Host "  Archivo nombres: $FirstNamesFile ($($firstNames.Count) nombres)" -ForegroundColor White
Write-Host "  Archivo apellidos: $LastNamesFile ($($lastNames.Count) apellidos)" -ForegroundColor White
Write-Host "  Contraseña inicial: [OCULTA]" -ForegroundColor White
Write-Host ""

# Calcular combinaciones posibles
$totalCombinations = $firstNames.Count * $lastNames.Count
Write-Host "📊 Combinaciones posibles: $totalCombinations" -ForegroundColor Cyan

if ($UserCount -gt $totalCombinations) {
    Write-Warning "⚠️ El número de usuarios ($UserCount) excede las combinaciones únicas posibles ($totalCombinations)."
    Write-Host "   Se reutilizarán nombres con diferentes combinaciones." -ForegroundColor Yellow
}

# Confirmar antes de continuar
$confirm = Read-Host "`n¿Desea continuar con la creación de $UserCount usuarios? (S/N)"
if ($confirm -ne 'S' -and $confirm -ne 's') {
    Write-Host "❌ Operación cancelada por el usuario." -ForegroundColor Red
    exit 0
}

# Inicializar HashSet para nombres de usuario únicos
$usedSamNames = [System.Collections.Generic.HashSet[string]]::new()

# Inicializar contadores
$creados = 0
$fallidos = 0
$usuariosCreados = @()
$errores = @()

# Crear usuarios
Write-Host "`n🚀 Iniciando creación de usuarios..." -ForegroundColor Green
Write-Host ("-" * 60) -ForegroundColor Gray

# Usar un timer para medir rendimiento
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 1; $i -le $UserCount; $i++) {
    # Seleccionar nombre y apellido aleatorio
    $nombre = $firstNames | Get-Random
    $apellido = $lastNames | Get-Random
    
    # Seleccionar departamento aleatorio
    $departamento = $departamentos | Get-Random
    
    # Generar samAccountName único
    $samAccountName = Generate-UniqueSamAccountName -Nombre $nombre -Apellido $apellido -UsedSamNames $usedSamNames
    
    # Crear el usuario
    Write-Host "`n🔄 Creando usuario $i de $UserCount..." -ForegroundColor Yellow
    $resultado = Create-ADUser -Nombre $nombre -Apellido $apellido -Departamento $departamento `
                                -OUPath $OUPath -DomainName $DomainName -InitialPassword $InitialPassword `
                                -SamAccountName $samAccountName -UserNumber $i -TotalUsers $UserCount
    
    if ($resultado.Success) {
        $creados++
        $usuariosCreados += $resultado
    } else {
        $fallidos++
        $errores += $resultado
        Write-Host "   ❌ Error: $($resultado.Error)" -ForegroundColor Red
    }
    
    # Pequeña pausa para no saturar el AD
    Start-Sleep -Milliseconds 100
}

$stopwatch.Stop()

# Mostrar resumen final
Write-Host "`n" + "="*60 -ForegroundColor Magenta
Write-Host "📊 RESUMEN DE CREACIÓN" -ForegroundColor Magenta
Write-Host "="*60 -ForegroundColor Magenta
Write-Host "  ✅ Usuarios creados: $creados" -ForegroundColor Green
Write-Host "  ❌ Usuarios fallidos: $fallidos" -ForegroundColor $(if ($fallidos -gt 0) {"Red"} else {"Green"})
Write-Host "  📋 Total solicitados: $UserCount" -ForegroundColor White
Write-Host "  ⏱️ Tiempo total: $($stopwatch.Elapsed.ToString())" -ForegroundColor White
Write-Host ("-" * 60) -ForegroundColor Gray

if ($creados -gt 0) {
    Write-Host "`n📋 Lista de usuarios creados:" -ForegroundColor Cyan
    $usuariosCreados | ForEach-Object { 
        Write-Host "  🔹 $($_.DisplayName) - SAM: $($_.SamAccountName)" -ForegroundColor Cyan
    }
    
    Write-Host "`n🔑 Contraseña inicial para todos los usuarios: [OCULTA]" -ForegroundColor Yellow
    Write-Host "📝 Nota: Los usuarios deberán cambiar su contraseña en el próximo inicio de sesión." -ForegroundColor Yellow
}

if ($fallidos -gt 0) {
    Write-Host "`n❌ Errores encontrados:" -ForegroundColor Red
    $errores | ForEach-Object { 
        Write-Host "  🔹 $($_.DisplayName) - Error: $($_.Error)" -ForegroundColor Red
    }
}

# Exportar reporte
$reportePath = ".\Reporte_Usuarios_Creados_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$reporte = @"
REPORTE DE CREACIÓN DE USUARIOS ACTIVE DIRECTORY
================================================
Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
OU: $OUPath
Dominio: $DomainName
Usuarios solicitados: $UserCount
Usuarios creados exitosamente: $creados
Usuarios fallidos: $fallidos
Tiempo total: $($stopwatch.Elapsed.ToString())

LISTA DE USUARIOS CREADOS:
$($usuariosCreados | ForEach-Object { "$($_.DisplayName) - $($_.SamAccountName)" } | Join-String -Separator "`n")

CONTRASEÑA INICIAL: [OCULTA]
Política: Cambiar en próximo inicio de sesión

ESTADÍSTICAS:
- Nombres disponibles: $($firstNames.Count)
- Apellidos disponibles: $($lastNames.Count)
- Combinaciones posibles: $totalCombinations
- Nombres de usuario generados: $creados

"@

$reporte | Out-File -FilePath $reportePath -Encoding UTF8
Write-Host "`n📄 Reporte guardado en: $reportePath" -ForegroundColor Green

Write-Host "`n✅ Proceso completado!" -ForegroundColor Green