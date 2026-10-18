`default_nettype none



module Modulador_FSK #(
    parameter freq_reloj = 10_000_000,
    parameter freq_0     = 125_000,
    parameter freq_1     = 250_000
)(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire bit_in,

    output reg siguiente_bit,
    output reg tx_out
);

//definidas las mismas frecuencias que para la demodulacion, podemos definir los ciclos de cada una:

    localparam ciclos_0 = freq_reloj/freq_0;
    localparam ciclos_1 = freq_reloj/freq_1;
    localparam [7:0] semiciclos_0 = ciclos_0/2;
    localparam [7:0] semiciclos_1 = ciclos_1/2;

    reg [7:0] cont;
    reg [7:0] semi_ciclos;
    reg fase_actual;

    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            siguiente_bit <= 1'd0;
            cont <= 8'd0;
            tx_out <= 1'd0;
            semi_ciclos <= semiciclos_0;
            fase_actual <= 1'b1; //Corregido al mirar la grafica, porque cuando empezaba abajo cambiaba con las bajadas de tx_out, lo cual es lo contrario de la logica programada, queremos que cambie en las subidas. Como estaba antes, cuando habia un bit de transicion, hacia media onda en la frecuencia de 80 pulsos y media en la de 40, por lo que quedaba algo inservible de 60 pulsos
        end
        else if(enable) begin

            siguiente_bit <= 1'b0;

            if(cont >= semi_ciclos - 8'd1)begin

                tx_out <= ~tx_out;
                fase_actual <= ~fase_actual;
                cont <= 8'd0;

                if(fase_actual == 1)begin
                    semi_ciclos <= bit_in ? semiciclos_1 : semiciclos_0;
                    siguiente_bit <= 1'b1;
                end

            end
            else begin
                cont <= cont + 8'd1;
            end

        end
        else begin
            siguiente_bit <= 1'b0;
            cont          <= 8'd0;
            tx_out        <= 1'b0;          //La portadora siempre termina abajo
            semi_ciclos   <= semiciclos_0;
            fase_actual   <= 1'b1;          
        end
    end


endmodule   

`default_nettype wire