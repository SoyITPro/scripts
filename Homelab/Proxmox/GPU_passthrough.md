🧠 ¿Qué es IOMMU?
IOMMU (Input-Output Memory Management Unit) es un componente de hardware que actúa como puente entre los dispositivos de entrada/salida (como tarjetas gráficas o de red) y la memoria principal del sistema. Permite asignar dispositivos directamente a máquinas virtuales, mejorando el rendimiento y la seguridad.

⚙️ Activar IOMMU en Proxmox
1. Habilitar IOMMU en el kernel (GRUB)
Edita /etc/default/grub y modifica la línea GRUB_CMDLINE_LINUX_DEFAULT:

Intel:

bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
AMD:

bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"
Aplica cambios y reinicia:

bash
update-grub
update-initramfs -u -k all
reboot
2. Verificar IOMMU en el host
bash
# Verificar mensajes IOMMU
dmesg | grep -i iommu

# Listar dispositivos NVIDIA (+ IDs)
lspci -nnk | grep -iA3 nvidia

# Mostrar grupos IOMMU
for g in /sys/kernel/iommu_groups/*; do
  echo "IOMMU Group ${g##*/}"
  ls -l $g/devices
done
Tras reiniciar, verifica el driver:

bash
lspci -k -s 02:00.0
# Debe decir: Kernel driver in use: vfio-pci
🛡️ Preparar VFIO y evitar drivers del host
1. Blacklist de drivers
Edita /etc/modprobe.d/blacklist.conf:

bash
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
2. Añadir módulos VFIO en /etc/modules
bash
vfio
vfio_iommu_type1
vfio_pci
3. Ligar GPU a vfio-pci
Archivo /etc/modprobe.d/vfio.conf:

bash
options vfio-pci ids=10de:1f02,10de:10f9,10de:1ada,10de:1adb disable_vga=1
Actualiza y reinicia:

bash
update-initramfs -u -k all
reboot
4. Confirmar que la GPU usa vfio-pci
bash
lspci -k -s 01:00.0
# Debe mostrar: Kernel driver in use: vfio-pci
🖥️ Crear y preparar la VM en Proxmox
VM ID: 100

BIOS: OVMF (UEFI)

Machine: q35

⚠️ Asegúrate de que la VM esté configurada para usar UEFI y que el dispositivo PCI esté asignado correctamente desde la interfaz de Proxmox.