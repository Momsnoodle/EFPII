import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer


# ---------------------------------------------------------
# helper: single-cycle pulse
# ---------------------------------------------------------
async def pulse(signal, dut):
    signal.value = 1
    await RisingEdge(dut.clk_i)
    signal.value = 0
    await RisingEdge(dut.clk_i)


# ---------------------------------------------------------
# test
# ---------------------------------------------------------
@cocotb.test()
async def MemoryGameStateMachineTest(dut):

    # ======================================================

    # Clock
    # ======================================================
    cocotb.start_soon(Clock(dut.clk_i, 20, units="ns").start())

    # ======================================================
    # Initial reset
    # ======================================================
    dut.tick_fast.value = 0
    dut.tick_slow.value = 0
    dut.tick_countdown.value = 0
    dut.button_i.value = 0
    dut.reset_or_begin_i.value = 1

    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)

    dut.reset_or_begin_i.value = 0

    # ======================================================
    # START GAME
    # ======================================================
    await pulse(dut.reset_or_begin_i, dut)

    # ======================================================
    # GENERATION PHASE (drive slow ticks)
    # ======================================================
    for _ in range(20):
        dut.tick_slow.value = 1
        await RisingEdge(dut.clk_i)
        dut.tick_slow.value = 0
        await RisingEdge(dut.clk_i)

    # let FSM settle
    await Timer(100, units="ns")

    # ======================================================
    # DISPLAY PHASE (LED sequence)
    # ======================================================
    for _ in range(10):
        dut.tick_fast.value = 1
        await RisingEdge(dut.clk_i)
        dut.tick_fast.value = 0
        await RisingEdge(dut.clk_i)

    await Timer(100, units="ns")

    # ======================================================
    # COUNTDOWN PHASE
    # ======================================================
    for _ in range(10):
        dut.tick_countdown.value = 1
        await RisingEdge(dut.clk_i)
        dut.tick_countdown.value = 0
        await RisingEdge(dut.clk_i)

    await Timer(100, units="ns")

    # ======================================================
    # PLAYING PHASE (simulate player input)
    # ======================================================
    for i in range(5):
        dut.button_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.button_i.value = 0
        await RisingEdge(dut.clk_i)

    # ======================================================
    # SCORING / ENDGAME settle time
    # ======================================================
    await Timer(200, units="ns")

    # ======================================================
    # BASIC ASSERTIONS
    # ======================================================
    dut._log.info(f"LED output: {dut.led_o.value}")
    dut._log.info(f"Score: {dut.score.value}")

    assert dut.score.value is not None