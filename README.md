## Edge-AI NPU Core: 8x8 INT4 Systolic Array


Tapeout Status: SUCCESS (GDSII Generated)

Process Node: SkyWater 130nm

Silicon Area: 8x2 Tiny Tapeout Tiles (~16,000 logic gates)

Verification: Cocotb (RTL & Gate-Level Simulation)

### Architecture Overview
This project implements a hardware AI accelerator using a Systolic Wavefront Dataflow. Instead of reading and writing to memory for every calculation like a standard CPU, this core passes data continuously through a grid of Processing Elements (PEs), maximizing throughput for Matrix Multiplication operations.

Processing Elements (Micro-MACs): 64 custom cores operating in an 8x8 grid.

Precision: INT4 Weights & Activations, INT16 Accumulators.

Dataflow: Weight-Stationary.

I/O Bottleneck Mitigation: A custom 8-bit to 32-bit staging buffer feeds the array, and a hardware multiplexer outputs the 128-bit internal results through a narrow 8-bit pad frame.

### The Tapeout Journey
Designing this ASIC required navigating the deep physical realities of semiconductor engineering, from RTL design to Gate-Level physics.

1. Solving the Single-Trigger Logic Trap
In SystemVerilog, declaring a logic variable linked to an input pin evaluates exactly once at power-on. To maintain a continuous physical connection to the external pads, all control paths were re-architected to use physical wire continuous assignments.

2. The Area Constraint: INT4 Quantization
The initial design utilized INT8 multipliers and INT32 accumulators. During OpenLane Physical Synthesis, this resulted in 186% Utilization of the maximum allowable silicon area (8x2 tiles), causing a global placement failure.

The Architect's Compromise: The math precision was scaled down to INT4. Because hardware multipliers scale quadratically, this shrank the logic footprint by over 70%, allowing the full 64-core grid to comfortably route at ~55% utilization.

3. Defeating Gate-Level Setup/Hold Violations
During Gate-Level Simulation (GLS), the physical SkyWater 130nm flip-flops went metastable, outputting an endless stream of X (unknown) states.

The Fix: The Python Cocotb testbench was completely decoupled from the clock's rising edge. Data inputs were shifted to the FallingEdge, granting the physical voltages a full 10 nanoseconds of propagation time to reach the logic gates and stabilize before the clock struck.

4. Preventing X-Poisoning (Time-Zero Initialization)
GLS introduces the reality of Time-Zero physics. When the simulation started, the clock ticked before the reset pin was physically tied to ground, causing "Zombie" X states to permanently poison the entire 8x8 grid.

The Fix: A Timer(1, units="ns") was injected into the testbench to forcefully initialize all input pins to hard 0s and 1s before the 50MHz crystal oscillator was allowed to start.

5. The OpenLane Power Tie-Off Hack
During final GLS Elaboration, the chip failed to power on because the synthesizer left the standard cell power nets floating.

The Fix: A Verilog $deposit system task was injected exclusively under the GL_TEST macro to forcefully inject voltage into the VPWR and VGND nets, waking the chip up for simulation without breaking the physical layout.

### Verification Outputs
The NPU was verified using a cycle-accurate Python testbench (Cocotb) against the physical SkyWater 130nm Gate-Level Netlist.

By pushing a uniform matrix of 1s through the 8x8 INT4 grid, we mathematically proved the systolic wavefront routing. Every cycle, the math accumulates as it ripples down the silicon columns.

```bash 
  110.00ns INFO     cocotb.tb    --- PHASE 1: FLOODING THE GRID WITH WEIGHTS ---
 1491.00ns INFO     cocotb.tb    --- PHASE 2: FLOODING ACTIVATIONS & WATCHING PINS ---
 ...
 2391.00ns INFO     cocotb.tb    Cycle 44: Output Pin = 1
 2411.00ns INFO     cocotb.tb    Cycle 45: Output Pin = 2
 2431.00ns INFO     cocotb.tb    Cycle 46: Output Pin = 3
 2451.00ns INFO     cocotb.tb    Cycle 47: Output Pin = 4
 2471.00ns INFO     cocotb.tb    Cycle 48: Output Pin = 5
 2491.00ns INFO     cocotb.tb    Cycle 49: Output Pin = 6
 2511.00ns INFO     cocotb.tb    Cycle 50: Output Pin = 7
 2531.00ns INFO     cocotb.tb    Cycle 51: Output Pin = 8
 2531.00ns INFO     cocotb.tb    SUCCESS! Caught the wave in the physical Gate-Level Netlist!
```
 
**Physical Layout (GDSII)**
The final Graphic Data System II (GDSII) layout routed by OpenLane, showcasing the dense standard cell placement of the 64 Processing Elements and the horizontal multi-layer metal mesh distributed across the 8x2 physical tile boundary.
![GDSII Render of the Systolic Array](gds_render.png)
