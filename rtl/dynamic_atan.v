module dynamic_atan#(
    parameter N_PE = 16,
    parameter DATA_WIDTH = 18
)(
    input i_clk,
    input i_rstn,

    input [DATA_WIDTH-1:0] i_data,
    input i_valid,

    output reg [DATA_WIDTH-1:0] o_atan_data,
    output reg o_valid,
    output reg o_done
);

    /* ------ Dynamic generation of atan coefficients for CORDIC_PE ------ */
    /*
        It uses hybrid mechnaism to generate atan coefficients
        Iteration 0: Take the actaul value of atan(2^0) from the input
        Iteration 1-5: Compute using Taylor series expansion
                    2^(-i) - ((2^(-3i)/4)+(2^(-3i)/16)+(2^(-3i)/64))  (Same as, x-(x^3)/3)
        Iteration 6-last: atan(2^(-i)) = 2^(-i)
    */

    reg [$clog2(N_PE)-1:0] atan_counter;
    reg state;

    wire [DATA_WIDTH-1:0] inv_2_pow_i;
    wire [DATA_WIDTH-1:0] inv_2_pow_3i;

    assign inv_2_pow_i = 16'b0001000000000000 >> atan_counter;
    assign inv_2_pow_3i = 16'b0001000000000000 >> 3*atan_counter; 

    always@(posedge i_clk) begin
        if(!i_rstn) begin
            atan_counter <= 0;
            state <= 0;
            o_atan_data <= 0;
            o_valid <= 0;
            o_done <= 0;
        end else begin
            case(state)
                0: begin
                    o_done <= 0;
                    if(i_valid) begin
                        o_atan_data <= i_data;
                        o_valid <= 1;
                        state <= 1;
                        atan_counter <= atan_counter + 1;
                    end
                    else begin
                        o_valid <= 0;
                        state <= 0;
                        atan_counter <= atan_counter;
                    end
                end

                1: begin
                    if(atan_counter>=1 && atan_counter<5) begin
                        atan_counter <= atan_counter + 1;
                        o_valid <= 1;
                        o_atan_data <= inv_2_pow_i - ((inv_2_pow_3i >> 2) + (inv_2_pow_3i >> 4) + (inv_2_pow_3i >> 6));
                    end
                    else if(atan_counter>=5) begin
                        if(atan_counter == N_PE) begin
                            atan_counter <= 0; // Reset counter after reaching N_PE
                            state <= 0; // Go back to initial state
                            o_valid <= 0; // Reset valid signal
                            o_done <= 1; // Indicate completion
                        end else begin
                            o_atan_data <= inv_2_pow_i;
                            atan_counter <= atan_counter + 1;
                            o_valid <= 1;
                        end
                    end
                end

                default: begin
                    o_valid <= 0;
                    state <= 0; // Reset to initial state
                    atan_counter <= 0; // Reset counter
                end

            endcase
        end
    end
endmodule