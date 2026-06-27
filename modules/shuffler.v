module shuffler(
  input clock,
  input reset,
  input start,
  input shuffle_controller, // 0 - deck inicial, 1 - embaralhar pilha de descarte
  input [6:0] card_count,   // 108 no embaralhamento inicial; discard_pointer - 1 no reembaralho
  input [5:0] read_data,

  output done,
  output read_source,
  output write_enable,
  output reset_pointers,
  output [5:0] card_out,
  output [6:0] read_address
);

  localparam STATE_IDLE = 3'b000;
  localparam STATE_DONE = 3'b001;
  localparam STATE_WRITING = 3'b010;
  localparam STATE_LOADING = 3'b011;
  localparam STATE_SHUFFLING = 3'b100;
  localparam STATE_RESETTING = 3'b101;

  reg [6:0] lfsr;                // registrador do gerador pseudoaleatório de 7 bits
  reg [2:0] state;               // estado atual da FSM
  reg [6:0] load_pointer;        // endereço de leitura durante LOADING
  reg [6:0] write_pointer;       // posição de escrita durante WRITING
  reg [6:0] shuffle_pointer;     // i do Fisher-Yates: posição atual do swap
  reg [5:0] card_buffer [0:107]; // cópia local das cartas a embaralhar

  wire [6:0] swap_index = lfsr % (shuffle_pointer + 7'd1); // j do Fisher-Yates: índice aleatório calculado do lfsr

  assign read_address = load_pointer;
  assign read_source = shuffle_controller;
  assign card_out = card_buffer[write_pointer];

  assign done = (state == STATE_DONE);
  assign write_enable = (state == STATE_WRITING);
  assign reset_pointers = (state == STATE_RESETTING);

  always @ (posedge clock) begin
    if(reset) begin
      state <= STATE_IDLE;
      load_pointer <= 0;
      shuffle_pointer <= 0;
      write_pointer <= 0;
      lfsr <= 7'b0000001;
    end else begin
      case(state)
        STATE_IDLE: begin
          lfsr <= {lfsr[5:0], lfsr[6] ^ lfsr[5]};

          if(start) begin
            load_pointer <= 0;
            state <= STATE_LOADING;
          end
        end
        STATE_LOADING: begin
          lfsr <= {lfsr[5:0], lfsr[6] ^ lfsr[5]};

          card_buffer[load_pointer] <= read_data;

          load_pointer <= load_pointer + 1;

          if(load_pointer == card_count - 1) begin
            state <= STATE_SHUFFLING;
            shuffle_pointer <= card_count - 1;
          end
        end
        STATE_SHUFFLING: begin
          lfsr <= {lfsr[5:0], lfsr[6] ^ lfsr[5]};

          card_buffer[shuffle_pointer] <= card_buffer[swap_index];
          card_buffer[swap_index] <= card_buffer[shuffle_pointer];

          shuffle_pointer <= shuffle_pointer - 1;

          if(shuffle_pointer == 1)
            state <= STATE_RESETTING;
        end
        STATE_RESETTING: begin
          state <= STATE_WRITING;
          write_pointer <= 0;
        end
        STATE_WRITING: begin
          write_pointer <= write_pointer + 1;

          if(write_pointer == card_count - 1)
            state <= STATE_DONE;
        end
        STATE_DONE: begin
          lfsr <= {lfsr[5:0], lfsr[6] ^ lfsr[5]};
        end
        default: begin
          lfsr <= {lfsr[5:0], lfsr[6] ^ lfsr[5]};
        end
      endcase
    end
  end
endmodule
