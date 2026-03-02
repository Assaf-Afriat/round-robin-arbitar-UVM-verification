# Elaborate the top module for Round-Robin Arbiter
# Set working directory to project root
cd ../..

# Elaborate with coverage (required for --coverage-report)
# -L mtiUvm links Questa's built-in UVM library
vopt +acc=npr +cover=bcesft -L mtiUvm -o tb_top_opt work.tb_top
quit -force
