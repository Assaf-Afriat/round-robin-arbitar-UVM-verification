/**
 * @file RrReqDriverCb.sv
 * @brief Round-Robin Arbiter Request Driver Callbacks
 *
 * Callback base class for RrReqDriver.
 * Extend this class and override methods to customize driver behavior.
 *
 * Usage:
 *   1. Extend this class and override pre_drive/post_drive
 *   2. Create instance in test
 *   3. Register with: uvm_callbacks#(RrReqDriver4, RrReqDriverCb)::add(driver, cb);
 *
 * Note: Using non-parameterized base class for UVM callback compatibility.
 *       The driver passes 'this' and item as uvm_object, callbacks cast as needed.
 *
 * @see UVM_VERIFICATION_PLAN.md Section 11.4
 */

class RrReqDriverCb extends uvm_callback;

  `uvm_object_utils(RrReqDriverCb)

  function new(string name = "RrReqDriverCb");
    super.new(name);
  endfunction

  // ===========================================================================
  // pre_drive
  // Called BEFORE driving item to interface.
  //
  // Use cases:
  //   - Logging: Print every item before driving
  //   - Modification: Corrupt req pattern for error injection
  //   - Delay injection: Add random delays before driving
  //   - Protocol violation: Force illegal patterns
  //
  // Arguments:
  //   driver - The driver instance (as uvm_component, cast if needed)
  //   item   - The item about to be driven (as uvm_object, cast to RrReqItem)
  //
  // Return:
  //   1 = continue driving (normal)
  //   0 = skip driving this item
  // ===========================================================================
  virtual function bit pre_drive(uvm_component driver, uvm_object item);
    // Default: do nothing, continue driving
    return 1;
  endfunction

  // ===========================================================================
  // post_drive
  // Called AFTER driving item to interface.
  //
  // Use cases:
  //   - Statistics: Count driven items per pattern type
  //   - Synchronization: Signal other components
  //   - Waveform markers: Add markers for debug
  //   - Coverage: Sample driver-side coverage
  //
  // Arguments:
  //   driver - The driver instance
  //   item   - The item that was driven
  // ===========================================================================
  virtual function void post_drive(uvm_component driver, uvm_object item);
    // Default: do nothing
  endfunction

endclass : RrReqDriverCb


// =============================================================================
// Example: Error Injection Callback (for N=4)
// Randomly corrupts req pattern for negative testing
// =============================================================================
class RrReqDriverErrInjectCb extends RrReqDriverCb;

  `uvm_object_utils(RrReqDriverErrInjectCb)

  // Probability of corruption (0-100)
  int unsigned corruption_pct = 0;

  // Statistics
  int items_driven;
  int items_corrupted;

  function new(string name = "RrReqDriverErrInjectCb");
    super.new(name);
    items_driven = 0;
    items_corrupted = 0;
  endfunction

  virtual function bit pre_drive(uvm_component driver, uvm_object item);
    RrReqItem4 req_item;
    int rand_val;

    items_driven++;

    // Cast to concrete type
    if (!$cast(req_item, item)) begin
      `uvm_warning("DRV_CB", "Could not cast item to RrReqItem4")
      return 1;
    end

    if (corruption_pct > 0) begin
      rand_val = $urandom_range(0, 99);
      if (rand_val < corruption_pct) begin
        bit [3:0] original_req = req_item.req;
        // Flip a random bit
        req_item.req = req_item.req ^ (1 << $urandom_range(0, 3));
        items_corrupted++;
        `uvm_warning("DRV_CB", $sformatf("ERROR INJECTION: req %b -> %b", original_req, req_item.req))
      end
    end

    return 1; // Continue driving
  endfunction

  virtual function void post_drive(uvm_component driver, uvm_object item);
    // Could add statistics logging here
  endfunction

  function void print_stats();
    `uvm_info("DRV_CB", $sformatf("Error Injection Stats: %0d/%0d items corrupted (%0d%%)",
              items_corrupted, items_driven,
              (items_driven > 0) ? (items_corrupted * 100 / items_driven) : 0), UVM_LOW)
  endfunction

endclass : RrReqDriverErrInjectCb


// =============================================================================
// Example: Logging Callback
// Logs every item at configurable verbosity
// =============================================================================
class RrReqDriverLogCb extends RrReqDriverCb;

  `uvm_object_utils(RrReqDriverLogCb)

  // Logging verbosity
  uvm_verbosity log_verbosity = UVM_MEDIUM;

  // Item counter
  int item_count;

  function new(string name = "RrReqDriverLogCb");
    super.new(name);
    item_count = 0;
  endfunction

  virtual function bit pre_drive(uvm_component driver, uvm_object item);
    RrReqItem4 req_item;

    item_count++;

    if ($cast(req_item, item))
      `uvm_info("DRV_CB", $sformatf("[PRE_DRIVE #%0d] %s", item_count, req_item.convert2string()), log_verbosity)
    else
      `uvm_info("DRV_CB", $sformatf("[PRE_DRIVE #%0d] item (unknown type)", item_count), log_verbosity)

    return 1;
  endfunction

  virtual function void post_drive(uvm_component driver, uvm_object item);
    `uvm_info("DRV_CB", $sformatf("[POST_DRIVE #%0d] Complete @ %0t", item_count, $time), log_verbosity)
  endfunction

endclass : RrReqDriverLogCb
