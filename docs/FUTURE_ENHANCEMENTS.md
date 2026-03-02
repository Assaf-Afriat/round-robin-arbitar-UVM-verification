# Future Enhancements

This document tracks planned improvements and feature ideas for the Round-Robin Arbiter UVM verification environment.

---

## 1. Interface Enhancements

### 1.1 Clocking Blocks

Add clocking blocks to `RrArbIf` for cleaner timing and race-condition avoidance.

**Current:**
```systemverilog
interface RrArbIf #(int N = 4) (input logic clk, input logic rst_n);
  logic [N-1:0] req;
  logic [N-1:0] gnt;
endinterface
```

**Proposed:**
```systemverilog
interface RrArbIf #(int N = 4) (input logic clk, input logic rst_n);
  logic [N-1:0] req;
  logic [N-1:0] gnt;

  // Driver clocking block - drives inputs
  clocking drv_cb @(posedge clk);
    default input #1step output #0;
    output req;
    input  gnt;
  endclocking

  // Monitor clocking block - samples all signals
  clocking mon_cb @(posedge clk);
    default input #1step;
    input req;
    input gnt;
  endclocking

  // DUT clocking block (for assertions)
  clocking dut_cb @(posedge clk);
    input req;
    input gnt;
  endclocking

endinterface
```

**Benefits:**
- Eliminates race conditions between driver/monitor
- Clear separation of input/output timing
- `#1step` input sampling avoids setup/hold issues
- Cleaner code in driver/monitor (use `m_vif.drv_cb.req <= ...`)

---

### 1.2 Modports

Add modports to restrict signal access per component.

**Proposed:**
```systemverilog
interface RrArbIf #(int N = 4) (input logic clk, input logic rst_n);
  logic [N-1:0] req;
  logic [N-1:0] gnt;

  // Clocking blocks (see 1.1)
  clocking drv_cb @(posedge clk); ... endclocking
  clocking mon_cb @(posedge clk); ... endclocking

  // Modport for driver - can only drive req
  modport driver_mp (
    clocking drv_cb,
    input clk, rst_n
  );

  // Modport for monitor - read-only access
  modport monitor_mp (
    clocking mon_cb,
    input clk, rst_n
  );

  // Modport for DUT connection
  modport dut_mp (
    input  clk, rst_n, req,
    output gnt
  );

endinterface
```

**Benefits:**
- Compile-time enforcement of access rules
- Driver cannot accidentally read `gnt` directly
- Monitor cannot accidentally drive signals
- Clearer intent in component declarations

**Driver usage:**
```systemverilog
virtual RrArbIf #(N).driver_mp m_vif;
// ...
m_vif.drv_cb.req <= item.req;
```

**Monitor usage:**
```systemverilog
virtual RrArbIf #(N).monitor_mp m_vif;
// ...
sampled_req = m_vif.mon_cb.req;
sampled_gnt = m_vif.mon_cb.gnt;
```

---

## 2. Additional Callbacks

### 2.1 Monitor Callback (`RrGntMonitorCb`)

Add callbacks to the monitor for observing/modifying sampled transactions.

**Proposed hooks:**
```systemverilog
class RrGntMonitorCb extends uvm_callback;

  // Called after sampling, before broadcasting to analysis port
  // Return 0 to suppress broadcasting this item
  virtual function bit on_sample(RrGntMonitor mon, RrGntItem item);
    return 1; // Default: broadcast
  endfunction

  // Called when specific pattern detected
  virtual function void on_pattern(RrGntMonitor mon, string pattern_name, RrGntItem item);
    // Default: do nothing
  endfunction

endclass
```

**Use cases:**
- **Logging**: Debug-level logging of every sample
- **Filtering**: Suppress certain transactions from scoreboard
- **Statistics**: Count specific patterns (e.g., all-ones req)
- **Triggers**: Signal events when specific conditions occur

---

### 2.2 Scoreboard Callback (`RrScoreboardCb`)

Add callbacks to the scoreboard for mismatch handling and prediction observation.

**Proposed hooks:**
```systemverilog
class RrScoreboardCb extends uvm_callback;

  // Called before comparison
  virtual function void pre_compare(RrScoreboard scb, 
                                    RrGntItem actual, 
                                    logic [N-1:0] expected_gnt);
  endfunction

  // Called on mismatch - can override error handling
  // Return 1 to suppress default error message
  virtual function bit on_mismatch(RrScoreboard scb,
                                   RrGntItem actual,
                                   logic [N-1:0] expected_gnt);
    return 0; // Default: report error normally
  endfunction

  // Called on match
  virtual function void on_match(RrScoreboard scb, RrGntItem actual);
  endfunction

endclass
```

**Use cases:**
- **Error injection testing**: Expect and tolerate specific mismatches
- **Custom error handling**: Log to file, trigger debug mode
- **Match statistics**: Track match patterns for coverage
- **Mismatch analysis**: Detailed logging of failure context

**Example - Mismatch Tolerance:**
```systemverilog
class RrScoreboardMismatchToleranceCb extends RrScoreboardCb;
  int allowed_mismatches = 5;
  int mismatch_count = 0;

  virtual function bit on_mismatch(RrScoreboard scb,
                                   RrGntItem actual,
                                   logic [N-1:0] expected_gnt);
    mismatch_count++;
    if (mismatch_count <= allowed_mismatches) begin
      `uvm_warning("SCB_CB", $sformatf("Tolerating mismatch %0d/%0d", 
                   mismatch_count, allowed_mismatches))
      return 1; // Suppress default error
    end
    return 0; // Report error
  endfunction
endclass
```

---

### 2.3 Reference Model Callback (`RrRefModelCb`)

Add callbacks to observe predictions.

**Proposed hooks:**
```systemverilog
class RrRefModelCb extends uvm_callback;

  // Called after prediction computed
  virtual function void on_prediction(RrRefModel model,
                                      logic [N-1:0] req,
                                      logic [N-1:0] predicted_gnt,
                                      int rr_ptr);
  endfunction

  // Called on pointer update
  virtual function void on_ptr_update(RrRefModel model,
                                      int old_ptr,
                                      int new_ptr);
  endfunction

endclass
```

**Use cases:**
- **Debug**: Trace prediction logic step-by-step
- **Coverage**: Sample prediction-related coverage
- **Comparison**: Compare against alternative models

---

## 3. Advanced Test Scenarios

### 3.1 Back-to-Back Grant Transitions

Test rapid grant switching without idle cycles.

### 3.2 Reset During Active Grant

Apply reset while a grant is active, verify clean recovery.

### 3.3 Glitch Injection

Use driver callback to inject single-cycle glitches on `req`.

### 3.4 Power-Aware Verification

Add clock gating scenarios if DUT supports it.

---

## 4. Coverage Enhancements

### 4.1 Transition Coverage

- Cover all `gnt[i]` to `gnt[j]` transitions
- Cover `req` pattern changes while holding grant

### 4.2 Timing Coverage

- Cover grants at different hold durations
- Cover near-timeout scenarios

### 4.3 Corner Case Bins

- Single requester sustained
- All requesters sustained
- Rapid on/off toggling

---

## 5. Infrastructure Improvements

### 5.1 Regression Script

- Parallel test execution
- Coverage merging
- HTML report generation

### 5.2 Constrained Random Improvements

- Weighted distribution for `req` patterns
- Configurable hold time distributions

### 5.3 Formal Verification Hooks

- Property files for formal tools
- Assertion coverage tracking

---

## Implementation Priority

| Priority | Feature | Effort | Value |
|----------|---------|--------|-------|
| High | Clocking blocks + Modports | Medium | High |
| Medium | Scoreboard callback | Low | Medium |
| Medium | Monitor callback | Low | Medium |
| Low | Reference model callback | Low | Low |
| Low | Regression script | Medium | High |

---

## Notes

- Clocking blocks require changes to driver and monitor `run_phase`
- Modports require updating `uvm_config_db` virtual interface types
- Callbacks can be added incrementally without breaking existing tests
