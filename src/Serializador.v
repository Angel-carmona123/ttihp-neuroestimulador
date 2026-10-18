`default_nettype none

`timescale 1ns / 1ps

module Serializador(
    input wire clk,
    input wire enable,
    input wire reset,
    input wire [7:0] byte_entrada,
    input wire siguiente_bit,

    output reg otro_byte,
    output reg bit_salida
);

    reg [2:0] cont;
    reg [7:0] byte_auxiliar;

    reg [2:0] estados;

    localparam Sync_Word = 3'd0;
    localparam Datos = 3'd1;
    
    reg [15:0] SW;

    reg [3:0] cont_sw;


    always @(posedge clk or negedge reset)begin
        if(!reset)begin
            bit_salida <= 1'b0;
            cont <= 3'd0;
            otro_byte <= 1'b0;
            byte_auxiliar <= 8'd0;
            estados <= Sync_Word;
            SW <= 16'b1010101010101010;
            cont_sw <= 4'd0;
        end

        else if(enable) begin

            otro_byte <= 1'b0;

            case (estados)
                Sync_Word: begin
                    if(siguiente_bit)begin   

                        cont_sw <= cont_sw + 4'd1;
                        bit_salida <= SW[15];
                        SW <= {SW[14:0],1'b0};

                        if(cont_sw == 4'd15)begin
                            byte_auxiliar <= byte_entrada;
                            estados <= Datos;
                            otro_byte <= 1'b1;
                        end

                    end
                end

                Datos: begin
                    if(siguiente_bit)begin   

                        cont <= cont + 3'd1;
                        bit_salida <= byte_auxiliar[7];
                        byte_auxiliar <= {byte_auxiliar[6:0],1'b0};

                        if(cont == 7)begin
                            otro_byte <= 1'b1;
                            cont <= 3'd0;
                            byte_auxiliar <= byte_entrada;
                        end

                        end
                end

            endcase
            

        end

        else begin
            bit_salida <= 1'b0;
            cont <= 3'd0;
            otro_byte <= 1'b0;
            byte_auxiliar <= 8'd0;
            estados <= Sync_Word;
            SW <= 16'b1010101010101010;
            cont_sw <= 4'd0;
        end

    end



endmodule

`default_nettype wire