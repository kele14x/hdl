import os
from cocotb_test.simulator import run

tests_dir = os.path.dirname(__file__)


def test_fifo_srl():
    run(
        toplevel_lang="verilog",
        verilog_sources=[
            os.path.join(tests_dir, "../rtl/fifo_srl.sv"),
            os.path.join(tests_dir, "../../util/srl.sv")
        ],
        toplevel="fifo_srl",
        module="fifo_srl_cocotb"
    )
