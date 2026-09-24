class fifo_driver #(parameter DATA_WIDTH = 8);
  virtual fifo_if #(DATA_WIDTH).DRV vif;
  mailbox #(fifo_item #(DATA_WIDTH)) drv_mbx;

  function new(virtual fifo_if #(DATA_WIDTH).DRV vif, mailbox #(fifo_item #(DATA_WIDTH)) drv_mbx);
    this.vif = vif;
    this.drv_mbx = drv_mbx;
  endfunction
  
  task reset_dut();
    vif.drv_cb.rst_n   <= 1'b0;
    vif.drv_cb.wr_en   <= 1'b0;
    vif.drv_cb.rd_en   <= 1'b0;
    vif.drv_cb.wr_data <= '0;
    repeat (3) @(vif.drv_cb);
    vif.drv_cb.rst_n   <= 1'b1;
    @(vif.drv_cb);
  endtask

  task run();
    fifo_item #(DATA_WIDTH) item;
    forever begin
      drv_mbx.get(item);
      @(vif.drv_cb);
      vif.drv_cb.wr_en   <= item.wr_en;
      vif.drv_cb.rd_en   <= item.rd_en;
      vif.drv_cb.wr_data <= item.wr_data;
    end
  endtask
endclass