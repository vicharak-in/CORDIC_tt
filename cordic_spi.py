# this script is to test the spi_codic on Vaaman  

import spidev

# === Packing function for 72-bit CORDIC packet ===
def pack_cordic_input(in_x, in_y, in_alpha, i_atan_0):
    for name, val in zip(["in_x", "in_y", "in_alpha", "i_atan_0"], [in_x, in_y, in_alpha, i_atan_0]):
        if val < 0 or val > 0x3FFFF:
            raise ValueError(f"{name} = {val} is out of 18-bit range (0 to 0x3FFFF)")
    return (i_atan_0 << 54) | (in_alpha << 36) | (in_y << 18) | in_x

# === Convert to list of 9 bytes (LSB first) ===
def to_spi_bytes(packed_val):
    return [(packed_val >> (8 * i)) & 0xFF for i in range(9)]

# === Your CORDIC input values ===
in_x      = 0x026DE
in_y      = 0x00000
in_alpha  = 0x03424
i_atan_0  = 0x03244

# === Pack and convert to SPI byte stream ===
packed_val = pack_cordic_input(in_x, in_y, in_alpha, i_atan_0)
spi_tx_data = to_spi_bytes(packed_val)

# === Print final input values ===
print(" Sent Values:")
print(f"in_x     = 0x{in_x:05X}")
print(f"in_y     = 0x{in_y:05X}")
print(f"in_alpha = 0x{in_alpha:05X}")
print(f"i_atan_0 = 0x{i_atan_0:05X}")

# === Initialize SPI ===
spi = spidev.SpiDev()
spi.open(1, 0)
spi.max_speed_hz = 500_000
spi.mode = 0b00

# === Step 1: Send 72-bit packet (9 bytes) ===
_ = spi.xfer2(spi_tx_data)

# === Step 2: Read 7 bytes one-by-one ===
rx_bytes = []
for _ in range(7):
    rx = spi.xfer2([0x00])
    rx_bytes.append(rx[0])

spi.close()

# === Step 3: Combine into 56-bit int (LSB first) ===
rx_val = 0
for i, b in enumerate(rx_bytes):
    rx_val |= (b << (8 * i))

# === Step 4: Discard 2 MSBs, extract 3x 18-bit words ===
rx_val_54 = rx_val & ((1 << 54) - 1)
word_0 = (rx_val_54 >> 0)  & 0x3FFFF
word_1 = (rx_val_54 >> 18) & 0x3FFFF
word_2 = (rx_val_54 >> 36) & 0x3FFFF

# === Print decoded 18-bit output ===
print("\n Received 18-bit Words (LSB first):")
print(f"Word 0: {word_0:6d} (0x{word_0:05X})")
print(f"Word 1: {word_1:6d} (0x{word_1:05X})")
print(f"Word 2: {word_2:6d} (0x{word_2:05X})")

