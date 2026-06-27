`include "../include/card_definitions.vh"

module play_validator (
  input [5:0] played_card,
  input [5:0] top_card,

  output valid_play
);

  wire same_color = played_card[5:4] == top_card[5:4];
  wire same_value = played_card[3:0] == top_card[3:0];
  wire is_wild = played_card[3:0] == `VALUE_WILD || played_card[3:0] == `VALUE_WILD_DRAW_FOUR;

  assign valid_play = same_color || same_value || is_wild;
endmodule
