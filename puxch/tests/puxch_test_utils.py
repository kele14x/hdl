import os
from pathlib import Path

from cocotb.triggers import RisingEdge, Timer
from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

PRJ_PATH = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")
SIM = SIM.lower()
GUI = os.environ.get("GUI", "false").lower() == "true"
WAVES = os.environ.get("WAVES", "false").lower() == "true"
REBUILD = os.environ.get("REBUILD", "false").lower() == "true"


async def sample_after_rising(clock):
    """Wait for a clock edge and allow registered outputs to settle."""
    await RisingEdge(clock)
    await Timer(1, unit="ps")


def run_cocotb(
    hdl_toplevel,
    test_module,
    parameters=None,
    sources=None,
    *,
    build_name=None,
    extra_env=None,
):
    """Build and run one PUXCH cocotb test in a persistent module build tree."""
    build_dir = PRJ_PATH / "sim_build" / SIM / (build_name or test_module)
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        sources=sources or resolve_flt(PRJ_PATH / "puxch.flt"),
        parameters=parameters or {},
        always=REBUILD,
        waves=WAVES,
        build_dir=build_dir,
    )
    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang="verilog",
        test_module=test_module,
        gui=GUI,
        waves=WAVES,
        test_dir=build_dir,
        extra_env=extra_env or {},
    )
