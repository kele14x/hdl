from pathlib import Path

from tools.flt_tool import main, resolve_flt


def test_resolve_flt_expands_nested_lists_and_ignores_cycles(tmp_path: Path):
    (tmp_path / "rtl").mkdir()
    (tmp_path / "rtl" / "top.sv").touch()
    (tmp_path / "rtl" / "dependency.sv").touch()
    (tmp_path / "top.flt").write_text("dependency.flt\nrtl/top.sv\n", encoding="utf-8")
    (tmp_path / "dependency.flt").write_text(
        "top.flt\nrtl/dependency.sv\n", encoding="utf-8"
    )

    assert resolve_flt(tmp_path / "top.flt") == [
        (tmp_path / "rtl" / "dependency.sv").resolve(),
        (tmp_path / "rtl" / "top.sv").resolve(),
    ]


def test_main_prints_resolved_paths(tmp_path: Path, capsys):
    source = tmp_path / "source.sv"
    source.touch()
    file_list = tmp_path / "source.flt"
    file_list.write_text("source.sv\n", encoding="utf-8")

    assert main([str(file_list), "--print-only"]) == 0
    assert capsys.readouterr().out == f"{source.resolve().as_posix()}\n"
