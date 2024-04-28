import cocotb
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotb.clock import Clock

import numpy as np


async def reset(dut):
    dut.rst_n.value = 0

    for i in range(3):
        dut.din_dr[i].value = 0
        dut.din_di[i].value = 0
    dut.din_chn.value = 0
    dut.sync_in.value = 0

    for i in range(3):
        for j in range(8):
            dut.ctrl_fcw[i][j].value = 13536 if i == 0 and j == 0 else 0

    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    await RisingEdge(dut.clk)


async def drive(dut, dr, di, chn, sync=False):
    clkedge = RisingEdge(dut.clk)
    n = len(dr)
    assert n == len(di)

    for i in range(n):
        for j in range(8):
            for k in range(3):
                c = j + k * 8
                dut.din_dr[k].value = int(dr[i]) if c == chn else 0
                dut.din_di[k].value = int(di[i]) if c == chn else 0
            dut.din_chn.value = (j + i * 8) % 256
            dut.sync_in.value = 1 if i == 0 and j == 0 and sync else 0
            await clkedge


async def sample_of(dut, n, chn, wait_sync=False):
    i = 0
    clkedge = RisingEdge(dut.clk)

    if wait_sync:
        while 1:
            await clkedge
            if dut.sync_out.value.is_resolvable and dut.sync_out.value == 1:
                break
    print("SYNC!")

    while i < n:
        if dut.dout_chn == int(chn / 8) * 16 + chn % 8:
            i = i + 1
            if dut.dout_dr.value.is_resolvable and dut.dout_di.value.is_resolvable:
                yield (
                    dut.dout_dr.value.signed_integer,
                    dut.dout_di.value.signed_integer,
                )
            else:
                yield (float("NaN"), float("NaN"))
        await clkedge


@cocotb.test()
async def test_prach_ddc(dut):
    # Reset
    cocotb.start_soon(Clock(dut.clk, 2, units="ns").start())
    await reset(dut)
    # Flush pipeline
    await cocotb.start_soon(drive(dut, np.zeros(512), np.zeros(512), 0, True))

    # Test input
    x = np.loadtxt("../matlab/test/prach_ddc_in.txt", delimiter=",")
    xr = x[:, 0]
    xi = x[:, 1]
    cocotb.start_soon(drive(dut, xr, xi, 0, True))

    # Test output
    y = np.loadtxt("../matlab/test/prach_ddc_out.txt", delimiter=",")
    res = [(x, y) async for (x, y) in sample_of(dut, 1536, 0, True)]
    res = np.array(res)
    print(res)

    assert(np.all(y == res))
