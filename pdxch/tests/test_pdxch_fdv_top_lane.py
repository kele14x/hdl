#!/usr/bin/env python3
"""Four-antenna lane check through gearbox, FDV RAM and FDV readout."""

from __future__ import annotations

import cocotb
import numpy as np
import pytest
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Combine, RisingEdge, Timer, with_timeout
from pdxch_reference import (
    best_body_alignment,
    fdv_readout_stream,
    pdxch_nr100m_reference,
    qpsk_bfp9_resource_elements,
)
from pdxch_test_utils import pdxch_sources, run_test

from hdl_tools.axis import AxisAgentConfig, AxisBeat, AxisFrame, AxisSourceDriver

NUM_ANT = 4


class _IndexedAxisView:
    def __init__(self, dut, antenna: int):
        self._dut = dut
        self._antenna = antenna

    def __getattr__(self, name):
        signal = getattr(self._dut, name)
        if name.startswith("s_defm_data_"):
            return signal[self._antenna]
        return signal


def _full_band_frame(antenna: int) -> AxisFrame:
    resource_elements = qpsk_bfp9_resource_elements(
        num_prb=273, cc=0, antenna=antenna, symbol=0
    )
    mantissas = (
        np.column_stack((resource_elements.real, resource_elements.imag)).astype(
            np.int16
        )
        // 128
    )
    bits = "".join(
        "00001111"
        + "".join(
            f"{int(real) & 0x1FF:09b}{int(imag) & 0x1FF:09b}"
            for real, imag in mantissas[prb * 12 : (prb + 1) * 12]
        )
        for prb in range(273)
    )
    payload = [int(bits[index : index + 8], 2) for index in range(0, len(bits), 8)]
    beats = []
    for offset in range(0, len(payload), 8):
        chunk = payload[offset : offset + 8]
        beats.append(
            AxisBeat(
                data=sum(byte << (8 * lane) for lane, byte in enumerate(chunk)),
                keep=(1 << len(chunk)) - 1,
                user=0,
                dest=0,
                last=offset + len(chunk) == len(payload),
            )
        )
    return AxisFrame(beats)


@cocotb.test()
async def test_gearbox_fdv_ram_readout_keeps_antenna_identity(dut):
    cocotb.start_soon(Clock(dut.ctrl_clk, 10, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_eth_xran, 2, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk, 2, unit="ns").start())

    dut.rst.value = 1
    dut.rst_eth_xran.value = 1
    dut.ctrl_rst.value = 1
    dut.sync_in.value = 0
    dut.ctrl_ud_comp_meth.value = 1
    dut.ctrl_ud_iq_width.value = 9
    dut.ctrl_fs_offset.value = 0
    dut.ctrl_phase_comp_addr.value = 0
    dut.ctrl_phase_comp_we.value = 0
    dut.ctrl_phase_comp_din.value = 0x4000
    for cc in range(3):
        dut.s_dl_sym_num[cc].value = 0
        dut.ctrl_en[cc].value = 0xF if cc == 0 else 0
        dut.ctrl_rat[cc].value = 2
        dut.ctrl_bist[cc].value = 0
        dut.ctrl_bw[cc].value = 4
        dut.ctrl_nprb[cc].value = 273
        dut.ctrl_rfs_offset[cc].value = 0
        for antenna in range(NUM_ANT):
            dut.ctrl_gain[cc][antenna].value = 0x4000
            dut.m_axis_tready[cc][antenna].value = 1

    sources = []
    for antenna in range(NUM_ANT):
        source = AxisSourceDriver(
            _IndexedAxisView(dut, antenna),
            AxisAgentConfig(
                prefix="s_defm_data",
                clock="clk_eth_xran",
                reset="rst_eth_xran",
                reset_active_level=1,
            ),
        )
        source.idle()
        sources.append(source)

    await ClockCycles(dut.clk_eth_xran, 8)
    dut.rst.value = 0
    dut.rst_eth_xran.value = 0
    dut.ctrl_rst.value = 0
    await ClockCycles(dut.clk_eth_xran, 8)

    for address in range(16):
        await RisingEdge(dut.ctrl_clk)
        dut.ctrl_phase_comp_addr.value = address
        dut.ctrl_phase_comp_we.value = 1
    await RisingEdge(dut.ctrl_clk)
    dut.ctrl_phase_comp_we.value = 0

    sends = [
        cocotb.start_soon(source.send(_full_band_frame(antenna), gap=1))
        for antenna, source in enumerate(sources)
    ]
    await Combine(*sends)

    async def capture_common_radio_phase():
        # All four outputs are parallel samples held for NUM_ANT clocks.  Use
        # one common phase; independently finding the first nonzero value on
        # each lane can associate the interleaved block with the wrong lane.
        for _ in range(100000):
            await RisingEdge(dut.clk)
            await Timer(1, unit="ps")
            values = []
            for antenna in range(NUM_ANT):
                value = dut.m_axis_tdata[0][antenna].value
                values.append(int(value) if value.is_resolvable else 0)
            tuser = dut.m_axis_tuser[0][0].value
            marker = int(tuser) & 1 if tuser.is_resolvable else 0
            if marker or any(values):
                samples = [[value] for value in values]
                break
        else:
            raise AssertionError("radio output did not start")

        for _ in range(4095):
            await ClockCycles(dut.clk, NUM_ANT)
            await Timer(1, unit="ps")
            for antenna in range(NUM_ANT):
                value = dut.m_axis_tdata[0][antenna].value
                samples[antenna].append(int(value) if value.is_resolvable else 0)
        return samples

    async def capture_channel_stream(prefix):
        channel_dut = dut.g_cc[0].u_channel
        samples = [[] for _ in range(NUM_ANT)]
        for _ in range(100000):
            await RisingEdge(dut.clk)
            await Timer(1, unit="ps")
            if int(getattr(channel_dut, f"{prefix}_dout_dv").value):
                channel = int(getattr(channel_dut, f"{prefix}_dout_chn").value)
                samples[channel].append(
                    complex(
                        getattr(channel_dut, f"{prefix}_dout_dr").value.to_signed(),
                        getattr(channel_dut, f"{prefix}_dout_di").value.to_signed(),
                    )
                )
                if all(len(stream) == 4096 for stream in samples):
                    return samples
        raise AssertionError(
            f"{prefix} output was incomplete: {[len(stream) for stream in samples]}"
        )

    radio_capture = cocotb.start_soon(capture_common_radio_phase())
    stage_captures = {
        prefix: cocotb.start_soon(capture_channel_stream(prefix))
        for prefix in ("gain", "pre_conv", "fft", "phase_comp")
    }

    await RisingEdge(dut.clk_eth_xran)
    dut.sync_in.value = 1
    await RisingEdge(dut.clk_eth_xran)
    dut.sync_in.value = 0

    expected = [
        fdv_readout_stream(
            qpsk_bfp9_resource_elements(num_prb=273, cc=0, antenna=antenna, symbol=0)
        )
        for antenna in range(NUM_ANT)
    ]
    checked = [0] * NUM_ANT
    for _ in range(50000):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ps")
        if int(dut.fdv_dout_dv[0].value):
            channel = int(dut.fdv_dout_chn[0].value)
            actual = (
                dut.fdv_dout_dr[0].value.to_signed(),
                dut.fdv_dout_di[0].value.to_signed(),
            )
            index = checked[channel]
            reference = expected[channel][index]
            expected_sample = (int(reference.real), int(reference.imag))
            assert actual == expected_sample, (
                f"FDV channel {channel} sample {index} carried {actual}, "
                f"expected antenna {channel} data {expected_sample}"
            )
            checked[channel] += 1
            if checked == [4096] * NUM_ANT:
                break

    assert checked == [4096] * NUM_ANT

    references = [
        pdxch_nr100m_reference(cc=0, antenna=antenna, symbol=0)
        for antenna in range(NUM_ANT)
    ]
    reference_field = {
        "gain": "fdv_stream",
        "pre_conv": "converter_stream",
        "fft": "fixed_time_domain",
        "phase_comp": "fixed_time_domain",
    }
    for prefix, capture in stage_captures.items():
        stage_samples = await with_timeout(capture, 200, timeout_unit="us")
        for antenna in range(NUM_ANT):
            candidates = []
            for reference_antenna in range(NUM_ANT):
                reference = getattr(
                    references[reference_antenna], reference_field[prefix]
                )
                offset, error = best_body_alignment(
                    stage_samples[antenna], reference, max_offset=8
                )
                rms = float(np.sqrt(np.mean(np.abs(error) ** 2)))
                candidates.append((rms, reference_antenna, offset))
            best_rms, best_antenna, best_offset = min(candidates)
            assert best_antenna == antenna and best_rms < 1.0, (
                f"{prefix} channel {antenna} best matches antenna {best_antenna} "
                f"at offset {best_offset}, RMS error {best_rms:.3f}"
            )

    captured_words = await with_timeout(radio_capture, 200, timeout_unit="us")
    for antenna in range(NUM_ANT):
        actual = np.asarray(
            [
                complex(
                    (word & 0xFFFF) - (0x10000 if word & 0x8000 else 0),
                    ((word >> 16) & 0xFFFF) - (0x10000 if word & 0x80000000 else 0),
                )
                for word in captured_words[antenna]
            ]
        )
        candidates = []
        for reference_antenna in range(NUM_ANT):
            reference = pdxch_nr100m_reference(
                cc=0, antenna=reference_antenna, symbol=0
            ).fixed_time_domain
            offset, error = best_body_alignment(actual, reference, max_offset=8)
            rms = float(np.sqrt(np.mean(np.abs(error) ** 2)))
            candidates.append((rms, reference_antenna, offset))
        best_rms, best_antenna, best_offset = min(candidates)
        assert best_antenna == antenna and best_rms < 1.0, (
            f"radio antenna {antenna} best matches antenna {best_antenna} "
            f"at offset {best_offset}, RMS error {best_rms:.3f}"
        )


def test_pdxch_fdv_top_lane_runner():
    run_test(
        hdl_toplevel="pdxch_top",
        test_module="test_pdxch_fdv_top_lane",
        sources=pdxch_sources("pdxch.flt"),
        parameters={"NUM_CC": 3, "NUM_ANT": NUM_ANT, "HALF_BLOCK": 0},
        build_name="fdv_top_lane",
    )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
