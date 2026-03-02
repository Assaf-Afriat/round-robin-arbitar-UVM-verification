/**
 * @file RrGntItem.sv
 * @brief Round-Robin Arbiter Grant Transaction Item
 *
 * Captured by the monitor on each clock cycle when gnt changes or req changes.
 * Used by scoreboard to compare against reference model predictions.
 */

class RrGntItem #(int N = 4) extends uvm_sequence_item;

  // ---------------------------------------------------------------------------
  // Transaction Fields (must be before uvm_field macros)
  // ---------------------------------------------------------------------------
  bit [N-1:0] gnt;        // Grant vector sampled from DUT
  bit [N-1:0] req;        // Request vector at same time (for reference model)
  time        timestamp;  // Simulation time when sampled

  // ---------------------------------------------------------------------------
  // UVM Factory Registration
  // ---------------------------------------------------------------------------
  `uvm_object_param_utils_begin(RrGntItem #(N))
    `uvm_field_int(gnt,       UVM_ALL_ON)
    `uvm_field_int(req,       UVM_ALL_ON)
    `uvm_field_int(timestamp, UVM_ALL_ON)
  `uvm_object_utils_end

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  function new(string name = "RrGntItem");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // convert2string
  // ---------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("RrGntItem: gnt=%b req=%b @%0t", gnt, req, timestamp);
  endfunction

  // ---------------------------------------------------------------------------
  // do_copy
  // ---------------------------------------------------------------------------
  virtual function void do_copy(uvm_object rhs);
    RrGntItem #(N) rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("DO_COPY", "Cast failed")
      return;
    end
    super.do_copy(rhs);
    gnt       = rhs_.gnt;
    req       = rhs_.req;
    timestamp = rhs_.timestamp;
  endfunction

  // ---------------------------------------------------------------------------
  // do_compare
  // ---------------------------------------------------------------------------
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    RrGntItem #(N) rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (gnt == rhs_.gnt) && (req == rhs_.req);
  endfunction

endclass : RrGntItem

typedef RrGntItem #(4) RrGntItem4;
