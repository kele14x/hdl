import mmap
import sys

DDR_OFFSET = 0x400000000

if __name__ == "__main__":
    filename = sys.argv[1]
    with open(filename, "rb") as f:
        data = f.read()
        print(f"Read {len(data)} bytes from {filename}")

    # Ensure data length is a multiple of 4 by padding with zeros
    remainder = len(data) % 4
    if remainder != 0:
        padding_size = 4 - remainder
        data += b'\x00' * padding_size

    with open("/dev/mem", "r+b") as f:
        mm = mmap.mmap(
            f.fileno(),
            4096 * ((len(data) + 4095) // 4096),
            prot=mmap.PROT_WRITE,
            offset=DDR_OFFSET,
        )
        mm.write(data)
        print(f"Wrote {len(data)} bytes to 0x{DDR_OFFSET:x}")
