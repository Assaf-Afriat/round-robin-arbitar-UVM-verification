/**
 * @file RrTimeoutTest.sv
 * @brief Round-Robin Arbiter Timeout Test
 *
 * Focus on timeout boundary scenarios:
 * - 63 cycle holds (no timeout)
 * - 64 cycle holds (timeout)
 * - 65+ cycle holds (post-timeout)
 */

class RrTimeoutTest4 extends RrBaseTest #(4, 64);

  `uvm_component_utils(RrTimeoutTest4)

  function new(string name = "RrTimeoutTest4", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    RrTimeoutSeq #(4) seq;
    phase.raise_objection(this);

    `uvm_info("TEST", "Starting Timeout Test (63, 64, 65 cycle holds)", UVM_MEDIUM)

    seq = RrTimeoutSeq #(4)::type_id::create("seq");
    seq.m_num_items = 60;
    seq.start(m_env.m_req_agent.m_sequencer);

    `uvm_info("TEST", "Timeout Test Complete", UVM_MEDIUM)
    phase.drop_objection(this);
  endtask

endclass : RrTimeoutTest4
