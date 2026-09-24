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

    //Tc1: Write
    repeat (DEPTH) begin
      @(posedge clk);
       if (!full) begin 
         wr_en <= 1;
         din <= $random;
       end
      end
    @(posedge clk);
       wr_en <= 0;
    
    //Tc2: Write while full
    @(posedge clk);
      wr_en <= 1;
      din <= 1;
    @(posedge clk);
      wr_en <= 0;

    #1 assert(full == 1 && count == 16)
     else $error("TC2 failed);

    //Tc3: Read
    repeat (DEPTH) begin

      @(posedge clk);
        if (!empty) begin
          rd_en <= 1;
        end
       end
      @(posedge clk);
        rd_en <= 0;
        if (empty) $display("Empty");
    
    //Tc4: Read while empty
    @(posedge clk);
      rd_en <= 1;
    @(posedge clk);
      rd_en <= 0;
    #1 assert(empty == 1 && count == 0)
      else $error("TC4 failed");

      #50;
      $finish;
      $stop;
    end

  
endmodule