 /**
 * @file RrFullTest.sv
 * @brief Round-Robin Arbiter Full Test
 *
 * Full virtual sequence test - runs all phases:
 * - Basic traffic
 * - Timeout scenarios
 * - Stress traffic
 * - Corner cases
 *
 * Use this for full coverage runs.
 */

class RrFullTest4 extends RrBaseTest #(4, 64);

  `uvm_component_utils(RrFullTest4)

  function new(string name = "RrFullTest4", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrVirtualSeq #(4) vseq;
    phase.raise_objection(this);

    `uvm_info("TEST", "========== Starting Full Test (Virtual Sequence) ==========", UVM_MEDIUM)

    vseq = RrVirtualSeq #(4)::type_id::create("vseq");
    vseq.m_req_seqr = m_env.m_req_agent.m_sequencer;
    vseq.m_num_basic_items   = 50;
    vseq.m_num_timeout_items = 40;
    vseq.m_num_stress_items  = 100;
    vseq.start(null);

    `uvm_info("TEST", "========== Full Test Complete ==========", UVM_MEDIUM)
    phase.drop_objection(this);
  endtask

endclass : RrFullTest4
