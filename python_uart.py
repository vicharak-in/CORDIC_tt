import serial
import time

# FTDI serial port name — adjust to your system
# On Linux/Mac it’s usually something like /dev/ttyUSB0
# On Windows it’s COMx (e.g. COM3)
PORT = '/dev/ttyUSB0'
BAUD = 115200

# Open serial port
ser = serial.Serial(PORT, BAUD, timeout=1)
time.sleep(0.1)  # Allow some time for FTDI to initialize

value = 0x03424

# Prepare bytes to send (LSB-first)
bytes_to_send = bytes([
    value & 0xFF,
    (value >> 8) & 0xFF,
    0x00
])

print(f"Opening serial port {PORT} at {BAUD} baud")
print(f"Sending: {[hex(b) for b in bytes_to_send]}")

ser.write(bytes_to_send)

time.sleep(0.01)

print("Waiting for 5-byte reply...")

reply = ser.read(5)

if len(reply) == 5:
    reply_bytes = list(reply)
    print(f"Received raw bytes: {[hex(b) for b in reply_bytes]}")

    # Combine as MSB-first 40-bit word
    raw = 0
    for b in reply_bytes:
        raw = (raw << 8) | b

    # Mask lower 4 bits
    raw &= ((1 << 36) - 1)

    value1 = (raw >> 18) & ((1 << 18) - 1)
    value2 = raw & ((1 << 18) - 1)

    print(f"Value 1 (18-bit): {hex(value1)}")
    print(f"Value 2 (18-bit): {hex(value2)}")

elif len(reply) > 0:
    print(f"Partial reply: {[hex(b) for b in reply]}")
else:
    print("No reply received.")

ser.close()
print("Serial port closed.")

