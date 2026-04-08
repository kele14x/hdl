#!/usr/bin/env python3

import os
from dataclasses import dataclass
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import ClockCycles, Event, RisingEdge
from cocotb_tools.runner import get_runner

ADDR_WIDTH = 10
DATA_WIDTH = 32

AXI_TIMEOUT_CYCLES = 16
TEST_TXN_COUNT = 10


async def reset_dut(dut):
    dut.s_axi_aresetn.value = 0
    await ClockCycles(dut.s_axi_aclk, 10)
    dut.s_axi_aresetn.value = 1
    await ClockCycles(dut.s_axi_aclk, 10)


class AxiOpHandle:
    def __init__(self):
        self._event = Event()
        self._result = None
        self._exc = None

    def set_result(self, result):
        if self._event.is_set():
            return
        self._result = result
        self._event.set()

    def set_exception(self, exc: Exception):
        if self._event.is_set():
            return
        self._exc = exc
        self._event.set()

    def done(self) -> bool:
        return self._event.is_set()

    def result(self):
        if not self._event.is_set():
            raise RuntimeError("Operation not completed")
        if self._exc is not None:
            raise self._exc
        return self._result

    async def wait(self):
        await self._event.wait()
        return self.result()


@dataclass
class _WriteReq:
    addr: int
    data: int
    handle: AxiOpHandle


@dataclass
class _ReadReq:
    addr: int
    handle: AxiOpHandle


class AxiMstAgent:
    def __init__(self, dut, timeout_cycles: int = AXI_TIMEOUT_CYCLES):
        self.dut = dut
        self.timeout_cycles = timeout_cycles
        self._full_wstrb = (2 ** (DATA_WIDTH // 8)) - 1

        self._wr_submit_q = Queue()
        self._rd_submit_q = Queue()
        self._tasks = []
        self._running = False

    def drive_idle(self):
        self.dut.s_axi_awaddr.value = 0
        self.dut.s_axi_awvalid.value = 0
        self.dut.s_axi_wdata.value = 0
        self.dut.s_axi_wstrb.value = 0
        self.dut.s_axi_wvalid.value = 0
        self.dut.s_axi_bready.value = 0
        self.dut.s_axi_araddr.value = 0
        self.dut.s_axi_arvalid.value = 0
        self.dut.s_axi_rready.value = 0

    def start(self):
        if self._running:
            return
        self._running = True
        self.drive_idle()

        self._tasks = [
            cocotb.start_soon(self._wr_loop()),
            cocotb.start_soon(self._rd_loop()),
        ]

    def stop(self):
        if not self._running:
            return
        self._running = False
        for task in self._tasks:
            task.cancel()
        self._tasks = []
        self.drive_idle()

    def write_nowait(self, addr: int, data: int) -> AxiOpHandle:
        handle = AxiOpHandle()
        self._wr_submit_q.put_nowait(_WriteReq(addr=addr, data=data, handle=handle))
        return handle

    async def write(self, addr: int, data: int) -> int:
        handle = self.write_nowait(addr=addr, data=data)
        return await handle.wait()

    def read_nowait(self, addr: int) -> AxiOpHandle:
        handle = AxiOpHandle()
        self._rd_submit_q.put_nowait(_ReadReq(addr=addr, handle=handle))
        return handle

    async def read(self, addr: int) -> tuple[int, int]:
        handle = self.read_nowait(addr=addr)
        return await handle.wait()

    async def _wait_ready(self, ready, timeout_msg: str):
        for _ in range(self.timeout_cycles):
            await RisingEdge(self.dut.s_axi_aclk)
            if int(ready.value):
                return
        raise TimeoutError(timeout_msg)

    async def _wait_valid(self, valid, timeout_msg: str):
        for _ in range(self.timeout_cycles):
            await RisingEdge(self.dut.s_axi_aclk)
            if int(valid.value):
                return
        raise TimeoutError(timeout_msg)

    async def _drive_write(self, addr: int, data: int):
        self.dut.s_axi_awaddr.value = addr
        self.dut.s_axi_wdata.value = data
        self.dut.s_axi_wstrb.value = self._full_wstrb
        self.dut.s_axi_awvalid.value = 1
        self.dut.s_axi_wvalid.value = 1

        aw_done = False
        w_done = False
        try:
            for _ in range(self.timeout_cycles):
                await RisingEdge(self.dut.s_axi_aclk)
                if not aw_done and int(self.dut.s_axi_awready.value):
                    aw_done = True
                    self.dut.s_axi_awvalid.value = 0
                if not w_done and int(self.dut.s_axi_wready.value):
                    w_done = True
                    self.dut.s_axi_wvalid.value = 0
                if aw_done and w_done:
                    return
            missing = []
            if not aw_done:
                missing.append("AW")
            if not w_done:
                missing.append("W")
            raise TimeoutError(f"AXI {'/'.join(missing)} handshake timeout")
        finally:
            self.dut.s_axi_awvalid.value = 0
            self.dut.s_axi_wvalid.value = 0

    async def _recv_b(self) -> int:
        self.dut.s_axi_bready.value = 1
        try:
            await self._wait_valid(self.dut.s_axi_bvalid, "AXI B handshake timeout")
            return int(self.dut.s_axi_bresp.value)
        finally:
            self.dut.s_axi_bready.value = 0

    async def _drive_ar(self, addr: int):
        self.dut.s_axi_araddr.value = addr
        self.dut.s_axi_arvalid.value = 1
        try:
            await self._wait_ready(self.dut.s_axi_arready, "AXI AR handshake timeout")
        finally:
            self.dut.s_axi_arvalid.value = 0

    async def _recv_r(self) -> tuple[int, int]:
        self.dut.s_axi_rready.value = 1
        try:
            await self._wait_valid(self.dut.s_axi_rvalid, "AXI R handshake timeout")
            rdata = int(self.dut.s_axi_rdata.value)
            rresp = int(self.dut.s_axi_rresp.value)
            return (rdata, rresp)
        finally:
            self.dut.s_axi_rready.value = 0

    async def _wr_loop(self):
        while True:
            req = await self._wr_submit_q.get()
            try:
                await self._drive_write(req.addr, req.data)
                bresp = await self._recv_b()
                req.handle.set_result(bresp)
            except Exception as exc:
                req.handle.set_exception(exc)

    async def _rd_loop(self):
        while True:
            req = await self._rd_submit_q.get()
            try:
                await self._drive_ar(req.addr)
                req.handle.set_result(await self._recv_r())
            except Exception as exc:
                req.handle.set_exception(exc)


# Model


def implicit_mem_data(addr: int) -> int:
    return (0xDEADBEEF + (addr >> 2)) & ((1 << DATA_WIDTH) - 1)


async def model(dut):
    mem = {}
    write_ack = False
    write_err = False
    read_ack = False
    read_err = False
    read_data = 0
    while True:
        await RisingEdge(dut.s_axi_aclk)
        # Reset condition
        if not dut.s_axi_aresetn.value:
            mem = {}
            write_ack = False
            write_err = False
            read_ack = False
            read_err = False
            read_data = 0
            dut.int_wr_ack.value = 0
            dut.int_wr_err.value = 0
            dut.int_rd_ack.value = 0
            dut.int_rd_err.value = 0
            dut.int_rd_data.value = 0
            continue

        # Write operation
        if int(dut.int_wr_en.value):
            addr = int(dut.int_addr.value)
            data = int(dut.int_wr_data.value)
            mem[addr] = data
            write_ack = True
            write_err = False
        # Read operation
        if int(dut.int_rd_en.value):
            addr = int(dut.int_addr.value)
            read_ack = True
            read_err = False
            read_data = mem[addr] if addr in mem else implicit_mem_data(addr)

        # Write response
        dut.int_wr_ack.value = 1 if write_ack else 0
        dut.int_wr_err.value = 1 if write_err else 0
        write_ack = False
        # Read response
        dut.int_rd_ack.value = 1 if read_ack else 0
        dut.int_rd_err.value = 1 if read_err else 0
        dut.int_rd_data.value = read_data
        read_ack = False


async def checker(dut, stop_evt: Event):
    aw_q = []
    w_q = []
    ar_q = []
    full_wstrb = (2 ** (DATA_WIDTH // 8)) - 1
    wr_cmp_cnt = 0
    rd_cmp_cnt = 0

    while True:
        await RisingEdge(dut.s_axi_aclk)
        if stop_evt.is_set():
            assert not aw_q, f"Checker: pending AW transactions at stop: {len(aw_q)}"
            assert not w_q, f"Checker: pending W transactions at stop: {len(w_q)}"
            assert not ar_q, f"Checker: pending AR transactions at stop: {len(ar_q)}"
            cocotb.log.info(
                "Checker: compared transactions: writes=%d reads=%d total=%d",
                wr_cmp_cnt,
                rd_cmp_cnt,
                wr_cmp_cnt + rd_cmp_cnt,
            )
            break

        if int(dut.s_axi_awvalid.value) and int(dut.s_axi_awready.value):
            aw_q.append(int(dut.s_axi_awaddr.value))

        if int(dut.s_axi_wvalid.value) and int(dut.s_axi_wready.value):
            w_q.append((int(dut.s_axi_wdata.value), int(dut.s_axi_wstrb.value)))

        if int(dut.s_axi_arvalid.value) and int(dut.s_axi_arready.value):
            ar_q.append(int(dut.s_axi_araddr.value))

        if int(dut.int_wr_en.value):
            assert aw_q, "Checker: int_wr_en without AXI AW"
            assert w_q, "Checker: int_wr_en without AXI W"
            exp_awaddr = aw_q.pop(0)
            exp_wdata, exp_wstrb = w_q.pop(0)

            got_addr = int(dut.int_addr.value)
            got_data = int(dut.int_wr_data.value)
            got_strb = int(dut.int_wr_strb.value)

            assert got_addr == exp_awaddr, (
                f"Checker: write addr mismatch got=0x{got_addr:x} exp=0x{exp_awaddr:x}"
            )
            assert got_data == exp_wdata, (
                f"Checker: write data mismatch got=0x{got_data:x} exp=0x{exp_wdata:x}"
            )
            assert got_strb == exp_wstrb == full_wstrb, (
                f"Checker: write strb mismatch got=0x{got_strb:x} exp=0x{exp_wstrb:x}"
            )
            wr_cmp_cnt += 1

        if int(dut.int_rd_en.value):
            assert ar_q, "Checker: int_rd_en without AXI AR"
            exp_araddr = ar_q.pop(0)
            got_addr = int(dut.int_addr.value)
            assert got_addr == exp_araddr, (
                f"Checker: read addr mismatch got=0x{got_addr:x} exp=0x{exp_araddr:x}"
            )
            rd_cmp_cnt += 1


async def stop_checker(dut, stop_evt: Event, checker_task):
    stop_evt.set()
    await RisingEdge(dut.s_axi_aclk)
    await checker_task


@cocotb.test()
async def test_axi4l_ipif_simple_write(dut):
    # Start clock and model
    Clock(dut.s_axi_aclk, 10, unit="ns").start()
    cocotb.start_soon(model(dut))

    # Reset DUT
    mst_agent = AxiMstAgent(dut)
    mst_agent.drive_idle()
    await reset_dut(dut)
    mst_agent.start()
    checker_stop_evt = Event()
    checker_task = cocotb.start_soon(checker(dut, checker_stop_evt))

    # Sequential write test (submit each write after previous completes).
    test_addr = [0x04 + i * 4 for i in range(TEST_TXN_COUNT)]
    test_data = [0xDEADBEEF + i for i in range(TEST_TXN_COUNT)]
    for addr, data in zip(test_addr, test_data):
        bresp = await mst_agent.write(addr, data)
        assert bresp == 0, f"AXI write response error: addr=0x{addr:x} bresp={bresp}"

    mst_agent.stop()
    await stop_checker(dut, checker_stop_evt, checker_task)

    # Recovery
    await ClockCycles(dut.s_axi_aclk, 10)


@cocotb.test()
async def test_axi4l_ipif_simple_b2b_write(dut):
    # Start clock and model
    Clock(dut.s_axi_aclk, 10, unit="ns").start()
    cocotb.start_soon(model(dut))

    # Reset DUT
    mst_agent = AxiMstAgent(dut)
    mst_agent.drive_idle()
    await reset_dut(dut)
    mst_agent.start()
    checker_stop_evt = Event()
    checker_task = cocotb.start_soon(checker(dut, checker_stop_evt))

    # Submit multiple writes first, then collect responses.
    test_addr = [0x04 + i * 4 for i in range(TEST_TXN_COUNT)]
    test_data = [0xDEADBEEF + i for i in range(TEST_TXN_COUNT)]
    handles = [mst_agent.write_nowait(a, d) for a, d in zip(test_addr, test_data)]
    bresp = [await handle.wait() for handle in handles]
    assert all(b == 0 for b in bresp), f"AXI write response error: bresp={bresp}"

    mst_agent.stop()
    await stop_checker(dut, checker_stop_evt, checker_task)

    # Recovery
    await ClockCycles(dut.s_axi_aclk, 10)


@cocotb.test()
async def test_axi4l_ipif_simple_read(dut):
    # Start clock and model
    Clock(dut.s_axi_aclk, 10, unit="ns").start()
    cocotb.start_soon(model(dut))

    # Reset DUT
    mst_agent = AxiMstAgent(dut)
    mst_agent.drive_idle()
    await reset_dut(dut)
    mst_agent.start()
    checker_stop_evt = Event()
    checker_task = cocotb.start_soon(checker(dut, checker_stop_evt))

    # Read implicitly initialized data.
    test_addr = [0x20 + i * 4 for i in range(TEST_TXN_COUNT)]
    test_data = [implicit_mem_data(addr) for addr in test_addr]

    for addr, exp_data in zip(test_addr, test_data):
        rdata, rresp = await mst_agent.read(addr)
        assert rresp == 0, f"AXI read response error: addr=0x{addr:x} rresp={rresp}"
        assert rdata == exp_data, (
            f"AXI read data mismatch: addr=0x{addr:x} got=0x{rdata:x} exp=0x{exp_data:x}"
        )

    mst_agent.stop()
    await stop_checker(dut, checker_stop_evt, checker_task)

    # Recovery
    await ClockCycles(dut.s_axi_aclk, 10)


@cocotb.test()
async def test_axi4l_ipif_simple_b2b_read(dut):
    # Start clock and model
    Clock(dut.s_axi_aclk, 10, unit="ns").start()
    cocotb.start_soon(model(dut))

    # Reset DUT
    mst_agent = AxiMstAgent(dut)
    mst_agent.drive_idle()
    await reset_dut(dut)
    mst_agent.start()
    checker_stop_evt = Event()
    checker_task = cocotb.start_soon(checker(dut, checker_stop_evt))

    # Read implicitly initialized data.
    test_addr = [0x40 + i * 4 for i in range(TEST_TXN_COUNT)]
    test_data = [implicit_mem_data(addr) for addr in test_addr]

    # Submit reads as fast as possible, then collect responses.
    handles = [mst_agent.read_nowait(addr) for addr in test_addr]
    results = [await handle.wait() for handle in handles]

    for addr, exp_data, (rdata, rresp) in zip(test_addr, test_data, results):
        assert rresp == 0, f"AXI read response error: addr=0x{addr:x} rresp={rresp}"
        assert rdata == exp_data, (
            f"AXI read data mismatch: addr=0x{addr:x} got=0x{rdata:x} exp=0x{exp_data:x}"
        )

    mst_agent.stop()
    await stop_checker(dut, checker_stop_evt, checker_task)

    # Recovery
    await ClockCycles(dut.s_axi_aclk, 10)


def test_axi4l_ipif_runner():
    sim = os.getenv("SIM", "verilator")

    proj_path = Path(__file__).resolve().parent
    sources = [
        proj_path / "../rtl/axi4l_ipif.sv",
    ]
    hdl_toplevel = "axi4l_ipif"

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        parameters={
            "ADDR_WIDTH": ADDR_WIDTH,
            "DATA_WIDTH": DATA_WIDTH,
        },
        always=True,
        waves=True,
    )
    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module="test_axi4l_ipif",
        waves=True,
    )


if __name__ == "__main__":
    test_axi4l_ipif_runner()
