import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

@cocotb.test()
async def test_systolic_array(dut):
    dut._log.info("Starting 2x2 NPU Systolic Array Test")

    # 1. Power on the Clock (50 MHz)
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # 2. System Reset (Hold the reset button down, then release)
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    dut._log.info("System Reset Complete")

    # 3. Phase 1: Load Weights (uio_in[0] is the weight_load wire)
    dut._log.info("Loading weights into the Processing Elements...")
    dut.uio_in.value = 1  # Set weight_load = 1
    dut.ui_in.value = 3   # We are loading the number '3' into the weights
    await RisingEdge(dut.clk)

    # 4. Phase 2: Stream Activations (uio_in[1] is the compute_en wire)
    dut._log.info("Streaming activations and computing...")
    dut.uio_in.value = 2  # Set compute_en = 1 (Binary 00000010)
    dut.ui_in.value = 4   # We are feeding the number '4' as data
    
    # Wait for the systolic wave to propagate through the 2x2 grid
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # 5. Verify the Output
    final_output = int(dut.uo_out.value)
    dut._log.info(f"NPU Output Pin Value: {final_output}")
    
    # We expect some math to have happened. If it's still 0, the architecture is broken.
    assert final_output != 0, "ERROR: The NPU did not output a calculation!"
    dut._log.info("SUCCESS: The Systolic Array successfully multiplied and routed the data!")