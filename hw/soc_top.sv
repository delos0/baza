// Minimal SoC: CV32E40P + 8KB ISRAM + 8KB DSRAM
// No peripherals, no debug module, no crossbar.

module soc_top
  import obi_pkg::*;
(
    input logic clk_i,
    input logic rst_ni,
    output logic core_sleep_o // for test purposes rn
);

  // Synchronized reset (4-FF chain, prevents metastability)
  logic rst_ns;

  rstgen_bypass rstgen_i (
      .clk_i,
      .rst_ni,
      .rst_test_mode_ni(1'b1),
      .test_mode_i     (1'b0),
      .rst_no          (rst_ns),
      .init_no         ()
  );

  // OBI buses: core => SRAM
  obi_req_t  instr_req,  data_req;
  obi_req_t  data_req_isram, data_req_dsram; // for address mapping

  obi_resp_t instr_resp, data_resp;
  obi_resp_t isram_data_resp, dsram_data_resp; // for address mapping



  // addr[13]: 0 means ISRAM (0x0000–0x1FFF), 1 means DSRAM (0x2000–0x3FFF)
  logic data_sel;
  assign data_sel = data_req.addr[13];

  // Gate req to each SRAM based on address
  always_comb begin
    data_req_isram     = data_req;
    data_req_isram.req = data_req.req & ~data_sel;
    data_req_dsram     = data_req;
    data_req_dsram.req = data_req.req & data_sel;
  end

  // Mux response back to core
  assign data_resp.gnt    = data_sel ? dsram_data_resp.gnt    : isram_data_resp.gnt;
  assign data_resp.rvalid = data_sel ? dsram_data_resp.rvalid : isram_data_resp.rvalid;
  assign data_resp.rdata  = data_sel ? dsram_data_resp.rdata  : isram_data_resp.rdata;






  cpu_subsystem #(
      .BOOT_ADDR     (32'h0000_0000),  // boot from base of ISRAM
      .DM_HALTADDRESS(32'h0000_0000)
  ) cpu_i (
      .clk_i,
      .rst_ni           (rst_ns),
      .hart_id_i        (32'h0),
      .core_instr_req_o (instr_req),
      .core_instr_resp_i(instr_resp),
      .core_data_req_o  (data_req),
      .core_data_resp_i (data_resp),
      .irq_i            ('0),
      .irq_ack_o        (),
      .irq_id_o         (),
      .debug_req_i      (1'b0),
      .core_sleep_o     (core_sleep_o) // for testing
  );

  // 8KB instruction SRAM (2048 × 32-bit words)
  sram_obi_wrap #(.NumWords(2048)) isram_i (
      .clk_i,
      .rst_ni(rst_ns),
      .req_i (instr_req),
      .resp_o(instr_resp)
  );

  // 8KB data SRAM (2048 × 32-bit words)
  sram_obi_wrap #(.NumWords(2048)) dsram_i (
      .clk_i,
      .rst_ni(rst_ns),
      /*
      .req_i (data_req),
      .resp_o(data_resp)
      */
      .req_i (data_req_dsram),
      .resp_o(dsram_data_resp)

  );

endmodule
