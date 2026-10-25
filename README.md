# Synchronous FIFO - Simple Layered Testbench

This project verifies a synchronous FIFO using a class-based SystemVerilog testbench.

```text
Stimulus:    environment -> drv_mbx -> driver -> interface -> DUT
Observation: DUT/interface -> monitor -> mon_mbx -> scoreboard
```

| File | Responsibility |
|---|---|
| `rtl/synch_fifo.sv` | Implements the FIFO using memory, pointers, and an occupancy counter. |
| `tb/fifo_if.sv` | Groups DUT signals and defines clocking blocks for driving and sampling. |
| `tb/fifo_item.sv` | Holds enables, data, and observed DUT state. |
| `tb/fifo_driver.sv` | Drives one queued item per clock; drives idle when the mailbox is empty. |
| `tb/fifo_monitor.sv` | Samples interface inputs and outputs, then sends observations to the scoreboard. |
| `tb/fifo_scoreboard.sv` | Predicts FIFO behavior and compares observed DUT outputs against the model. |
| `tb/fifo_env.sv` | Connects the classes and generates test cases. |
| `tb/synch_fifo_tb.sv` | Creates the clock, interface, DUT, and environment. |

## Scoreboard Model

The reference model has two state variables:

```systemverilog
expected_queue    // Values that should still be stored in the FIFO
expected_rd_data  // Value that dout should currently hold
```

Each monitor sample is processed in this order:

1. During reset, clear the queue, set `expected_rd_data` to zero, and check reset outputs.
2. Otherwise, compare `count`, `full`, `empty`, and `rd_data` against the current model.
3. Determine whether read and write requests are accepted using occupancy before either operation.
4. For an accepted read, pop the queue front and save the expected output for the next sample.
5. For an accepted write, push `wr_data` to the queue back.

`read_count` counts accepted reads; `error_count` counts failures. There are no
coverage counters, `match_count`, or `pending_read`. Outputs are checked on every
sample, including idle cycles. The report passes only when no errors occurred,
at least one read was accepted, and the model queue is empty.

## Read Timing

The monitor uses `input #1step`, so it samples immediately before the rising clock
edge. The RTL updates `dout` in the NBA region after that edge. The sample at an
accepted read therefore still contains the previous output. The scoreboard saves
the expected read result and checks it against the next monitor sample.

For example, suppose the FIFO contains A5 and `dout` currently holds 00:

| Sample | Monitor observes | Scoreboard action |
|---|---|---|
| Read request | `rd_en=1`, `rd_data=00` | Check the previous expected value 00, then pop A5 and save expected=A5. |
| Next sample | `rd_data=A5` | Compare the output against expected=A5. |

## Completion

The driver uses `busy` to indicate that it is driving an item. `wait_done()` waits
until the mailbox is empty and the driver is no longer busy, then allows one more
monitor sample to check the final result. It checks completion at the falling
edge to avoid racing the classes that run at the rising edge. Separate
submitted/driven/applied/sample/processed counters are not required by this flow.

## Test Cases

1. Startup reset.
2. Reset while the FIFO contains unread data and `dout` is nonzero.
3. Fill the FIFO and attempt overflow writes.
4. Drain the FIFO and attempt underflow reads.
5. Simultaneous read/write at empty, partial, and full occupancy. `DEPTH=1` has no partial state.
6. Generate 200 random items, then drain the FIFO.

There is no copy test or unused copy method. Directed requests are generated with
`send_item()`. Random stimulus uses `item.randomize()` without additional constraints.

## Running Simulation

From the project root, enter `sim` and run each command in order:

```text
cd sim
xvlog --sv -f filelist.f
xelab synch_fifo_tb -debug typical -s tb_top
xsim tb_top -runall
```


To change the FIFO configuration, edit `DATA_WIDTH` and `DEPTH` in
`tb/synch_fifo_tb.sv`, then compile and elaborate again.
