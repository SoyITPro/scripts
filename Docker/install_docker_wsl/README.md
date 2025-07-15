Instalacíón de Docker en WSL 2 con Windows 11

### Requisitos
---


* Windows 10, 11 últimas versiones
* [Habilitar WSL](https://youtu.be/-jTNQSlkw2Y)
* Ubuntu 24.04 como distro

### Actualizar Ubuntu
---

``` bash
sudo apt update && sudo apt upgrade -y
```

### Instalar dependencias
---
``` bash
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
```

### Agregar Docker GPG Key
---
``` bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

### Agregar los repositorios de Docker
---
``` bash
echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Instalar Docker Engine
---
``` bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Agregar tu usuario a Docker Group
---
``` bash
sudo usermod -aG docker $USER
```

### Verificar la instalación
---
Cierre la terminal de Ubuntu
Reinicie WSL con comando en PowerShell

``` powershell
wsl --shutdown
```
Ingrese nuevamente en Ubuntu y verifique que Docker se instaló correctamente.

``` bash
docker --version
```