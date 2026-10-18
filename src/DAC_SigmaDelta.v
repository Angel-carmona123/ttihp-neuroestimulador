`default_nettype none

 
module DAC_SigmaDelta #(
    parameter N = 10                      //Ancho de la muestra de entrada
)(
    input  wire         clk,
    input  wire         reset,
    input  wire [N-1:0] muestra,
    
    output wire         bitstream
);
 
    //N bits para la suma mas uno para el acarreo, que es el bitstream
    reg [N:0] acumulador;
 
    always @(posedge clk or negedge reset) begin
        if (!reset)
            acumulador <= {(N+1){1'b0}};
        else
            //Descartamos el acarreo anterior y sumamos la muestra
            acumulador <= {1'b0, acumulador[N-1:0]} + {1'b0, muestra};
    end
 
    assign bitstream = acumulador[N];
 
endmodule

`default_nettype wire