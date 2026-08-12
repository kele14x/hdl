"""Reusable cocotb environment for the lowphy integration tops."""

import re
from pathlib import Path
from typing import ClassVar

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

from hdl_tools.axi4lite import AxiLiteAgent, AxiLiteAgentConfig

_PORT_RE = re.compile(
    r"\binput\s+(?:wire|logic)\s+(?:signed\s+)?"
    r"(?:\[[^\]]+\]\s+)?([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:,|\))"
)


def input_port_names(rtl_path: Path):
    """Return scalar/vector input ports declared in an ANSI module header."""
    ports = []
    for line in rtl_path.read_text(encoding="utf-8").splitlines():
        code = line.split("//", 1)[0]
        ports.extend(match.group(1) for match in _PORT_RE.finditer(code))
    return ports


class LowphyTB:
    """Clock, reset, idle-input, and AXI setup shared by lowphy0/lowphy1."""

    CLOCKS: ClassVar = {
        "s_axi_aclk": (10, "ns"),
        "internal_bus_clk": (2.5, "ns"),
        # 491.52 MHz is 2034.505... ps. The RTL timescale is 1 ps, so use the
        # nearest representable period for functional simulation.
        "clk": (2034, "ps"),
    }

    def __init__(self, dut, rtl_path: Path, axi_prefix="s0_axi"):
        self.dut = dut
        self.rtl_path = rtl_path
        self.axi_agent = AxiLiteAgent(
            dut,
            AxiLiteAgentConfig(
                prefix=axi_prefix,
                clock="s_axi_aclk",
                reset="s_axi_aresetn",
            ),
        )
        self.axi = self.axi_agent.driver
        self._clock_tasks = []

    def _set_if_present(self, name, value):
        handle = getattr(self.dut, name, None)
        if handle is not None:
            handle.value = value

    def drive_idle_inputs(self):
        """Initialize every top-level input, enabling downstream ready pins."""
        clock_and_reset = {
            *self.CLOCKS,
            "s_axi_aresetn",
            "rst",
            "rstn",
            "defm_reset",
            "fram_reset",
            "defm_reset_active",
            "fram0_reset_active",
        }
        for name in input_port_names(self.rtl_path):
            if name in clock_and_reset:
                continue
            value = 1 if name.endswith("_tready") else 0
            self._set_if_present(name, value)

    async def start_clocks(self):
        for name, (period, unit) in self.CLOCKS.items():
            handle = getattr(self.dut, name, None)
            if handle is not None:
                self._clock_tasks.append(
                    cocotb.start_soon(Clock(handle, period, unit=unit).start())
                )
        await RisingEdge(self.dut.s_axi_aclk)

    async def reset(self, cycles=16):
        """Apply resets in all domains, then release them synchronously."""
        self.drive_idle_inputs()
        await self.axi.reset()

        self._set_if_present("s_axi_aresetn", 0)
        self._set_if_present("rst", 1)
        self._set_if_present("rstn", 0)
        self._set_if_present("defm_reset", 1)
        self._set_if_present("fram_reset", 1)
        self._set_if_present("defm_reset_active", 1)
        self._set_if_present("fram0_reset_active", 1)

        await ClockCycles(self.dut.s_axi_aclk, cycles)
        self._set_if_present("s_axi_aresetn", 1)

        if hasattr(self.dut, "internal_bus_clk"):
            await RisingEdge(self.dut.internal_bus_clk)
        self._set_if_present("defm_reset", 0)
        self._set_if_present("fram_reset", 0)
        self._set_if_present("defm_reset_active", 0)
        self._set_if_present("fram0_reset_active", 0)

        if hasattr(self.dut, "clk"):
            await RisingEdge(self.dut.clk)
        self._set_if_present("rst", 0)
        self._set_if_present("rstn", 1)
        await ClockCycles(self.dut.s_axi_aclk, 4)

    async def start(self):
        await self.start_clocks()
        await self.axi_agent.start()
        await self.reset()
