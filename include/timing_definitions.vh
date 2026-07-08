`ifdef SIM_FAST
  // valores reduzidos só para simulação rápida (ModelSim/Icarus com +define+SIM_FAST)
  // -- nunca usados na síntese real do Quartus, que não define SIM_FAST.
  `define TWO_SECONDS_CLOCK  32'd20
  `define DEBOUNCE_THRESHOLD 20'd8
`else
  `define TWO_SECONDS_CLOCK  32'd100_000_000  // 2 segundos a 50 MHz
  `define DEBOUNCE_THRESHOLD 20'd999_999      // 20 ms a 50 MHz
`endif
