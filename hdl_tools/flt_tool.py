#!/usr/bin/env python3
"""Expand hierarchical HDL ``.flt`` file lists.

Each non-comment entry is resolved relative to the file list that contains it.
Entries ending in ``.flt`` are expanded recursively; every file list is read at
most once, so shared dependencies and cycles are safe.
"""

from __future__ import annotations

import argparse
from collections.abc import Sequence
from pathlib import Path

__version__ = "1.0.0"


def resolve_flt(flt_file: Path) -> list[Path]:
    """Return source files from *flt_file*, recursively expanding ``.flt`` entries."""
    resolved_files: list[Path] = []
    parsed_flts: set[Path] = set()

    def parse(file_list: Path) -> None:
        file_list = file_list.resolve()
        if file_list in parsed_flts:
            return
        if not file_list.is_file():
            raise FileNotFoundError(f"File list not found: {file_list}")

        parsed_flts.add(file_list)
        for raw_line in file_list.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue

            entry = (file_list.parent / line).resolve()
            if entry.suffix.lower() == ".flt":
                parse(entry)
            else:
                if not entry.is_file():
                    raise FileNotFoundError(
                        f"Source listed by {file_list} does not exist: {line}"
                    )
                resolved_files.append(entry)

    parse(flt_file)
    return resolved_files


def parse_arguments(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("flt", type=Path, help="Top-level .flt file to resolve")
    parser.add_argument(
        "-p",
        "--print-only",
        action="store_true",
        help="Retained for compatibility; resolved source paths are always printed",
    )
    parser.add_argument("--version", action="version", version=__version__)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    """Print the recursively resolved source paths for a top-level ``.flt`` file."""
    args = parse_arguments(argv)
    if args.flt.suffix.lower() != ".flt":
        raise ValueError(f"Expected a .flt file: {args.flt}")
    for source in resolve_flt(args.flt):
        print(source.as_posix())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
