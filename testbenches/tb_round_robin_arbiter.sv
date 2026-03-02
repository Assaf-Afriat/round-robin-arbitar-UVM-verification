//-----------------------------------------------------------------------------
// Testbench: tb_round_robin_arbiter
//
// Tests full functionality of round-robin arbiter:
//   - Reset
//   - Single requester
//   - Multiple requesters (round-robin fairness)
//   - Handshake (grant held until req drops)
//   - One-hot grant invariant
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_round_robin_arbiter;

  parameter int N          = 4;
  parameter     CLK_PERIOD = 10;

  logic        clk;
  logic        rst_n;
  logic [N-1:0] req;
  logic [N-1:0] gnt;
  logic [$clog2(N>1?N:2)-1:0] rr_ptr_debug;
  logic [6:0] hold_cnt_debug;  // up to 64

  round_robin_arbiter #(.N(N)) dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .req            (req),
    .gnt            (gnt),
    .rr_ptr_debug   (rr_ptr_debug),
    .hold_cnt_debug (hold_cnt_debug)
  );

  //----------------------------------------------------------------------------
  // Clock generation
  //----------------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  //----------------------------------------------------------------------------
  // Debug: Print priority order every cycle (in-flight, not only on grant)
  // Priority = rr_ptr, (rr_ptr+1)%N, (rr_ptr+2)%N, ...  (highest first)
  //----------------------------------------------------------------------------
  function automatic string get_priority_str;
    input int ptr;
    string s;
    int p;
    for (int i = 0; i < N; i++) begin
      p = (ptr + i) % N;
      if (i == 0) s = $sformatf("%0d", p);
      else        s = $sformatf("%s>%0d", s, p);
    end
    return s;
  endfunction

  always @(posedge clk) begin
    $display("[%0t] priority: %s  |  rr_ptr=%0d  hold=%0d  req=%b  gnt=%b",
             $time, get_priority_str(rr_ptr_debug), rr_ptr_debug, hold_cnt_debug, req, gnt);
  end

  //----------------------------------------------------------------------------
  // Helper: assert one-hot or zero
  //----------------------------------------------------------------------------
  function automatic bit is_onehot_or_zero(logic [N-1:0] vec);
    int count;
    count = $countones(vec);
    return (count == 0 || count == 1);
  endfunction

  //----------------------------------------------------------------------------
  // Helper: get index of granted requester (-1 if none)
  //-----------------------------------------------------------------------------
  function automatic int get_granted_idx(logic [N-1:0] g);
    for (int i = 0; i < N; i++)
      if (g[i]) return i;
    return -1;
  endfunction

  //----------------------------------------------------------------------------
  // Test: Reset
  //----------------------------------------------------------------------------
  task test_reset;
    $display("[%0t] TEST: Reset", $time);
    rst_n = 0;
    req   = '0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
    if (gnt != '0) $error("After reset, gnt should be 0, got %b", gnt);
    else $display("  PASS: gnt=0 after reset");
  endtask

  //----------------------------------------------------------------------------
  // Test: Single requester
  //----------------------------------------------------------------------------
  task test_single_requester;
    $display("[%0t] TEST: Single requester", $time);
    rst_n = 1;
    req   = 4'b0001;  // req[0]
    repeat (2) @(posedge clk);  // 1 cycle for grant to appear
    if (gnt != 4'b0001)
      $error("Single req[0]: expected gnt=0001, got %b", gnt);
    else
      $display("  PASS: req[0] -> gnt[0]");
    req = '0;
    @(posedge clk);
  endtask

  //----------------------------------------------------------------------------
  // Test: Round-robin fairness (all request)
  //----------------------------------------------------------------------------
  task test_round_robin;
    $display("[%0t] TEST: Round-robin (all request)", $time);
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;
    @(posedge clk);  // reset so rr_ptr=0
    req   = '1;  // all request
    // First grant should go to 0 (rr_ptr starts at 0)
    repeat (2) @(posedge clk);
    if (gnt != 4'b0001)
      $error("RR step 1: expected gnt=0001, got %b", gnt);
    // Release req[0] -> re-arbitrate, next should be req[1]
    req = 4'b1110;
    repeat (2) @(posedge clk);
    if (gnt != 4'b0010)
      $error("RR step 2: expected gnt=0010, got %b", gnt);
    req = 4'b1100;
    repeat (2) @(posedge clk);
    if (gnt != 4'b0100)
      $error("RR step 3: expected gnt=0100, got %b", gnt);
    req = 4'b1000;
    repeat (2) @(posedge clk);
    if (gnt != 4'b1000)
      $error("RR step 4: expected gnt=1000, got %b", gnt);
    $display("  PASS: round-robin 0->1->2->3");
    req = '0;
    @(posedge clk);
  endtask

  //----------------------------------------------------------------------------
  // Test: Handshake - grant held until req drops
  //----------------------------------------------------------------------------
  task test_handshake;
    $display("[%0t] TEST: Handshake", $time);
    rst_n = 1;
    req   = 4'b0100;  // req[2]
    repeat (2) @(posedge clk);
    if (gnt != 4'b0100)
      $error("Handshake: expected gnt=0100, got %b", gnt);
    // Hold req for 3 more cycles - gnt should stay
    repeat (3) @(posedge clk);
    if (gnt != 4'b0100)
      $error("Handshake: gnt should stay 0100 while req held, got %b", gnt);
    // Drop req -> gnt clears (may take 2 cycles: condition + register)
    req = '0;
    repeat (2) @(posedge clk);
    if (gnt != '0)
      $error("Handshake: after req drop, gnt should go 0, got %b", gnt);
    $display("  PASS: grant held until req dropped");
  endtask

  //----------------------------------------------------------------------------
  // Test: One-hot invariant (continuous check)
  //----------------------------------------------------------------------------
  task test_onehot_invariant;
    $display("[%0t] TEST: One-hot invariant", $time);
    rst_n = 1;
    req   = '0;
    repeat (2) @(posedge clk);
    // Random req patterns
    for (int k = 0; k < 20; k++) begin
      req = $urandom_range((1 << N) - 1, 0);
      repeat (3) @(posedge clk);
      if (!is_onehot_or_zero(gnt))
        $error("One-hot violated: req=%b gnt=%b", req, gnt);
    end
    $display("  PASS: gnt always one-hot or zero");
    req = '0;
  endtask

  //----------------------------------------------------------------------------
  // Test: Max hold timeout - prevents starvation
  //----------------------------------------------------------------------------
  task test_max_hold_timeout;
    $display("[%0t] TEST: Max hold timeout (64 cycles)", $time);
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;
    @(posedge clk);  // rr_ptr=0
    req   = '0;
    repeat (2) @(posedge clk);
    // req[0] holds for 70 cycles - should force timeout after 64, grant to req[1]
    req   = 4'b0011;  // req[0] and req[1] both request
    repeat (70) @(posedge clk);
    // After 64 cycles holding, we should have switched to req[1]
    if (gnt != 4'b0010)
      $error("Max hold: expected grant to switch to req[1] after timeout, got gnt=%b", gnt);
    else
      $display("  PASS: grant rotated to req[1] after 64-cycle hold");
    req = '0;
    repeat (2) @(posedge clk);
  endtask

  //----------------------------------------------------------------------------
  // Test: No grant when no request
  //----------------------------------------------------------------------------
  task test_no_request;
    $display("[%0t] TEST: No grant when no request", $time);
    rst_n = 1;
    req   = '0;
    repeat (5) @(posedge clk);
    if (gnt != '0)
      $error("No req: gnt should be 0, got %b", gnt);
    else
      $display("  PASS: gnt=0 when req=0");
  endtask

  //----------------------------------------------------------------------------
  // Main
  //----------------------------------------------------------------------------
  initial begin
    $display("========================================");
    $display(" Round-Robin Arbiter Testbench (N=%0d)", N);
    $display("========================================");
    req = '0;
    rst_n = 0;
    repeat (5) @(posedge clk);

    test_reset;
    repeat (2) @(posedge clk);

    test_single_requester;
    repeat (2) @(posedge clk);

    test_round_robin;
    repeat (2) @(posedge clk);

    test_handshake;
    repeat (2) @(posedge clk);

    test_onehot_invariant;
    repeat (2) @(posedge clk);

    test_max_hold_timeout;
    repeat (2) @(posedge clk);

    test_no_request;

    repeat (5) @(posedge clk);
    $display("========================================");
    $display(" ALL TESTS DONE");
    $display("========================================");
    $finish;
  end

endmodule
