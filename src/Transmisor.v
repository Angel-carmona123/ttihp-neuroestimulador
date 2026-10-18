`default_nettype none

`timescale 1ns / 1ps

module Transmisor(
    input wire clk,
    input wire enable,
    input wire reset,
    input wire [7:0] byte_in,

    output wire tx_out,
    output wire otro_byte
);
    //Declaramos las varibales auxiliares que necesitamos para unir ambos modulos

    wire siguiente_bit;
    wire bit_dato;

    //Instanciamos en este modulo tanto el serializador que toma los bytes como el modulador que saca los datos.

    Serializador
    Serializador(
        .clk(clk),
        .enable(enable),
        .reset(reset),
        .byte_entrada(byte_in),
        .siguiente_bit(siguiente_bit),

        .otro_byte(otro_byte),
        .bit_salida(bit_dato)

    );


    Modulador_FSK
    Modulador_FSK(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .bit_in(bit_dato),

        .siguiente_bit(siguiente_bit),
        .tx_out(tx_out)
    );


endmodule

`default_nettype wire