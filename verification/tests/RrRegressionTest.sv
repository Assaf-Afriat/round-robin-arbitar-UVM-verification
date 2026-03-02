/**
 * @file RrRegressionTest.sv
 * @brief Round-Robin Arbiter Regression Test
 *
 * Full regression test with extended runs:
 * - More basic items
 * - More timeout scenarios
 * - More stress items
 *
 * Use for nightly/weekly regression runs.
 */

class RrRegressionTest4 extends RrBaseTest #(4, 64);

  `uvm_component_utils(RrRegressionTest4)

  function new(string name = "RrRegressionTest4", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrVirtualSeq #(4) vseq;
    phase.raise_objection(this);

    `uvm_info("TEST", "========== Starting Regression Test ==========", UVM_MEDIUM)

    vseq = RrVirtualSeq #(4)::type_id::create("vseq");
    vseq.m_req_seqr = m_env.m_req_agent.m_sequencer;
    vseq.m_num_basic_items   = 100;
    vseq.m_num_timeout_items = 80;
    vseq.m_num_stress_items  = 200;
    vseq.start(null);

    `uvm_info("TEST", "========== Regression Test Complete ==========", UVM_MEDIUM)
    phase.drop_objection(this);
  endtask

endclass : RrRegressionTest4
