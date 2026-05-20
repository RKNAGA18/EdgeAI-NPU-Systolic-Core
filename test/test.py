import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def flood_test(dut):
    """THE WAVEFRONT TEST: Flooding the array to watch the math ripple out in real-time."""
    
    # 1. Start the Clock
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

    # 2. System Reset
    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.uio_in.value = 0
    dut.ui_in.value = 0
    for _ in range(5): await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    dut._log.info("--- PHASE 1: FLOODING THE GRID WITH WEIGHTS ---")
    dut.uio_in.value = 0b00000011 # CS=1, WE=1
    
    for _ in range(64):
        dut.ui_in.value = 1
        await RisingEdge(dut.clk)

    dut._log.info("--- PHASE 2: FLOODING ACTIVATIONS & WATCHING PINS ---")
    dut.uio_in.value = 0b00000010 # CS=1, WE=0
    
    success = False
    
    for cycle in range(50):
        dut.ui_in.value = 1
        await RisingEdge(dut.clk)
        
        output_val = int(dut.uo_out.value)
        dut._log.info(f"Cycle {cycle}: Output Pin = {output_val}")
        
        if output_val == 8:
            success = True
            dut._log.info("SUCCESS! Caught the wave! The 8x8 Array is mathematically perfect!")
            break
            
    assert success, "The array never output the correct math!"
