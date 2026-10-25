class fifo_env #(parameter DATA_WIDTH = 8, parameter DEPTH = 16);
  fifo_driver     #(DATA_WIDTH, DEPTH) drv;
  fifo_monitor    #(DATA_WIDTH, DEPTH) mon;
  fifo_scoreboard #(DATA_WIDTH, DEPTH) scb;

  mailbox #(fifo_item #(DATA_WIDTH)) drv_mbx;
  mailbox #(fifo_item #(DATA_WIDTH)) mon_mbx;
  virtual fifo_if #(DATA_WIDTH, DEPTH) vif;

  function new(virtual fifo_if #(DATA_WIDTH, DEPTH) vif);
    this.vif = vif;
    drv_mbx = new();
    mon_mbx = new();
    drv = new(vif.DRV, drv_mbx);
    mon = new(vif.MON, mon_mbx);
    scb = new(mon_mbx);
  endfunction

  task send_item(bit write_enable, bit read_enable,
                 logic [DATA_WIDTH-1:0] write_data = '0);
    fifo_item #(DATA_WIDTH) item;
    item = new();
    item.wr_en = write_enable;
    item.rd_en = read_enable;
    item.wr_data = write_data;
    drv_mbx.put(item);
  endtask

  task wait_done();
    // busy stays high until the edge that applies the last queued item.
    do begin
      @(negedge vif.clk);
    end while (drv_mbx.num() > 0 || drv.busy);
    // Give mon_cb one more sample to check the last registered read result.
    @(negedge vif.clk);
  endtask

  task drain_fifo();
    repeat (DEPTH) send_item(0, 1);
    wait_done();
  endtask

  task test_reset();
    $display("[TEST CASE 1] Reset at startup");
    drv.reset_dut();
    wait_done();
  endtask

  task test_reset_nonempty();
    $display("[TEST CASE 2] Reset while FIFO contains unread data");
    // Make dout nonzero so reset must clear both queued data and read output.
    send_item(1, 0, '1);
    send_item(0, 1);
    wait_done();
    for (int i = 0; i < DEPTH && i < 3; i++) begin
      send_item(1, 0, DATA_WIDTH'(8'h5A + i));
    end
    wait_done();
    drv.reset_dut();
    wait_done();
  endtask

  task test_burst_write_overflow();
    $display("[TEST CASE 3] Burst write to full, then overflow");
    for (int i = 0; i < DEPTH + 3; i++) begin
      send_item(1, 0, DATA_WIDTH'(8'hA5 + i));
    end
    wait_done();
  endtask

  task test_burst_read_underflow();
    $display("[TEST CASE 4] Burst read to empty, then underflow");
    repeat (DEPTH + 3) send_item(0, 1);
    wait_done();
  endtask

  task test_simultaneous_rw(int iterations = 20);
    $display("[TEST CASE 5] Simultaneous read/write at empty");
    send_item(1, 1, DATA_WIDTH'(8'hC3));
    wait_done();

    if (DEPTH > 1) begin
      $display("[TEST CASE 5] Simultaneous read/write at partial occupancy");
      for (int i = 0; i < iterations; i++) begin
        send_item(1, 1, DATA_WIDTH'(8'h31 + i));
      end
      wait_done();
    end

    // Fill every available slot before testing the full boundary.
    repeat (DEPTH) send_item(1, 0, DATA_WIDTH'(8'h7E));
    wait_done();
    $display("[TEST CASE 5] Simultaneous read/write at full");
    send_item(1, 1, DATA_WIDTH'(8'hD2));
    wait_done();
    drain_fifo();
  endtask

  task test_random_stress(int iterations = 200);
    fifo_item #(DATA_WIDTH) item;
    $display("[TEST CASE 6] Constrained random stress (%0d items)", iterations);
    repeat (iterations) begin
      item = new();
      if (!item.randomize()) begin
        $fatal(1, "Failed to randomize FIFO transaction");
      end
      drv_mbx.put(item);
    end
    wait_done();
    drain_fifo();
  endtask

  task run_all();
    fork
      drv.run();
      mon.run();
      scb.run();
    join_none

    test_reset();
    test_reset_nonempty();
    test_burst_write_overflow();
    test_burst_read_underflow();
    test_simultaneous_rw();
    test_random_stress();

    scb.report();
  endtask
endclass
