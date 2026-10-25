`timescale 1ns/1ps

module synch_fifo_tb;
  import fifo_pkg::*;

  parameter DATA_WIDTH = 8;
  parameter DEPTH      = 16;
  localparam CLK_PERIOD = 10;
  localparam MAX_CYCLES = 10000 + 20 * DEPTH;

  logic clk;

  // 1. Clock Generation
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // 2. Interface Instantiation
  fifo_if #(DATA_WIDTH, DEPTH) _if(clk);

  // 3. DUT Instantiation
  sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
  ) dut (
    .clk     (_if.clk),
    .rstn    (_if.rst_n),
    .wr_en   (_if.wr_en),
    .rd_en   (_if.rd_en),
    .din     (_if.wr_data),
    .dout    (_if.rd_data),
    .full    (_if.full),
    .empty   (_if.empty),
    .count   (_if.count)
  );

  // 4. Test execution
  initial begin
    fifo_env #(DATA_WIDTH, DEPTH) env;
    env = new(_if);
    env.run_all();
    $finish;
  end

  initial begin
    repeat (MAX_CYCLES) @(posedge clk);
    $fatal(1, "[TIMEOUT] Test did not complete after %0d clocks", MAX_CYCLES);
  end

  // 5. Dump Waveform
  initial begin
    $dumpfile("fifo_tb.vcd");
    $dumpvars(0, synch_fifo_tb);
  end
endmodule
