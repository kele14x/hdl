import cocotb
import pyuvm
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
class BasicTest(uvm_test):

    def __init__(self, name, parent):
        self.dut = cocotb.top
        super().__init__(name, parent)

    async def run_phase(self):
        self.raise_objection()
        cocotb.start_soon(Clock(self.dut.aclk, 10).start())
        await ClockCycles(self.dut.aclk, 10)
        self.drop_objection()
