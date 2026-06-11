module memoria_uno (
    input clk,               
    input reset,            
    input [1:0] mem_ctrl,    // Interface de controle 
    input [6:0] addr,        // garante 108 posições do baralho
    input [7:0] card_in,     
    output reg [7:0] card_out 
);

    // Memória para 108 cartas 
    reg [7:0] ram [0:107]; 
    integer i;

    //limpa memória caso reset 
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 108; i = i + 1) begin
                ram[i] <= 8'b00000000;
            end
            card_out <= 8'b00000000;
        end 
        else begin
            case (mem_ctrl)
                2'b01: begin // Dá valor as cartas, proveniente do embaralhador
                    ram[addr] <= card_in;
                end
                
                2'b10: begin // Utilizado ao "Cavar" carta
                    if (ram[addr] != 8'b0) begin
                        card_out <= ram[addr];
                        //  Remove a carta da memória após a leitura
                        // para evitar duplicatas ou cartas infinitas
                        ram[addr] <= 8'b00000000; 
                    end
                    else begin
                        card_out <= 8'b00000000;
                    end
                end
                
                default: begin
                    card_out <= 8'b0;
                end
            endcase
        end
    end

endmodule
