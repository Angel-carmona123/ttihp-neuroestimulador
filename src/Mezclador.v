`default_nettype none

`timescale 1ns / 1ps
 
module Mezclador 
#(
    parameter [7:0] A_TX = 8'd25          //Amplitud de la portadora FSK
)
(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] valor_amplitud,     //Magnitud de la bifasica (ESTIMULA)
    input  wire       polaridad,          //1 = fase positiva, 0 = fase negativa
    input  wire       tx_out,             //Portadora del transmisor
    input  wire       tx_activo,          //1 mientras el transmisor emite
 
    output reg  [9:0] muestra_dac         //Suma en binario desplazado (512 = cero)
);
 
    //Componente de estimulacion con signo (complemento a dos, 10 bits)
    wire [9:0] estimulo_pos = {2'b00, valor_amplitud};
    wire [9:0] estimulo     = polaridad ? estimulo_pos : (~estimulo_pos + 10'd1);
 
    //Componente de portadora: +A, -A o 0
    wire [9:0] portadora_pos = {2'b00, A_TX};
    wire [9:0] portadora     = !tx_activo ? 10'd0 : tx_out ? portadora_pos : (~portadora_pos + 10'd1);
 
    //Suma en complemento a dos: maximo |255 + 255| = 510 < 512, nunca desborda
    wire [9:0] suma = estimulo + portadora;
 
    //Paso a binario desplazado: sumar 512 equivale a invertir el bit de signo
    always @(posedge clk or negedge reset) begin
        if (!reset)
            muestra_dac <= 10'd512;
        else
            muestra_dac <= {~suma[9], suma[8:0]};
    end
    
 
endmodule

`default_nettype wire