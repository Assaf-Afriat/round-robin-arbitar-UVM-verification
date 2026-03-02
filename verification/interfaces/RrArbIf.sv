/**
 * @file RrArbIf.sv
 * @brief Round-Robin Arbiter Interface
 *
 * Interface for driving req and sampling gnt.
 */

interface RrArbIf #(int N = 4) (input logic clk, input logic rst_n);

  logic [N-1:0] req;  // Request vector (driver drives)
  logic [N-1:0] gnt;  // Grant vector (DUT drives, monitor samples)

endinterface : RrArbIf
