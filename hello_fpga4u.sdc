# Oscilador de 24 MHz
create_clock -name clk24 -period 41.667 [get_ports clk]
derive_clock_uncertainty
# Entradas asíncronas (botones y reset): sin restricciones de tiempo
set_false_path -from [get_ports {button_n[*] rst_n}]
set_false_path -to [get_ports {led_button[*] led[*]}]
