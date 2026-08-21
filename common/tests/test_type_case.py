#!/usr/bin/env python3
import os
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.triggers import Timer
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

prj_path = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=verilator")
GUI = os.environ.get("GUI", "false").lower() == "true"

CASES = [
    {
        "name": "identity",
        "params": {"IN_WIDTH": 16, "OUT_WIDTH": 16, "TRUNC": 0, "SATURATE": 1},
    },
    {
        "name": "saturate",
        "params": {"IN_WIDTH": 18, "OUT_WIDTH": 16, "TRUNC": 0, "SATURATE": 1},
    },
    {
        "name": "sext",
        "params": {"IN_WIDTH": 16, "OUT_WIDTH": 18, "TRUNC": 0, "SATURATE": 1},
    },
    {
        "name": "trunc_sat",
        "params": {"IN_WIDTH": 32, "OUT_WIDTH": 16, "TRUNC": 15, "SATURATE": 1},
    },
    {
        "name": "trunc_wrap",
        "params": {"IN_WIDTH": 32, "OUT_WIDTH": 16, "TRUNC": 15, "SATURATE": 0},
    },
    {
        "name": "trunc_rne_sat",
        "params": {"IN_WIDTH": 32, "OUT_WIDTH": 16, "TRUNC": 15, "ROUND": 1, "SATURATE": 1},
    },
    {
        "name": "trunc_rne_wrap",
        "params": {"IN_WIDTH": 32, "OUT_WIDTH": 16, "TRUNC": 15, "ROUND": 1, "SATURATE": 0},
    },
    {
        "name": "rne_ties",
        "params": {"IN_WIDTH": 8, "OUT_WIDTH": 4, "TRUNC": 4, "ROUND": 1, "SATURATE": 1},
    },
    {
        "name": "rne_sext",
        "params": {"IN_WIDTH": 8, "OUT_WIDTH": 16, "TRUNC": 2, "ROUND": 1, "SATURATE": 1},
    },
    {
        "name": "pad_sext",
        "params": {"IN_WIDTH": 16, "OUT_WIDTH": 18, "TRUNC": -2, "SATURATE": 1},
    },
    {
        "name": "pad_wrap",
        "params": {"IN_WIDTH": 16, "OUT_WIDTH": 12, "TRUNC": -2, "SATURATE": 0},
    },
]


def to_signed(x, w):
    x &= (1 << w) - 1
    if x >> (w - 1):
        x -= 1 << w
    return x


def model(din, in_w, out_w, trunc, round_, saturate):
    if trunc >= 0:
        if round_ and trunc > 0:
            din += (1 << (trunc - 1)) - 1 + ((din >> trunc) & 1)
        val = din >> trunc
        eff = in_w - trunc
    else:
        val = din << (-trunc)
        eff = in_w - trunc
    sign = 1 if val < 0 else 0
    diff = eff - out_w
    if diff <= -1:
        ovf = 0
        dout = to_signed(val, out_w)
    else:
        top = (val >> (out_w - 1)) & ((1 << (diff + 2)) - 1)
        in_range = top == 0 or top == (1 << (diff + 2)) - 1
        ovf = 0 if in_range else 1
        if in_range or not saturate:
            dout = to_signed(val, out_w)
        else:
            dout = -(1 << (out_w - 1)) if sign else (1 << (out_w - 1)) - 1
    return dout, ovf


@cocotb.test()
async def test_type_case(dut):
    in_w = int(os.environ.get("IN_WIDTH", "16"))
    out_w = int(os.environ.get("OUT_WIDTH", "16"))
    trunc = int(os.environ.get("TRUNC", "0"))
    round_ = int(os.environ.get("ROUND", "0"))
    saturate = int(os.environ.get("SATURATE", "1"))

    rng = np.random.default_rng(12345)
    low = -(1 << (in_w - 1))
    high = (1 << (in_w - 1)) - 1

    values = [low, low + 1, -1, 0, 1, high - 1, high]
    values += [int(v) for v in rng.integers(low, high + 1, size=512, dtype=np.int64)]

    for v in values:
        dut.din.value = v
        await Timer(1, unit="ns")
        exp_dout, exp_ovf = model(v, in_w, out_w, trunc, round_, saturate)
        got_dout = int(dut.dout.value.signed_integer)
        got_ovf = int(dut.ovf.value)
        assert got_ovf == exp_ovf, (
            f"din={v}: ovf {got_ovf} != expected {exp_ovf} (out {got_dout} vs {exp_dout})"
        )
        assert got_dout == exp_dout, (
            f"din={v}: dout {got_dout} != expected {exp_dout} (ovf {got_ovf} vs {exp_ovf})"
        )


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_type_case_runner(case):
    parameters = case["params"]
    run_dir = prj_path / "sim_build" / case["name"]
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel="type_case",
        sources=resolve_flt(prj_path / "common.flt"),
        parameters=parameters,
        always=True,
        waves=True,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel="type_case",
        hdl_toplevel_lang="verilog",
        test_module="test_type_case",
        waves=True,
        gui=GUI,
        test_dir=run_dir,
        extra_env={key: str(value) for key, value in parameters.items()},
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
