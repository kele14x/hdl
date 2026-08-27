# Cocotb verification agents

Reusable cocotb protocol agents, transaction models, and reference helpers
live in the installed `hdl_tools` package. `common` contains synthesizable RTL
and its module tests only.

The helpers use a small set of UVM-like concepts without a factory or phase
system.

| UVM concept | cocotb component |
| --- | --- |
| sequence item | `AxiLiteTransaction`, `AxisFrame`, `AxisBeat` |
| driver | `AxiLiteMasterDriver`, `AxisSourceDriver`, `AxisSinkDriver` |
| monitor | `AxiLiteMonitor`, `AxisMonitor` |
| analysis port | `AnalysisPort` |
| agent | `AxiLiteAgent`, `AxisAgent` |
| active/passive setting | `AgentMode.ACTIVE`, `AgentMode.PASSIVE` |

Drivers only control interface signals. Monitors never drive signals and
publish completed transactions through analysis ports. Reference models and
scoreboards subscribe to those ports, keeping protocol timing separate from
functional checking.

## AXI4-Lite

```python
from hdl_tools.axi4lite import AxiLiteAgent, AxiLiteAgentConfig

agent = AxiLiteAgent(
    dut,
    AxiLiteAgentConfig(
        prefix="s_axi",
        clock="s_axi_aclk",
        reset="s_axi_aresetn",
    ),
)
await agent.start()

await agent.write(0x04, 0x12345678)
assert await agent.read(0x04) == 0x12345678
observed_transaction = await agent.monitor.transactions.get()
```

The monitor independently queues AW, W, and AR handshakes, then pairs them
with B and R responses. This preserves legal AXI4-Lite address/data ordering.

`hdl_tools.axi4lite` also provides per-channel agents (`ARAgent`, `AWAgent`,
`WAgent`, `RAgent`, `BAgent`) with vector sequences for channel-level
stimulus, all built on the valid/ready primitives in `hdl_tools.handshake`.

## AXI-Stream

```python
from hdl_tools.axis import (
    AxisAgent,
    AxisAgentConfig,
    AxisFrame,
    AxisRole,
)

source = AxisAgent(
    dut,
    AxisAgentConfig(prefix="s_axis", clock="aclk", role=AxisRole.SOURCE),
)
sink = AxisAgent(
    dut,
    AxisAgentConfig(prefix="m_axis", clock="aclk", role=AxisRole.SINK),
    ready_policy=lambda cycle: cycle % 3 != 0,
)
await source.start()
await sink.start()

await source.send(AxisFrame.from_words([1, 2, 3]))
actual = await sink.receive()
```

`AxisMonitor.beats` publishes every accepted beat, while
`AxisMonitor.frames` publishes TLAST-delimited frames. Interfaces without
TLAST publish each beat as a one-beat frame.

## Register model

`RegisterBlock` adds a UVM-RAL-style layer above a bus agent. A protocol
adapter performs frontdoor accesses, while `RegisterPredictor` subscribes to
the bus monitor and updates mirrors for accesses made outside the model.

```python
from hdl_tools.registers import AxiLiteRegisterAdapter, RegisterPredictor

registers.bind(AxiLiteRegisterAdapter(axi_agent))
predictor = RegisterPredictor(registers, axi_agent.monitor.transactions)

await registers.check_reset()
await registers.scratch0.val.write(0x12345678)
await registers.scratch0.mirror(check=True)
```

Fields define reset values, access policy, volatility, and compare/write
masks. Register definitions remain protocol-independent.

## Native FIFO

`FifoWriteAgent` and `FifoReadAgent` support the repository's native
write-enable/full and read-enable/empty interfaces, including independent
clock domains. Drivers add randomized enable gaps, while passive monitors
publish every accepted `FifoTransfer` through an analysis port.

```python
from hdl_tools.fifo import FifoReadAgent, FifoReadBus, FifoWriteAgent, FifoWriteBus

writer = FifoWriteAgent(FifoWriteBus(dut.wr_clk, dut.wr_en, dut.din, dut.full))
reader = FifoReadAgent(FifoReadBus(dut.rd_clk, dut.rd_en, dut.dout, dut.empty))
await writer.start()
await reader.start()
```

`FifoTestbench`, `directed_sequences`, and `random_sequences` provide the
shared environment used by the FIFO regression tests.

## Radio timing

`RadioTimingAgent` normalizes frame, slot, and multi-numerology symbol strobes
into hierarchical `RadioTimingEvent` transactions. Its active mode can also
drive an external synchronization pulse.

```python
from hdl_tools.timing import RadioTimingAgent, RadioTimingAgentConfig

timing = RadioTimingAgent(
    dut,
    RadioTimingAgentConfig(numerology=1, slots_per_frame=20),
)
await timing.start()
await timing.pulse_sync()
frame = await timing.wait_frame()
symbol = await timing.wait_symbol()
```

Separate frame, slot, symbol, and combined analysis ports let downstream
scoreboards subscribe only to the boundaries they consume.

## Ethernet and eCPRI packets

`AxisCodecAgent` composes a byte-level codec with an existing `AxisAgent`.
The AXIS layer owns handshake/backpressure, while `EthernetCodec` and
`EcpriCodec` own header serialization and parsing.

```python
from hdl_tools.packets import AxisCodecAgent, EcpriCodec

packets = AxisCodecAgent(axis_agent, EcpriCodec())
await packets.start()
await packets.send(ecpri_packet)
decoded = await packets.receive()
```

The conversion honors little-endian AXIS byte lanes and `TKEEP`, works at any
byte-multiple data width, and publishes decoded packets through an analysis
port. VLAN Ethernet, generic eCPRI, IQ/RTC, ODM, and concatenated messages are
supported.
