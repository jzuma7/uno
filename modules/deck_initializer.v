`include "../include/card_definitions.vh"
`include "../include/memory_definitions.vh"

module deck_initializer(
  input clock,
  input reset,
  output done,
  output write_enable,
  output [5:0] card_out
);

  localparam STATE_DONE = 2'b10;
  localparam STATE_GENERATING = 2'b01;

  reg  done_reg;
  reg  write_enable_reg;
  reg [1:0] state;
  reg [5:0] card_out_reg;
  reg [6:0] card_counter;

  assign done = done_reg;
  assign write_enable = write_enable_reg;
  assign card_out = card_out_reg;

  reg [1:0]  color;
  reg [6:0]  position;
  reg [3:0]  card_value;

  always @ (*) begin
    // Cor baseada no card_counter (blocos de 25 cartas por cor)
    if (card_counter < 7'd25)
      color = `COLOR_RED;
    else if (card_counter < 7'd50)
      color = `COLOR_GREEN;
    else if (card_counter < 7'd75)
      color = `COLOR_BLUE;
    else
      color = `COLOR_YELLOW;

    // Posição dentro do grupo de cor (0 a 24)
    if (card_counter < 7'd25)
      position = card_counter;
    else if (card_counter < 7'd50)
      position = card_counter - 7'd25;
    else if (card_counter < 7'd75)
      position = card_counter - 7'd50;
    else if (card_counter < 7'd100)
      position = card_counter - 7'd75;
    else
      position = 7'd0;

    // Valor baseado na posição dentro do grupo:
    //   posição  0        → 0       (1 carta)
    //   posições 1  a 2  → 1       (2 cartas)
    //   posições 3  a 4  → 2       (2 cartas)
    //   posições 5  a 6  → 3       (2 cartas)
    //   posições 7  a 8  → 4       (2 cartas)
    //   posições 9  a 10 → 5       (2 cartas)
    //   posições 11 a 12 → 6       (2 cartas)
    //   posições 13 a 14 → 7       (2 cartas)
    //   posições 15 a 16 → 8       (2 cartas)
    //   posições 17 a 18 → 9       (2 cartas)
    //   posições 19 a 20 → Skip    (2 cartas)
    //   posições 21 a 22 → Reverse (2 cartas)
    //   posições 23 a 24 → DrawTwo (2 cartas)
    if (position == 7'd0)
      card_value = 4'd0;
    else if (position <= 7'd2)
      card_value = 4'd1;
    else if (position <= 7'd4)
      card_value = 4'd2;
    else if (position <= 7'd6)
      card_value = 4'd3;
    else if (position <= 7'd8)
      card_value = 4'd4;
    else if (position <= 7'd10)
      card_value = 4'd5;
    else if (position <= 7'd12)
      card_value = 4'd6;
    else if (position <= 7'd14)
      card_value = 4'd7;
    else if (position <= 7'd16)
      card_value = 4'd8;
    else if (position <= 7'd18)
      card_value = 4'd9;
    else if (position <= 7'd20)
      card_value = `VALUE_SKIP;
    else if (position <= 7'd22)
      card_value = `VALUE_REVERSE;
    else
      card_value = `VALUE_DRAW_TWO;

    // Carta final: wilds não têm cor
    if (card_counter >= 7'd104)
      card_out_reg = {2'b00, `VALUE_WILD_DRAW_FOUR};
    else if (card_counter >= 7'd100)
      card_out_reg = {2'b00, `VALUE_WILD};
    else
      card_out_reg = {color, card_value};

    write_enable_reg = (state == STATE_GENERATING);
  end

  always @ (posedge clock) begin
    if(reset) begin
      state <= STATE_GENERATING;
      card_counter <= 7'd0;
      done_reg <= 1'b0;
    end else begin
      case(state)
        STATE_GENERATING: begin
          if(card_counter == 7'd107) begin
            state <= STATE_DONE;
          end else begin
            card_counter <= card_counter + 7'd1;
          end
        end
        STATE_DONE: begin
            done_reg <= 1'b1;
          end
        default: state <= STATE_GENERATING;
      endcase
    end
  end
endmodule
