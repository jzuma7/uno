module display(
    input clock,
    input reg [5:0] top_card,
    input reg [5:0] player_card,
    input reg [6:0] n_player,
    input reg [6:0] n_cpu,
output reg [6:0] hex7,
output reg [6:0] hex6,
output reg [6:0] hex5,
output reg [6:0] hex4,
output reg [6:0] hex3,
output reg [6:0] hex2,
output reg [6:0] hex1,
output reg [6:0] hex0
);
reg[3:0] dezena_p;
reg[3:0] unidade_p;
reg[3:0] dezena_c;
reg[3:0] unidade_c;

wire [1:0] cor_top = top_card[5:4];
wire [3:0] n_top = top_card[3:0];
wire [1:0] cor_player = player_card[5:4];
wire [3:0] n_card_player = player_card[3:0];

always @(*)
    begin
    dezena_c = n_cpu/10;
    unidade_c = n_cpu%10;
    dezena_p = n_player/10;
    unidade_p = n_player%10;
    case (unidade_p) 
        4'd0: hex0  = 7'b1000000;
        4'd1: hex0 = 7'b1111001;
        4'd2: hex0 = 7'b0100100;
        4'd3: hex0 = 7'b0110000;
        4'd4: hex0 = 7'b0011001;
        4'd5: hex0 = 7'b0010010;
        4'd6: hex0 = 7'b0000010;
        4'd7: hex0 = 7'b1111000;
        4'd8: hex0 = 7'b0000000;
        4'd9: hex0 = 7'b0011000; 
        default: hex0 = 7'b1111111;
    endcase  case(dezena_p)
          4'd0: hex1  = 7'b1000000;
        4'd1: hex1 = 7'b1111001;
        4'd2: hex1 = 7'b0100100;
        4'd3: hex1 = 7'b0110000;
        4'd4: hex1 = 7'b0011001;
        4'd5: hex1 = 7'b0010010;
        4'd6: hex1 = 7'b0000010;
        4'd7: hex1 = 7'b1111000;
        4'd8: hex1 = 7'b0000000;
        4'd9: hex1 = 7'b0011000; 
        default: hex1 = 7'b1111111;
    endcase case(dezena_c)
          4'd0: hex7  = 7'b1000000;
        4'd1: hex7 = 7'b1111001;
        4'd2: hex7 = 7'b0100100;
        4'd3: hex7 = 7'b0110000;
        4'd4: hex7 = 7'b0011001;
        4'd5: hex7 = 7'b0010010;
        4'd6: hex7 = 7'b0000010;
        4'd7: hex7 = 7'b1111000;
        4'd8: hex7 = 7'b0000000;
        4'd9: hex7 = 7'b0011000; 
        default: hex7 = 7'b1111111;
    endcase case(unidade_c)
          4'd0: hex6  = 7'b1000000;
        4'd1: hex6 = 7'b1111001;
        4'd2: hex6 = 7'b0100100;
        4'd3: hex6 = 7'b0110000;
        4'd4: hex6 = 7'b0011001;
        4'd5: hex6 = 7'b0010010;
        4'd6: hex6 = 7'b0000010;
        4'd7: hex6 = 7'b1111000;
        4'd8: hex6 = 7'b0000000;
        4'd9: hex6 = 7'b0011000;
        default: hex6 = 7'b1111111;
    endcase case(n_top)
        4'd0: hex5  = 7'b1000000;
        4'd1: hex5 = 7'b1111001;
        4'd2: hex5 = 7'b0100100;
        4'd3: hex5 = 7'b0110000;
        4'd4: hex5 = 7'b0011001;
        4'd5: hex5 = 7'b0010010;
        4'd6: hex5 = 7'b0000010;
        4'd7: hex5 = 7'b1111000;
        4'd8: hex5 = 7'b0000000;
        4'd9: hex5 = 7'b0011000;
        4'd10: hex5 = 7'b0111111; // Skip (Traço no meio)
        4'd11: hex5 = 7'b0000111; // Reverse (Letra 't') T DE TURN
        4'd12: hex5 = 7'b0100001; // Draw Two (Letra 'd')
        4'd13: hex5 = 7'b0110110; // Wild (Três barras)
        4'd14: hex5 = 7'b0001110; // Wild Draw Four (Letra 'F')
        default: hex5 = 7'b1111111;
    endcase case(cor_top)
     // O zero será vermelho, o 1 será verde, o  2 será amarelo e o 3 será azul 
        2'd0: hex4: 7'b1001110;
        2'd1: hex4: 7'b0010000;
        2'd2: hex4: 7'b0010001;
        2'd3: hex4: 7'b0000011;
        default: hex4: 7'b1111111;
    endcase case(n_card_player)
         4'd0: hex3  = 7'b1000000;
        4'd1: hex3 = 7'b1111001;
        4'd2: hex3 = 7'b0100100;
        4'd3: hex3 = 7'b0110000;
        4'd4: hex3 = 7'b0011001;
        4'd5: hex3 = 7'b0010010;
        4'd6: hex3 = 7'b0000010;
        4'd7: hex3 = 7'b1111000;
        4'd8: hex3 = 7'b0000000;
        4'd9: hex3 = 7'b0010000;
        4'd10: hex3 = 7'b0111111; // Skip (Traço no meio)
        4'd11: hex3 = 7'b0000111; // Reverse (Letra 't')
        4'd12: hex3 = 7'b0100001; // Draw Two (Letra 'd')
        4'd13: hex3 = 7'b0110110; // Wild (Três barras)
        4'd14: hex3 = 7'b0001110; // Wild Draw Four (Letra 'F')
        default: hex3 = 7'b1111111;
    endcase case(cor_player)
        2'd0: hex2: 7'b1001110;
        2'd1: hex2: 7'b0010000;
        2'd2: hex2: 7'b0010001;
        2'd3: hex2: 7'b0000011;
        default: 7'b1111111;
    endcase



    end


endmodule
