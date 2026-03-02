/**
 * @file RrReqAgent.sv
 * @brief Round-Robin Arbiter Request Agent
 *
 * Agent containing driver, sequencer, and monitor.
 * - Active mode (default): driver + sequencer + monitor
 * - Passive mode: monitor only
 *
 * Configurable via RrAgentConfig object in config_db.
 * Monitor sends RrGntItem to analysis port for scoreboard/coverage.
 */

class RrReqAgent #(int N = 4) extends uvm_agent;

  `uvm_component_param_utils(RrReqAgent #(N))

  // Configuration object
  RrAgentConfig m_cfg;

  // Sub-components
  RrReqDriver #(N)    m_driver;
  RrReqSequencer #(N) m_sequencer;
  RrGntMonitor #(N)   m_monitor;

  function new(string name = "RrReqAgent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get configuration from config_db or create default
    if (!uvm_config_db#(RrAgentConfig)::get(this, "", "m_cfg", m_cfg)) begin
      `uvm_info("AGENT", "No config found, using defaults", UVM_MEDIUM)
      m_cfg = RrAgentConfig::type_id::create("m_cfg");
    end

    // Override is_active from config
    is_active = m_cfg.is_active;

    // Monitor is always built (passive or active)
    m_monitor = RrGntMonitor #(N)::type_id::create("m_monitor", this);
    m_monitor.sample_every_cycle = m_cfg.sample_every_cycle;

    // Driver and sequencer only in active mode
    if (m_cfg.is_active == UVM_ACTIVE) begin
      m_driver    = RrReqDriver #(N)::type_id::create("m_driver", this);
      m_sequencer = RrReqSequencer #(N)::type_id::create("m_sequencer", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect driver to sequencer only in active mode
    if (m_cfg.is_active == UVM_ACTIVE) begin
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    end
  endfunction

endclass : RrReqAgent

typedef RrReqAgent #(4) RrReqAgent4;
