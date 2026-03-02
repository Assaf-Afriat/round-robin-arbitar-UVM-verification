/**
 * @file RrReqDriver.sv
 * @brief Round-Robin Arbiter Request Driver
 *
 * Drives req[] based on RrReqItem. Protocol:
 * - idle_before cycles of req=0
 * - req for (hold_cycles+1) cycles (min 1)
 * - idle_after cycles of req=0
 *
 * @see UVM_VERIFICATION_PLAN.md
 */

class RrReqDriver #(int N = 4) extends uvm_driver #(RrReqItem #(N));

  `uvm_component_param_utils(RrReqDriver #(N))

  virtual RrArbIf #(N) m_vif;

  function new(string name = "RrReqDriver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (!uvm_config_db#(virtual RrArbIf #(N))::get(this, "", "rr_arb_if", m_vif))
      `uvm_fatal("NO_RR_ARB_IF", "RrArbIf not set - check tb_top")
  endfunction

  virtual task run_phase(uvm_phase phase);
    if (m_vif == null) begin
      `uvm_fatal("DRV", "Virtual interface is null")
      return;
    end

    reset_driver();

    // Wait for reset release
    @(posedge m_vif.clk);
    while (!m_vif.rst_n) @(posedge m_vif.clk);

    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_item(RrReqItem #(N) item);
    // Idle before
    m_vif.req <= '0;
    repeat (item.idle_before) @(posedge m_vif.clk);

    // Hold request: at least 1 cycle, or hold_cycles+1 total
    m_vif.req <= item.req;
    repeat (item.hold_cycles + 1) @(posedge m_vif.clk);

    // Idle after
    m_vif.req <= '0;
    repeat (item.idle_after) @(posedge m_vif.clk);

    `uvm_info("DRV", $sformatf("Drove: %s", item.convert2string()), UVM_HIGH)
  endtask

  virtual task reset_driver();
    if (m_vif != null)
      m_vif.req <= '0;
  endtask

endclass : RrReqDriver

typedef RrReqDriver #(4) RrReqDriver4;
