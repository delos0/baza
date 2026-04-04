// Extracted from x-heep memory_subsystem.sv
// Single-bank OBI wrapper around sram_wrapper

module sram_obi_wrap
  import obi_pkg::*;
#(
    parameter int unsigned NumWords  = 32'd2048,  // 8KB, 32-bit words
    parameter int unsigned DataWidth = 32'd32,
    parameter int unsigned AddrWidth = $clog2(NumWords)
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  obi_req_t  req_i,
    output obi_resp_t resp_o
);

  logic ram_valid_q;
  logic [AddrWidth-1:0] ram_addr;

  assign ram_addr   = req_i.addr[AddrWidth+1:2];

  // SRAM always accepts, gnt is hardwired 1
  assign resp_o.gnt = 1'b1;

  // rvalid is gnt delayed one cycle
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) ram_valid_q <= 1'b0;
    // else         ram_valid_q <= resp_o.gnt;  // BUG: gnt=1 always → rvalid stuck high
  else         ram_valid_q <= req_i.req;
  end
  assign resp_o.rvalid = ram_valid_q;

  sram_wrapper #(
      .NumWords (NumWords),
      .DataWidth(DataWidth)
  ) sram_i (
      .clk_i,
      .rst_ni,
      .req_i           (req_i.req),
      .we_i            (req_i.we),
      .addr_i          (ram_addr),
      .wdata_i         (req_i.wdata),
      .be_i            (req_i.be),
      .pwrgate_ni      (1'b1),
      .pwrgate_ack_no  (),
      .set_retentive_ni(1'b1),
      .rdata_o         (resp_o.rdata)
  );

endmodule
