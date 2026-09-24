class fifo_monitor #(parameter DATA_WIDTH = 8);
  virtual fifo_if #(DATA_WIDTH).MON vif;
  mailbox #(fifo_item #(DATA_WIDTH)) mon_mbx;

  function new(virtual fifo_if #(DATA_WIDTH).MON vif, mailbox #(fifo_item #(DATA_WIDTH)) mon_mbx);
    this.vif = vif;
    this.mon_mbx = mon_mbx;
  endfunction

  task run();
    fifo_item #(DATA_WIDTH) item;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.rst_n) begin
        item = new();
        item.wr_en   = vif.mon_cb.wr_en;
        item.rd_en   = vif.mon_cb.rd_en;
        item.wr_data = vif.mon_cb.wr_data;
        item.rd_data = vif.mon_cb.rd_data;
        item.full    = vif.mon_cb.full;
        item.empty   = vif.mon_cb.empty;
        mon_mbx.put(item);
      end
    end
  endtask
endclass