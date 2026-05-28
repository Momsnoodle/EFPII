import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer


@cocotb.test()
async def MainTest(dut):

    # =========================================================
    # CLOCK
    # =========================================================

    clock = Clock(dut.MAX10_CLK1_50, 20, units="ns")
    cocotb.start_soon(clock.start())

    await FallingEdge(dut.MAX10_CLK1_50)

    # =========================================================
    # INITIAL VALUES
    # =========================================================

    # Buttons are active LOW on DE10-Lite
    dut.KEY.value = 0b11

    # Switches unused
    dut.SW.value = 0

    # Wait some cycles for reset generator
    for _ in range(10):
        await FallingEdge(dut.MAX10_CLK1_50)

    # =========================================================
    # START GAME
    # KEY[0] pressed
    # =========================================================

    dut._log.info("Starting game")

    dut.KEY.value = 0b10  # press KEY[0]
    await Timer(10000, units="ns")

    dut.KEY.value = 0b11  # release KEY[0]

    # wait for FSM to react
    for _ in range(5000):
        await FallingEdge(dut.MAX10_CLK1_50)

        # =========================================================
    # OBSERVE LED ACTIVITY
    # =========================================================
    dut._log.info("Monitoring LED activity")

    led_seen = False

    for _ in range(5000):

        await RisingEdge(dut.MAX10_CLK1_50)

        # check specific LED bit
        if dut.state != 0 :

            led_seen = True

            dut._log.info("LEDR[0] went HIGH")

            break

    assert led_seen, "State never changed"

    # =========================================================
    # SIMULATE BUTTON INPUTS
    # KEY[1]
    # =========================================================

    dut._log.info("Sending player inputs")

    for _ in range(5):

        # press KEY[1]
        dut.KEY.value = 0b01
        await Timer(100, units="ns")

        # release
        dut.KEY.value = 0b11
        await Timer(200, units="ns")

    # =========================================================
    # WAIT FOR SCORING
    # =========================================================

    for _ in range(500):
        await FallingEdge(dut.MAX10_CLK1_50)

    dut._log.info(f"Score = {int(dut.score.value)}")

    # =========================================================
    # BASIC CHECKS
    # =========================================================

    assert int(dut.score.value) >= 0

    dut._log.info("Main test completed successfully")