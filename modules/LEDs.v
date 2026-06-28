module leds(
    input win,
    input lose,
    input skip_action,
    input draw_action,
    input cpu_turn,
    input player_turn,
    input clk,
    input rst,
    output reg [8:0] led_green,
    output reg [17:0] led_red
    
);

always @(posedge clk or negedge rst) begin
    if (rst == 0 ) begin
        led_green <= 9'b0;
        led_red <= 18'b0;
    end else begin
        if (win) begin
            led_green <= 9'b111111111;
            led_red <= 18'b0;
        end else if (lose) begin
            led_green  <= 9'b0;
            led_red <= 18'b111111111111111111;
        end else if (skip_action) led_red[0] <= 1'b1;
            else if (draw_action) led_red[1] <= 1'b1;
            else if (player_turn) led_green[0] <= 1'b1;
            else if (cpu_turn) led_green[1] <= 1'b1;
        else begin
            led_green <= 9'b0;
            led_red <= 18'b0;
        end
    end            
            
end
endmodule