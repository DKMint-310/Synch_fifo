class fifo_item #(parameter DATA_WIDTH = 8);
  rand logic                  wr_en;
  rand logic                  rd_en;
  rand logic [DATA_WIDTH-1:0] wr_data;

  logic                       rst_n;
  logic [DATA_WIDTH-1:0]      rd_data;
  logic                       full;
  logic                       empty;
  int unsigned                count;

  function void print(string tag = "");
    $display("[%s] @%0t | wr_en=%0b wr_data=0x%02h | rd_en=%0b rd_data=0x%02h | full=%0b empty=%0b", 
             tag, $time, wr_en, wr_data, rd_en, rd_data, full, empty);
  endfunction

  // Bare member access avoids the XSIM 2024.2 .empty elaboration issue.
  function logic get_empty();
    return empty;
  endfunction

  function void set_empty(logic value);
    empty = value;
  endfunction

endclass
