/**
 * @file RrVirtualSeq.sv
 * @brief Round-Robin Arbiter Top Virtual Sequence
 *
 * Orchestrates complete verification flow per UVM_VERIFICATION_PLAN.md:
 * 1. Basic traffic (sanity)
 * 2. Timeout scenarios (hold 63, 64, 65 cycles)
 * 3. Stress traffic (back-to-back, many patterns)
 * 4. Corner cases (directed scenarios from plan)
 * 5. Reset injection (optional)
 *
 * Designed to achieve:
 * - Full functional coverage
 * - SVA assertion coverage
 * - Code coverage
 */

class RrVirtualSeq #(int N = 4) extends uvm_sequence;

  `uvm_object_param_utils(RrVirtualSeq #(N))

  // ============================================================================
  // Sequencer Handle (set by test)
  // ============================================================================
  uvm_sequencer #(RrReqItem #(N)) m_req_seqr;

  // ============================================================================
  // Configuration Knobs
  // ============================================================================
  int m_num_basic_items    = 50;
  int m_num_timeout_items  = 30;
  int m_num_stress_items   = 100;
  int m_num_corner_items   = 20;

  // ============================================================================
  // Constructor
  // ============================================================================
  function new(string name = "RrVirtualSeq");
    super.new(name);
  endfunction

  // ============================================================================
  // body - Main orchestration
  // ============================================================================
  virtual task body();
    `uvm_info("VSEQ", "========== Starting Virtual Sequence ==========", UVM_MEDIUM)

    // Phase 1: Basic traffic (sanity)
    do_basic_traffic();

    // Phase 2: Timeout scenarios
    do_timeout_scenarios();

    // Phase 3: Stress traffic
    do_stress_traffic();

    // Phase 4: Corner cases
    do_corner_cases();

    // Phase 5: Final drain
    do_drain();

    `uvm_info("VSEQ", "========== Virtual Sequence Complete ==========", UVM_MEDIUM)
  endtask

  // ============================================================================
  // Phase 1: Basic Traffic
  // Random patterns, short holds
  // ============================================================================
  virtual task do_basic_traffic();
    RrBaseReqSeq #(N) seq;

    `uvm_info("VSEQ", "Phase 1: Basic Traffic", UVM_MEDIUM)

    seq = RrBaseReqSeq #(N)::type_id::create("basic_seq");
    seq.m_num_items = m_num_basic_items;
    seq.start(m_req_seqr);

    `uvm_info("VSEQ", $sformatf("Basic traffic complete: %0d items", m_num_basic_items), UVM_MEDIUM)
  endtask

  // ============================================================================
  // Phase 2: Timeout Scenarios
  // Force hold cycles around timeout boundary (63, 64, 65)
  // ============================================================================
  virtual task do_timeout_scenarios();
    RrTimeoutSeq #(N) seq;

    `uvm_info("VSEQ", "Phase 2: Timeout Scenarios (63, 64, 65 cycle holds)", UVM_MEDIUM)

    seq = RrTimeoutSeq #(N)::type_id::create("timeout_seq");
    seq.m_num_items = m_num_timeout_items;
    seq.start(m_req_seqr);

    `uvm_info("VSEQ", $sformatf("Timeout scenarios complete: %0d items", m_num_timeout_items), UVM_MEDIUM)
  endtask

  // ============================================================================
  // Phase 3: Stress Traffic
  // Back-to-back, mixed patterns, no idle
  // ============================================================================
  virtual task do_stress_traffic();
    RrStressSeq #(N) seq;

    `uvm_info("VSEQ", "Phase 3: Stress Traffic (back-to-back)", UVM_MEDIUM)

    seq = RrStressSeq #(N)::type_id::create("stress_seq");
    seq.m_num_items = m_num_stress_items;
    seq.start(m_req_seqr);

    `uvm_info("VSEQ", $sformatf("Stress traffic complete: %0d items", m_num_stress_items), UVM_MEDIUM)
  endtask

  // ============================================================================
  // Phase 4: Corner Cases
  // Directed scenarios from verification plan
  // ============================================================================
  virtual task do_corner_cases();
    RrCornerSeq #(N) seq;

    `uvm_info("VSEQ", "Phase 4: Corner Cases (directed scenarios)", UVM_MEDIUM)

    seq = RrCornerSeq #(N)::type_id::create("corner_seq");
    seq.start(m_req_seqr);

    `uvm_info("VSEQ", "Corner cases complete", UVM_MEDIUM)
  endtask

  // ============================================================================
  // Phase 5: Drain
  // Let DUT settle with no requests
  // ============================================================================
  virtual task do_drain();
    RrDrainSeq #(N) seq;

    `uvm_info("VSEQ", "Phase 5: Drain (idle cycles)", UVM_MEDIUM)

    seq = RrDrainSeq #(N)::type_id::create("drain_seq");
    seq.start(m_req_seqr);

    `uvm_info("VSEQ", "Drain complete", UVM_MEDIUM)
  endtask

endclass : RrVirtualSeq

typedef RrVirtualSeq #(4) RrVirtualSeq4;

// Note: Reset injection sequences require a proper reset agent or must be
// done from tb_top module. Sequences cannot directly drive interface signals.
