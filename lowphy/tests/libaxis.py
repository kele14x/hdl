"""Compatibility imports for the shared AXI-Stream verification agent."""

from hdl_tools.axis import (
    AxisAgent,
    AxisAgentConfig,
    AxisBeat,
    AxisError,
    AxisFrame,
    AxisMonitor,
    AxisRole,
    AxisSink,
    AxisSinkDriver,
    AxisSource,
    AxisSourceDriver,
)

AxisTimeout = AxisError

__all__ = [
    "AxisAgent",
    "AxisAgentConfig",
    "AxisBeat",
    "AxisError",
    "AxisFrame",
    "AxisMonitor",
    "AxisRole",
    "AxisSink",
    "AxisSinkDriver",
    "AxisSource",
    "AxisSourceDriver",
    "AxisTimeout",
]
