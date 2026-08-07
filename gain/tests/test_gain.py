import os
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb_tools.runner import get_runner

from common.tb import AgentMode
from common.tb.dsp import (
    DspSample,
    DspSampleAgent,
    DspSampleAgentConfig,
    DspSampleSignals,
)
from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent
rng = np.random.default_rng(12345)

HAS_CDC = int(os.environ.get("HAS_CDC", "0"))
NUM_ANT = int(os.environ.get("NUM_ANT", "4"))
COMPLEX = int(os.environ.get("COMPLEX", "1"))
GAIN_WIDTH = int(os.environ.get("GAIN_WIDTH", "16"))

GUI = os.environ.get("GUI", "False").lower() == "true"

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

CTRL_GAIN_DR = rng.integers(
    -(2 ** (GAIN_WIDTH - 1)), 2 ** (GAIN_WIDTH - 1), size=NUM_ANT
)
CTRL_GAIN_DI = rng.integers(
    -(2 ** (GAIN_WIDTH - 1)), 2 ** (GAIN_WIDTH - 1), size=NUM_ANT
)


def truncate(x, w):
    """Truncate the input to the specified width."""
    x = x % 2**w
    x = x - 2**w if x > 2 ** (w - 1) - 1 else x
    return x


def saturation(x, w):
    """Saturate the input to the specified width."""
    if x > 2 ** (w - 1) - 1:
        return 2 ** (w - 1) - 1
    elif x < -(2 ** (w - 1)):
        return -(2 ** (w - 1))
    else:
        return x


def model(dr, di, gr, gi):
    """Model the adder."""
    dout_dr = dr * gr - di * gi
    dout_di = dr * gi + di * gr
    dout_dr = (dout_dr + 2**13) / 2**14
    dout_di = (dout_di + 2**13) / 2**14
    dout_dr = int(np.floor(dout_dr))
    dout_di = int(np.floor(dout_di))
    dout_dr = saturation(dout_dr, GAIN_WIDTH)
    dout_di = saturation(dout_di, GAIN_WIDTH)
    return (dout_dr, dout_di)


async def reset(dut):
    """Reset the DUT."""
    dut.rst.value = 1

    dut.din_dr.value = 0
    dut.din_di.value = 0
    dut.din_sf.value = 0
    dut.din_sl.value = 0
    dut.din_sy.value = 0
    dut.din_chn.value = 0
    dut.din_dv.value = 0

    for i in range(NUM_ANT):
        dut.ctrl_gain_dr[i].value = int(CTRL_GAIN_DR[i])
        dut.ctrl_gain_di[i].value = int(CTRL_GAIN_DI[i])

    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 10)


def make_samples(count=10000):
    """Create a reproducible cycle-level IQ sequence, including invalid gaps."""
    return [
        DspSample(
            i=int(rng.integers(-(2**15), 2**15)),
            q=int(rng.integers(-(2**15), 2**15)),
            start_frame=bool(rng.integers(0, 2)),
            start_slot=bool(rng.integers(0, 2)),
            start_symbol=bool(rng.integers(0, 2)),
            channel=int(rng.integers(0, NUM_ANT)),
            valid=bool(rng.integers(0, 2)),
        )
        for _ in range(count)
    ]


@cocotb.test()
async def test_gain(dut):
    """Check gain data and metadata with reusable DSP sample agents."""
    cocotb.log.info("Simulation started")
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset(dut)

    source = DspSampleAgent(
        dut,
        DspSampleAgentConfig(
            signals=DspSampleSignals.from_prefix("din"),
            reset="rst",
        ),
    )
    sink = DspSampleAgent(
        dut,
        DspSampleAgentConfig(
            signals=DspSampleSignals.from_prefix("dout"),
            reset="rst",
            mode=AgentMode.PASSIVE,
            timeout_cycles=100,
        ),
    )
    await source.start()
    await sink.start()

    samples = make_samples()
    expected = [sample for sample in samples if sample.valid]
    await source.send(samples)

    for index, sample in enumerate(expected):
        actual = await sink.receive()
        gr = int(CTRL_GAIN_DR[sample.channel])
        gi = int(CTRL_GAIN_DI[sample.channel]) if COMPLEX else 0
        expected_i, expected_q = model(sample.i, sample.q, gr, gi)
        assert actual == DspSample(
            i=expected_i,
            q=expected_q,
            start_frame=sample.start_frame,
            start_slot=sample.start_slot,
            start_symbol=sample.start_symbol,
            channel=sample.channel,
        ), f"sample {index} mismatch: input={sample}, output={actual}"

    await ClockCycles(dut.clk, 10)
    cocotb.log.info("Simulation finished")


def test_gain_runner():
    """Run the test."""
    hdl_toplevel = "gain"
    hdl_toplevel_lang = "verilog"

    verilog_sources = resolve_flt(prj_path / "gain.flt")

    parameters = {
        "NUM_ANT": NUM_ANT,
        "COMPLEX": COMPLEX,
        "GAIN_WIDTH": GAIN_WIDTH,
    }

    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        sources=verilog_sources,
        parameters=parameters,
        build_args=[],
        waves=True,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_gain",
        waves=True,
        gui=GUI,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
