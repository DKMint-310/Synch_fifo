class fifo_driver #(parameter DATA_WIDTH = 8, parameter DEPTH = 16);
  virtual fifo_if #(DATA_WIDTH, DEPTH).DRV vif;
  mailbox #(fifo_item #(DATA_WIDTH)) drv_mbx;

  bit busy = 0;
  bit reset_active = 1;

  function new(virtual fifo_if #(DATA_WIDTH, DEPTH).DRV vif, mailbox #(fifo_item #(DATA_WIDTH)) drv_mbx);
    this.vif = vif;
    this.drv_mbx = drv_mbx;
  endfunction

  task reset_dut();
    // Stop run() before either task writes clocking outputs.
    reset_active = 1;
    busy = 0;
    vif.drv_cb.rst_n   <= 1'b0;
    vif.drv_cb.wr_en   <= 1'b0;
    vif.drv_cb.rd_en   <= 1'b0;
    vif.drv_cb.wr_data <= '0;
    repeat (3) @(vif.drv_cb);
    vif.drv_cb.rst_n   <= 1'b1;
    @(vif.drv_cb);
    reset_active = 0;
  endtask

  task run();
    fifo_item #(DATA_WIDTH) item;
    forever begin
      @(vif.drv_cb);
      if (!reset_active) begin
        // One queued item drives one cycle; no item means idle.
        busy = drv_mbx.try_get(item);
        if (busy) begin
          vif.drv_cb.wr_en   <= item.wr_en;
          vif.drv_cb.rd_en   <= item.rd_en;
          vif.drv_cb.wr_data <= item.wr_data;
        end else begin
          // An empty mailbox must not repeat the last active command.
          vif.drv_cb.wr_en   <= 1'b0;
          vif.drv_cb.rd_en   <= 1'b0;
          vif.drv_cb.wr_data <= '0;
        end
      end
    end
  endtask
endclass
