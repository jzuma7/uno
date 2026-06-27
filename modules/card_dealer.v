module card_dealer(
  input clock,
  input reset,
  input start,
  input [5:0] read_data,
  input [2:0] cards_to_deal, // número de cartas a serem distribuidas

  output done,
  output write_enable,
  output [1:0] memory_controller, // WARNING: pode ter conflito com o fsm principal
  output [5:0] card_out
);

  localparam STATE_IDLE = 2'b00;
  localparam STATE_DEALING = 2'b01;
  localparam STATE_DONE = 2'b10;

  reg [1:0] state;
  reg [2:0] deal_counter;

  assign card_out = read_data;
  assign done = (state == STATE_DONE);
  assign memory_controller = (state == STATE_DEALING) ? 2'b01 : 2'b00;
  assign write_enable = (state == STATE_DEALING);

  always @ (posedge clock) begin
    if(reset) begin
      state <= STATE_IDLE;
      deal_counter <= 0;
    end else begin
      case(state)
        STATE_IDLE: begin
          if(start) begin
            state <= STATE_DEALING;
            deal_counter <= 0;
          end
        end
        STATE_DEALING: begin
          deal_counter <= deal_counter + 1;
          if(deal_counter == cards_to_deal - 1)
            state <= STATE_DONE;
        end
        STATE_DONE: begin
          state <= STATE_IDLE;
        end
        default: begin
          state <= STATE_IDLE;
        end
      endcase
    end
  end
endmodule
