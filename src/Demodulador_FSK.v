`default_nettype none



module Demodulador_FSK #(

    //Definimos estos parámetros como configurables en el Top_Module por si despues 
    //Queremos demodular a diferentes frecuencias, pues puede ser que vengan a diferentes frecuencias
    //desde diferentes neuros
    
    parameter freq_reloj = 10_000_000, // Reloj del sistema (10 MHz)
    parameter freq_0     = 125_000, // Frecuencia para el bit '0' (125 kHz)
    parameter freq_1     = 250_000  // Frecuencia para el bit '1' (250 kHz)
    
)
(
    input wire clk,   
    input wire reset,
    input wire rx_in_antena,  // La onda cuadrada ruidosa que viene del comparador analógico

    output reg rx_limpio,      // El bit digital puro (0 o 1) que irá a tu Always_On_Domain
    output reg rx_valid
);

    // Calculamos cuantos ciclos de reloj caben dentro de cada frecuencia
    
    localparam ciclos_f0 = freq_reloj / freq_0; //Darian unos 80 ciclos
    localparam ciclos_f1 = freq_reloj / freq_1; //Darian unos 40 ciclos
    
    //Calculamos un umbral desde el cual poder decidir si al ver llegar las ondas se queda por 
    //abajo o por el contrario se queda por arriba de esa media y de esa manera ver si es un
    //0 o un 1 lo que me estan mandando
    
    localparam [7:0] media_ciclos = (ciclos_f0 + ciclos_f1) / 2; //La media de los dos es de unos 60 ciclos

    //Para intentar solucionar el problema de la estabilidad entre la antena y el reloj interno
    //del ASIC vamos a poner dos registros que me van a guardar los datos en diferentes tiempos
    //primero lo que llega en sync_1 y este despues en sync_2, y de esta forma me soluciono que no se me
    //solapen los eventos
    
    reg sync_1;
    reg sync_2;
    reg anterior;

    //Ponemos un contador que nos permita llegar hasta los 8 bits
    
    reg [7:0] contador_periodo;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
        
            sync_1 <= 1'b0;
            sync_2 <= 1'b0;
            anterior <= 1'b0;
            contador_periodo <= 8'd0;
            rx_limpio <= 1'b0;
            rx_valid <= 1'b0;
            
        end 
        else begin

            sync_1 <= rx_in_antena;
            sync_2 <= sync_1;
            anterior <= sync_2;

            //Como tenemos un registro de memoria, debemos de comparar cuando es que la onda
            //completa una subida, y de esa manera, poder ver cuantos ciclos de reloj han pasado
            //si mas cercano al valor lento o mas cercano a un valor rapido
            
            if (sync_2 == 1'b1 && anterior == 1'b0) begin
                
                //Analizamos como ha quedado el contador de los periodos con respecto a la media
                
                if (contador_periodo > media_ciclos) begin
                
                    rx_limpio <= 1'b0; // Onda lenta -> Es un 0
                    
                end 
                else begin
                
                    rx_limpio <= 1'b1; // Onda rápida -> Es un 1
                    
                end
                
                // Acabamos de decidir si es un 0 o un 1. Levantamos la bandera para avisar.
                rx_valid <= 1'b1;
                //Reseteamos el contador y empezamos a analizar un nuevo dato
                
                contador_periodo <= 8'd0;
                
            end 
            else begin
            
                //Apagamos el rx_valid para asi poder diferenciar los bits correctos
                rx_valid <= 1'b0;
                
                //Actualizamos el contador
                
                if (contador_periodo < 8'd255) begin
                    contador_periodo <= contador_periodo + 8'd1;
                end
            end
        end
    end

endmodule

`default_nettype wire