# GPU Passthrough en Proxmox VE

## Que es IOMMU

### **Es un componente de hardware que actúa como un puente entre los dispositivos de E/S (como tarjetas gráficas o de red) y la memoria principal del sistema**

En el host Proxmox, ejecuta:

# Habilitar IOMMU en el kernel (GRUB)

Edita `/etc/default/grub` y modifica la línea `GRUB_CMDLINE_LINUX_DEFAULT` añadiendo el parámetro correspondiente:

- Intel:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
```

- AMD:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"

```

Aplicar y reiniciar:

```bash
update-grub
update-initramfs -u -k all
reboot

```

# Verificar IOMMU en el host (Proxmox)

```bash
# Verificar mensajes IOMMU
dmesg | grep -i iommu
# Lista dispositivos NVIDIA (+ IDs)
lspci -nnk | grep -iA3 nvidia
# Mostrar grupos IOMMU (útil para ver qué va junto)
for g in /sys/kernel/iommu_groups/*; do
  echo "IOMMU Group ${g##*/}"
  ls -l $g/devices
done

```

Verifica tras reinicio

```bash
lspci -k -s 02:00.0
# Debe decir: Kernel driver in use: vfio-pci
```

# Preparar vfio + evitar drivers del host

1. Crea/edita `/etc/modprobe.d/blacklist.conf` (evitar que host cargue drivers):

```bash
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf

```

## Añade módulos para VFIO en `/etc/modules`:

```bash
vfio
vfio_iommu_type1
vfio_pci

```

## Ligar la GPU a vfio-pci

Archivo **`/etc/modprobe.d/vfio.conf`**:

```bash
options vfio-pci ids=10de:1f02,10de:10f9,10de:1ada,10de:1adb disable_vga=1
```
Cambiar por los grupos de tu implementación

## Actualiza initramfs y reinicia:

```bash
update-initramfs -u -k all
reboot

```

## Después del reinicio, confirma que la GPU esté ligada a `vfio-pci`:

```bash
lspci -k -s 01:00.0   # sustituye la dirección PCI
# debe mostrar "Kernel driver in use: vfio-pci"

```

## Crear / preparar la VM en Proxmox

Suponiendo que tu VM es ID **100** y usas BIOS **OVMF (UEFI)** y **Machine: q35**:

```bash
# Ocultar hypervisor para evitar Code 43
qm set 100 -cpu host,hidden=1

# Pasar GPU (VGA)
qm set 100 -hostpci0 02:00.0,pcie=1,x-vga=1

# Pasar Audio HDMI
qm set 100 -hostpci1 02:00.1

# (opcional) pasar también USB controllers
qm set 100 -hostpci2 02:00.2
qm set 100 -hostpci3 02:00.3
 
```