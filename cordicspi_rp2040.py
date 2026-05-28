from machine import Pin, SPI
import time



# example input 
in_x     = 0x026DE
in_y     = 0x00000
in_alpha = 0x03424
i_atan_0 = 0x03244


spi = SPI(0, baudrate=500_000, polarity=0, phase=0, bits=8,
          sck=Pin(2), mosi=Pin(3), miso=Pin(4))
cs = Pin(5, Pin.OUT)
cs.value(1)

def send_byte(byte_val):
    cs.value(0)
    spi.write(bytearray([byte_val]))
    cs.value(1)
    time.sleep_us(10)  

def read_byte():
    cs.value(0)
    val = spi.read(1, 0x00)[0]  # Send dummy 0x00 and read response
    cs.value(1)
    time.sleep_us(10)  
    return val

def pack_cordic_input(in_x, in_y, in_alpha, i_atan_0):
    for name, val in zip(["in_x", "in_y", "in_alpha", "i_atan_0"], [in_x, in_y, in_alpha, i_atan_0]):
        if val < 0 or val > 0x3FFFF:
            raise ValueError(f"{name} = {val} out of 18-bit range")
    return (i_atan_0 << 54) | (in_alpha << 36) | (in_y << 18) | in_x

# === Convert packed input to list of bytes
def to_spi_bytes(packed_val):
    return [(packed_val >> (8 * i)) & 0xFF for i in range(9)]

# === Receive and unpack 7 bytes of response ===
def receive_response():
    rx = []
    for _ in range(7):
        b = read_byte()
        rx.append(b)
    return rx

def unpack_response(rx_bytes):
    val = 0
    for i in range(7):
        val |= (rx_bytes[i] << (8 * i))
    val &= (1 << 54) - 1
    word_0 = (val >> 0)  & 0x3FFFF
    word_1 = (val >> 18) & 0x3FFFF
    word_2 = (val >> 36) & 0x3FFFF
    return word_0, word_1, word_2

packed = pack_cordic_input(in_x, in_y, in_alpha, i_atan_0)
tx_bytes = to_spi_bytes(packed)

print("\n Sending ")
for i, b in enumerate(tx_bytes):
    #print(f"Byte {i}: 0x{b:02X}")
    send_byte(b)

# Optional delay to let FPGA finish
time.sleep_us(50)

print("\n Receiving")
rx_bytes = receive_response()
#for i, b in enumerate(rx_bytes):
    #print(f"Byte {i}: 0x{b:02X}")

word0, word1, word2 = unpack_response(rx_bytes)

print("\n Cordic outputs :")
print(f"Word 0: {word0} (0x{word0:05X})")
print(f"Word 1: {word1} (0x{word1:05X})")
print(f"Word 2: {word2} (0x{word2:05X})")



