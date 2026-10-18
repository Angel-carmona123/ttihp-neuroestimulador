`default_nettype none

`timescale 1ns / 1ps


module FSM_Principal(
    input wire clk,
    input wire reset,
    input wire rx_completo,
    input wire rx_error,
    input wire [7:0] dato_leido,
    input wire otro_byte_transmitir,

    output reg [7:0] addr_rd,
    output reg estimular,
    output reg enable_always_on_domain,
    output reg [7:0] letra_amplitud,
    output reg [2:0] repeticiones,
    output reg enable_transmisor,
    output reg [7:0] byte_a_transmitir,
    output reg rearme
    );

    reg [1:0] estados;
    localparam Espera = 2'd0;
    localparam Lectura = 2'd1;
    localparam Transmitiendo = 2'd2;

    parameter [7:0] id_generica = 8'd3;
    parameter [7:0] broadcast = 8'd10;

    reg [7:0] DST;
    reg [7:0] SRC;
    reg [7:0] CMD;

    reg [7:0] mi_id;

    reg [2:0] addr_lect;
    reg espera_sram; 

    reg [2:0] cont_transmisor;

    localparam Estimula = 8'd0;
    localparam Comunica = 8'd1;
    localparam Cambia_ID = 8'd2;
    localparam Parada = 8'd3;
    localparam Respuesta_Activo = 8'd4;

    always@( posedge clk or negedge reset)begin
        if(!reset)begin
            estados <= Espera;
            addr_rd <= 8'd0;
            estimular <= 0;
            enable_always_on_domain <= 1'd1;
            SRC <= 8'd0;
            CMD <= 8'd0;
            DST <= 8'd0;
            letra_amplitud <= 8'd0;
            repeticiones <= 3'd0;
            addr_lect <= 3'd0;
            espera_sram <= 1'b0;
            mi_id <= id_generica;
            enable_transmisor <= 1'b0;
            cont_transmisor <= 3'd0;
            byte_a_transmitir <= 8'd0;
            rearme <= 1'b0;
        end
        else begin
            rearme <= 1'b0;
            case(estados)

                Espera: begin
                    estimular <= 1'd0;
                    enable_always_on_domain <= 1'd0;
                    addr_rd <= 8'd0;
                    addr_lect <= 3'd0;
                    espera_sram <= 1'b1;   //Al entrar en lectura, la dir 0 ya estara puesta; esperamos 1 ciclo

                    if(rx_completo && !rearme)begin
                        estados <= Lectura;
                    end
                    else if(rx_error && !rearme)begin
                        estados <= Espera;
                        rearme <= 1'b1;
                    end
                end

                Lectura: begin
                    enable_always_on_domain <= 1'd0;

                    if (espera_sram) begin
                        //Añadimos un ciclo de espera porque no le daba tiempo a la fsm de leer el dato y sacarlo de la SRAM. No capturamos nada todavia.
                        espera_sram <= 1'b0;
                    end
                    else begin
                        //Ahora dato_leido ya es valido para la addr_rd actual.
                        case(addr_lect)
                            3'd0: begin
                                DST <= dato_leido;      
                                addr_rd <= 8'd1;
                                addr_lect <= 3'd1;
                                espera_sram <= 1'b1;    //Cada vez que leemos, nos vamos a esperar un ciclo
                            end

                            3'd1: begin
                                SRC <= dato_leido;      
                                addr_rd <= 8'd2;
                                addr_lect <= 3'd2;
                                espera_sram <= 1'b1;    

                                if (DST != mi_id && DST != broadcast) begin //Comprobamos que el mensaje era para nosotros o para todos, sino, volvemos a espera.
                                    estados <= Espera;
                                    rearme <= 1'b1;
                                end

                            end

                            3'd2: begin
                                CMD <= dato_leido;      
                                addr_rd <= 8'd3;
                                addr_lect <= 3'd3;
                                espera_sram <= 1'b1; 
                            end

                            3'd3: begin
                                letra_amplitud <= dato_leido;
                                addr_rd <= 8'd4;
                                addr_lect <= 3'd4;
                                espera_sram <= 1'b1;
                            end

                            3'd4: begin
                                repeticiones <= dato_leido[2:0];
                                addr_rd <= 8'd5;
                                addr_lect <= 3'd5;
                                espera_sram <= 1'b1;
                            end

                            3'd5: begin
                                                           
                                case(CMD)
                                    Estimula: begin
                                        estimular <= 1'b1;
                                        estados <= Espera;
                                    end
                                    Comunica: begin
                                        byte_a_transmitir <= SRC;
                                        estados <= Transmitiendo;
                                    end
                                    Cambia_ID: begin
                                        if(SRC == 8'd0)begin
                                            mi_id <= letra_amplitud;
                                        end
                                        estados <= Espera;
                                        rearme <= 1'b1;
                                    end
                                    Parada: begin
                                        estados <= Espera;
                                        rearme <= 1'b1;
                                    end
                                    Respuesta_Activo: begin
                                        if(SRC == 8'd0)begin
                                            byte_a_transmitir <= SRC;
                                            estados <= Transmitiendo;
                                        end
                                        else begin
                                            estados <= Espera;
                                            rearme <= 1'b1;
                                        end    
                                    end
                                    default: begin
                                        estados <= Espera;  //Al final ponemos un estado de seguridad poniendo el espera para no quedarnos pillados
                                        rearme <= 1'b1;
                                    end
                                endcase
                            end
                        endcase
                    end
                end

                Transmitiendo: begin
                    enable_transmisor <= 1'b1;
                    if(otro_byte_transmitir)begin
                        cont_transmisor <= cont_transmisor + 3'd1;
                        case(cont_transmisor)
                            3'd0: begin
                                byte_a_transmitir <= DST;
                            end
                            3'd1: begin
                                byte_a_transmitir <= CMD;
                            end
                            3'd2: begin
                                byte_a_transmitir <= letra_amplitud;
                            end
                            3'd3: begin
                                byte_a_transmitir <= repeticiones;
                            end
                            3'd4: begin
                                byte_a_transmitir <= 8'h00; //Cola: empuja REP fuera del pipeline                                
                            end
                            3'd5: begin 
                                ;                           //Se ha quedado con la cola por lo que le damos un ciclo de espera
                            end
                            3'd6: begin
                            // Este pulso confirma que repeticiones ya salió entero.
                                enable_transmisor <= 1'b0;
                                cont_transmisor <= 3'd0;
                                estados <= Espera;
                            end
                        endcase                       
                    end                   
                end
            endcase
        end
    end


endmodule

`default_nettype wire