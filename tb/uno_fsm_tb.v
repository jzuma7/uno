`default_nettype none
`timescale 1ps/1ps

module uno_fsm_tb;
    reg clock_tb;
    reg [3:0] KEY_tb;
    wire [6:0] HEX0_tb, HEX1_tb, HEX2_tb, HEX3_tb, HEX4_tb, HEX5_tb, HEX6_tb, HEX7_tb;
    wire [17:0] LEDR_tb;
    wire [8:0] LEDG_tb;
    wire win_tb;
    wire lose_tb;


    uno_fsm DUT(
        .CLOCK_50 (clock_tb),
        .KEY (KEY_tb),
        .HEX0 (HEX0_tb),
        .HEX1 (HEX1_tb),
        .HEX2 (HEX2_tb),
        .HEX3 (HEX3_tb),
        .HEX4 (HEX4_tb),
        .HEX5 (HEX5_tb),
        .HEX6 (HEX6_tb),
        .HEX7 (HEX7_tb),
        .LEDR (LEDR_tb),
        .LEDG (LEDG_tb),
        .win  (win_tb),
        .lose (lose_tb)
    );

    localparam  CLK_PERIOD = 10;
    always #(CLK_PERIOD) clock_tb = ~clock_tb;

    // buttons_interface.v só aceita a mudança depois de `DEBOUNCE_THRESHOLD`
    // ciclos de divergência constante entre ~key_raw e debounced_* -- ou seja,
    // precisa de DEBOUNCE_THRESHOLD+1 bordas de clock com o botão parado num
    // estado para o debounce disparar. Isso vale tanto para pressionar quanto
    // para soltar. Compile com +define+SIM_FAST para reduzir esse valor (e o
    // TWO_SECONDS_CLOCK usado pela led_interface/cpu_hand) só para simulação
    // rápida -- a síntese real no Quartus nunca define SIM_FAST.
`ifdef SIM_FAST
    localparam DEBOUNCE_CYCLES = 10;
`else
    localparam DEBOUNCE_CYCLES = 1_000_000;
`endif

    task press_buton(input integer btn_idx);
        begin
        @(posedge clock_tb);
        KEY_tb[btn_idx] = 1'b0;

        repeat(DEBOUNCE_CYCLES) @(posedge clock_tb);
        KEY_tb[btn_idx] = 1'b1;

        repeat(DEBOUNCE_CYCLES) @(posedge clock_tb);
        end
    endtask
    integer tentativas;

    initial begin
        $dumpfile("uno_fsm_tb.vcd");
        $dumpvars(0, uno_fsm_tb);
        clock_tb = 0;
        KEY_tb = 4'b1111;

        $display("\n[TEMPO: %0t] Ligando placa e aplicando RESET...", $time);

        KEY_tb[0] = 1'b0;

        repeat(DEBOUNCE_CYCLES) @(posedge clock_tb);

        KEY_tb[0] = 1'b1;

        repeat(DEBOUNCE_CYCLES) @(posedge clock_tb);
            // win/lose vêm direto das portas dedicadas da uno_fsm -- não
            // precisa mais decodificar LEDG/LEDR (que só existem para a
            // placa física e ficam latched por >=2s, sem servir de flag
            // confiável de fim de jogo no testbench).
            // Turno do player lido direto de DUT.player_turn_signal (sinal
            // interno da uno_fsm), não de LEDR_tb[0]: o LED fica latched por
            // >=2s (requisito da placa física), então continua em 1 por
            // muito tempo depois que o estado real já saiu de
            // STATE_PLAYER_TURN. Usar o LED aqui faria o testbench continuar
            // tentando PLAY/SELECT/DRAW bem depois do turno real ter
            // terminado (no-op, mas mascara o estado real da FSM).
            while (!win_tb && !lose_tb) begin
            if (DUT.player_turn_signal == 1'b1) begin // Se é o turno do jogador
                tentativas = 0;
                $display("\nJogador esta analisando a mao...");
                while (DUT.player_turn_signal == 1'b1 && tentativas < 20) begin
                    press_buton(2);
                    if (DUT.player_turn_signal == 1'b1) begin
                        press_buton(1);
                        tentativas = tentativas + 1;
                    end
                end
                if (DUT.player_turn_signal == 1'b1) begin
                    $display("Jogador nao tem carta valida. Comprando (DRAW)...");
                    press_buton(3);
                end

            end else begin
                @(posedge clock_tb);
            end
        end

        $display("\n==================================================");
        $display("                  FIM DE JOGO!");
        if (win_tb) begin
            $display("   RESULTADO: O JOGADOR VENCEU A PARTIDA! (WIN)");
        end else if (lose_tb) begin
            $display("   RESULTADO: A CPU VENCEU A PARTIDA! (LOSE)");
        end
        $display("==================================================");

        #500 $stop;
    end

endmodule
`default_nettype wire
