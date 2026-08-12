"""Shared cocotb runner helpers for the PDXCH regression tests."""

from __future__ import annotations

import os
import shutil
from collections.abc import Iterable
from pathlib import Path

from cocotb_tools.runner import get_runner

from hdl_tools.flt_tool import resolve_flt

PRJ_PATH = Path(__file__).resolve().parent.parent
SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

_SIMULATOR_BINARIES = {
    "questa": "vsim",
    "modelsim": "vsim",
    "icarus": "iverilog",
    "verilator": "verilator",
}
_simulator_binary = _SIMULATOR_BINARIES.get(SIM.lower())
if _simulator_binary and shutil.which(_simulator_binary) is None:
    raise RuntimeError(
        f"SIM={SIM!r} was selected, but the required executable "
        f"{_simulator_binary!r} is not available on PATH"
    )


def pdxch_sources(*filelists: str) -> list[Path]:
    """Resolve one or more PDXCH-relative file lists without duplicates."""

    sources: list[Path] = []
    seen: set[Path] = set()
    for filelist in filelists:
        for source in resolve_flt(PRJ_PATH / filelist):
            if source not in seen:
                sources.append(source)
                seen.add(source)
    return sources


def run_test(
    *,
    hdl_toplevel: str,
    test_module: str,
    sources: Iterable[Path],
    parameters: dict[str, int | bool] | None = None,
    build_name: str | None = None,
) -> None:
    """Build and run a test in the persistent PDXCH sim_build directory."""

    run_dir = PRJ_PATH / "sim_build" / (build_name or test_module)
    waves = os.environ.get("PDXCH_WAVES", "true").lower() == "true"
    runner = get_runner(SIM)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        sources=list(sources),
        parameters=parameters or {},
        always=True,
        waves=waves,
        build_dir=run_dir,
    )
    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang="verilog",
        test_module=test_module,
        waves=waves,
        gui=os.environ.get("GUI", "false").lower() == "true",
        test_dir=run_dir,
    )
