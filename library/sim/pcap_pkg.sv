// file: pcap_pkg.sv
// brief: Wireshark pcap file (.pcap) helper library. PCAP file (.pcap) has
//        some variants in the world. The following will only provide support
//        for pcap format used by Wireshark.

`default_nettype none
package pcap_pkg;

  // Data types define
  //==================

  // PCAP has a global header containing some global information followed by
  // zero of more records for each captured packet. It's look like this:
  //
  // | Global Header | Packet Header | Packet Data | Packet Header | Packet Data | ...
  //
  // The capture does not necessary contain all the data in the packet as it
  // appeared one the network. The capture might contain at more the first N
  // bytes. The value if N is called "snapshot length" or `snaplen`.

  // PCAP file global header
  //   6 32-bit words = 24 bytes
  //
  //   magic_number: used to detect the file format itself and the byte
  //     ordering of all header. Not packet data is not affect by a specific
  //     byte alignment.
  //   version_major, version_minor: the version number of this file format
  //   thiszone: the correction time in seconds between GMT (UTC) and the local
  //     timezone. In practice, thiszone is always 0.
  //   sigfigs: in theory, the accuracy of time stamps in the capture. All tools
  //     set it if zero.
  //   snaplen: the snapshot length. Typically 65536.
  //   network: link-layer header type, see http://www.tcpdump.org/linktypes.html
  //
  typedef struct packed {
    logic [31:0] magic_number;  // magic number
    logic [15:0] version_major;  // major version number
    logic [15:0] version_minor;  // minor version number
    logic [31:0] thiszone;  // GMT to local correction
    logic [31:0] sigfigs;  // accuracy of timestamp
    logic [31:0] snaplen;  // max length of captured packets in octets
    logic [31:0] network;  // data link type
  } pcap_header_t;

  // PCAP record (packet) header
  //   4 32-bit words = 16 bytes
  //
  //   ts_sec: the data and the time when this packet was captured. This value
  //     is seconds since Jan, 1, 1970 00:00:00 GMT.
  //   ts_usec: the microseconds when this packet was captured for normal file.
  //     If nanosecond-resolution file, this is nanoseconds.
  //   incl_len: the number of bytes of packet actually captured and saved in
  //     file. Should never become larger than `orig_len` or `snaplen`.
  //   orig_len: the length of the packet it appeared on the network.
  //
  typedef struct {
    logic [31:0] ts_sec;  // timestamp seconds
    logic [31:0] ts_usec;  // timestamp microseconds
    logic [31:0] incl_len;  // number of octets of packet saved in file
    logic [31:0] orig_len;  // actual length of packet
  } pcap_rec_header_t;

  // Packet data buffer
  typedef struct {
    logic [7:0] buffer[16384]; // data blob
    int len; // buffer length
  } pkt_buffer_t;

  typedef struct {
    int file;
    int read_mode;
    int pkt_cnt;
  } pcap_handler_t;

  // Helper functions
  //=================

  // Open the pcap file and read global header, return how to read it.
  //
  //   file_name: the filename to read
  //   return: file handler
  //
  function automatic pcap_handler_t pcap_open(input string file_name);
    int file;
    int read_mode;
    int magic_number;
    pcap_header_t global_header;
    pcap_handler_t ret;

    $info("Read pcap file \"%s\"", file_name);
    file = $fopen(file_name, "rb");
    if (file < 0) begin
      // $fatal("Unable to open file \"%s\"", file_name);
    end

    magic_number = read_4bytes(file, 1);
    $info(" magic_number: %x", magic_number);
    read_mode = read_magic_number(magic_number);
    $info(" file read mode: %x", read_mode);

    global_header.magic_number = magic_number;
    global_header.version_major = read_2bytes(file, (read_mode & 1));
    global_header.version_minor = read_2bytes(file, (read_mode & 1));
    global_header.thiszone = read_4bytes(file, (read_mode & 1));
    global_header.sigfigs = read_4bytes(file, (read_mode & 1));
    global_header.snaplen = read_4bytes(file, (read_mode & 1));
    global_header.network = read_4bytes(file, (read_mode & 1));

    $info(" version_major: %x", global_header.version_major);
    $info(" version_minor: %x", global_header.version_minor);
    $info(" thiszone: %x", global_header.thiszone);
    $info(" sigfigs: %x", global_header.sigfigs);
    $info(" snaplen: %x", global_header.snaplen);
    $info(" network: %x", global_header.network);

    ret.file = file;
    ret.read_mode = read_mode;
    ret.pkt_cnt = 0;
    return ret;
  endfunction

  // Read one record (packet) from pcap file, including the record header and
  // packet data. Note that the pcap global header should already be skipped.
  //
  //   file: the file handler to read, should got from $fopen()
  //   read_mode: pcap header read format got from pcap_open()
  //   return: one packet in buffer
  //
  function automatic pkt_buffer_t pcap_read_packet(pcap_handler_t h);
    int file;
    int read_mode;
    pcap_rec_header_t pkt_header;
    pkt_buffer_t pkt;

    file = h.file;
    read_mode = h.read_mode;

    pkt_header.ts_sec   = read_4bytes(file, (read_mode & 1));
    pkt_header.ts_usec  = read_4bytes(file, (read_mode & 1));
    pkt_header.incl_len = read_4bytes(file, (read_mode & 1));
    pkt_header.orig_len = read_4bytes(file, (read_mode & 1));

    $info("Read one packet from pcap");
    $info(" ts_sec: %d", pkt_header.ts_sec);
    $info(" ts_nsec: %d", pkt_header.ts_usec);
    $info(" incl_len: %d", pkt_header.incl_len);
    $info(" orig_len: %d", pkt_header.orig_len);

    for (int i = 0; i < pkt_header.incl_len; i++) begin
      pkt.buffer[i] = $fgetc(file);
    end
    pkt.len = pkt_header.incl_len;

    h.pkt_cnt++;
    return pkt;
  endfunction


  // Read 4 bytes from file, set le = 1 if file is stored in little endian.
  function automatic logic [31:0] read_4bytes(input int fPtr, input int le);
    logic [31:0] ret;
    if (le) begin
      ret[7:0]   = $fgetc(fPtr);
      ret[15:8]  = $fgetc(fPtr);
      ret[23:16] = $fgetc(fPtr);
      ret[31:24] = $fgetc(fPtr);
    end else begin
      ret[31:24] = $fgetc(fPtr);
      ret[23:16] = $fgetc(fPtr);
      ret[15:8]  = $fgetc(fPtr);
      ret[7:0]   = $fgetc(fPtr);
    end
    return ret;
  endfunction

  // Read 2 bytes from file, set le = 1 if file is stored in little endian.
  function automatic logic [15:0] read_2bytes(input int fPtr, input int le);
    logic [15:0] ret;
    if (le) begin
      ret[7:0]  = $fgetc(fPtr);
      ret[15:8] = $fgetc(fPtr);
    end else begin
      ret[15:8] = $fgetc(fPtr);
      ret[7:0]  = $fgetc(fPtr);
    end
    return ret;
  endfunction

  // Given the magic number of global header, it will return the pcap header
  // read mode, `ts_nsec` resolution.
  function automatic int read_magic_number(input int magic_number);
    case (magic_number)
      'hA1B2C3D4: begin
        $info("Magic number format is Little Endian");
        return 'h101;
      end
      'hA1B23C4D: begin
        $info("Magic number format is Little Endian in NanoSecond resolution");
        return 'h111;
      end
      'hD4C3B2A1: begin
        $info("Magic number format is Big Endian");
        return 'h100;
      end
      'h4D3CB2A1: begin
        $info("Magic number format is Big Endian in NameSecond resolution");
      end
      default: begin
        $error("Magic number not recognized");
        $stop();
        return 0;
      end
    endcase
  endfunction

endpackage

`default_nettype wire
