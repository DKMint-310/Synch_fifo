`timescale 1ns/1ps

module sync_fifo_tb;
   parameter DATA_WIDTH = 8;
   parameter DEPTH = 16;

   logic clk;
   logic rstn;
   logic wr_en;
   logic [DATA_WIDTH-1:0] din;
   logic full;
   logic rd_en;
   logic [DATA_WIDTH-1:0] dout;
   logic empty;
   logic [$clog2(DEPTH):0] count;

   sync_fifo #(
       .DATA_WIDTH(DATA_WIDTH),
       .DEPTH(DEPTH)
   ) dut (.*);

   always #5 clk = ~clk;

   initial begin
    clk = 0;
    rstn = 0;
    wr_en = 0;
    rd_en = 0;
    din = 0;

    #20 rstn = 1;

    repeat (DEPTH) begin
      @(posedge clk);
       if (!full) begin 
         wr_en <= 1;
         din <= $random;
       end
      end
    @(posedge clk);
       wr_en = 0;
       if (full) $display("Full");
    
    
    repeat (DEPTH) begin

      @(posedge clk);
        if (!empty) begin
          rd_en <= 1;
        end
       end
      @(posedge clk);
        rd_en <= 0;
        if (empty) $display("Empty");
      
      #50;
      $finish;
    end
endmodule