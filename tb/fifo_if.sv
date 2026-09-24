`timescale 1ns/1ps

interface fifo_if #(parameter DATA_WIDTH = 8) (input logic clk);
  logic                  rst_n;
  logic                  wr_en;
  logic                  rd_en;
  logic [DATA_WIDTH-1:0] wr_data;
  logic [DATA_WIDTH-1:0] rd_data;
  logic                  full;
  logic                  empty;

  clocking drv_cb @(posedge clk);
    default input #1step output #1ns; 
    output rst_n, wr_en, rd_en, wr_data;
    input  full, empty, rd_data;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst_n, wr_en, rd_en, wr_data, rd_data, full, empty;
  endclocking

  modport DRV(clocking drv_cb);
  modport MON(clocking mon_cb); 
endinterface