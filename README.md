# FPGA4U Hello World (Cyclone II EP2C20) en un Mac Apple Silicon

## Qué hace el diseño

| Elemento | Comportamiento |
|---|---|
| LEDs de los pulsadores (amarillo, verde, naranja, rojo) | Contador binario, más o menos 1,4 veces por segundo |
| Matriz de 96 LEDs | Una luz que recorre los 96 LEDs |
| SW6 mantenido | La luz cambia de sentido |
| SW5 mantenido | La luz se para |
| SW3 / SW4 | Encienden su LED mientras están pulsados |
| SW7 (Rz) | Reset del diseño |
| SW8 (Init) | Recarga lo que haya en la flash (no es del diseño, es de la placa) |

Ficheros:

- `hello_fpga4u.v`: el diseño en Verilog.
- `hello_fpga4u.qsf` / `.qpf`: el proyecto de Quartus con todos los pines (sacados de la wiki de la EPFL).
- `hello_fpga4u.sdc`: el reloj de 24 MHz.
- `build.sh`: compila y genera `.sof`, `.svf` y `.jic`.
- `program_vm.sh`: programa la placa desde la VM.
- `program_mac.sh`: programa la placa desde macOS con OpenOCD (experimental).

> Antes de nada, mira la serigrafía del chip grande. Si pone **EP2C20F484C6N** en vez de C8,
> cambia `EP2C20F484C8` por `EP2C20F484C6` en `hello_fpga4u.qsf`.

---

## 1. Crear la VM en UTM

Quartus II 13.0 SP1, la última versión que soporta Cyclone II, solo existe para x86. En Apple
Silicon hay que **emular** x86 con UTM (QEMU). Funciona, pero es lento, así que usaremos una VM
sin escritorio y compilaremos por línea de comandos.

1. Instala UTM: https://mac.getutm.app (o `brew install --cask utm`).
2. Descarga la ISO de **Ubuntu Server 20.04 LTS (amd64)**: https://releases.ubuntu.com/20.04/
   (la 20.04 tiene las librerías antiguas que espera Quartus 13; con la 22.04 o la 24.04 hay que pelearse más).
3. En UTM: **Create a New Virtual Machine → Emulate → Linux**.
   - Boot ISO: la ISO de Ubuntu.
   - Architecture: **x86_64**, System: **Standard PC (Q35 + ICH9)**.
   - Memoria: **8 GB**; CPU cores: **4** o más.
   - Disco: **40 GB** (Quartus ocupa unos 10 GB instalado y el instalador otros 5).
   - Shared Directory: elige `~/FPGA4U_HelloWorld` (lo montaremos en la VM).
4. Antes de arrancar, en la configuración de la VM:
   - **Input → USB Sharing**: activado, **USB Support: USB 2.0** (la placa es USB 2.0).
   - **Sharing → Directory Share Mode: VirtFS**.
5. Arranca e instala Ubuntu Server con las opciones por defecto. Marca **Install OpenSSH server**.
   Con la emulación la instalación tarda un buen rato.
6. Al terminar, quita la ISO (icono del CD → Eject) y reinicia.

Consejo: es más cómodo trabajar por SSH desde el Terminal del Mac. Mira la IP con `ip a` dentro
de la VM y luego, desde el Mac: `ssh usuario@IP_DE_LA_VM`.

## 2. Preparar Ubuntu para Quartus 13

Dentro de la VM:

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y libc6:i386 libncurses5:i386 libstdc++6:i386 libxext6:i386 \
    libxft2:i386 libxtst6:i386 libzstd1:i386 lib32z1 libncurses5 libxft2 libxtst6 \
    libsm6 libxrender1 libfontconfig1 make
```

Montar la carpeta compartida con el Mac:

```bash
sudo mkdir -p /mnt/fpga
echo 'share /mnt/fpga 9p trans=virtio,version=9p2000.L,rw,_netdev,nofail 0 0' | sudo tee -a /etc/fstab
sudo mount -a
ls /mnt/fpga   # aquí deberías ver hello_fpga4u.v, build.sh, ...
```

Si el montaje da problemas de permisos, puedes copiar la carpeta por SSH desde el Mac:
`scp -r ~/FPGA4U_HelloWorld usuario@IP_DE_LA_VM:~/`

## 3. Instalar Quartus II 13.0 SP1 Web Edition (gratis)

1. En el Mac, entra en el Download Center de Intel FPGA: https://www.intel.com/content/www/us/en/collections/products/fpga/software/downloads.html
   → **Quartus II Web Edition → 13.0sp1 → Linux**.
   Descarga el fichero combinado **`Quartus-web-13.0.1.232-linux.tar`** (unos 4,5 GB, pide cuenta de Intel).
   Ya incluye los ficheros de la familia Cyclone II.
2. Pásalo a la VM, por ejemplo dejándolo en `~/FPGA4U_HelloWorld` (que es la carpeta compartida) o con `scp`.
3. En la VM:

```bash
mkdir ~/quartus-setup && cd ~/quartus-setup
tar xf /mnt/fpga/Quartus-web-13.0.1.232-linux.tar
./setup.sh
```

   Instala en `~/altera/13.0sp1` y selecciona al menos **Quartus II Web Edition** y
   **Cyclone II/III/IV**. Si el instalador se queja de que no hay pantalla, mira `./setup.sh --help`
   para ver la opción de modo texto.

4. Añade Quartus al PATH:

```bash
cat >> ~/.bashrc <<'EOF'
export QUARTUS_ROOTDIR=$HOME/altera/13.0sp1/quartus
export PATH=$QUARTUS_ROOTDIR/bin:$PATH
export QUARTUS_64BIT=1
EOF
source ~/.bashrc
quartus_sh --version
```

5. Permiso para que un usuario normal acceda al USB-Blaster:

```bash
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666"' \
  | sudo tee /etc/udev/rules.d/51-usbblaster.rules
sudo udevadm control --reload-rules
```

## 4. Compilar

```bash
cd /mnt/fpga
./build.sh
```

Con la emulación puede tardar varios minutos. Si todo va bien tendrás en `output_files/`:

- `hello_fpga4u.sof`: carga directa en la FPGA (se pierde al apagar).
- `hello_fpga4u.svf`: lo mismo, en formato estándar para OpenOCD.
- `hello_fpga4u.jic`: imagen para grabar la flash EPCS16 (permanente).

## 5. Programar la placa

### Opción A: desde la VM

1. Conecta la placa al Mac (con un adaptador USB-C si hace falta).
2. En la barra de UTM pulsa el icono **USB** y elige el dispositivo **USB-Blaster / Altera**.
3. En la VM:

```bash
cd /mnt/fpga
./program_vm.sh          # carga en la FPGA
./program_vm.sh flash    # o graba la flash para que arranque sola
```

`jtagconfig` tiene que mostrar algo como `USB-Blaster [...] 020B30DD EP2C15/20`. Si no aparece:
`sudo killall jtagd; jtagconfig`.

### Opción B: desde macOS con OpenOCD (sin pasar el USB a la VM)

Útil si el paso de USB en la emulación da problemas. **Experimental**: no está probado con esta placa.

```bash
brew install openocd
cd ~/FPGA4U_HelloWorld
./program_mac.sh
```

Si OpenOCD no encuentra el adaptador o el ID no coincide, el mensaje de error dirá qué IDCODE ve;
ajusta `-expected-id` en `program_mac.sh`.

## Problemas típicos

- **`jtagconfig` dice "No JTAG hardware available"**: la placa no está pasada a la VM (menú USB de UTM),
  o falta la regla udev. Prueba `lsusb | grep 09fb`.
- **El diseño carga pero no se ve nada**: revisa que el modelo del chip (C8/C6) sea el correcto,
  pulsa SW7 (reset) y comprueba que SW5 no esté pulsado (la luz se para).
- **Al quitar la alimentación se borra**: normal con `.sof`/`.svf`. Para que sea permanente usa `./program_vm.sh flash`.
- **Quartus da errores de librerías al arrancar**: el mensaje dice qué `.so` falta. Instala la versión
  `:i386` de ese paquete con `apt`.
