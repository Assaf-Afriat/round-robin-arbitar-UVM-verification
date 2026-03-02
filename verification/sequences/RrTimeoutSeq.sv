/**
 * @file RrTimeoutSeq.sv
 * @brief Round-Robin Arbiter Timeout Stress Sequence
 *
 * Forces hold_cycles 63-70 to stress max-hold timeout.
 * Per verification plan: rr_timeout_seq.
 */

class RrTimeoutSeq #(int N = 4) extends uvm_sequence #(RrReqItem #(N));

  `uvm_object_param_utils(RrTimeoutSeq #(N))

  int m_num_items = 20;

  function new(string name = "RrTimeoutSeq");
    super.new(name);
  endfunction

  virtual task body();
    RrReqItem #(N) item;
    `uvm_info("TIMEOUT_SEQ", $sformatf("Starting: %0d timeout items", m_num_items), UVM_MEDIUM)

    repeat (m_num_items) begin
      item = RrReqItem #(N)::type_id::create("item");
      start_item(item);
      if (!item.randomize() with {
        hold_cycles inside {[63:70]};
        req != 0;
      })
        `uvm_fatal("TIMEOUT_SEQ", "Randomization failed")
      finish_item(item);
    end

    `uvm_info("TIMEOUT_SEQ", "Complete", UVM_MEDIUM)
  endtask

endclass : RrTimeoutSeq

typedef RrTimeoutSeq #(4) RrTimeoutSeq4;
