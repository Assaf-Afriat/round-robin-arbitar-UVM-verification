/**
 * @file RrCornerTest.sv
 * @brief Round-Robin Arbiter Corner Case Test
 *
 * Directed corner case scenarios from verification plan:
 * - No request
 * - Single requester
 * - All requesters
 * - Back-to-back transitions
 * - Partial drop
 * - etc.
 */

class RrCornerTest4 extends RrBaseTest #(4, 64);

  `uvm_component_utils(RrCornerTest4)

  function new(string name = "RrCornerTest4", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrCornerSeq #(4) seq;
    phase.raise_objection(this);

    `uvm_info("TEST", "Starting Corner Case Test", UVM_MEDIUM)

    seq = RrCornerSeq #(4)::type_id::create("seq");
    seq.start(m_env.m_req_agent.m_sequencer);

    `uvm_info("TEST", "Corner Case Test Complete", UVM_MEDIUM)
    phase.drop_objection(this);
  endtask

endclass : RrCornerTest4
