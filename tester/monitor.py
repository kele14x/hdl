from typing import Dict, List, Optional

import cocotb
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge


class DataMonitor:
    """
    Monitor to read every tick's sample from signals
    """

    def __init__(self, dut: SimHandleBase, signals: List[str], delay: int = 0,
                 clk: str = 'clk', rst: Optional[str] = None):
        self.dut = dut
        self.values = Queue[Dict[str, SimHandleBase]]()

        self._signals = {name: getattr(self.dut, name) for name in signals}
        self._delay = delay
        self._clk = getattr(self.dut, clk)
        if rst is None:
            self._rst = None
        else:
            self._rst = getattr(self, rst)
        self._coro = None

    def start(self) -> None:
        """Start the monitor."""
        if self._coro is not None:
            raise RuntimeError("Monitor already started")
        self._coro = cocotb.start_soon(self._monitor())

    def stop(self) -> None:
        """Stop the monitor."""
        if self._coro is None:
            raise RuntimeError("Monitor not started")
        self._coro.kill()
        self._coro = None

    async def _monitor(self) -> None:
        await ClockCycles(self._clk, self._delay)
        while True:
            await RisingEdge(self._clk)
            self.values.put_nowait(self._sample())

    def _sample(self) -> Dict[str, int]:
        return {name: sig.value for name, sig in self._signals.items()}
