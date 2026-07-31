"""Register model for the lowphy SystemRDL address map."""

import register_map as reg

from common.tb.registers import (
    AxiLiteRegisterAdapter,
    FieldSpec,
    RegisterAccess,
    RegisterBlock,
    RegisterPredictor,
    RegisterSpec,
)


def _field(name, lsb, width, reset=0, access=RegisterAccess.RW, volatile=False):
    return FieldSpec(name, lsb, width, reset, access, volatile)


def _register(name, address, *fields):
    return RegisterSpec(name, address, tuple(fields))


def _cc_fields(width, reset=0, access=RegisterAccess.RW):
    return tuple(
        _field(f"cc{index}", 4 * index, width, reset, access) for index in range(3)
    )


def lowphy_register_specs():
    specs = [
        _register(
            "version",
            reg.VERSION,
            _field("val", 0, 32, 0x20250106, RegisterAccess.RO),
        ),
        _register("scratch0", reg.SCRATCH0, _field("val", 0, 32)),
        _register("scratch1", reg.SCRATCH1, _field("val", 0, 32)),
        _register("dl_en", reg.DL_EN, *_cc_fields(4)),
        _register("dl_rat", reg.DL_RAT, *_cc_fields(2)),
        _register("dl_bist", reg.DL_BIST, *_cc_fields(4)),
        _register("dl_bw", reg.DL_BW, *_cc_fields(4, reset=2)),
        _register(
            "dl_ud",
            reg.DL_UD,
            _field("comp_meth", 0, 4, 1),
            _field("iq_width", 4, 4, 9),
            _field("fs_offset", 8, 4),
        ),
        _register("ul_en", reg.UL_EN, *_cc_fields(4)),
        _register("ul_rat", reg.UL_RAT, *_cc_fields(2)),
        _register("ul_bist", reg.UL_BIST, *_cc_fields(4)),
        _register("ul_bw", reg.UL_BW, *_cc_fields(4, reset=2)),
        _register(
            "ul_ud",
            reg.UL_UD,
            _field("comp_meth", 0, 4, 1),
            _field("iq_width", 4, 4, 9),
            _field("fs_offset", 8, 4),
        ),
        _register("prach_en", reg.PRACH_EN, *_cc_fields(4)),
        _register("prach_format", reg.PRACH_FORMAT, *_cc_fields(4)),
        _register("prach_rat", reg.PRACH_RAT, *_cc_fields(2)),
        _register(
            "prach_bist",
            reg.PRACH_BIST,
            *_cc_fields(4),
            _field("static_c_cc0", 16, 4),
            _field("static_c_cc1", 20, 4),
            _field("static_c_cc2", 24, 4),
        ),
        _register("prach_bw", reg.PRACH_BW, *_cc_fields(4, reset=2)),
        _register(
            "prach_ud",
            reg.PRACH_UD,
            _field("comp_meth", 0, 4, 1),
            _field("iq_width", 4, 4, 9),
            _field("fs_offset", 8, 4),
        ),
    ]

    for prefix, addresses, width, reset in (
        ("dl_nprb", reg.DL_NPRB, 9, 100),
        ("dl_rfs_offset", reg.DL_RFS_OFFSET, 23, 0),
        ("dl_gain", reg.DL_GAIN, 17, 0x4000),
        ("ul_nprb", reg.UL_NPRB, 9, 100),
        ("ul_rfs_offset", reg.UL_RFS_OFFSET, 23, 0),
        ("ul_gain", reg.UL_GAIN, 17, 0x4000),
        ("prach_rfs_offset", reg.PRACH_RFS_OFFSET, 23, 0),
        ("prach_ta3_offset", reg.PRACH_TA3_OFFSET, 23, 0),
        ("prach_cfg3", reg.PRACH_CFG3, 16, 0),
    ):
        specs.extend(
            _register(f"{prefix}_{index}", address, _field("val", 0, width, reset))
            for index, address in enumerate(addresses)
        )

    for index, address in enumerate(reg.PRACH_CFG0):
        specs.append(
            _register(
                f"prach_cfg0_{index}",
                address,
                _field("symbol_id", 0, 6),
                _field("slot_id", 8, 6),
                _field("subframe_id", 16, 4),
                _field("subframe_inc", 20, 4),
            )
        )
    for index, address in enumerate(reg.PRACH_CFG1):
        specs.append(
            _register(
                f"prach_cfg1_{index}",
                address,
                _field("time_offset", 0, 16),
                _field("cp_length", 16, 16),
            )
        )
    for index, address in enumerate(reg.PRACH_CFG2):
        specs.append(
            _register(
                f"prach_cfg2_{index}",
                address,
                _field("num_symbol", 0, 4),
                _field("freq_offset", 4, 24),
            )
        )

    for index, address in enumerate(reg.PRACH_MSG0):
        specs.append(
            _register(
                f"prach_msg0_{index}",
                address,
                _field("symbol_id", 0, 6, access=RegisterAccess.RO, volatile=True),
                _field("slot_id", 8, 6, access=RegisterAccess.RO, volatile=True),
                _field("subframe_id", 16, 4, access=RegisterAccess.RO, volatile=True),
            )
        )
    for index, address in enumerate(reg.PRACH_MSG1):
        specs.append(
            _register(
                f"prach_msg1_{index}",
                address,
                _field("time_offset", 0, 16, access=RegisterAccess.RO, volatile=True),
                _field("cp_length", 16, 16, access=RegisterAccess.RO, volatile=True),
            )
        )
    for index, address in enumerate(reg.PRACH_MSG2):
        specs.append(
            _register(
                f"prach_msg2_{index}",
                address,
                _field("num_symbol", 0, 4, access=RegisterAccess.RO, volatile=True),
                _field("freq_offset", 4, 24, access=RegisterAccess.RO, volatile=True),
            )
        )

    return tuple(sorted(specs, key=lambda spec: spec.address))


def create_lowphy_ral(axi_agent=None):
    """Create the lowphy model and optionally bind it to an AXI-Lite agent."""
    block = RegisterBlock("lowphy", lowphy_register_specs())
    if axi_agent is not None:
        block.bind(AxiLiteRegisterAdapter(axi_agent))
        block.predictor = RegisterPredictor(
            block,
            axi_agent.monitor.transactions,
        )
    return block
