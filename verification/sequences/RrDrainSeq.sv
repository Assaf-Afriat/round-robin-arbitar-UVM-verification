/**
 * @file RrDrainSeq.sv
 * @brief Round-Robin Arbiter Drain Sequence
 *
 * Sends idle requests (req=0) to drain the DUT and let gnt clear.
 * Used at the end of tests to ensure clean state.
 */

class RrDrainSeq #(int N = 4) extends uvm_sequence #(RrReqItem #(N));

  `uvm_object_param_utils(RrDrainSeq #(N))

  int m_num_items = 5;

  function new(string name = "RrDrainSeq");
    super.new(name);
  endfunction

  virtual task body();
    RrReqItem #(N) item;

    repeat (m_num_items) begin
      item = RrReqItem #(N)::type_id::create("drain_item");
      item.req = '0;
      item.hold_cycles = 0;
      item.idle_before = 0;
      item.idle_after = 2;
      start_item(item);
      finish_item(item);
    end
  endtask

endclass : RrDrainSeq

typedef RrDrainSeq #(4) RrDrainSeq4;
