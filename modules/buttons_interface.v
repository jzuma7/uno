module buttons_interface(
  input clock,
  input [3:0] key_raw,

  output draw,
  output play,
  output reset,
  output select
);

  // canal KEY[0] — reset
  reg debounced_reset;
  reg [19:0] counter_reset;

  // canal KEY[1] — select
  reg debounced_select;
  reg previous_select;
  reg [19:0] counter_select;

  // canal KEY[2] — play
  reg debounced_play;
  reg previous_play;
  reg [19:0] counter_play;

  // canal KEY[3] — draw
  reg debounced_draw;
  reg previous_draw;
  reg [19:0] counter_draw;

  assign reset = debounced_reset;
  assign play = debounced_play && !previous_play;
  assign draw = debounced_draw && !previous_draw;
  assign select = debounced_select && !previous_select;

  // KEY[0] — reset (nível contínuo, sem edge detection)
  always @ (posedge clock) begin
    if (~key_raw[0] != debounced_reset) begin
      if (counter_reset == 20'd999_999) begin
        debounced_reset <= ~key_raw[0];
        counter_reset   <= 0;
      end else
        counter_reset <= counter_reset + 1;
    end else
      counter_reset <= 0;
  end

  // KEY[1] — select
  always @ (posedge clock) begin
    previous_select <= debounced_select;
    if (~key_raw[1] != debounced_select) begin
      if (counter_select == 20'd999_999) begin
        debounced_select <= ~key_raw[1];
        counter_select   <= 0;
      end else
        counter_select <= counter_select + 1;
    end else
      counter_select <= 0;
  end

  // KEY[2] — play
  always @ (posedge clock) begin
    previous_play <= debounced_play;
    if (~key_raw[2] != debounced_play) begin
      if (counter_play == 20'd999_999) begin
        debounced_play <= ~key_raw[2];
        counter_play   <= 0;
      end else
        counter_play <= counter_play + 1;
    end else
      counter_play <= 0;
  end

  // KEY[3] — draw
  always @(posedge clock) begin
    previous_draw <= debounced_draw;
    if (~key_raw[3] != debounced_draw) begin
      if (counter_draw == 20'd999_999) begin
        debounced_draw <= ~key_raw[3];
        counter_draw   <= 0;
      end else
        counter_draw <= counter_draw + 1;
    end else
      counter_draw <= 0;
  end


endmodule
