import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge, Timer

prj_path = Path(__file__).resolve().parent.parent


async def reset(dut):
    dut.rst_n.value = 0

    for cc in range(0, 1):
        for band in range(0, 1):
            dut.din0_dr[cc][band].value = 0
            dut.din0_di[cc][band].value = 0
            dut.din0_chn[cc][band].value = 0
            dut.din0_sym[cc][band].value = 0
            dut.din0_dv[cc][band].value = 0
            dut.din0_sync[cc][band].value = 0

            dut.din1_dr[cc][band].value = 0
            dut.din1_di[cc][band].value = 0
            dut.din1_chn[cc][band].value = 0
            dut.din1_sym[cc][band].value = 0
            dut.din1_dv[cc][band].value = 0
            dut.din1_sync[cc][band].value = 0

    dut.rst_csr_n.value = 0

    dut.ctrl_mu.value = 0
    dut.ctrl_cc_sel.value = 0
    dut.ctrl_band_sel.value = 0
    dut.ctrl_ant_sel.value = 0
    dut.ctrl_pos_sel.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    await ClockCycles(dut.clk_csr, 10)
    dut.rst_csr_n.value = 1


async def drive(dut):
    await RisingEdge(dut.clk)

    for sym in range(0, 140):
        for chn in range(0, 4):
            for i in range(0, 2048):
                #
                for cc in range(0, 1):
                    for band in range(0, 1):
                        dut.din0_dr[cc][band].value = random.randint(-2**15, 2**15-1)
                        dut.din0_di[cc][band].value = random.randint(-2**15, 2**15-1)
                        dut.din0_chn[cc][band].value = chn
                        dut.din0_sym[cc][band].value = sym
                        dut.din0_dv[cc][band].value = 1
                        dut.din0_sync[cc][band].value = 1 if i == 0 else 0
                await RisingEdge(dut.clk)
            for cc in range(0, 1):
                for band in range(0, 1):
                    dut.din0_dv[cc][band].value = 0
            await RisingEdge(dut.clk)


@cocotb.test()
async def test_power_meter(dut):
    # Generate clocks
    cocotb.start_soon(Clock(dut.clk, period=4, units="ns").start())
    cocotb.start_soon(Clock(dut.clk_csr, period=10, units="ns").start())

    # Reset DUT
    await reset(dut)
    cocotb.start_soon(drive(dut))

    # finish
    await Timer(1000 * 1000, units="ns")


def test_power_meter_runner():
    sim = "questa"

    hdl_toplevel = "power_meter"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "../common/rtl/cdc_bits.sv",
        prj_path / "../common/rtl/delay.sv",
        prj_path / "rtl/power_meter.sv",
    ]

    test_args = ["-L", "altera_mf_ver", "-L", "altera_lnsim_ver"]
    test_args += ["-gNUM_CC=1", "-gNUM_BAND=1"]

    runner = get_runner(sim)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        # build_args=["-gNUM_CC=1", "-gNUM_BAND=1"],
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_args=test_args,
        test_module="test_power_meter",
        waves=True,
        gui=True,
    )


if __name__ == "__main__":
    test_power_meter_runner()
