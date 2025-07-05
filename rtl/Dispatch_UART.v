module Dispatch_UART #(
    parameter DATA_WIDTH_IN = 40,
    parameter DATA_WIDTH_OUT = 8
) (
    input clk,
    input rst,
    input [DATA_WIDTH_IN-1 : 0] i_data,
    input i_data_valid,
    input tx_done, //from UART Transmitter logic
    
    output [DATA_WIDTH_OUT-1:0] o_data,
    output o_data_valid
);
    reg [DATA_WIDTH_IN-1 : 0] r_data;
    reg [DATA_WIDTH_OUT-1 : 0] r_data_out;
    reg r_valid_out;
    reg [2:0] state;
    reg [2:0] count;

    always@(posedge clk) begin
        if(!rst) begin
            state <= 0;
            count <= 0;
        end
        else begin
            case(state)
            0: begin
                r_valid_out <= 0;
                if(i_data_valid) begin
                    r_data <= i_data;
                    state <= 1;
                end
            end

            1: begin
                state <= 1;
                if(count>=5) begin
                    count <= 0;
                    state <= 0;
                    r_valid_out <= 0;
                    r_data <= r_data;
                end
                else begin
                    r_data_out <= r_data[(DATA_WIDTH_IN - (DATA_WIDTH_OUT*count))-1 -: DATA_WIDTH_OUT];
                    r_valid_out <= 1;
                    count <= count;
                    state <= 2;
                end
            end

            2: begin
                state  <= 2;
                r_data <= r_data;
                r_valid_out <= 0;
                if(tx_done) begin
                    count <= count + 1;
                    state <= 1;
                end
            end

            default: state <= state;
            endcase
        end
    end

    assign o_data_valid = r_valid_out;
    assign o_data = r_data_out;
endmodule
