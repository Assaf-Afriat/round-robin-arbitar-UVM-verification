/**
 * @file RrRefModel.sv
 * @brief Round-Robin Arbiter Reference Model
 *
 * Predicts expected gnt based on req history.
 * Mirrors RTL logic:
 * - Registered gnt (1-cycle latency)
 * - Round-robin pointer advances when granted requester is at rr_ptr
 * - Re-arbitrate when gnt==0 or (gnt & req)==0
 * - Timeout after MAX_HOLD_CYC cycles forces re-arbitration
 *
 * @see UVM_VERIFICATION_PLAN.md Section 2
 */

class RrRefModel #(int N = 4, int MAX_HOLD_CYC = 64);

  // Internal state (mirrors DUT)
  bit [N-1:0] m_gnt;
  int         m_rr_ptr;
  int         m_hold_count;

  // Previous req for pipeline modeling
  bit [N-1:0] m_prev_req;

  function new();
    reset();
  endfunction

  // Reset state
  function void reset();
    m_gnt        = '0;
    m_rr_ptr     = 0;
    m_hold_count = 0;
    m_prev_req   = '0;
  endfunction

  // Compute next grant given current req (called each cycle)
  // Returns predicted gnt for THIS cycle (after posedge clk)
  function bit [N-1:0] predict(bit [N-1:0] req);
    bit [N-1:0] next_gnt;
    int         granted_idx;
    bit         holding;
    bit         timeout;
    int         arb_ptr;

    // Find granted index
    granted_idx = 0;
    for (int i = 0; i < N; i++)
      if (m_gnt[i]) granted_idx = i;

    holding = (m_gnt & req) != '0;
    timeout = (m_hold_count >= (MAX_HOLD_CYC - 1)) && holding;

    // Determine arbitration pointer
    if (timeout)
      arb_ptr = (granted_idx + 1) % N;
    else
      arb_ptr = m_rr_ptr;

    // Compute next_gnt using round-robin arbitration
    next_gnt = compute_next_gnt(req, arb_ptr);

    // Update state for next cycle
    if (timeout) begin
      m_rr_ptr     = (granted_idx + 1) % N;
      m_gnt        = next_gnt;
      m_hold_count = 0;
    end else begin
      // Pointer: advance when requester at rr_ptr has grant
      if (m_gnt[m_rr_ptr])
        m_rr_ptr = (m_rr_ptr + 1) % N;

      // Grant: re-arbitrate when no grants or all granted requesters released req
      if ((m_gnt == '0) || ((m_gnt & req) == '0)) begin
        m_gnt        = next_gnt;
        m_hold_count = 0;
      end else if (holding) begin
        m_hold_count = m_hold_count + 1;
      end
    end

    m_prev_req = req;
    return m_gnt;
  endfunction

  // Round-robin arbitration: rotate req by arb_ptr, pick LSB, rotate back
  function bit [N-1:0] compute_next_gnt(bit [N-1:0] req, int arb_ptr);
    bit [N-1:0] req_rotated;
    bit [N-1:0] winner_rotated;
    bit [N-1:0] result;

    // Rotate right by arb_ptr
    req_rotated = (req >> arb_ptr) | (req << (N - arb_ptr));

    // Pick lowest set bit (priority encoder)
    winner_rotated = req_rotated & ((~req_rotated) + 1);

    // Rotate back left by arb_ptr
    result = (winner_rotated << arb_ptr) | (winner_rotated >> (N - arb_ptr));

    return result;
  endfunction

  // Get current predicted gnt (without advancing state)
  function bit [N-1:0] get_gnt();
    return m_gnt;
  endfunction

  // Get current rr_ptr (for debug)
  function int get_rr_ptr();
    return m_rr_ptr;
  endfunction

  // Get hold count (for debug)
  function int get_hold_count();
    return m_hold_count;
  endfunction

endclass : RrRefModel
