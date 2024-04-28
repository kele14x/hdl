from pathlib import Path

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge, Timer

NFFT = 1536
prj_path = Path(__file__).resolve().parent.parent


async def reset(dut):
    dut.rst_n.value = 0
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_dv.value = 0
    dut.sync_in.value = 0
    dut.hdr_in.value = 0
    await ClockCycles(dut.clk, 16)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 16)


async def drive(dut, xs):
    clkedge = RisingEdge(dut.clk)

    for i, x in enumerate(xs):
        dut.sync_in.value = 1 if i == 0 else 0
        dut.din_dr.value = int(np.real(x))
        dut.din_di.value = int(np.imag(x))
        dut.din_dv.value = 1
        dut.hdr_in.value = 100
        await clkedge

    dut.sync_in.value = 0
    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_dv.value = 0
    dut.hdr_in.value = 0


async def sample(dut):
    clkedge = RisingEdge(dut.clk)

    # Wait for sync
    while True:
        if dut.sync_out.value.is_resolvable and dut.sync_out.value == 1:
            break
        await clkedge

    # Collect data
    y = np.zeros(NFFT, dtype=np.complex_)
    for i in range(NFFT):
        assert dut.dout_dr.value.is_resolvable and dut.dout_di.value.is_resolvable
        dr = dut.dout_dr.value.signed_integer
        di = dut.dout_di.value.signed_integer
        y[i] = dr + 1j * di
        await clkedge

    return y


async def debug(clk, sync, dr, di):
    clkedge = RisingEdge(clk)

    # Wait for sync
    while True:
        if sync.value.is_resolvable and sync.value == 1:
            break
        await clkedge

    # Collect data
    y = np.zeros(NFFT, dtype=np.complex_)
    for i in range(NFFT):
        assert dr.value.is_resolvable and di.value.is_resolvable
        y[i] = dr.value.signed_integer + 1j * di.value.signed_integer
        await clkedge

    with open(prj_path / "matlab/test/debug.txt", "w") as f:
        for yy in y:
            f.write("%d, %d\n" % (np.real(yy), np.imag(yy)))


@cocotb.test()
async def test_prach_fft_simple(dut):
    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    await reset(dut)

    # Test input
    x = np.loadtxt(prj_path / "matlab/test/prach_fft_in.txt", delimiter=",")
    x = x[:, 0] + 1j * x[:, 1]
    cocotb.start_soon(drive(dut, x))

    cocotb.start_soon(
        debug(dut.clk, dut.u_ditfft3.s1_sync, dut.u_ditfft3.s1_dr, dut.u_ditfft3.s1_di)
    )

    # Reference output
    r = np.loadtxt(prj_path / "matlab/test/prach_fft_out.txt", delimiter=",")
    r = r[:, 0] + 1j * r[:, 1]

    # Actual output
    y = await sample(dut)
    for i in range(NFFT):
        assert (
            r[i] == y[i]
        ), f"different sample at index {i}: reference {r[i]}, actual {y[i]}"

    await Timer(5000, units="ns")


def test_prach_fft_runner():
    sim = "questa"

    hdl_toplevel = "prach_fft"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "src/cmult.sv",
        prj_path / "src/delay.sv",
        prj_path / "src/prach_ditfft2.sv",
        prj_path / "src/prach_ditfft2_bf.sv",
        prj_path / "src/prach_ditfft2_twiddler.sv",
        prj_path / "src/prach_ditfft3.sv",
        prj_path / "src/prach_ditfft3_bf1.sv",
        prj_path / "src/prach_ditfft3_bf2.sv",
        prj_path / "src/prach_ditfft3_bf3.sv",
        prj_path / "src/prach_fft.sv",
    ]

    test_args = ["-L", "altera_mf_ver"]

    runner = get_runner(sim)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_args=test_args,
        test_module="test_prach_fft",
        waves=True,
    )


if __name__ == "__main__":
    test_prach_fft_runner()
