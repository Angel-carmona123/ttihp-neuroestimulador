`default_nettype none

`timescale 1ns / 1ps

module ESTIMULA(
    input wire clk,
    input wire reset,
    input wire enable_estimulacion,
    input wire [7:0] letra_amplitud,
    input wire [2:0] repeticiones,
    
    output reg [7:0] valor_amplitud,
    output reg polaridad,
    output reg final_estimulacion
);
    //Definimos todos los estados por los que va a pasar la onda bifasica para hacer su forma
    reg [2:0] Estados;
    localparam Reposo     = 3'd0;
    localparam Positiva   = 3'd1;
    localparam Cero_Medio = 3'd2;
    localparam Negativa   = 3'd3;
    localparam Cero_final = 3'd4;

    reg [11:0] contador; 

    //Definimos los tiempos de cada uno de esos estados
    localparam tiempo_4ms = 12'd4000;
    localparam tiempo_1ms = 12'd1000;

    reg [7:0] amplitud_real;
    reg [2:0] repeticiones_internas;
    reg [7:0] amplitud_fija;
    reg [2:0] repeticiones_fijas;
    always @(*) begin
        //Vamos a diferenciar la amplitud que vamos a sacar a la salida por una serie de letras que le vamos a enviar en la entrada
        case(letra_amplitud)
            8'h41: amplitud_real = 8'd40;  //'A'
            8'h42: amplitud_real = 8'd80;  //'B'
            8'h43: amplitud_real = 8'd100; //'C'
            8'h44: amplitud_real = 8'd150; //'D'
            8'h45: amplitud_real = 8'd200; //'E'
            default: amplitud_real = 8'd0;
        endcase
    end

    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            Estados <= Reposo;
            contador <= 12'd0;
            valor_amplitud <= 8'd0;
            polaridad <= 1'b1;
            final_estimulacion <= 1'b0;
            repeticiones_internas <= 3'd0;
        end
        else begin
            case(Estados)
                //ponemos todos los estados y como tienen que estar los diferentes amplitudes y la polaridad
                Reposo: begin
                    final_estimulacion <= 1'b0;
                    valor_amplitud <= 8'd0;
                    contador <= 12'd0;
                    polaridad <= 1'b1;
                    repeticiones_internas <= 3'd0;
                    if(enable_estimulacion) begin
                        amplitud_fija <= amplitud_real;
                        repeticiones_fijas <= repeticiones;
                        Estados <= Positiva;
                    end 
                end
                
                Positiva: begin
                    valor_amplitud <= amplitud_fija;
                    polaridad <= 1'b1;
                    if(contador == (tiempo_4ms - 1)) begin
                        contador <= 12'd0;
                        Estados <= Cero_Medio;
                    end
                    else begin
                        contador <= contador + 12'd1;
                    end
                end
                
                Cero_Medio: begin
                    valor_amplitud <= 8'd0;
                    if(contador == (tiempo_1ms - 1)) begin
                        contador <= 12'd0;
                        Estados <= Negativa;
                    end
                    else begin
                        contador <= contador + 12'd1;
                    end
                end
                
                Negativa: begin
                    valor_amplitud <= amplitud_fija;
                    polaridad <= 1'b0;
                    if(contador == (tiempo_4ms - 1)) begin
                        contador <= 12'd0;
                        Estados <= Cero_final;
                    end
                    else begin
                        contador <= contador + 12'd1;
                    end
                end
                
                //en el ultimo cero debemos de confirmar que no hemos llegado a la repeticion final, en caso contrario, dejamos de estimular
                Cero_final: begin
                    valor_amplitud <= 8'd0;
                    if(contador == (tiempo_1ms - 1)) begin
                        contador <= 12'd0;
                        if(repeticiones_internas + 3'd1 == repeticiones) begin
                            final_estimulacion <= 1'b1;
                            Estados <= Reposo;      
                        end
                        else begin
                            repeticiones_internas <= repeticiones_internas + 3'd1;
                            Estados <= Positiva;
                        end        
                    end
                    else begin
                        contador <= contador + 12'd1;
                    end
                end
                default: Estados <= Reposo;
            endcase
        end
    end

endmodule

`default_nettype wire