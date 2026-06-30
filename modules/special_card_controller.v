`include "../include/card_definitions.vh"

module special_card_controller (
  input [5:0] played_card,

  output [2:0] action // 0: None, 1: Skip, 2: Draw2, 3: Wild, 4: Wild4
);

  reg [2:0] action;

  always @ (*) begin
    case (played_card[3:0])
      `VALUE_SKIP:           action = 3'd1;
      `VALUE_REVERSE:        action = 3'd1; // Treated as Skip
      `VALUE_DRAW_TWO:       action = 3'd2;
      `VALUE_WILD:           action = 3'd3;
      `VALUE_WILD_DRAW_FOUR: action = 3'd4;
      default:               action = 3'd0;
    endcase
  end
endmodule