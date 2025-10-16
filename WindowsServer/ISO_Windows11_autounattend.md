# 🧩 Personalizar la instalación de Windows 11 con un archivo `autounattend.xml`

En este artículo aprenderás a automatizar la instalación de **Windows 11** mediante un archivo de respuesta (`autounattend.xml`) y a crear una **ISO personalizada** con la herramienta **oscdimg**, ideal para entornos de laboratorio, Hyper-V, Proxmox o VMware.

---

## 📁 ¿Qué es `autounattend.xml`?

El archivo `autounattend.xml` le indica al instalador de Windows qué configuraciones aplicar automáticamente, como:

- Crear una **cuenta local**  
- Establecer **idioma, zona horaria y teclado**  
- Aceptar términos de licencia  
- Saltar la conexión a Internet  
- Configurar el nombre del equipo

Con este archivo, puedes realizar instalaciones **sin intervención del usuario**, conocidas como *instalaciones desatendidas*.

---

## ⚙️ Paso 1. Crear el archivo `autounattend.xml`

Puedes generar este archivo usando la herramienta oficial de Microsoft:  
📎 [Windows System Image Manager (SIM)](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/windows-system-image-manager--windows-sim-)

También puedes usar el sitio [https://schneegans.de/windows/unattend-generator/](https://schneegans.de/windows/unattend-generator/)
Modifica las opciones del archivo autonattend.xml que necesites para tu instalacion

## 📦 Paso 2. Montar el ISO de Windows 11

Podemos darle doble clic al ISO o montarlo con PowerShell

```powershell
Mount-DiskImage -ImagePath "C:\Win11.iso"
```

Copia todo su contenido a una carpeta temporal en el Explorador de archivos o con robocopy:
```powershell
robocopy D:\ C:\W11ISO /E
```

Copia tu archivo autounattend.xml en la raíz de esa carpeta:
```powershell
copy C:\autounattend.xml C:\Win11_Custom\
```

## 🧱 Paso 3. Instalar las herramientas del ADK

Para usar oscdimg, necesitas el Windows ADK (Assessment and Deployment Kit):
🔗 Descargar Windows ADK

Instala también el componente Deployment Tools.

Después de la instalación, encontrarás oscdimg.exe en una ruta similar a:

```java
C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe
```

## 💽 Paso 4. Crear la ISO personalizada
Ejecuta el siguiente comando en PowerShell o en el símbolo del sistema (CMD):

```powershell
oscdimg.exe" -m -o -u2 -udfver102 -bootdata:2#p0,e,bC:\Win11_Custom\boot\etfsboot.com#pEF,e,bC:\Win11_Custom\efi\microsoft\boot\efisys.bin C:\W11_Custom C:\ISOs\Win11_Custom.iso
```

## ✅ Conclusión

Con este método puedes:

- Automatizar instalaciones de Windows 11

- Crear usuarios locales sin conexión a Internet

- Personalizar la configuración regional

- Preparar entornos de prueba o despliegue masivo