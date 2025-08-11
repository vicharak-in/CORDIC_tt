module top_CORDIC_Engine_v1#(
    parameter DATA_WIDTH = 18,
    parameter N_PE = 15
)
(
    input i_clk,
    input i_rst_n,
    
    input signed [DATA_WIDTH - 1 : 0] in_x,
    input signed [DATA_WIDTH - 1 : 0] in_y,
    input signed [DATA_WIDTH - 1 : 0] in_alpha,
    input [DATA_WIDTH -1 : 0] in_atan_0,
    input i_valid_in,

    output reg signed [DATA_WIDTH - 1 : 0] out_costheta,
    output reg signed [DATA_WIDTH - 1 : 0] out_sintheta,
    output reg signed [DATA_WIDTH - 1 : 0] out_alpha,
    output reg o_valid_out
);

   


    /* ---- Pre-processing: Mapping the input angle to appropriate quadrants ---- */
    // Note: Angle should be in the radians in [0,2*pi]
    
    reg signed [DATA_WIDTH-1 : 0] r_i_alpha1, r_i_alpha2;
    reg signed [DATA_WIDTH-1 : 0] diff1, diff2, diff3;
    reg diff_valid;

    always@(posedge i_clk) begin
        if(i_valid_in) begin
            diff1 <= in_alpha - 16'h1922;
            diff2 <= in_alpha - 16'h3244;
            diff3 <= in_alpha - 16'h4b66;
            r_i_alpha1 <= in_alpha;
            diff_valid <= 1'b1;
        end
        else diff_valid <= 1'b0;
    end

    wire v1, v2, v3;
    assign v1 = diff1[DATA_WIDTH-1];
    assign v2 = diff2[DATA_WIDTH-1];
    assign v3 = diff3[DATA_WIDTH-1];

    wire [1:0] w_i_quadrant;
    assign w_i_quadrant[1] = ~v1&~v2;
    assign w_i_quadrant[0] = ~v1&(~(v2^v3));

    reg [1:0] quadrant;
    reg quadrant_valid;
    always@(posedge i_clk) begin
        if(diff_valid) begin
            case(w_i_quadrant)
                2'b00: begin 
                    quadrant <= 2'b00; // Q1
                    quadrant_valid <= 1'b1;
                    r_i_alpha2 <= r_i_alpha1;
                end

                2'b01: begin
                    quadrant <= 2'b01; // Q2
                    quadrant_valid <= 1'b1;
                    r_i_alpha2 <= diff1;
                end

                2'b10: begin
                    quadrant <= 2'b10; // Q2
                    quadrant_valid <= 1'b1;
                    r_i_alpha2 <= diff2;
                end

                2'b11: begin
                    quadrant <= 2'b11;
                    quadrant_valid <= 1'b1;
                    r_i_alpha2 <= diff3;
                end

                default: quadrant_valid <= 1'b0;
            endcase
        end
        else quadrant_valid <= 1'b0;
    end

    reg r_quadrant_valid;
    always@(posedge i_clk) r_quadrant_valid <= quadrant_valid;

    wire [1:0] w_quadrant;

    wire [DATA_WIDTH-1 : 0] w_costheta, w_sintheta;

    wire [DATA_WIDTH-1 : 0] w_o_alpha;

    wire w_o_valid;

    wire [DATA_WIDTH-1 : 0] w_atan;

    /* ------------------ Dynamic_atan_coefficient_generator ------------ */
    dynamic_atan #(
        .N_PE(N_PE),
        .DATA_WIDTH(DATA_WIDTH)
    )
    dynamic_atan_inst (
        .i_clk(i_clk),
        .i_rstn(i_rst_n),
        .i_data(in_atan_0),
        .i_valid(quadrant_valid),
        .o_atan_data(w_atan),
        .o_valid(),
        .o_done()
    );
    
    
    /* ------------------ CORDIC ENGINE ----------------------- */
    CORDIC_Engine_v1 # (
        .DATA_WIDTH(DATA_WIDTH),
        .N_PE(N_PE)
    )
    CORDIC_Engine_v1_inst (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .in_x(in_x),
        .in_y(in_y),
        .in_alpha(r_i_alpha2),
        .in_atan(w_atan),
        .i_quadrant(quadrant),
        .valid_in(r_quadrant_valid),
        .out_x(w_costheta),
        .out_y(w_sintheta),
        .out_alpha(w_o_alpha),
        .out_quadrant(w_quadrant),
        .valid_out(w_o_valid)
    );


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
