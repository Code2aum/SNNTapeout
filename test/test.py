import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def decode_outputs(uo_val, uio_val):
    spike  = (uo_val >> 7) & 1
    v_lo   = uo_val & 0x7F
    v_hi   = uio_val & 0xFF
    v_mem  = (v_hi << 7) | v_lo
    return spike, v_mem

async def reset_dut(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    dut.rst_n.value = 0
    dut.ena.value   = 0
    dut.ui_in.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    dut.ena.value   = 1
    await RisingEdge(dut.clk)

@cocotb.test()
async def test_periodic_firing(dut):
    await reset_dut(dut)
    dut.ui_in.value = 0x30
    spike_count  = 0
    spike_cycles = []
    for cycle in range(150):
        await RisingEdge(dut.clk)
        spike, v_mem = decode_outputs(int(dut.uo_out.value), int(dut.uio_out.value))
        if spike:
            spike_count += 1
            spike_cycles.append(cycle)
            cocotb.log.info(f"Cycle {cycle:4d}: SPIKE #{spike_count}  |  v_mem={v_mem:#06x}")
    assert spike_count > 0, "Neuron NEVER fired in 150 cycles!"
    cocotb.log.info(f"TEST 1 PASSED — {spike_count} spikes | cycles: {spike_cycles}")

@cocotb.test()
async def test_membrane_decay(dut):
    await reset_dut(dut)
    dut.ui_in.value = 0x40
    for _ in range(25):
        await RisingEdge(dut.clk)
    dut.ui_in.value = 0x00
    v_mem = 0
    for cycle in range(60):
        await RisingEdge(dut.clk)
        _, v_mem = decode_outputs(int(dut.uo_out.value), int(dut.uio_out.value))
        cocotb.log.info(f"Decay cycle {cycle:3d}: v_mem={v_mem}")
    assert v_mem < 20, f"Membrane did not decay! Final v_mem={v_mem}"
    cocotb.log.info("TEST 2 PASSED — membrane decayed correctly")

@cocotb.test()
async def test_refractory_period(dut):
    await reset_dut(dut)
    dut.ui_in.value = 0xFF
    spike_cycles = []
    for cycle in range(30):
        await RisingEdge(dut.clk)
        if (int(dut.uo_out.value) >> 7) & 1:
            spike_cycles.append(cycle)
    for i in range(1, len(spike_cycles)):
        gap = spike_cycles[i] - spike_cycles[i-1]
        assert gap >= 4, f"Spike too soon! Gap={gap} at cycles {spike_cycles[i-1]} and {spike_cycles[i]}"
    cocotb.log.info(f"TEST 3 PASSED — spike cycles: {spike_cycles}")

@cocotb.test()
async def test_reset_behavior(dut):
    await reset_dut(dut)
    dut.ui_in.value = 0x50
    for _ in range(20):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    spike, v_mem = decode_outputs(int(dut.uo_out.value), int(dut.uio_out.value))
    assert spike == 0, f"Spike during reset! spike={spike}"
    assert v_mem == 0, f"Membrane not cleared! v_mem={v_mem}"
    cocotb.log.info("TEST 4 PASSED — reset clears membrane correctly")