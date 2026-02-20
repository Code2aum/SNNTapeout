<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a Leaky Integrate-and-Fire (LIF) spiking neuron in synthesizable Verilog.

Each clock cycle the neuron performs three operations:
1. **Leak** — the membrane potential decays by V/16 (arithmetic right shift by 4)
2. **Integrate** — the 8-bit input current on ui_in is added to the membrane potential
3. **Fire** — if the membrane crosses the threshold (256), a spike is emitted on uo_out[7] and the membrane resets to 0, followed by a 4-cycle refractory period

## How to test

1. Hold rst_n LOW for at least 2 clock cycles to reset the neuron
2. Release rst_n HIGH and set ena HIGH
3. Drive ui_in with an 8-bit value representing input current (e.g. 0x30 for moderate firing rate)
4. Monitor uo_out[7] for spike pulses — each HIGH pulse is one spike
5. Monitor uo_out[6:0] and uio_out[7:0] together for a 15-bit view of the membrane potential

## External hardware

No external hardware required. All inputs are driven digitally and all outputs are digital signals.
