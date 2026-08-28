"""End-to-end PUXCH receive-path simulation.

The test drives radio samples into the AXI-Stream input, programs the real
AXI4-Lite register block, and checks the requested O-RAN output words against
a fixed-point model of gain, frequency conversion, FFT, and buffer packing.

The register block and the PUXCH data path contain three independent carrier
buffers.  A separate simulator run is used for each carrier so that each run
can read both legal pieces of the 273-PRB request without carrying state from
a previous carrier request.
"""

from __future__ import annotations

import os
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Combine, RisingEdge, Timer, with_timeout
from puxch_reference import bfp9_readout_words, puxch_reference
from puxch_test_utils import run_cocotb

from hdl_tools.axi4lite import AxiLiteAgent, AxiLiteAgentConfig
from hdl_tools.axis import (
    AxisAgent,
    AxisAgentConfig,
    AxisBeat,
    AxisFrame,
    AxisRole,
    AxisSourceDriver,
)

NUM_CC = 3
NUM_ANT = 4
FFT_SIZE = 4096
# The first sync marker is followed by 4096 samples per antenna.  The extra
# groups keep the source valid until the first complete FFT has entered the
# processing pipeline, without reaching the next bank's full frame.
NUM_SOURCE_GROUPS = 4200
NUM_OUTPUT_PRB = 273
TEST_CC = int(os.environ.get("PUXCH_TEST_CC", "0"))

# PUXCH register addresses.
UL_EN = 0x210
UL_RAT = 0x214
UL_BIST = 0x218
UL_BW = 0x21C
UL_NPRB_BASE = 0x220
UL_RFS_OFFSET_BASE = 0x230
UL_UD = 0x258
UL_GAIN_BASE = 0x300
UL_PHASE_COMP_BASE = 0xA00

NR_30_KHZ_ALL_CC = 0x222
BW_100_MHZ_ALL_CC = 0x444
ALL_ANTENNAS_ALL_CC = 0xFFF
UNITY_Q14 = 0x4000
GAIN_Q14 = (0x4000, 0x3000, 0x5000, 0x2000)


class _IndexedAxisView:
    """Expose one element of an unpacked AXI-Stream array to an agent."""

    def __init__(self, dut, prefix: str, *indices: int):
        self._dut = dut
        self._prefix = prefix
        self._indices = indices

    def __getattr__(self, name):
        signal = getattr(self._dut, name)
        if name.startswith(f"{self._prefix}_"):
            for index in self._indices:
                signal = signal[index]
        return signal


def _pack_iq(real: int, imag: int) -> int:
    return ((int(imag) & 0xFFFF) << 16) | (int(real) & 0xFFFF)


def _source_frame(
    rng: np.random.Generator, antenna: int
) -> tuple[AxisFrame, np.ndarray, np.ndarray]:
    """Create a continuous held-sample stream for one radio antenna."""

    real = rng.integers(-64, 65, size=NUM_SOURCE_GROUPS, dtype=np.int64)
    imag = rng.integers(-64, 65, size=NUM_SOURCE_GROUPS, dtype=np.int64)
    beats = []
    for group in range(NUM_SOURCE_GROUPS):
        data = _pack_iq(real[group], imag[group])
        for repeat in range(NUM_ANT):
            beats.append(
                AxisBeat(
                    data=data,
                    user=(TEST_CC << 4) | antenna,
                    last=(group == NUM_SOURCE_GROUPS - 1 and repeat == NUM_ANT - 1),
                )
            )
    return AxisFrame(beats), real, imag


async def _configure(axi: AxiLiteAgent):
    assert await axi.read(0x00) == 0x20250106
    await axi.write(UL_EN, ALL_ANTENNAS_ALL_CC)
    await axi.write(UL_RAT, NR_30_KHZ_ALL_CC)
    await axi.write(UL_BIST, 0)
    await axi.write(UL_BW, BW_100_MHZ_ALL_CC)
    # BFP9 output is mandatory. Keep the legacy comp_meth field at zero to
    # verify that it no longer enables a raw-data bypass.
    await axi.write(UL_UD, 0x090)

    for cc in range(NUM_CC):
        await axi.write(UL_NPRB_BASE + 4 * cc, NUM_OUTPUT_PRB)
        await axi.write(UL_RFS_OFFSET_BASE + 4 * cc, 0)
        for antenna in range(NUM_ANT):
            await axi.write(
                UL_GAIN_BASE + 4 * (cc * NUM_ANT + antenna),
                GAIN_Q14[antenna],
            )

    # Program all carrier/symbol pages.  Unity compensation exercises the
    # phase-compensation RAM write path while keeping the arithmetic reference
    # independent of the selected symbol page.
    for address in range(NUM_CC * 16):
        await axi.write(UL_PHASE_COMP_BASE + 4 * address, UNITY_Q14)

    assert await axi.read(UL_EN) & 0xFFF == ALL_ANTENNAS_ALL_CC
    assert await axi.read(UL_RAT) & 0xFFF == NR_30_KHZ_ALL_CC
    assert await axi.read(UL_BW) & 0xFFF == BW_100_MHZ_ALL_CC
    assert await axi.read(UL_NPRB_BASE) & 0x1FF == NUM_OUTPUT_PRB
    assert await axi.read(UL_PHASE_COMP_BASE) == UNITY_Q14


async def _reset(dut, axi: AxiLiteAgent, sources, sinks):
    axi.driver.idle()
    dut.s_axi_aresetn.value = 0
    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    dut.sync_in.value = 0
    for source in sources:
        source.idle()
    for sink in sinks:
        sink.driver.idle()

    # Keep the design in reset for 100 cycles of every clock domain so all
    # flops have settled from their power-on X state, then wait another 100
    # cycles after release before driving stimulus.
    await ClockCycles(dut.s_axi_aclk, 100)
    await ClockCycles(dut.clk, 100)
    await ClockCycles(dut.clk_eth_xran, 100)
    dut.s_axi_aresetn.value = 1
    dut.rst.value = 0
    dut.rst_eth_xran.value = 0
    await ClockCycles(dut.s_axi_aclk, 100)
    await ClockCycles(dut.clk, 100)


async def _capture_first_symbol(dut):
    """Capture the first complete symbol at the resynchronizer boundary.

    The phase-output counters are only used as a completion indication.  The
    expected values are calculated from the resynchronizer samples, while the
    final assertions consume only the external FRAM stream.
    """

    channel = dut.i_puxch.g_cc[TEST_CC].u_channel
    resync = channel.u_resync
    samples = [[] for _ in range(NUM_ANT)]
    phase_count = [0] * NUM_ANT
    started = False
    phase_started = False
    previous_sy = False
    previous_phase_sy = False

    while (
        not started
        or any(len(values) < FFT_SIZE for values in samples)
        or not phase_started
        or min(phase_count) < FFT_SIZE
    ):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")

        sy = bool(int(resync.dout_sy.value))
        if sy and not previous_sy:
            started = True
        previous_sy = sy
        if started and int(resync.dout_dv.value):
            antenna = int(resync.dout_chn.value)
            if antenna < NUM_ANT and len(samples[antenna]) < FFT_SIZE:
                samples[antenna].append(
                    (resync.dout_dr.value.to_signed(), resync.dout_di.value.to_signed())
                )

        phase_sy = bool(int(channel.phase_comp_dout_sy.value))
        if phase_sy and not previous_phase_sy:
            phase_started = True
        previous_phase_sy = phase_sy
        if phase_started and int(channel.phase_comp_dout_dv.value):
            antenna = int(channel.phase_comp_dout_chn.value)
            if antenna < NUM_ANT and phase_count[antenna] < FFT_SIZE:
                phase_count[antenna] += 1

    return samples


async def _pulse_sync(dut):
    await RisingEdge(dut.clk_eth_xran)
    dut.sync_in.value = 1
    await RisingEdge(dut.clk_eth_xran)
    await Timer(1, unit="ps")
    dut.sync_in.value = 0


async def _request(dut, antenna: int, cc: int, start_prb: int, num_prb: int):
    request = (1 << 24) | (int(start_prb) << 15) | (int(num_prb) << 7) | int(cc)
    await RisingEdge(dut.clk_eth_xran)
    dut.m_fram_data_req[antenna].value = request
    await RisingEdge(dut.clk_eth_xran)
    await Timer(1, unit="ps")
    dut.m_fram_data_req[antenna].value = 0


async def _receive_request(
    sink: AxisAgent, dut, antenna: int, start_prb: int, num_prb: int
):
    receive_task = cocotb.start_soon(sink.receive())
    await _request(dut, antenna, TEST_CC, start_prb, num_prb)
    return await with_timeout(receive_task, 20, timeout_unit="us")


@cocotb.test()
async def test_puxch_end_to_end_data_path(dut):
    assert 0 <= TEST_CC < NUM_CC
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 2, unit="ns").start())

    axi = AxiLiteAgent(
        dut,
        AxiLiteAgentConfig(
            prefix="s_axi",
            clock="s_axi_aclk",
            reset="s_axi_aresetn",
            reset_active_level=0,
            timeout_cycles=100,
        ),
    )

    sources = []
    for cc in range(NUM_CC):
        for antenna in range(NUM_ANT):
            view = _IndexedAxisView(dut, "s_axis", cc, antenna)
            sources.append(
                AxisSourceDriver(
                    view,
                    AxisAgentConfig(
                        prefix="s_axis",
                        clock="clk",
                        reset="rst",
                        reset_active_level=1,
                        timeout_cycles=1000,
                    ),
                )
            )

    sinks = []
    for antenna in range(NUM_ANT):
        view = _IndexedAxisView(dut, "m_fram_data", antenna)
        sinks.append(
            AxisAgent(
                view,
                AxisAgentConfig(
                    prefix="m_fram_data",
                    clock="clk_eth_xran",
                    reset="rst_eth_xran",
                    reset_active_level=1,
                    timeout_cycles=10000,
                    role=AxisRole.SINK,
                ),
                # bfp_comp cannot be backpressured, so the framer stream must
                # stay always-ready; the buffer's hold-under-backpressure
                # behavior is covered by test_puxch_buffer instead.
            )
        )

    # Hold reset for 100 cycles of every clock domain and wait another 100
    # after release, BEFORE starting any agent: monitors that start at 0 ns
    # otherwise sample the power-on X state on their first clock edge.
    await _reset(dut, axi, sources, sinks)
    await axi.start()
    for sink in sinks:
        await sink.start()
    await _configure(axi)

    rng = np.random.default_rng(0x50555843 + TEST_CC)
    target_sources = sources[TEST_CC * NUM_ANT : (TEST_CC + 1) * NUM_ANT]
    source_records = [_source_frame(rng, antenna) for antenna in range(NUM_ANT)]
    send_tasks = [
        cocotb.start_soon(source.send(record[0]))
        for source, record in zip(target_sources, source_records, strict=True)
    ]

    await ClockCycles(dut.clk, 32)
    capture_task = cocotb.start_soon(_capture_first_symbol(dut))
    await _pulse_sync(dut)
    captured = await with_timeout(capture_task, 200, timeout_unit="us")
    await Combine(*send_tasks)

    for antenna in range(NUM_ANT):
        assert len(captured[antenna]) == FFT_SIZE
        captured_real = np.asarray(
            [sample[0] for sample in captured[antenna]], dtype=np.int64
        )
        captured_imag = np.asarray(
            [sample[1] for sample in captured[antenna]], dtype=np.int64
        )
        source_real = source_records[antenna][1]
        source_imag = source_records[antenna][2]
        matching_offsets = [
            offset
            for offset in range(NUM_SOURCE_GROUPS - FFT_SIZE + 1)
            if np.array_equal(captured_real, source_real[offset : offset + FFT_SIZE])
            and np.array_equal(captured_imag, source_imag[offset : offset + FFT_SIZE])
        ]
        assert matching_offsets, (
            f"carrier {TEST_CC}, antenna {antenna}: radio input did not "
            "reach the PUXCH resynchronizer"
        )

    # The wrapper currently exposes symbol-bank zero (s_ul_sym_num is tied to
    # zero).  The request field holds only eight bits of PRB count, so read the
    # complete 273-PRB region as 255 + 18 PRBs.
    reference_by_antenna = []
    for antenna in range(NUM_ANT):
        real = np.asarray([sample[0] for sample in captured[antenna]], dtype=np.int64)
        imag = np.asarray([sample[1] for sample in captured[antenna]], dtype=np.int64)
        reference_by_antenna.append(
            puxch_reference(
                real,
                imag,
                rat=2,
                bw=4,
                nprb=NUM_OUTPUT_PRB,
                gain=GAIN_Q14[antenna],
            )
        )

    for antenna, reference in enumerate(reference_by_antenna):
        for start_prb, num_prb in ((0, 255), (255, 18)):
            frame = await _receive_request(
                sinks[antenna], dut, antenna, start_prb, num_prb
            )
            expected, expected_keep = bfp9_readout_words(
                reference,
                start_prb=start_prb,
                num_prb=num_prb,
            )
            assert len(frame) == len(expected)
            assert [beat.keep for beat in frame] == expected_keep
            assert [beat.last for beat in frame] == [False] * (len(frame) - 1) + [True]
            assert [beat.data for beat in frame] == expected, (
                f"BFP9 PUXCH mismatch for carrier {TEST_CC}, antenna {antenna}, "
                f"PRBs {start_prb}:{start_prb + num_prb}"
            )
            await ClockCycles(dut.clk_eth_xran, 32)

    assert all(sink.monitor.frames.empty() for sink in sinks)
    for source in target_sources:
        source.idle()
    for sink in sinks:
        sink.stop()
    axi.stop()


def _run_puxch(test_cc, monkeypatch):
    monkeypatch.setenv("PUXCH_TEST_CC", str(test_cc))
    run_cocotb(
        "puxch",
        Path(__file__).stem,
        parameters={
            "NUM_CC": NUM_CC,
            "NUM_ANT": NUM_ANT,
            "HALF_BLOCK": 0,
            "HALF_FFT": 0,
        },
        build_name=f"end_to_end_cc{test_cc}",
        extra_env={"PUXCH_TEST_CC": str(test_cc)},
    )


@pytest.mark.parametrize(
    "test_cc", range(NUM_CC), ids=[f"cc{cc}" for cc in range(NUM_CC)]
)
def test_puxch_runner(test_cc, monkeypatch):
    _run_puxch(test_cc, monkeypatch)


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
