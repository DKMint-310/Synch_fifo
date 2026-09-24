class fifo_scoreboard #(parameter DATA_WIDTH = 8, parameter DEPTH = 16);
  mailbox #(fifo_item #(DATA_WIDTH)) mon_mbx;
  logic [DATA_WIDTH-1:0] expected_queue[$];

  int match_count = 0;
  int error_count = 0;

  function new(mailbox #(fifo_item #(DATA_WIDTH)) mon_mbx);
    this.mon_mbx = mon_mbx;
  endfunction

  task run();
    fifo_item #(DATA_WIDTH) item;
    logic [DATA_WIDTH-1:0] expected_data;

    forever begin
      mon_mbx.get(item);

      // 1. Check flag
      if (expected_queue.size() == 0 && !item.empty) begin
        $error("[SCB FAIL] @%0t: FIFO empty but empty flag = 0", $time);
        error_count++;
      end
      if (expected_queue.size() == DEPTH && !item.full) begin
        $error("[SCB FAIL] @%0t: FIFO full but full flag = 0", $time);
        error_count++;
      end

      // 2. Read
      if (item.rd_en) begin
        if (expected_queue.size() > 0) begin
          expected_data = expected_queue.pop_front();
          if (item.rd_data === expected_data) begin
            match_count++;
          end else begin
            $error("[SCB FAIL] @%0t: Data mismatch! Expected: 0x%02h, Got: 0x%02h", 
                   $time, expected_data, item.rd_data);
            error_count++;
          end
        end else begin
          // Corner Case: Read when empty (Underflow) - Flag empty stay = 1
          if (!item.empty) begin
            $error("[SCB FAIL] @%0t: Underflow but empty flag = 0", $time);
            error_count++;
          end
        end
      end

      // Write
      if (item.wr_en) begin
        if (expected_queue.size() < DEPTH) begin
          expected_queue.push_back(item.wr_data);
        end else begin
          // Corner Case: Write when full (Overflow) 
          if (!item.full) begin
            $error("[SCB FAIL] @%0t: Overflow but full flag = 0", $time);
            error_count++;
          end
        end
      end
    end
  endtask

  function void report();
    $display(" Matches (Passed Reads) : %0d", match_count);
    $display(" Errors Found           : %0d", error_count);
    if (error_count == 0 && match_count > 0)
      $display(" STATUS                 : TEST PASSED (100%% SUCCESS)");
    else
      $display(" STATUS                 : TEST FAILED");
    $display("=======================================================\n");
  endfunction
endclass