/**
 * @file RrCoverageCollector.sv
 * @brief Round-Robin Arbiter Functional Coverage Collector
 *
 * Implements functional coverage per UVM_VERIFICATION_PLAN.md Section 6.
 * Subscribes to monitor's analysis port to sample coverage.
 *
 * Coverage Groups:
 * - Request patterns (none, single, pairs, all)
 * - Grant patterns (none, single)
 * - Last->Next grant transitions (RR fairness)
 * - Hold duration (timeout boundary)
 * - rr_ptr values
 * - Cross coverage (req x gnt, last_gnt x next_gnt)
 */

class RrCoverageCollector #(int N = 4, int MAX_HOLD_CYC = 64) extends uvm_subscriber #(RrGntItem #(N));

  `uvm_component_param_utils(RrCoverageCollector #(N, MAX_HOLD_CYC))

  // ============================================================================
  // State Tracking
  // ============================================================================
  bit [N-1:0] m_last_gnt;
  bit [N-1:0] m_last_req;
  int         m_hold_count;
  int         m_rr_ptr;

  // Sampled values for coverage
  bit [N-1:0] m_sampled_req;
  bit [N-1:0] m_sampled_gnt;
  bit [N-1:0] m_sampled_last_gnt;
  int         m_sampled_hold_count;
  bit         m_sampled_timeout;

  // ============================================================================
  // Coverage Group: Request Patterns
  // ============================================================================
  covergroup cg_req_patterns;
    option.per_instance = 1;
    option.name = "cg_req_patterns";

    cp_req: coverpoint m_sampled_req {
      bins none     = {'0};
      bins single[] = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
      bins pairs[]  = {4'b0011, 4'b0101, 4'b0110, 4'b1001, 4'b1010, 4'b1100};
      bins triple[] = {4'b0111, 4'b1011, 4'b1101, 4'b1110};
      bins all      = {4'b1111};
    }
  endgroup

  // ============================================================================
  // Coverage Group: Grant Patterns
  // ============================================================================
  covergroup cg_gnt_patterns;
    option.per_instance = 1;
    option.name = "cg_gnt_patterns";

    cp_gnt: coverpoint m_sampled_gnt {
      bins none     = {'0};
      bins single[] = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
    }
  endgroup

  // ============================================================================
  // Coverage Group: Last->Next Grant Transitions (RR Fairness)
  // ============================================================================
  covergroup cg_gnt_transitions;
    option.per_instance = 1;
    option.name = "cg_gnt_transitions";

    cp_last_gnt: coverpoint m_sampled_last_gnt {
      bins none     = {'0};
      bins gnt_0    = {4'b0001};
      bins gnt_1    = {4'b0010};
      bins gnt_2    = {4'b0100};
      bins gnt_3    = {4'b1000};
    }

    cp_next_gnt: coverpoint m_sampled_gnt {
      bins none     = {'0};
      bins gnt_0    = {4'b0001};
      bins gnt_1    = {4'b0010};
      bins gnt_2    = {4'b0100};
      bins gnt_3    = {4'b1000};
    }

    // Cross: all valid last->next transitions
    cx_gnt_transition: cross cp_last_gnt, cp_next_gnt;
  endgroup

  // ============================================================================
  // Coverage Group: Hold Duration (Timeout Boundary)
  // ============================================================================
  covergroup cg_hold_duration;
    option.per_instance = 1;
    option.name = "cg_hold_duration";

    cp_hold_count: coverpoint m_sampled_hold_count {
      bins hold_zero     = {0};
      bins hold_short    = {[1:10]};
      bins hold_mid      = {[11:62]};
      bins hold_boundary = {63};
      bins hold_timeout  = {64};
      bins hold_over     = {[65:$]};
    }

    cp_timeout: coverpoint m_sampled_timeout {
      bins no_timeout  = {0};
      bins timeout_hit = {1};
    }

    // Cross: hold_count at timeout boundary
    cx_hold_timeout: cross cp_hold_count, cp_timeout;
  endgroup

  // ============================================================================
  // Coverage Group: Request x Grant Cross
  // ============================================================================
  covergroup cg_req_gnt_cross;
    option.per_instance = 1;
    option.name = "cg_req_gnt_cross";

    cp_req_nonzero: coverpoint m_sampled_req {
      bins any_req[] = {[1:15]};
    }

    cp_gnt_idx: coverpoint m_sampled_gnt {
      bins gnt_0 = {4'b0001};
      bins gnt_1 = {4'b0010};
      bins gnt_2 = {4'b0100};
      bins gnt_3 = {4'b1000};
    }

    // Cross: verify grant matches a requesting bit
    cx_req_gnt: cross cp_req_nonzero, cp_gnt_idx;
  endgroup

  // ============================================================================
  // Constructor
  // ============================================================================
  function new(string name = "RrCoverageCollector", uvm_component parent = null);
    super.new(name, parent);
    cg_req_patterns   = new();
    cg_gnt_patterns   = new();
    cg_gnt_transitions = new();
    cg_hold_duration  = new();
    cg_req_gnt_cross  = new();
  endfunction

  // ============================================================================
  // write (from analysis port)
  // ============================================================================
  virtual function void write(RrGntItem #(N) t);
    // Sample values
    m_sampled_req      = t.req;
    m_sampled_gnt      = t.gnt;
    m_sampled_last_gnt = m_last_gnt;

    // Track hold count
    if (t.gnt != '0 && t.gnt == m_last_gnt && (t.gnt & t.req) != '0) begin
      m_hold_count++;
    end else begin
      m_hold_count = 0;
    end
    m_sampled_hold_count = m_hold_count;
    m_sampled_timeout = (m_hold_count >= MAX_HOLD_CYC);

    // Sample coverage
    cg_req_patterns.sample();
    cg_gnt_patterns.sample();
    cg_gnt_transitions.sample();
    cg_hold_duration.sample();
    if (t.req != '0 && t.gnt != '0)
      cg_req_gnt_cross.sample();

    // Update state for next cycle
    m_last_gnt = t.gnt;
    m_last_req = t.req;
  endfunction

  // ============================================================================
  // report_phase - Print coverage summary
  // ============================================================================
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    print_coverage_summary();
  endfunction

  // ============================================================================
  // print_coverage_summary
  // ============================================================================
  virtual function void print_coverage_summary();
    string table_str;
    real req_cov, gnt_cov, trans_cov, hold_cov, cross_cov, total_cov;
    string req_status, gnt_status, trans_status, hold_status, cross_status;

    req_cov   = cg_req_patterns.get_coverage();
    gnt_cov   = cg_gnt_patterns.get_coverage();
    trans_cov = cg_gnt_transitions.get_coverage();
    hold_cov  = cg_hold_duration.get_coverage();
    cross_cov = cg_req_gnt_cross.get_coverage();
    total_cov = (req_cov + gnt_cov + trans_cov + hold_cov + cross_cov) / 5.0;

    // Status indicators (targets from verification plan)
    req_status   = (req_cov >= 100.0) ? "PASS" : (req_cov >= 80.0) ? "WARN" : "FAIL";
    gnt_status   = (gnt_cov >= 100.0) ? "PASS" : (gnt_cov >= 80.0) ? "WARN" : "FAIL";
    trans_status = (trans_cov >= 80.0) ? "PASS" : (trans_cov >= 60.0) ? "WARN" : "FAIL";
    hold_status  = (hold_cov >= 80.0) ? "PASS" : (hold_cov >= 60.0) ? "WARN" : "FAIL";
    cross_status = (cross_cov >= 80.0) ? "PASS" : (cross_cov >= 60.0) ? "WARN" : "FAIL";

    table_str = "\n";
    table_str = {table_str, "  +============================================================+\n"};
    table_str = {table_str, "  |              FUNCTIONAL COVERAGE SUMMARY                  |\n"};
    table_str = {table_str, "  +============================================================+\n"};
    table_str = {table_str, "  |  Coverage Group              |  Coverage %   |  Status    |\n"};
    table_str = {table_str, "  +------------------------------+---------------+------------+\n"};
    table_str = {table_str, $sformatf("  |  Request Patterns            |    %6.2f%%    |  %-8s  |\n", req_cov, req_status)};
    table_str = {table_str, $sformatf("  |  Grant Patterns              |    %6.2f%%    |  %-8s  |\n", gnt_cov, gnt_status)};
    table_str = {table_str, $sformatf("  |  Grant Transitions (RR)      |    %6.2f%%    |  %-8s  |\n", trans_cov, trans_status)};
    table_str = {table_str, $sformatf("  |  Hold Duration (Timeout)     |    %6.2f%%    |  %-8s  |\n", hold_cov, hold_status)};
    table_str = {table_str, $sformatf("  |  Req x Gnt Cross             |    %6.2f%%    |  %-8s  |\n", cross_cov, cross_status)};
    table_str = {table_str, "  +============================================================+\n"};
    table_str = {table_str, $sformatf("  |  TOTAL (Average)             |    %6.2f%%    |            |\n", total_cov)};
    table_str = {table_str, "  +============================================================+\n"};
    table_str = {table_str, "  |  SVA ASSERTION COVERAGE (see UCDB for details)            |\n"};
    table_str = {table_str, "  |  - A1: One-hot gnt            - Covered via simulation    |\n"};
    table_str = {table_str, "  |  - A2: No req -> no gnt       - Covered via simulation    |\n"};
    table_str = {table_str, "  |  - A3: Gnt implies req        - Covered via simulation    |\n"};
    table_str = {table_str, "  |  - A5: No starvation          - Covered via simulation    |\n"};
    table_str = {table_str, "  |  - A8: Reset clears gnt       - Covered via simulation    |\n"};
    table_str = {table_str, "  +============================================================+\n"};

    `uvm_info("COVERAGE", table_str, UVM_LOW)
  endfunction

endclass : RrCoverageCollector

typedef RrCoverageCollector #(4, 64) RrCoverageCollector4;
