/**
 * @file RrBaseTest.sv
 * @brief Round-Robin Arbiter Base Test Class
 *
 * Base test class with common functionality.
 * Derived tests are in separate files.
 */

// ============================================================================
// Base Test Class (parameterized)
// ============================================================================
class RrBaseTest #(int N = 4, int MAX_HOLD_CYC = 64) extends uvm_test;

  `uvm_component_param_utils(RrBaseTest #(N, MAX_HOLD_CYC))

  RrEnv #(N, MAX_HOLD_CYC) m_env;

  function new(string name = "RrBaseTest", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = RrEnv #(N, MAX_HOLD_CYC)::type_id::create("m_env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrBaseReqSeq #(N) seq;
    phase.raise_objection(this);

    `uvm_info("TEST", "Starting RrBaseReqSeq", UVM_MEDIUM)
    seq = RrBaseReqSeq #(N)::type_id::create("seq");
    seq.m_num_items = 30;
    seq.start(m_env.m_req_agent.m_sequencer);

    `uvm_info("TEST", "Sequence complete", UVM_MEDIUM)
    phase.drop_objection(this);
  endtask

  // ============================================================================
  // report_phase - Final test summary
  // ============================================================================
  virtual function void report_phase(uvm_phase phase);
    string table_str;
    int mismatch_count;
    string test_result;

    super.report_phase(phase);

    // Get mismatch count from scoreboard
    mismatch_count = m_env.m_scoreboard.m_mismatch_count;
    test_result = (mismatch_count == 0) ? "PASSED" : "FAILED";

    table_str = "\n";
    table_str = {table_str, "  +============================================================+\n"};
    table_str = {table_str, "  |                    TEST SUMMARY                           |\n"};
    table_str = {table_str, "  +============================================================+\n"};
    table_str = {table_str, $sformatf("  |  Test Name:        %-39s |\n", get_type_name())};
    table_str = {table_str, $sformatf("  |  Scoreboard:       %0d mismatches                          |\n", mismatch_count)};
    table_str = {table_str, "  +============================================================+\n"};
    table_str = {table_str, $sformatf("  |  RESULT:           %-39s |\n", test_result)};
    table_str = {table_str, "  +============================================================+\n"};

    if (mismatch_count > 0)
      `uvm_error("TEST", table_str)
    else
      `uvm_info("TEST", table_str, UVM_NONE)
  endfunction

endclass : RrBaseTest


// ============================================================================
// RrBaseTest4 - Basic sanity test (concrete class for factory registration)
// ============================================================================
class RrBaseTest4 extends RrBaseTest #(4, 64);

  `uvm_component_utils(RrBaseTest4)

  function new(string name = "RrBaseTest4", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : RrBaseTest4
