/**
 * @file RrCornerSeq.sv
 * @brief Round-Robin Arbiter Corner-Case Sequence
 *
 * Directed corner cases: no req, single req, all req, round-robin pattern.
 * Per verification plan: rr_corner_seq.
 */

class RrCornerSeq #(int N = 4) extends uvm_sequence #(RrReqItem #(N));

  `uvm_object_param_utils(RrCornerSeq #(N))

  function new(string name = "RrCornerSeq");
    super.new(name);
  endfunction

  virtual task body();
    RrReqItem #(N) item;
    `uvm_info("CORNER_SEQ", "Starting corner cases", UVM_MEDIUM)

    // 1. No request (idle)
    item = RrReqItem #(N)::type_id::create("item");
    start_item(item);
    if (!item.randomize() with { req == 0; hold_cycles == 0; })
      `uvm_fatal("CORNER_SEQ", "Randomization failed")
    finish_item(item);

    // 2. Single requester [0], hold briefly
    item = RrReqItem #(N)::type_id::create("item");
    start_item(item);
    if (!item.randomize() with { req == 1; hold_cycles inside {[0:5]}; })
      `uvm_fatal("CORNER_SEQ", "Randomization failed")
    finish_item(item);

    // 3. All request, hold for round-robin stress
    item = RrReqItem #(N)::type_id::create("item");
    start_item(item);
    if (!item.randomize() with { req == (1<<N)-1; hold_cycles inside {[1:10]}; })
      `uvm_fatal("CORNER_SEQ", "Randomization failed")
    finish_item(item);

    // 4. Round-robin pattern: 1111 -> 0111 -> 0011 -> 0001 (release lowest bit each time)
    for (int i = N-1; i >= 0; i--) begin
      item = RrReqItem #(N)::type_id::create("item");
      start_item(item);
      if (!item.randomize() with {
        req == ((1 << (i+1)) - 1);
        hold_cycles inside {[1:3]};
        idle_before == 0;
        idle_after  == 0;
      })
        `uvm_fatal("CORNER_SEQ", "Randomization failed")
      finish_item(item);
    end

    `uvm_info("CORNER_SEQ", "Complete", UVM_MEDIUM)
  endtask

endclass : RrCornerSeq

typedef RrCornerSeq #(4) RrCornerSeq4;
