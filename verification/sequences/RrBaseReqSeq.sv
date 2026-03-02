/**
 * @file RrBaseReqSeq.sv
 * @brief Round-Robin Arbiter Base Request Sequence
 *
 * Random req stimulus with default constraints.
 * Per verification plan: rr_basic_seq.
 */

class RrBaseReqSeq #(int N = 4) extends uvm_sequence #(RrReqItem #(N));

  `uvm_object_param_utils(RrBaseReqSeq #(N))

  int m_num_items = 50;

  function new(string name = "RrBaseReqSeq");
    super.new(name);
  endfunction

  virtual task body();
    RrReqItem #(N) item;
    `uvm_info("BASE_SEQ", $sformatf("Starting: %0d items", m_num_items), UVM_MEDIUM)

    repeat (m_num_items) begin
      item = RrReqItem #(N)::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_fatal("BASE_SEQ", "Randomization failed")
      finish_item(item);
    end

    `uvm_info("BASE_SEQ", "Complete", UVM_MEDIUM)
  endtask

endclass : RrBaseReqSeq

typedef RrBaseReqSeq #(4) RrBaseReqSeq4;
