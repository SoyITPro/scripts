# Configuración de Registro: RedirectionWarningDialogVersion

## 📍 Ruta del Registro
HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services\Client


## ⚙️ Valor Configurado

- **Nombre:** `RedirectionWarningDialogVersion`  
- **Tipo:** `REG_DWORD`  
- **Dato:** `1`  

## 🧠 ¿Qué hace esta configuración?

Este valor controla el comportamiento del cuadro de advertencia relacionado con la **redirección de recursos locales** en conexiones de **Escritorio Remoto (RDP)**.

Cuando se establece en:

- `1` → Se utiliza una versión específica del cuadro de advertencia que aparece cuando se redirigen recursos como:
  - Unidades locales
  - Portapapeles
  - Dispositivos USB
  - Impresoras

## 🔐 ¿Por qué es importante?

En entornos empresariales, la redirección de recursos puede representar un **riesgo de seguridad**, ya que permite transferir datos entre el equipo local y el remoto.

Esta clave permite:

- Estandarizar el comportamiento del aviso de seguridad.
- Asegurar que los usuarios reciban una advertencia consistente.
- Apoyar políticas de seguridad definidas mediante GPO o herramientas como Intune.

## 🏢 Escenarios comunes de uso

- Implementaciones corporativas con políticas de seguridad estrictas.
- Ambientes donde se requiere control sobre la exfiltración de datos.
- Configuración gestionada mediante:
  - Group Policy (GPO)
  - Microsoft Intune
  - Scripts de automatización

## ⚠️ Consideraciones

- Este valor no desactiva la redirección, solo afecta la forma en que se presenta la advertencia al usuario.
- Debe ser aplicado con privilegios administrativos.
- Puede ser sobrescrito por políticas de dominio si existen.

## 📦 Ejemplo de archivo `.reg`

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services\Client]
"RedirectionWarningDialogVersion"=dword:00000001