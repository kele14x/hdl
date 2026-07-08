"""eCPRI Data Structures"""

from dataclasses import dataclass


@dataclass
class EthernetHeader:
    """Ethernet Header"""

    dest_mac = 0
    src_mac = 0
    ethertype = 0
    with_vlan = False
    vlan_tag = 0

    def __len__(self):
        """Return the data stream length of the header"""
        c = 18 if self.with_vlan else 14
        return c

    def __bytes__(self):
        """Get the byte stream"""
        ret = [(self.dest_mac >> 8 * (5 - i)) & 0xFF for i in range(6)]
        ret += [(self.src_mac >> 8 * (5 - i)) & 0xFF for i in range(6)]
        if self.with_vlan:
            ret += [0x81, 0x00]
            ret += [(self.vlan_tag >> 8 * (1 - i)) & 0xFF for i in range(2)]
        ret += [(self.ethertype >> 8 * (1 - i)) & 0xFF for i in range(2)]
        return bytes(ret)


@dataclass
class EthernetPacket:
    """Ethernet Packet"""

    hdr = EthernetHeader()
    payload = None

    def __len__(self):
        """Return the data stream length of the packet"""
        c = len(self.hdr)
        if self.payload is not None:
            c += len(self.payload)
        return c

    def __bytes__(self):
        """Get the data stream"""
        ret = bytes(self.hdr)
        if self.payload is not None:
            ret += bytes(self.payload)
        return ret


@dataclass
class EcpriCommonHeader:
    """eCPRI Common Header"""

    version = 0
    reserved = 0
    concat = 0
    message_type = 0
    payload_size = 0

    def __len__(self):
        """Return the data stream length of the header"""
        return 4

    def __bytes__(self):
        """Get the data stream"""
        data = (
            (self.version << 28)
            + (self.reserved << 25)
            + (self.concat << 24)
            + (self.message_type << 16)
            + self.payload_size
        )
        ret = [(data >> 8 * (3 - i)) & 0xFF for i in range(4)]
        return bytes(ret)


@dataclass
class EcpriMessage:
    """General eCPRI Message"""

    common_hdr = EcpriCommonHeader()
    payload = None

    def __len__(self):
        """Return the data stream length of the message"""
        c = len(self.common_hdr) + len(self.payload)
        if self.common_hdr.concat:
            c = (c + 3) // 4 * 4
        return c

    def __bytes__(self):
        """Get the data stream"""
        ret = bytes(self.common_hdr)
        if self.payload is not None:
            ret += bytes(self.payload)
        return ret


@dataclass
class EcpriIqMessage:
    """eCPRI IQ Message (type 0)"""

    common_hdr = EcpriCommonHeader()
    pc_id = 0
    seq_id = 0
    e_bit = 0
    subseq_id = 0

    payload = None

    def __len__(self):
        """Return the data stream length of the message"""
        c = len(self.common_hdr) + 4
        if self.payload is not None:
            c += len(self.payload)
        return c

    def __bytes__(self):
        """Get the data stream"""
        ret = bytes(self.common_hdr)
        ret += bytes([(self.pc_id >> 8 * (1 - i)) & 0xFF for i in range(2)])
        ret += bytes([self.seq_id])
        ret += bytes([self.e_bit << 7 | self.subseq_id])
        if self.payload is not None:
            ret += bytes(self.payload)
        return ret


@dataclass
class EcpriIqcMessage:
    """eCPRI IQ Control Message (type 1)"""

    common_hdr = EcpriCommonHeader()
    rtc_id = 0
    seq_id = 0
    e_bit = 0
    subseq_id = 0

    payload = None

    def __len__(self):
        """Return the data stream length of the message"""
        c = len(self.common_hdr) + 4
        if self.payload is not None:
            c += len(self.payload)
        return c

    def __bytes__(self):
        """Get the data stream"""
        ret = bytes(self.common_hdr)
        ret += bytes([(self.rtc_id >> 8 * (1 - i)) & 0xFF for i in range(2)])
        ret += bytes([self.seq_id])
        ret += bytes([self.e_bit << 7 | self.subseq_id])
        if self.payload is not None:
            ret += bytes(self.payload)
        return ret


@dataclass
class EcpriOdmMessage:
    """eCPRI One-Way Delay Measurement Message (type 5)"""

    common_hdr = EcpriCommonHeader()

    measurement_id = 0
    action_type = 0
    timestamp = 0
    compensation = 0
    dummy = None

    def __len__(self):
        """Return the data stream length of the message"""
        c = len(self.common_hdr) + 20
        if self.dummy is not None:
            c += len(self.dummy)
        return c

    def __bytes__(self):
        """Get the data stream"""
        ret = bytes(self.common_hdr)
        ret += bytes([self.measurement_id])
        ret += bytes([self.action_type])
        ret += bytes([(self.timestamp >> 8 * (9 - i)) & 0xFF for i in range(10)])
        ret += bytes([(self.compensation >> 8 * (7 - i)) & 0xFF for i in range(8)])
        if self.dummy is not None:
            ret += bytes(self.dummy)
        return ret


@dataclass
class EcpriPacket:
    """eCPRI Packet"""

    ethernet_hdr = EthernetHeader()
    messages = None

    def __len__(self):
        """Return the payload length of the packet."""
        c = len(self.ethernet_hdr)
        if self.messages is not None:
            for message in self.messages:
                c += len(message)
        return c

    def __bytes__(self):
        """Get the byte stream"""
        ret = bytes(self.ethernet_hdr)
        if self.messages is not None:
            for message in self.messages:
                ret += bytes(message)
        return ret
