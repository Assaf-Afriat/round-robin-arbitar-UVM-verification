/**
 * @file tb_top.sv
 * @brief Round-Robin Arbiter UVM Testbench Top
 *
 * Instantiates DUT, interface, generates clock/reset.
 * Sets config_db and runs UVM test.
 * Binds SVA assertions to DUT.
 */

`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;
import RrUvmPkg::*;

// RTL
`include "../rtl/round_robin_arbiter.sv"

// SVA Assertions
`include "sva/rr_arbiter_sva.sv"

module tb_top;

  localparam int N = 4;

  logic clk;
  logic rst_n;

  RrArbIf #(N) arb_if (.clk(clk), .rst_n(rst_n));

  logic [$clog2(N>1?N:2)-1:0] rr_ptr_debug;
  logic [6:0] hold_cnt_debug;

  round_robin_arbiter #(
    .N           (N),
    .MAX_HOLD_CYC(64)
  ) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .req          (arb_if.req),
    .gnt          (arb_if.gnt),
    .rr_ptr_debug (rr_ptr_debug),
    .hold_cnt_debug(hold_cnt_debug)
  );

  // ============================================================================
  // SVA Bind - Connect assertions to DUT
  // ============================================================================
  bind dut rr_arbiter_sva #(
    .N           (N),
    .MAX_HOLD_CYC(64)
  ) sva_inst (
    .clk   (clk),
    .rst_n (rst_n),
    .req   (req),
    .gnt   (gnt)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    repeat (10) @(posedge clk);
    rst_n = 1;
    `uvm_info("TB_TOP", "Reset deasserted", UVM_MEDIUM)
  end

  initial begin
    arb_if.req = '0;
  end

  initial begin
    uvm_config_db#(virtual RrArbIf #(N))::set(null, "*", "rr_arb_if", arb_if);
    run_test("RrBaseTest4");
    #100;
    $finish;
  end

endmodule : tb_top
