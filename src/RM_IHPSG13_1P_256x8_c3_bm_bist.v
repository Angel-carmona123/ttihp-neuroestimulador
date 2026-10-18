// Caja negra del macro SRAM RM_IHPSG13_1P_256x8_c3_bm_bist (IHP SG13G2).
// Solo declara los puertos: Yosys no sintetiza su interior y LibreLane
// coloca en su lugar el macro físico (LEF/GDS de la carpeta macro/).
// Para simulación se usa el modelo de test/models/, nunca este archivo.

`default_nettype none

(* blackbox *)
module RM_IHPSG13_1P_256x8_c3_bm_bist (
    input  wire       A_CLK,
    input  wire       A_MEN,
    input  wire       A_WEN,
    input  wire       A_REN,
    input  wire [7:0] A_ADDR,
    input  wire [7:0] A_DIN,
    input  wire       A_DLY,
    output wire [7:0] A_DOUT,
    input  wire [7:0] A_BM,
    input  wire       A_BIST_CLK,
    input  wire       A_BIST_EN,
    input  wire       A_BIST_MEN,
    input  wire       A_BIST_WEN,
    input  wire       A_BIST_REN,
    input  wire [7:0] A_BIST_ADDR,
    input  wire [7:0] A_BIST_DIN,
    input  wire [7:0] A_BIST_BM
);

endmodule

`default_nettype wire