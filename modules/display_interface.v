`include "../include/card_definitions.vh"

module display_interface(
  input [5:0] top_card,
  input [5:0] player_card,
  input [6:0] n_player,
  input [6:0] n_cpu,

  output [6:0] hex7,
  output [6:0] hex6,
  output [6:0] hex5,
  output [6:0] hex4,
  output [6:0] hex3,
  output [6:0] hex2,
  output [6:0] hex1,
  output [6:0] hex0
);

  reg [6:0] hex7_reg;
  reg [6:0] hex6_reg;
  reg [6:0] hex5_reg;
  reg [6:0] hex4_reg;
  reg [6:0] hex3_reg;
  reg [6:0] hex2_reg;
  reg [6:0] hex1_reg;
  reg [6:0] hex0_reg;

  assign hex7 = hex7_reg;
  assign hex6 = hex6_reg;
  assign hex5 = hex5_reg;
  assign hex4 = hex4_reg;
  assign hex3 = hex3_reg;
  assign hex2 = hex2_reg;
  assign hex1 = hex1_reg;
  assign hex0 = hex0_reg;

  reg [3:0] dezena_p;
  reg [3:0] unidade_p;
  reg [3:0] dezena_c;
  reg [3:0] unidade_c;

  wire [3:0] n_top = top_card[3:0];
  wire [1:0] cor_top = top_card[5:4];
  wire [1:0] cor_player = player_card[5:4];
  wire [3:0] n_card_player = player_card[3:0];

  always @(*) begin
    dezena_c = n_cpu / 10;
    unidade_c = n_cpu % 10;
    dezena_p = n_player / 10;
    unidade_p = n_player % 10;

    // HEX7 = cor de player_card
    case (cor_player)
      `COLOR_RED:    hex7_reg = 7'b1001110; // r
      `COLOR_GREEN:  hex7_reg = 7'b0010000; // g
      `COLOR_BLUE:   hex7_reg = 7'b0000011; // b
      `COLOR_YELLOW: hex7_reg = 7'b0010001; // y
      default:       hex7_reg = 7'b1111111;
    endcase

    // HEX6 = valor de player_card
    case (n_card_player)
      4'd0:                  hex6_reg = 7'b1000000;
      4'd1:                  hex6_reg = 7'b1111001;
      4'd2:                  hex6_reg = 7'b0100100;
      4'd3:                  hex6_reg = 7'b0110000;
      4'd4:                  hex6_reg = 7'b0011001;
      4'd5:                  hex6_reg = 7'b0010010;
      4'd6:                  hex6_reg = 7'b0000010;
      4'd7:                  hex6_reg = 7'b1111000;
      4'd8:                  hex6_reg = 7'b0000000;
      4'd9:                  hex6_reg = 7'b0011000;
      `VALUE_SKIP:           hex6_reg = 7'b0111111; // -
      `VALUE_REVERSE:        hex6_reg = 7'b0000111; // t
      `VALUE_DRAW_TWO:       hex6_reg = 7'b0100001; // d
      `VALUE_WILD:           hex6_reg = 7'b0110110; // =
      `VALUE_WILD_DRAW_FOUR: hex6_reg = 7'b0001110; // F
      default:               hex6_reg = 7'b1111111;
    endcase

    // HEX5 = dezenas de n_player
    case (dezena_p)
      4'd0: hex5_reg = 7'b1000000;
      4'd1: hex5_reg = 7'b1111001;
      4'd2: hex5_reg = 7'b0100100;
      4'd3: hex5_reg = 7'b0110000;
      4'd4: hex5_reg = 7'b0011001;
      4'd5: hex5_reg = 7'b0010010;
      4'd6: hex5_reg = 7'b0000010;
      4'd7: hex5_reg = 7'b1111000;
      4'd8: hex5_reg = 7'b0000000;
      4'd9: hex5_reg = 7'b0011000;
      default: hex5_reg = 7'b1111111;
    endcase

    // HEX4 = unidades de n_player
    case (unidade_p)
      4'd0: hex4_reg = 7'b1000000;
      4'd1: hex4_reg = 7'b1111001;
      4'd2: hex4_reg = 7'b0100100;
      4'd3: hex4_reg = 7'b0110000;
      4'd4: hex4_reg = 7'b0011001;
      4'd5: hex4_reg = 7'b0010010;
      4'd6: hex4_reg = 7'b0000010;
      4'd7: hex4_reg = 7'b1111000;
      4'd8: hex4_reg = 7'b0000000;
      4'd9: hex4_reg = 7'b0011000;
      default: hex4_reg = 7'b1111111;
    endcase

    // HEX3 = dezenas de n_cpu
    case (dezena_c)
      4'd0: hex3_reg = 7'b1000000;
      4'd1: hex3_reg = 7'b1111001;
      4'd2: hex3_reg = 7'b0100100;
      4'd3: hex3_reg = 7'b0110000;
      4'd4: hex3_reg = 7'b0011001;
      4'd5: hex3_reg = 7'b0010010;
      4'd6: hex3_reg = 7'b0000010;
      4'd7: hex3_reg = 7'b1111000;
      4'd8: hex3_reg = 7'b0000000;
      4'd9: hex3_reg = 7'b0011000;
      default: hex3_reg = 7'b1111111;
    endcase

    // HEX2 = unidades de n_cpu
    case (unidade_c)
      4'd0: hex2_reg = 7'b1000000;
      4'd1: hex2_reg = 7'b1111001;
      4'd2: hex2_reg = 7'b0100100;
      4'd3: hex2_reg = 7'b0110000;
      4'd4: hex2_reg = 7'b0011001;
      4'd5: hex2_reg = 7'b0010010;
      4'd6: hex2_reg = 7'b0000010;
      4'd7: hex2_reg = 7'b1111000;
      4'd8: hex2_reg = 7'b0000000;
      4'd9: hex2_reg = 7'b0011000;
      default: hex2_reg = 7'b1111111;
    endcase

    // HEX1 = cor de top_card
    case (cor_top)
      `COLOR_RED:    hex1_reg = 7'b1001110; // r
      `COLOR_GREEN:  hex1_reg = 7'b0010000; // g
      `COLOR_BLUE:   hex1_reg = 7'b0000011; // b
      `COLOR_YELLOW: hex1_reg = 7'b0010001; // y
      default:       hex1_reg = 7'b1111111;
    endcase

    // HEX0 = valor de top_card
    case (n_top)
      4'd0:                  hex0_reg = 7'b1000000;
      4'd1:                  hex0_reg = 7'b1111001;
      4'd2:                  hex0_reg = 7'b0100100;
      4'd3:                  hex0_reg = 7'b0110000;
      4'd4:                  hex0_reg = 7'b0011001;
      4'd5:                  hex0_reg = 7'b0010010;
      4'd6:                  hex0_reg = 7'b0000010;
      4'd7:                  hex0_reg = 7'b1111000;
      4'd8:                  hex0_reg = 7'b0000000;
      4'd9:                  hex0_reg = 7'b0011000;
      `VALUE_SKIP:           hex0_reg = 7'b0111111; // -
      `VALUE_REVERSE:        hex0_reg = 7'b0000111; // t
      `VALUE_DRAW_TWO:       hex0_reg = 7'b0100001; // d
      `VALUE_WILD:           hex0_reg = 7'b0110110; // =
      `VALUE_WILD_DRAW_FOUR: hex0_reg = 7'b0001110; // F
      default:               hex0_reg = 7'b1111111;
    endcase
  end
endmodule
