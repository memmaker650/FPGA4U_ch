// -----------------------------------------------------------------------------
// Hello World para la placa FPGA4U (EPFL) - Altera Cyclone II EP2C20F484
//
//  - Los 4 LEDs de los pulsadores (amarillo, verde, naranja, rojo) cuentan
//    en binario, más o menos 1,4 veces por segundo.
//  - La matriz de 96 LEDs muestra una luz que recorre los 96 LEDs (un solo
//    LED encendido cada vez, para no pedir mucha corriente al USB).
//  - SW6 (Button_n[0]) mantenido pulsado: la luz cambia de sentido.
//  - SW5 (Button_n[1]) mantenido pulsado: la luz se detiene.
//  - SW4..SW3: al pulsarlos se enciende su LED (prueba de los botones).
//  - SW7 (Rz): reset del diseño.
//
// Reloj: oscilador de 24 MHz (Clk0, PIN_L1).
// Botones: activos a nivel bajo ('0' al pulsar). LEDs: activos a nivel alto.
// -----------------------------------------------------------------------------
module hello_fpga4u (
    input  wire        clk,          // 24 MHz
    input  wire        rst_n,        // SW7 (Rz), activo a nivel bajo
    input  wire [3:0]  button_n,     // SW3..SW6, activos a nivel bajo
    output wire [3:0]  led_button,   // LEDs junto a los pulsadores
    output wire [95:0] led           // matriz de 96 LEDs
);

    // --- Sincronización del reset y de los botones (señales asíncronas) ---
    reg [1:0] rst_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rst_sync <= 2'b00;
        else        rst_sync <= {rst_sync[0], 1'b1};
    end
    wire rst = ~rst_sync[1];

    reg [3:0] btn_meta, btn;   // btn = 1 cuando el botón está pulsado
    always @(posedge clk) begin
        btn_meta <= ~button_n;
        btn      <= btn_meta;
    end

    // --- Divisor de frecuencia ---
    // 24 MHz / 2^21 = ~11,4 Hz  -> paso de la luz que recorre la matriz
    // 24 MHz / 2^24 = ~1,43 Hz  -> contador binario de los 4 LEDs
    reg [23:0] div;
    always @(posedge clk) begin
        if (rst) div <= 24'd0;
        else     div <= div + 24'd1;
    end
    wire tick_fast = (div[20:0] == 21'h1FFFFF);
    wire tick_slow = (div == 24'hFFFFFF);

    // --- Contador binario en los LEDs de los pulsadores ---
    reg [3:0] count;
    always @(posedge clk) begin
        if (rst)            count <= 4'd0;
        else if (tick_slow) count <= count + 4'd1;
    end
    // El LED de un botón pulsado se enciende siempre.
    assign led_button = count | btn;

    // --- Luz que recorre la matriz de 96 LEDs ---
    reg [6:0] pos;   // 0..95
    always @(posedge clk) begin
        if (rst) begin
            pos <= 7'd0;
        end else if (tick_fast && !btn[1]) begin
            if (!btn[0]) pos <= (pos == 7'd95) ? 7'd0  : pos + 7'd1;
            else         pos <= (pos == 7'd0)  ? 7'd95 : pos - 7'd1;
        end
    end
    assign led = 96'd1 << pos;

endmodule
