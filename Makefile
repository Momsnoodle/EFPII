# Source files
VERILOG_SOURCES = $(PWD)/MemoryGameStateMachine.sv
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=MemoryGameStateMachine
# MODULE is the name of the Python test file:
MODULE=MemoryGameStateMachineTest


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 1ns
# Tell it to trace the result
EXTRA_ARGS += --trace --trace-structs

# Run the simulation
include $(shell cocotb-config --makefiles)/Makefile.sim


