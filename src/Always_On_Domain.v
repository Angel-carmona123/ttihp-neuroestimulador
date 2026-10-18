`default_nettype none

`timescale 1ns / 1ps

//Bloque que va a estar siempre despierto escuchando el canal para identificar el Sync_Word 
//Una vez detectado, enciende el resto del ASIC

module Always_On_Domain(
    input wire clk_lento,   
    input wire reset,
    input wire rx_in,       //El pin que llega desde el demodulador
    input wire rx_valid,    
    input wire rearme,
    
    output reg sys_enable   //LSeñal de Salida que activa el resto del ASIC
);
    //Definimos el sync_word como AA en hexadecimal, que es un codigo complicado que salga de forma aleatoria
    
    localparam CLAVE_COMPLETA = 16'b10101010_10101010; 

    //El cable por el que van a ir entrando los datos es de 16 bits
    
    reg [15:0] shift_reg;

    always @(posedge clk_lento or negedge reset) begin
        if (!reset) begin
            shift_reg <= 16'b0;
            sys_enable <= 1'b0;
        end

        else if (rearme) begin
            shift_reg <= 16'b0;
            sys_enable <= 1'b0;
        end 
        
        else begin
        
            //Vamos Desplazando los 16 bits, soltamos el más viejo de la izquierda
            //Y metemos el nuevo por la derecha solo cuando rx_valid es uno
            if(rx_valid)begin   
                shift_reg <= {shift_reg[14:0], rx_in};

                //En cada pulso de reloj, preguntamos si los 16 bits que hay 
                //Ahora mismo en el canal son iguales a la contraseña fiajada.
            
                if ({shift_reg[14:0], rx_in} == CLAVE_COMPLETA) begin
                    sys_enable <= 1'b1; //Despertamos el ASIC
                end
            end
        end
    end
endmodule

`default_nettype wire