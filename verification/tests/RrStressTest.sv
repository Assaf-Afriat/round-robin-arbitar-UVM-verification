/**
 * @file RrStressTest.sv
 * @brief Round-Robin Arbiter Stress Test
 *
 * Back-to-back stress testing with:
 * - Minimal idle cycles
 * - Mixed request patterns
 * - High transaction count
 */

class RrStressTest4 extends RrBaseTest #(4, 64);

  `uvm_component_utils(RrStressTest4)

  function new(string name = "RrStressTest4", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrStressSeq #(4) seq;
    phase.raise_objection(this);

    `uvm_info("TEST", "Starting Stress Test (back-to-back)", UVM_MEDIUM)

    seq = RrStressSeq #(4)::type_id::create("seq");
    seq.m_num_items = 200;
    seq.start(m_env.m_req_agent.m_sequencer);

    `uvm_info("TEST", "Stress Test Complete", UVM_MEDIUM)
    phase.drop_objection(this);
  endtask

endclass : RrStressTest4
