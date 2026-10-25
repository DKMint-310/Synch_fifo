class fifo_monitor #(parameter DATA_WIDTH = 8, parameter DEPTH = 16);
  virtual fifo_if #(DATA_WIDTH, DEPTH).MON vif;
  mailbox #(fifo_item #(DATA_WIDTH)) mon_mbx;
  bit reset_seen = 0;

  function new(virtual fifo_if #(DATA_WIDTH, DEPTH).MON vif, mailbox #(fifo_item #(DATA_WIDTH)) mon_mbx);
    this.vif = vif;
    this.mon_mbx = mon_mbx;
  endfunction

  task run();
    fifo_item #(DATA_WIDTH) item;
    forever begin
      @(vif.mon_cb);
      // Clocking outputs assert the first reset after the first clock edge.
      // Arm at its first low sample; all later X/Z states are checked.
      if (!reset_seen) begin
        if (vif.mon_cb.rst_n !== 1'b0) continue;
        reset_seen = 1;
      end
      item = new();
      item.rst_n   = vif.mon_cb.rst_n;
      item.wr_en   = vif.mon_cb.wr_en;
      item.rd_en   = vif.mon_cb.rd_en;
      item.wr_data = vif.mon_cb.wr_data;
      item.rd_data = vif.mon_cb.rd_data;
      item.full    = vif.mon_cb.full;
      item.set_empty(vif.mon_cb.sampled_empty);
      item.count   = vif.mon_cb.count;
      // Reset cycles are observations too: the scoreboard must clear its model.
      mon_mbx.put(item);
    end
  endtask
endclass
