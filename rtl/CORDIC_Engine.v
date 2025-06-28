module CORDIC_Engine #(
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
    input [$clog2(N_PE) : 0] i_count,
    input valid_in,
    
    output reg signed [DATA_WIDTH - 1 : 0] out_x = 0,
    output reg signed [DATA_WIDTH - 1 : 0] out_y = 0,
    output reg signed [DATA_WIDTH - 1 : 0] out_alpha = 0,
    output reg valid_out = 0
);

always @(posedge i_clk) begin
    if(!i_rst_n) begin
        out_x <= 0;
        out_y <= 0;
        out_alpha <= 0;
        valid_out <= 0;
    end
    else begin
        if(valid_in) begin
            if(in_alpha[DATA_WIDTH - 1] == 1'b0) begin
                out_alpha <= in_alpha + ~(in_atan) + 1; 
                out_x <= in_x - (in_y >>> i_count);
                out_y <= in_y + (in_x >>> i_count);
                valid_out <= 1'b1;
            end
            else begin
                out_alpha <= in_alpha + (in_atan);
                out_x <= in_x + (in_y >>> i_count);
                out_y <= in_y - (in_x >>> i_count);
                valid_out <= 1'b1;
            end
        end
        else begin
            out_alpha <= out_alpha;
            out_x <= out_x;
            out_y <= out_y;
            valid_out <= 1'b0;
        end
    end
end

endmodule
