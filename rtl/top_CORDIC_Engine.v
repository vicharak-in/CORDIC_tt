module top_CORDIC_Engine#(
    parameter DATA_WIDTH = 18,
    parameter N_PE = 15
)
(
    input i_clk,
    input i_rst_n,
    
    input signed [DATA_WIDTH - 1 : 0] in_x,
    input signed [DATA_WIDTH - 1 : 0] in_y,
    input signed [DATA_WIDTH - 1 : 0] in_alpha,
    input i_valid_in,

    output signed [DATA_WIDTH - 1 : 0] out_costheta,
    output signed [DATA_WIDTH - 1 : 0] out_sintheta,
    output signed [DATA_WIDTH - 1 : 0] out_alpha,
    output o_valid_out
);

    reg [DATA_WIDTH-1 : 0] atan [0:N_PE-1];
    /*
    initial begin
        $readmemb("rtl/arctan.mem",atan);
    end
    */

    initial begin
        atan[0] = 18'b 000011001001000100;
        atan[1] = 18'b 000001110110101100;
        atan[2] = 18'b 000000111110101110;
        atan[3] = 18'b 000000011111110101;
        atan[4] = 18'b 000000001111111111;
        atan[5] = 18'b 000000001000000000;
        atan[6] = 18'b 000000000100000000;
        atan[7] = 18'b 000000000010000000;
        atan[8] = 18'b 000000000001000000;
        atan[9] = 18'b 000000000000100000;
        atan[10] = 18'b 000000000000010000;
        atan[11] = 18'b 000000000000001000;
        atan[12] = 18'b 000000000000000100;
        atan[13] = 18'b 000000000000000010;
        atan[14] = 18'b 000000000000000001;
    end

    genvar i;
    generate
        for (i = 0; i < N_PE; i = i + 1) begin : CORDIC_PE
            wire [DATA_WIDTH-1 : 0] intermediate_x;
            wire [DATA_WIDTH-1 : 0] intermediate_y;
            wire [DATA_WIDTH-1 : 0] intermediate_alpha;
            wire intermediate_valid_out;

            if(i == 0) begin
                CORDIC_Engine #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .N_PE(N_PE)
                ) cordic_engine_inst (
                    .i_clk(i_clk),
                    .i_rst_n(i_rst_n),
                    .in_x(in_x),
                    .in_y(in_y),
                    .in_alpha(in_alpha),
                    .in_atan(atan[i]),
                    .i_count(i),
                    .valid_in(i_valid_in),

                    .out_x(intermediate_x),
                    .out_y(intermediate_y),
                    .out_alpha(intermediate_alpha),
                    .valid_out(intermediate_valid_out)
                );
            end
            else if(i == N_PE-1) begin
                CORDIC_Engine #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .N_PE(N_PE)
                ) cordic_engine_inst (
                    .i_clk(i_clk),
                    .i_rst_n(i_rst_n),
                    .in_x(CORDIC_PE[i-1].intermediate_x),
                    .in_y(CORDIC_PE[i-1].intermediate_y),
                    .in_alpha(CORDIC_PE[i-1].intermediate_alpha),
                    .in_atan(atan[i]),
                    .i_count(i),
                    .valid_in(CORDIC_PE[i-1].intermediate_valid_out),

                    .out_x(out_costheta),
                    .out_y(out_sintheta),
                    .out_alpha(out_alpha),
                    .valid_out(o_valid_out)
                );
            end
            else begin
                CORDIC_Engine #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .N_PE(N_PE)
                ) cordic_engine_inst (
                    .i_clk(i_clk),
                    .i_rst_n(i_rst_n),
                    .in_x(CORDIC_PE[i-1].intermediate_x),
                    .in_y(CORDIC_PE[i-1].intermediate_y),
                    .in_alpha(CORDIC_PE[i-1].intermediate_alpha),
                    .in_atan(atan[i]),
                    .i_count(i),
                    .valid_in(CORDIC_PE[i-1].intermediate_valid_out),

                    .out_x(intermediate_x),
                    .out_y(intermediate_y),
                    .out_alpha(intermediate_alpha),
                    .valid_out(intermediate_valid_out)
                );
            end
        end
    endgenerate

endmodule