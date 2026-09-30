# Known issues

## Design

### PDXCH

- Date: 2026-09-08
- Source commit: `786f998`

#### ISSUE-01 · P1：停用或复位后可能持续输出非零旧样本

**位置**：[pdxch_block2stream.sv](../pdxch/rtl/pdxch_block2stream.sv)，基线第 177–183、213 行；[pdxch_fdv_buffer_readout.sv](../pdxch/rtl/pdxch_fdv_buffer_readout.sv)，第 439–443 行。

`dout[i]` 仅在输入有效或 RAM 回放有效时更新，没有复位清零路径；`m_axis_tvalid[i]` 恒为 1。`ctrl_en` 关闭后，readout 停止产生该天线的有效数据，但输出级没有对应的停用清零控制。

当有效输入及 RAM 回放结束，输出寄存器保持最后一个样本。若该样本非零，下游仍会将其作为有效数据持续接收。复位也没有直接清除这个输出寄存器；读回放状态同样缺少完整复位处理。

**建议**：为输出和回放控制建立明确的复位、停用处理；自由运行输出模式下，停用后输出零值。不要简单在每个 `din_dv=0` 的周期清零，因为正常采样间隔需要保持样本，且 CP 回放也使用无有效输入的时段。

**待补验证**：

- 先输出非零数据，再关闭单根天线或整个 CC，检查流水排空后的输出。
- 在正常输出和 RAM 回放期间分别执行 radio-only reset，检查复位后的数据和标记。
- 验证清零控制不破坏正常样本保持、CP 回放以及重新使能后的首符号。

#### ISSUE-02 · P2：HALF_BLOCK 地址回绕可绕过越界检查

**位置**：[pdxch_fdv_buffer_write.sv](../pdxch/rtl/pdxch_fdv_buffer_write.sv)，基线第 72–84 行。

起始地址先以有限位宽计算，再进行 bank 上界检查。半容量模式下，中间状态的 IQ 地址宽度为 12 位，exponent 地址宽度为 11 位，无法覆盖全部 10 位 `startPrb` 输入对应的计算结果。

例如 `HALF_BLOCK=1`、`bank=1`、`startPrb=512` 且 CC 匹配时：

| 地址 | 未截断结果 | 截断结果 |
| --- | ---: | ---: |
| IQ | `1024 + 512 × 6 = 4096` | 12 位截断为 0 |
| Exponent | `512 + 512 × 3 = 2048` | 11 位截断为 0 |

截断后的两个地址均通过上界检查，异常包可以写入 bank 0，而不是被拒绝。此问题属于非法 PRB 输入的边界保护缺陷，不表示正常合法 PRB 会发生该回绕。

**建议**：先检查原始 PRB 范围，或用足够宽的中间地址完成计算和边界判断，再缩窄到 RAM 端口位宽；保持包内地址越界后的写入抑制。

**待补验证**：将半容量模式的 `startPrb=512`、高端地址、两种 bank、合法边界和跨边界长包加入确定性回归，并覆盖 full-block 模式。

#### ISSUE-03 · P2，条件性风险：符号号没有与 gearbox 数据一起保存

**位置**：[pdxch_top.sv](../pdxch/rtl/pdxch_top.sv)，基线第 105–116、136–142 行；[pdxch_fdv_buffer_write.sv](../pdxch/rtl/pdxch_fdv_buffer_write.sv)，第 66–77 行。

输入数据经过 `pdxch_bfp_gearbox` 缓冲后才进入 writer，而实时 `s_dl_sym_num` 直接连接到 FDV buffer。writer 在压缩输出首拍时选择并锁存 bank。

如果符号号在输入包结束后、压缩输出首拍被 writer 采样前变化，旧包会按新符号号选择 bank。已有包内 bank 锁存只保护 writer 首拍之后的变化，无法保护此前的 gearbox 缓冲窗口。

**待确认的接口约束**：上游是否保证 `s_dl_sym_num` 至少稳定到 writer 接收压缩输出首拍。若有可靠保证，此场景可能不会在系统中触发，应将保证写入接口约定；否则需要修改设计。

**建议**：在输入包首拍握手时保存对应 CC 的符号信息，与包元数据一同经过 gearbox，再提供给 writer。多天线和多 CC 场景必须保存各自正确的关联信息。

**待补验证**：使用短包，在输入 TLAST 握手后立即切换符号号，并覆盖输入停顿、连续包、多 CC 和多天线。

## Tests

### Regression runner and cocotb coverage gaps

Reviewed against the working tree on 2026-09-30. Direct-target counts below
mean distinct RTL modules selectable as a cocotb runner's top, excluding
packages. A static instantiation path from a tested top identifies a possible
parent test; it does not establish functional coverage.

- **P0 — Root regression can report success without running tests on Bash 3.2**

  [scripts/run_targets.sh](../scripts/run_targets.sh) uses `mapfile`, which the
  current macOS Bash 3.2 does not provide. `make test MODULES="ptp oran_slave fh
  pps_top common" SIMULATORS=verilator` prints `mapfile: command not found` and
  `list: unbound variable`, then reports “all passed” with exit 0 without
  running module or helper tests. The same runner serves the other root stages.
  Use a compatible module-list implementation or enforce a supported shell, and
  make runner setup failures return nonzero.
  [tests/test_regression_runner.py](../tests/test_regression_runner.py) exposes
  the skipped discovery and execution.

- **P1 — O-RAN datapath remains unchecked: 1/35 direct targets**

  [test_oran_top_smoke.py](../oran_slave/tests/test_oran_top_smoke.py) targets
  `oran_top` and checks registers, reset recovery, and idle TX. All 35 RTL
  modules now have a static path from that top, but the test sends no DL/UL
  traffic. Add checked Ethernet parsing/framing, compression/decompression,
  section routing, and a completed DL and UL transaction.

- **P1 — PTP receive and timestamp-exchange coverage remains incomplete: 1/7 direct targets**

  [test_ptp_lite.py](../ptp/tests/test_ptp_lite.py) checks a complete expected
  Sync frame, timestamp-request metadata, output backpressure, and reset
  recovery through `ptp_lite`, its controller, and framer. RX traffic and
  returned TX timestamps remain inactive. Add checked receive parsing and
  supported timestamp/message exchanges. The legacy `ptp.sv`, `ptp_regs.v`, and
  `ptp_wrapper.v` remain absent from all resolved block filelists; declare their
  support status and add tests if retained.

- **P1 — FH datapath remains unchecked: 2/12 direct targets**

  [test_fh_smoke.py](../fh/tests/test_fh_smoke.py) checks full-top registers,
  idle TX, and reset recovery;
  [test_fh_framer_padding.py](../fh/tests/test_fh_framer_padding.py) checks
  padding directly. Ten of the twelve RTL modules have a static path from these
  targets. Add checked full-top traffic covering deframing, width conversion,
  buffering, and switching. `fh_wrapper` and `fh_framer_message` still have no
  tested parent path; test the wrapper if supported and resolve the
  message-framer support decision below.

- **P1 — PPS behavior remains incompletely checked: 3/11 direct targets**

  [test_pps_top_smoke.py](../pps_top/tests/test_pps_top_smoke.py) adds full-top
  register/reset checks and visible timer progress alongside the existing delay
  and expand tests. All eleven RTL modules now have a static test-parent path.
  Add checked PPS and timestamp events, synchronization/CDC behavior, symbol
  timing, counter boundaries, and checker results; the top smoke holds `pps_in`
  and `ts_valid` low.

- **P1 — CoE and eCPRI tests can miss datapath failures**

  [test_coe.py](../coe/tests/test_coe.py) sends and loops traffic without
  comparing received payloads. [test_ecpri.py](../ecpri/tests/test_ecpri.py)
  checks version/scratch registers while its Ethernet input loop remains
  commented out. [test_ecpri_framer.py](../ecpri/tests/test_ecpri_framer.py)
  starts a background producer and waits 1,000 cycles without output assertions
  or a producer-completion check. Add independent payload/order/count
  scoreboards and bounded waits for stimulus completion and output drain.

- **P1 — Low-PHY integration remains control-plane only**

  [test_lowphy_smoke.py](../lowphy/tests/test_lowphy_smoke.py) now parametrizes
  both `lowphy0` and `lowphy1` by default, with `LOWPHY_TOP` selecting one. Its
  assertions still cover only register reads/writes. Add checked DL, UL, and
  PRACH datapath transactions through both tops.

- **P1 — Timer implementation branch is missed**

  [test_timer.py](../timer/tests/test_timer.py) sets `SIM_SPEED_UP` but not
  `FREQ_MODE`. [timer.sv](../timer/rtl/timer.sv) defaults to mode 0, so
  `timer_core_491p52` has neither a direct test nor an enabled parent-test
  configuration. Parametrize both implementations.

- **P2 — Common utility modules lack functional tests**

  [util_clk_fwd.sv](../common/rtl/util_clk_fwd.sv) and
  [util_gpio_gw.sv](../common/rtl/util_gpio_gw.sv) have no direct cocotb target
  or static path from a tested top. Add functional tests or document a support
  waiver.

- **P2 — Orphan RTL needs a support decision**

  [nco_lut.sv](../nco/rtl/nco_lut.sv) is not instantiated and is absent from all
  resolved block filelists; current `nco` uses `dds_lut`.
  [fh_framer_message.sv](../fh/rtl/fh_framer_message.sv) is in `fh.flt` but is
  not instantiated. Add direct tests if supported, or explicitly classify these
  modules as retired.

- **P2 — No shared suite tiers**

  No repository-wide sanity/smoke/regression pytest markers or Make targets
  exist. The shared module test target runs the module's entire pytest
  directory. Define explicit tiers and selection rules, including which cocotb
  cases each runner launches.

Verification on the review date: the four O-RAN, PTP, FH, and PPS top smoke
runners and all 16 `common` cases passed when invoked directly on Verilator.
The 14 Python helper/runner cases reported 12 passes and two failures, both
exposing the Bash 3.2 root-runner defect above. Questa was unavailable on this
host; no full regression was run for this review.

### Intentional exceptions

- [cdc/tests/test_cdc_async_rst.py:48](../cdc/tests/test_cdc_async_rst.py#L48)
  waits for `ValueChange(dest_arst)` after stopping the destination clock to
  prove reset assertion is asynchronous. Replacing this with a destination
  clock wait would defeat that test; it is not a synchronous sampling defect.
- Genuine combinational settling is used in `common/tests/test_type_cast.py:117`,
  `pdxch/tests/test_pdxch_fdv_buffer_map.py:28`, and
  `pdxch/tests/test_pdxch_conv.py:75` (FFT-size decode with CDC disabled).
  These are the three retained `Timer` sites.
