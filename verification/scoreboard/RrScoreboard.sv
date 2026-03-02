/**
 * @file RrScoreboard.sv
 * @brief Round-Robin Arbiter Scoreboard
 *
 * Subscribes to monitor's analysis port.
 * Uses RrRefModel to predict expected gnt.
 * Compares DUT gnt vs. predicted gnt and reports mismatches.
 *
 * @see UVM_VERIFICATION_PLAN.md
 */

class RrScoreboard #(int N = 4, int MAX_HOLD_CYC = 64) extends uvm_scoreboard;

  `uvm_component_param_utils(RrScoreboard #(N, MAX_HOLD_CYC))

  // Analysis export to receive RrGntItem from monitor
  uvm_analysis_imp #(RrGntItem #(N), RrScoreboard #(N, MAX_HOLD_CYC)) analysis_export;

  // Reference model
  RrRefModel #(N, MAX_HOLD_CYC) m_ref_model;

  // Statistics
  int m_match_count;
  int m_mismatch_count;
  int m_total_count;

  // Track if we're in reset (skip comparison)
  bit m_in_reset;
  bit m_first_sample;

  // Pipeline delay: DUT gnt is registered, so we need to compare
  // current gnt with prediction from PREVIOUS req
  bit [N-1:0] m_prev_req;
  bit         m_second_sample;

  function new(string name = "RrScoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export = new("analysis_export", this);
    m_ref_model     = new();
    m_match_count    = 0;
    m_mismatch_count = 0;
    m_total_count    = 0;
    m_in_reset       = 1;
    m_first_sample   = 1;
    m_second_sample  = 0;
    m_prev_req       = '0;
  endfunction

  // Called by monitor via analysis port
  // Key insight: DUT gnt is REGISTERED, so current gnt reflects PREVIOUS req.
  // We compare DUT's gnt against ref model's prediction from prev_req.
  virtual function void write(RrGntItem #(N) item);
    bit [N-1:0] expected_gnt;
    bit [N-1:0] actual_gnt;

    m_total_count++;

    // Skip first sample - initialize ref model and save req
    if (m_first_sample) begin
      m_ref_model.reset();
      m_first_sample  = 0;
      m_second_sample = 1;
      m_prev_req      = item.req;
      `uvm_info("SCB", $sformatf("First sample (pipeline prime): req=%b gnt=%b", item.req, item.gnt), UVM_HIGH)
      return;
    end

    // Second sample - now we can start comparing
    // The DUT's gnt at this cycle was computed from m_prev_req
    if (m_second_sample) begin
      // Call predict with the PREVIOUS req to get expected gnt for THIS cycle
      expected_gnt = m_ref_model.predict(m_prev_req);
      m_second_sample = 0;
    end else begin
      // Normal operation: predict was already called last cycle with prev_req
      // Now call predict with current req to advance ref model and get expected gnt
      expected_gnt = m_ref_model.predict(m_prev_req);
    end

    actual_gnt = item.gnt;

    // Compare and print table
    if (actual_gnt == expected_gnt) begin
      m_match_count++;
      print_transaction_table("MATCH", m_match_count, m_prev_req, expected_gnt, actual_gnt,
                              m_ref_model.get_rr_ptr(), item.timestamp);
    end else begin
      m_mismatch_count++;
      print_transaction_table("MISMATCH", m_mismatch_count, m_prev_req, expected_gnt, actual_gnt,
                              m_ref_model.get_rr_ptr(), item.timestamp);
    end

    // Save current req for next cycle
    m_prev_req = item.req;
  endfunction

  // ============================================================================
  // print_transaction_table
  // Prints a formatted table for each transaction check
  // ============================================================================
  virtual function void print_transaction_table(
    string       txn_type,     // "MATCH" or "MISMATCH"
    int          txn_num,      // Transaction number
    bit [N-1:0]  req,          // Request vector
    bit [N-1:0]  expected_gnt, // Expected grant
    bit [N-1:0]  actual_gnt,   // Actual grant from DUT
    int          rr_ptr,       // Round-robin pointer
    time         timestamp     // Simulation time
  );
    string table_str;
    string status_str;
    string gnt_status;

    if (txn_type == "MATCH") begin
      status_str = "OK";
      gnt_status = "OK";
    end else begin
      status_str = "FAIL";
      gnt_status = "MISMATCH";
    end

    table_str = "\n";
    table_str = {table_str, $sformatf("  +==============[ %s #%-4d ]==============+\n", txn_type, txn_num)};
    table_str = {table_str, "  |  Field        |   Value                    |\n"};
    table_str = {table_str, "  +---------------+----------------------------+\n"};
    table_str = {table_str, $sformatf("  |  Time         |   %0t                 | \n", timestamp)};
    table_str = {table_str, $sformatf("  |  REQ          |   %b                     |\n", req)};
    table_str = {table_str, $sformatf("  |  RR_PTR       |   %0d                        |\n", rr_ptr)};
    table_str = {table_str, "  +---------------+----------------------------+\n"};
    table_str = {table_str, $sformatf("  |  Expected GNT |   %b                     |\n", expected_gnt)};
    table_str = {table_str, $sformatf("  |  Actual GNT   |   %b                     |\n", actual_gnt)};
    table_str = {table_str, "  +---------------+----------------------------+\n"};
    table_str = {table_str, $sformatf("  |  STATUS       |   %-24s |\n", status_str)};
    table_str = {table_str, "  +============================================+\n"};

    if (txn_type == "MISMATCH") begin
      `uvm_error("SCB", table_str)
    end else begin
      `uvm_info("SCB", table_str, UVM_HIGH)
    end
  endfunction

  // Report statistics at end of simulation
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    print_summary_table();
  endfunction

  // ============================================================================
  // print_summary_table
  // Prints a formatted summary table at end of test
  // ============================================================================
  virtual function void print_summary_table();
    string table_str;
    string pass_fail;

    pass_fail = (m_mismatch_count == 0) ? "PASS" : "FAIL";

    table_str = "\n";
    table_str = {table_str, "  +============================================================+\n"};
    table_str = {table_str, "  |              SCOREBOARD SUMMARY                           |\n"};
    table_str = {table_str, "  +============================================================+\n"};
    table_str = {table_str, "  |  STATISTICS                                               |\n"};
    table_str = {table_str, "  +-----------------------+------------------------------------+\n"};
    table_str = {table_str, $sformatf("  |  Total Comparisons    |  %6d                           |\n", m_total_count)};
    table_str = {table_str, $sformatf("  |  Matched              |  %6d                           |\n", m_match_count)};
    table_str = {table_str, $sformatf("  |  Mismatched           |  %6d                           |\n", m_mismatch_count)};
    table_str = {table_str, "  +============================================================+\n"};
    table_str = {table_str, $sformatf("  |  RESULT: %-49s|\n", pass_fail)};
    table_str = {table_str, "  +============================================================+\n"};

    `uvm_info("SCB", table_str, UVM_NONE)

    if (m_mismatch_count > 0)
      `uvm_error("SCB", "TEST FAILED - mismatches detected")
  endfunction

  // Reset handling - call this from test if reset occurs mid-simulation
  virtual function void handle_reset();
    m_ref_model.reset();
    m_first_sample  = 1;
    m_second_sample = 0;
    m_prev_req      = '0;
    `uvm_info("SCB", "Reference model reset", UVM_MEDIUM)
  endfunction

endclass : RrScoreboard

typedef RrScoreboard #(4, 64) RrScoreboard4;
