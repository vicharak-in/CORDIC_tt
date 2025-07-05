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

    output reg signed [DATA_WIDTH - 1 : 0] out_costheta,
    output reg signed [DATA_WIDTH - 1 : 0] out_sintheta,
    output reg signed [DATA_WIDTH - 1 : 0] out_alpha,
    output reg o_valid_out
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

    /* ---- Pre-processing: Mapping the input angle to appropriate quadrants ---- */
    // Note: Angle should be in the radians in [0,2*pi]
    
    reg signed [DATA_WIDTH-1 : 0] r_i_alpha1, r_i_alpha2;
    reg signed [DATA_WIDTH-1 : 0] diff1, diff2, diff3;
    reg diff_valid;

    always@(posedge i_clk) begin
        if(i_valid_in) begin
            diff1 <= in_alpha - 18'h0_64_88;
            diff2 <= in_alpha - 18'h0_C9_10;
            diff3 <= in_alpha - 18'h1_2D_98;
            r_i_alpha1 <= in_alpha;
            diff_valid <= 1'b1;
        end
        else diff_valid <= 1'b0;
    end

    wire v1, v2, v3;
    assign v1 = diff1[DATA_WIDTH-1];
    assign v2 = diff2[DATA_WIDTH-1];
    assign v3 = diff3[DATA_WIDTH-1];

    reg [1:0] quadrant;
    reg quadrant_valid;
    always@(posedge i_clk) begin
        if(diff_valid) begin
            case({v1,v2,v3})
                3'b111: begin 
                    quadrant <= 2'b00; // Q1
                    quadrant_valid <= 1'b1;
                    r_i_alpha2 <= r_i_alpha1;
                end

                3'b011: begin
                    quadrant <= 2'b01; // Q2
                    quadrant_valid <= 1'b1;
                    r_i_alpha2 <= diff1;
                end

                3'b001: begin
                    quadrant <= 2'b10; // Q2
                    quadrant_valid <= 1'b1;
                    r_i_alpha2 <= diff2;
                end

                3'b000: begin
                    quadrant <= 2'b11;
                    quadrant_valid <= 1'b1;
                    r_i_alpha2 <= diff3;
                end

                default: quadrant_valid <= 1'b0;
            endcase
        end
        else quadrant_valid <= 1'b0;
    end

    wire [1:0] w_quadrant;

    wire [DATA_WIDTH-1 : 0] w_costheta, w_sintheta;

    wire [DATA_WIDTH-1 : 0] w_o_alpha;

    wire w_o_valid;

    /* ------------------ CORDIC ENGINE ----------------------- */
    genvar i;
    generate
        for (i = 0; i < N_PE; i = i + 1) begin : CORDIC_PE
            wire [DATA_WIDTH-1 : 0] intermediate_x;
            wire [DATA_WIDTH-1 : 0] intermediate_y;
            wire [DATA_WIDTH-1 : 0] intermediate_alpha;
            wire [1:0] intermediate_quadrant;
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
                    .in_alpha(r_i_alpha2),
                    .in_atan(atan[i]),
                    .i_count(i),
                    .i_quadrant(quadrant),
                    .valid_in(quadrant_valid),

                    .out_x(intermediate_x),
                    .out_y(intermediate_y),
                    .out_alpha(intermediate_alpha),
                    .out_quadrant(intermediate_quadrant),
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
                    .i_quadrant(CORDIC_PE[i-1].intermediate_quadrant),
                    .valid_in(CORDIC_PE[i-1].intermediate_valid_out),

                    .out_x(w_costheta),
                    .out_y(w_sintheta),
                    .out_alpha(w_o_alpha),
                    .out_quadrant(w_quadrant),
                    .valid_out(w_o_valid)
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
                    .i_quadrant(CORDIC_PE[i-1].intermediate_quadrant),
                    .valid_in(CORDIC_PE[i-1].intermediate_valid_out),

                    .out_x(intermediate_x),
                    .out_y(intermediate_y),
                    .out_alpha(intermediate_alpha),
                    .out_quadrant(intermediate_quadrant),
                    .valid_out(intermediate_valid_out)
                );
            end
        end
    endgenerate


    /* ---------------------- Post-processing the CORDIC Engine result ---------------- */
    wire [DATA_WIDTH-1 : 0] twos_comp_costheta, twos_comp_sintheta;
    assign twos_comp_costheta = ~w_costheta + 1;
    assign twos_comp_sintheta = ~w_sintheta + 1;

    always@(posedge i_clk) begin
        if(w_o_valid) begin
		out_alpha <= w_o_alpha;
            case(w_quadrant)
                2'b00: begin
                    out_costheta <= w_costheta;
                    out_sintheta <= w_sintheta;
                    o_valid_out <= 1'b1;
                end 

                2'b01: begin
                    out_costheta <= twos_comp_sintheta;
                    out_sintheta <= w_costheta;
                    o_valid_out <= 1'b1;
                end

                2'b10: begin
                    out_costheta <= twos_comp_costheta;
                    out_sintheta <= twos_comp_sintheta;
                    o_valid_out <= 1'b1;
                end

                2'b11: begin
                    out_costheta <= w_sintheta;
                    out_sintheta <= twos_comp_costheta;
                    o_valid_out <= 1'b1;
                end

                default: o_valid_out <= 1'b0;
            endcase
        end

        else o_valid_out <= 1'b0;
    end


endmodule
