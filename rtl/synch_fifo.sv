`timescale 1ns/1ps

module sync_fifo #(
    parameter DATA_WIDTH = 8,  // 8 bit
    parameter DEPTH      = 16  // buffer size
)(
    input logic   clk,
    input logic   rstn,
    input logic   wr_en,
    input logic   [DATA_WIDTH-1:0] din,
    input logic   rd_en,
    output logic  full,
    output logic  empty,
    output logic  [DATA_WIDTH-1:0] dout,
    output logic [$clog2(DEPTH):0] count
);

localparam int PTR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;

logic [DATA_WIDTH-1:0] mem [DEPTH]; // array
logic [PTR_WIDTH-1:0] wr_ptr;
logic [PTR_WIDTH-1:0] rd_ptr;

initial begin
  if (DATA_WIDTH < 1) $fatal(1, "DATA_WIDTH must be at least 1");
  if (DEPTH < 1) $fatal(1, "DEPTH must be at least 1");
end

// Write
always_ff @(posedge clk or negedge rstn) begin
  if(!rstn) begin 
    wr_ptr <= '0;
  end else if (wr_en && !full) begin
    mem[wr_ptr] <= din;
    // Explicit wrap also supports DEPTH=1 and non-power-of-two depths.
    if (wr_ptr == DEPTH - 1) wr_ptr <= '0;
    else wr_ptr <= wr_ptr + 1'b1;
  end
end

// Read
always_ff @(posedge clk or negedge rstn) begin
  if (!rstn) begin
    rd_ptr <= '0;
    dout <= '0;
  end else if (rd_en && !empty) begin
    dout <= mem[rd_ptr];
    if (rd_ptr == DEPTH - 1) rd_ptr <= '0;
    else rd_ptr <= rd_ptr + 1'b1;
  end
end

// Counter
always_ff @(posedge clk or negedge rstn) begin
  if (!rstn) begin
    count <= '0;
  end else begin 
    case({wr_en && !full , rd_en && !empty}) 
      2'b10: count <= count + 1'b1;
      2'b01: count <= count - 1'b1;
    endcase
  end
end

assign empty = (count == 0);
assign full = (count == DEPTH);

endmodule
