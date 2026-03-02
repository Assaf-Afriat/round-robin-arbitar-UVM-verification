# Round-Robin Arbiter with UVM Verification

**A complete SystemVerilog RTL design with production-quality UVM verification environment**

[![Verification Status](https://img.shields.io/badge/Verification-PASSED-brightgreen)]()
[![Assertions](https://img.shields.io/badge/Assertions-100%25-blue)]()
[![Coverage](https://img.shields.io/badge/Coverage->95%25-blue)]()
[![UVM](https://img.shields.io/badge/UVM-1.1d-orange)]()

---

## Overview

This project demonstrates industry-standard verification practices on a parameterized N-way round-robin arbiter with starvation prevention. The verification environment achieves **100% assertion coverage**, **zero mismatches**, and **>95% functional coverage**.

### Key Skills Demonstrated

- **RTL Design**: Parameterized SystemVerilog, FSM design, timeout mechanism
- **UVM Methodology**: Complete testbench architecture with agents, scoreboard, coverage
- **SystemVerilog Assertions (SVA)**: Protocol checking, cover properties
- **Functional Coverage**: Covergroups, crosses, coverage-driven verification
- **Reference Modeling**: Cycle-accurate behavioral model for self-checking
- **Scripting**: Python + Tcl automation for Questa/ModelSim

---

## Design Specification

| Parameter | Value | Description |
|-----------|-------|-------------|
| `N` | 4 (configurable) | Number of requesters |
| `MAX_HOLD_CYC` | 64 | Starvation prevention timeout |

### Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | input | 1 | Clock |
| `rst_n` | input | 1 | Active-low async reset |
| `req` | input | N | Request vector |
| `gnt` | output | N | One-hot grant vector |

### Behavior

- **Round-Robin Fairness**: After granting requester `i`, priority moves to `i+1`
- **Starvation Prevention**: Force re-arbitration after 64 consecutive hold cycles
- **Registered Output**: Grant appears 1 cycle after arbitration decision
- **Handshake Protocol**: Requester holds `req` until transaction complete

---

## Verification Results

```
================================================================================
                    VERIFICATION SIGN-OFF
================================================================================
  Tests:              5/5 PASSED
  Assertions:         5/5 (100% coverage, 0 failures)
  Scoreboard:         ~50,000 comparisons, 0 mismatches
  Functional Coverage: >95%
================================================================================
```

### Test Suite

| Test | Purpose | Status |
|------|---------|--------|
| `RrFullTest4` | Complete verification (all scenarios) | ✅ PASS |
| `RrTimeoutTest4` | Timeout boundary (63, 64, 65 cycles) | ✅ PASS |
| `RrStressTest4` | Back-to-back high traffic | ✅ PASS |
| `RrCornerTest4` | Directed corner cases | ✅ PASS |
| `RrRegressionTest4` | Extended random regression | ✅ PASS |

### SVA Assertions

| Assertion | Property | Status |
|-----------|----------|--------|
| A1 | Grant is one-hot or zero | ✅ |
| A2 | No request → no grant | ✅ |
| A3 | Grant implies request active | ✅ |
| A5 | No starvation (timeout works) | ✅ |
| A8 | Reset clears grant | ✅ |

---

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                         UVM Testbench                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  RrVirtualSeq: BasicSeq → TimeoutSeq → StressSeq → ...  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│  ┌───────────────────────────┼───────────────────────────────┐ │
│  │                        RrEnv                              │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐│ │
│  │  │ RrReqAgent  │  │ RrScoreboard│  │RrCoverageCollector  ││ │
│  │  │  • Driver   │  │  • RefModel │  │  • 5 covergroups    ││ │
│  │  │  • Monitor  │──│  • Compare  │  │  • crosses          ││ │
│  │  │  • Sequencer│  └─────────────┘  └─────────────────────┘│ │
│  │  └─────────────┘                                          │ │
│  └───────────────────────────────────────────────────────────┘ │
└────────────────────────────┬───────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
   ┌─────────┐        ┌───────────┐        ┌───────────┐
   │ RrArbIf │◄──────►│    DUT    │◄──────►│    SVA    │
   │  (vif)  │        │ N=4,MAX=64│        │ 5 asserts │
   └─────────┘        └───────────┘        └───────────┘
```

---

## Quick Start

```bash
# Navigate to run scripts
cd scripts/Run

# Run full verification with coverage
python run.py --clean --test RrFullTest4 --coverage-report

# View results
cat ../../coverage/RrFullTest4_coverage.txt
```

### Prerequisites

- Questa/ModelSim (uses built-in UVM library)
- Python 3.x

---

## Project Structure

```
round-robin-arbiter/
├── rtl/
│   └── round_robin_arbiter.sv      # DUT
├── spec/
│   └── SPEC.md                     # Design specification
├── verification/
│   ├── pkg/RrUvmPkg.sv             # UVM package
│   ├── agent/                      # Driver, Monitor, Sequencer
│   ├── scoreboard/                 # Scoreboard + Reference Model
│   ├── coverage/                   # Functional Coverage
│   ├── sequences/                  # Stimulus sequences
│   ├── tests/                      # UVM tests
│   ├── sva/                        # SystemVerilog Assertions
│   └── tb_top.sv                   # Testbench top
├── scripts/Run/
│   ├── run.py                      # Main run script
│   └── *.do                        # Questa scripts
└── docs/
    ├── UVM_VERIFICATION_PLAN.md    # Verification plan
    └── SIGN_OFF.md                 # Sign-off report
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [SPEC.md](spec/SPEC.md) | Design specification |
| [UVM_VERIFICATION_PLAN.md](docs/UVM_VERIFICATION_PLAN.md) | Verification strategy, coverage plan |
| [SIGN_OFF.md](docs/SIGN_OFF.md) | Verification results, sign-off |
| [Run README](scripts/Run/README.md) | How to run simulations |

---

## Technologies

- **RTL**: SystemVerilog (IEEE 1800-2017)
- **Verification**: UVM 1.1d, SystemVerilog Assertions
- **Simulator**: Questa/ModelSim 2025.1
- **Scripting**: Python 3, Tcl

---

## Author

Assaf Afriat

---

## License

This project is for demonstration purposes.
#   r o u n d - r o b i n - a r b i t a r - U V M - v e r i f i c a t i o n  
 