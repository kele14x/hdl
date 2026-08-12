"""Shared helpers for the cdc cocotb tests."""

from cocotb.triggers import RisingEdge


async def wait_for_value(signal, clock, value, cycles=20):
    for _ in range(cycles):
        await RisingEdge(clock)
        if int(signal.value) == value:
            return
    raise AssertionError(
        f"{signal._name} did not become {value} within {cycles} cycles"
    )
