# Round-Robin Arbiter with UVM Verification

A complete SystemVerilog RTL design with production-quality UVM verification environment.

![Verification](https://img.shields.io/badge/Verification-PASSED-brightgreen)
![Assertions](https://img.shields.io/badge/Assertions-100%25-blue)
![Coverage](https://img.shields.io/badge/Coverage->95%25-blue)
![UVM](https://img.shields.io/badge/UVM-1.1d-orange)

## Overview

This project demonstrates industry-standard verification practices on a parameterized N-way round-robin arbiter with starvation prevention.

**Verification Results:**
- 5/5 tests PASSED
- 100% assertion coverage (0 failures)
- ~50,000 scoreboard comparisons (0 mismatches)
- \>95% functional coverage

## Key Skills Demonstrated

| Category | Skills |
|----------|--------|
| RTL Design | Parameterized SystemVerilog, FSM, timeout mechanism |
| UVM | Agents, scoreboard, reference model, coverage collector |
| SVA | Protocol assertions, cover properties |
| Coverage | Covergroups, crosses, coverage-driven verification |
| Automation | Python + Tcl scripting for Questa/ModelSim |

## Design Specification

**Parameters:**
- `N = 4` (configurable number of requesters)
- `MAX_HOLD_CYC = 64` (starvation prevention timeout)

**Interface:**

| Signal | Dir | Width | Description |
|--------|-----|-------|-------------|
| clk | in | 1 | Clock |
| rst_n | in | 1 | Active-low async reset |
| req | in | N | Request vector |
| gnt | out | N | One-hot grant vector |

**Behavior:**
- Round-robin fairness: after granting `i`, priority moves to `i+1`
- Starvation prevention: force re-arbitration after 64 hold cycles
- Registered output: grant appears 1 cycle after arbitration
- Handshake: requester holds `req` until transaction complete

## Verification Summary

### Test Results

| Test | Purpose | Status |
|------|---------|--------|
| RrFullTest4 | Complete verification | PASS |
| RrTimeoutTest4 | Timeout boundary (63-65 cycles) | PASS |
| RrStressTest4 | Back-to-back high traffic | PASS |
| RrCornerTest4 | Directed corner cases | PASS |
| RrRegressionTest4 | Extended random regression | PASS |

### SVA Assertions

| ID | Property | Status |
|----|----------|--------|
| A1 | Grant is one-hot or zero | PASS |
| A2 | No request implies no grant | PASS |
| A3 | Grant implies request active | PASS |
| A5 | No starvation (timeout works) | PASS |
| A8 | Reset clears grant | PASS |

## Architecture

```
+------------------------------------------------------------------+
|                         UVM Testbench                            |
|  +------------------------------------------------------------+  |
|  |  RrVirtualSeq: BasicSeq -> TimeoutSeq -> StressSeq -> ...  |  |
|  +------------------------------------------------------------+  |
|                              |                                   |
|  +---------------------------v--------------------------------+  |
|  |                        RrEnv                               |  |
|  |  +-----------+  +-------------+  +---------------------+   |  |
|  |  | RrReqAgent|  | RrScoreboard|  | RrCoverageCollector |   |  |
|  |  |  - Driver |  |  - RefModel |  |  - 5 covergroups    |   |  |
|  |  |  - Monitor|->|  - Compare  |  |  - crosses          |   |  |
|  |  |  - Seqr   |  +-------------+  +---------------------+   |  |
|  |  +-----------+                                             |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
                             |
        +--------------------+--------------------+
        v                    v                    v
   +---------+        +------------+        +-----------+
   | RrArbIf |<------>|    DUT     |<------>|    SVA    |
   |  (vif)  |        | N=4,MAX=64 |        | 5 asserts |
   +---------+        +------------+        +-----------+
```

## Quick Start

```bash
cd scripts/Run
python run.py --clean --test RrFullTest4 --coverage-report
```

**Prerequisites:** Questa/ModelSim, Python 3.x

## Project Structure

```
round-robin-arbiter/
├── rtl/                    # RTL source
│   └── round_robin_arbiter.sv
├── spec/                   # Design specification
│   └── SPEC.md
├── verification/           # UVM testbench
│   ├── pkg/                # UVM package
│   ├── agent/              # Driver, Monitor, Sequencer
│   ├── scoreboard/         # Scoreboard + Reference Model
│   ├── coverage/           # Functional Coverage
│   ├── sequences/          # Stimulus sequences
│   ├── tests/              # UVM tests
│   ├── sva/                # SystemVerilog Assertions
│   └── tb_top.sv           # Testbench top
├── scripts/Run/            # Simulation scripts
│   ├── run.py              # Main run script
│   └── *.do                # Questa scripts
└── docs/                   # Documentation
    ├── UVM_VERIFICATION_PLAN.md
    └── SIGN_OFF.md
```

## Documentation

- [Design Specification](spec/SPEC.md)
- [Verification Plan](docs/UVM_VERIFICATION_PLAN.md)
- [Sign-Off Report](docs/SIGN_OFF.md)
- [Run Scripts](scripts/Run/README.md)

## Technologies

- SystemVerilog (IEEE 1800-2017)
- UVM 1.1d
- Questa/ModelSim 2025.1
- Python 3, Tcl

## Author

Assaf Afriat
