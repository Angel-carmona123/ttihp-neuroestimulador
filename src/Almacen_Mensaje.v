`default_nettype none

`timescale 1ns / 1ps


module Almacen_Mensaje(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire rx, //Pin que le llega del demodulador
    input wire rx_valid,
    input wire rearme,
    
    output reg [7:0] addr_wr, //Recordar que trabajamos con 256 direcciones de almacenamiento
    output reg [7:0] byte_entrada, //Vamos a ir guardando de byte en byte
    output reg wr_enable_sram,
    output reg rx_error, //Si el CRC falla, sacamos un valor fuera que lo diga
    output reg rx_completo //Avisamos al exterior de que la señal esta completa
    );
    
    //Declaramos las variables que vamos a necesitar
    
    reg [2:0] contador_bits;
    reg [7:0] registro_byte;
    reg [7:0] longitud_onda;
    reg byte_listo;
    
    //Recordar que tal como tenemos ahora definido el problema vamos a tener:
    //addr 0: DST (El destino al que queriamos que llegara)
    //addr 1: SRC (Origen del destino)
    //addr 2: CMD (Comando)
    //addr 3: LTR /Letra de la amplitud que va a tener la onda)
    //addr 4: REP (Numero de veces que se quiere repetir la trama)


    localparam [7:0] n_bytes_uso = 8'd5;
    localparam [7:0] ultima_dir = n_bytes_uso - 8'd1;




    //Proponemos una mini maquina de estados que recorra el proceso de rellenar la memoria y dejar congelado el programa al final
    
    reg [1:0] estado;
    localparam Recibiendo = 2'd0;
    localparam Esperando = 2'd1;
    localparam Terminado = 2'd2;
    
    
    //Instanciamos dentro el modulo del CRC
    reg enable_CRC;
    wire [7:0] CRC_calculado;
    wire crc_activo = enable && (estado == Recibiendo) && rx_valid;
    
    Calculador_CRC
    Calculador_CRC(
        .clk(clk),
        .reset(reset),
        .enable(crc_activo), //Hemos tenido que cambiar como le llega el enable al CRC pues iba un ciclo tarde y lo calculaba mal, por eso hemos puesto un WIRE combinacional arriba que nos lo calcule directo, no con un <=
        .bit_entrada(rx),
        .limpiar(rearme),
        
        .resultado_CRC(CRC_calculado)
    );
    
    
    always@( posedge clk or negedge reset)begin
        if(!reset)begin
            contador_bits <= 3'd0;
            registro_byte <= 8'd0;
            byte_entrada <= 8'd0;
            longitud_onda <= 8'd0; 
            addr_wr <= 8'd0;
            wr_enable_sram <= 1'd0;
            rx_completo <= 1'd0;
            enable_CRC <= 1'd0;
            rx_error <= 1'd0;
            byte_listo <= 1'b0;
            
            estado <= Recibiendo;
        end

        else if(rearme) begin
            contador_bits <= 3'd0;
            registro_byte <= 8'd0;
            addr_wr <= 8'd0;
            wr_enable_sram <= 1'd0;
            rx_completo <= 1'd0;
            rx_error <= 1'd0;
            byte_listo <= 1'b0;
            estado <= Recibiendo;
        end
        
         //Estado donde mandamos la información a la SRAM
         
         else if(enable) begin

            if (rx_valid) begin
                registro_byte <= {registro_byte[6:0], rx};
                contador_bits <= contador_bits + 3'd1;
                
                if (contador_bits == 3'd7) begin
                    byte_entrada <= {registro_byte[6:0], rx}; //Sacamos el byte empaquetado
                    byte_listo <= 1'b1;                       //Levantamos la señal
                end 
                else begin
                    byte_listo <= 1'b0;
                end
            end 
            else begin
                //Si rx_valid es 0, bajamos la señal para que no dure más de 1 ciclo
                byte_listo <= 1'b0; 
            end

            wr_enable_sram <= 1'b0;
            
                case (estado)
                Recibiendo: begin
                    //Solo lo habilitamos en el ciclo exacto donde rx_valid es 1.
                    if (byte_listo) begin
                        wr_enable_sram <= 1'b1;

                        if (addr_wr == ultima_dir) begin
                            estado <= Esperando;
                        end
                    end
                    //Apuntamos a la siguiente dirección de memoria
                    else if (wr_enable_sram) begin
                    addr_wr <= addr_wr + 8'd1;
                    end
                end
                
                Esperando: begin
                    //En este estado solo esperamos a que llegue el ultimo byte
                    if (byte_listo) begin
                        if (CRC_calculado == byte_entrada) begin
                            rx_completo <= 1'b1;
                        end else begin
                            rx_error <= 1'b1;
                        end
                        estado <= Terminado;
                    end
                end
                
                Terminado: begin
                    //Acabamos el proceso, el sistema se queda congelado hasta un reset o apagado
                end
            endcase
            
        end
    end


endmodule

`default_nettype wire