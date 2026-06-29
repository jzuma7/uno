`include "../include/card_definitions.vh"
`include "../include/timing_definitions.vh"
`include "../include/memory_definitions.vh"

module uno_fsm (
  input  CLOCK_50,
  input  [3:0] KEY,
  output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
  output [17:0] LEDR,
  output [8:0]  LEDG
);

  // ── Memory operations ──────────────────────────────────────────
  localparam OPERATION_IDLE         = 2'b00;
  localparam OPERATION_DRAW_CARD    = 2'b01;
  localparam OPERATION_DISCARD_CARD = 2'b10;
  localparam OPERATION_LOAD_CARD    = 2'b11;

  // ── FSM states ─────────────────────────────────────────────────
  localparam STATE_INIT_DECK          = 5'd0;
  localparam STATE_INIT_SHUFFLE       = 5'd1;
  localparam STATE_DEAL_PLAYER        = 5'd2;
  localparam STATE_DEAL_CPU           = 5'd3;
  localparam STATE_DEAL_INITIAL_DRAW  = 5'd4;
  localparam STATE_DISCARD_INITIAL    = 5'd5;
  localparam STATE_PLAYER_TURN        = 5'd6;
  localparam STATE_PLAYER_PLAY        = 5'd7;
  localparam STATE_PLAYER_DRAW_START  = 5'd8;
  localparam STATE_PLAYER_DRAW_WAIT   = 5'd9;
  localparam STATE_PLAYER_DRAW_CHECK  = 5'd10;
  localparam STATE_CPU_TURN           = 5'd11;
  localparam STATE_CPU_PLAY           = 5'd12;
  localparam STATE_CPU_DRAW_START     = 5'd13;
  localparam STATE_CPU_DRAW_WAIT      = 5'd14;
  localparam STATE_DEAL_PENALTY       = 5'd15;
  localparam STATE_CHECK_DECK         = 5'd16;
  localparam STATE_RESHUFFLE          = 5'd17;
  localparam STATE_WIN                = 5'd18;
  localparam STATE_LOSE               = 5'd19;

  // ── FSM registers ──────────────────────────────────────────────
  reg [4:0] state;
  reg [4:0] return_state;   // estado de retorno após CHECK_DECK / RESHUFFLE
  reg [5:0] drawn_card_reg; // carta capturada no draw do player
  reg [2:0] action_reg;     // efeito especial da carta jogada
  reg [2:0] penalty_count;  // cartas a distribuir na penalidade (2 ou 4)
  reg       penalize_player; // 0 = CPU penalizada, 1 = player penalizado
  reg       cpu_drew;        // flag: CPU já comprou neste turno

  // ── Clock e reset (gerados pelo buttons_interface) ─────────────
  wire clock;
  wire reset;
  wire select;
  wire play;
  wire draw;

  // ── Memória ────────────────────────────────────────────────────
  reg  [5:0] card_in_reg;
  wire [5:0] memory_card_out;
  wire [5:0] top_card;
  wire       deck_empty;
  wire [6:0] discard_pointer_out;
  wire [5:0] shuffler_read_data;

  reg  [1:0] memory_controller;
  reg  [5:0] card_in;
  wire       reset_deck_pointers;
  wire       shuffler_read_source;
  wire [6:0] shuffler_read_address;

  // ── deck_initializer ───────────────────────────────────────────
  wire       deck_initializer_done;
  wire       deck_initializer_write_enable;
  wire [5:0] deck_initializer_card_out;

  // ── shuffler ───────────────────────────────────────────────────
  reg        shuffler_start;
  reg        shuffler_controller;
  reg  [6:0] shuffler_card_count;
  wire       shuffler_done;
  wire       shuffler_write_enable;
  wire [5:0] shuffler_card_out;

  // ── card_dealer ────────────────────────────────────────────────
  reg        dealer_start;
  reg  [2:0] dealer_cards_to_deal;
  wire       dealer_done;
  wire       dealer_write_enable;
  wire [1:0] dealer_memory_controller;
  wire [5:0] dealer_card_out;

  // ── player_hand ────────────────────────────────────────────────
  wire [5:0] player_hand_card_in;
  reg        player_turn_signal;
  reg        player_write_enable;
  reg        player_end_turn;
  wire       player_play_card;
  wire       player_invalid_move;
  wire [5:0] player_card_out;
  wire [6:0] player_hand_count;
  wire       player_valid_play;

  // ── cpu_hand ───────────────────────────────────────────────────
  reg        cpu_turn_signal;
  reg        cpu_write_enable;
  wire       cpu_play_card;
  wire       cpu_need_to_draw;
  wire       cpu_turn_done;
  wire [5:0] cpu_card_out;
  wire [6:0] cpu_hand_count;
  wire       cpu_valid_play;

  // ── LED latch + timer ──────────────────────────────────────────
  reg [17:0] LEDR;
  reg [8:0]  LEDG;
  reg player_turn_latch, cpu_turn_latch;
  reg invalid_move_latch, draw_action_latch, skip_action_latch;
  reg win_latch, lose_latch;
  reg [31:0] player_turn_timer, cpu_turn_timer;
  reg [31:0] invalid_move_timer, draw_action_timer, skip_action_timer;
  wire led_draw_action;
  wire led_skip_action;

  // ── Sinais auxiliares ──────────────────────────────────────────
  wire drawn_card_valid;

  assign drawn_card_valid = (drawn_card_reg[5:4] == top_card[5:4]) ||
                            (drawn_card_reg[3:0] == top_card[3:0]) ||
                            (drawn_card_reg[3:0] >= `VALUE_WILD);

  // wild recebe a cor do top_card atual antes de ser descartado
  wire [5:0] drawn_card_adjusted;
  assign drawn_card_adjusted = (drawn_card_reg[3:0] >= `VALUE_WILD)
                               ? {top_card[5:4], drawn_card_reg[3:0]}
                               : drawn_card_reg;

  // ── Clock e reset ──────────────────────────────────────────────
  assign clock = CLOCK_50;

  // card_in do player_hand: drawn_card_reg no check do draw, senão dealer
  assign player_hand_card_in = (state == STATE_PLAYER_DRAW_CHECK) ? drawn_card_reg
                                                                    : dealer_card_out;

  // ── Mux combinacional ──────────────────────────────────────────
  always @ (*) begin
    // defaults
    memory_controller = OPERATION_IDLE;
    card_in           = 6'b0;
    player_write_enable = 1'b0;
    cpu_write_enable    = 1'b0;
    player_end_turn     = 1'b0;
    player_turn_signal  = 1'b0;
    cpu_turn_signal     = 1'b0;

    case (state)
      STATE_INIT_DECK: begin
        memory_controller = deck_initializer_write_enable ? OPERATION_LOAD_CARD
                                                          : OPERATION_IDLE;
        card_in = deck_initializer_card_out;
      end

      STATE_INIT_SHUFFLE, STATE_RESHUFFLE: begin
        memory_controller = shuffler_write_enable ? OPERATION_LOAD_CARD
                                                  : OPERATION_IDLE;
        card_in = shuffler_card_out;
      end

      STATE_DEAL_PLAYER: begin
        memory_controller   = dealer_memory_controller;
        player_write_enable = dealer_write_enable;
      end

      STATE_DEAL_CPU: begin
        memory_controller = dealer_memory_controller;
        cpu_write_enable  = dealer_write_enable;
      end

      STATE_DEAL_INITIAL_DRAW: begin
        memory_controller = dealer_memory_controller;
      end

      STATE_DISCARD_INITIAL: begin
        memory_controller = OPERATION_DISCARD_CARD;
        card_in           = card_in_reg;
      end

      STATE_PLAYER_TURN: begin
        player_turn_signal = 1'b1;
      end

      STATE_PLAYER_PLAY: begin
        memory_controller = OPERATION_DISCARD_CARD;
        card_in           = card_in_reg;
      end

      STATE_PLAYER_DRAW_WAIT: begin
        memory_controller = dealer_memory_controller;
      end

      STATE_PLAYER_DRAW_CHECK: begin
        player_end_turn = 1'b1;
        if (drawn_card_valid) begin
          memory_controller = OPERATION_DISCARD_CARD;
          card_in           = drawn_card_adjusted;
        end else begin
          player_write_enable = 1'b1;
        end
      end

      STATE_CPU_TURN: begin
        cpu_turn_signal = 1'b1;
      end

      STATE_CPU_PLAY: begin
        memory_controller = OPERATION_DISCARD_CARD;
        card_in           = card_in_reg;
      end

      STATE_CPU_DRAW_WAIT: begin
        memory_controller = dealer_memory_controller;
        cpu_write_enable  = dealer_write_enable;
      end

      STATE_DEAL_PENALTY: begin
        memory_controller = dealer_memory_controller;
        if (penalize_player)
          player_write_enable = dealer_write_enable;
        else
          cpu_write_enable = dealer_write_enable;
      end

      default: begin
      end
    endcase
  end

  // ── Instâncias ─────────────────────────────────────────────────

  buttons_interface buttons_interface_inst (
    .clock   (clock),
    .key_raw (KEY),
    .reset   (reset),
    .select  (select),
    .play    (play),
    .draw    (draw)
  );

  memory memory_inst (
    .clock                 (clock),
    .reset                 (reset),
    .card_in               (card_in),
    .memory_controller     (memory_controller),
    .deck_empty            (deck_empty),
    .card_out              (memory_card_out),
    .top_card              (top_card),
    .reset_deck_pointers   (reset_deck_pointers),
    .shuffler_read_source  (shuffler_read_source),
    .shuffler_read_address (shuffler_read_address),
    .shuffler_read_data    (shuffler_read_data),
    .discard_pointer_out   (discard_pointer_out)
  );

  deck_initializer deck_initializer_inst (
    .clock        (clock),
    .reset        (reset),
    .done         (deck_initializer_done),
    .write_enable (deck_initializer_write_enable),
    .card_out     (deck_initializer_card_out)
  );

  shuffler shuffler_inst (
    .clock            (clock),
    .reset            (reset),
    .start            (shuffler_start),
    .shuffle_controller (shuffler_controller),
    .card_count       (shuffler_card_count),
    .read_data        (shuffler_read_data),
    .done             (shuffler_done),
    .read_source      (shuffler_read_source),
    .read_address     (shuffler_read_address),
    .write_enable     (shuffler_write_enable),
    .reset_pointers   (reset_deck_pointers),
    .card_out         (shuffler_card_out)
  );

  card_dealer card_dealer_inst (
    .clock             (clock),
    .reset             (reset),
    .start             (dealer_start),
    .read_data         (memory_card_out),
    .cards_to_deal     (dealer_cards_to_deal),
    .done              (dealer_done),
    .write_enable      (dealer_write_enable),
    .memory_controller (dealer_memory_controller),
    .card_out          (dealer_card_out)
  );

  player_hand player_hand_inst (
    .clock         (clock),
    .reset         (reset),
    .turn          (player_turn_signal),
    .select        (select),
    .play          (play),
    .draw          (1'b0),
    .valid_play    (player_valid_play),
    .special_draw  (1'b0),
    .write_enable  (player_write_enable),
    .card_in       (player_hand_card_in),
    .end_turn      (player_end_turn),
    .play_card     (player_play_card),
    .invalid_move  (player_invalid_move),
    .card_out      (player_card_out),
    .hand_count    (player_hand_count)
  );

  cpu_hand cpu_hand_inst (
    .clock         (clock),
    .reset         (reset),
    .turn          (cpu_turn_signal),
    .valid_play    (cpu_valid_play),
    .special_draw  (1'b0),
    .write_enable  (cpu_write_enable),
    .card_in       (dealer_card_out),
    .turn_done     (cpu_turn_done),
    .play_card     (cpu_play_card),
    .need_to_draw  (cpu_need_to_draw),
    .card_out      (cpu_card_out),
    .hand_count    (cpu_hand_count)
  );

  play_validator player_play_validator (
    .played_card (player_card_out),
    .top_card    (top_card),
    .valid_play  (player_valid_play)
  );

  play_validator cpu_play_validator (
    .played_card (cpu_card_out),
    .top_card    (top_card),
    .valid_play  (cpu_valid_play)
  );

  display_interface display_interface_inst (
    .top_card    (top_card),
    .player_card (player_card_out),
    .n_player    (player_hand_count),
    .n_cpu       (cpu_hand_count),
    .hex7        (HEX7),
    .hex6        (HEX6),
    .hex5        (HEX5),
    .hex4        (HEX4),
    .hex3        (HEX3),
    .hex2        (HEX2),
    .hex1        (HEX1),
    .hex0        (HEX0)
  );

  // ── FSM sequencial ────────────────────────────────────────────
  always @ (posedge clock) begin
    if (reset) begin
      state                <= STATE_INIT_DECK;
      return_state         <= STATE_INIT_DECK;
      drawn_card_reg       <= 6'b0;
      action_reg           <= 3'b0;
      penalty_count        <= 3'b0;
      penalize_player      <= 1'b0;
      cpu_drew             <= 1'b0;
      card_in_reg          <= 6'b0;
      dealer_start         <= 1'b0;
      dealer_cards_to_deal  <= 3'b0;
      shuffler_start        <= 1'b0;
      shuffler_controller   <= 1'b0;
      shuffler_card_count   <= 7'b0;
    end else begin
      dealer_start   <= 1'b0;
      shuffler_start <= 1'b0;

      case (state)

        // ── Init ────────────────────────────────────────────────
        STATE_INIT_DECK: begin
          if (deck_initializer_done) begin
            shuffler_start      <= 1'b1;
            shuffler_controller <= 1'b0;
            shuffler_card_count <= 7'd108;
            state               <= STATE_INIT_SHUFFLE;
          end
        end

        STATE_INIT_SHUFFLE: begin
          if (shuffler_done) begin
            dealer_start         <= 1'b1;
            dealer_cards_to_deal <= 3'd7;
            state                <= STATE_DEAL_PLAYER;
          end
        end

        STATE_DEAL_PLAYER: begin
          if (dealer_done) begin
            dealer_start         <= 1'b1;
            dealer_cards_to_deal <= 3'd7;
            state                <= STATE_DEAL_CPU;
          end
        end

        STATE_DEAL_CPU: begin
          if (dealer_done) begin
            dealer_start         <= 1'b1;
            dealer_cards_to_deal <= 3'd1;
            state                <= STATE_DEAL_INITIAL_DRAW;
          end
        end

        STATE_DEAL_INITIAL_DRAW: begin
          if (dealer_write_enable)
            drawn_card_reg <= dealer_card_out;
          if (dealer_done) begin
            card_in_reg <= (drawn_card_reg[3:0] >= `VALUE_WILD)
                           ? {top_card[5:4], drawn_card_reg[3:0]}
                           : drawn_card_reg;
            state       <= STATE_DISCARD_INITIAL;
          end
        end

        STATE_DISCARD_INITIAL: begin
          state <= STATE_PLAYER_TURN;
        end

        // ── Turno do player ─────────────────────────────────────
        STATE_PLAYER_TURN: begin
          if (player_play_card) begin
            if (player_card_out[3:0] >= `VALUE_WILD)
              card_in_reg <= {top_card[5:4], player_card_out[3:0]};
            else
              card_in_reg <= player_card_out;
            case (player_card_out[3:0])
              `VALUE_SKIP, `VALUE_REVERSE: action_reg <= 3'd1;
              `VALUE_DRAW_TWO:             action_reg <= 3'd2;
              `VALUE_WILD:                 action_reg <= 3'd3;
              `VALUE_WILD_DRAW_FOUR:       action_reg <= 3'd4;
              default:                     action_reg <= 3'd0;
            endcase
            state <= STATE_PLAYER_PLAY;
          end else if (draw) begin
            state <= STATE_PLAYER_DRAW_START;
          end
        end

        STATE_PLAYER_PLAY: begin
          if (player_hand_count == 7'd0)
            state <= STATE_WIN;
          else begin
            case (action_reg)
              3'd1: state <= STATE_PLAYER_TURN;
              3'd2: begin
                penalize_player <= 1'b0;
                penalty_count   <= 3'd2;
                return_state    <= STATE_DEAL_PENALTY;
                state           <= STATE_CHECK_DECK;
              end
              3'd4: begin
                penalize_player <= 1'b0;
                penalty_count   <= 3'd4;
                return_state    <= STATE_DEAL_PENALTY;
                state           <= STATE_CHECK_DECK;
              end
              default: state <= STATE_CPU_TURN;
            endcase
          end
        end

        STATE_PLAYER_DRAW_START: begin
          if (deck_empty) begin
            return_state <= STATE_PLAYER_DRAW_START;
            state        <= STATE_CHECK_DECK;
          end else begin
            dealer_start         <= 1'b1;
            dealer_cards_to_deal <= 3'd1;
            state                <= STATE_PLAYER_DRAW_WAIT;
          end
        end

        STATE_PLAYER_DRAW_WAIT: begin
          if (dealer_write_enable)
            drawn_card_reg <= dealer_card_out;
          if (dealer_done)
            state <= STATE_PLAYER_DRAW_CHECK;
        end

        STATE_PLAYER_DRAW_CHECK: begin
          if (drawn_card_valid) begin
            case (drawn_card_reg[3:0])
              `VALUE_SKIP, `VALUE_REVERSE: begin
                action_reg <= 3'd1;
                state      <= STATE_PLAYER_TURN;
              end
              `VALUE_DRAW_TWO: begin
                action_reg      <= 3'd2;
                penalize_player <= 1'b0;
                penalty_count   <= 3'd2;
                return_state    <= STATE_DEAL_PENALTY;
                state           <= STATE_CHECK_DECK;
              end
              `VALUE_WILD_DRAW_FOUR: begin
                action_reg      <= 3'd4;
                penalize_player <= 1'b0;
                penalty_count   <= 3'd4;
                return_state    <= STATE_DEAL_PENALTY;
                state           <= STATE_CHECK_DECK;
              end
              default: begin
                action_reg <= 3'd0;
                state      <= STATE_CPU_TURN;
              end
            endcase
          end else begin
            state <= STATE_CPU_TURN;
          end
        end

        // ── Turno da CPU ────────────────────────────────────────
        STATE_CPU_TURN: begin
          if (cpu_play_card) begin
            if (cpu_card_out[3:0] >= `VALUE_WILD)
              card_in_reg <= {top_card[5:4], cpu_card_out[3:0]};
            else
              card_in_reg <= cpu_card_out;
            case (cpu_card_out[3:0])
              `VALUE_SKIP, `VALUE_REVERSE: action_reg <= 3'd1;
              `VALUE_DRAW_TWO:             action_reg <= 3'd2;
              `VALUE_WILD:                 action_reg <= 3'd3;
              `VALUE_WILD_DRAW_FOUR:       action_reg <= 3'd4;
              default:                     action_reg <= 3'd0;
            endcase
            state <= STATE_CPU_PLAY;
          end else if (cpu_need_to_draw && !cpu_drew) begin
            cpu_drew <= 1'b1;
            state    <= STATE_CPU_DRAW_START;
          end else if (cpu_turn_done) begin
            cpu_drew <= 1'b0;
            state    <= STATE_PLAYER_TURN;
          end
        end

        STATE_CPU_PLAY: begin
          cpu_drew <= 1'b0;
          if (cpu_hand_count == 7'd0)
            state <= STATE_LOSE;
          else begin
            case (action_reg)
              3'd1: state <= STATE_CPU_TURN;
              3'd2: begin
                penalize_player <= 1'b1;
                penalty_count   <= 3'd2;
                return_state    <= STATE_DEAL_PENALTY;
                state           <= STATE_CHECK_DECK;
              end
              3'd4: begin
                penalize_player <= 1'b1;
                penalty_count   <= 3'd4;
                return_state    <= STATE_DEAL_PENALTY;
                state           <= STATE_CHECK_DECK;
              end
              default: state <= STATE_PLAYER_TURN;
            endcase
          end
        end

        STATE_CPU_DRAW_START: begin
          if (deck_empty) begin
            return_state <= STATE_CPU_DRAW_START;
            state        <= STATE_CHECK_DECK;
          end else begin
            dealer_start         <= 1'b1;
            dealer_cards_to_deal <= 3'd1;
            state                <= STATE_CPU_DRAW_WAIT;
          end
        end

        STATE_CPU_DRAW_WAIT: begin
          if (dealer_done)
            state <= STATE_CPU_TURN;
        end

        // ── Estados compartilhados ──────────────────────────────
        STATE_CHECK_DECK: begin
          if (deck_empty) begin
            shuffler_start      <= 1'b1;
            shuffler_controller <= 1'b1;
            shuffler_card_count <= discard_pointer_out - 7'd1;
            state               <= STATE_RESHUFFLE;
          end else begin
            if (return_state == STATE_DEAL_PENALTY) begin
              dealer_start         <= 1'b1;
              dealer_cards_to_deal <= penalty_count;
            end
            state <= return_state;
          end
        end

        STATE_RESHUFFLE: begin
          if (shuffler_done) begin
            if (return_state == STATE_DEAL_PENALTY) begin
              dealer_start         <= 1'b1;
              dealer_cards_to_deal <= penalty_count;
            end
            state <= return_state;
          end
        end

        STATE_DEAL_PENALTY: begin
          if (dealer_done) begin
            if (penalize_player)
              state <= STATE_CPU_TURN;
            else
              state <= STATE_PLAYER_TURN;
          end
        end

        STATE_WIN:  state <= STATE_WIN;
        STATE_LOSE: state <= STATE_LOSE;

        default: state <= STATE_INIT_DECK;

      endcase
    end
  end

  // ── Pulsos de LED ──────────────────────────────────────────────
  assign led_draw_action =
    ((state == STATE_PLAYER_DRAW_WAIT) && dealer_write_enable) ||
    ((state == STATE_CPU_DRAW_WAIT)    && dealer_write_enable) ||
    ((state == STATE_DEAL_PENALTY)     && dealer_write_enable);

  assign led_skip_action =
    ((state == STATE_PLAYER_PLAY) && (action_reg == 3'd1)) ||
    ((state == STATE_CPU_PLAY)    && (action_reg == 3'd1)) ||
    ((state == STATE_PLAYER_DRAW_CHECK) && drawn_card_valid &&
     (drawn_card_reg[3:0] == `VALUE_SKIP || drawn_card_reg[3:0] == `VALUE_REVERSE));

  // ── win / lose latches ─────────────────────────────────────────
  always @(posedge clock) begin
    if (reset) begin
      win_latch  <= 1'b0;
      lose_latch <= 1'b0;
    end else begin
      if (state == STATE_WIN)  win_latch  <= 1'b1;
      if (state == STATE_LOSE) lose_latch <= 1'b1;
    end
  end

  // ── player_turn latch + timer ──────────────────────────────────
  always @(posedge clock) begin
    if (reset) begin
      player_turn_latch <= 1'b0;
      player_turn_timer <= 32'b0;
    end else if (player_turn_signal) begin
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

  // ── cpu_turn latch + timer ─────────────────────────────────────
  always @(posedge clock) begin
    if (reset) begin
      cpu_turn_latch <= 1'b0;
      cpu_turn_timer <= 32'b0;
    end else if (cpu_turn_signal) begin
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

  // ── invalid_move latch + timer ─────────────────────────────────
  always @(posedge clock) begin
    if (reset) begin
      invalid_move_latch <= 1'b0;
      invalid_move_timer <= 32'b0;
    end else if (player_invalid_move) begin
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

  // ── draw_action latch + timer ──────────────────────────────────
  always @(posedge clock) begin
    if (reset) begin
      draw_action_latch <= 1'b0;
      draw_action_timer <= 32'b0;
    end else if (led_draw_action) begin
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

  // ── skip_action latch + timer ──────────────────────────────────
  always @(posedge clock) begin
    if (reset) begin
      skip_action_latch <= 1'b0;
      skip_action_timer <= 32'b0;
    end else if (led_skip_action) begin
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

  // ── saída dos LEDs ─────────────────────────────────────────────
  always @(*) begin
    LEDR = 18'b0;
    LEDG = 9'b0;
    if (win_latch) begin
      LEDR[5] = 1'b1;
    end else if (lose_latch) begin
      LEDR[6] = 1'b1;
    end else begin
      LEDR[0] = player_turn_latch;
      LEDR[1] = cpu_turn_latch;
      LEDR[2] = invalid_move_latch;
      LEDR[3] = draw_action_latch;
      LEDR[4] = skip_action_latch;
    end
  end

endmodule
