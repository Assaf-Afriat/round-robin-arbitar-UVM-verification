/**
 * @file RrStressSeq.sv
 * @brief Round-Robin Arbiter Stress Sequence
 *
 * Back-to-back requests, minimal idle. Mixed patterns.
 * Per verification plan: rr_stress_seq.
 */

class RrStressSeq #(int N = 4) extends uvm_sequence #(RrReqItem #(N));

  `uvm_object_param_utils(RrStressSeq #(N))

  int m_num_items = 100;

  function new(string name = "RrStressSeq");
    super.new(name);
  endfunction

  virtual task body();
    RrReqItem #(N) item;
    `uvm_info("STRESS_SEQ", $sformatf("Starting: %0d stress items", m_num_items), UVM_MEDIUM)

    repeat (m_num_items) begin
      item = RrReqItem #(N)::type_id::create("item");
      start_item(item);
      if (!item.randomize() with {
        idle_before == 0;
        idle_after  == 0;
      })
        `uvm_fatal("STRESS_SEQ", "Randomization failed")
      finish_item(item);
    end

    `uvm_info("STRESS_SEQ", "Complete", UVM_MEDIUM)
  endtask

endclass : RrStressSeq

typedef RrStressSeq #(4) RrStressSeq4;
