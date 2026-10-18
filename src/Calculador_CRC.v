`default_nettype none


`timescale 1ns / 1ps


module Calculador_CRC(
    input wire clk,
    input wire reset,
    input wire enable, 
    input wire bit_entrada,
    input wire limpiar,
    
    output reg [7:0] resultado_CRC
    );
    
    //Declaramos los elementos necesarios para el juego de puertas XOR
    //Buscamos seguir la ecuacion de division g(x) = x^8 + x^2 + x + 1
    
    wire resto;
    assign resto = resultado_CRC[7] ^ bit_entrada;
    
    always@( posedge clk or negedge reset)begin
        if(!reset)begin
            resultado_CRC <= 8'd0;
        end
        else if(limpiar) begin
            resultado_CRC <= 8'd0;
        end
        else
        if (enable) begin   
            resultado_CRC[0] <= resto;
            resultado_CRC[1] <= resultado_CRC[0] ^ resto;
            resultado_CRC[2] <= resultado_CRC[1] ^ resto;
            resultado_CRC[3] <= resultado_CRC[2];
            resultado_CRC[4] <= resultado_CRC[3];
            resultado_CRC[5] <= resultado_CRC[4];
            resultado_CRC[6] <= resultado_CRC[5];
            resultado_CRC[7] <= resultado_CRC[6];
        end
    end
endmodule


`default_nettype wire