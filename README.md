## CORDIC_tt

 - Current version of CORDIC Engine is radix-2 architecture fixed-point design (Q3.14)
 - 15-stage pipelined architecture
 - Fractional width can be changed as per the precision requirement
 - Accepts angle in radians
 - Input angle is compared with boundary limit of quadrant and mapped the input angle to either Q1 or Q4
 - Output of CORDIC Engine is post-processed (swapped and/or 2's complement) based on the quadrant of input angle falls in
