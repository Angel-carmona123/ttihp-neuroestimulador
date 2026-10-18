`default_nettype none

`timescale 1ns / 1ps

module ASIC_Top(
    input  wire [7:0] ui_in,   //Pines de entrada dedicados
    input  wire       ena,     //Señal de Enable general (la ignoramos, siempre a 1)
    input  wire       clk,     //Reloj global (Relojo fisico del chip)
    input  wire       rst_n,   //Reset global (Activo a nivel bajo)
    input  wire [7:0] uio_in,  //Pines bidireccionales: Camino de entrada
    
    output wire [7:0] uo_out,  //Pines de salida dedicados
    output wire [7:0] uio_out, //Pines bidireccionales que usaremos para la amplitud
    output wire [7:0] uio_oe   //Pines bidireccionales
    );


    //Empezamos a asignar pines de la placa a lo que necesitamos despues
    
    wire rx_in = ui_in[0];

    //Definimos las salidas de cada modulo
    
    //Salidas del Demodulador
    wire rx_limpio;
    wire rx_valid;
    
    //Salidas del Always_On_Domain
    wire sys_enable;
    
    //Salidas del Alamcena Mensaje
    wire [7:0] addr_wr;
    wire [7:0] byte_entrada;
    wire wr_enable_sram;
    wire rx_error;
    wire rx_completo;
    
    //Salidas de la FSM Principal
    wire [7:0] addr_rd;
    wire estimular;
    wire enable_always_on;
    wire [7:0] letra_amplitud;
    wire [2:0] repeticiones;
    wire rearme;
    
    //Salidas de la memoria SRAM - Aún por instanciar
    wire [7:0] dato_leido;

    //Salidas del Estimulador
    wire [7:0] valor_amplitud;
    wire polaridad;
    wire final_estimulacion;

    //Como la memoria solo tiene una entrada de dirección, decidimos
    //quién tiene el control basándonos en si ya recibimos el mensaje o no.

    wire [7:0] sram_addr; // A_ADDR
    wire       sram_wen;  // A_WEN (Write Enable)
    wire       sram_ren;  // A_REN (Read Enable)

    //Para el transmisor

    wire       enable_transmisor;
    wire [7:0] byte_a_transmitir;
    wire       tx_out;
    wire       otro_byte;

    wire [9:0] muestra;

    //Cable necesario para el DAC
    wire dac_bitstream;

    //Control de direccion, para la FSM si rx_completo=1, es decir leo, almacen si rx_completo=0, es decir que escribo
    assign sram_addr = (rx_completo) ? addr_rd : addr_wr;
    
    //Control de escritura, lo desactivamos poniendolo a 0 si rx_completo=1, usa wr_enable_sram si rx_completo=0
    assign sram_wen  = (rx_completo) ? 1'b0 : wr_enable_sram;
    
    //Control de lectura lo mismo, activamos, que es ponerlo a 1 si rx_completo=1, desactivamos (0) si rx_completo=0
    assign sram_ren  = (rx_completo) ? 1'b1 : 1'b0;

//DEFINICIÓN DE LAS INSTANCIAS

Demodulador_FSK
demodulador(
    //Inputs
    .clk(clk),
    .reset(rst_n),
    .rx_in_antena(rx_in),
    ///Outputs
    .rx_valid(rx_valid),
    .rx_limpio(rx_limpio)
);
    

Always_On_Domain
Always_Domain(
    //Inputs
    .clk_lento(clk),
    .reset(rst_n),
    .rx_in(rx_limpio),
    .rx_valid(rx_valid),
    .rearme(rearme),
    //Outputs
    .sys_enable(sys_enable)
);
    

Almacen_Mensaje
Almacen(
    //Inputs
    .clk(clk),
    .reset(rst_n),
    .enable(sys_enable),
    .rx(rx_limpio),
    .rx_valid(rx_valid),
    .rearme(rearme),
    //Output
    .addr_wr(addr_wr),
    .byte_entrada(byte_entrada),
    .wr_enable_sram(wr_enable_sram),
    .rx_error(rx_error),
    .rx_completo(rx_completo)
);


FSM_Principal
FSM(
    //Inputs
    .clk(clk),
    .reset(rst_n),
    .rx_completo(rx_completo),
    .rx_error(rx_error),
    .dato_leido(dato_leido),
    .otro_byte_transmitir(otro_byte),
    //Outputs
    .addr_rd(addr_rd),
    .estimular(estimular),
    .enable_always_on_domain(enable_always_on),
    .letra_amplitud(letra_amplitud),
    .repeticiones(repeticiones),
    .rearme(rearme),
    .enable_transmisor(enable_transmisor),
    .byte_a_transmitir(byte_a_transmitir)
);   

    
ESTIMULA
Estimula(
    //Inputs
    .clk(clk),
    .reset(rst_n),
    .enable_estimulacion(estimular),
    .letra_amplitud(letra_amplitud),
    .repeticiones(repeticiones),
    //Outputs
    .valor_amplitud(valor_amplitud),
    .polaridad(polaridad),
    .final_estimulacion(final_estimulacion)
);


DAC_SigmaDelta
DAC(
    //Inputs
    .clk(clk),
    .reset(rst_n),
    .muestra(muestra),
    //Outputs
    .bitstream(dac_bitstream)
);

Transmisor
Transmisor(
    //Inputs
    .clk(clk),
    .reset(rst_n),
    .enable(enable_transmisor),
    .byte_in(byte_a_transmitir),
    //Outputs
    .tx_out(tx_out),
    .otro_byte(otro_byte)
);

Mezclador
Mezclador(
    //Inputs
    .clk(clk),
    .reset(rst_n),
    .valor_amplitud(valor_amplitud),     
    .polaridad(polaridad),          
    .tx_out(tx_out),             
    .tx_activo(enable_transmisor),          
    //Outputs
    .muestra_dac(muestra)         
);
 



RM_IHPSG13_1P_256x8_c3_bm_bist 
SRAM_IHP(
    .A_CLK(clk),          
    .A_MEN(1'b1),          //Memory Enable (siempre encendida)
    .A_WEN(sram_wen),      //Write Enable desde nuestro MUX
    .A_REN(sram_ren),      //Read Enable desde nuestro MUX
    .A_ADDR(sram_addr),    //Dirección desde nuestro MUX
    .A_DIN(byte_entrada),  //Datos desde el Almacén
    .A_DLY(1'b0),          //Delay 
    .A_DOUT(dato_leido),   //Datos hacia la FSM
    .A_BM(8'hFF),          //Bit Mask (8'hFF = no enmascarar)
        
    //Pines de BIST (Desactivados)
    .A_BIST_CLK(1'b0),
    .A_BIST_EN(1'b0),
    .A_BIST_MEN(1'b0),
    .A_BIST_WEN(1'b0),
    .A_BIST_REN(1'b0),
    .A_BIST_ADDR(8'd0),
    .A_BIST_DIN(8'd0),
    .A_BIST_BM(8'd0)
);

    //Asignamos por ultimo los pones físicos
    assign uo_out[0] = polaridad;        //Salida hacia el circuito analógico
    assign uo_out[1] = sys_enable;       //Podemos comprobar con estosi se despertó
    assign uo_out[2] = rx_valid;         //Podemos medir los pulsos del demodulador
    assign uo_out[3] = rx_completo;      //Podemos ver si leyó bien el mensaje
    assign uo_out[4] = dac_bitstream;    //Lo ponemos para poder ver la salida del dac
    assign uo_out[5] = tx_out;
    assign uo_out[7:6] = 2'b00;        //OBLIGATORIO: Los pines que no usemos los ponesmos a 0

    //Pines Bidireccionales
    assign uio_out = valor_amplitud;     //Como estamos usando ya varios pines de salida para otra cosa, dejamos esto para el valor de la amplitud
    
    //Configuramos el puerto bidireccional (0 = Entrada, 1 = Salida)
    assign uio_oe  = 8'hFF;              //Todo el bus uio configurado como salida para la estimulacion(11111111)



endmodule

`default_nettype wire