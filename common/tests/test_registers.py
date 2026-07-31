"""Unit tests for the protocol-independent register model."""

import asyncio

import pytest

from common.tb.registers import (
    FieldSpec,
    RegisterAccess,
    RegisterAdapter,
    RegisterBlock,
    RegisterError,
    RegisterSpec,
)


class MemoryAdapter(RegisterAdapter):
    def __init__(self, values):
        self.values = dict(values)

    async def read(self, address):
        return self.values[address]

    async def write(self, address, data, strobe=None):
        old = self.values[address]
        strobe = 0xF if strobe is None else strobe
        mask = sum(0xFF << (8 * index) for index in range(4) if strobe & (1 << index))
        self.values[address] = (old & ~mask) | (data & mask)


def make_block():
    specs = (
        RegisterSpec(
            "control",
            0x00,
            (
                FieldSpec("enable", 0, 1),
                FieldSpec("mode", 4, 2, reset=1),
            ),
        ),
        RegisterSpec(
            "status",
            0x04,
            (
                FieldSpec(
                    "count",
                    0,
                    8,
                    access=RegisterAccess.RO,
                    volatile=True,
                ),
            ),
        ),
    )
    adapter = MemoryAdapter({0x00: 0x10, 0x04: 0})
    return RegisterBlock("unit", specs, adapter), adapter


def test_field_access_and_mirror():
    block, adapter = make_block()

    async def scenario():
        await block.control.enable.write(1)
        assert adapter.values[0x00] == 0x11
        assert block.control.enable.mirrored_value == 1
        assert block.control.mode.mirrored_value == 1

        adapter.values[0x04] = 0xA5
        assert await block.status.count.read() == 0xA5
        with pytest.raises(RegisterError, match="read-only"):
            await block.status.count.write(0)

    asyncio.run(scenario())


def test_mirror_mismatch_reports_register():
    block, adapter = make_block()
    adapter.values[0x00] = 0x20
    with pytest.raises(RegisterError, match="control.*mirror mismatch"):
        asyncio.run(block.control.mirror(check=True))
