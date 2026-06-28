`include "../include/timing_definitions.vh"

module player_hand (
  input clock,
  input reset,
  input turn,
  input select,
  input play,
  input draw,
  input valid_play,
  input special_draw,
  input write_enable,
  input [5:0] card_in,

  output play_card,
  output invalid_move,
  output turn_done,
  output [5:0] card_out,
  output [6:0] hand_count
);

  localparam STATE_IDLE = 2'b00;
  localparam STATE_PLAY = 2'b01;
  localparam STATE_DRAW = 2'b10;
  localparam STATE_DONE = 2'b11;

  reg turn_done_reg;
  reg card_received;
  reg [1:0] state;
  reg [6:0] hand_count_reg;
  reg [5:0] player_hand [0:63];
  reg [6:0] player_hand_play_pointer;

  assign turn_done = turn_done_reg;
  assign hand_count = hand_count_reg;
  assign card_out = player_hand[player_hand_play_pointer];
  assign play_card = (state == STATE_PLAY) && play && valid_play && (hand_count_reg > 0);
  assign invalid_move = (state == STATE_PLAY) && play && !valid_play;

  always @(posedge clock) begin
    if (reset) begin
      turn_done_reg <= 0;
      card_received <= 0;
      hand_count_reg <= 0;
      state <= STATE_IDLE;
      player_hand_play_pointer <= 0;
    end else begin
      if (write_enable) begin
        card_received <= 1;
        hand_count_reg <= hand_count_reg + 1;
        player_hand[hand_count_reg] <= card_in;
      end

      case (state)
        STATE_IDLE: begin
          turn_done_reg <= 0;
          if (turn) begin
            state <= STATE_PLAY;
            player_hand_play_pointer <= 0;
          end else if (special_draw) begin
            card_received <= 0;
            state <= STATE_DRAW;
          end
        end

        STATE_PLAY: begin
          if (play && valid_play && hand_count_reg > 0) begin
            player_hand[player_hand_play_pointer] <= player_hand[hand_count_reg - 1];
            hand_count_reg <= hand_count_reg - 1;
            player_hand_play_pointer <= 0;
            state <= STATE_DONE;
          end else if (draw) begin
            card_received <= 0;
            state <= STATE_DRAW;
          end else if (select && hand_count_reg > 0) begin
            if (player_hand_play_pointer + 1 >= hand_count_reg)
              player_hand_play_pointer <= 0;
            else
              player_hand_play_pointer <= player_hand_play_pointer + 1;
          end
        end

        STATE_DRAW: begin
          if (card_received && !write_enable) begin
            card_received <= 0;
            state <= STATE_DONE;
          end
        end

        STATE_DONE: begin
          turn_done_reg <= 1;
          state <= STATE_IDLE;
        end
      endcase
    end
  end
endmodule
