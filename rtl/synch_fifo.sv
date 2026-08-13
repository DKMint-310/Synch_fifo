'timescale 1ns/1ps

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
    output logic [$clog2(DEPTH:0)] count
);

logic [DATA_WIDTH-1:0] mem [DEPTH] // array

logic [$clog2(DEPTH)-1:0] wr_ptr; 
logic [$clog2(DEPTH)-1:0] rd_ptr;

// Write
always_ff @(posedge clk or negedge rstn) begin
  if(!rstn) begin 
    wr_ptr <= '0;
  end else if (wr_en && !full) begin
    mem[wr_ptr] <= din;
    wr_ptr <= wr_ptr + 1'b1;
  end
end

// Read
always_ff @(posedge clk or negedge rstn) begin
  if (!rstn) begin
    rd_en <= 0;
    dout <= 0;
  end else if (rd_en && !empty)
    dout <= mem[rd_ptr];
    rd_ptr <= rd_ptr + 1'b1;
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
      default: count <= count;
    endcase
  end
end

assign empty = (count == 0);
assign full = (count == DEPTH);

endmodule