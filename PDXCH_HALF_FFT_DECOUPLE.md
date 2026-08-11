# PDXCH: HALF_FFT / HALF_BLOCK 参数解耦 — 设计目标与 Review 记录

日期: 2026-08-11
状态: 设计已确认（未实施），待 Codex 实现

## 1. 背景与目标

当前 `pdxch_top` 用单一 `HALF_BLOCK` 参数同时控制两个本应独立的维度：

| HALF_BLOCK | fdv_buffer IQ 深度 | FFT 点数 |
|---|---|---|
| 0 | 3584 (full) | 4096 (4k, LOG_FFT_SIZE=12) |
| 1 | 2048 (half) | 2048 (2k, LOG_FFT_SIZE=11) |

需求矩阵要求 2×2 组合中的三档：

| 规格 | Block size | FFT | 数据量核对 |
|---|---|---|---|
| NR 100MHz | full (3584) | 4k | 273 PRB=3276 RE ≤ 3584 ✓ |
| NR 30MHz | **half (2048)** | **4k** | 160 PRB=1920 RE ≤ 2048 ✓ |
| 低带宽 | half (2048) | 2k | ✓ |

**缺口**: NR 30MHz 需要 half 缓冲 + 4k FFT，当前参数化不存在该组合——half 强制绑 2k。30MHz 产品被迫多花 12 tile BRAM 或 FFT 降级。

### 目标设计

顶层参数与 `HALF_BLOCK` 并列，新增 `HALF_FFT`（对应关系与 `HALF_BLOCK` 一致，均为 `1'b0` 默认）：

```verilog
module pdxch_top #(
    parameter int  NUM_CC   = 3,
    parameter int  NUM_ANT  = 4,
    parameter bit  HALF_BLOCK = 1'b0,  // 只控制 fdv_buffer IQ/EXP 深度
    parameter bit  HALF_FFT   = 1'b0   // 新增：1 => FFT 2k (LOG_FFT_SIZE=11), 0 => 4k (12)
)
```

传递链拆分:
- `HALF_BLOCK` → `pdxch_fdv_buffer`（write 侧 `IQ_BANK_DEPTH/EXP_BANK_DEPTH`、readout 侧 `rd_half` 逻辑）——只碰缓冲
- `HALF_FFT` → `pdxch_channel` → `fft`（替换现 `pdxch_channel.sv:43` 的 `localparam int LogFftSize = HALF_BLOCK ? 11 : 12;`）——只碰 FFT

### 兼容性验证结论（已读 RTL 确认）

1. **pdxch_conv 无兼容问题**：`fft_size` 是运行时查表（ctrl_rat/ctrl_bw），与编译期参数正交，NCO 步进 `index_next += fft_size` 天然支持 4k（12-bit index 0-4095）。解耦后 conv 一行不用改。
2. **block2stream 无兼容问题**：512 深度滚动窗口在 4k 下已验证，2k 每 ant 点数减半只会更宽裕。
3. **约束**：编译期 FFT 尺寸是运行时 ctrl_bw 配置的上限。若 `HALF_FFT=1`（2k 硬件），软件必须保证不配到 4k 档（bw≥3@15kHz / bw≥4@30kHz），否则静默算错（见 Finding 1）。

### 改动面

| 文件 | 改动 |
|---|---|
| `pdxch_top.sv` | 新增 `HALF_FFT` 参数，传给 channel |
| `pdxch_channel.sv` | `LogFftSize` 改用 `HALF_FFT ? 11 : 12` |
| `pdxch_fdv_buffer*` | 不动（继续吃 HALF_BLOCK） |
| `lowphy0/1.sv`, `puxch.sv` | 实例化点补传 `HALF_FFT`（lowphy0: 0, lowphy1/puxch: 1，保持现状行为） |

### 预期收益

- NR 30MHz 档：half block 省 12 tile BRAM（3 CC × 每 CC 8 B36），FFT 保持 4k
- 低带宽档：half + 2k，BRAM 与 FFT 均瘦身

---

## 2. Review Findings

### Finding 1: HALF_FFT/HALF_BLOCK=1 时 ctrl_size=4k 请求静默算错 — [Open/未确认]

- **位置**: `pdxch_channel.sv` ctrl_size 生成逻辑（L89-128）+ `fft.sv` bypass 逻辑（L242-249）
- **现象**: ctrl_size 由 ctrl_rat + ctrl_bw 决定，与 HALF_BLOCK/HALF_FFT 无关。若硬件 FFT 上限 2k（HALF_BLOCK=1 现状，或解耦后 HALF_FFT=1）而软件配置到大带宽（NR 15kHz bw≥3 / NR 30kHz bw≥4 → ctrl_size=2'b10=4k），`fft.sv` 中 `bypass=0`（全 stage 开启）+ `ctrl_scale=1`，但硬件只有 11 级 stage，结果静默错误，无断言无报错。
- **影响**: 配置错误时输出错误数据且无任何指示；pdxch_conv 的 fft_size 查表同样请求 4k，两者一致地错误。
- **建议**（待确认）: HALF_FFT=1 时钳制 ctrl_size 上限为 2'b01（2k），或加断言/DRC check；确认实际产品是否存在该配置组合。
- **验证方式**: 读 pdxch_channel ctrl_size 映射 + fft bypass 逻辑确认（已做，逻辑确认存在）；可通过 HALF_FFT=1 实例化 + 4k 配置仿真复现（未做）。

### Finding 2: pdxch_regs 固定 3CC×4ANT 与 pdxch NUM_ANT 参数化不匹配 — [Open/未确认]

- **位置**: `pdxch.sv` ctrl_gain 数组声明（L84 `[NUM_CC][NUM_ANT]`）+ `pdxch_regs` 实例化（L95-198，固定连接 4ANT 的 gain 端口 L165-187）
- **现象**: `pdxch_regs` 无参数化，硬编码 3CC×4ANT 的 `dl_gain_*_val_out` 端口；而 `pdxch.sv` 用 `NUM_ANT` 参数声明 `ctrl_gain [NUM_CC][NUM_ANT]`。当 NUM_ANT=2（如低带宽实例/测试）时，连接 `ctrl_gain[cc][2]`/`[3]` 越界。Verilator 报 `SELRANGE`（Selection index out of range），Questa 不报。
- **处理**: 已在 `pdxch.sv` 加 `/* verilator lint_off SELRANGE */` 包住 regs 实例化（ant≥NUM_ANT 的连接在功能上未使用，Quest 双通道 11 passed 验证无功能影响）。**这只是压掉 lint，根因未修**。
- **影响**: NUM_ANT<4 时 regs 仍为不存在的 ant 输出 gain——当前无功能影响（未使用），但属于真实设计不匹配，若未来 regs 增加对 ant 的依赖（如 per-ant 状态回读）会出问题。
- **建议**（待确认）: 让 `pdxch_regs` 参数化（NUM_ANT 传入，generate 生成 gain 端口），或 `pdxch.sv` 用 generate 按 NUM_ANT 选择连接。
- **验证方式**: 已通过 Verilator SELRANGE 警告定位（NUM_ANT=2 测试触发）；Quest 仿真 11 passed 确认现行为无功能影响。

### 已确认无问题的项（本次 review 排除）

- pdxch_conv NCO 步进与编译期 FFT 尺寸解耦 ✓
- block2stream 512 深滚动窗口兼容 2k/4k ✓
- fdv_buffer readout 读地址按 PRB 生成，不依赖 FFT 点数 ✓
- phase_comp 相位表深度（4-bit addr）与 FFT 点数无关 ✓（相位步长按 4k 校准，2k 时需仿真确认，暂列为低风险项）

---

## 3. 实施顺序（供 Codex 参考）

1. 实现 `HALF_FFT` 参数解耦（改动面见上表），保持默认行为不变（HALF_FFT=0）
2. 更新三个实例化点（lowphy0/1, puxch）传 `HALF_FFT`，与现行为一致
3. 验证：.flt 解析 + WSL Verilator 全量 lint；对默认参数跑 OOC 综合确认资源不变
4. 确认 Finding 1 处理方式（钳制或断言）后再实现
5. 逐项 commit（用户确认后），默认不 push
