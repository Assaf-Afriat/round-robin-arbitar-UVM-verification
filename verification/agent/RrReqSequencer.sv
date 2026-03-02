/**
 * @file RrReqSequencer.sv
 * @brief Round-Robin Arbiter Request Sequencer
 *
 * Sequencer for RrReqItem transactions.
 */

class RrReqSequencer #(int N = 4) extends uvm_sequencer #(RrReqItem #(N));

  `uvm_component_param_utils(RrReqSequencer #(N))

  function new(string name = "RrReqSequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : RrReqSequencer

typedef RrReqSequencer #(4) RrReqSequencer4;
