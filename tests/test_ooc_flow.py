"""Check OOC stage selection without requiring Vivado or writing build products."""

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = [
    ("fft/synth/fft_ooc.tcl", ["{output_dir}"], "fft"),
    ("lowphy/synth/lowphy0_ooc.tcl", [], "lowphy0"),
    ("lowphy/synth/lowphy1_ooc.tcl", [], "lowphy1"),
    ("pdxch/synth/pdxch_ooc.tcl", ["1", "1"], "pdxch"),
    ("prach/synth/prach_ooc.tcl", ["2"], "prach"),
    ("puxch/synth/puxch_ooc.tcl", ["1", "0"], "puxch"),
]


@pytest.fixture
def tcl_runner(tmp_path):
    tclsh = shutil.which("tclsh")
    if tclsh is None:
        pytest.skip("tclsh is unavailable")
    harness = tmp_path / "vivado_stub.tcl"
    harness.write_text(
        """
set checkpoints {}
rename file native_file
proc file {subcommand args} {
  global checkpoints
  if {$subcommand eq "mkdir"} { return }
  if {$subcommand eq "exists" && [lindex $args 0] in $checkpoints} { return 1 }
  tailcall native_file $subcommand {*}$args
}
proc cd {args} {}
foreach command {
  read_verilog read_xdc synth_design report_utilization report_timing_summary
  report_route_status close_design open_checkpoint opt_design place_design
  phys_opt_design route_design
} {
  proc $command {args} [format {puts "CALL:%s:$args"} $command]
}
proc write_checkpoint {args} {
  global checkpoints
  lappend checkpoints [lindex $args end]
  puts "CALL:write_checkpoint:$args"
}
set entrypoint [lindex $argv 0]
set argv [lrange $argv 1 end]
source $entrypoint
"""
    )

    def run(script, args):
        return subprocess.run(
            [tclsh, str(harness), str(ROOT / script), *args],
            text=True,
            capture_output=True,
            check=False,
            timeout=30,
        )

    return run


@pytest.mark.parametrize("script,args,prefix", SCRIPTS)
@pytest.mark.parametrize("stage", [None, "synth", "impl"])
def test_tcl_stops_at_selected_stage(tcl_runner, tmp_path, script, args, prefix, stage):
    args = [arg.format(output_dir=tmp_path / "fft-build") for arg in args]
    if stage is not None:
        args += ["-stage", stage]
    result = tcl_runner(script, args)
    assert result.returncode == 0, result.stdout + result.stderr
    calls = [
        line.removeprefix("CALL:").split(":", 1)
        for line in result.stdout.splitlines()
        if line.startswith("CALL:")
    ]
    names = [name for name, _ in calls]
    assert names.count("synth_design") == 1
    checkpoints = [args for name, args in calls if name == "write_checkpoint"]
    assert checkpoints[0].endswith(f"/{prefix}_ooc.dcp")
    if stage == "impl":
        assert names[names.index("close_design") : names.index("route_design") + 1] == [
            "close_design",
            "open_checkpoint",
            "opt_design",
            "place_design",
            "phys_opt_design",
            "route_design",
        ]
        opened = [args for name, args in calls if name == "open_checkpoint"]
        assert opened == [checkpoints[0].removeprefix("-force ")]
        assert checkpoints[1].endswith(f"/{prefix}_impl.dcp")
        assert "report_route_status" in names
    else:
        assert "open_checkpoint" not in names
        assert "opt_design" not in names
        assert "route_design" not in names
        assert len(checkpoints) == 1


@pytest.mark.parametrize(
    "args",
    [
        ["-stage"],
        ["-stage", "invalid"],
        ["-stage", "impl", "extra"],
        ["-stage", "impl", "-stage", "synth"],
    ],
)
def test_invalid_stage_fails_before_synthesis(tcl_runner, args):
    result = tcl_runner("fft/synth/fft_ooc.tcl", args)
    assert result.returncode != 0
    assert "-stage must be" in result.stderr
    assert "CALL:" not in result.stdout


@pytest.mark.parametrize("script,args,prefix", SCRIPTS)
def test_extra_positional_argument_reports_usage(tcl_runner, script, args, prefix):
    result = tcl_runner(script, [*args, "extra"])
    assert result.returncode != 0
    assert "usage:" in result.stderr
    assert "CALL:" not in result.stdout


@pytest.mark.parametrize("module", ["fft", "lowphy", "pdxch", "prach", "puxch"])
def test_make_ooc_explicitly_selects_synthesis(tmp_path, module):
    block = tmp_path / module
    block.mkdir()
    shutil.copy(ROOT / module / "Makefile", block / "Makefile")
    scripts = tmp_path / "scripts"
    scripts.mkdir()
    shutil.copy(ROOT / "scripts/cocotb.mk", scripts / "cocotb.mk")
    vivado = tmp_path / "vivado"
    vivado.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
    vivado.chmod(0o755)
    result = subprocess.run(
        ["make", "ooc", f"VIVADO={vivado}", "OOC_TCLARGS=custom-argument"],
        cwd=block,
        text=True,
        capture_output=True,
        check=False,
        timeout=30,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert "-tclargs\ncustom-argument\n-stage\nsynth\n" in result.stdout
    removed = subprocess.run(
        ["make", "--dry-run", "ooc-impl"],
        cwd=block,
        text=True,
        capture_output=True,
        check=False,
        timeout=30,
    )
    assert removed.returncode != 0
    assert "No rule to make target" in removed.stderr
