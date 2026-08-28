# Design Specification for LowPHY

## 1. Purpose

This document is the design specification for the LowPHY subsystem.

The LowPHY design targets an O-RAN O-RU radio unit and implements the low-PHY portion of the signal-processing chain between the O-RAN framer and deframer interfaces and the internal radio sample interfaces.

This document captures:

- the current architectural view from the RTL code base
- the major module hierarchy
- the functional split between downlink, uplink, and PRACH processing
- the key interfaces and control structure
- areas that may still benefit from later expansion

## 2. Precondition

This section summarizes signal-processing background that is assumed by the RTL and by the rest of this document.

### 2.1 Fixed-Point Representation

The RTL uses a fixed-point notation of the form `fi(signed, width, frac)`.

In this notation:

- the first field indicates whether the number is signed
- the second field is the total bit width, including the sign bit when signed
- the third field is the number of fractional bits

For example, `fi(1, 16, 15)` means:

- `1`: signed number
- `16`: total width is 16 bits
- `15`: fractional width is 15 bits

This corresponds to a signed 16-bit fixed-point value with 15 fractional bits. Its arithmetic range is `-1 <= x < 1`, so `-1` is representable and `+1` is not.

The bit storage for `fi(1, 16, 15)` is shown below.

![Bit storage layout for fi(1, 16, 15)](fi_1_16_15_bit_layout.svg)

For `fi(1, 16, 15)`, the stored bits can be interpreted as:

$$
x = -S \cdot 2^{0} + F_{14} \cdot 2^{-1} + F_{13} \cdot 2^{-2} + \cdots + F_{1} \cdot 2^{-14} + F_{0} \cdot 2^{-15}
$$

where `S`, `F14`, ..., `F0` are the individual stored bits and each bit is either `0` or `1`.

Complex fixed-point values use the notation `cfi(signed, width, frac)`, where the leading `c` means complex.

For example, `cfi(1, 16, 15)` means:

- the real part uses `fi(1, 16, 15)`
- the imaginary part uses `fi(1, 16, 15)`

So a `cfi(1, 16, 15)` sample contains one 16-bit signed fixed-point real value and one 16-bit signed fixed-point imaginary value.

When the complex sample is packed into one 32-bit word, the Q sample occupies the upper 16 bits and the I sample occupies the lower 16 bits. In bit-range notation, this is `Q[31:16]` and `I[15:0]`.

![32-bit storage layout for cfi(1, 16, 15)](cfi_1_16_15_word_layout.svg)

The same complex sample can also be viewed as an I/Q point in the complex plane, where the in-phase and quadrature components are each stored as `fi(1, 16, 15)` values.

![I/Q interpretation for cfi(1, 16, 15)](cfi_1_16_15_iq_plane.svg)

For a constant-envelope complex sinusoid,

$$
x(t) = \cos(2 \pi t) + j \sin(2 \pi t)
$$

the I/Q point lies on a circle of radius `1`. This corresponds to a complex waveform with magnitude `1`, which is a useful reference for `0 dBFS` complex signal power.

Points outside that circle, such as approximately `0.8 + 0.8j`, have magnitude greater than `1` and therefore instantaneous power above `0 dBFS`, even though such operation is usually avoided in a communication system.

This is the most common numeric format used throughout the RTL datapaths.

### 2.2 Fixed-Point Arithmetic

Arithmetic between fixed-point values follows the same signed-fractional interpretation.

For example, if `a` and `b` are both `fi(1, 16, 15)`, then:

$$
p = a \cdot b
$$

The full-precision product keeps 30 fractional bits, so it can be represented as `fi(1, 31, 30)`.

If the result must be converted back to `fi(1, 16, 15)`, the usual truncation step is to remove the trailing 15 fractional bits.

In bit terms, this is equivalent to taking the full-precision product and shifting it right by 15 bits.

$$
Y_{\mathrm{int}} = P_{\mathrm{int}} \gg 15
$$

$$
y = Y_{\mathrm{int}} \cdot 2^{-15}
$$

where `P_int` is the signed integer bit pattern of the full-precision `fi(1, 31, 30)` product, `>> 15` is an arithmetic right shift that discards the lower 15 fractional bits, and `y` is the reduced-width `fi(1, 16, 15)` result.

This truncation keeps the sign bit and the upper 15 fractional bits, while discarding the lower 15 fractional bits to reduce datapath width.

### 2.3 Digital Power

Digital power is calculated from the arithmetic value of the fixed-point samples.

The first step is to convert the stored binary data into its arithmetic value by using the fixed-point weight equation described in Section 2.1.

Once the sample values are interpreted as arithmetic values, the digital power relative to full scale is computed from the average squared magnitude:

$$
P\ [\mathrm{dBFS}] = 10 \cdot \log_{10}\left( \operatorname{average}\left( |x|^2 \right) \right)
$$

For a real-valued sample, `|x|^2 = x^2`. For a complex sample, `|x|^2 = I^2 + Q^2`.

This definition is consistent with the unit-circle interpretation above, where a constant-envelope complex waveform with magnitude `1` corresponds to `0 dBFS` average power.

## 3. Functional Overview

LowPHY integrates the low-level signal-processing functions required on the O-RAN O-RU side.

At a high level:

- downlink O-RAN U-Plane data from the deframer is processed by `pdxch` and converted into radio-domain sample streams
- uplink radio-domain sample streams are processed by `puxch` and formatted toward the framer as O-RAN U-Plane data
- PRACH uplink processing is handled separately by `prach`, using PRACH C-Plane information plus radio sample inputs to generate PRACH U-Plane output
- AXI-Lite control registers configure LowPHY itself and the embedded channel-processing blocks
- timing, synchronization, and reset distribution align the internal processing with O-RAN and radio timing domains

## 4. Architecture Summary

### 4.1 Major hierarchy

The core composition inside `lowphy_band` is:

- `lowphy_regs`: top-level register block for integrated control and status
- `pdxch_top`: downlink datapath integration
- `puxch_top`: uplink datapath integration
- `prach_top`: PRACH datapath integration

`lowphy_band` acts as the integration shell that binds these blocks together and presents:

- AXI-Lite control/status access
- O-RAN framer and deframer side interfaces
- PRACH message interface
- timing and reset interfaces
- radio sample ingress and egress interfaces

### 4.2 Processing split

The design is structurally split as follows:

- Downlink: `pdxch`
- Uplink: `puxch`
- PRACH: `prach`

This matches the intended O-RAN low-PHY partitioning for the O-RU implementation.

### 4.3 Parameterization

The shared `lowphy_band` module is parameterized by:

- `NUM_CC`: number of component carriers, currently checked to be 1 to 3
- `NUM_ANT`: number of antennas, currently checked to be 1, 2, or 4
- `CC_ID`: carrier-group base identifier for a band instance
- `ANT_ID`: antenna-group base identifier for a band instance
- `HAS_BFP`: retained for interface compatibility only; the PRACH and PUXCH blocks now always include their BFP compressors (compression itself is enabled or disabled at runtime through the `ud_comp_meth` registers)
- `HALF_BLOCK`: packaging-related mode used by the composed datapaths

### 4.4 Block diagram and connectivity

The following diagram shows the current logical composition of `lowphy_band` as implemented in RTL.

![Logical composition of lowphy_band](lowphy_band_overview.svg)

At the current integration level:

- `lowphy_regs` provides one integrated control and status register map for the band instance
- `pdxch_top` consumes deframer-side O-RAN U-Plane data and produces radio-domain downlink samples
- `puxch_top` consumes radio-domain uplink samples and produces framer-side O-RAN U-Plane data
- `prach_top` consumes PRACH C-Plane control plus radio-domain uplink samples and produces PRACH framer output
- `lowphy_band` is the point where timing, reset, and bus-domain connections are distributed into the three datapath blocks

The main connectivity inside `lowphy_band` is summarized below.

- AXI-Lite interface connects to `lowphy_regs`
- `lowphy_regs` drives control buses for DL, UL, and PRACH sub-blocks
- `lowphy_regs` also receives PRACH-related status back from `prach_top`
- deframer-side data `s_defm_data_*` connects into `pdxch_top`
- framer-side data `m_fram_data_*` is sourced by `puxch_top`
- PRACH framer data `m_fram_prach_*` is sourced by `prach_top`
- radio downlink samples `m_axis_*` are sourced by `pdxch_top`
- radio uplink samples `s_axis_*` are shared as inputs to both `puxch_top` and `prach_top`
- DL timing inputs feed `pdxch_top`
- UL timing inputs feed `puxch_top`
- PRACH message inputs feed `prach_top`
- framer and deframer resets are synchronized into `internal_bus_clk` before use by the O-RAN-side datapaths

### 4.5 Packaging connectivity

The external top-level packaging differs between `lowphy0` and `lowphy1`.

#### `lowphy0`

![lowphy0 packaging view](lowphy0_packaging.svg)

`lowphy0` is a direct one-instance packaging layer around one `lowphy_band` core.

#### `lowphy1`

![lowphy1 packaging view](lowphy1_packaging.svg)

`lowphy1` partitions the external interface set across three `lowphy_band` instances.

Observed mapping pattern from the RTL:

- `u_b0` is controlled by `S0_AXI` and uses timing groups `s0` to `s2`
- `u_b1` is controlled by `S1_AXI` and uses timing groups `s3` to `s5`
- `u_b2` is controlled by `S2_AXI` and uses timing groups `s6` to `s8`
- framer and deframer antenna ports are split across these three instances
- each band instance has its own PRACH output stream and unsolicited framer output port group

The following simplified view shows the top-level relationship.

![lowphy1 instance mapping](lowphy1_mapping.svg)

This packaging suggests the LowPHY subsystem is designed to scale by composing several reusable band-level integration blocks rather than duplicating one monolithic top.

## 5. Module-Level Description

Based on the current RTL, the implementation does not expose a single module literally named `lowphy`.

Instead, the current top-level packaging is organized as:

- `lowphy_band`: reusable band-level integration module
- `lowphy0`: one-band packaging variant
- `lowphy1`: multi-band packaging variant
- `lowphy0_wrapper` and `lowphy1_wrapper`: IP-packaging wrappers with interface annotations

For the purpose of this document, the term `LowPHY` refers to this overall subsystem.

### 5.1 `lowphy_band`

`lowphy_band` is the primary reusable LowPHY integration module.

Main responsibilities:

- instantiate and connect `pdxch_top`, `puxch_top`, and `prach_top`
- expose the full O-RAN-side and radio-side interfaces for one logical band instance
- host the integrated register map through `lowphy_regs`
- collect and distribute control fields for DL, UL, and PRACH processing
- synchronize framer and deframer resets into the internal bus clock domain
- provide simple pass-through or placeholder handling for some auxiliary interfaces such as early BID, SSB, and unsolicited framer outputs

Current implementation notes from the RTL:

- early BID ready signals are tied active
- framer BID ready signals are tied active
- deframer BID ready signals are tied active
- unsolicited framer output is currently tied inactive and zeroed
- SSB-related ready signals are tied active

These behaviors should be reviewed later to determine whether they are intentional final behavior or temporary integration stubs.

### 5.2 `lowphy0`

`lowphy0` is a packaged top-level that instantiates one `lowphy_band` instance.

Current configuration in code:

- `NUM_CC = 3`
- `NUM_ANT = 4`
- `HALF_BLOCK = 0`

This variant maps one AXI-Lite port and one set of external interfaces to a single band-level LowPHY instance.

### 5.3 `lowphy1`

`lowphy1` is a larger packaged top-level that instantiates three `lowphy_band` instances.

Current implementation pattern:

- one instance with `NUM_ANT = NumAnt / 2`
- two additional instances with `NUM_ANT = NumAnt / 4`
- separate AXI-Lite control ports for the three instantiated band blocks
- separate timing and data interface groups mapped into each band instance

This indicates `lowphy1` is used to package multiple LowPHY bands or antenna-group partitions into one top-level integration.

### 5.4 Wrappers

`lowphy0_wrapper` and `lowphy1_wrapper` are wrapper modules intended for tool flow and IP packaging.

Their main role is to:

- preserve the external port list
- add interface metadata and annotations such as `X_INTERFACE_INFO`
- support integration into Vivado or other IP-based system assembly flows

## 6. Downlink Path

### 6.1 Functional role

The downlink path accepts O-RAN U-Plane data from the deframer side and converts it into radio sample streams toward the radio interface.

### 6.2 Main implementation block

The main integrated block is `pdxch_top`, instantiated in `lowphy_band`.

The lower-level `pdxch` subsystem includes:

- `pdxch_regs`
- `pdxch_top`
- `pdxch_channel`
- `pdxch_conv`
- `pdxch_conv_nco`
- `pdxch_fdv_buffer` and related buffer modules
- `pdxch_block2stream`

### 6.3 Interface view

At LowPHY integration level, the downlink side uses:

- deframer data inputs `s_defm_data_*`
- downlink timing inputs such as `s_dl_sym_num`
- radio sample outputs `m_axis_*`

### 6.4 Control view

The integrated downlink controls include at least:

- enable per CC
- RAT selection per CC
- BIST control per CC
- bandwidth configuration per CC
- PRB count per CC
- RFS offset per CC
- gain per CC and antenna
- user-data compression settings
- DL phase compensation RAM access

### 6.5 Detailed implementation flow

The current downlink implementation in `pdxch_top` is organized as a per-antenna front end followed by a per-CC channel-processing chain.

The effective stage order is shown below.

![Downlink processing flow](downlink_flow.svg)

### 6.6 Stage-by-stage description

#### Stage 1: U-Plane input adaptation

The downlink path starts from `s_defm_data_*` on the O-RAN deframer side.

For each antenna in `pdxch_top`:

- if `HAS_BFP` is enabled, `bfp_decomp` expands compressed O-RAN payload data into a 128-bit internal stream
- if `HAS_BFP` is disabled, the logic repacks pairs of 64-bit transfers into one 128-bit word
- the adapted output is carried on internal `s0_axis_*` buses

This step normalizes the deframer output into a common 128-bit format for the next buffering stage.

#### Stage 2: FDV buffer write-side processing

For each component carrier, `pdxch_top` instantiates one `pdxch_fdv_buffer`.

Inside `pdxch_fdv_buffer`:

- `pdxch_fdv_buffer_write` examines U-Plane metadata from `tuser`
- the logic extracts at least start-of-section, carrier ID, start PRB, and number of PRBs
- incoming 128-bit words are byte-reversed and word-reversed before memory write so the RAM layout matches later readout order
- only payload for the selected `CC_ID` is written into that carrier buffer
- write address generation is derived from start PRB and current symbol-bank selection

At this point the incoming frequency-domain payload has been placed into a carrier-local RAM structure indexed for later symbol-time readout.

#### Stage 3: Radio-timed read scheduling

`pdxch_fdv_buffer` bridges from the O-RAN input timing to the radio sample timing.

The current implementation does this by:

- delaying `sync_in` by `ctrl_rfs_offset` to create `defm_radio_start_10ms`
- delaying that pulse again by a fixed 4000-cycle interval to allow upstream O-RAN buffering to complete
- crossing the delayed pulse from `clk_eth_xran` into `clk` using `cdc_pulse`
- driving a `symbol_timer` from the synchronized pulse to produce `start_of_frame`, `start_of_slot`, and `start_of_symbol`

This is the key alignment mechanism that makes buffered frequency-domain data available in the radio clock domain at the expected symbol boundaries.

#### Stage 4: FDV buffer readout and PRB mapping

`pdxch_fdv_buffer_readout` performs the timed extraction of buffered RE data.

Main behaviors visible in the RTL:

- control fields such as enable, RAT, BIST, bandwidth, and PRB count are synchronized into the radio clock domain
- symbol start selection depends on numerology: 15 kHz modes use one symbol-start bit and 30 kHz modes use the other
- the readout counter and derived phase/index values define when and where data is read from memory
- read address mapping depends on RAT and bandwidth, including FFT-size related masking
- for LTE, the readout logic explicitly inserts a DC null handling offset on the right half of the spectrum
- read enable is issued per antenna phase, effectively sequencing antenna data across the shared channel pipeline
- optional BIST data can replace RAM data using an LFSR-driven QPSK-like pattern when enabled

The output of this stage is a sequential complex sample stream with sideband markers:

- `dout_dr`, `dout_di`
- `dout_sf`, `dout_sl`, `dout_sy`
- `dout_chn`
- `dout_dv`, `dout_last`

This is the main handoff from buffered frequency-domain resource data into the downstream per-CC signal-processing chain.

#### Stage 5: Per-antenna gain application

Inside `pdxch_channel`, the first active processing block is `gain`.

The gain stage:

- applies carrier-local `ctrl_gain[ant]`
- operates on the sequential complex stream
- preserves symbol, slot, frame, channel, valid, and last sideband information

This stage provides coarse output scaling before the inverse transform chain.

#### Stage 6: Pre-IFFT conversion

After gain, `pdxch_channel` applies `pdxch_conv`.

From the RTL, this block performs a frequency-domain conversion step driven by `ctrl_rat` and `ctrl_bw`.

Observed behaviors include:

- selecting an FFT-size related stride from RAT and bandwidth
- computing an index sequence per antenna channel
- reversing the index ordering used for later mapping
- computing a phase increment that depends on slot and symbol boundaries
- generating NCO cosine and sine values through `pdxch_conv_nco`
- applying a complex rotation to the incoming complex samples

This stage appears to prepare the frequency-domain input ordering and phase relationship expected by the inverse FFT stage.

#### Stage 7: Inverse FFT

`pdxch_channel` then instantiates `fft` with:

- `INV_FFT = 1'b1`
- `BIT_REVERSED_INPUT = 1'b1`
- runtime controls `ctrl_size` and `ctrl_itlv`

`ctrl_size` and `ctrl_itlv` are derived from `ctrl_rat` and `ctrl_bw`.

In effect, the downlink path selects among 1k, 2k, or 4k transform-related operating points depending on numerology and configured bandwidth.

This stage performs the core frequency-domain to time-domain conversion for the downlink signal.

#### Stage 8: Phase compensation

After the inverse FFT, `pdxch_channel` applies `phase_comp`.

This block is controlled by:

- `ctrl_rat`
- phase-compensation coefficient writes via `ctrl_phase_comp_addr`, `ctrl_phase_comp_we`, and `ctrl_phase_comp_din`

The corresponding readback memory is exposed in the DL register map as `dl_phase_comp`.

This stage provides programmable phase adjustment after the inverse FFT.

#### Stage 9: Block-to-stream formatting

The final downlink stage inside `pdxch_channel` is `pdxch_block2stream`.

This block:

- writes sequential complex samples into per-antenna RAMs
- uses symbol markers to trigger readout
- reconstructs one AXI-Stream-style output per antenna
- drives `m_axis_tdata`, `m_axis_tuser`, `m_axis_tlast`, and `m_axis_tvalid`

Current implementation details visible in the RTL:

- the sample payload is emitted as `{Q, I}` packed into `m_axis_tdata`
- `m_axis_tuser[i][0]` carries a delayed sync marker, while the rest of `tuser` is zero
- `m_axis_tlast` is tied low in this block
- `m_axis_tvalid` is tied high in this block
- `m_axis_tready` is currently ignored by the implementation

These handshake semantics should be reviewed carefully before treating the radio-side stream as a conventional backpressure-capable AXI-Stream interface.

### 6.7 Downlink control interaction summary

The main downlink controls affect the processing chain as follows.

| Control | Main stage affected | Purpose |
| --- | --- | --- |
| `ctrl_ud_comp_meth`, `ctrl_ud_iq_width`, `ctrl_fs_offset` | input adaptation | Configure BFP decompression |
| `ctrl_en` | FDV readout | Enable active antenna or carrier readout |
| `ctrl_rat` | FDV readout, pre-IFFT conversion, inverse FFT, phase compensation | Select LTE / NR mode and numerology behavior |
| `ctrl_bist` | FDV readout | Enable BIST sample generation |
| `ctrl_bw` | FDV readout, pre-IFFT conversion, inverse FFT | Select bandwidth-dependent sizing and mapping |
| `ctrl_nprb` | FDV buffer readout | Limit active PRB region |
| `ctrl_rfs_offset` | radio-timed scheduling | Shift radio-start alignment relative to `sync_in` |
| `ctrl_gain` | gain | Set per-antenna amplitude scaling |
| `dl_phase_comp` memory | phase compensation | Program per-symbol phase correction |

### 6.8 Downlink implementation notes and current risks

The following details are worth carrying as explicit implementation notes in the spec.

- The downlink datapath crosses from `clk_eth_xran` into `clk` through the FDV buffer structure rather than a simple stream CDC.
- `pdxch_fdv_buffer_readout` time-multiplexes antenna data through a shared downstream chain using the internal `phase` and `dout_chn` sequencing.
- LTE-specific DC-null handling is explicitly implemented in the readout address mapping.
- BIST generation is inserted in the FDV readout stage rather than later in the time-domain chain.
- `pdxch_block2stream` currently does not honor `m_axis_tready`, which may be acceptable only if the radio-side consumer is always ready.

## 7. Uplink Path

### 7.1 Functional role

The uplink path accepts radio sample streams and converts them into O-RAN U-Plane output toward the framer side.

### 7.2 Main implementation block

The main integrated block is `puxch_top`, instantiated in `lowphy_band`.

The lower-level `puxch` subsystem includes:

- `puxch_regs`
- `puxch_top`
- `puxch_channel`
- `puxch_conv`
- `puxch_resync`
- `puxch_buffer`

### 7.3 Interface view

At LowPHY integration level, the uplink side uses:

- radio sample inputs `s_axis_*`
- uplink timing inputs such as `s_ul_sym_num`
- framer data outputs `m_fram_data_*`
- framer request input `m_fram_data_req`

### 7.4 Control view

The integrated uplink controls include at least:

- enable per CC
- RAT selection per CC
- BIST control per CC
- bandwidth configuration per CC
- PRB count per CC
- RFS offset per CC
- gain per CC and antenna
- user-data compression settings
- UL phase compensation RAM access

### 7.5 Detailed implementation flow

The current uplink implementation in `puxch_top` is organized as a per-CC channel-processing chain followed by a per-antenna buffering and framer-output stage.

The effective stage order is shown below.

![Uplink processing flow](uplink_flow.svg)

### 7.6 Stage-by-stage description

#### Stage 1: Radio input capture and resynchronization

The uplink path starts from radio-domain sample streams on `s_axis_*`.

For each component carrier, `puxch_top` instantiates one `puxch_channel`.

Inside `puxch_channel`, the first functional stage is `puxch_resync`.

Observed responsibilities from the RTL:

- receive one AXI-Stream-like input per antenna
- use a synchronized `sync_in` pulse as the basis for internal symbol timing
- run a local `symbol_timer` in the radio clock domain
- generate start-of-frame, start-of-slot, and start-of-symbol markers
- sequence a channel index `chn` over the active antenna lanes
- convert parallel per-antenna radio streams into one sequential complex stream tagged by `dout_chn`
- zero-fill disabled channels based on `ctrl_en`

This stage creates the time-multiplexed complex stream used by the rest of the uplink carrier pipeline.

Implementation note:

- `s_axis_tready` is tied active in `puxch_resync`
- `dout_last` is tied low in this block

#### Stage 2: Uplink start alignment

`puxch_channel` aligns its internal processing and framer-side output timing relative to `sync_in` and `ctrl_rfs_offset`.

The current implementation does this by:

- crossing `ctrl_rat` and `ctrl_rfs_offset` into `clk_eth_xran`
- delaying `sync_in` by `ctrl_rfs_offset` to create `sync_s`
- using `sync_s` as the start time of PUXCH channel processing
- generating `fram_radio_start_10ms` by delaying `sync_s` with a fixed offset that depends on numerology
- crossing `sync_s` into the radio clock domain with `cdc_pulse`

The fixed output delay is currently:

- `54477` cycles for LTE and NR 15 kHz related processing
- `27341` cycles for NR 30 kHz related processing

This mechanism aligns the framer-visible UL output timing to the expected O-RAN side schedule.

#### Stage 3: Per-antenna gain application

After `puxch_resync`, `puxch_channel` applies the shared `gain` block.

The gain stage:

- applies carrier-local `ctrl_gain[ant]`
- preserves sequential sideband information
- operates in the radio clock domain

This stage provides configurable amplitude scaling before transform processing.

#### Stage 4: Pre-FFT conversion

After gain, `puxch_channel` applies `puxch_conv`.

From the RTL, this block performs uplink frequency-domain preparation ahead of the FFT.

Observed behaviors include:

- synchronizing `ctrl_rat`, `ctrl_bw`, and `ctrl_nprb` into the radio clock domain
- selecting FFT-size dependent stride and masking according to RAT and bandwidth
- maintaining a per-antenna sample index
- generating valid and last markers from index progression
- computing a phase increment derived from `ctrl_nprb`
- applying a numerology-dependent complex rotation using a DDS LUT

In the LTE case, the phase increment includes a half-subcarrier shift adjustment.

This stage prepares the uplink stream for the forward FFT and subcarrier mapping expected by the O-RAN uplink format.

#### Stage 5: FFT

`puxch_channel` instantiates `fft` with:

- `INV_FFT = 1'b0`
- `BIT_REVERSED_INPUT = 1'b0`
- runtime controls `ctrl_size` and `ctrl_itlv`

As with the downlink, `ctrl_size` and `ctrl_itlv` are derived from `ctrl_rat` and `ctrl_bw`.

This stage performs the core time-domain to frequency-domain conversion for uplink signal generation.

#### Stage 6: Phase compensation

After the FFT, `puxch_channel` applies `phase_comp`.

This stage is controlled by:

- `ctrl_rat`
- UL phase-compensation writes via `ctrl_phase_comp_addr`, `ctrl_phase_comp_we`, and `ctrl_phase_comp_din`

The corresponding control memory is exposed in the UL register map as `ul_phase_comp`.

This stage provides programmable phase adjustment after the forward FFT.

#### Stage 7: Per-antenna ping-pong buffering

`puxch_top` next instantiates one `puxch_buffer` per antenna.

Each `puxch_buffer` accepts the sequential outputs from all component carriers:

- `din_dr`, `din_di`
- `din_sf`, `din_sl`, `din_sy`
- `din_chn`, `din_dv`

Main observed write-side behavior:

- each CC keeps a write bank and write counter
- bank toggling occurs on symbol boundaries
- write addresses are bit-reversed before RAM storage
- in both half- and full-block modes, each complex RE is internally compressed to a 9-bit I mantissa, a 9-bit Q mantissa, and a shared per-RE 4-bit exponent
- the IQ memory uses an 18-bit write port and a 36-bit read port, packing two compressed REs per framer-side address
- exponent storage uses a corresponding 4-bit write port and 8-bit read port
- FFT bins above the 275-PRB full-block capacity are not written
- the 3584x36 full-block IQ memory is segmented into three RAMB36-sized regions and one RAMB18-sized tail to avoid rounding the inferred memory up to four RAMB36 tiles
- half-block mode supports 160 PRBs (1920 REs) per ping/pong bank; its two 1920x18 IQ banks map to two RAMB36 primitives, while the combined 3840x4 exponent memory maps to one RAMB18 primitive

This stage collects FFT-domain output into antenna-local storage so that the O-RAN framer can read requested PRB ranges later.

#### Stage 8: Framer request-driven readout

`puxch_buffer` reads data out in the O-RAN clock domain according to `m_fram_data_req`.

Observed read-side behavior from the RTL:

- request metadata is taken from `m_fram_data_req`
- request fields include validity, start PRB, number of PRBs, and CC ID
- requests are queued in a small FIFO in `clk_eth_xran`
- only one request is actively serviced at a time using `rd_busy`
- the read bank is selected from `s_ul_sym_num[fifo_req_cc][0]`
- read count starts at `start_prb * 6`
- readout ends at `(start_prb + num_prb) * 6 - 1`
- read data from the selected CC RAM is OR-combined onto one antenna-local output bus

In both modes, the buffer emits two compressed REs and their individual exponents in a 44-bit internal BFP9 payload. It does not reconstruct 16-bit IQ values after the RAM read.

#### Stage 9: Stream pipeline and BFP compression

Still inside `puxch_buffer`, the raw readout stream passes through:

- a small FWFT output FIFO (`fifo_srl`); downstream backpressure freezes the whole read pipeline instead of buffering into a deep FIFO (see KNOWN_ISSUES.md, section 5, for the long-backpressure limitation)
- an output timing register stage `axis_reg`

This produces one antenna-local internal-BFP9 stream `s0_axis_*` in the O-RAN clock domain.

`bfp_comp` then finds the largest of the 12 per-RE exponents in each PRB and right-shifts the stored 9-bit mantissas directly to that shared exponent. This is bit-exact with the former decompress-to-16-bit then recompress path, but removes both wide arithmetic stages. Final BFP9 output is mandatory; the legacy compression-method and IQ-width controls remain only for register-map compatibility. `ctrl_fs_offset` still adjusts the reported exponent.

Then `puxch_top` performs the final action per antenna:

- `bfp_comp` compresses the 64-bit stream using `ctrl_ud_comp_meth`, `ctrl_ud_iq_width`, and `ctrl_fs_offset`; with compression disabled (`ctrl_ud_comp_meth != 1`) the data passes through unchanged apart from added latency

This stage forms the final U-Plane payload forwarded toward the framer.

### 7.7 Uplink control interaction summary

The main uplink controls affect the processing chain as follows.

| Control | Main stage affected | Purpose |
| --- | --- | --- |
| `ctrl_ud_comp_meth`, `ctrl_ud_iq_width`, `ctrl_fs_offset` | final compression stage | Configure BFP compression toward framer output |
| `ctrl_en` | resync and channel selection | Enable active antenna lanes for a carrier |
| `ctrl_rat` | alignment timing, pre-FFT conversion, FFT, phase compensation, buffer sizing | Select LTE / NR mode and numerology behavior |
| `ctrl_bist` | resync path behavior | Carried into `puxch_resync`; detailed BIST behavior should be reviewed further |
| `ctrl_bw` | resync channel span, pre-FFT conversion, FFT, buffer addressing | Select bandwidth-dependent sizing and lane behavior |
| `ctrl_nprb` | pre-FFT conversion | Define PRB-dependent phase and mapping behavior |
| `ctrl_rfs_offset` | uplink start alignment | Shift the UL processing start relative to `sync_in` |
| `ctrl_gain` | gain | Set per-antenna amplitude scaling |
| `ul_phase_comp` memory | phase compensation | Program per-symbol phase correction |

### 7.8 Uplink implementation notes and current risks

The following details are worth carrying as explicit implementation notes in the spec.

- The uplink path begins with a resynchronization stage that time-multiplexes antenna samples into a shared per-CC processing pipeline.
- `puxch_buffer` is request-driven on the framer side; UL data is not simply streamed continuously out of the FFT path.
- Ping-pong RAM banking is used to decouple radio-clock writes from O-RAN-clock reads.
- The framer request queue is serialized through a FIFO, so only one queued request per antenna buffer is actively serviced at a time.
- `puxch_resync` ties `s_axis_tready` high, which assumes the radio source can be accepted continuously.
- `ctrl_bist` is carried into `puxch_resync`, but a deeper review is still needed to document whether the current UL BIST path is fully implemented or only partially wired.

## 8. PRACH Path

### 8.1 Functional role

The PRACH path is separated from the normal uplink channel path and handles PRACH-specific processing and formatting.

### 8.2 Main implementation block

The main integrated block is `prach_top`, instantiated in `lowphy_band`.

The lower-level `prach` subsystem includes:

- `prach_regs`
- `prach_top`
- `prach_channel`
- `prach_ctrl`
- `prach_ddc`
- `prach_hb2`
- `prach_hb4`
- `prach_fft` and associated FFT helper modules
- `prach_reshape`
- `prach_resync`
- `prach_stream2block`
- `prach_framer` and `prach_framer_buffer`

### 8.3 Interface view

At LowPHY integration level, the PRACH side uses:

- PRACH C-Plane message inputs `s_prach_*`
- radio sample inputs shared from the radio-side uplink sample interface
- PRACH framer output `m_fram_prach_*`

### 8.4 Control and status view

The integrated PRACH controls include at least:

- enable per CC
- PRACH format per CC
- RAT selection per CC
- BIST and static-C controls per CC
- bandwidth configuration per CC
- RFS offset per CC
- TA3 offset per CC
- compression settings
- configured subframe, slot, and symbol identifiers
- configured time offset and CP length
- configured number of symbols and frequency offset
- configured sampling offset

The top-level register block also captures PRACH message status fields such as:

- decoded or observed subframe, slot, and symbol identifiers
- decoded or observed time offset and CP length
- decoded or observed number of symbols and frequency offset

### 8.5 Detailed implementation flow

The current PRACH implementation in `prach_top` is organized as one PRACH-processing chain per component carrier, followed by a fan-in switch that arbitrates the carrier outputs onto one PRACH framer stream.

The effective stage order is shown below.

![PRACH processing flow](prach_flow.svg)

### 8.6 Stage-by-stage description

#### Stage 1: PRACH control interpretation

For each component carrier, `prach_top` instantiates one `prach_channel`.

Inside `prach_channel`, `prach_ctrl` is responsible for determining when a PRACH burst should be captured and how it should be processed.

Observed behavior from the RTL:

- PRACH C-Plane fields are transferred from `clk_eth_xran` into `clk` using `cdc_handshake_f`
- static PRACH configuration registers are also crossed into the processing clock domain
- dynamic PRACH messages are accepted only when they match the local `CC_ID` and antenna group window
- the control block computes:
  - start symbol ID
  - start sample index
  - number of symbols
  - frequency control word `rd_fcw`
  - section ID
- the control block can operate from either live C-Plane messages or static configuration registers when `ctrl_static_c` is enabled
- captured or decoded message fields are reported back through the PRACH status registers

This stage is the control-plane heart of the PRACH subsystem.

#### Stage 2: Sync alignment into the processing domain

`prach_channel` aligns PRACH processing to the O-RAN timing reference.

The current implementation:

- delays `sync_in` in `clk_eth_xran` by `ctrl_rfs_offset`
- crosses the delayed pulse into the radio processing clock with `cdc_pulse`
- uses the synchronized pulse as the timing reference for PRACH resynchronization and sample capture

This provides the time base that connects O-RAN PRACH scheduling to the radio-sample stream.

#### Stage 3: Radio sample resynchronization

After control generation, `prach_channel` applies `prach_resync` to the radio input streams.

At a high level, this block:

- accepts per-antenna uplink radio samples on `s_axis_*`
- uses the synchronized PRACH timing pulse as its timing reference
- emits a sequential complex stream with frame, slot, symbol, channel, valid, and last sidebands

This stage serves the same structural purpose as the UL resync block but is dedicated to PRACH capture requirements.

#### Stage 4: PRACH digital down-conversion and decimation

`prach_channel` next applies `prach_ddc`.

This is one of the most substantial processing blocks in the PRACH chain.

Observed implementation features:

- the input stream is mixed by a programmable NCO-driven `mixer` using `rd_fcw`
- the mixer output then passes through six reshape and half-band stages
- `ctrl_bw` selects bypass patterns for the half-band filter chain
- the chain uses a combination of `prach_hb2`, `prach_hb4`, and `prach_reshape` stages
- after multistage decimation, `prach_conv` performs a final conversion step
- the output logic suppresses invalid or out-of-range channel results by zeroing channels above `NUM_ANT`

This stage shifts the PRACH frequency region to baseband and reduces the effective sample rate before block capture and FFT processing.

#### Stage 5: Stream-to-block capture

After DDC, `prach_channel` applies `prach_stream2block`.

This block captures the PRACH sequence samples required for FFT processing.

Observed behavior from the RTL:

- it tracks symbol count and sample count relative to the synchronized radio stream
- a write-state FSM transitions through idle, CP skip, first sequence, and optional second sequence states
- the block begins capture when the current symbol matches either `ctrl_start_symbol0` or `ctrl_start_symbol1`
- capture begins at `ctrl_start_sample`
- a first 1536-sample sequence is always captured
- a second 1536-sample sequence is captured when `ctrl_num_symbol` indicates a longer format
- captured samples are written per antenna into local RAMs

When enough samples have been captured for a requesting antenna, `prach_stream2block` asserts `ap_req` and arbitrates the readout request.

This stage converts the continuous decimated stream into a PRACH-length block suitable for FFT.

#### Stage 6: PRACH FFT

The block output from `prach_stream2block` feeds `prach_fft`.

The current implementation uses:

- `FFT_SIZE = 1536`
- a dedicated PRACH FFT datapath built from `prach_fft_ditfft3` and cascaded `prach_fft_ditfft2` stages
- explicit output saturation logic
- delayed sideband propagation for frame, slot, symbol, channel, and last markers

This stage performs the main PRACH frequency-domain transform used to create the PRACH uplink packet payload.

#### Stage 7: PRACH framer buffering

After FFT, `prach_channel` applies `prach_framer`, whose first internal stage is `prach_framer_buffer`.

Observed framer-buffer behavior:

- writes 32-bit `{Q, I}` samples into antenna-local RAMs
- starts a write burst on symbol-valid data for the selected antenna channel
- stops the write after 864 input words per antenna path in the current implementation
- raises a per-antenna arbitration request once the channel buffer has been filled
- arbitrates one antenna buffer at a time for output
- reads out 64-bit words assembled from two complex samples
- fills `m_axis_tuser` with `{8'b0, CC_ID, ANT_ID, rd_section_id}`

This stage packages FFT outputs into a structure ready for PRACH U-Plane transport.

#### Stage 8: BFP compression and async transfer

Still inside `prach_framer`:

- the `prach_framer_buffer` output is always compressed by `prach_bfp_compress`
- the resulting PRACH stream is then transferred from `clk` into `clk_eth_xran` using `axis_fifo_alt` in asynchronous mode

This stage creates the final per-CC PRACH U-Plane stream in the O-RAN clock domain.

#### Stage 9: Carrier output arbitration

At the top level of `prach_top`, the three per-CC PRACH outputs are combined using `axis_switch`.

Observed behavior:

- each carrier-local `prach_channel` produces one PRACH AXI-Stream output
- `axis_switch` arbitrates across `NUM_CC` sources into one destination stream
- the selected result is emitted on `m_fram_prach_*`

This is the final LowPHY PRACH output visible to the framer side.

### 8.7 PRACH control interaction summary

The main PRACH controls affect the processing chain as follows.

| Control | Main stage affected | Purpose |
| --- | --- | --- |
| `ctrl_ud_comp_meth`, `ctrl_ud_iq_width`, `ctrl_fs_offset` | framer output compression | Configure PRACH BFP compression |
| `ctrl_en` | resync and sample acceptance | Enable active PRACH channel processing |
| `ctrl_rat` | control interpretation | Select numerology-dependent symbol mapping |
| `ctrl_bist` | resync path | Carried into PRACH front-end logic; detailed BIST behavior needs deeper review |
| `ctrl_bw` | DDC decimation chain | Select half-band bypass pattern and effective rate reduction |
| `ctrl_rfs_offset` | sync alignment | Shift PRACH timing relative to `sync_in` |
| `ctrl_ta3_offset` | control path | Present in CSR and channel control path; detailed downstream use should be reviewed further |
| `ctrl_static_c` | control interpretation | Select static PRACH schedule instead of live C-Plane control |
| `ctrl_subframe_inc`, `ctrl_subframe_id`, `ctrl_slot_id`, `ctrl_symbol_id` | control interpretation | Define static PRACH timing |
| `ctrl_time_offset`, `ctrl_cp_length` | control interpretation | Define static start sample timing |
| `ctrl_num_symbol`, `ctrl_freq_offset` | control interpretation | Define static PRACH format and DDC center frequency |
| `ctrl_sampling_offset` | control interpretation | Adjust capture start sample |
| `prach_msg0/1/2` status registers | reporting | Return observed PRACH C-Plane information |

### 8.8 PRACH implementation notes and current risks

The following details are worth carrying as explicit implementation notes in the spec.

- `s_prach_tready` is tied active at `prach_top`, so the design assumes incoming PRACH control messages can always be accepted.
- The PRACH chain supports both dynamic C-Plane-driven operation and static configuration-driven operation.
- The DDC path is more specialized than the normal UL path and includes a dedicated multistage decimation chain.
- PRACH capture is request-driven per antenna inside `prach_stream2block`, and arbitration is first-channel-first.
- `prach_framer_buffer` and `prach_framer` create a self-contained PRACH U-Plane packet stream before the final carrier arbitration step.
- `ctrl_ta3_offset` is exposed in the control interface, but its exact usage should be reviewed further in later documentation work.

## 9. Interface Summary

### 9.1 Control interface

LowPHY uses AXI-Lite slave interfaces for configuration and status access.

Depending on the packaging variant:

- `lowphy0` exposes one AXI-Lite slave interface
- `lowphy1` exposes three AXI-Lite slave interfaces

The reusable `lowphy_band` core exposes one AXI-Lite slave port with the following signals.

| Signal group | Direction | Width | Notes |
| --- | --- | --- | --- |
| `s_axi_aclk` | input | 1 | AXI-Lite clock |
| `s_axi_aresetn` | input | 1 | Active-low AXI-Lite reset |
| `s_axi_awaddr` | input | 16 | Write address |
| `s_axi_awprot` | input | 2 | Write protection attributes |
| `s_axi_awvalid` / `s_axi_awready` | input / output | 1 | Write address handshake |
| `s_axi_wdata` | input | 32 | Write data |
| `s_axi_wstrb` | input | 4 | Byte enable |
| `s_axi_wvalid` / `s_axi_wready` | input / output | 1 | Write data handshake |
| `s_axi_bresp` | output | 2 | Write response |
| `s_axi_bvalid` / `s_axi_bready` | output / input | 1 | Write response handshake |
| `s_axi_araddr` | input | 16 | Read address |
| `s_axi_arprot` | input | 2 | Read protection attributes |
| `s_axi_arvalid` / `s_axi_arready` | input / output | 1 | Read address handshake |
| `s_axi_rdata` | output | 32 | Read data |
| `s_axi_rresp` | output | 2 | Read response |
| `s_axi_rvalid` / `s_axi_rready` | output / input | 1 | Read data handshake |

### 9.2 O-RAN side interfaces

The LowPHY subsystem interfaces with O-RAN framer and deframer logic through the following grouped port sets on `lowphy_band`.

| Port group | Signals | Direction | Dimensionality | Function |
| --- | --- | --- | --- | --- |
| Early BID from deframer | `s_defm_ebid_tdata`, `s_defm_ebid_tvalid`, `s_defm_ebid_tlast`, `s_defm_ebid_tready` | input to LowPHY except `tready` | scalar stream | Early beam-ID sideband toward LowPHY |
| Early BID from framer | `s_fram_ebid_tdata`, `s_fram_ebid_tvalid`, `s_fram_ebid_tlast`, `s_fram_ebid_tready` | input to LowPHY except `tready` | scalar stream | Early beam-ID sideband toward LowPHY |
| PRACH C-Plane | `s_prach_*` | mostly input, `s_prach_tready` output | scalar message set | PRACH control-plane message accepted by `prach_top` |
| Framer U-Plane output | `m_fram_data_tdata`, `m_fram_data_tkeep`, `m_fram_data_tvalid`, `m_fram_data_tlast`, `m_fram_data_tready`, `m_fram_data_req` | mostly output from LowPHY | `[NUM_ANT]` | Uplink U-Plane generated by `puxch_top` |
| Framer BID sideband | `s_fram_bid_*` | mostly input, `s_fram_bid_ready` output | `[NUM_ANT]` | Beam-ID forwarding metadata associated with framer path |
| Framer unsolicited output | `m_fram_unsol_*` | mostly output from LowPHY | scalar stream | Reserved or unsupported framer-side output, currently tied inactive in RTL |
| Framer PRACH output | `m_fram_prach_*` | mostly output from LowPHY | scalar stream | PRACH U-Plane generated by `prach_top` |
| Deframer U-Plane input | `s_defm_data_tdata`, `s_defm_data_tkeep`, `s_defm_data_tvalid`, `s_defm_data_tlast`, `s_defm_data_tready`, `s_defm_data_tuser`, `s_defm_data_tdest` | mostly input to LowPHY | `[NUM_ANT]` | Downlink U-Plane received by `pdxch_top` |
| Deframer BID sideband | `s_defm_bid_*` | mostly input, `s_defm_bid_ready` output | `[NUM_ANT]` | Beam-ID forwarding metadata associated with deframer path |
| Parsed O-RAN header inputs | `s_ep_debug`, `s_t_header_offset_valid`, `s_runt_packet_len`, `s_rtc_pc_id`, `s_concat`, `s_messagetype`, `s_seqid`, `s_subseqid`, `s_ebit`, `s_payloadsize`, `s_packet_in_window`, `s_offset_in_symbol` | input | scalar set | Parsed packet-level metadata exposed at band level |
| Parsed radio app header inputs | `s_radio_app_head_valid`, `s_datadirection`, `s_numsections`, `s_sectiontype`, `s_filterindex`, `s_frameid`, `s_subframeid`, `s_slotid`, `s_symbolid`, `s_udcomphdr`, `s_timeoffset`, `s_framestructure`, `s_cplength` | input | scalar set | Parsed radio application header fields |
| Parsed section header inputs | `s_section_header_valid`, `s_numsymbol`, `s_numprbc`, `s_startprbc`, `s_sectionid`, `s_rb`, `s_remask`, `s_beamid15`, `s_freqoffset` | input | scalar set | Parsed section-level metadata |
| Raw extension inputs | `s_beamweights_*`, `s_raw_cplane_*`, `s_unsupport_ext_*` | input | scalar streams | Raw and extension payload visibility at band level |

### 9.3 Timing and synchronization

The design includes timing and synchronization groups summarized below.

| Port group | Signals | Direction | Dimensionality | Function |
| --- | --- | --- | --- | --- |
| UL timing | `s_ul_sym_num`, `s_ul_cta_sym_num`, `s_ul_update`, `s_ul_slot_update`, `s_ul_toggle` | input | `[NUM_CC]` | Uplink symbol timing distributed to `puxch_top` |
| DL timing | `s_dl_sym_num`, `s_dl_cta_sym_num`, `s_dl_update`, `s_dl_slot_update`, `s_dl_toggle` | input | `[NUM_CC]` | Downlink symbol timing distributed to `pdxch_top` |
| CC control timing | `s_cc_enable`, `s_cc_reload` | input | `[NUM_CC]` | Per-carrier enable and reload controls |
| Radio start status | `fram_radio_start_10ms`, `defm_radio_start_10ms` | output | `[NUM_CC]` | 10 ms radio start indications produced by uplink and downlink datapaths |
| RFS strobes | `fram_rfs_in`, `defm_rfs_in` | input | scalar | Mandatory timing strobes for framer and deframer domains |
| Readiness inputs | `fram_ready`, `defm_ready` | input | scalar | External readiness status at band level |

### 9.4 Radio sample interfaces

The LowPHY radio-domain interfaces are arrayed by component carrier and antenna.

| Port group | Signals | Direction | Dimensionality | Function |
| --- | --- | --- | --- | --- |
| Radio DL output | `m_axis_tdata`, `m_axis_tuser`, `m_axis_tlast`, `m_axis_tvalid`, `m_axis_tready` | mostly output from LowPHY | `[NUM_CC][NUM_ANT]` | Downlink sample stream produced by `pdxch_top` toward radio |
| Radio UL input | `s_axis_tdata`, `s_axis_tuser`, `s_axis_tlast`, `s_axis_tvalid`, `s_axis_tready` | mostly input to LowPHY | `[NUM_CC][NUM_ANT]` | Uplink sample stream consumed by `puxch_top` and `prach_top` |
| Radio clocking | `clk`, `rst` | input | scalar | Radio processing clock domain |

### 9.5 Clock, reset, and auxiliary interfaces

The remaining top-level `lowphy_band` ports are support and integration signals.

| Port group | Signals | Direction | Dimensionality | Function |
| --- | --- | --- | --- | --- |
| Internal bus clock | `internal_bus_clk` | input | scalar | O-RAN-side processing clock used by framer and deframer datapaths |
| O-RAN reset inputs | `defm_reset`, `fram_reset` | input | scalar | Reset sources synchronized inside `lowphy_band` |
| O-RAN reset status | `defm_reset_active`, `fram0_reset_active` | input | scalar | Reset activity indicators at top level |
| SSB data | `s_ssb_data_*` | mostly input, `s_ssb_data_tready` output | scalar stream | SSB-related data visibility at band level |
| SSB early BID | `s_ssb_ebid_*` | mostly input, `s_ssb_ebid_tready` output | scalar stream | Early beam-ID input for SSB |
| SSB BID forward | `s_ssb_bid_*` | mostly input, `s_ssb_bid_tready` output | scalar set | SSB beam forwarding sideband |

### 9.6 Port matrix by internal ownership

The following matrix summarizes which internal block primarily owns each external interface group.

| External group | `lowphy_regs` | `pdxch_top` | `puxch_top` | `prach_top` | `lowphy_band` glue |
| --- | --- | --- | --- | --- | --- |
| AXI-Lite slave | primary |  |  |  | routes CSR signals |
| Deframer U-Plane data |  | primary consumer |  |  | routes arrays |
| Framer U-Plane data |  |  | primary producer |  | routes arrays |
| PRACH C-Plane message |  |  |  | primary consumer | routes scalar message |
| PRACH U-Plane output |  |  |  | primary producer | routes stream |
| Radio DL sample output |  | primary producer |  |  | routes arrays |
| Radio UL sample input |  |  | primary consumer | primary consumer | shared fanout |
| UL timing |  |  | primary consumer |  | routes arrays |
| DL timing |  | primary consumer |  |  | routes arrays |
| PRACH status back to CSR | status sink |  |  | primary producer | routes status |
| Early BID and SSB aux ports |  |  |  |  | primary handling, mostly ready tie-offs |
| Reset synchronization |  | consumes synced reset | consumes synced reset | consumes synced reset | primary CDC logic |

## 10. Register Architecture

The integrated register map is defined in the LowPHY register definition and implemented by `lowphy_regs`.

The register map is organized into common, downlink, uplink, PRACH, and phase-compensation regions. Arrayed registers are placed as consecutive 32-bit words unless otherwise noted by the RDL.

### 10.1 Register map overview

| Region | Address range | Purpose |
| --- | --- | --- |
| Common | `0x000` to `0x008` | Version and scratch registers |
| Downlink control | `0x010` to `0x16C` | DL enable, format, offsets, compression, gain |
| Uplink control | `0x210` to `0x36C` | UL enable, format, offsets, compression, gain |
| PRACH control and inspect | `0x410` to `0x528` | PRACH enable, static config, inspect/status |
| DL phase compensation memory | `0x800` to `0x8FC` | 64 x 32-bit external memory |
| UL phase compensation memory | `0xA00` to `0xAFC` | 64 x 32-bit external memory |

### 10.2 Common registers

| Register | Address | Access | Description | Reset/default |
| --- | --- | --- | --- | --- |
| `version` | `0x000` | SW read-only | Design version register | `32'h20250106` |
| `scratch0` | `0x004` | RW | General-purpose scratch register 0 | `0x00000000` |
| `scratch1` | `0x008` | RW | General-purpose scratch register 1 | `0x00000000` |

### 10.3 Downlink control registers

| Register | Address | Access | Key fields | Reset/default |
| --- | --- | --- | --- | --- |
| `dl_en` | `0x010` | RW | `cc0[3:0]`, `cc1[7:4]`, `cc2[11:8]` | all `0x0` |
| `dl_rat` | `0x014` | RW | `cc0[1:0]`, `cc1[5:4]`, `cc2[9:8]` | all `0x0` |
| `dl_bist` | `0x018` | RW | `cc0[3:0]`, `cc1[7:4]`, `cc2[11:8]` | all `0x0` |
| `dl_bw` | `0x01C` | RW | `cc0[3:0]`, `cc1[7:4]`, `cc2[11:8]` | all `0x2` |
| `dl_nprb[0..2]` | `0x020`, `0x024`, `0x028` | RW | `val[8:0]` | `100` |
| `dl_rfs_offset[0..2]` | `0x030`, `0x034`, `0x038` | RW | `val[22:0]` | `0x0` |
| `dl_ud` | `0x058` | RW | `comp_meth[3:0]`, `iq_width[7:4]`, `fs_offset[11:8]` | `comp_meth=1`, `iq_width=9`, `fs_offset=0` |
| `dl_gain[cc][ant]` | `0x100` to `0x12C` | RW | `val[16:0]` | `0x4000` |

Downlink register intent:

- per-CC enable, RAT, BIST, bandwidth, PRB count, and RFS offset drive `pdxch_top`
- `dl_ud` controls deframer-side user-data compression settings
- `dl_gain[cc][ant]` provides gain control per carrier and antenna
- `dl_phase_comp` memory provides DL phase-compensation coefficient storage

### 10.4 Uplink control registers

| Register | Address | Access | Key fields | Reset/default |
| --- | --- | --- | --- | --- |
| `ul_en` | `0x210` | RW | `cc0[3:0]`, `cc1[7:4]`, `cc2[11:8]` | all `0x0` |
| `ul_rat` | `0x214` | RW | `cc0[1:0]`, `cc1[5:4]`, `cc2[9:8]` | all `0x0` |
| `ul_bist` | `0x218` | RW | `bist_cc0[3:0]`, `bist_cc1[7:4]`, `bist_cc2[11:8]` | all `0x0` |
| `ul_bw` | `0x21C` | RW | `cc0[3:0]`, `cc1[7:4]`, `cc2[11:8]` | all `0x2` |
| `ul_nprb[0..2]` | `0x220`, `0x224`, `0x228` | RW | `val[8:0]` | `100` |
| `ul_rfs_offset[0..2]` | `0x230`, `0x234`, `0x238` | RW | `val[22:0]` | `0x0` |
| `ul_ud` | `0x258` | RW | `fs_offset[11:8]`, `iq_width[7:4]`, `comp_meth[3:0]` | `comp_meth=1`, `iq_width=9`, `fs_offset=0` |
| `ul_gain[cc][ant]` | `0x300` to `0x32C` | RW | `val[16:0]` | `0x4000` |

Uplink register intent:

- per-CC enable, RAT, BIST, bandwidth, PRB count, and RFS offset drive `puxch_top`
- `ul_ud` controls framer-side user-data compression settings
- `ul_gain[cc][ant]` provides per-carrier, per-antenna gain control
- `ul_phase_comp` memory provides UL phase-compensation coefficient storage

### 10.5 PRACH control registers

| Register | Address | Access | Key fields | Reset/default |
| --- | --- | --- | --- | --- |
| `prach_en` | `0x410` | RW | `cc0[3:0]`, `cc1[7:4]`, `cc2[11:8]` | all `0x0` |
| `prach_format` | `0x414` | RW | `cc0[3:0]`, `cc1[7:4]`, `cc2[11:8]` | all `0x0` |
| `prach_rat` | `0x418` | RW | `cc0[1:0]`, `cc1[5:4]`, `cc2[9:8]` | all `0x0` |
| `prach_bist` | `0x41C` | RW | `bist_cc0`, `bist_cc1`, `bist_cc2`, `static_c_cc0`, `static_c_cc1`, `static_c_cc2` | all `0x0` |
| `prach_bw` | `0x420` | RW | `cc0[3:0]`, `cc1[7:4]`, `cc2[11:8]` | all `0x2` |
| `prach_rfs_offset[0..2]` | `0x430`, `0x434`, `0x438` | RW | `val[22:0]` | `0x0` |
| `prach_ta3_offset[0..2]` | `0x440`, `0x444`, `0x448` | RW | `val[22:0]` | `0x0` |
| `prach_ud` | `0x458` | RW | `fs_offset[11:8]`, `iq_width[7:4]`, `comp_meth[3:0]` | `comp_meth=1`, `iq_width=9`, `fs_offset=0` |
| `prach_cfg0[0..2]` | `0x460`, `0x464`, `0x468` | RW | `symbol_id[5:0]`, `slot_id[13:8]`, `subframe_id[19:16]`, `subframe_inc[23:20]` | all `0x0` |
| `prach_cfg1[0..2]` | `0x470`, `0x474`, `0x478` | RW | `time_offset[15:0]`, `cp_length[31:16]` | all `0x0` |
| `prach_cfg2[0..2]` | `0x480`, `0x484`, `0x488` | RW | `num_symbol[3:0]`, `freq_offset[27:4]` | all `0x0` |
| `prach_cfg3[0..2]` | `0x490`, `0x494`, `0x498` | RW | `sampling_offset[15:0]` | all `0x0` |

PRACH control intent:

- `prach_en`, `prach_format`, `prach_rat`, and `prach_bw` control the active PRACH mode per CC
- `prach_bist` includes both PRACH BIST control and static-configuration enable fields
- `prach_cfg0` to `prach_cfg3` provide static PRACH schedule and format information
- `prach_ud` controls PRACH framer compression settings

### 10.6 PRACH inspect and status registers

These registers are software read-only and hardware write-only in the RDL. They expose decoded or captured PRACH C-Plane information back to software.

| Register | Address | Access | Key fields | Description |
| --- | --- | --- | --- | --- |
| `prach_msg0[0..2]` | `0x500`, `0x504`, `0x508` | SW read-only | `symbol_id[5:0]`, `slot_id[13:8]`, `subframe_id[19:16]` | Captured PRACH timing identifiers |
| `prach_msg1[0..2]` | `0x510`, `0x514`, `0x518` | SW read-only | `time_offset[15:0]`, `cp_length[31:16]` | Captured PRACH timing offsets |
| `prach_msg2[0..2]` | `0x520`, `0x524`, `0x528` | SW read-only | `num_symbol[3:0]`, `freq_offset[27:4]` | Captured PRACH burst size and frequency offset |

### 10.7 Phase compensation memories

| Memory | Base address | Entries | Width | Access | Purpose |
| --- | --- | --- | --- | --- | --- |
| `dl_phase_comp` | `0x800` | 64 | 32 | RW external memory | DL phase compensation coefficients |
| `ul_phase_comp` | `0xA00` | 64 | 32 | RW external memory | UL phase compensation coefficients |

### 10.8 Register usage summary by datapath

| Datapath | Main control registers | Status returned |
| --- | --- | --- |
| Downlink `pdxch_top` | `dl_*`, `dl_phase_comp` | no dedicated status block visible in the integrated register definition |
| Uplink `puxch_top` | `ul_*`, `ul_phase_comp` | no dedicated status block visible in the integrated register definition |
| PRACH `prach_top` | `prach_*` | `prach_msg0`, `prach_msg1`, `prach_msg2` |

The register map chapter is now suitable as a working register summary, but a later revision should still add full bitfield-by-bitfield tables if a software-facing programming guide is needed.

## 11. Software Programming View

This chapter describes how software is expected to interact with the current LowPHY register map at a practical integration level.

The intent here is not to replace a future software API specification, but to provide a usable programming model for bring-up, configuration, and runtime inspection.

### 11.1 Programming model overview

At the current RTL level, software interacts with LowPHY through one AXI-Lite register map per `lowphy_band` instance.

The programming model is organized around three major datapath groups:

- downlink control through the `dl_*` register family
- uplink control through the `ul_*` register family
- PRACH control and inspection through the `prach_*` register family

In practical terms, software should treat each band instance as an independently configurable block with:

- common identification and scratch registers
- per-CC datapath controls
- per-CC and per-antenna gain controls
- phase-compensation coefficient memories
- PRACH status readback registers

### 11.2 Typical software responsibilities

For a normal bring-up flow, software is expected to:

1. verify register access using `version`, `scratch0`, and `scratch1`
2. program DL parameters for each active component carrier
3. program UL parameters for each active component carrier
4. program PRACH parameters for each active component carrier if PRACH is used
5. populate DL and UL phase-compensation memories if non-default correction is required
6. enable the desired carriers and paths
7. monitor PRACH inspect/status registers during runtime or debug

### 11.3 Recommended initialization sequence

The following sequence is a practical software-oriented initialization order derived from the current register organization.

| Step | Action | Main registers |
| --- | --- | --- |
| 1 | Read back hardware version | `version` |
| 2 | Verify read/write path | `scratch0`, `scratch1` |
| 3 | Program DL format and bandwidth settings | `dl_rat`, `dl_bw`, `dl_nprb`, `dl_rfs_offset`, `dl_ud` |
| 4 | Program DL gain and optional phase correction | `dl_gain[*][*]`, `dl_phase_comp` |
| 5 | Program UL format and bandwidth settings | `ul_rat`, `ul_bw`, `ul_nprb`, `ul_rfs_offset`, `ul_ud` |
| 6 | Program UL gain and optional phase correction | `ul_gain[*][*]`, `ul_phase_comp` |
| 7 | Program PRACH static or semi-static settings if used | `prach_rat`, `prach_bw`, `prach_rfs_offset`, `prach_ta3_offset`, `prach_ud`, `prach_cfg0..3` |
| 8 | Configure BIST or static-C options if needed | `dl_bist`, `ul_bist`, `prach_bist` |
| 9 | Enable active datapaths | `dl_en`, `ul_en`, `prach_en` |
| 10 | Monitor runtime PRACH activity | `prach_msg0..2` |

### 11.4 Common software access pattern

The current register map uses a repeated pattern across DL, UL, and PRACH.

Software can generally interpret the control model as:

- one register for per-CC enable
- one register for per-CC RAT or numerology selection
- one register for per-CC BIST or special-mode control
- one register for per-CC bandwidth selection
- one array for per-CC PRB count or offsets
- one register for compression configuration
- one 2D array for per-CC and per-antenna gain

This repeated structure makes it practical to implement software helpers using a carrier-indexed configuration object.

### 11.5 Downlink software view

For downlink configuration, software should treat the following fields as the primary per-carrier setup set.

| Function | Registers | Notes |
| --- | --- | --- |
| Enable DL per CC | `dl_en` | Each CC uses a 4-bit field |
| Select RAT | `dl_rat` | Encodes LTE, NR 15 kHz, or NR 30 kHz behavior |
| Configure BIST | `dl_bist` | Enables DL built-in test behavior |
| Set bandwidth | `dl_bw` | Drives FFT sizing and mapping behavior |
| Set PRB count | `dl_nprb[cc]` | One entry per CC |
| Set radio-start offset | `dl_rfs_offset[cc]` | Relative timing adjustment |
| Configure decompression | `dl_ud` | Compression method, IQ width, FS offset |
| Set output gain | `dl_gain[cc][ant]` | One entry per CC and antenna |
| Program phase correction | `dl_phase_comp` | 64-entry external memory |

Downlink software notes:

- `dl_ud` should match the deframer-side payload encoding
- `dl_gain` defaults to `0x4000`, corresponding to nominal gain in the current design convention
- `dl_phase_comp` is optional for basic bring-up, but required if symbol-based phase correction is needed

### 11.6 Uplink software view

For uplink configuration, software should use the analogous `ul_*` register family.

| Function | Registers | Notes |
| --- | --- | --- |
| Enable UL per CC | `ul_en` | Each CC uses a 4-bit field |
| Select RAT | `ul_rat` | Controls numerology-dependent FFT behavior |
| Configure BIST | `ul_bist` | Enables UL built-in test behavior |
| Set bandwidth | `ul_bw` | Drives FFT sizing and buffer behavior |
| Set PRB count | `ul_nprb[cc]` | One entry per CC |
| Set radio-start offset | `ul_rfs_offset[cc]` | Relative timing adjustment |
| Configure framer compression | `ul_ud` | Compression method, IQ width, FS offset |
| Set input gain | `ul_gain[cc][ant]` | One entry per CC and antenna |
| Program phase correction | `ul_phase_comp` | 64-entry external memory |

Uplink software notes:

- `ul_ud` should match the expected framer-side packet encoding
- UL data output is request-driven on the framer side, so software configuration alone does not force packet generation without downstream requests
- UL gain and phase compensation should be programmed consistently with the radio calibration strategy

### 11.7 PRACH software view

PRACH programming is more control-plane oriented than the normal UL path.

Software can operate PRACH in two main modes:

- dynamic mode, where live PRACH C-Plane messages drive the processing
- static mode, where `prach_cfg0..3` and `prach_bist.static_c_*` provide fixed PRACH parameters

Primary PRACH software-visible controls are:

| Function | Registers | Notes |
| --- | --- | --- |
| Enable PRACH per CC | `prach_en` | Each CC uses a 4-bit field |
| Select PRACH format | `prach_format` | Format field per CC |
| Select RAT | `prach_rat` | Controls numerology-dependent behavior |
| Configure static mode and BIST | `prach_bist` | Includes both BIST and `static_c` fields |
| Set bandwidth | `prach_bw` | Affects decimation path selection |
| Set timing offsets | `prach_rfs_offset[cc]`, `prach_ta3_offset[cc]` | PRACH timing alignment controls |
| Configure PRACH compression | `prach_ud` | Compression settings for PRACH framer output |
| Configure static timing | `prach_cfg0[cc]`, `prach_cfg1[cc]`, `prach_cfg2[cc]`, `prach_cfg3[cc]` | Static PRACH schedule and frequency settings |
| Inspect received messages | `prach_msg0[cc]`, `prach_msg1[cc]`, `prach_msg2[cc]` | Read-only decoded C-Plane values |

PRACH software notes:

- in static mode, software must program a coherent set of timing and frequency values across `prach_cfg0..3`
- in dynamic mode, `prach_msg0..2` are useful for confirming that the hardware received and interpreted the expected C-Plane message
- `prach_ta3_offset` is present in the programming model and should be treated as part of the PRACH timing calibration set even though its detailed downstream effect should still be reviewed further

### 11.8 Phase-compensation memory programming

Both DL and UL expose 64-entry external memories for phase compensation.

Software should treat these memories as indexed coefficient tables addressed by the hardware according to carrier and symbol context.

Practical guidance:

- initialize all entries to the default value if no custom correction is needed
- update the entire relevant table before enabling the corresponding datapath when possible
- avoid partial runtime updates unless the system-level software can guarantee a safe update window

### 11.9 Example bring-up checklist

The following checklist can be used as a practical first-pass software sequence.

1. Read `version` and confirm the expected RTL build.
2. Write and read back `scratch0` and `scratch1`.
3. Program `dl_rat`, `dl_bw`, `dl_nprb`, `dl_rfs_offset`, `dl_ud`, and `dl_gain`.
4. Program `ul_rat`, `ul_bw`, `ul_nprb`, `ul_rfs_offset`, `ul_ud`, and `ul_gain`.
5. Program `prach_rat`, `prach_bw`, `prach_rfs_offset`, `prach_ud`, and, if used, `prach_cfg0..3`.
6. Load `dl_phase_comp` and `ul_phase_comp` if phase correction is required.
7. Set `dl_en`, `ul_en`, and `prach_en` for the desired carriers.
8. Observe runtime behavior and read `prach_msg0..2` during PRACH verification.

### 11.10 Software limitations and assumptions

Based on the current RTL and register map, software should assume the following.

- There is no separate interrupt or event register block visible in the integrated register definition.
- PRACH runtime visibility is provided through inspect/status registers rather than an explicit event queue.
- BIST control exists, but full software procedures for BIST execution should be validated with testbench or lab behavior before being treated as production-ready.
- Some datapath behavior depends on always-ready assumptions on the streaming boundaries, so software should configure downstream blocks consistently with those expectations.

## 12. Clock and Reset Architecture

The current RTL uses multiple clock and reset domains.

Main domains visible at integration level:

- AXI-Lite control clock domain: `s_axi_aclk`
- internal O-RAN bus clock domain: `internal_bus_clk`
- radio sample clock domain: `clk`

Main reset sources visible at integration level:

- AXI-Lite reset: `s_axi_aresetn`
- radio path reset: `rst`
- framer reset input: `fram_reset`
- deframer reset input: `defm_reset`

In `lowphy_band`, framer and deframer reset inputs are synchronized into the internal bus clock domain through `xpm_cdc_single` instances before being used by the integrated datapaths.

## 13. Packaging Variants

### 13.1 `lowphy0`

Intended as a smaller packaging variant for one band-level instance.

Observed characteristics:

- one `lowphy_band` instance
- three CC timing groups
- four antenna-side framer and deframer data ports
- one PRACH output stream

### 13.2 `lowphy1`

Intended as a larger packaging variant with multiple band partitions.

Observed characteristics:

- three `lowphy_band` instances
- three AXI-Lite control interfaces
- timing groups split across `s0` to `s8`
- antenna-side framer and deframer data ports split across multiple band instances
- multiple PRACH and unsolicited outputs, one per instantiated band block

### 13.3 Packaging comparison overview

The current code base uses two main packaging styles around the shared `lowphy_band` core.

`lowphy0` is the simpler one-band packaging variant.

`lowphy1` is a composed multi-band or multi-partition packaging variant that aggregates three `lowphy_band` instances behind one larger top-level interface set.

At a high level:

- `lowphy0` prioritizes a direct 1:1 mapping between the external port set and one reusable core instance
- `lowphy1` prioritizes capacity scaling by partitioning antennas and timing groups across multiple reusable core instances

### 13.4 Structural comparison table

| Aspect | `lowphy0` | `lowphy1` |
| --- | --- | --- |
| Core composition | one `lowphy_band` instance | three `lowphy_band` instances |
| Local parameters | `NUM_CC=3`, `NUM_ANT=4`, `HALF_BLOCK=0` | `NUM_CC=3`, `NUM_ANT=8`, `HALF_BLOCK=1` at top level, then partitioned per instance |
| AXI-Lite control ports | one slave interface | three slave interfaces (`S0_AXI`, `S1_AXI`, `S2_AXI`) |
| CC timing groups | one set covering `s0..s2` | three sets covering `s0..s2`, `s3..s5`, `s6..s8` |
| Antenna-side O-RAN data ports | four framer and four deframer antenna ports | eight framer and eight deframer antenna ports split across three band instances |
| PRACH outputs | one PRACH stream | three PRACH streams, one per band instance |
| Unsolicited framer outputs | one output group | three output groups, one per band instance |
| Radio-side presentation | one `NUM_CC x NUM_ANT` array passed directly to the core | partitioned internal arrays combined into wide top-level radio buses |
| Packaging intent | compact single-band top | larger aggregated top with internal partitioning |

### 13.5 `lowphy0` composition detail

`lowphy0` is structurally straightforward.

Current implementation characteristics:

- one `lowphy_band` instance named `u_b0`
- one AXI-Lite slave interface connected directly to that instance
- one PRACH C-Plane port group connected directly to that instance
- three CC timing groups mapped directly into the instance
- four antenna-side framer ports mapped directly into the instance
- four antenna-side deframer ports mapped directly into the instance
- one unsolicited framer stream output
- one PRACH framer stream output

This version is easier to reason about because almost every external port group maps directly to the corresponding port group on the underlying `lowphy_band` core.

### 13.6 `lowphy1` composition detail

`lowphy1` is a hierarchical packaging layer that partitions the overall external interface set across three `lowphy_band` instances.

The instantiated cores are:

- `u_b0` with `NUM_ANT = NumAnt / 2`
- `u_b1` with `NUM_ANT = NumAnt / 4`, `CC_ID = 0`, `ANT_ID = 0`
- `u_b2` with `NUM_ANT = NumAnt / 4`, `CC_ID = 0`, `ANT_ID = 2`

Observed top-level decomposition:

- `u_b0` handles a 4-antenna slice
- `u_b1` handles a 2-antenna slice
- `u_b2` handles a second 2-antenna slice

Together these add up to the top-level `NumAnt = 8` organization.

### 13.7 Timing-group mapping in `lowphy1`

The three band instances in `lowphy1` are mapped to distinct timing groups.

| Instance | AXI-Lite port | Timing groups | Antenna slice |
| --- | --- | --- | --- |
| `u_b0` | `S0_AXI` | `s0`, `s1`, `s2` | 4 antennas |
| `u_b1` | `S1_AXI` | `s3`, `s4`, `s5` | 2 antennas |
| `u_b2` | `S2_AXI` | `s6`, `s7`, `s8` | 2 antennas |

This means `lowphy1` is not just a larger flat instance; it is an explicit aggregation of three separately controlled band-level processing partitions.

### 13.8 O-RAN-side antenna mapping comparison

The O-RAN framer and deframer data interfaces differ significantly between the two package variants.

For `lowphy0`:

- framer antenna outputs use `m000` to `m003`
- deframer antenna inputs use `s000` to `s003`

For `lowphy1`:

- `u_b0` uses antenna-facing O-RAN streams `0` to `3`
- `u_b1` uses antenna-facing O-RAN streams `4` to `5`
- `u_b2` uses antenna-facing O-RAN streams `6` to `7`

So the `lowphy1` package is effectively built by concatenating three antenna groups into one larger top-level O-RAN interface set.

### 13.9 Radio-side packaging comparison

The radio-side presentation also differs between the two variants.

For `lowphy0`:

- the internal `m_axis_*` and `s_axis_*` arrays from the one `lowphy_band` instance are exposed naturally as the only radio interface set

For `lowphy1`:

- radio streams are internally partitioned into three groups:
  - a `3 x 4` group for `u_b0`
  - a `3 x 2` group for `u_b1`
  - a `3 x 2` group for `u_b2`
- the top-level module then presents these through wide packed radio buses:
  - `m_dl_axis_tdata[767:0]`
  - `s_ul_axis_tdata[767:0]`
  - associated shared user, last, valid, and ready signals

This indicates `lowphy1` is intended for a different top-level integration style than `lowphy0`, likely one where multiple radio lanes are already aggregated outside the LowPHY core boundary.

### 13.10 PRACH and auxiliary output comparison

The packaging of PRACH and auxiliary outputs also differs.

| Output type | `lowphy0` | `lowphy1` |
| --- | --- | --- |
| PRACH stream outputs | one | three |
| Unsolicited framer outputs | one | three |
| SSB-related auxiliary inputs | one set | one shared set reused across the three internal instances |
| Early BID ports | one shared set | one shared set reused across the three internal instances |

This reuse of shared auxiliary inputs in `lowphy1` is important from a system-integration perspective because not every external interface is partitioned the same way as the timing and antenna data paths.

### 13.11 Software and system implications

The two packaging variants imply different software and system-integration expectations.

For `lowphy0`:

- one register map instance controls the full packaged block
- one timing group set is sufficient
- one PRACH output stream must be handled by the surrounding system

For `lowphy1`:

- software must manage three independent AXI-Lite control interfaces
- timing generators must provide three independent timing-group bundles
- the surrounding system must handle three PRACH outputs and three unsolicited outputs
- antenna and radio aggregation outside the band-level core is more complex

### 13.12 Selection guidance

Based on the current RTL structure alone:

- choose `lowphy0` when a single `lowphy_band` instance with four antenna-side O-RAN ports is sufficient
- choose `lowphy1` when the design needs the larger eight-antenna aggregated package and can support three separate control and timing partitions

This conclusion is based strictly on the present RTL structure and port organization. Final product selection should still be confirmed at the system-integration level.

## 14. Referenced Design Elements

- `lowphy_band`
- `lowphy0`
- `lowphy1`
- `lowphy0_wrapper`
- `lowphy1_wrapper`
- `lowphy_regs`
- `pdxch`
- `puxch`
- `prach`
