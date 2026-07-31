"""Low-PHY register offsets and reset values from ``rdl/lowphy.rdl``."""

VERSION = 0x000
SCRATCH0 = 0x004
SCRATCH1 = 0x008

DL_EN = 0x010
DL_RAT = 0x014
DL_BIST = 0x018
DL_BW = 0x01C
DL_NPRB = tuple(0x020 + 4 * index for index in range(3))
DL_RFS_OFFSET = tuple(0x030 + 4 * index for index in range(3))
DL_UD = 0x058
DL_GAIN = tuple(0x100 + 4 * index for index in range(12))

UL_EN = 0x210
UL_RAT = 0x214
UL_BIST = 0x218
UL_BW = 0x21C
UL_NPRB = tuple(0x220 + 4 * index for index in range(3))
UL_RFS_OFFSET = tuple(0x230 + 4 * index for index in range(3))
UL_UD = 0x258
UL_GAIN = tuple(0x300 + 4 * index for index in range(12))

PRACH_EN = 0x410
PRACH_FORMAT = 0x414
PRACH_RAT = 0x418
PRACH_BIST = 0x41C
PRACH_BW = 0x420
PRACH_RFS_OFFSET = tuple(0x430 + 4 * index for index in range(3))
PRACH_TA3_OFFSET = tuple(0x440 + 4 * index for index in range(3))
PRACH_UD = 0x458
PRACH_CFG0 = tuple(0x460 + 4 * index for index in range(3))
PRACH_CFG1 = tuple(0x470 + 4 * index for index in range(3))
PRACH_CFG2 = tuple(0x480 + 4 * index for index in range(3))
PRACH_CFG3 = tuple(0x490 + 4 * index for index in range(3))
PRACH_MSG0 = tuple(0x500 + 4 * index for index in range(3))
PRACH_MSG1 = tuple(0x510 + 4 * index for index in range(3))
PRACH_MSG2 = tuple(0x520 + 4 * index for index in range(3))

DL_PHASE_COMP = 0x800
UL_PHASE_COMP = 0xA00

RESET_VALUES = {
    VERSION: 0x20250106,
    SCRATCH0: 0,
    SCRATCH1: 0,
    DL_EN: 0,
    DL_RAT: 0,
    DL_BIST: 0,
    DL_BW: 0x222,
    DL_UD: 0x091,
    UL_EN: 0,
    UL_RAT: 0,
    UL_BIST: 0,
    UL_BW: 0x222,
    UL_UD: 0x091,
    PRACH_EN: 0,
    PRACH_FORMAT: 0,
    PRACH_RAT: 0,
    PRACH_BIST: 0,
    PRACH_BW: 0x222,
    PRACH_UD: 0x091,
}

for address in DL_NPRB + UL_NPRB:
    RESET_VALUES[address] = 100
for address in DL_RFS_OFFSET + UL_RFS_OFFSET + PRACH_RFS_OFFSET + PRACH_TA3_OFFSET:
    RESET_VALUES[address] = 0
for address in DL_GAIN + UL_GAIN:
    RESET_VALUES[address] = 0x4000
for address in PRACH_CFG0 + PRACH_CFG1 + PRACH_CFG2 + PRACH_CFG3:
    RESET_VALUES[address] = 0
