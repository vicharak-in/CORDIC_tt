## CORDIC_tt

 - Current version of CORDIC Engine is radix-2 architecture fixed-point design (Q3.14)
 - 15-stage pipelined architecture
 - Fractional width can be changed as per the precision requirement
 - Accepts angle in radians
 - Input angle is compared with boundary limit of quadrant and mapped the input angle to either Q1 or Q4
 - Output of CORDIC Engine is post-processed (swapped and/or 2's complement) based on the quadrant of input angle falls in

#### UART Pin-Outs

1. RX - FPGA PIN 32
2. TX - FPGA PIN 30


#### pinouts for the spi_interface with vaaman 

### What you need:
- All the wires should be of identical lengths. 
- You will need a dummy SPI device in your Linux kernel (e.g., `/dev/spidev1.0`, here 1 is bus and 0 is device).
- `SPI_Slave.v` is the slave. `spi_lb_top.v` is top module responsible for loopback functionality. `spi.py`/`spi.c` is for CPU, which works as SPI master here.  
#### Pin assignments:

| Pin    | CPU Pin | FPGA Pin |
|---------|-------------|---------------|
|`sclk`  |7              |H13 - 7    |
|`mosi`|29       |E9 - 29|
|`miso`|31|L15 - 31|
|`cs_n`|33|L18 - 33|
--------------------------------------------------------------------------------------------
