module CORDIC_Engine_v1 #(
	parameter DATA_WIDTH = 18,
    parameter N_PE = 16
)
(
    input i_clk,
    input i_rst_n,
    input signed [DATA_WIDTH - 1 : 0] in_x,
    input signed [DATA_WIDTH - 1 : 0] in_y,
    input signed [DATA_WIDTH - 1 : 0] in_alpha,
    input signed [DATA_WIDTH - 1 : 0] in_atan,
    input [1:0] i_quadrant,
    input valid_in,
    
    output reg signed [DATA_WIDTH - 1 : 0] out_x = 0,
    output reg signed [DATA_WIDTH - 1 : 0] out_y = 0,
    output reg signed [DATA_WIDTH - 1 : 0] out_alpha = 0,
    output reg [1:0] out_quadrant = 0,
    output reg valid_out = 0
);


reg [$clog2(N_PE) : 0] count;
reg signed [DATA_WIDTH-1 : 0] r_alpha;
reg signed [DATA_WIDTH-1 : 0] r_x;
reg signed [DATA_WIDTH-1 : 0] r_y;
reg state;

always @(posedge i_clk) begin
    if(!i_rst_n) begin
        count <= 0;
        state <= 0;
        r_alpha <= 0;
        r_x <= 0;
        r_y <= 0;
        out_x <= 0;
        out_y <= 0;
        out_alpha <= 0;
        valid_out <= 0;
        out_quadrant <= 0;
    end
    else begin
        case(state)
            0: begin
                valid_out <= 0;
                out_quadrant <= out_quadrant;
                if(valid_in) begin
                    count <= count + 1;
                    state <= 1;
                    if(in_alpha[DATA_WIDTH - 1] == 1'b0) begin
                        r_alpha <= in_alpha + ~(in_atan) + 1; 
                        r_x <= in_x - (in_y >>> count);
                        r_y <= in_y + (in_x >>> count);
                    end
                    else begin
                        r_alpha <= in_alpha + (in_atan);
                        r_x <= in_x + (in_y >>> count);
                        r_y <= in_y - (in_x >>> count);
                    end
                end
                else begin
                    r_alpha <= r_alpha;
                    r_x <= r_x;
                    r_y <= r_y;
                    count <= count;
                    state <= 0;
                end
            end

            1: begin
                if(count == N_PE) begin
                    count <= 0; // Reset counter after reaching N_PE
                    state <= 0; // Go back to initial state
                    valid_out <= 1; // Indicate valid output
                    out_quadrant <= i_quadrant; // Update quadrant
                    out_alpha <= r_alpha;
                    out_x <= r_x;
                    out_y <= r_y;
                end
                else begin
                    count <= count + 1;
                    if(r_alpha[DATA_WIDTH - 1] == 1'b0) begin
                        r_alpha <= r_alpha + ~(in_atan) + 1; 
                        r_x <= r_x - (r_y >>> count);
                        r_y <= r_y + (r_x >>> count);
                    end
                    else begin
                        r_alpha <= r_alpha + (in_atan);
                        r_x <= r_x + (r_y >>> count);
                        r_y <= r_y - (r_x >>> count);
                    end
                end
            end
        endcase
    end
end

endmodule
