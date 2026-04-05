# Activar gpedit.msc en Windows Home usando un script

## 📌 Descripción general

Este script de tipo **batch (.bat)** permite habilitar el Editor de Directivas de Grupo (**gpedit.msc**) en ediciones de Windows donde no está disponible por defecto, como **Windows Home**.

El script funciona instalando manualmente paquetes internos del sistema relacionados con las políticas de grupo utilizando la herramienta DISM.

---

## ⚙️ ¿Qué hace el código en términos generales?

1. Busca en el sistema los paquetes relacionados con:

   * Group Policy Client Extensions
   * Group Policy Client Tools

2. Genera un listado de estos paquetes en un archivo temporal (`List.txt`).

3. Recorre cada paquete encontrado.

4. Usa DISM para instalar dichos paquetes en el sistema en ejecución.

5. Permite que el sistema tenga acceso al editor de políticas de grupo (`gpedit.msc`).

---

## 🧾 Código del script

```bat
@echo off
pushd "%~dp0"

dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum >List.txt
dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum >>List.txt

for /f %%i in ('findstr /i . List.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"
pause
```

---

## 🚀 Cómo usar el script

### 1. Crear el archivo

1. Abre el Bloc de notas.
2. Copia el código anterior.
3. Guarda el archivo como:

```
gpedit.bat
```

> ⚠️ Asegúrate de que la extensión sea `.bat` y no `.txt`.

---

### 2. Ejecutar como administrador

1. Haz clic derecho sobre el archivo.
2. Selecciona **"Ejecutar como administrador"**.

---

### 3. Esperar la instalación

* El proceso puede tardar unos minutos.
* Verás cómo DISM instala los paquetes.

---

### 4. Verificar que gpedit funciona

1. Presiona `Win + R`.
2. Escribe:

```
gpedit.msc
```

3. Presiona Enter.

Si todo salió bien, se abrirá el Editor de Directivas de Grupo.

---

## ⚠️ Consideraciones importantes

* Este método **no es oficial**.
* No convierte Windows Home en Pro.
* Algunas políticas pueden no funcionar completamente.
* Se recomienda crear un punto de restauración antes de ejecutar el script.

---

## 🛠️ Posibles problemas

### ❌ gpedit.msc no abre

* Reinicia el sistema.
* Verifica que ejecutaste el script como administrador.

### ❌ Errores en DISM

Ejecuta en CMD como administrador:

```
sfc /scannow
```

Luego intenta nuevamente.

---

## 🧠 Conclusión

Este script es una forma práctica de habilitar herramientas avanzadas de administración en Windows Home reutilizando componentes que ya existen en el sistema pero no están activados por defecto.

---

## 📄 Licencia

Uso educativo y bajo tu propia responsabilidad.
