from pathlib import Path

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import ClockCycles, RisingEdge, Timer

prj_path = Path(__file__).resolve().parent.parent


async def reset(dut):
    dut.rst_dsp_n.value = 0

    dut.din_dr_cc0.value = 0
    dut.din_dr_cc1.value = 0
    dut.din_dr_cc2.value = 0
    dut.din_di_cc0.value = 0
    dut.din_di_cc1.value = 0
    dut.din_di_cc2.value = 0
    dut.din_chn.value = 0
    dut.sync_in.value = 0

    dut.rst_eth_xran_n.value = 0

    dut.avst_sink_c_valid.value = 0
    dut.avst_sink_c_startofpacket.value = 0
    dut.avst_sink_c_endofpacket.value = 0
    dut.avst_sink_c_error.value = 0

    dut.rx_c_rtc_id.value = 0
    dut.rx_c_seq_id.value = 0
    #
    dut.rx_c_dataDirection.value = 0
    dut.rx_c_payloadVersion.value = 0
    dut.rx_c_filterIndex.value = 0
    dut.rx_c_frameId.value = 0
    dut.rx_c_subframeId.value = 0
    dut.rx_c_slotId.value = 0
    dut.rx_c_symbolId.value = 0
    dut.rx_c_sectionType.value = 0
    #
    dut.rx_c_timeOffset.value = 0
    dut.rx_c_frameStructure.value = 0
    dut.rx_c_cpLength.value = 0
    dut.rx_c_udCompHdr.value = 0
    #
    dut.rx_c_sectionId.value = 0
    dut.rx_c_rb.value = 0
    dut.rx_c_symInc.value = 0
    dut.rx_c_startPrbc.value = 0
    dut.rx_c_numPrbc.value = 0
    dut.rx_c_reMask.value = 0
    dut.rx_c_numSymbol.value = 0
    dut.rx_c_ef.value = 0
    dut.rx_c_beamid.value = 0
    dut.rx_c_freqOffset.value = 0

    dut.avst_source_u_ready.value = 0

    await ClockCycles(dut.clk_eth_xran, 16)
    dut.rst_eth_xran_n.value = 1

    await RisingEdge(dut.clk_dsp)
    dut.rst_dsp_n.value = 1

    await Timer(100, units="ns")


async def send_c_msg(
    dut,
    /,
    rtc_id=0,
    frameId=0,
    subframeId=0,
    slotId=0,
    symbolId=0,
    timeOffset=0,
    cpLength=0,
    freqOffset=0,
):
    dut.avst_sink_c_valid.value = 1
    dut.avst_sink_c_startofpacket.value = 1
    dut.avst_sink_c_endofpacket.value = 1
    dut.avst_sink_c_error.value = 0

    dut.rx_c_rtc_id.value = rtc_id
    dut.rx_c_seq_id.value = 0
    #
    dut.rx_c_dataDirection.value = 0  # 0 for UL
    dut.rx_c_payloadVersion.value = 1
    dut.rx_c_filterIndex.value = 1  # F0
    dut.rx_c_frameId.value = frameId
    dut.rx_c_subframeId.value = subframeId
    dut.rx_c_slotId.value = slotId
    dut.rx_c_symbolId.value = symbolId
    dut.rx_c_sectionType.value = 3
    #
    dut.rx_c_timeOffset.value = timeOffset
    dut.rx_c_frameStructure.value = 220  # 1101,1100
    dut.rx_c_cpLength.value = cpLength
    dut.rx_c_udCompHdr.value = 0
    #
    dut.rx_c_sectionId.value = 0
    dut.rx_c_rb.value = 0
    dut.rx_c_symInc.value = 0
    dut.rx_c_startPrbc.value = 0
    dut.rx_c_numPrbc.value = 72
    dut.rx_c_reMask.value = 4095
    dut.rx_c_numSymbol.value = 1
    dut.rx_c_ef.value = 0
    dut.rx_c_beamid.value = 0
    dut.rx_c_freqOffset.value = freqOffset

    await RisingEdge(dut.clk_eth_xran)

    dut.avst_sink_c_valid.value = 0
    dut.avst_sink_c_startofpacket.value = 0
    dut.avst_sink_c_endofpacket.value = 0
    dut.avst_sink_c_error.value = 0

    dut.rx_c_rtc_id.value = 0
    dut.rx_c_seq_id.value = 0
    #
    dut.rx_c_dataDirection.value = 0
    dut.rx_c_payloadVersion.value = 0
    dut.rx_c_filterIndex.value = 0
    dut.rx_c_frameId.value = 0
    dut.rx_c_subframeId.value = 0
    dut.rx_c_slotId.value = 0
    dut.rx_c_symbolId.value = 0
    dut.rx_c_sectionType.value = 0
    #
    dut.rx_c_timeOffset.value = 0
    dut.rx_c_frameStructure.value = 0
    dut.rx_c_cpLength.value = 0
    dut.rx_c_udCompHdr.value = 0
    #
    dut.rx_c_sectionId.value = 0
    dut.rx_c_rb.value = 0
    dut.rx_c_symInc.value = 0
    dut.rx_c_startPrbc.value = 0
    dut.rx_c_numPrbc.value = 0
    dut.rx_c_reMask.value = 0
    dut.rx_c_numSymbol.value = 0
    dut.rx_c_ef.value = 0
    dut.rx_c_beamid.value = 0
    dut.rx_c_freqOffset.value = 0


async def drive(dut, xs, chn):
    clkedge = RisingEdge(dut.clk_dsp)

    for i, x in enumerate(xs):
        for j in range(8):
            # CC0
            dut.din_dr_cc0.value = int(np.real(x)) if j == chn else 0
            dut.din_di_cc0.value = int(np.imag(x)) if j == chn else 0
            # CC1
            dut.din_dr_cc1.value = int(np.real(x)) if j + 8 == chn else 0
            dut.din_di_cc1.value = int(np.imag(x)) if j + 8 == chn else 0
            # CC2
            dut.din_dr_cc2.value = int(np.real(x)) if j + 16 == chn else 0
            dut.din_di_cc2.value = int(np.imag(x)) if j + 16 == chn else 0
            #
            dut.din_chn.value = j
            dut.sync_in.value = 1 if i == 0 and j == 0 else 0
            await clkedge


@cocotb.test()
async def test_prach_top(dut):
    await reset(dut)
    await Timer(100, units="ns")

    # Send C-Plane message
    await RisingEdge(dut.clk_eth_xran)
    await send_c_msg(dut, rtc_id=0, cpLength=3168, freqOffset=-14400)

    # Test input
    await Timer(100, units="ns")
    await RisingEdge(dut.clk_dsp)
    x = np.loadtxt(prj_path / "matlab/test/prach_top_in.txt", delimiter=",")
    x = x[:, 0] + 1j * x[:, 1]
    cocotb.start_soon(drive(dut, x, 0))

    # finish
    await Timer(1100 * 1000, units="ns")


def test_prach_top_runner():
    sim = "questa"

    hdl_toplevel = "tb_prach_top"
    hdl_toplevel_lang = "verilog"

    verilog_sources = [
        prj_path / "src/cmult.sv",
        prj_path / "src/delay.sv",
        prj_path / "src/prach_buffer.sv",
        prj_path / "src/prach_buffer_ch.sv",
        prj_path / "src/prach_buffer_cp_fifo.sv",
        prj_path / "src/prach_buffer_readout.sv",
        prj_path / "src/prach_c_plane.sv",
        prj_path / "src/prach_conv.sv",
        prj_path / "src/prach_conv_nco.sv",
        prj_path / "src/prach_ddc.sv",
        prj_path / "src/prach_ditfft2.sv",
        prj_path / "src/prach_ditfft2_bf.sv",
        prj_path / "src/prach_ditfft2_twiddler.sv",
        prj_path / "src/prach_ditfft3.sv",
        prj_path / "src/prach_ditfft3_bf1.sv",
        prj_path / "src/prach_ditfft3_bf2.sv",
        prj_path / "src/prach_ditfft3_bf3.sv",
        prj_path / "src/prach_fft.sv",
        prj_path / "src/prach_framer.sv",
        prj_path / "src/prach_framer_buffer.sv",
        prj_path / "src/prach_framer_cdc.sv",
        prj_path / "src/prach_hb1.sv",
        prj_path / "src/prach_hb1_ch.sv",
        prj_path / "src/prach_hb2.sv",
        prj_path / "src/prach_hb2_ch.sv",
        prj_path / "src/prach_hb3.sv",
        prj_path / "src/prach_hb4.sv",
        prj_path / "src/prach_hb5.sv",
        prj_path / "src/prach_mixer.sv",
        prj_path / "src/prach_mixer_ch.sv",
        prj_path / "src/prach_nco.sv",
        prj_path / "src/prach_reshape1.sv",
        prj_path / "src/prach_reshape2.sv",
        prj_path / "src/prach_reshape_ch.sv",
        prj_path / "src/prach_resync.sv",
        prj_path / "src/prach_top.sv",
        prj_path / "tb/tb_prach_top.sv",
    ]

    test_args = ["-L", "altera_mf_ver"]

    runner = get_runner(sim)
    runner.build(
        hdl_toplevel=hdl_toplevel,
        verilog_sources=verilog_sources,
        always=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_args=test_args,
        test_module="test_prach_top",
        waves=True,
        gui=True,
    )


if __name__ == "__main__":
    test_prach_top_runner()
