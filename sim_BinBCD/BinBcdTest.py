import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.result import TestFailure


@cocotb.test()
async def BinBcdTest(dut):
    """Try accessing the design."""

    # set up the clock
    clock = Clock(dut.clk_i, 20, units="ns")  # Create a 20ns period clock
    cocotb.fork(clock.start())  # Start the clock
    # Synchronize with the clock
    await FallingEdge(dut.clk_i)
    
    # set up the input signals and do a reset
    dut.reset_i = 1
    dut.start_i = 0
    dut.binary_i = 12345
    await FallingEdge(dut.clk_i)
    
    # switch off the reset
    dut.reset_i = 0
    await FallingEdge(dut.clk_i)
    
    # start conversion:
    dut.start_i = 1
    await FallingEdge(dut.clk_i)
    
    
    # wait a bit, set the start to 0 and wait again...
    await Timer(1000, "ns")
    dut.start_i = 0
    await Timer(100, "ns")
    
    
    # check if we got the correct result:
    for i in range(0,5):
        if (dut.bcd_o[i] != 5-i):
            raise TestFailure("Wrong result")
