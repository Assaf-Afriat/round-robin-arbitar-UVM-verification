# Questa/ModelSim run script for Round-Robin Arbiter UVM
# Run from project root: vsim -do verification/run_uvm.do

if {[file exists work]} { vdel -all }
vlib work

if {[info exists env(UVM_HOME)] && $env(UVM_HOME) != ""} {
  set UVM_HOME $env(UVM_HOME)
} else {
  set UVM_HOME "C:/questasim64_2025.1_2/verilog_src/uvm-1.1d"
}

cd verification
vlog +incdir+$UVM_HOME/src -sv $UVM_HOME/src/uvm_pkg.sv
vlog -sv interfaces/RrArbIf.sv
vlog +incdir+$UVM_HOME/src -sv pkg/RrUvmPkg.sv
vlog +incdir+$UVM_HOME/src -sv tb_top.sv
cd ..

vsim -voptargs=+acc work.tb_top
run -all
quit -f
