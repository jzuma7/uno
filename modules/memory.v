`include "../include/memory_definitions.vh"

module memory(
  input clock,
  input reset,
  input [5:0] card_in,
  input [1:0] memory_controller,

  output deck_empty,
  output [5:0] card_out,
  output [5:0] top_card,

  input reset_deck_pointers,
  input shuffler_read_source,   // 0 = deck, 1 = discard_pile
  input [6:0] shuffler_read_address,

  output [5:0] shuffler_read_data,
  output [6:0] discard_pointer_out
);

  localparam OPERATION_IDLE = 2'b00;
  localparam OPERATION_LOAD_CARD = 2'b11;
  localparam OPERATION_DRAW_CARD = 2'b01;
  localparam OPERATION_DISCARD_CARD = 2'b10;

  reg [5:0] top_card_reg;
  reg [5:0] deck [0:`DECK_SIZE - 1];
  reg [5:0] discard_pile [0:`DISCARD_SIZE - 1];

  reg [6:0] draw_pointer;
  reg [6:0] load_pointer;
  reg [6:0] discard_pointer;

  assign top_card = top_card_reg;
  assign card_out = deck[draw_pointer];
  assign deck_empty = (draw_pointer >= load_pointer);

  assign shuffler_read_data = shuffler_read_source
      ? discard_pile[shuffler_read_address]
      : deck[shuffler_read_address];
  assign discard_pointer_out = discard_pointer;

  always @ (posedge clock) begin
    if(reset) begin
      draw_pointer <= 0;
      load_pointer <= 0;
      discard_pointer <= 0;
      top_card_reg <= 0;
    end else begin
      if(reset_deck_pointers) begin
        draw_pointer <= 0;
        load_pointer <= 0;
        discard_pointer <= 0;
      end else begin
        case(memory_controller)
          OPERATION_IDLE: begin
          end
          OPERATION_DRAW_CARD: begin
            if(!deck_empty) draw_pointer <= draw_pointer + 1;
          end
          OPERATION_LOAD_CARD: begin
            if(load_pointer < `DECK_SIZE) begin
              deck[load_pointer] <= card_in;
              load_pointer <= load_pointer + 1;
            end
          end
          OPERATION_DISCARD_CARD: begin
            if(discard_pointer < `DISCARD_SIZE) begin
              discard_pile[discard_pointer] <= card_in;
              top_card_reg <= card_in;
              discard_pointer <= discard_pointer + 1;
            end
          end
          default: begin
          end
        endcase
      end
    end
  end
endmodule
