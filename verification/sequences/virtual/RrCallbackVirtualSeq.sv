/**
 * @file RrCallbackVirtualSeq.sv
 * @brief Virtual Sequence demonstrating all driver callbacks
 *
 * Runs multiple phases to showcase callback functionality:
 *   Phase 1: Normal traffic (no callbacks active)
 *   Phase 2: Logging callback enabled
 *   Phase 3: Error injection callback enabled
 *   Phase 4: Both callbacks stacked
 *
 * @see RrReqDriverCb.sv
 */

class RrCallbackVirtualSeq #(int N = 4) extends uvm_sequence;

  `uvm_object_param_utils(RrCallbackVirtualSeq #(N))

  // Sequencer handle (set by test before starting)
  RrReqSequencer #(N) m_req_seqr;

  // Driver handle (set by test for callback registration)
  RrReqDriver #(N) m_driver;

  // Configuration
  int m_items_per_phase = 10;

  // Callback instances
  RrReqDriverLogCb       m_log_cb;
  RrReqDriverErrInjectCb m_err_cb;

  function new(string name = "RrCallbackVirtualSeq");
    super.new(name);
  endfunction

  virtual task body();
    if (m_req_seqr == null) begin
      `uvm_fatal("VSEQ", "m_req_seqr is null - set before starting")
      return;
    end
    if (m_driver == null) begin
      `uvm_fatal("VSEQ", "m_driver is null - set before starting")
      return;
    end

    // Create callback instances
    m_log_cb = RrReqDriverLogCb::type_id::create("m_log_cb");
    m_log_cb.log_verbosity = UVM_LOW;

    m_err_cb = RrReqDriverErrInjectCb::type_id::create("m_err_cb");
    m_err_cb.corruption_pct = 30;  // 30% corruption for visibility

    // =========================================================================
    // PHASE 1: Normal traffic (baseline, no callbacks)
    // =========================================================================
    run_phase1_normal();

    // =========================================================================
    // PHASE 2: Logging callback
    // =========================================================================
    run_phase2_logging();

    // =========================================================================
    // PHASE 3: Error injection callback
    // =========================================================================
    run_phase3_error_injection();

    // =========================================================================
    // PHASE 4: Both callbacks stacked
    // =========================================================================
    run_phase4_stacked();

    // Final summary
    print_summary();
  endtask


  // ---------------------------------------------------------------------------
  // Phase 1: Normal traffic (no callbacks)
  // ---------------------------------------------------------------------------
  virtual task run_phase1_normal();
    RrBaseReqSeq #(N) seq;

    `uvm_info("VSEQ", "============================================================", UVM_LOW)
    `uvm_info("VSEQ", "PHASE 1: Normal Traffic (no callbacks)", UVM_LOW)
    `uvm_info("VSEQ", "============================================================", UVM_LOW)

    seq = RrBaseReqSeq #(N)::type_id::create("phase1_seq");
    seq.m_num_items = m_items_per_phase;
    seq.start(m_req_seqr);

    `uvm_info("VSEQ", "Phase 1 complete - baseline established", UVM_LOW)
  endtask


  // ---------------------------------------------------------------------------
  // Phase 2: Logging callback enabled
  // ---------------------------------------------------------------------------
  virtual task run_phase2_logging();
    RrBaseReqSeq #(N) seq;

    `uvm_info("VSEQ", "============================================================", UVM_LOW)
    `uvm_info("VSEQ", "PHASE 2: Logging Callback Active", UVM_LOW)
    `uvm_info("VSEQ", "  Watch for [DRV_CB] PRE_DRIVE/POST_DRIVE messages", UVM_LOW)
    `uvm_info("VSEQ", "============================================================", UVM_LOW)

    // Register logging callback
    uvm_callbacks #(RrReqDriver #(N), RrReqDriverCb)::add(m_driver, m_log_cb);

    seq = RrBaseReqSeq #(N)::type_id::create("phase2_seq");
    seq.m_num_items = m_items_per_phase;
    seq.start(m_req_seqr);

    // Remove callback for next phase
    uvm_callbacks #(RrReqDriver #(N), RrReqDriverCb)::delete(m_driver, m_log_cb);

    `uvm_info("VSEQ", $sformatf("Phase 2 complete - logged %0d items", m_log_cb.item_count), UVM_LOW)
  endtask


  // ---------------------------------------------------------------------------
  // Phase 3: Error injection callback enabled
  // ---------------------------------------------------------------------------
  virtual task run_phase3_error_injection();
    RrBaseReqSeq #(N) seq;

    `uvm_info("VSEQ", "============================================================", UVM_LOW)
    `uvm_info("VSEQ", "PHASE 3: Error Injection Callback Active", UVM_LOW)
    `uvm_info("VSEQ", $sformatf("  Corruption rate: %0d%%", m_err_cb.corruption_pct), UVM_LOW)
    `uvm_info("VSEQ", "  Watch for [DRV_CB] ERROR INJECTION warnings", UVM_LOW)
    `uvm_info("VSEQ", "============================================================", UVM_LOW)

    // Register error injection callback
    uvm_callbacks #(RrReqDriver #(N), RrReqDriverCb)::add(m_driver, m_err_cb);

    seq = RrBaseReqSeq #(N)::type_id::create("phase3_seq");
    seq.m_num_items = m_items_per_phase;
    seq.start(m_req_seqr);

    // Remove callback for next phase
    uvm_callbacks #(RrReqDriver #(N), RrReqDriverCb)::delete(m_driver, m_err_cb);

    `uvm_info("VSEQ", $sformatf("Phase 3 complete - corrupted %0d/%0d items",
              m_err_cb.items_corrupted, m_err_cb.items_driven), UVM_LOW)
  endtask


  // ---------------------------------------------------------------------------
  // Phase 4: Both callbacks stacked
  // ---------------------------------------------------------------------------
  virtual task run_phase4_stacked();
    RrBaseReqSeq #(N) seq;
    int log_start, err_start;

    `uvm_info("VSEQ", "============================================================", UVM_LOW)
    `uvm_info("VSEQ", "PHASE 4: Stacked Callbacks (Logging + Error Injection)", UVM_LOW)
    `uvm_info("VSEQ", "  Both callbacks execute in registration order", UVM_LOW)
    `uvm_info("VSEQ", "============================================================", UVM_LOW)

    // Track starting counts
    log_start = m_log_cb.item_count;
    err_start = m_err_cb.items_driven;

    // Register BOTH callbacks - they execute in order added
    uvm_callbacks #(RrReqDriver #(N), RrReqDriverCb)::add(m_driver, m_log_cb);
    uvm_callbacks #(RrReqDriver #(N), RrReqDriverCb)::add(m_driver, m_err_cb);

    seq = RrBaseReqSeq #(N)::type_id::create("phase4_seq");
    seq.m_num_items = m_items_per_phase;
    seq.start(m_req_seqr);

    // Remove both callbacks
    uvm_callbacks #(RrReqDriver #(N), RrReqDriverCb)::delete(m_driver, m_log_cb);
    uvm_callbacks #(RrReqDriver #(N), RrReqDriverCb)::delete(m_driver, m_err_cb);

    `uvm_info("VSEQ", $sformatf("Phase 4 complete - logged %0d items this phase",
              m_log_cb.item_count - log_start), UVM_LOW)
  endtask


  // ---------------------------------------------------------------------------
  // Print final summary
  // ---------------------------------------------------------------------------
  virtual function void print_summary();
    int corruption_rate;
    string summary;
    corruption_rate = (m_err_cb.items_driven > 0) ? (m_err_cb.items_corrupted * 100 / m_err_cb.items_driven) : 0;

    summary = "\n";
    summary = {summary, "  +==============[ CALLBACK VSEQ SUMMARY ]==============+\n"};
    summary = {summary, "  |  Field                |   Value                     |\n"};
    summary = {summary, "  +=======================+=============================+\n"};
    summary = {summary, $sformatf("  |  Items per Phase      |   %-4d                      |\n", m_items_per_phase)};
    summary = {summary, $sformatf("  |  Total Phases         |   %-4d                      |\n", 4)};
    summary = {summary, "  +-----------------------+-----------------------------+\n"};
    summary = {summary, "  |  LOGGING CALLBACK                                   |\n"};
    summary = {summary, "  +-----------------------+-----------------------------+\n"};
    summary = {summary, $sformatf("  |  Items Logged         |   %-4d (phases 2 & 4)       |\n", m_log_cb.item_count)};
    summary = {summary, "  +-----------------------+-----------------------------+\n"};
    summary = {summary, "  |  ERROR INJECTION CALLBACK                           |\n"};
    summary = {summary, "  +-----------------------+-----------------------------+\n"};
    summary = {summary, $sformatf("  |  Items Driven         |   %-4d (phases 3 & 4)       |\n", m_err_cb.items_driven)};
    summary = {summary, $sformatf("  |  Items Corrupted      |   %-4d                      |\n", m_err_cb.items_corrupted)};
    summary = {summary, $sformatf("  |  Corruption Rate      |   %-3d%%                      |\n", corruption_rate)};
    summary = {summary, "  +=====================================================+\n"};

    `uvm_info("CB_VSEQ", summary, UVM_LOW)
  endfunction

endclass : RrCallbackVirtualSeq
