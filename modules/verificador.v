module verify (
    input [5:0] carta_jogada,
    input [5:0] carta_topo,
    output wire result
);

assign result = carta_jogada[5:4] == carta_topo[5:4] || carta_jogada[3:0] == carta_topo[3:0] || carta_jogada[3:0] == 4'b1101 || carta_jogada[3:0] == 4'b1110;
endmodule
