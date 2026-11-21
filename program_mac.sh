#!/usr/bin/env bash
# Programa la FPGA directamente desde macOS con OpenOCD (brew install openocd),
# usando el .svf generado en la VM. EXPERIMENTAL: no probado con esta placa.
set -euo pipefail
cd "$(dirname "$0")"

openocd \
    -f interface/altera-usb-blaster.cfg \
    -c "adapter speed 1000" \
    -c "jtag newtap ep2c20 tap -irlen 10 -expected-id 0x020b30dd" \
    -c "init" \
    -c "svf -tap ep2c20 -progress output_files/hello_fpga4u.svf" \
    -c "shutdown"
