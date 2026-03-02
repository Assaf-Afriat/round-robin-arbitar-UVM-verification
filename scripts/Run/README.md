# Round-Robin Arbiter UVM Run Scripts

Questa/ModelSim run flow adapted from the CPM project.

## Prerequisites

- Questa/ModelSim in PATH
- Uses Questa's built-in UVM library (`-L mtiUvm`)

## Usage

From project root:

```bash
cd scripts/Run
python run.py
```

## Available Tests

| Test Name | Description |
|-----------|-------------|
| `RrBaseTest4` | Basic sanity test (30 random items) |
| `RrFullTest4` | Full virtual sequence (basic + timeout + stress + corner) |
| `RrTimeoutTest4` | Focus on timeout boundary (63, 64, 65 cycle holds) |
| `RrStressTest4` | Back-to-back stress testing (200 items) |
| `RrCornerTest4` | Directed corner case scenarios |
| `RrRegressionTest4` | Full regression (longer runs) |

## Options

| Option | Description |
|--------|-------------|
| `--test <name>` | UVM test name (default: RrBaseTest4) |
| `--seed <n>` | Random seed (default: 1) |
| `--verbosity <level>` | UVM_NONE, UVM_LOW, UVM_MEDIUM, UVM_HIGH, UVM_FULL, UVM_DEBUG |
| `--gui` | Run in GUI mode with waveform |
| `--clean` | Clean sim/work before compile |
| `--no-compile` | Skip compile and elaborate |
| `--coverage-report` | Enable coverage and generate reports |
| `--timeout <sec>` | Simulation timeout in seconds (default: 300) |

## Examples

```bash
# Basic sanity test
python run.py

# Full coverage run (recommended)
python run.py --test RrFullTest4 --coverage-report

# GUI with waveform
python run.py --gui

# Timeout scenarios
python run.py --test RrTimeoutTest4

# Regression with verbose output
python run.py --test RrRegressionTest4 --verbosity UVM_HIGH

# Clean build with coverage
python run.py --clean --coverage-report --test RrFullTest4
```

## Output

- **Logs**: `logs/<test>.log`
- **Waveform**: `logs/<test>.wlf`
- **Coverage**: `coverage/<test>.ucdb` (when `--coverage-report`)

## Assertion Report

After a run with `--coverage-report`:

```bash
vsim -c -do assertion_report.do
```

Generates assertion reports in `coverage/assertion_report/`.

## modelsim.ini

Project root contains `modelsim.ini` with:

- `work = sim/work` – work library location
- `others = $QUESTASIM_DIR/../modelsim.ini` – inherits installation config
