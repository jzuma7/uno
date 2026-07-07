`include "../include/timing_definitions.vh"
`include "../include/memory_definitions.vh"

module cpu_hand (
  input clock,
  input reset,
  input turn,
  input valid_play,
  input special_draw,
  input write_enable,
  input [5:0] card_in,

  output turn_done,
  output play_card,
  output need_to_draw,
  output [5:0] card_out,
  output [6:0] hand_count
);

  localparam STATE_IDLE = 2'b00;
  localparam STATE_PLAY = 2'b01;
  localparam STATE_DRAW = 2'b10;
  localparam STATE_DONE = 2'b11;

  reg turn_done_reg;
  reg card_received;    // ao menos uma carta foi recebida em STATE_DRAW
  reg drew_for_play;    // entrou em STATE_DRAW por need_to_draw (não por penalidade)
  reg [1:0] state;
  reg [31:0] timer;
  reg [6:0] hand_count_reg;
  reg [5:0] cpu_hand [0:`DECK_SIZE - 1]; // pior caso: mão acumula quase todo o baralho via penalidades/draws
  reg [6:0] cpu_hand_play_pointer;

  assign turn_done  = turn_done_reg;
  assign hand_count = hand_count_reg;
  assign card_out   = cpu_hand[cpu_hand_play_pointer];
  assign play_card  = (state == STATE_PLAY && valid_play);
  assign need_to_draw = (hand_count_reg > 0) && (cpu_hand_play_pointer >= hand_count_reg);

  always @ (posedge clock) begin
    if (reset) begin
      timer <= 0;
      turn_done_reg <= 0;
      card_received <= 0;
      drew_for_play <= 0;
      hand_count_reg <= 0;
      state <= STATE_IDLE;
      cpu_hand_play_pointer <= 0;
    end else begin
      // AVISO: game_fsm não deve pulsar write_enable enquanto state==STATE_PLAY
      // e valid_play==1 — conflito de NBA em hand_count_reg.
      if (write_enable) begin
        card_received <= 1;
        cpu_hand[hand_count_reg] <= card_in;
        hand_count_reg <= hand_count_reg + 1;
      end
      case (state)
        STATE_IDLE: begin
          turn_done_reg <= 0;
          if (turn) begin
            state <= STATE_PLAY;
            drew_for_play <= 0;
            cpu_hand_play_pointer <= 0;
          end else if (special_draw) begin
            card_received <= 0;
            state <= STATE_DRAW;
          end
        end

        STATE_PLAY: begin
          if (valid_play) begin
            timer <= 0;
            drew_for_play <= 0;
            state <= STATE_DONE;
            hand_count_reg <= hand_count_reg - 1;
            cpu_hand[cpu_hand_play_pointer] <= cpu_hand[hand_count_reg - 1];
          end else if (need_to_draw) begin
            if (!drew_for_play) begin
              drew_for_play <= 1;
              card_received <= 0;
              state <= STATE_DRAW;
            end else begin
              timer <= 0;
              drew_for_play <= 0;
              state <= STATE_DONE;
            end
          end else begin
            cpu_hand_play_pointer <= cpu_hand_play_pointer + 1;
          end
        end

        STATE_DRAW: begin
          // AVISO: sem timeout — game_fsm deve garantir que o dealer
          // sempre entregue ao menos 1 carta ao entrar neste estado.
          if (card_received && !write_enable) begin
            card_received <= 0;
            if (drew_for_play) begin
              state <= STATE_PLAY;
              cpu_hand_play_pointer <= hand_count_reg - 1;
            end else begin
              timer <= 0;
              state <= STATE_DONE;
            end
          end
        end

        STATE_DONE: begin
          if (timer < `TWO_SECONDS_CLOCK)
            timer <= timer + 1;
          else begin
            turn_done_reg <= 1;
            state <= STATE_IDLE;
          end
        end
      endcase
    end
  end
endmodule
