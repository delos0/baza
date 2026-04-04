// Top-level testbench wrapper for Verilator.
// Drives clock/reset from sim_main.cpp; preloads ISRAM via $readmemh.

module tb (
    input  logic clk_i,
    input  logic rst_ni,
    output logic core_sleep_o
);

  soc_top dut (
      .clk_i,
      .rst_ni,
      .core_sleep_o
  );

  // Preload firmware into ISRAM before simulation starts.
  // Path: dut (soc_top) → isram_i (sram_obi_wrap) → sram_i (sram_wrapper) → tc_ram_i (tc_sram) → sram[]
  initial begin
    $readmemh("sw/firmware.hex", dut.isram_i.sram_i.tc_ram_i.sram);
  end

endmodule
