"""Exercise regression discovery and failure propagation in isolated repositories."""

import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.fixture
def regression_repo(tmp_path):
    shutil.copy(ROOT / "Makefile", tmp_path / "Makefile")
    (tmp_path / "scripts").mkdir()
    for name in ("run_targets.sh", "cocotb.mk"):
        shutil.copy(ROOT / "scripts" / name, tmp_path / "scripts" / name)
    (tmp_path / "tests").mkdir()
    (tmp_path / "tests" / "test_helpers.py").write_text(
        "from pathlib import Path\n"
        "def test_helper():\n"
        "    Path('helpers-ran').touch()\n"
    )
    return tmp_path


def run_make(root, *args):
    env = os.environ.copy()
    for name in ("MAKEFLAGS", "MFLAGS", "MAKELEVEL", "HDL_MODULES"):
        env.pop(name, None)
    return subprocess.run(
        ["make", *args, f"PYTEST={sys.executable} -m pytest"],
        cwd=root,
        env=env,
        text=True,
        capture_output=True,
        check=False,
        timeout=30,
    )


def add_block(root, name, *, makefile=True):
    block = root / name
    (block / "rtl").mkdir(parents=True)
    (block / "rtl" / f"{name}.sv").touch()
    if makefile:
        (block / "Makefile").write_text("test:\n\t@touch test-ran\n")
    return block


def test_root_discovers_rtl_and_continues_after_missing_makefile(regression_repo):
    root = regression_repo
    add_block(root, "a_missing", makefile=False)
    common = add_block(root, "common")
    result = run_make(root, "test")
    assert result.returncode != 0
    assert "a_missing" in result.stdout and "FAIL" in result.stdout
    assert (common / "test-ran").exists()
    assert (root / "helpers-ran").exists()
    assert (root / ".build_logs/test-hdl_tools.log").exists()


def test_root_runs_helpers_even_with_module_override(regression_repo):
    root = regression_repo
    common = add_block(root, "common")
    result = run_make(root, "test", "MODULES=common")
    assert result.returncode == 0, result.stdout + result.stderr
    assert (common / "test-ran").exists()
    assert (root / "helpers-ran").exists()
    (root / "tests/test_helpers.py").write_text(
        "def test_helper():\n    assert False\n"
    )
    result = run_make(root, "test", "MODULES=common")
    assert result.returncode != 0
    assert "test-hdl_tools.log" in result.stdout


@pytest.mark.parametrize("case", ["missing_tests", "empty_tests", "empty_simulators"])
def test_module_cannot_pass_without_tests_or_simulators(regression_repo, case):
    block = add_block(regression_repo, "ip")
    (block / "Makefile").write_text(
        "MODULE := ip\nSIMULATORS ?= verilator\ninclude ../scripts/cocotb.mk\n"
    )
    if case != "missing_tests":
        (block / "tests").mkdir()
    if case == "empty_simulators":
        (block / "tests/test_sentinel.py").write_text(
            "def test_sentinel():\n    pass\n"
        )
    args = ["test"] + (["SIMULATORS="] if case == "empty_simulators" else [])
    result = run_make(block, *args)
    assert result.returncode != 0, result.stdout + result.stderr
    if case == "missing_tests":
        assert "has no tests/ directory" in result.stderr
    elif case == "empty_simulators":
        assert "SIMULATORS must not be empty" in result.stderr
    else:
        assert "no tests ran" in result.stdout
