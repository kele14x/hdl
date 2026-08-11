"""Ethernet/eCPRI codecs layered on the generic AXI-Stream agent."""

from __future__ import annotations

from dataclasses import dataclass, field

from hdl_tools.axis import AxisAgent, AxisBeat, AxisFrame

from .base import AnalysisPort

__all__ = [
    "AxisCodecAgent",
    "EcpriCodec",
    "EcpriCommonHeader",
    "EcpriIqMessage",
    "EcpriIqcMessage",
    "EcpriMessage",
    "EcpriOdmMessage",
    "EcpriPacket",
    "EthernetCodec",
    "EthernetHeader",
    "EthernetPacket",
    "PacketCodecError",
    "RawBytesCodec",
    "axis_frame_from_bytes",
    "axis_frame_to_bytes",
]


class PacketCodecError(ValueError):
    """Raised when a packet cannot be serialized or parsed."""


def _uint(value, bits, name):
    value = int(value)
    if not 0 <= value < (1 << bits):
        raise PacketCodecError(f"{name} does not fit in {bits} bits: {value}")
    return value


@dataclass
class EthernetHeader:
    dest_mac: int = 0
    src_mac: int = 0
    ethertype: int = 0
    with_vlan: bool = False
    vlan_tag: int = 0
    vlan_tpid: int = 0x8100

    def __len__(self):
        return 18 if self.with_vlan else 14

    def __bytes__(self):
        data = _uint(self.dest_mac, 48, "destination MAC").to_bytes(6, "big")
        data += _uint(self.src_mac, 48, "source MAC").to_bytes(6, "big")
        if self.with_vlan:
            data += _uint(self.vlan_tpid, 16, "VLAN TPID").to_bytes(2, "big")
            data += _uint(self.vlan_tag, 16, "VLAN tag").to_bytes(2, "big")
        return data + _uint(self.ethertype, 16, "EtherType").to_bytes(2, "big")

    @classmethod
    def decode_from(cls, data):
        data = bytes(data)
        if len(data) < 14:
            raise PacketCodecError("Ethernet frame is shorter than 14 bytes")
        dest_mac = int.from_bytes(data[0:6], "big")
        src_mac = int.from_bytes(data[6:12], "big")
        type_or_tpid = int.from_bytes(data[12:14], "big")
        if type_or_tpid in {0x8100, 0x88A8}:
            if len(data) < 18:
                raise PacketCodecError("VLAN Ethernet frame is shorter than 18 bytes")
            return (
                cls(
                    dest_mac=dest_mac,
                    src_mac=src_mac,
                    ethertype=int.from_bytes(data[16:18], "big"),
                    with_vlan=True,
                    vlan_tag=int.from_bytes(data[14:16], "big"),
                    vlan_tpid=type_or_tpid,
                ),
                18,
            )
        return cls(dest_mac=dest_mac, src_mac=src_mac, ethertype=type_or_tpid), 14


@dataclass
class EthernetPacket:
    hdr: EthernetHeader = field(default_factory=EthernetHeader)
    payload: bytes = b""

    def __len__(self):
        return len(self.hdr) + len(self.payload)

    def __bytes__(self):
        return bytes(self.hdr) + bytes(self.payload)


class EthernetCodec:
    def encode(self, packet):
        return bytes(packet)

    def decode(self, data):
        data = bytes(data)
        header, offset = EthernetHeader.decode_from(data)
        return EthernetPacket(header, data[offset:])


@dataclass
class EcpriCommonHeader:
    version: int = 1
    reserved: int = 0
    concat: int = 0
    message_type: int = 0
    payload_size: int | None = None

    def __len__(self):
        return 4

    def encode(self, payload_size=None):
        size = self.payload_size if payload_size is None else payload_size
        size = 0 if size is None else size
        word = (
            (_uint(self.version, 4, "eCPRI version") << 28)
            | (_uint(self.reserved, 3, "eCPRI reserved") << 25)
            | (_uint(self.concat, 1, "eCPRI concat") << 24)
            | (_uint(self.message_type, 8, "eCPRI message type") << 16)
            | _uint(size, 16, "eCPRI payload size")
        )
        return word.to_bytes(4, "big")

    def __bytes__(self):
        return self.encode()

    @classmethod
    def decode(cls, data):
        data = bytes(data)
        if len(data) < 4:
            raise PacketCodecError("eCPRI common header is shorter than 4 bytes")
        word = int.from_bytes(data[:4], "big")
        return cls(
            version=(word >> 28) & 0xF,
            reserved=(word >> 25) & 0x7,
            concat=(word >> 24) & 0x1,
            message_type=(word >> 16) & 0xFF,
            payload_size=word & 0xFFFF,
        )


@dataclass
class EcpriMessage:
    common_hdr: EcpriCommonHeader = field(default_factory=EcpriCommonHeader)
    payload: bytes = b""

    def _body(self):
        return bytes(self.payload)

    def __len__(self):
        raw_length = 4 + len(self._body())
        return (raw_length + 3) // 4 * 4 if self.common_hdr.concat else raw_length

    def __bytes__(self):
        body = self._body()
        size = len(body) if self.common_hdr.payload_size is None else None
        data = self.common_hdr.encode(size) + body
        if self.common_hdr.concat:
            data += bytes((-len(data)) % 4)
        return data


@dataclass
class EcpriIqMessage(EcpriMessage):
    pc_id: int = 0
    seq_id: int = 0
    e_bit: int = 0
    subseq_id: int = 0

    def _body(self):
        return (
            _uint(self.pc_id, 16, "eCPRI PC_ID").to_bytes(2, "big")
            + bytes([_uint(self.seq_id, 8, "eCPRI sequence ID")])
            + bytes(
                [
                    (_uint(self.e_bit, 1, "eCPRI E bit") << 7)
                    | _uint(self.subseq_id, 7, "eCPRI subsequence ID")
                ]
            )
            + bytes(self.payload)
        )


@dataclass
class EcpriIqcMessage(EcpriMessage):
    rtc_id: int = 0
    seq_id: int = 0
    e_bit: int = 0
    subseq_id: int = 0

    def _body(self):
        return (
            _uint(self.rtc_id, 16, "eCPRI RTC_ID").to_bytes(2, "big")
            + bytes([_uint(self.seq_id, 8, "eCPRI sequence ID")])
            + bytes(
                [
                    (_uint(self.e_bit, 1, "eCPRI E bit") << 7)
                    | _uint(self.subseq_id, 7, "eCPRI subsequence ID")
                ]
            )
            + bytes(self.payload)
        )


@dataclass
class EcpriOdmMessage(EcpriMessage):
    measurement_id: int = 0
    action_type: int = 0
    timestamp: int = 0
    compensation: int = 0
    dummy: bytes = b""

    def _body(self):
        return (
            bytes([_uint(self.measurement_id, 8, "measurement ID")])
            + bytes([_uint(self.action_type, 8, "action type")])
            + _uint(self.timestamp, 80, "ODM timestamp").to_bytes(10, "big")
            + _uint(self.compensation, 64, "ODM compensation").to_bytes(8, "big")
            + bytes(self.dummy)
        )


@dataclass
class EcpriPacket:
    ethernet_hdr: EthernetHeader = field(default_factory=EthernetHeader)
    messages: list[EcpriMessage] = field(default_factory=list)
    padding: bytes = b""

    def __len__(self):
        return len(bytes(self))

    def __bytes__(self):
        return (
            bytes(self.ethernet_hdr)
            + b"".join(bytes(message) for message in self.messages)
            + bytes(self.padding)
        )


class EcpriCodec:
    """Encode and decode Ethernet-encapsulated eCPRI messages."""

    def encode(self, packet):
        return bytes(packet)

    @staticmethod
    def _decode_message(common, body):
        if common.message_type in {0, 1}:
            if len(body) < 4:
                raise PacketCodecError(
                    "eCPRI IQ/RTC message payload is shorter than 4 bytes"
                )
            identifier = int.from_bytes(body[0:2], "big")
            sequence = body[2]
            e_bit = body[3] >> 7
            subsequence = body[3] & 0x7F
            if common.message_type == 0:
                return EcpriIqMessage(
                    common_hdr=common,
                    payload=body[4:],
                    pc_id=identifier,
                    seq_id=sequence,
                    e_bit=e_bit,
                    subseq_id=subsequence,
                )
            return EcpriIqcMessage(
                common_hdr=common,
                payload=body[4:],
                rtc_id=identifier,
                seq_id=sequence,
                e_bit=e_bit,
                subseq_id=subsequence,
            )
        if common.message_type == 5:
            if len(body) < 20:
                raise PacketCodecError(
                    "eCPRI ODM message payload is shorter than 20 bytes"
                )
            return EcpriOdmMessage(
                common_hdr=common,
                measurement_id=body[0],
                action_type=body[1],
                timestamp=int.from_bytes(body[2:12], "big"),
                compensation=int.from_bytes(body[12:20], "big"),
                dummy=body[20:],
            )
        return EcpriMessage(common_hdr=common, payload=body)

    def decode(self, data):
        data = bytes(data)
        ethernet_header, offset = EthernetHeader.decode_from(data)
        messages = []
        while len(data) - offset >= 4:
            start = offset
            common = EcpriCommonHeader.decode(data[offset : offset + 4])
            offset += 4
            end = offset + int(common.payload_size or 0)
            if end > len(data):
                raise PacketCodecError(
                    f"eCPRI message declares {common.payload_size} payload bytes, "
                    f"only {len(data) - offset} remain"
                )
            messages.append(self._decode_message(common, data[offset:end]))
            offset = end
            if not common.concat:
                break
            offset = start + ((offset - start + 3) // 4 * 4)
        return EcpriPacket(ethernet_header, messages, data[offset:])


class RawBytesCodec:
    def encode(self, packet):
        return bytes(packet)

    def decode(self, data):
        return bytes(data)


def axis_frame_from_bytes(data, byte_lanes, *, users=None, dest=None):
    data = bytes(data)
    if not data:
        raise PacketCodecError("cannot serialize an empty packet to AXI-Stream")
    if byte_lanes <= 0:
        raise ValueError("byte_lanes must be positive")
    beat_count = (len(data) + byte_lanes - 1) // byte_lanes
    if users is None:
        users = [None] * beat_count
    elif isinstance(users, int):
        users = [users] * beat_count
    else:
        users = list(users)
    if len(users) != beat_count:
        raise ValueError("users must provide one value per AXI-Stream beat")

    beats = []
    for index in range(beat_count):
        chunk = data[index * byte_lanes : (index + 1) * byte_lanes]
        beats.append(
            AxisBeat(
                data=int.from_bytes(chunk, "little"),
                keep=(1 << len(chunk)) - 1,
                user=users[index],
                dest=dest,
                last=index == beat_count - 1,
            )
        )
    return AxisFrame(beats)


def axis_frame_to_bytes(frame, byte_lanes):
    data = bytearray()
    for beat in frame.beats:
        keep = (1 << byte_lanes) - 1 if beat.keep is None else int(beat.keep)
        for lane in range(byte_lanes):
            if keep & (1 << lane):
                data.append((int(beat.data) >> (8 * lane)) & 0xFF)
    return bytes(data)


class AxisCodecAgent:
    """Packet codec layer composed over an existing :class:`AxisAgent`."""

    def __init__(self, axis_agent: AxisAgent, codec, byte_lanes=None):
        self.axis = axis_agent
        self.codec = codec
        self.byte_lanes = byte_lanes or len(axis_agent.monitor._sig("tdata")) // 8
        self.packets = AnalysisPort()
        self._started = False

    def _observe_frame(self, frame):
        packet = self.codec.decode(axis_frame_to_bytes(frame, self.byte_lanes))
        self.packets.write(packet)

    async def start(self):
        if self._started:
            return
        self.axis.monitor.frames.subscribe(self._observe_frame)
        await self.axis.start()
        self._started = True

    def stop(self):
        if self._started:
            self.axis.monitor.frames.unsubscribe(self._observe_frame)
            self.axis.stop()
            self._started = False

    async def send(self, packet, *, users=None, dest=None, gap=None):
        frame = axis_frame_from_bytes(
            self.codec.encode(packet),
            self.byte_lanes,
            users=users,
            dest=dest,
        )
        return await self.axis.send(frame, gap)

    async def receive(self):
        return await self.packets.get()
