import random
from typing import Dict, List

import cocotb
import matlab.engine
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, RisingEdge

FFT_SIZE = cocotb.top.FFT_SIZE.value
INPUT_DATA_WIDTH = cocotb.top.INPUT_DATA_WIDTH.value
PHASE_WIDTH = cocotb.top.PHASE_WIDTH.value
OUTPUT_DATA_WIDTH = cocotb.top.OUTPUT_DATA_WIDTH.value
HAS_BITREVERSE = cocotb.top.HAS_BITREVERSE.value


class PacketMonitor:
    """
    Simple monitor to capture data with in a packet.
    """

    def __init__(self, clk: SimHandleBase,
                 signals: List[Dict[str, SimHandleBase]], valid: SimHandleBase,
                 last: SimHandleBase):
        self.values = Queue[Dict[str, BinaryValue]]()
        self._clk = clk
        self._signals = signals
        self._valid = valid
        self._last = last
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
        transaction = []
        while True:
            await RisingEdge(self._clk)
            if self._valid.value:
                transaction.append(self._sample())
                if self._last.value:
                    self.values.put_nowait(transaction)
                    transaction = []

    def _sample(self) -> Dict[str, BinaryValue]:
        return {name: signal.value for name, signal in self._signals.items()}


class FftTester:
    """Checker of a FFT instance."""

    def __init__(self, dut: SimHandleBase):
        self.dut = dut
        self._checker = None

        self.input_mon = PacketMonitor(
            clk=self.dut.clk,
            signals={
                "data_i_in": self.dut.data_i_in,
                "data_q_in": self.dut.data_q_in,
            },
            valid=self.dut.data_valid_in,
            last=self.dut.data_last_in,
        )

        self.output_mon = PacketMonitor(
            clk=self.dut.clk,
            signals={
                "data_i_out": self.dut.data_i_out,
                "data_q_out": self.dut.data_q_out,
            },
            valid=self.dut.data_valid_out,
            last=self.dut.data_last_out,
        )

        # Start MATLAB session
        self._eng = matlab.engine.start_matlab("-sd ~/Workspaces/dfe")
        self._eng.setpath(nargout=0)

        # Create MATLAB reference System object
        self._model = self._eng.dfe.FFT(
            "FFTSize", float(FFT_SIZE),
            "InputDataWidth", float(INPUT_DATA_WIDTH),
            "PhaseWidth", float(PHASE_WIDTH),
            "OutputDataWidth", float(OUTPUT_DATA_WIDTH),
            'HasBitReverse', HAS_BITREVERSE,
        )

    def start(self) -> None:
        """Start the checker."""
        if self._checker is not None:
            raise RuntimeError("Checker already started")
        self.input_mon.start()
        self.output_mon.start()
        self._checker = cocotb.start_soon(self._check())

    def stop(self) -> None:
        """Stop the checker."""
        if self._checker is None:
            raise RuntimeError("Checker not started")
        self.input_mon.stop()
        self.output_mon.stop()
        self._checker.kill()
        self._checker = None

    def model(self, x: List[complex]) -> List[complex]:
        """
        Run the model with the given input and return the output.
        """
        # Create a MATLAB column vector
        x = matlab.double(x, is_complex=True)
        x = self._eng.transpose(x)
        y = self._eng.step(self._model, x)
        # Convert to Python list
        y = self._eng.num2cell(y)
        return y

    async def _check(self) -> None:
        """Checker function."""
        while True:
            input = await self.input_mon.values.get()
            output = await self.output_mon.values.get()
            x = [x["data_i_in"].signed_integer + 1j *
                 x["data_q_in"].signed_integer for x in input]
            y = [y["data_i_out"].signed_integer + 1j *
                 y["data_q_out"].signed_integer for y in output]
            y_ref = self.model(x)
            assert y == y_ref, "Output mismatch"


@cocotb.test()
async def fft_test(dut):
    """Test FFT design."""

    # Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())

    # Reset interface
    dut.rst.value = 1
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0
    dut.data_valid_in.value = 0
    dut.data_last_in.value = 0

    # Reset core
    await ClockCycles(dut.clk, 16)
    dut.rst.value = 0

    # Create checker
    await ClockCycles(dut.clk, 10)
    checker = FftTester(dut)
    checker.start()

    await ClockCycles(dut.clk, 10)
    for i in range(0, FFT_SIZE):
        await RisingEdge(dut.clk)
        dut.data_i_in.value = random.randint(
            -2**(INPUT_DATA_WIDTH-1), 2**(INPUT_DATA_WIDTH-1) - 1)
        dut.data_q_in.value = random.randint(
            -2**(INPUT_DATA_WIDTH-1), 2**(INPUT_DATA_WIDTH-1) - 1)
        dut.data_valid_in.value = 1
        if i == FFT_SIZE - 1:
            dut.data_last_in.value = 1
        else:
            dut.data_last_in.value = 0

    await RisingEdge(dut.clk)
    dut.data_i_in.value = 0
    dut.data_q_in.value = 0
    dut.data_valid_in.value = 0
    dut.data_last_in.value = 0

    await ClockCycles(dut.clk, 10000)
