class fifo_scoreboard #(parameter DATA_WIDTH = 8, parameter DEPTH = 16);
  mailbox #(fifo_item #(DATA_WIDTH)) mon_mbx;
  logic [DATA_WIDTH-1:0] expected_queue[$];
  logic [DATA_WIDTH-1:0] expected_rd_data = '0;
  int unsigned error_count = 0;
  int unsigned read_count = 0;

  function new(mailbox #(fifo_item #(DATA_WIDTH)) mon_mbx);
    this.mon_mbx = mon_mbx;
  endfunction

  function void fail(string message);
    error_count++;
    $error("[SCB FAIL] @%0t: %s", $time, message);
  endfunction

  function void check_outputs(fifo_item #(DATA_WIDTH) item);
    int unsigned expected_count;
    logic expected_full;
    logic expected_empty;

    expected_count = expected_queue.size();
    expected_full = (expected_count == DEPTH);
    expected_empty = (expected_count == 0);

    if (item.count !== expected_count)
      fail($sformatf("Count mismatch: expected %0d, got %0d", expected_count, item.count));
    if (item.full !== expected_full)
      fail($sformatf("Full mismatch: expected %0b, got %0b", expected_full, item.full));
    if (item.get_empty() !== expected_empty)
      fail($sformatf("Empty mismatch: expected %0b, got %0b", expected_empty, item.get_empty()));
    if (item.rd_data !== expected_rd_data)
      fail($sformatf("Read data mismatch: expected 0x%0h, got 0x%0h", expected_rd_data, item.rd_data));
  endfunction

  task run();
    fifo_item #(DATA_WIDTH) item;
    int unsigned pre_count;
    bit accept_write;
    bit accept_read;

    forever begin
      mon_mbx.get(item);

      if (item.rst_n === 1'b0) begin
        // Reset clears the FIFO model and its registered output.
        expected_queue.delete();
        expected_rd_data = '0;
        check_outputs(item);
      end else if (item.rst_n === 1'b1) begin
        // Samples are taken before this edge. The registered output therefore
        // belongs to the previous edge, including its value on idle cycles.
        check_outputs(item);

        if ((item.wr_en !== 1'b0) && (item.wr_en !== 1'b1))
          fail("wr_en contains X/Z");
        if ((item.rd_en !== 1'b0) && (item.rd_en !== 1'b1))
          fail("rd_en contains X/Z");

        // Both permissions use occupancy BEFORE either operation. At full,
        // simultaneous read/write accepts only the read; at empty, only write.
        pre_count = expected_queue.size();
        accept_write = (item.wr_en === 1'b1) && (pre_count < DEPTH);
        accept_read = (item.rd_en === 1'b1) && (pre_count > 0);

        if (accept_read) begin
          // Save this edge's read result for the NEXT monitor sample.
          expected_rd_data = expected_queue.pop_front();
          read_count++;
        end
        if (accept_write) begin
          if (^item.wr_data === 1'bx)
            fail("Accepted write data contains X/Z");
          expected_queue.push_back(item.wr_data);
        end
      end else begin
        fail("rst_n contains X/Z");
      end
    end
  endtask

  function void report();
    if (expected_queue.size() != 0)
      fail("FIFO was not drained before reporting");
    $display(" Accepted reads         : %0d", read_count);
    $display(" Errors Found           : %0d", error_count);

    if (error_count != 0 || read_count == 0)
      $fatal(1, "TEST FAILED: errors found or no accepted reads");
    $display(" STATUS                 : TEST PASSED");
    $display("=======================================================\n");
  endfunction
endclass
