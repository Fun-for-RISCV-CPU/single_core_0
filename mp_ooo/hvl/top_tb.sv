module top_tb;

  timeunit 1ps; timeprecision 1ps;

  int clock_half_period_ps = 5;

  bit clk;
  always #(clock_half_period_ps) clk = ~clk;

  bit rst;

  int timeout = 1000;  // in cycles, change according to your needs

  // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
  mem_itf mem_itf_i (.*);
  mem_itf mem_itf_d (.*);
  magic_dual_port mem (
      .itf_i(mem_itf_i),
      .itf_d(mem_itf_d)
  );

  // Single memory port connection when caches are integrated into design (CP3 and after)
  /*
    bmem_itf bmem_itf(.*);
    blocking_burst_memory burst_memory(.itf(bmem_itf));
    */
  bmem_itf bmem_itf (.*);

  mon_itf mon_itf (.*);
  //   monitor monitor (.itf(mon_itf));

  cpu dut (
      .clk(clk),
      .rst(rst),

      // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
      .imem_addr (mem_itf_i.addr),
      .imem_rmask(mem_itf_i.rmask),
      .imem_rdata(mem_itf_i.rdata),
      .imem_resp (mem_itf_i.resp),

      .dmem_addr (mem_itf_d.addr),
      .dmem_rmask(mem_itf_d.rmask),
      .dmem_wmask(mem_itf_d.wmask),
      .dmem_rdata(mem_itf_d.rdata),
      .dmem_wdata(mem_itf_d.wdata),
      .dmem_resp (mem_itf_d.resp)

      // Single memory port connection when caches are integrated into design (CP3 and after)
      /*
        .bmem_addr      (bmem_itf.addr),
        .bmem_read      (bmem_itf.read),
        .bmem_write     (bmem_itf.write),
        .bmem_rdata     (bmem_itf.rdata),
        .bmem_wdata     (bmem_itf.wdata),
        .bmem_resp      (bmem_itf.resp)
        */

  );

  // localparam SUPERSCALAR = 1;
  // logic [31:0] instr_tail[SUPERSCALAR];
  // logic instr_valid_out[SUPERSCALAR];

  logic [31:0] instr_tail;
  logic instr_valid_out;

  assign instr_tail = dut.instr;
  assign instr_valid_out = dut.instr_valid_out;

  task automatic do_reset();
    rst <= 1'b1;
    repeat (4) @(posedge clk);
    rst <= 1'b0;
  endtask : do_reset

  task automatic instr_queue_test();
    logic PASSED = 1'b1;
    @(posedge clk iff instr_valid_out[0]);
    if (instr_tail[0] != 32'h00400093) begin
      $display("Instruction %d failed assertion", 0);
    end
    repeat (50) @(posedge clk);
  endtask

  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, "+all");
    do_reset();
    instr_queue_test();
    repeat (10) @(posedge clk);
    $finish;
  end

  //   `include "../../hvl/rvfi_reference.svh"

  //   initial begin
  //     $fsdbDumpfile("dump.fsdb");
  //     $fsdbDumpvars(0, "+all");
  //     rst = 1'b1;
  //     repeat (2) @(posedge clk);
  //     rst <= 1'b0;
  //   end

  //   always @(posedge clk) begin
  //     if (mon_itf.halt) begin
  //       $finish;
  //     end
  //     if (timeout == 0) begin
  //       $error("TB Error: Timed out");
  //       $finish;
  //     end
  //     if (mon_itf.error != 0) begin
  //       repeat (5) @(posedge clk);
  //       $finish;
  //     end
  //     if (mem_itf_i.error != 0) begin
  //       repeat (5) @(posedge clk);
  //       $finish;
  //     end
  //     if (mem_itf_d.error != 0) begin
  //       repeat (5) @(posedge clk);
  //       $finish;
  //     end
  //     timeout <= timeout - 1;
  //   end

endmodule
