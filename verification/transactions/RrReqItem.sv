/**
 * @file RrReqItem.sv
 * @brief Round-Robin Arbiter Request Sequence Item
 *
 * UVM sequence item for driving request patterns to the arbiter.
 * Used by the request driver to generate req[] stimulus.
 *
 * @see UVM_VERIFICATION_PLAN.md
 */

class RrReqItem #(int N = 4) extends uvm_sequence_item;

  // ---------------------------------------------------------------------------
  // Transaction Fields (must be before uvm_field macros)
  // ---------------------------------------------------------------------------
  rand bit [N-1:0] req;          // Request vector (1 = request)
  rand int         hold_cycles;  // Cycles to hold req (0 = single cycle)
  rand int         idle_before;  // Idle cycles (req=0) before this item
  rand int         idle_after;   // Idle cycles (req=0) after this item

  // ---------------------------------------------------------------------------
  // UVM Factory Registration
  // ---------------------------------------------------------------------------
  `uvm_object_param_utils_begin(RrReqItem #(N))
    `uvm_field_int(req,          UVM_ALL_ON)
    `uvm_field_int(hold_cycles,  UVM_ALL_ON)
    `uvm_field_int(idle_before,  UVM_ALL_ON)
    `uvm_field_int(idle_after,   UVM_ALL_ON)
  `uvm_object_utils_end

  // ---------------------------------------------------------------------------
  // Constraints - Request Patterns
  // Mix: no req, single, multiple, all (per verification plan)
  // ---------------------------------------------------------------------------
  constraint c_req_patterns {
    req dist {
      '0             := 10,  // no request
      [1:(1<<N)-1]   := 90   // any non-zero pattern (single, 2-3, or all bits)
    };
  }

  constraint c_hold {
    hold_cycles inside {[0:70]};  // Include 63, 64, 65 for timeout testing
  }

  constraint c_idle_before {
    idle_before inside {[0:5]};
  }

  constraint c_idle_after {
    idle_after inside {[0:5]};
  }

  // Soft constraint: bias timeout boundary for coverage
  constraint c_timeout_boundary {
    soft hold_cycles dist {
      [0:62]   := 80,
      [63:65]  := 15,  // timeout boundary
      [66:70]  := 5
    };
  }

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  function new(string name = "RrReqItem");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // do_copy
  // ---------------------------------------------------------------------------
  virtual function void do_copy(uvm_object rhs);
    RrReqItem #(N) rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("DO_COPY", "Cast failed")
      return;
    end
    super.do_copy(rhs);
    req         = rhs_.req;
    hold_cycles = rhs_.hold_cycles;
    idle_before = rhs_.idle_before;
    idle_after  = rhs_.idle_after;
  endfunction

  // ---------------------------------------------------------------------------
  // do_compare
  // ---------------------------------------------------------------------------
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    RrReqItem #(N) rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return (req == rhs_.req) &&
           (hold_cycles == rhs_.hold_cycles) &&
           (idle_before == rhs_.idle_before) &&
           (idle_after == rhs_.idle_after);
  endfunction

  // ---------------------------------------------------------------------------
  // do_print
  // ---------------------------------------------------------------------------
  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("req",         req,         N,  UVM_BIN);
    printer.print_field("hold_cycles", hold_cycles, 32, UVM_DEC);
    printer.print_field("idle_before", idle_before, 32, UVM_DEC);
    printer.print_field("idle_after",  idle_after,  32, UVM_DEC);
  endfunction

  // ---------------------------------------------------------------------------
  // convert2string
  // ---------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("RrReqItem: req=%b hold=%0d idle_before=%0d idle_after=%0d",
                    req, hold_cycles, idle_before, idle_after);
  endfunction

endclass : RrReqItem

// Type alias for default N=4 (enables factory registration)
typedef RrReqItem #(4) RrReqItem4;
