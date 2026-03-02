/**
 * @file RrCallbackDemoTest.sv
 * @brief Demonstrates UVM Callback Usage
 *
 * Tests available:
 *   - RrCallbackLogTest4:   Logging callback only
 *   - RrCallbackErrTest4:   Error injection callback only
 *   - RrCallbackMultiTest4: Both callbacks stacked
 *   - RrCallbackFullTest4:  Virtual sequence with all callback phases
 */

// =============================================================================
// Test 1: Logging Callback Demo
// =============================================================================
class RrCallbackLogTest4 extends RrBaseTest #(4, 64);

  `uvm_component_utils(RrCallbackLogTest4)

  RrReqDriverLogCb m_log_cb;

  function new(string name = "RrCallbackLogTest4", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    m_log_cb = RrReqDriverLogCb::type_id::create("m_log_cb");
    m_log_cb.log_verbosity = UVM_LOW;
    uvm_callbacks #(RrReqDriver4, RrReqDriverCb)::add(m_env.m_req_agent.m_driver, m_log_cb);
    `uvm_info("TEST", "Logging callback registered", UVM_LOW)
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrBaseReqSeq #(4) seq;
    phase.raise_objection(this);
    `uvm_info("TEST", "========== Callback Logging Demo ==========", UVM_LOW)
    seq = RrBaseReqSeq #(4)::type_id::create("seq");
    seq.m_num_items = 10;
    seq.start(m_env.m_req_agent.m_sequencer);
    `uvm_info("TEST", $sformatf("Logged %0d items", m_log_cb.item_count), UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass : RrCallbackLogTest4


// =============================================================================
// Test 2: Error Injection Callback Demo
// =============================================================================
class RrCallbackErrTest4 extends RrBaseTest #(4, 64);

  `uvm_component_utils(RrCallbackErrTest4)

  RrReqDriverErrInjectCb m_err_cb;

  function new(string name = "RrCallbackErrTest4", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    m_err_cb = RrReqDriverErrInjectCb::type_id::create("m_err_cb");
    m_err_cb.corruption_pct = 20;
    uvm_callbacks #(RrReqDriver4, RrReqDriverCb)::add(m_env.m_req_agent.m_driver, m_err_cb);
    `uvm_info("TEST", $sformatf("Error injection registered (corruption=%0d%%)", m_err_cb.corruption_pct), UVM_LOW)
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrBaseReqSeq #(4) seq;
    phase.raise_objection(this);
    `uvm_info("TEST", "========== Error Injection Demo ==========", UVM_LOW)
    seq = RrBaseReqSeq #(4)::type_id::create("seq");
    seq.m_num_items = 50;
    seq.start(m_env.m_req_agent.m_sequencer);
    m_err_cb.print_stats();
    phase.drop_objection(this);
  endtask

endclass : RrCallbackErrTest4


// =============================================================================
// Test 3: Multiple Callbacks Demo
// =============================================================================
class RrCallbackMultiTest4 extends RrBaseTest #(4, 64);

  `uvm_component_utils(RrCallbackMultiTest4)

  RrReqDriverLogCb       m_log_cb;
  RrReqDriverErrInjectCb m_err_cb;

  function new(string name = "RrCallbackMultiTest4", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    m_log_cb = RrReqDriverLogCb::type_id::create("m_log_cb");
    m_log_cb.log_verbosity = UVM_MEDIUM;
    m_err_cb = RrReqDriverErrInjectCb::type_id::create("m_err_cb");
    m_err_cb.corruption_pct = 5;
    uvm_callbacks #(RrReqDriver4, RrReqDriverCb)::add(m_env.m_req_agent.m_driver, m_log_cb);
    uvm_callbacks #(RrReqDriver4, RrReqDriverCb)::add(m_env.m_req_agent.m_driver, m_err_cb);
    `uvm_info("TEST", "Stacked callbacks registered (logging + error injection)", UVM_LOW)
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrBaseReqSeq #(4) seq;
    phase.raise_objection(this);
    `uvm_info("TEST", "========== Multiple Callbacks Demo ==========", UVM_LOW)
    seq = RrBaseReqSeq #(4)::type_id::create("seq");
    seq.m_num_items = 30;
    seq.start(m_env.m_req_agent.m_sequencer);
    `uvm_info("TEST", $sformatf("Logged %0d items", m_log_cb.item_count), UVM_LOW)
    m_err_cb.print_stats();
    phase.drop_objection(this);
  endtask

endclass : RrCallbackMultiTest4


// =============================================================================
// Test 4: Full Callback Virtual Sequence
// Runs all 4 phases: normal -> logging -> error injection -> stacked
// =============================================================================
class RrCallbackFullTest4 extends RrBaseTest #(4, 64);

  `uvm_component_utils(RrCallbackFullTest4)

  function new(string name = "RrCallbackFullTest4", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrCallbackVirtualSeq #(4) vseq;
    phase.raise_objection(this);

    `uvm_info("TEST", "========== Full Callback Demo (4 Phases) ==========", UVM_LOW)

    vseq = RrCallbackVirtualSeq #(4)::type_id::create("vseq");
    vseq.m_req_seqr = m_env.m_req_agent.m_sequencer;
    vseq.m_driver   = m_env.m_req_agent.m_driver;
    vseq.m_items_per_phase = 15;
    vseq.start(null);

    `uvm_info("TEST", "========== Full Callback Demo Complete ==========", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass : RrCallbackFullTest4
