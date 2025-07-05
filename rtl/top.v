module top#(
    parameter DATA_WIDTH = 18,
    parameter N_PE = 15
)(
    input i_clk,
    input i_RX_Serial,

    output o_Tx_Serial
);

    localparam CLK_FREQ     = 100000000;
    localparam BAUD_RATE    = 11520;
    localparam CLKS_PER_BIT = 870;

    /* ----------------------- UART Rx --------------------------- */
    wire uart_rx_valid;
    wire [7:0] uart_rx_byte;

    uart_rx #(
        .CLOCKS_PER_BIT(CLKS_PER_BIT)
    )
    uart_rx_inst (
        .i_Clock(i_clk),
        .i_RX_Serial(uart_rx_i),
        .o_RX_DV(uart_rx_valid),
        .o_RX_Byte(uart_rx_byte)
    );

    reg [1:0] byte_count = 0;
    reg [23:0] input_angle_cordic;
    reg valid_angle_cordic;

    reg [DATA_WIDTH-1 : 0] in_x;
    reg [DATA_WIDTH-1 : 0] in_y;

    always@(posedge i_clk) begin
        if(byte_count==2) begin
            if(uart_rx_valid) begin
                byte_count <= 0;
                valid_angle_cordic <= 1'b1;
                input_angle_cordic[((byte_count+1)*8)-1 -: 8] <= uart_rx_byte;
                in_x <= 18'h026de;
                in_y <= 18'h00000;
            end
            else begin 
                valid_angle_cordic <= 1'b0;
                byte_count <= byte_count;
            end
        end
        else begin
            if(uart_rx_valid) begin
                byte_count <= byte_count + 2'd1;
                input_angle_cordic[((byte_count+1)*8)-1 -: 8] <= uart_rx_byte;
            end
        end
    end

    /* -------------------------- Top CORDIC Engine --------------- */
    wire [DATA_WIDTH-1 : 0] cordic_out_costheta, cordic_out_sintheta;
    wire [DATA_WIDTH-1 : 0] cordic_in_angle;
    wire cordic_out_valid;

    assign cordic_in_angle = input_angle_cordic[DATA_WIDTH-1:0];

    top_CORDIC_Engine # (
        .DATA_WIDTH(DATA_WIDTH),
        .N_PE(N_PE)
    )
    top_CORDIC_Engine_inst (
        .i_clk(i_clk),
        .i_rst_n(1'b1),
        .in_x(in_x),
        .in_y(in_y),
        .in_alpha(cordic_in_angle),
        .i_valid_in(valid_angle_cordic),
        .out_costheta(cordic_out_costheta),
        .out_sintheta(cordic_out_sintheta),
        .out_alpha(),
        .o_valid_out(cordic_out_valid)
    );

    /* ----------------- UART Dispatcher ---------------------- */
    wire [39:0] UART_dispatch_data;
    assign UART_dispatch_data = {4'b0000,cordic_out_costheta,cordic_out_sintheta};
    
    wire tx_done;
    wire [7:0] uart_tx_data;
    wire uart_tx_dv;
    
    Dispatch_UART # (
        .DATA_WIDTH_IN(40), // CORDIC o/p = 18(cos) + 18(sin) + 4 ==> 5 bytes
        .DATA_WIDTH_OUT(8)
    )
    Dispatch_UART_inst (
        .clk(i_clk),
        .rst(1'b1),
        .i_data(UART_dispatch_data),
        .i_data_valid(cordic_out_valid),
        .tx_done(tx_done),
        .o_data(uart_tx_data),
        .o_data_valid(uart_tx_dv)
    );

    /* ---------------------- UART Tx -------------------------- */
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    )
    uart_tx_inst (
        .i_Clock(i_clk),
        .i_Rst_L(1'b1),
        .i_TX_DV(uart_tx_dv),
        .i_TX_Byte(uart_tx_data),
        .o_TX_Active(),
        .o_TX_Serial(o_Tx_Serial),
        .o_TX_Done(tx_done)
    );


endmodule