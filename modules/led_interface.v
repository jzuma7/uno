`include "../include/timing_definitions.vh"

module led_interface(
  input clock,
  input reset,
  input player_turn,
  input cpu_turn,
  input invalid_move,
  input draw_action,
  input skip_action,
  input win,
  input lose,

  output [17:0] ledr,
  output [8:0] ledg
);

  reg win_latch;
  reg lose_latch;
  reg player_turn_latch;
  reg cpu_turn_latch;
  reg invalid_move_latch;
  reg draw_action_latch;
  reg skip_action_latch;

  reg [17:0] ledr_reg;
  reg [8:0] ledg_reg;

  assign ledr = ledr_reg;
  assign ledg = ledg_reg;

  reg [31:0] player_turn_timer, cpu_turn_timer, invalid_move_timer;
  reg [31:0] draw_action_timer, skip_action_timer;

  always @(posedge clock) begin
    if (reset) begin
      win_latch  <= 1'b0;
      lose_latch <= 1'b0;
    end else begin
      if (win)
        win_latch  <= 1'b1;
      if (lose)
        lose_latch <= 1'b1;
    end
  end

  always @ (posedge clock) begin
    if (reset) begin
      player_turn_latch <= 1'b0;
      player_turn_timer <= 32'b0;
    end else if (player_turn) begin
      player_turn_latch <= 1'b1;
      player_turn_timer <= 32'b0;
    end else if (player_turn_latch) begin
      if (player_turn_timer == `TWO_SECONDS_CLOCK - 1) begin
        player_turn_latch <= 1'b0;
        player_turn_timer <= 32'b0;
      end else
        player_turn_timer <= player_turn_timer + 1'b1;
    end
  end

  always @ (posedge clock) begin
    if (reset) begin
      cpu_turn_latch <= 1'b0;
      cpu_turn_timer <= 32'b0;
    end else if (cpu_turn) begin
      cpu_turn_latch <= 1'b1;
      cpu_turn_timer <= 32'b0;
    end else if (cpu_turn_latch) begin
      if (cpu_turn_timer == `TWO_SECONDS_CLOCK - 1) begin
        cpu_turn_latch <= 1'b0;
        cpu_turn_timer <= 32'b0;
      end else
        cpu_turn_timer <= cpu_turn_timer + 1'b1;
    end
  end

  always @ (posedge clock) begin
    if (reset) begin
      invalid_move_latch <= 1'b0;
      invalid_move_timer <= 32'b0;
    end else if (invalid_move) begin
      invalid_move_latch <= 1'b1;
      invalid_move_timer <= 32'b0;
    end else if (invalid_move_latch) begin
      if (invalid_move_timer == `TWO_SECONDS_CLOCK - 1) begin
        invalid_move_latch <= 1'b0;
        invalid_move_timer <= 32'b0;
      end else
        invalid_move_timer <= invalid_move_timer + 1'b1;
    end
  end

  always @ (posedge clock) begin
    if (reset) begin
      draw_action_latch <= 1'b0;
      draw_action_timer <= 32'b0;
    end else if (draw_action) begin
      draw_action_latch <= 1'b1;
      draw_action_timer <= 32'b0;
    end else if (draw_action_latch) begin
      if (draw_action_timer == `TWO_SECONDS_CLOCK - 1) begin
        draw_action_latch <= 1'b0;
        draw_action_timer <= 32'b0;
      end else
        draw_action_timer <= draw_action_timer + 1'b1;
    end
  end

  always @ (posedge clock) begin
    if (reset) begin
      skip_action_latch <= 1'b0;
      skip_action_timer <= 32'b0;
    end else if (skip_action) begin
      skip_action_latch <= 1'b1;
      skip_action_timer <= 32'b0;
    end else if (skip_action_latch) begin
      if (skip_action_timer == `TWO_SECONDS_CLOCK - 1) begin
        skip_action_latch <= 1'b0;
        skip_action_timer <= 32'b0;
      end else
        skip_action_timer <= skip_action_timer + 1'b1;
    end
  end

  always @ (*) begin
    if (win_latch) begin
      ledg_reg = 9'h1FF;
      ledr_reg = 18'b0;
    end else if (lose_latch) begin
      ledg_reg = 9'b0;
      ledr_reg = 18'h3FFFF;
    end else begin
      ledg_reg = 9'b0;
      ledr_reg = {13'b0, invalid_move_latch, skip_action_latch,
        draw_action_latch, cpu_turn_latch, player_turn_latch};
    end
  end
endmodule
