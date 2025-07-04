`timescale 1ns/1ps
`include "../rtl/top_CORDIC_Engine.v"
`include "../rtl/CORDIC_Engine.v"

module tb_top_CORDIC_Engine();

    reg i_clk;
    reg i_rst_n;
    
    reg signed [DATA_WIDTH - 1 : 0] in_x;
    reg signed [DATA_WIDTH - 1 : 0] in_y;
    reg signed [DATA_WIDTH - 1 : 0] in_alpha;
    reg i_valid_in;

    wire signed [DATA_WIDTH - 1 : 0] out_costheta;
    wire signed [DATA_WIDTH - 1 : 0] out_sintheta;
    wire signed [DATA_WIDTH - 1 : 0] out_alpha;
    wire o_valid_out;


    initial i_clk = 1'b1;
    always #5 i_clk = ~i_clk;

    localparam DATA_WIDTH = 18;
    localparam N_PE = 15;
    top_CORDIC_Engine # (
        .DATA_WIDTH(DATA_WIDTH),
        .N_PE(N_PE)
    )
    top_CORDIC_Engine_inst (
      .i_clk(i_clk),
      .i_rst_n(i_rst_n),
      .in_x(in_x),
      .in_y(in_y),
      .in_alpha(in_alpha),
      .i_valid_in(i_valid_in),
      .out_costheta(out_costheta),
      .out_sintheta(out_sintheta),
      .out_alpha(out_alpha),
      .o_valid_out(o_valid_out)
    );

    // alpha is the angle in radians, represented in fixed-point format
    integer f1,f2,f3;
    initial begin

        $dumpfile("tb_top_CORDIC_Engine.vcd");
        $dumpvars(0);

        f1 = $fopen("input.txt", "w");
        f2 = $fopen("cos_output.txt", "w");
        f3 = $fopen("sin_output.txt", "w");

        if (f1 == 0 || f2 == 0 || f3 == 0) begin
            $display("Error opening file");
            $finish;
        end
        i_rst_n = 1'b0;
        i_valid_in = 1'b0;
        in_x = 0;
        in_y = 0;
        in_alpha = 0;

        #10 i_rst_n = 1'b1;
        #10 i_valid_in = 1'b1;
            in_x = 18'h026de; // Scaling value for CORDIC 0.60729
            in_y = 18'h00000;
            in_alpha = 18'h00000;
        #10 in_alpha = 18'h03424;
        #10 in_alpha = 18'h02300;
        #10 in_alpha = 18'h039f8;
        #10 in_alpha = 18'hfc99a;
        #10 in_alpha = 18'hfd000;
        #10 in_alpha = 18'h03244; 
        #10 in_alpha = 18'hfcdbc;
        #10 in_alpha = 18'h08000;
        #10 in_alpha = 18'h0cccd;
        #10 in_alpha = 18'h0f99a;
        #10 in_alpha = 18'h13333;
        #10 in_alpha = 18'h0_64_87;
        #10 in_alpha = 18'h0_C9_09;
        #10 in_alpha = 18'h1_2D_97;
        #10 i_valid_in = 1'b0;

        #800; // Wait for the CORDIC computation to finish
        $fclose(f1);
        $fclose(f2);
        $fclose(f3);
        
        $display("Simulation finished successfully.\n");
        $display("Anayzing results...");

        f1 = $fopen("input.txt", "r");
        f2 = $fopen("cos_output.txt", "r");
        f3 = $fopen("sin_output.txt", "r");

        while(!$feof(f1)) begin
            reg signed [DATA_WIDTH - 1 : 0] r_in_alpha;
            reg signed [DATA_WIDTH - 1 : 0] r_out_costheta;
            reg signed [DATA_WIDTH - 1 : 0] r_out_sintheta;

            $fscanf(f1, "%h\n", r_in_alpha);
            $fscanf(f2, "%h\n", r_out_costheta);
            $fscanf(f3, "%h\n", r_out_sintheta);

            $display("Input angle: %f", r_in_alpha / (2**14.0)); 

            $display("Expected Result, Cosine Output: %f, Sine Output: %f", $cos(r_in_alpha/2**14.0), $sin(r_in_alpha/2**14.0));
            $display("CORDIC Result, Cosine Output: %f, Sine Output: %f \n", r_out_costheta / (2**14.0), r_out_sintheta / (2**14.0));
        end

        $finish;
    end

    // Write input and output values to files
    always @(posedge i_clk) begin
        if (i_valid_in) begin
            $fwrite(f1, "%h\n", in_alpha);
        end
        if (o_valid_out) begin
            $fwrite(f2, "%h\n", out_costheta);
            $fwrite(f3, "%h\n", out_sintheta);
        end
    end

endmodule