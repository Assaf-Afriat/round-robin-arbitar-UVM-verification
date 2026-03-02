//-----------------------------------------------------------------------------
// SVA Bindings for Round-Robin Arbiter
// Bind this module to the DUT to enable assertions without modifying RTL.
// Usage: bind round_robin_arbiter rr_arbiter_sva #(.N(4)) sva_inst (.*);
//
// Per UVM_VERIFICATION_PLAN.md Section 3:
// A1-A3: Invariants
// A4-A5: Round-Robin Fairness (complex, covered in scoreboard)
// A6-A7: Timeout/Starvation Prevention
// A8-A9: Reset
//-----------------------------------------------------------------------------

module rr_arbiter_sva #(
  parameter int N           = 4,
  parameter int MAX_HOLD_CYC = 64
) (
  input logic        clk,
  input logic        rst_n,
  input logic [N-1:0] req,
  input logic [N-1:0] gnt
);

  // =========================================================================
  // Auxiliary signals for assertions
  // =========================================================================
  logic holding;
  logic [N-1:0] prev_gnt;
  int hold_count;
  logic gnt_changed;
  logic other_requesters;  // Are there requesters other than the current grantee?

  assign holding = (gnt != '0) && ((gnt & req) != '0);
  assign gnt_changed = (gnt != prev_gnt);
  assign other_requesters = ((req & ~gnt) != '0);  // Other requesters waiting

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_gnt   <= '0;
      hold_count <= 0;
    end else begin
      prev_gnt <= gnt;
      // Count consecutive cycles with same gnt while holding AND other requesters waiting
      if (gnt_changed || !holding || !other_requesters)
        hold_count <= 0;
      else
        hold_count <= hold_count + 1;
    end
  end

  // =========================================================================
  // A1: gnt is one-hot or all-zero (INVARIANT)
  // =========================================================================
  property p_onehot_or_zero;
    @(posedge clk) disable iff (!rst_n)
      ($countones(gnt) <= 1);
  endproperty
  a_onehot: assert property (p_onehot_or_zero)
    else $error("SVA A1: gnt must be one-hot or zero, got %b", gnt);
  c_onehot: cover property (p_onehot_or_zero);

  // =========================================================================
  // A2: No request -> next cycle no grant
  // =========================================================================
  property p_no_req_no_gnt;
    @(posedge clk) disable iff (!rst_n)
      (|req == 1'b0) |-> ##1 (gnt == '0);
  endproperty
  a_no_req_no_gnt: assert property (p_no_req_no_gnt)
    else $error("SVA A2: req=0 should lead to gnt=0 next cycle");
  c_no_req_no_gnt: cover property (p_no_req_no_gnt);

  // =========================================================================
  // A3: Grant implies request (handshake)
  // When gnt is non-zero, either current req has that bit set, or
  // it was set in the previous cycle (hold-over)
  // =========================================================================
  property p_gnt_implies_req;
    @(posedge clk) disable iff (!rst_n)
      (gnt != '0) |-> ((gnt & req) != '0) || ((gnt & $past(req)) != '0);
  endproperty
  a_gnt_implies_req: assert property (p_gnt_implies_req)
    else $error("SVA A3: gnt=%b without matching req=%b or past_req", gnt, req);
  c_gnt_implies_req: cover property (p_gnt_implies_req);

  // =========================================================================
  // A5: Starvation prevention - no requester should wait more than MAX_HOLD_CYC cycles
  // hold_count only increments when: holding AND other_requesters waiting
  // The assertion is: hold_count should never reach MAX_HOLD_CYC
  // (DUT should force re-arbitration before that)
  // =========================================================================
  property p_no_starvation;
    @(posedge clk) disable iff (!rst_n)
      (hold_count < MAX_HOLD_CYC);
  endproperty
  a_no_starvation: assert property (p_no_starvation)
    else $error("SVA A5: hold_count=%0d reached MAX_HOLD_CYC=%0d - starvation!", hold_count, MAX_HOLD_CYC);
  c_no_starvation: cover property (p_no_starvation);

  // Cover: timeout boundary nearly reached (hold_count gets high)
  property p_near_timeout;
    @(posedge clk) disable iff (!rst_n)
      (hold_count >= MAX_HOLD_CYC - 5) && other_requesters;
  endproperty
  c_near_timeout: cover property (p_near_timeout);

  // =========================================================================
  // A8: Reset clears grant
  // =========================================================================
  property p_reset_clears_gnt;
    @(posedge clk)
      (!rst_n) |-> ##1 (gnt == '0);
  endproperty
  a_reset_clears_gnt: assert property (p_reset_clears_gnt)
    else $error("SVA A8: Reset should clear gnt");
  c_reset_clears_gnt: cover property (p_reset_clears_gnt);

  // =========================================================================
  // A9: After reset release, pointer should be 0
  // (Cannot check rr_ptr directly without debug port, covered in scoreboard)
  // =========================================================================

  // =========================================================================
  // Coverage: Timeout event occurred
  // =========================================================================
  property p_timeout_occurred;
    @(posedge clk) disable iff (!rst_n)
      (hold_count == MAX_HOLD_CYC - 1) && holding ##1 (gnt != $past(gnt));
  endproperty
  c_timeout_event: cover property (p_timeout_occurred);

  // =========================================================================
  // Coverage: Grant transition (any change in gnt)
  // =========================================================================
  property p_gnt_change;
    @(posedge clk) disable iff (!rst_n)
      (gnt != $past(gnt));
  endproperty
  c_gnt_change: cover property (p_gnt_change);

  // =========================================================================
  // Coverage: All requesters requesting simultaneously
  // =========================================================================
  property p_all_req;
    @(posedge clk) disable iff (!rst_n)
      (req == {N{1'b1}});
  endproperty
  c_all_req: cover property (p_all_req);

  // =========================================================================
  // Coverage: Single requester
  // =========================================================================
  property p_single_req;
    @(posedge clk) disable iff (!rst_n)
      ($countones(req) == 1);
  endproperty
  c_single_req: cover property (p_single_req);

  // =========================================================================
  // Coverage: No requesters
  // =========================================================================
  property p_no_req;
    @(posedge clk) disable iff (!rst_n)
      (req == '0);
  endproperty
  c_no_req: cover property (p_no_req);

endmodule
