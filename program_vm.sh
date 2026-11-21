#!/usr/bin/env bash
# Programa la FPGA desde la VM (la placa tiene que estar pasada a la VM por USB).
#   ./program_vm.sh         -> carga el .sof en la FPGA (se pierde al apagar)
#   ./program_vm.sh flash   -> graba la flash EPCS16 (permanente)
set -euo pipefail
cd "$(dirname "$0")"

jtagconfig   # debe mostrar: 1) USB-Blaster [...]  020B30DD  EP2C15/20

if [[ "${1:-}" == "flash" ]]; then
    quartus_pgm -c USB-Blaster -m JTAG -o "p;output_files/hello_fpga4u.jic"
    echo "Flash grabada. Pulsa SW8 (Init) o desenchufa y enchufa la placa."
else
    quartus_pgm -c USB-Blaster -m JTAG -o "p;output_files/hello_fpga4u.sof"
fi
