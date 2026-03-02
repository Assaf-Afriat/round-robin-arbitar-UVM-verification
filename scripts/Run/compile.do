# QuestaSim Compile Script for Round-Robin Arbiter UVM Verification
# Usage: vsim -c -do compile.do
# Note: Run this script from the scripts/Run directory
# It will change to project root (../..) before compiling

# Set working directory to project root
cd ../..

# Create sim/ folder and work library
file mkdir sim
vlib sim/work
vmap work sim/work

# UVM include path for uvm_macros.svh
# Uses Questa's built-in UVM source location
if {[info exists ::env(QUESTASIM_DIR)]} {
    set UVM_HOME "$::env(QUESTASIM_DIR)/../verilog_src/uvm-1.1d"
} elseif {[info exists ::env(MTI_HOME)]} {
    set UVM_HOME "$::env(MTI_HOME)/verilog_src/uvm-1.1d"
} else {
    set UVM_HOME "C:/questasim64_2025.1_2/verilog_src/uvm-1.1d"
}

# Compile interface (interfaces cannot be inside packages)
vlog -sv -work work +incdir+verification verification/interfaces/RrArbIf.sv

# Compile UVM package (includes all verification components)
# Uses Questa's built-in UVM library (mtiUvm) - need -L mtiUvm to find uvm_pkg
# Add +cover=bcesft for coverage: branch, condition, expression, statement, fsm, toggle
vlog -sv -work work -L mtiUvm +cover=bcesft +incdir+$UVM_HOME/src +incdir+verification verification/pkg/RrUvmPkg.sv

# Compile testbench top (RTL is included via `include)
vlog -sv -work work -L mtiUvm +cover=bcesft +incdir+$UVM_HOME/src +incdir+verification verification/tb_top.sv

quit -force
