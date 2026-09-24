class fifo_item #(parameter DATA_WIDTH = 8);
  rand logic                  wr_en;
  rand logic                  rd_en;
  rand logic [DATA_WIDTH-1:0] wr_data;

  logic [DATA_WIDTH-1:0]      rd_data;
  logic                       full;
  logic                       empty;

  constraint c_wr_rd_dist {
    wr_en dist {1 := 50, 0 := 50};
    rd_en dist {1 := 50, 0 := 50};
  }

  function void print(string tag = "");
    $display("[%s] @%0t | wr_en=%0b wr_data=0x%02h | rd_en=%0b rd_data=0x%02h | full=%0b empty=%0b", 
             tag, $time, wr_en, wr_data, rd_en, rd_data, full, empty);
  endfunction

  function fifo_item copy();
    fifo_item cp = new();
    cp.wr_en   = this.wr_en;
    cp.rd_en   = this.rd_en;
    cp.wr_data = this.wr_data;
    cp.rd_data = this.rd_data;
    cp.full    = this.full;
    cp.empty   = this.empty;
    return cp;
  endfunction
endclass