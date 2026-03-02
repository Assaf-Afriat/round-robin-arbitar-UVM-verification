/**
 * @file RrEnv.sv
 * @brief Round-Robin Arbiter UVM Environment
 *
 * Top-level verification environment.
 * Contains:
 * - Request agent (driver, sequencer, monitor)
 * - Scoreboard with reference model
 * - Coverage collector
 *
 * Virtual interface must be set via config_db before run:
 *   uvm_config_db#(virtual RrArbIf #(N))::set(null, "*", "rr_arb_if", vif);
 */

class RrEnv #(int N = 4, int MAX_HOLD_CYC = 64) extends uvm_env;

  `uvm_component_param_utils(RrEnv #(N, MAX_HOLD_CYC))

  RrReqAgent #(N)                       m_req_agent;
  RrScoreboard #(N, MAX_HOLD_CYC)       m_scoreboard;
  RrCoverageCollector #(N, MAX_HOLD_CYC) m_coverage;

  // Coverage enable (can be disabled via config_db)
  bit m_has_coverage = 1;

  function new(string name = "RrEnv", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Check if coverage should be enabled
    void'(uvm_config_db#(bit)::get(this, "", "has_coverage", m_has_coverage));

    m_req_agent  = RrReqAgent #(N)::type_id::create("m_req_agent", this);
    m_scoreboard = RrScoreboard #(N, MAX_HOLD_CYC)::type_id::create("m_scoreboard", this);

    if (m_has_coverage)
      m_coverage = RrCoverageCollector #(N, MAX_HOLD_CYC)::type_id::create("m_coverage", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect monitor's analysis port to scoreboard
    m_req_agent.m_monitor.ap.connect(m_scoreboard.analysis_export);

    // Connect monitor's analysis port to coverage collector
    if (m_has_coverage && m_coverage != null)
      m_req_agent.m_monitor.ap.connect(m_coverage.analysis_export);
  endfunction

endclass : RrEnv

typedef RrEnv #(4) RrEnv4;
