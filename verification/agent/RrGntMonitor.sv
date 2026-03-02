/**
 * @file RrGntMonitor.sv
 * @brief Round-Robin Arbiter Grant Monitor
 *
 * Passive monitor that samples gnt and req from the interface.
 * Sends RrGntItem transactions via analysis port to scoreboard/coverage.
 *
 * Sampling strategy:
 * - Sample on every posedge clk after reset
 * - Send transaction when gnt changes or on every cycle (configurable)
 *
 * @see UVM_VERIFICATION_PLAN.md
 */

class RrGntMonitor #(int N = 4) extends uvm_monitor;

  `uvm_component_param_utils(RrGntMonitor #(N))

  // Analysis port for scoreboard/coverage subscribers
  uvm_analysis_port #(RrGntItem #(N)) ap;

  // Virtual interface handle
  virtual RrArbIf #(N) m_vif;

  // Configuration: sample every cycle or only on gnt change
  bit sample_every_cycle = 1;

  // Previous gnt for change detection
  bit [N-1:0] m_prev_gnt;

  function new(string name = "RrGntMonitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (!uvm_config_db#(virtual RrArbIf #(N))::get(this, "", "rr_arb_if", m_vif))
      `uvm_fatal("NO_RR_ARB_IF", "RrArbIf not set - check tb_top")
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrGntItem #(N) item;

    if (m_vif == null) begin
      `uvm_fatal("MON", "Virtual interface is null")
      return;
    end

    // Wait for reset release
    @(posedge m_vif.clk);
    while (!m_vif.rst_n) @(posedge m_vif.clk);

    m_prev_gnt = '0;

    forever begin
      @(posedge m_vif.clk);

      // Sample current state
      if (sample_every_cycle || (m_vif.gnt != m_prev_gnt)) begin
        item = RrGntItem #(N)::type_id::create("item");
        item.gnt       = m_vif.gnt;
        item.req       = m_vif.req;
        item.timestamp = $time;

        ap.write(item);

        `uvm_info("MON", $sformatf("Sampled: %s", item.convert2string()), UVM_HIGH)
      end

      m_prev_gnt = m_vif.gnt;
    end
  endtask

endclass : RrGntMonitor

typedef RrGntMonitor #(4) RrGntMonitor4;
