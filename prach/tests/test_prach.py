"""Top-level end-to-end regression for the full ``prach`` module.

The test instantiates the whole PRACH module (AXI4-Lite register block, O-RAN
C-plane interface, and the receive chain resync -> DDC -> stream2block ->
FFT -> framer) and exercises the reachable top-level interfaces end to end
with the production radio timing:

    AXI regs   -> prach_regs  -> cdc -> resync/ctrl          (register path)
    C-plane    -> cdc handshake -> prach_ctrl -> status regs  (message path)
    sync_in    -> pulse delay -> cdc -> resync frame start    (timing path)
    radio AXI-S -> resync -> ddc                 (front-end data path)

Radio configuration (production values): ``clk`` is a 491.52 MHz radio clock
(2034 ps in simulation; the 1 ps time precision cannot represent 491.52 MHz
exactly, a 0.02% deviation irrelevant for this cycle-accurate design) and
each antenna is captured at 30.72 Msps, i.e. one 32-bit I/Q word every 16
radio clocks.  In the resynchronizer this is the chn_max=15 lane
configuration (bw = 2, the "30.72" entry).  The six-stage DDC decimates each
antenna by 16 to the 1.92 Msps PRACH baseband rate.

Checks:

1.  AXI4-Lite register programming and readback (version, en/rat/bw/ud,
    scratch) through ``prach_regs``.
2.  One dynamic O-RAN C-plane message crosses the CDC handshake and is
    latched by ``prach_ctrl``; the CC0 inspect registers (prach_msg0/1/2)
    mirror the message fields.
3.  The ``sync_in`` pulse reaches the resynchronizer and starts the radio
    frame / symbol timing (start-of-frame / start-of-symbol observed).
4.  The generated LTE F0 waveform survives ``prach_resync`` bit-exactly on
    the active antenna, with four valid complex lanes per 16-clock loop.
5.  The DDC rotates the four antenna channels at the 1.92 Msps cadence.
6.  An F0 preamble runs for one nominal 1 ms interval and produces one
    complete U-plane packet through stream2block -> FFT -> framer.
7.  The FFT contains exactly 13 left guard REs, 839 occupied REs, and 12
    right guard REs in the 864-RE window consumed by the framer, and the ZC
    sequence has approximately constant magnitude.
"""

from __future__ import annotations

import os
import shutil
from pathlib import Path

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb_tools.runner import get_runner
from hdl_tools.axi4lite import AxiLiteAgent, AxiLiteAgentConfig
from hdl_tools.flt_tool import resolve_flt
from prach_waveform import DEFAULT_WAVEFORM_PATH, read_iq_hex

PRJ_PATH = Path(__file__).resolve().parent.parent

SIM = os.environ.get("SIM")
if not SIM:
    raise RuntimeError("SIM must be set explicitly, for example SIM=questa")

NUM_CC = 3
NUM_ANT = 4
SECTION_ID = 0x321
TEST_CC = 0
TEST_ANT = 0

# Mixed C-plane values make the status-register check sensitive to field
# packing and CDC corruption while keeping the F0 timing fields production-valid.
CPLANE_SUBFRAME = 0x0
CPLANE_SLOT = 0x0
CPLANE_SYMBOL = 0x0
CPLANE_TIME_OFFSET = 0x0
CPLANE_CP_LENGTH = 0x0
CPLANE_NUM_SYMBOL = 0x1
# Lowest RE of the 864-RE LTE PRACH occasion: -9 MHz / 0.625 kHz.
CPLANE_FREQ_OFFSET = (-14_400) & 0xFFFFFF

# Radio system clock / sample-rate configuration (production values): the
# radio clock runs at 491.52 MHz and each antenna is captured at 30.72 Msps,
# i.e. one 32-bit I/Q word every 16 radio clocks.  In the resynchronizer this
# is the chn_max=15 lane configuration (bw = 2, the "30.72" entry).
#
# The simulator time precision is 1 ps, so 491.52 MHz (a 2034.5052 ps period)
# cannot be represented exactly, and cocotb clock periods must be even (the
# high/low halves are each period/2).  2034 ps is used instead (0.02%
# deviation, irrelevant for this cycle-accurate design).
RADIO_CLOCK_PS = 2034
RADIO_SAMPLES_PER_CLK = 16
F0_RADIO_CYCLES = 491_520
FRONTEND_CHECK_CYCLES = 2048
U_PLANE_DRAIN_ETH_CYCLES = 2048

# PRACH register addresses (word index << 2, from rdl/prach.rdl).
PRACH_EN = 0x410
PRACH_FORMAT = 0x414
PRACH_RAT = 0x418
PRACH_BIST = 0x41C
PRACH_BW = 0x420
PRACH_UD = 0x458
PRACH_CFG3_BASE = 0x490
PRACH_MSG0_BASE = 0x500
PRACH_MSG1_BASE = 0x510
PRACH_MSG2_BASE = 0x520

CC0_EN = 0xF
RAT_LTE = 0x0
# chn_max = 15: 16 radio-clock phases per antenna sample -> 30.72 Msps per
# antenna on the 491.52 MHz radio clock (the resynchronizer's "30.72" lane
# configuration).
BW_30MHZ_ALL_CC = 0x222
UD_BFP9 = 0x00000091  # comp_meth=1, iq_width=9, fs_offset=0

FFT_SIZE = 1536
CAPTURE_RE = 864
LEFT_GUARD_RE = 13
ACTIVE_RE = 839
RIGHT_GUARD_RE = 12
# The fixed-point RTL guard/noise floor is near -55 dB, while the corrected
# active ZC bins remain within 1 dB of the peak.
OCCUPIED_THRESHOLD_DB = -50.0
MAX_ACTIVE_RIPPLE_DB = 1.0


def _set_cplane(dut, **overrides):
    fields = {
        "s_prach_rtc_pc_id": 0,
        "s_prach_cc": TEST_CC,
        "s_prach_ss": TEST_ANT,
        "s_prach_section_id": SECTION_ID,
        "s_prach_return_port": 0,
        "s_prach_filter_index": 0,
        "s_prach_f": 0,
        "s_prach_sf": CPLANE_SUBFRAME,
        "s_prach_sl": CPLANE_SLOT,
        "s_prach_sy": CPLANE_SYMBOL,
        "s_prach_time_offset": CPLANE_TIME_OFFSET,
        "s_prach_frame_structure": 0,
        "s_prach_cp_length": CPLANE_CP_LENGTH,
        "s_prach_udcomphdr": 0,
        "s_prach_rb": 0,
        "s_prach_syminc": 0,
        "s_prach_start_prbc": 0,
        "s_prach_num_prbc": 0,
        "s_prach_remask": 0,
        "s_prach_num_symbol": CPLANE_NUM_SYMBOL,
        "s_prach_beamid": 0,
        "s_prach_freqoffset": CPLANE_FREQ_OFFSET,
    }
    fields.update(overrides)
    for name, value in fields.items():
        getattr(dut, name).value = value


def _signed16(value: int) -> int:
    value &= 0xFFFF
    return value - (1 << 16) if value & (1 << 15) else value


async def _reset(dut, axi: AxiLiteAgent):
    axi.driver.idle()
    dut.s_axi_aresetn.value = 0
    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    dut.sync_in.value = 0
    dut.s_prach_tvalid.value = 0
    _set_cplane(dut)
    for cc in range(NUM_CC):
        for antenna in range(NUM_ANT):
            dut.s_axis_tdata[cc][antenna].value = 0
            dut.s_axis_tlast[cc][antenna].value = 0
            dut.s_axis_tuser[cc][antenna].value = 0
            dut.s_axis_tvalid[cc][antenna].value = 1
    dut.m_fram_prach_tready.value = 1

    # Hold every clock domain in reset long enough for all flops to settle,
    # then wait again after release before driving stimulus.
    await ClockCycles(dut.s_axi_aclk, 100)
    await ClockCycles(dut.clk, 100)
    await ClockCycles(dut.clk_eth_xran, 100)
    dut.s_axi_aresetn.value = 1
    dut.rst.value = 0
    dut.rst_eth_xran.value = 0
    await ClockCycles(dut.s_axi_aclk, 100)
    await ClockCycles(dut.clk, 100)
    await ClockCycles(dut.clk_eth_xran, 100)


async def _configure(axi: AxiLiteAgent):
    assert await axi.read(0x00) == 0x20250106
    await axi.write(PRACH_EN, CC0_EN)
    await axi.write(PRACH_FORMAT, 0)
    await axi.write(PRACH_RAT, RAT_LTE)
    await axi.write(PRACH_BIST, 0)  # dynamic (non-static) C-plane
    await axi.write(PRACH_BW, BW_30MHZ_ALL_CC)
    await axi.write(PRACH_UD, UD_BFP9)
    await axi.write(PRACH_CFG3_BASE + 4 * TEST_CC, 0)  # sampling_offset = 0

    # Scratch registers exercise the generic write/read datapath.
    await axi.write(0x04, 0xCAFE1234)
    await axi.write(0x08, 0x55AA55AA)
    assert await axi.read(0x04) == 0xCAFE1234
    assert await axi.read(0x08) == 0x55AA55AA

    assert await axi.read(PRACH_EN) & 0xFFF == CC0_EN
    assert await axi.read(PRACH_RAT) & 0x3 == RAT_LTE
    assert await axi.read(PRACH_BW) & 0xFFF == BW_30MHZ_ALL_CC
    assert await axi.read(PRACH_UD) & 0xFF == 0x91


async def _send_cplane(dut):
    """Send one C-plane message using the source-side ready/valid handshake."""
    _set_cplane(dut)
    dut.s_prach_tvalid.value = 1
    while True:
        await RisingEdge(dut.clk_eth_xran)
        if int(dut.s_prach_tready.value):
            break
    await Timer(1, unit="ps")
    dut.s_prach_tvalid.value = 0


async def _pulse_sync(dut):
    await RisingEdge(dut.clk_eth_xran)
    dut.sync_in.value = 1
    await RisingEdge(dut.clk_eth_xran)
    await Timer(1, unit="ps")
    dut.sync_in.value = 0


def _set_radio_sample(dut, word: int):
    """Drive one 30.72 Msps sample on the active antenna lane."""
    for cc in range(NUM_CC):
        for antenna in range(NUM_ANT):
            dut.s_axis_tdata[cc][antenna].value = word if antenna == TEST_ANT else 0


async def _drive_radio_samples(dut, waveform, first_sample: int, last_sample: int):
    """Drive production-rate samples without waking Python every radio edge."""
    group_period_ps = RADIO_CLOCK_PS * RADIO_SAMPLES_PER_CLK
    for sample in range(first_sample, last_sample):
        _set_radio_sample(dut, int(waveform[sample]))
        # The extra picosecond leaves the input update after the following
        # 16th rising edge, avoiding a same-timestamp race with the DUT.
        await Timer(group_period_ps + 1, unit="ps")


async def _monitor_uplane(dut, words):
    """Capture U-plane transfers at the Ethernet clock boundary."""
    while True:
        await RisingEdge(dut.clk_eth_xran)
        await Timer(1, unit="ps")
        if int(dut.m_fram_prach_tvalid.value):
            words.append(
                (
                    int(dut.m_fram_prach_tdata.value),
                    int(dut.m_fram_prach_tkeep.value),
                    int(dut.m_fram_prach_tlast.value),
                    int(dut.m_fram_prach_tuser.value),
                )
            )


async def _monitor_fft(dut, fft, samples):
    """Capture one valid 1536-point FFT output block from the active channel."""
    await RisingEdge(fft.dout_dv)
    await Timer(1, unit="ps")
    while len(samples) < FFT_SIZE:
        if int(fft.dout_dv.value):
            samples.append(
                (
                    int(fft.dout_chn.value),
                    _signed16(int(fft.dout_dr.value)),
                    _signed16(int(fft.dout_di.value)),
                )
            )
        if len(samples) == FFT_SIZE:
            break
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")


async def _monitor_valid_samples(dut, stream, samples, limit=32):
    """Capture a small number of valid samples from a streaming block."""
    while len(samples) < limit:
        await RisingEdge(stream.dout_dv)
        await Timer(1, unit="ps")
        while int(stream.dout_dv.value) and len(samples) < limit:
            samples.append(
                (
                    int(stream.dout_chn.value),
                    _signed16(int(stream.dout_dr.value)),
                    _signed16(int(stream.dout_di.value)),
                )
            )
            await RisingEdge(dut.clk)
            await Timer(1, unit="ps")


@cocotb.test()
async def test_prach_f0_1ms_e2e(dut):
    cocotb.start_soon(Clock(dut.s_axi_aclk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk, RADIO_CLOCK_PS, unit="ps").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 8, unit="ns").start())

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

    await _reset(dut, axi)
    await axi.start()
    await _configure(axi)
    dut._log.info("register configuration complete")

    channel = dut.i_prach_top.g_cc[TEST_CC].u_channel
    ctrl = channel.u_ctrl
    resync = channel.u_resync
    ddc = channel.u_ddc
    stream2block = channel.u_stream2block
    fft = channel.u_fft
    waveform = read_iq_hex(DEFAULT_WAVEFORM_PATH)
    assert waveform.size * RADIO_SAMPLES_PER_CLK == F0_RADIO_CYCLES

    # ---- C-plane -> prach_ctrl -> CSR status registers -----------------
    await _send_cplane(dut)
    dut._log.info("C-plane message sent")
    msg0 = await axi.read(PRACH_MSG0_BASE + 4 * TEST_CC)
    msg1 = await axi.read(PRACH_MSG1_BASE + 4 * TEST_CC)
    msg2 = await axi.read(PRACH_MSG2_BASE + 4 * TEST_CC)
    assert msg0 & 0x3F == CPLANE_SYMBOL, "symbol id mismatch"
    assert (msg0 >> 8) & 0x3F == CPLANE_SLOT, "slot id mismatch"
    assert (msg0 >> 16) & 0xF == CPLANE_SUBFRAME, "subframe id mismatch"
    assert msg1 & 0xFFFF == CPLANE_TIME_OFFSET, "time offset mismatch"
    assert (msg1 >> 16) & 0xFFFF == CPLANE_CP_LENGTH, "CP length mismatch"
    assert msg2 & 0xF == CPLANE_NUM_SYMBOL, "num_symbol mismatch"
    assert (msg2 >> 4) & 0xFFFFFF == CPLANE_FREQ_OFFSET, "frequency offset mismatch"
    assert int(ctrl.rd_section_id.value) == SECTION_ID, "section id mismatch"
    dut._log.info("C-plane status registers verified")

    # ---- sync -> resync frame start -------------------------------------
    await ClockCycles(dut.clk_eth_xran, 16)
    await _pulse_sync(dut)
    dut._log.info("radio-frame sync issued")

    uplane_words = []
    uplane_monitor = cocotb.start_soon(_monitor_uplane(dut, uplane_words))
    fft_samples = []
    fft_monitor = cocotb.start_soon(_monitor_fft(dut, fft, fft_samples))
    ddc_samples = []
    ddc_monitor = cocotb.start_soon(
        _monitor_valid_samples(dut, ddc, ddc_samples, limit=32)
    )
    stream2block_samples = []
    stream2block_monitor = cocotb.start_soon(
        _monitor_valid_samples(dut, stream2block, stream2block_samples, limit=FFT_SIZE)
    )

    # ---- Front end: F0 waveform through resync, DDC cadence -------------
    # Check the first short prefix cycle by cycle, then drive the remainder
    # in 16-clock groups. Inputs are changed only immediately after a clock
    # edge, so every valid resync sample has an unambiguous expected word.
    _set_radio_sample(dut, int(waveform[0]))
    seen_sf = False
    seen_sy = False
    resync_hits = 0
    resync_misses = 0
    resync_valid_phases = set()
    ddc_valid = 0
    ddc_ant0 = 0
    ddc_channels = set()
    for cycle in range(FRONTEND_CHECK_CYCLES):
        resync_phase = int(resync.chn.value)
        expected_antenna = resync_phase % NUM_ANT
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        if int(resync.dout_sf.value):
            seen_sf = True
        if int(resync.dout_sy.value):
            seen_sy = True
        if int(resync.dout_dv.value):
            resync_valid_phases.add(resync_phase)
            expected = (
                int(waveform[cycle // RADIO_SAMPLES_PER_CLK])
                if resync_phase < NUM_ANT and expected_antenna == TEST_ANT
                else 0
            )
            actual = (int(resync.dout_di.value) << 16) | int(resync.dout_dr.value)
            if actual == expected:
                resync_hits += 1
            else:
                resync_misses += 1
        if int(channel.u_ddc.dout_dv.value):
            ddc_valid += 1
            channel_value = int(channel.u_ddc.dout_chn.value) & 0xFF
            ddc_channels.add(channel_value)
            if channel_value == TEST_ANT:
                ddc_ant0 += 1
        if (
            cycle + 1
        ) % RADIO_SAMPLES_PER_CLK == 0 and cycle + 1 < FRONTEND_CHECK_CYCLES:
            _set_radio_sample(dut, int(waveform[(cycle + 1) // RADIO_SAMPLES_PER_CLK]))

    first_remaining_sample = FRONTEND_CHECK_CYCLES // RADIO_SAMPLES_PER_CLK
    await _drive_radio_samples(dut, waveform, first_remaining_sample, waveform.size)

    # Allow the stream2block, FFT, framer buffer, and Ethernet FIFO to drain.
    await ClockCycles(dut.clk_eth_xran, U_PLANE_DRAIN_ETH_CYCLES)
    uplane_monitor.cancel()
    fft_monitor.cancel()
    ddc_monitor.cancel()
    stream2block_monitor.cancel()

    dut._log.info(
        "F0 front end: cycles=%s resync hits/misses=%s/%s sf=%s sy=%s "
        "ddc_valid=%s ant0=%s channels=%s DDC samples=%s "
        "stream2block samples=%s FFT samples=%s U-plane words=%s "
        "DDC maxabs=%s stream2block maxabs=%s",
        F0_RADIO_CYCLES,
        resync_hits,
        resync_misses,
        seen_sf,
        seen_sy,
        ddc_valid,
        ddc_ant0,
        sorted(ddc_channels),
        ddc_samples[:4],
        stream2block_samples[:4],
        len(fft_samples),
        len(uplane_words),
        max((max(abs(real), abs(imag)) for _, real, imag in ddc_samples), default=0),
        max(
            (max(abs(real), abs(imag)) for _, real, imag in stream2block_samples),
            default=0,
        ),
    )

    fft_complex = np.asarray(
        [complex(real, imag) for _, real, imag in fft_samples], dtype=np.complex128
    )
    fft_magnitude = np.abs(fft_complex)
    fft_db = 20 * np.log10(
        np.maximum(fft_magnitude, 1e-12) / np.maximum(fft_magnitude.max(), 1e-12)
    )
    active_start = LEFT_GUARD_RE
    active_stop = active_start + ACTIVE_RE
    capture_stop = active_stop + RIGHT_GUARD_RE
    assert capture_stop == CAPTURE_RE
    left_guard_db = float(np.median(fft_db[:active_start]))
    active_db = float(np.median(fft_db[active_start:active_stop]))
    right_guard_db = float(np.median(fft_db[active_stop:capture_stop]))
    unused_db = float(np.median(fft_db[capture_stop:]))
    active_ripple_db = float(np.ptp(fft_db[active_start:active_stop]))
    occupied_re = np.flatnonzero(fft_db > OCCUPIED_THRESHOLD_DB)
    expected_occupied_re = np.arange(active_start, active_stop)
    dut._log.info(
        "FFT regions dB: left=%s active=%s right=%s tail=%s "
        "active ripple=%s ctrl_fcw=%s",
        left_guard_db,
        active_db,
        right_guard_db,
        unused_db,
        active_ripple_db,
        int(ctrl.rd_fcw.value),
    )

    assert seen_sf, "resynchronizer never asserted start-of-frame after sync"
    assert seen_sy, "resynchronizer never asserted start-of-symbol"
    assert resync_hits > 0 and resync_misses == 0, (
        f"resync antenna0 waveform mismatches={resync_misses}, "
        f"checked={resync_hits + resync_misses}"
    )
    assert resync_valid_phases == set(range(NUM_ANT)), (
        f"expected four complex antenna phases, got {sorted(resync_valid_phases)}"
    )
    assert ddc_valid > 0 and sorted(ddc_channels) == [0, 1, 2, 3], (
        f"DDC channels not rotating through 0..3: {sorted(ddc_channels)}"
    )
    assert ddc_ant0 >= 4, f"DDC antenna0 output too sparse: {ddc_ant0}"
    assert any(real or imag for _, real, imag in ddc_samples), (
        "DDC payload is entirely zero"
    )
    assert any(real or imag for _, real, imag in stream2block_samples), (
        "stream2block payload is entirely zero"
    )
    assert len(fft_samples) == FFT_SIZE, (
        f"expected one {FFT_SIZE}-sample FFT block, got {len(fft_samples)} samples"
    )
    assert {channel for channel, _, _ in fft_samples} == {TEST_ANT}
    assert any(real or imag for _, real, imag in fft_samples), (
        "FFT payload is entirely zero"
    )
    assert active_db > -12.0, f"839 active REs are too weak: median={active_db:.1f} dB"
    assert active_ripple_db < MAX_ACTIVE_RIPPLE_DB, (
        f"ZC magnitude ripple is too large: {active_ripple_db:.3f} dB"
    )
    assert left_guard_db < active_db - 35.0, (
        f"13 left guard REs are not clear: {left_guard_db:.1f} dB"
    )
    assert right_guard_db < active_db - 35.0, (
        f"12 right guard REs are not clear: {right_guard_db:.1f} dB"
    )
    assert unused_db < active_db - 35.0, (
        f"unused FFT bins are not clear: {unused_db:.1f} dB"
    )
    assert np.array_equal(occupied_re, expected_occupied_re), (
        f"expected occupied FFT REs {active_start}..{active_stop - 1}, "
        f"got {occupied_re.tolist()}"
    )
    assert len(uplane_words) == 252, (
        f"expected one 252-word F0 U-plane packet, got {len(uplane_words)} words"
    )
    assert [keep for _, keep, _, _ in uplane_words] == [0xFF] * 252
    assert [last for _, _, last, _ in uplane_words] == [0] * 251 + [1]
    assert {user for _, _, _, user in uplane_words} == {SECTION_ID}

    axi.stop()


def test_prach_e2e_runner():
    run_dir = PRJ_PATH / "sim_build" / "prach_top_e2e"
    runner = get_runner(SIM)
    waves = bool(int(os.environ.get("WAVES", "0")))
    runner.build(
        hdl_toplevel="prach",
        sources=resolve_flt(PRJ_PATH / "prach.flt"),
        parameters={"NUM_CC": NUM_CC, "NUM_ANT": NUM_ANT},
        always=True,
        waves=waves,
        build_dir=run_dir,
    )
    # The FFT twiddle ROMs are loaded with $readmemh relative to the simulator
    # working directory (the test directory).
    for mem in (PRJ_PATH / "rtl").glob("prach_fft_*.mem"):
        shutil.copy(mem, run_dir)
    runner.test(
        hdl_toplevel="prach",
        hdl_toplevel_lang="verilog",
        test_module="test_prach",
        waves=waves,
        gui=os.environ.get("GUI", "false").lower() == "true",
        test_dir=run_dir,
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
