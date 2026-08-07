"""Helpers for driving cocotb simulator runners."""

from __future__ import annotations

from collections.abc import Mapping

_RAW_STRING_PARAM_SIMULATORS = {"verilator", "icarus"}

_TWO_STATE_SIMULATORS = {"verilator"}


def quote_string_parameters(
    sim: str, parameters: Mapping[str, object]
) -> dict[str, object]:
    """Quote string parameter values for simulators that take -G/-P overrides raw."""
    if sim.lower() not in _RAW_STRING_PARAM_SIMULATORS:
        return dict(parameters)
    return {
        name: f'"{value}"' if isinstance(value, str) else value
        for name, value in parameters.items()
    }


def assert_x_or_zero(sim: str, value: object) -> None:
    """Assert an undefined-read output: X on four-state simulators, zero on Verilator."""
    if sim.lower() in _TWO_STATE_SIMULATORS:
        assert int(value) == 0
    else:
        assert not value.is_resolvable
