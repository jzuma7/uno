module verificador (
    input [5:0] carta_jogada,
    input [5:0] carta_topo,
    output wire result
);

// 0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111
//  0     1    2    3    4    5    6    7    8    9   +2  rvrs blck wild wild+4
localparam [3:0] carta_wild = 4'b1101;
localparam [3:0] carta_wild4 = 4'b1110;

wire mesma_cor = carta_jogada[5:4] == carta_topo[5:4];
wire mesmo_tipo = carta_jogada[3:0] == carta_topo[3:0];
wire eh_wild = carta_jogada[3:0] == carta_wild || carta_jogada[3:0] == carta_wild4;

assign result = mesma_cor || mesmo_tipo || eh_wild;
endmodule
