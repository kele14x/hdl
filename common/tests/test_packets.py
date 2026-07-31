from common.tb.axis import AxisBeat, AxisFrame
from common.tb.packets import (
    EcpriCodec,
    EcpriCommonHeader,
    EcpriIqMessage,
    EcpriOdmMessage,
    EcpriPacket,
    EthernetCodec,
    EthernetHeader,
    EthernetPacket,
    axis_frame_from_bytes,
    axis_frame_to_bytes,
)


def test_ethernet_vlan_round_trip():
    packet = EthernetPacket(
        hdr=EthernetHeader(
            dest_mac=0x001122334455,
            src_mac=0xAABBCCDDEEFF,
            ethertype=0xAEFE,
            with_vlan=True,
            vlan_tag=0x7123,
        ),
        payload=bytes(range(31)),
    )
    decoded = EthernetCodec().decode(bytes(packet))
    assert decoded == packet


def test_ecpri_concatenated_messages_round_trip():
    iq = EcpriIqMessage(
        common_hdr=EcpriCommonHeader(concat=1, message_type=0),
        pc_id=0x1234,
        seq_id=0x56,
        e_bit=1,
        subseq_id=0x12,
        payload=b"iq-payload",
    )
    odm = EcpriOdmMessage(
        common_hdr=EcpriCommonHeader(concat=0, message_type=5),
        measurement_id=3,
        action_type=4,
        timestamp=0x00112233445566778899,
        compensation=0xAABBCCDDEEFF0011,
    )
    packet = EcpriPacket(
        ethernet_hdr=EthernetHeader(
            dest_mac=0x001122334455,
            src_mac=0x66778899AABB,
            ethertype=0xAEFE,
        ),
        messages=[iq, odm],
    )

    decoded = EcpriCodec().decode(bytes(packet))
    assert decoded.ethernet_hdr == packet.ethernet_hdr
    assert isinstance(decoded.messages[0], EcpriIqMessage)
    assert decoded.messages[0].payload == iq.payload
    assert decoded.messages[0].pc_id == iq.pc_id
    assert isinstance(decoded.messages[1], EcpriOdmMessage)
    assert decoded.messages[1].timestamp == odm.timestamp
    assert bytes(decoded) == bytes(packet)


def test_axis_frame_byte_lane_conversion_uses_tkeep():
    payload = bytes(range(11))
    frame = axis_frame_from_bytes(payload, 4)
    assert frame.beats[-1].keep == 0b111
    assert axis_frame_to_bytes(frame, 4) == payload

    sparse = AxisFrame([AxisBeat(data=0x44332211, keep=0b0101, last=True)])
    assert axis_frame_to_bytes(sparse, 4) == bytes([0x11, 0x33])
