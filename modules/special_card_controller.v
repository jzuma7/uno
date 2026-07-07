`include "../include/card_definitions.vh"

module special_card_controller (
  input [5:0] played_card,

  output [2:0] action // 0: None, 1: Skip, 2: Draw2, 3: Wild, 4: Wild4
);

  reg [2:0] action_reg;
  assign action = action_reg;

  always @ (*) begin
    case (played_card[3:0])
      `VALUE_SKIP:           action_reg = 3'd1;
      `VALUE_REVERSE:        action_reg = 3'd1; // Treated as Skip
      `VALUE_DRAW_TWO:       action_reg = 3'd2;
      `VALUE_WILD:           action_reg = 3'd3;
      `VALUE_WILD_DRAW_FOUR: action_reg = 3'd4;
      default:               action_reg = 3'd0;
    endcase
  end
endmodule