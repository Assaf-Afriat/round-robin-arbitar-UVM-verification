module round_robin_arbiter #(
  parameter int N           = 4,
  parameter int MAX_HOLD_CYC = 64  // max cycles one requester holds grant; prevents starvation
) (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [N-1:0] req,
  output logic [N-1:0] gnt,
  output logic [(N==1?1:$clog2(N))-1:0] rr_ptr_debug,   // debug: round-robin pointer
  output logic [$clog2(MAX_HOLD_CYC+1)-1:0] hold_cnt_debug  // debug: cycles holding current grant
);

  // Pointer: next requester to try (0..N-1). Uses minimal bits for synthesis.
  localparam int PTR_W   = (N == 1) ? 1 : $clog2(N);
  localparam int CNT_W   = $clog2(MAX_HOLD_CYC + 1);

  logic [PTR_W-1:0] rr_ptr;
  logic [CNT_W-1:0] hold_count;
  logic [N-1:0]     next_gnt;

  // Granted index (one-hot gnt -> index) for timeout logic
  logic [PTR_W-1:0] granted_idx;
  logic             holding;        // gnt & req != 0
  logic             timeout;        // hold_count >= MAX_HOLD_CYC
  logic [PTR_W-1:0] arb_ptr;        // rr_ptr or (granted+1) when timeout

  always_comb begin
    granted_idx = PTR_W'(0);
    for (int i = 0; i < N; i++)
      if (gnt[i]) granted_idx = PTR_W'(i);
  end

  assign holding = (gnt & req) != '0;
  assign timeout = (hold_count >= CNT_W'(MAX_HOLD_CYC - 1)) && holding;
  assign arb_ptr = timeout ? PTR_W'((granted_idx + 1) % N) : rr_ptr;

  // ---------------------------------------------------------------------------
  // Next grant logic (combinatorial)
  // Uses arb_ptr: normal rr_ptr, or skip-current when timeout.
  // ---------------------------------------------------------------------------
  logic [2*N-1:0] req_shifted;
  logic [N-1:0]   req_rotated;
  logic [N-1:0]   winner_rotated;

  assign req_shifted = {req, req} >> arb_ptr;
  assign req_rotated = req_shifted[N-1:0];

  assign winner_rotated = req_rotated & ((~req_rotated) + 1);
  assign next_gnt = (winner_rotated << arb_ptr) | (winner_rotated >> (N - arb_ptr));

  // ---------------------------------------------------------------------------
  // Sequential logic (async reset, per slide)
  // - rr_ptr: advance when granted requester is at rr_ptr
  // - gnt: registered; update only when no grants or all granted dropped req
  // ---------------------------------------------------------------------------
  assign rr_ptr_debug   = rr_ptr;
  assign hold_cnt_debug = hold_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rr_ptr     <= PTR_W'(0);
      gnt        <= '0;
      hold_count <= CNT_W'(0);
    end else if (timeout) begin
      rr_ptr     <= PTR_W'((granted_idx + 1) % N);
      gnt        <= next_gnt;
      hold_count <= CNT_W'(0);
    end else begin
      // Pointer: advance when requester at rr_ptr has grant
      if (gnt[rr_ptr]) begin
        rr_ptr <= PTR_W'((rr_ptr + 1) % N);
      end

      // Grant: re-arbitrate when no grants or all granted requesters released req
      if ((|gnt == 1'b0) || ((gnt & req) == '0)) begin
        gnt        <= next_gnt;
        hold_count <= CNT_W'(0);
      end else if (holding) begin
        hold_count <= hold_count + 1'b1;
      end
    end
  end

endmodule
