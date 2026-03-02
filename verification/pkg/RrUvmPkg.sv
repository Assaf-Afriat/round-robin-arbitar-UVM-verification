/**
 * @file RrUvmPkg.sv
 * @brief Round-Robin Arbiter UVM Package
 *
 * Single package for all UVM verification components.
 * Usage: import RrUvmPkg::*;
 */

package RrUvmPkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Note: RrArbIf interface is compiled separately (cannot be in package)

  // Transactions
  `include "transactions/RrReqItem.sv"
  `include "transactions/RrGntItem.sv"

  // Agent (callbacks must be before driver)
  `include "agent/RrAgentConfig.sv"
  `include "agent/RrReqDriverCb.sv"
  `include "agent/RrReqDriver.sv"
  `include "agent/RrReqSequencer.sv"
  `include "agent/RrGntMonitor.sv"
  `include "agent/RrReqAgent.sv"

  // Scoreboard (includes reference model)
  `include "scoreboard/RrRefModel.sv"
  `include "scoreboard/RrScoreboard.sv"

  // Coverage
  `include "coverage/RrCoverageCollector.sv"

  // Env
  `include "env/RrEnv.sv"

  // Sequences
  `include "sequences/RrBaseReqSeq.sv"
  `include "sequences/RrTimeoutSeq.sv"
  `include "sequences/RrStressSeq.sv"
  `include "sequences/RrCornerSeq.sv"
  `include "sequences/RrDrainSeq.sv"
  `include "sequences/virtual/RrVirtualSeq.sv"
  `include "sequences/virtual/RrCallbackVirtualSeq.sv"

  // Tests
  `include "tests/RrBaseTest.sv"
  `include "tests/RrFullTest.sv"
  `include "tests/RrTimeoutTest.sv"
  `include "tests/RrStressTest.sv"
  `include "tests/RrCornerTest.sv"
  `include "tests/RrRegressionTest.sv"
  `include "tests/RrCallbackDemoTest.sv"

endpackage : RrUvmPkg
