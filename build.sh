#!/usr/bin/env bash
# Compila el proyecto y genera los ficheros de programación.
# Ejecutar DENTRO de la VM Linux con Quartus II 13.0 SP1 en el PATH.
set -euo pipefail
cd "$(dirname "$0")"

quartus_sh --flow compile hello_fpga4u

# .svf: para programar desde macOS con OpenOCD (program_mac.sh)
quartus_cpf -c -q 6.0MHz -g 3.3 -n p \
    output_files/hello_fpga4u.sof output_files/hello_fpga4u.svf

# .jic: para grabar la flash EPCS16 y que el diseño arranque solo al enchufar
quartus_cpf -c -d EPCS16 -s EP2C20 \
    output_files/hello_fpga4u.sof output_files/hello_fpga4u.jic

echo
echo "OK. Ficheros en output_files/: hello_fpga4u.sof, .svf, .jic"
